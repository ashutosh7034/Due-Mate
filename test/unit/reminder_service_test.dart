import 'package:duemate/core/database/database.dart';
import 'package:duemate/core/notifications/reminder_service.dart';
import 'package:duemate/models/enums.dart';
import 'package:duemate/models/reminder.dart';
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

  TaskItem buildTask({
    required String id,
    required DateTime deadline,
    TaskStatus status = TaskStatus.notStarted,
    bool recurring = false,
    RecurrenceType recurrenceType = RecurrenceType.none,
    String? recurrenceDays,
    String? recurrenceSourceId,
  }) {
    final now = DateTime(2026, 10, 8, 6, 0);
    return TaskItem(
      id: id,
      title: 'Task $id',
      priority: Priority.high,
      status: status,
      recurrenceType: recurrenceType,
      isRecurring: recurring,
      deadline: deadline,
      recurrenceDays: recurrenceDays,
      recurrenceSourceId: recurrenceSourceId,
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('syncTask schedules every future reminder and persists them', () async {
    final deadline = DateTime.now().add(const Duration(days: 2));
    final task = buildTask(id: 't1', deadline: deadline);
    await taskRepo.insert(task);

    await service.syncTask(
      task: task,
      specs: const [
        ReminderSpec.before(1440),
        ReminderSpec.before(60),
        ReminderSpec.atDeadline(),
      ],
    );

    final stored = await reminderRepo.getForTask(task.id);
    // 3 requested + 1 overdue nudge.
    expect(stored, hasLength(4));
    // All four are future (deadline is 2 days out).
    expect(notifications.forTask(task.id), hasLength(4));
  });

  test('scenario 4 — completing a task cancels its reminders', () async {
    final deadline = DateTime.now().add(const Duration(days: 2));
    final task = buildTask(id: 't1', deadline: deadline);
    await taskRepo.insert(task);
    await service.syncTask(
      task: task,
      specs: const [ReminderSpec.atDeadline()],
    );
    final scheduledIds = notifications
        .forTask(task.id)
        .map((c) => c.notificationId)
        .toSet();
    expect(scheduledIds, isNotEmpty);

    // Simulate completion.
    final completed = task.copyWith(
      status: TaskStatus.completed,
      completedAt: DateTime.now(),
    );
    await taskRepo.update(completed);
    await service.resyncFromStored(completed);

    expect(notifications.cancelled.toSet(), containsAll(scheduledIds));
    final stored = await reminderRepo.getForTask(task.id);
    expect(stored, isEmpty);
  });

  test(
    'scenario 5 — changing the deadline cancels old and schedules new',
    () async {
      final oldDeadline = DateTime.now().add(const Duration(days: 1));
      final task = buildTask(id: 't1', deadline: oldDeadline);
      await taskRepo.insert(task);
      await service.syncTask(
        task: task,
        specs: const [ReminderSpec.before(60), ReminderSpec.atDeadline()],
      );
      final oldIds = notifications
          .forTask(task.id)
          .map((c) => c.notificationId)
          .toList();

      final newDeadline = DateTime.now().add(const Duration(days: 5));
      final rescheduled = task.copyWith(deadline: newDeadline);
      await taskRepo.update(rescheduled);
      await service.resyncFromStored(rescheduled);

      // Every old notification was cancelled.
      expect(notifications.cancelled, containsAll(oldIds));

      // New notifications exist and point at the new deadline.
      final stored = await reminderRepo.getForTask(task.id);
      final atDeadline = stored.firstWhere(
        (r) => r.kind == ReminderKind.atDeadline,
      );
      expect(
        atDeadline.scheduledAt.difference(newDeadline).inSeconds.abs(),
        lessThan(2),
      );
      // None of the new ids collide with the old ones.
      final newIds = stored.map((r) => r.notificationId).toSet();
      expect(newIds.intersection(oldIds.toSet()), isEmpty);
    },
  );

  test('scenario 6 — deleting a task cancels its notifications', () async {
    final deadline = DateTime.now().add(const Duration(days: 3));
    final task = buildTask(id: 't1', deadline: deadline);
    await taskRepo.insert(task);
    await service.syncTask(
      task: task,
      specs: const [ReminderSpec.atDeadline()],
    );
    final ids = notifications
        .forTask(task.id)
        .map((c) => c.notificationId)
        .toList();

    await service.cancelTask(task.id);
    await taskRepo.delete(task.id);

    expect(notifications.cancelled, containsAll(ids));
    expect(await reminderRepo.getForTask(task.id), isEmpty);
  });

  test(
    'master switch off cancels everything and clears stored reminders',
    () async {
      final deadline = DateTime.now().add(const Duration(days: 2));
      final task = buildTask(id: 't1', deadline: deadline);
      await taskRepo.insert(task);
      await service.syncTask(
        task: task,
        specs: const [ReminderSpec.atDeadline()],
      );

      await settingsRepo.save(const UserSettings(notificationsEnabled: false));
      final settings = await settingsRepo.load();
      await service.applySettingsChange(settings);

      expect(notifications.cancelAllCount, greaterThan(0));
      expect(await reminderRepo.getForTask(task.id), isEmpty);
    },
  );

  test(
    'processDueNotifications creates centre entries and marks them read-able',
    () async {
      // Deadline slightly in the past so reminders and the overdue sweep fire.
      final deadline = DateTime.now().subtract(const Duration(minutes: 5));
      final task = buildTask(id: 't1', deadline: deadline);
      await taskRepo.insert(task);
      await service.syncTask(
        task: task,
        specs: const [ReminderSpec.before(60)],
      );

      await service.processDueNotifications();

      final centre = await notificationRepo.watchAll().first;
      expect(centre, isNotEmpty);
      expect(
        centre.any((n) => n.taskId == task.id),
        isTrue,
        reason: 'an overdue or reminder entry should exist for the task',
      );

      // The task itself should have been marked overdue.
      final loaded = await taskRepo.getById(task.id);
      expect(loaded!.status, TaskStatus.overdue);
    },
  );

  test('processDueNotifications does not duplicate the same day', () async {
    final deadline = DateTime.now().subtract(const Duration(minutes: 5));
    final task = buildTask(id: 't1', deadline: deadline);
    await taskRepo.insert(task);
    await service.syncTask(task: task, specs: const [ReminderSpec.before(60)]);

    await service.processDueNotifications();
    final firstCount = (await notificationRepo.watchAll().first).length;
    await service.processDueNotifications();
    final secondCount = (await notificationRepo.watchAll().first).length;

    expect(secondCount, firstCount);
  });
}
