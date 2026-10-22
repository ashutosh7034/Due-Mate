import 'package:duemate/core/utils/deadline_calculator.dart';
import 'package:duemate/models/enums.dart';
import 'package:duemate/models/task_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Countdown and Deadline Consistency across Screens', () {
    final now = DateTime(2026, 10, 13, 18, 45); // 6:45 PM
    final deadline = DateTime(2026, 10, 13, 18, 55); // 6:55 PM (10 mins away)

    final task = TaskItem(
      id: 'task-consistent-1',
      title: 'Submit quarterly report',
      priority: Priority.urgent,
      status: TaskStatus.notStarted,
      deadline: deadline,
      isRecurring: false,
      sortOrder: 0,
      recurrenceType: RecurrenceType.none,
      createdAt: now,
      updatedAt: now,
    );

    test('Authoritative countdown calculation produces identical duration & label across calls', () {
      final info1 = task.deadlineInfo(now: now);
      final info2 = DeadlineCalculator.compute(
        deadline: task.deadline,
        status: task.status,
        isOverdueFlag: task.isOverdue(now: now),
        now: now,
      );

      expect(info1.durationToDeadline, equals(const Duration(minutes: 10)));
      expect(info2.durationToDeadline, equals(const Duration(minutes: 10)));
      expect(info1.relativeLabel, equals(info2.relativeLabel));
      expect(info1.relativeLabel, equals('10m remaining'));
      expect(info1.bucket, equals(DeadlineBucket.dueToday));
    });

    test('Countdown advances consistently when clock ticks without database writes', () {
      // 8 minutes later (6:53 PM -> 2 minutes remaining)
      final eightMinutesLater = now.add(const Duration(minutes: 8));
      final infoLater = task.deadlineInfo(now: eightMinutesLater);

      expect(infoLater.durationToDeadline, equals(const Duration(minutes: 2)));
      expect(infoLater.relativeLabel, equals('2m remaining'));

      // 10 minutes later (6:55 PM -> 0 minutes / due now)
      final atDeadline = now.add(const Duration(minutes: 10));
      final infoAtDeadline = task.deadlineInfo(now: atDeadline);
      expect(infoAtDeadline.relativeLabel, equals('Due now'));

      // 15 minutes later (7:00 PM -> 5m overdue)
      final overdueTime = now.add(const Duration(minutes: 15));
      final infoOverdue = task.deadlineInfo(now: overdueTime);
      expect(infoOverdue.isOverdue, isTrue);
      expect(infoOverdue.relativeLabel, equals('Overdue by 5m'));
    });

    test(
      'UTC to local timezone conversion preserves the exact deadline instant',
      () {
        // Indian Standard Time: UTC+5:30
        // 6:55 PM IST = 13:25 UTC
        final deadlineUtc = DateTime.utc(2026, 10, 13, 13, 25);
        final taskWithUtc = task.copyWith(deadline: deadlineUtc);

        final clockIst = DateTime(2026, 10, 13, 18, 45); // 6:45 PM local
        final info = taskWithUtc.deadlineInfo(now: clockIst);

        expect(info.durationToDeadline, equals(const Duration(minutes: 10)));
        expect(info.relativeLabel, equals('10m remaining'));
      },
    );

    test('Rescheduled task deadline immediately recalculates countdown without parsing strings', () {
      final rescheduledDeadline = DateTime(2026, 10, 14, 18, 55); // Next day
      final updatedTask = task.copyWith(deadline: rescheduledDeadline);

      final info = updatedTask.deadlineInfo(now: now);
      expect(info.isDueTomorrow, isTrue);
      expect(
        info.durationToDeadline,
        equals(const Duration(hours: 24, minutes: 10)),
      );
    });

    test('Closed or completed task correctly reflects completed state without contradictory labels', () {
      final completedTask = task.copyWith(
        status: TaskStatus.completed,
        completedAt: now,
      );

      final info = completedTask.deadlineInfo(now: now);
      expect(info.relativeLabel, equals('Completed'));
      expect(info.bucket, equals(DeadlineBucket.closed));
    });
  });
}
