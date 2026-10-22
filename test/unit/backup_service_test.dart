import 'package:drift/native.dart';
import 'package:duemate/core/database/database.dart';
import 'package:duemate/core/notifications/reminder_service.dart';
import 'package:duemate/core/services/backup_service.dart';
import 'package:duemate/models/category.dart';
import 'package:duemate/models/enums.dart';
import 'package:duemate/models/task_item.dart';
import 'package:duemate/repositories/category_repository.dart';
import 'package:duemate/repositories/notification_repository.dart';
import 'package:duemate/repositories/reminder_repository.dart';
import 'package:duemate/repositories/settings_repository.dart';
import 'package:duemate/repositories/task_repository.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_notification_service.dart';

void main() {
  late AppDatabase db;
  late TaskRepository taskRepo;
  late CategoryRepository categoryRepo;
  late ReminderRepository reminderRepo;
  late NotificationRepository notificationRepo;
  late SettingsRepository settingsRepo;
  late FakeNotificationService notifications;
  late ReminderService reminderService;
  late BackupService backupService;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    taskRepo = TaskRepository(db);
    categoryRepo = CategoryRepository(db);
    reminderRepo = ReminderRepository(db);
    notificationRepo = NotificationRepository(db);
    settingsRepo = SettingsRepository(db);
    notifications = FakeNotificationService();
    reminderService = ReminderService(
      notifications: notifications,
      reminders: reminderRepo,
      notificationCenter: notificationRepo,
      tasks: taskRepo,
      settings: settingsRepo,
    );
    backupService = BackupService(db: db, reminderService: reminderService);
  });

  tearDown(() async {
    await db.close();
  });

  test('exportBackupData exports valid DueMate JSON structure', () async {
    final now = DateTime.now();
    await categoryRepo.upsert(
      Category(
        id: 'cat-work',
        name: 'Work',
        iconKey: 'briefcase',
        color: const Color(0xFF2196F3),
        createdAt: now,
      ),
    );

    await taskRepo.insert(
      TaskItem(
        id: 'task-1',
        title: 'Complete DueMate V2',
        priority: Priority.urgent,
        status: TaskStatus.inProgress,
        recurrenceType: RecurrenceType.none,
        isRecurring: false,
        categoryId: 'cat-work',
        deadline: now.add(const Duration(days: 1)),
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final json = await backupService.exportBackupData();
    expect(json.isNotEmpty, isTrue);

    final validation = backupService.validateBackup(json);
    expect(validation.isValid, isTrue);
    expect(validation.taskCount, 1);
    expect(validation.categoryCount, 1);
  });

  test('validateBackup rejects invalid, corrupted, or mismatched JSON', () {
    expect(backupService.validateBackup('').isValid, isFalse);
    expect(backupService.validateBackup('{ invalid json').isValid, isFalse);
    expect(
      backupService
          .validateBackup('{"app": "AnotherApp", "tasks": []}')
          .isValid,
      isFalse,
    );
    expect(
      backupService
          .validateBackup('{"app": "DueMate", "tasks": "not-a-list"}')
          .isValid,
      isFalse,
    );
  });

  test('restoreBackup restores tasks and subtasks transactionally', () async {
    const backupJson = '''
{
  "app": "DueMate",
  "version": 1,
  "exportedAt": "2026-10-14T10:00:00.000Z",
  "categories": [
    {
      "id": "cat-study",
      "name": "Study",
      "icon": "book",
      "color": 4282550000,
      "isDefault": false,
      "sortOrder": 0,
      "createdAt": "2026-10-14T09:00:00.000Z"
    }
  ],
  "tasks": [
    {
      "id": "task-parent",
      "title": "Study for Exam",
      "priority": "high",
      "status": "todo",
      "recurrenceType": "none",
      "isRecurring": false,
      "categoryId": "cat-study",
      "parentTaskId": null,
      "sortOrder": 0,
      "createdAt": "2026-10-14T09:00:00.000Z",
      "updatedAt": "2026-10-14T09:00:00.000Z"
    },
    {
      "id": "task-child",
      "title": "Chapter 1 review",
      "priority": "medium",
      "status": "todo",
      "recurrenceType": "none",
      "isRecurring": false,
      "categoryId": "cat-study",
      "parentTaskId": "task-parent",
      "sortOrder": 0,
      "createdAt": "2026-10-14T09:05:00.000Z",
      "updatedAt": "2026-10-14T09:05:00.000Z"
    }
  ],
  "reminders": []
}
''';

    final result = await backupService.restoreBackup(
      backupJson,
      mergeMode: true,
    );
    expect(result.tasksRestored, 2);
    expect(result.categoriesRestored, 1);

    final parent = await taskRepo.getById('task-parent');
    expect(parent, isNotNull);
    expect(parent!.title, 'Study for Exam');

    final subtasks = await taskRepo.getSubtasks('task-parent');
    expect(subtasks, hasLength(1));
    expect(subtasks.first.title, 'Chapter 1 review');
    expect(subtasks.first.parentTaskId, 'task-parent');
  });
}
