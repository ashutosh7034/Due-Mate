import 'package:duemate/core/database/database.dart';
import 'package:duemate/core/notifications/reminder_planner.dart';
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
  late AppDatabase testDb;
  late TaskRepository taskRepo;
  late ReminderRepository reminderRepo;
  late NotificationRepository notifRepo;
  late SettingsRepository settingsRepo;
  late FakeNotificationService fakeNotifications;
  late ReminderService reminderService;

  setUp(() async {
    testDb = openTestDatabase();
    taskRepo = TaskRepository(testDb);
    reminderRepo = ReminderRepository(testDb);
    notifRepo = NotificationRepository(testDb);
    settingsRepo = SettingsRepository(testDb);
    fakeNotifications = FakeNotificationService();

    reminderService = ReminderService(
      notifications: fakeNotifications,
      reminders: reminderRepo,
      notificationCenter: notifRepo,
      tasks: taskRepo,
      settings: settingsRepo,
    );
  });

  tearDown(() async {
    await testDb.close();
  });

  group('Notification Scheduling, Cancellation & Rescheduling Regression', () {
    final now = DateTime.now();
    final deadline = now.add(const Duration(hours: 2));

    final task = TaskItem(
      id: 'task-sched-1',
      title: 'Submit report',
      priority: Priority.urgent,
      status: TaskStatus.notStarted,
      deadline: deadline,
      isRecurring: false,
      sortOrder: 0,
      recurrenceType: RecurrenceType.none,
      createdAt: now,
      updatedAt: now,
    );

    test(
      'Planning generates at-deadline and overdue reminders as requested',
      () {
        final specs = const [ReminderSpec.atDeadline()];
        final settings = const UserSettings(overdueRemindersEnabled: true);

        var idCounter = 1000;
        final planned = ReminderPlanner.plan(
          task: task,
          specs: specs,
          settings: settings,
          allocateId: () => idCounter++,
          now: now,
        );

        expect(planned.length, equals(2));
        expect(planned[0].kind, equals(ReminderKind.atDeadline));
        expect(planned[0].scheduledAt, equals(deadline));
        expect(planned[1].kind, equals(ReminderKind.overdue));
        expect(
          planned[1].scheduledAt,
          equals(deadline.add(const Duration(minutes: 10))),
        );
      },
    );

    test(
      'syncTask schedules OS alarms for future reminders and stores them in DB',
      () async {
        await taskRepo.insert(task);
        await reminderService.syncTask(
          task: task,
          specs: const [ReminderSpec.atDeadline()],
        );

        final stored = await reminderRepo.getForTask(task.id);
        expect(stored.isNotEmpty, isTrue);
        expect(
          fakeNotifications.scheduled.length,
          equals(stored.where((r) => r.isFuture).length),
        );
      },
    );

    test(
      'Rescheduling deadline cancels previous OS alarms and creates new ones',
      () async {
        await taskRepo.insert(task);
        await reminderService.syncTask(
          task: task,
          specs: const [ReminderSpec.atDeadline()],
        );

        final firstScheduledIds = fakeNotifications.scheduled
            .map((s) => s.notificationId)
            .toSet();
        expect(firstScheduledIds.isNotEmpty, isTrue);

        // Reschedule to tomorrow 6:55 PM
        final newDeadline = deadline.add(const Duration(days: 1));
        final updatedTask = task.copyWith(deadline: newDeadline);
        await taskRepo.update(updatedTask);
        await reminderService.syncTask(
          task: updatedTask,
          specs: const [ReminderSpec.atDeadline()],
        );

        // All initial alarm IDs must have been cancelled
        for (final id in firstScheduledIds) {
          expect(fakeNotifications.cancelled.contains(id), isTrue);
        }

        // New alarms are registered
        final currentScheduled = fakeNotifications.scheduled;
        expect(
          currentScheduled.any((s) => s.scheduledAt.day == newDeadline.day),
          isTrue,
        );
      },
    );

    test('Completing a task cancels all outstanding alarms and clears stored reminders', () async {
      await taskRepo.insert(task);
      await reminderService.syncTask(
        task: task,
        specs: const [ReminderSpec.atDeadline()],
      );

      expect(fakeNotifications.scheduled.isNotEmpty, isTrue);

      final completedTask = task.copyWith(status: TaskStatus.completed);
      await reminderService.syncTask(task: completedTask, specs: const []);

      final stored = await reminderRepo.getForTask(task.id);
      expect(stored, isEmpty);
      expect(fakeNotifications.cancelled.length, greaterThanOrEqualTo(1));
    });
  });
}
