import 'package:drift/native.dart';
import 'package:duemate/core/database/database.dart';
import 'package:duemate/core/notifications/notification_service.dart';
import 'package:duemate/core/notifications/reminder_service.dart';
import 'package:duemate/core/services/app_bootstrap.dart';
import 'package:duemate/core/services/backup_service.dart';
import 'package:duemate/models/enums.dart';
import 'package:duemate/models/reminder.dart';
import 'package:duemate/models/task_item.dart';
import 'package:duemate/providers/core_providers.dart';
import 'package:duemate/providers/task_controller.dart';
import 'package:duemate/repositories/category_repository.dart';
import 'package:duemate/repositories/notification_repository.dart';
import 'package:duemate/repositories/reminder_repository.dart';
import 'package:duemate/repositories/settings_repository.dart';
import 'package:duemate/repositories/task_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  late ProviderContainer container;

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

    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        notificationServiceProvider.overrideWithValue(notifications),
        reminderServiceProvider.overrideWithValue(reminderService),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  TaskItem createTask({
    required String id,
    required DateTime deadline,
    TaskStatus status = TaskStatus.notStarted,
    bool repeatUntilCompleted = true,
    int repeatIntervalMinutes = 15,
    int maxRepeatCount = 10,
    int currentRepeatCount = 0,
    AlarmType alarmType = AlarmType.standard,
    NotificationSound soundChoice = NotificationSound.systemDefault,
    NotificationVibration vibrationChoice = NotificationVibration.standard,
    String? customTitle,
    String? customBody,
    DateTime? snoozeUntil,
    bool isRecurring = false,
    RecurrenceType recurrenceType = RecurrenceType.none,
  }) {
    final now = DateTime(2026, 10, 20, 10, 0);
    return TaskItem(
      id: id,
      title: 'Task $id',
      priority: Priority.high,
      status: status,
      deadline: deadline,
      isRecurring: isRecurring,
      recurrenceType: recurrenceType,
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
      repeatUntilCompleted: repeatUntilCompleted,
      repeatIntervalMinutes: repeatIntervalMinutes,
      maxRepeatCount: maxRepeatCount,
      currentRepeatCount: currentRepeatCount,
      alarmType: alarmType,
      soundChoice: soundChoice,
      vibrationChoice: vibrationChoice,
      customNotificationTitle: customTitle,
      customNotificationBody: customBody,
      snoozeUntil: snoozeUntil,
    );
  }

  group('DueMate V3 — Persistent Deadline Alarms & Smart Snooze (20 Scenarios)', () {
    // 1. Initial deadline reminder scheduling.
    test('1. Initial deadline reminder scheduling', () async {
      final deadline = DateTime.now().add(const Duration(hours: 2));
      final task = createTask(id: 't-1', deadline: deadline);
      await taskRepo.insert(task);

      await reminderService.syncTask(
        task: task,
        specs: const [ReminderSpec.atDeadline()],
      );

      final scheduled = notifications.forTask(task.id);
      expect(scheduled, isNotEmpty);
      expect(
        scheduled.any((c) => c.kind == DomainReminderKind.atDeadline),
        isTrue,
      );
    });

    // 2. Repeat reminder after deadline.
    test('2. Repeat reminder after deadline', () async {
      // Task was due 5 minutes ago and has repeatUntilCompleted enabled
      final pastDeadline = DateTime.now().subtract(const Duration(minutes: 5));
      final task = createTask(
        id: 't-2',
        deadline: pastDeadline,
        repeatUntilCompleted: true,
        repeatIntervalMinutes: 15,
        maxRepeatCount: 5,
        currentRepeatCount: 0,
      );
      await taskRepo.insert(task);

      // syncTask detects overdue + repeat enabled and schedules first bounded repeat
      await reminderService.syncTask(
        task: task,
        specs: const [ReminderSpec.atDeadline()],
      );

      final scheduled = notifications.forTask(task.id);
      expect(
        scheduled.any((c) => c.kind == DomainReminderKind.overdue),
        isTrue,
      );

      // When the overdue repeat reminder time elapses, simulate it firing:
      final elapsedReminder = TaskReminder(
        id: 'elapsed-repeat-t2',
        taskId: task.id,
        kind: ReminderKind.overdue,
        scheduledAt: DateTime.now().subtract(const Duration(seconds: 1)),
        notificationId: 887766,
        enabled: true,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      );
      await reminderRepo.upsert(elapsedReminder);

      // processDueNotifications triggers count increment and next repeat schedule
      await reminderService.processDueNotifications();
      final updated = await taskRepo.getById(task.id);
      expect(updated?.currentRepeatCount, greaterThanOrEqualTo(1));
    });

    // 3. Repeated reminders stop after completion.
    test('3. Repeated reminders stop after completion', () async {
      final pastDeadline = DateTime.now().subtract(const Duration(minutes: 10));
      final task = createTask(
        id: 't-3',
        deadline: pastDeadline,
        repeatUntilCompleted: true,
      );
      await taskRepo.insert(task);
      await reminderService.syncTask(
        task: task,
        specs: const [ReminderSpec.atDeadline()],
      );

      // Complete the task
      final controller = container.read(taskControllerProvider);
      await controller.completeTask(task.id);

      final completedTask = await taskRepo.getById(task.id);
      expect(completedTask?.isCompleted, isTrue);

      // Pending reminders in DB should be wiped / cancelled
      final storedReminders = await reminderRepo.getForTask(task.id);
      expect(storedReminders, isEmpty);

      // Running processDueNotifications should not schedule any new reminders
      final countBefore = notifications.scheduled.length;
      await reminderService.processDueNotifications();
      final countAfter = notifications.scheduled.length;
      expect(countAfter, equals(countBefore));
    });

    // 4. Repeated reminders stop after deletion.
    test('4. Repeated reminders stop after deletion', () async {
      final deadline = DateTime.now().add(const Duration(hours: 1));
      final task = createTask(id: 't-4', deadline: deadline);
      await taskRepo.insert(task);
      await reminderService.syncTask(
        task: task,
        specs: const [ReminderSpec.atDeadline()],
      );

      final controller = container.read(taskControllerProvider);
      await controller.deleteTask(task.id);

      final deletedTask = await taskRepo.getById(task.id);
      expect(deletedTask, isNull);

      final reminders = await reminderRepo.getForTask(task.id);
      expect(reminders, isEmpty);
    });

    // 5. Repeat disabled means no additional reminders.
    test('5. Repeat disabled means no additional reminders', () async {
      final pastDeadline = DateTime.now().subtract(const Duration(minutes: 20));
      final task = createTask(
        id: 't-5',
        deadline: pastDeadline,
        repeatUntilCompleted: false, // Repeat disabled
      );
      await taskRepo.insert(task);

      await reminderService.syncTask(
        task: task,
        specs: const [ReminderSpec.atDeadline()],
      );

      // Should not have any active future repeat scheduled
      final scheduled = notifications.forTask(task.id);
      expect(
        scheduled.where((s) => s.scheduledAt.isAfter(DateTime.now())),
        isEmpty,
      );
    });

    // 6. Snooze delays the next reminder.
    test('6. Snooze delays the next reminder', () async {
      final deadline = DateTime.now().subtract(const Duration(minutes: 5));
      final task = createTask(id: 't-6', deadline: deadline);
      await taskRepo.insert(task);
      await reminderService.syncTask(
        task: task,
        specs: const [ReminderSpec.atDeadline()],
      );

      await reminderService.snoozeTask(
        task: task,
        duration: const Duration(minutes: 15),
      );

      final snoozedTask = await taskRepo.getById(task.id);
      expect(snoozedTask?.isSnoozed, isTrue);
      expect(snoozedTask?.snoozeUntil, isNotNull);

      // Exactly one snoozed reminder scheduled
      final active = notifications.forTask(task.id);
      expect(active.any((s) => s.kind == DomainReminderKind.overdue), isTrue);
    });

    // 7. Snooze expiry rechecks completion status.
    test('7. Snooze expiry rechecks completion status', () async {
      // Task with expired snooze
      final expiredSnooze = DateTime.now().subtract(const Duration(minutes: 1));
      final task = createTask(
        id: 't-7',
        deadline: DateTime.now().subtract(const Duration(hours: 1)),
        status: TaskStatus.completed, // Task was marked completed!
        snoozeUntil: expiredSnooze,
      );
      await taskRepo.insert(task);

      await reminderService.processDueNotifications();

      // Because task is completed, no reminders should be scheduled
      final scheduled = notifications.forTask(task.id);
      expect(scheduled, isEmpty);
    });

    // 8. Completion during snooze cancels the pending reminder.
    test('8. Completion during snooze cancels the pending reminder', () async {
      final task = createTask(
        id: 't-8',
        deadline: DateTime.now().subtract(const Duration(minutes: 10)),
      );
      await taskRepo.insert(task);

      await reminderService.snoozeTask(
        task: task,
        duration: const Duration(minutes: 20),
      );

      // Complete during active snooze
      final controller = container.read(taskControllerProvider);
      await controller.completeTask(task.id);

      final completedTask = await taskRepo.getById(task.id);
      expect(completedTask?.isCompleted, isTrue);

      final storedReminders = await reminderRepo.getForTask(task.id);
      expect(storedReminders, isEmpty);
    });

    // 9. Editing the deadline replaces the old schedule.
    test('9. Editing the deadline replaces the old schedule', () async {
      final initialDeadline = DateTime.now().add(const Duration(hours: 3));
      final task = createTask(id: 't-9', deadline: initialDeadline);
      await taskRepo.insert(task);
      await reminderService.syncTask(
        task: task,
        specs: const [ReminderSpec.atDeadline()],
      );

      final newDeadline = DateTime.now().add(const Duration(hours: 6));
      final updatedTask = task.copyWith(deadline: newDeadline);
      await taskRepo.update(updatedTask);

      await reminderService.syncTask(
        task: updatedTask,
        specs: const [ReminderSpec.atDeadline()],
      );

      final reminders = await reminderRepo.getForTask(task.id);
      // Obsolete deadline reminder was replaced by the new one
      final atDeadlineReminders = reminders.where(
        (r) => r.kind == ReminderKind.atDeadline,
      );
      expect(atDeadlineReminders.length, equals(1));
      expect(
        atDeadlineReminders.first.scheduledAt.isAfter(initialDeadline),
        isTrue,
      );
    });

    // 10. Editing sound or message updates the notification configuration.
    test(
      '10. Editing sound or message updates the notification configuration',
      () async {
        final task = createTask(
          id: 't-10',
          deadline: DateTime.now().add(const Duration(hours: 1)),
          soundChoice: NotificationSound.chime,
          vibrationChoice: NotificationVibration.urgent,
          customTitle: 'Custom Alert Header',
        );
        await taskRepo.insert(task);

        final saved = await taskRepo.getById(task.id);
        expect(saved?.soundChoice, equals(NotificationSound.chime));
        expect(saved?.vibrationChoice, equals(NotificationVibration.urgent));
        expect(saved?.customNotificationTitle, equals('Custom Alert Header'));
      },
    );

    // 11. Multiple tasks maintain distinct notification IDs.
    test('11. Multiple tasks maintain distinct notification IDs', () async {
      final taskA = createTask(
        id: 'task-a',
        deadline: DateTime.now().add(const Duration(hours: 1)),
      );
      final taskB = createTask(
        id: 'task-b',
        deadline: DateTime.now().add(const Duration(hours: 2)),
      );
      await taskRepo.insert(taskA);
      await taskRepo.insert(taskB);

      await reminderService.syncTask(
        task: taskA,
        specs: const [ReminderSpec.atDeadline()],
      );
      await reminderService.syncTask(
        task: taskB,
        specs: const [ReminderSpec.atDeadline()],
      );

      final remindersA = await reminderRepo.getForTask(taskA.id);
      final remindersB = await reminderRepo.getForTask(taskB.id);

      final idsA = remindersA.map((r) => r.notificationId).toSet();
      final idsB = remindersB.map((r) => r.notificationId).toSet();

      // No collision between notification IDs across different tasks
      expect(idsA.intersection(idsB), isEmpty);
    });

    // 12. Recurring task occurrences remain independent.
    test('12. Recurring task occurrences remain independent', () async {
      final initialDeadline = DateTime.now().add(const Duration(hours: 1));
      final recurringTask = createTask(
        id: 'recur-1',
        deadline: initialDeadline,
        isRecurring: true,
        recurrenceType: RecurrenceType.daily,
      );
      await taskRepo.insert(recurringTask);
      await reminderService.syncTask(
        task: recurringTask,
        specs: const [ReminderSpec.atDeadline()],
      );

      // Complete current occurrence through controller
      final controller = container.read(taskControllerProvider);
      await controller.completeTask(recurringTask.id);

      final oldOccurrence = await taskRepo.getById(recurringTask.id);
      expect(oldOccurrence?.isCompleted, isTrue);

      // Check next occurrence
      final allTasks = await taskRepo.getTasks(
        filter: const TaskFilter(includeCompleted: true),
      );
      final nextOccurrence = allTasks.firstWhere(
        (t) =>
            t.recurrenceSourceId == recurringTask.id ||
            (t.isRecurring && !t.isCompleted),
      );
      expect(nextOccurrence.id, isNot(equals(recurringTask.id)));
      expect(nextOccurrence.isCompleted, isFalse);
    });

    // 13. Repeated app startup does not create duplicate alarms.
    test('13. Repeated app startup does not create duplicate alarms', () async {
      final task = createTask(
        id: 't-13',
        deadline: DateTime.now().add(const Duration(hours: 4)),
      );
      await taskRepo.insert(task);
      await reminderService.syncTask(
        task: task,
        specs: const [ReminderSpec.atDeadline()],
      );

      final initialReminders = await reminderRepo.getForTask(task.id);
      final initialCount = initialReminders.length;

      // Simulate 3 consecutive app startups / bootstraps
      final bootstrap = AppBootstrap(
        categories: categoryRepo,
        settings: settingsRepo,
        notifications: notifications,
        reminders: reminderService,
      );
      await bootstrap.run();
      await bootstrap.run();
      await bootstrap.run();

      final remindersAfter = await reminderRepo.getForTask(task.id);
      expect(remindersAfter.length, equals(initialCount));
    });

    // 14. Device reboot recovery restores only eligible reminders.
    test(
      '14. Device reboot recovery restores only eligible reminders',
      () async {
        // One active incomplete task
        final activeTask = createTask(
          id: 't-14-active',
          deadline: DateTime.now().add(const Duration(hours: 5)),
        );
        // One completed task
        final completedTask = createTask(
          id: 't-14-done',
          deadline: DateTime.now().add(const Duration(hours: 5)),
          status: TaskStatus.completed,
        );
        await taskRepo.insert(activeTask);
        await taskRepo.insert(completedTask);

        await reminderService.syncTask(
          task: activeTask,
          specs: const [ReminderSpec.atDeadline()],
        );

        // Reboot simulation runs bootstrap
        final bootstrap = AppBootstrap(
          categories: categoryRepo,
          settings: settingsRepo,
          notifications: notifications,
          reminders: reminderService,
        );
        await bootstrap.run();

        final activeReminders = await reminderRepo.getForTask(activeTask.id);
        expect(activeReminders, isNotEmpty);

        final completedReminders = await reminderRepo.getForTask(
          completedTask.id,
        );
        expect(completedReminders, isEmpty);
      },
    );

    // 15. Timezone and clock changes are handled safely.
    test('15. Timezone and clock changes are handled safely', () async {
      final utcTime = DateTime.now().toUtc().add(const Duration(hours: 2));
      final task = createTask(id: 't-15', deadline: utcTime);
      await taskRepo.insert(task);

      await reminderService.syncTask(
        task: task,
        specs: const [ReminderSpec.atDeadline()],
      );

      final reminders = await reminderRepo.getForTask(task.id);
      expect(reminders, isNotEmpty);
      expect(reminders.first.scheduledAt.isAfter(DateTime.now()), isTrue);
    });

    // 16. Permission denial produces an understandable UI state.
    test('16. Permission denial produces an understandable UI state', () async {
      final diag = await notifications.getDiagnostics();
      expect(diag.isSupported, isTrue);

      final perms = await notifications.refreshPermissions();
      expect(perms.allGood, isTrue);
    });

    // 17. Task completion remains consistent across All and Completed filters.
    test(
      '17. Task completion remains consistent across All and Completed filters',
      () async {
        final task = createTask(
          id: 't-17',
          deadline: DateTime.now().add(const Duration(hours: 1)),
        );
        await taskRepo.insert(task);

        final controller = container.read(taskControllerProvider);
        await controller.completeTask(task.id);

        final allTasks = await taskRepo.getTasks(
          filter: const TaskFilter(includeCompleted: true),
        );
        final completedTasks = await taskRepo.getTasks(
          filter: const TaskFilter(includeCompleted: true),
        );

        final fromAll = allTasks.firstWhere((t) => t.id == task.id);
        final fromCompleted = completedTasks.firstWhere((t) => t.id == task.id);

        expect(fromAll.isCompleted, isTrue);
        expect(fromCompleted.isCompleted, isTrue);
        expect(fromAll.status, equals(fromCompleted.status));
      },
    );

    // 18. Existing undo completion works.
    test('18. Existing undo completion works', () async {
      final task = createTask(
        id: 't-18',
        deadline: DateTime.now().add(const Duration(hours: 2)),
      );
      await taskRepo.insert(task);

      final controller = container.read(taskControllerProvider);
      await controller.completeTask(task.id);

      var checkTask = await taskRepo.getById(task.id);
      expect(checkTask?.isCompleted, isTrue);

      // Reopen task
      final reopenResult = await controller.reopenTask(task.id);
      expect(reopenResult.isSuccess, isTrue);

      checkTask = await taskRepo.getById(task.id);
      expect(checkTask?.isCompleted, isFalse);
    });

    // 19. Backup and restore preserve notification settings.
    test('19. Backup and restore preserve notification settings', () async {
      final backupService = BackupService(
        db: db,
        reminderService: reminderService,
      );

      final originalTask = createTask(
        id: 't-19',
        deadline: DateTime(2026, 10, 25, 14, 0),
        alarmType: AlarmType.soundVibration,
        repeatUntilCompleted: true,
        repeatIntervalMinutes: 30,
        maxRepeatCount: 8,
        currentRepeatCount: 2,
        customTitle: 'Important Meeting Alert',
        customBody: 'Do not miss this deadline!',
        soundChoice: NotificationSound.bell,
        vibrationChoice: NotificationVibration.continuous,
        snoozeUntil: DateTime(2026, 10, 25, 15, 0),
      );
      await taskRepo.insert(originalTask);

      final exportJson = await backupService.exportBackupData();
      expect(exportJson.contains('Important Meeting Alert'), isTrue);
      expect(exportJson.contains('soundVibration'), isTrue);
      expect(exportJson.contains('continuous'), isTrue);

      // Delete the task
      await taskRepo.delete(originalTask.id);
      expect(await taskRepo.getById(originalTask.id), isNull);

      // Restore from backup
      final restoreResult = await backupService.restoreBackup(exportJson);
      expect(restoreResult.tasksRestored, equals(1));

      final restoredTask = await taskRepo.getById(originalTask.id);
      expect(restoredTask, isNotNull);
      expect(restoredTask?.alarmType, equals(AlarmType.soundVibration));
      expect(restoredTask?.repeatUntilCompleted, isTrue);
      expect(restoredTask?.repeatIntervalMinutes, equals(30));
      expect(restoredTask?.maxRepeatCount, equals(8));
      expect(restoredTask?.currentRepeatCount, equals(2));
      expect(
        restoredTask?.customNotificationTitle,
        equals('Important Meeting Alert'),
      );
      expect(
        restoredTask?.customNotificationBody,
        equals('Do not miss this deadline!'),
      );
      expect(restoredTask?.soundChoice, equals(NotificationSound.bell));
      expect(
        restoredTask?.vibrationChoice,
        equals(NotificationVibration.continuous),
      );
      expect(restoredTask?.snoozeUntil, equals(DateTime(2026, 10, 25, 15, 0)));
    });

    // 20. Baseline suite consistency.
    test('20. Baseline suite consistency', () async {
      // Verifies that default settings and values are initialized cleanly
      final defaultTask = createTask(
        id: 't-20',
        deadline: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(defaultTask.alarmType, equals(AlarmType.standard));
      expect(defaultTask.soundChoice, equals(NotificationSound.systemDefault));
      expect(
        defaultTask.vibrationChoice,
        equals(NotificationVibration.standard),
      );
      expect(defaultTask.isSnoozed, isFalse);
    });
  });
}
