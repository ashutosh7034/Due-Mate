import 'package:duemate/models/app_notification.dart';
import 'package:duemate/models/enums.dart';
import 'package:duemate/models/reminder.dart';
import 'package:duemate/models/task_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Alerts Screen Filtering & Separation Logic', () {
    final now = DateTime(2026, 10, 13, 18, 45); // 6:45 PM
    final deadline = DateTime(2026, 10, 13, 18, 55); // 6:55 PM
    final overdueAt = DateTime(2026, 10, 13, 19, 5); // 7:05 PM

    final openTask = TaskItem(
      id: 'task-1',
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

    final completedTask = TaskItem(
      id: 'task-2',
      title: 'Completed assignment',
      priority: Priority.medium,
      status: TaskStatus.completed,
      deadline: now.subtract(const Duration(hours: 1)),
      isRecurring: false,
      sortOrder: 1,
      recurrenceType: RecurrenceType.none,
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now,
    );

    // Two scheduled reminders matching the user's scenario
    final reminderAtDeadline = TaskReminder(
      id: 'task-1:atDeadline:x:${deadline.millisecondsSinceEpoch}',
      taskId: openTask.id,
      kind: ReminderKind.atDeadline,
      scheduledAt: deadline,
      notificationId: 101,
      enabled: true,
      createdAt: now,
    );

    final reminderOverdue = TaskReminder(
      id: 'task-1:overdue:x:${overdueAt.millisecondsSinceEpoch}',
      taskId: openTask.id,
      kind: ReminderKind.overdue,
      scheduledAt: overdueAt,
      notificationId: 102,
      enabled: true,
      createdAt: now,
    );

    // One delivered historical notification record
    final deliveredHistory = AppNotification(
      id: 'notif-hist-1',
      taskId: completedTask.id,
      category: NotificationCategory.completed,
      title: 'Completed: Completed assignment',
      body: 'Task finished on time',
      createdAt: now.subtract(const Duration(minutes: 30)),
    );

    test('Active scheduled reminders for open tasks are recognized as upcoming and not empty', () {
      final allReminders = [reminderAtDeadline, reminderOverdue];
      final tasksMap = {openTask.id: openTask, completedTask.id: completedTask};

      final upcoming = allReminders.where((r) {
        if (!r.enabled) return false;
        final local = r.scheduledAt.isUtc
            ? r.scheduledAt.toLocal()
            : r.scheduledAt;
        if (!local.isAfter(now)) return false;
        final task = tasksMap[r.taskId];
        return task != null && !task.isCompleted;
      }).toList();

      expect(upcoming.length, equals(2));
      expect(upcoming[0].kind, equals(ReminderKind.atDeadline));
      expect(upcoming[0].scheduledAt, equals(deadline));
      expect(upcoming[1].kind, equals(ReminderKind.overdue));
      expect(upcoming[1].scheduledAt, equals(overdueAt));
    });

    test('Completed tasks do not show orphaned upcoming reminders', () {
      final closedTaskReminder = TaskReminder(
        id: 'closed-rem-1',
        taskId: completedTask.id,
        kind: ReminderKind.atDeadline,
        scheduledAt: deadline,
        notificationId: 201,
        enabled: true,
      );

      final allReminders = [closedTaskReminder];
      final tasksMap = {completedTask.id: completedTask};

      final upcoming = allReminders.where((r) {
        if (!r.enabled) return false;
        final local = r.scheduledAt.isUtc
            ? r.scheduledAt.toLocal()
            : r.scheduledAt;
        if (!local.isAfter(now)) return false;
        final task = tasksMap[r.taskId];
        return task != null && !task.isCompleted;
      }).toList();

      expect(upcoming, isEmpty);
    });

    test(
      'Delivered notifications and scheduled reminders are strictly segregated',
      () {
        expect(reminderAtDeadline.isDelivered, isFalse);
        expect(
          deliveredHistory.category,
          equals(NotificationCategory.completed),
        );

        final deliveredReminders = [reminderAtDeadline]
            .where((r) => r.isDelivered)
            .toList();
        expect(deliveredReminders, isEmpty);
      },
    );

    test('Due-soon filter correctly identifies tasks due within the due-soon window', () {
      final info = openTask.deadlineInfo(now: now);
      expect(info.isDueSoon, isTrue);
      expect(info.isDueToday, isTrue);
    });
  });
}
