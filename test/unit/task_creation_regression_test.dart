import 'package:drift/native.dart';
import 'package:duemate/core/database/database.dart';
import 'package:duemate/core/notifications/reminder_service.dart';
import 'package:duemate/models/enums.dart';
import 'package:duemate/models/reminder.dart';
import 'package:duemate/models/task_item.dart';
import 'package:duemate/providers/core_providers.dart';
import 'package:duemate/providers/task_controller.dart';
import 'package:duemate/repositories/task_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart';

import '../helpers/fake_notification_service.dart';

void main() {
  group('Database Schema & Migration Regression', () {
    test(
      'upgrades schema v1 tasks table (missing user_id) to v2 with user_id',
      () async {
        // 1. Manually create a raw SQLite database at user_version 1 without user_id column
        final raw = sqlite3.openInMemory();
        raw.execute('PRAGMA user_version = 1;');
        raw.execute('''
        CREATE TABLE "categories" (
          "id" TEXT NOT NULL,
          "name" TEXT NOT NULL,
          "icon" TEXT NOT NULL DEFAULT 'folder',
          "color" INTEGER NOT NULL,
          "is_default" INTEGER NOT NULL DEFAULT 0,
          "sort_order" INTEGER NOT NULL DEFAULT 0,
          "created_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
          PRIMARY KEY ("id")
        );
      ''');
        raw.execute('''
        CREATE TABLE "tasks" (
          "id" TEXT NOT NULL,
          "title" TEXT NOT NULL,
          "description" TEXT NULL,
          "notes" TEXT NULL,
          "category_id" TEXT NULL REFERENCES categories (id) ON DELETE SET NULL,
          "priority" INTEGER NOT NULL,
          "status" INTEGER NOT NULL,
          "deadline" INTEGER NULL,
          "is_recurring" INTEGER NOT NULL DEFAULT 0,
          "recurrence_type" INTEGER NOT NULL,
          "recurrence_days" TEXT NULL,
          "recurrence_source_id" TEXT NULL,
          "completed_at" INTEGER NULL,
          "parent_task_id" TEXT NULL REFERENCES tasks (id) ON DELETE CASCADE,
          "sort_order" INTEGER NOT NULL DEFAULT 0,
          "created_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
          "updated_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
          PRIMARY KEY ("id")
        );
      ''');
        raw.execute('''
        CREATE TABLE "reminders" (
          "id" TEXT NOT NULL,
          "task_id" TEXT NOT NULL REFERENCES tasks (id) ON DELETE CASCADE,
          "kind" INTEGER NOT NULL,
          "minutes_before" INTEGER NULL,
          "scheduled_at" INTEGER NOT NULL,
          "notification_id" INTEGER NOT NULL,
          "enabled" INTEGER NOT NULL DEFAULT 1,
          "notified_at" INTEGER NULL,
          "created_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
          PRIMARY KEY ("id")
        );
      ''');
        raw.execute('''
        CREATE TABLE "task_notifications" (
          "id" TEXT NOT NULL,
          "task_id" TEXT NULL REFERENCES tasks (id) ON DELETE CASCADE,
          "category" INTEGER NOT NULL,
          "title" TEXT NOT NULL,
          "body" TEXT NOT NULL,
          "created_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
          "read_at" INTEGER NULL,
          PRIMARY KEY ("id")
        );
      ''');
        raw.execute('''
        CREATE TABLE "app_settings" (
          "key" TEXT NOT NULL,
          "value" TEXT NOT NULL,
          PRIMARY KEY ("key")
        );
      ''');

        // Verify v1 tasks table does not have user_id
        final v1Cols = raw.select("PRAGMA table_info('tasks');");
        expect(v1Cols.any((r) => r['name'] == 'user_id'), isFalse);

        // 2. Wrap the existing database with AppDatabase.
        // Drift detects user_version 1 vs schemaVersion 2 and runs onUpgrade automatically!
        final db = AppDatabase.withExecutor(NativeDatabase.opened(raw));

        // Trigger database open
        final cols = await db.customSelect("PRAGMA table_info('tasks');").get();
        expect(cols.any((r) => r.data['name'] == 'user_id'), isTrue);
        expect(cols.any((r) => r.data['name'] == 'alarm_type'), isTrue);
        expect(
          cols.any((r) => r.data['name'] == 'repeat_until_completed'),
          isTrue,
        );

        final userVersionRow = await db
            .customSelect('PRAGMA user_version;')
            .getSingle();
        expect(userVersionRow.data.values.first, equals(3));

        // 3. Verify inserting and reading a task with userId works seamlessly
        final repo = TaskRepository(db);
        final testTask = TaskItem(
          id: 'test_migrated_1',
          title: 'Migrated Task',
          priority: Priority.high,
          status: TaskStatus.notStarted,
          isRecurring: false,
          recurrenceType: RecurrenceType.none,
          userId: 'user_123',
          sortOrder: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await repo.insert(testTask);

        final retrieved = await repo.getById('test_migrated_1');
        expect(retrieved, isNotNull);
        expect(retrieved!.title, 'Migrated Task');
        expect(retrieved.userId, 'user_123');

        await db.close();
      },
    );
  });

  group('Task Creation Flow & Partial Failure Safety', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase.withExecutor(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(
            FakeNotificationService(),
          ),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('creates task matching user reported scenario (Assignment submission, Urgent, 5m reminder)', () async {
      final controller = container.read(taskControllerProvider);
      final deadline = DateTime(2026, 10, 13, 17, 30);

      final draft = TaskDraft(
        title: 'Assignment submission',
        priority: Priority.urgent,
        categoryId: null, // None
        deadline: deadline,
        reminders: [
          const ReminderSpec(
            kind: ReminderKind.beforeDeadline,
            minutesBefore: 5,
          ),
        ],
        recurrenceType: RecurrenceType.none,
      );

      final result = await controller.createTask(draft);
      expect(result.isSuccess, isTrue);
      expect(result.error, isNull);

      final tasks = await container.read(taskRepositoryProvider).getTasks();
      expect(tasks, hasLength(1));
      final savedTask = tasks.first;
      expect(savedTask.title, 'Assignment submission');
      expect(savedTask.priority, Priority.urgent);
      expect(savedTask.categoryId, isNull);
      expect(savedTask.deadline, equals(deadline));
      expect(savedTask.isRecurring, isFalse);

      // Verify reminder was planned and saved
      final reminders = await container
          .read(reminderRepositoryProvider)
          .getForTask(savedTask.id);
      expect(reminders, isNotEmpty);
      expect(
        reminders.any(
          (r) => r.kind == ReminderKind.beforeDeadline && r.minutesBefore == 5,
        ),
        isTrue,
      );
    });

    test('rolls back inserted task if reminder scheduling fails to prevent duplicates on retry', () async {
      // Mock reminder service to throw an exception during syncTask
      final failingContainer = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(
            FakeNotificationService(),
          ),
          reminderServiceProvider.overrideWithValue(
            _FailingReminderService(
              notifications: FakeNotificationService(),
              reminders: container.read(reminderRepositoryProvider),
              notificationCenter: container.read(
                notificationRepositoryProvider,
              ),
              tasks: container.read(taskRepositoryProvider),
              settings: container.read(settingsRepositoryProvider),
            ),
          ),
        ],
      );

      final controller = failingContainer.read(taskControllerProvider);
      final taskRepo = failingContainer.read(taskRepositoryProvider);

      final draft = TaskDraft(
        title: 'Partial failure task',
        priority: Priority.high,
        deadline: DateTime(2026, 10, 13, 18, 0),
        reminders: [
          const ReminderSpec(
            kind: ReminderKind.beforeDeadline,
            minutesBefore: 15,
          ),
        ],
      );

      // First attempt fails during reminder scheduling
      final result1 = await controller.createTask(draft);
      expect(result1.isSuccess, isFalse);
      expect(result1.error, 'Could not save the task. Please try again.');

      // CRITICAL: The task must NOT be left orphaned in the database!
      final tasksAfterFail = await taskRepo.getTasks();
      expect(
        tasksAfterFail,
        isEmpty,
        reason: 'Task should be rolled back so retry does not duplicate',
      );

      // Normal container where reminders succeed
      final normalController = container.read(taskControllerProvider);
      final result2 = await normalController.createTask(draft);
      expect(result2.isSuccess, isTrue);

      final tasksAfterRetry = await container
          .read(taskRepositoryProvider)
          .getTasks();
      expect(
        tasksAfterRetry,
        hasLength(1),
        reason: 'Only exactly one task exists after retry',
      );

      failingContainer.dispose();
    });
  });
}

class _FailingReminderService extends ReminderService {
  _FailingReminderService({
    required super.notifications,
    required super.reminders,
    required super.notificationCenter,
    required super.tasks,
    required super.settings,
  });

  @override
  Future<void> syncTask({
    required TaskItem task,
    required List<ReminderSpec> specs,
  }) async {
    throw Exception('Simulated reminder scheduling failure');
  }
}
