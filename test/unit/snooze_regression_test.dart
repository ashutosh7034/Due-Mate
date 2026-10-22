import 'package:duemate/core/database/database.dart';
import 'package:duemate/core/notifications/reminder_service.dart';
import 'package:duemate/models/enums.dart';
import 'package:duemate/models/task_item.dart';
import 'package:duemate/models/user_settings.dart';
import 'package:duemate/repositories/notification_repository.dart';
import 'package:duemate/repositories/reminder_repository.dart';
import 'package:duemate/repositories/settings_repository.dart';
import 'package:duemate/repositories/task_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_notification_service.dart';
import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late TaskRepository taskRepo;
  late ReminderRepository reminderRepo;
  late NotificationRepository notificationRepo;
  late SettingsRepository settingsRepo;
  late FakeNotificationService notifications;
  late ReminderService service;

  setUp(() {
    db = openTestDatabase();
    taskRepo = TaskRepository(db);
    reminderRepo = ReminderRepository(db);
    notificationRepo = NotificationRepository(db);
    settingsRepo = SettingsRepository(db);
    notifications = FakeNotificationService();
    service = ReminderService(
      notifications: notifications,
      reminders: reminderRepo,
      notificationCenter: notificationRepo,
      tasks: taskRepo,
      settings: settingsRepo,
    );
  });

  tearDown(() async {
    await db.close();
  });

  TaskItem createTask({required String id, DateTime? deadline}) {
    final now = DateTime.now();
    return TaskItem(
      id: id,
      title: 'Task $id',
      priority: Priority.high,
      status: TaskStatus.notStarted,
      recurrenceType: RecurrenceType.none,
      isRecurring: false,
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
      deadline: deadline ?? now.add(const Duration(hours: 2)),
    );
  }

  test(
    'snoozeTask schedules custom OS notification and persists reminder record',
    () async {
      final task = createTask(id: 'task-snooze-1');
      await taskRepo.insert(task);

      final beforeSnooze = DateTime.now();
      const snoozeDuration = Duration(minutes: 15);

      await service.snoozeTask(task: task, duration: snoozeDuration);

      final scheduled = notifications.scheduled;
      expect(scheduled, hasLength(1));
      expect(scheduled.first.taskId, 'task-snooze-1');
      expect(scheduled.first.kind, ReminderKind.custom);

      // Scheduled time should be approximately now + 15 minutes
      final diff = scheduled.first.scheduledAt.difference(
        beforeSnooze.add(snoozeDuration),
      );
      expect(diff.inSeconds.abs(), lessThanOrEqualTo(3));

      // Stored in SQLite
      final stored = await reminderRepo.getForTask('task-snooze-1');
      expect(stored, hasLength(1));
      expect(stored.first.kind, ReminderKind.custom);
      expect(stored.first.notificationId, scheduled.first.notificationId);
    },
  );

  test(
    'snoozeTask does not schedule when notifications are globally disabled',
    () async {
      await settingsRepo.save(const UserSettings(notificationsEnabled: false));

      final task = createTask(id: 'task-snooze-disabled');
      await taskRepo.insert(task);

      await service.snoozeTask(
        task: task,
        duration: const Duration(minutes: 10),
      );

      expect(notifications.scheduled, isEmpty);
      final stored = await reminderRepo.getForTask('task-snooze-disabled');
      expect(stored, isEmpty);
    },
  );
}
