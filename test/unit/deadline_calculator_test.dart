import 'package:duemate/core/utils/deadline_calculator.dart';
import 'package:duemate/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A fixed "now": Wednesday 8 Oct 2026, 10:00.
  final now = DateTime(2026, 10, 8, 10, 0);

  group('DeadlineCalculator.compute', () {
    test('no deadline yields the none bucket', () {
      final info = DeadlineCalculator.compute(
        deadline: null,
        status: TaskStatus.notStarted,
        isOverdueFlag: false,
        now: now,
      );
      expect(info.hasDeadline, isFalse);
      expect(info.bucket, DeadlineBucket.none);
    });

    test('scenario 1 — due tomorrow is Upcoming/tomorrow', () {
      final info = DeadlineCalculator.compute(
        deadline: DateTime(2026, 10, 9, 18, 0),
        status: TaskStatus.notStarted,
        isOverdueFlag: false,
        now: now,
      );
      expect(info.bucket, DeadlineBucket.dueTomorrow);
      expect(info.isDueTomorrow, isTrue);
      expect(info.isOverdue, isFalse);
    });

    test('scenario 2 — due later today is Due today', () {
      final info = DeadlineCalculator.compute(
        deadline: DateTime(2026, 10, 8, 19, 0),
        status: TaskStatus.notStarted,
        isOverdueFlag: false,
        now: now,
      );
      expect(info.bucket, DeadlineBucket.dueToday);
      expect(info.isDueToday, isTrue);
    });

    test('scenario 3 — passed deadline is Overdue', () {
      final info = DeadlineCalculator.compute(
        deadline: DateTime(2026, 10, 8, 7, 45),
        status: TaskStatus.notStarted,
        isOverdueFlag: false,
        now: now,
      );
      expect(info.bucket, DeadlineBucket.overdue);
      expect(info.isOverdue, isTrue);
      expect(info.relativeLabel, startsWith('Overdue by'));
      expect(info.relativeLabel, contains('2h'));
    });

    test('a completed task is not overdue even when the deadline passed', () {
      final info = DeadlineCalculator.compute(
        deadline: DateTime(2026, 10, 1, 9, 0),
        status: TaskStatus.completed,
        isOverdueFlag: false,
        now: now,
      );
      expect(info.bucket, DeadlineBucket.closed);
      expect(info.isOverdue, isFalse);
    });

    test('this-week bucket for 3 days out', () {
      final info = DeadlineCalculator.compute(
        deadline: DateTime(2026, 10, 11, 12, 0),
        status: TaskStatus.notStarted,
        isOverdueFlag: false,
        now: now,
      );
      expect(info.bucket, DeadlineBucket.thisWeek);
    });

    test('upcoming bucket for far dates', () {
      final info = DeadlineCalculator.compute(
        deadline: DateTime(2026, 11, 20, 12, 0),
        status: TaskStatus.notStarted,
        isOverdueFlag: false,
        now: now,
      );
      expect(info.bucket, DeadlineBucket.upcoming);
    });
  });

  group('DeadlineCalculator.isOverdue', () {
    test('false for completed or cancelled tasks', () {
      expect(
        DeadlineCalculator.isOverdue(
          deadline: DateTime(2020),
          status: TaskStatus.completed,
          now: now,
        ),
        isFalse,
      );
      expect(
        DeadlineCalculator.isOverdue(
          deadline: DateTime(2020),
          status: TaskStatus.cancelled,
          now: now,
        ),
        isFalse,
      );
    });

    test('true for an open task past its deadline', () {
      expect(
        DeadlineCalculator.isOverdue(
          deadline: DateTime(2026, 10, 8, 9, 59),
          status: TaskStatus.notStarted,
          now: now,
        ),
        isTrue,
      );
    });
  });

  group('DeadlineCalculator.effectiveStatus', () {
    test('flips an open task to overdue once the deadline passes', () {
      expect(
        DeadlineCalculator.effectiveStatus(
          current: TaskStatus.notStarted,
          deadline: DateTime(2026, 10, 8, 9, 0),
          now: now,
        ),
        TaskStatus.overdue,
      );
    });

    test('does not auto-complete a task whose deadline passed', () {
      final status = DeadlineCalculator.effectiveStatus(
        current: TaskStatus.inProgress,
        deadline: DateTime(2026, 10, 8, 9, 0),
        now: now,
      );
      expect(status, isNot(TaskStatus.completed));
      expect(status, TaskStatus.overdue);
    });

    test('rescheduling an overdue task clears the overdue status', () {
      expect(
        DeadlineCalculator.effectiveStatus(
          current: TaskStatus.overdue,
          deadline: DateTime(2026, 10, 20, 12, 0),
          now: now,
        ),
        TaskStatus.notStarted,
      );
    });

    test('leaves closed tasks untouched', () {
      expect(
        DeadlineCalculator.effectiveStatus(
          current: TaskStatus.completed,
          deadline: DateTime(2026, 10, 8, 9, 0),
          now: now,
        ),
        TaskStatus.completed,
      );
    });
  });

  group('relative labels', () {
    test('minutes remaining', () {
      final info = DeadlineCalculator.compute(
        deadline: now.add(const Duration(minutes: 45)),
        status: TaskStatus.notStarted,
        isOverdueFlag: false,
        now: now,
      );
      expect(info.relativeLabel, '45m remaining');
      expect(info.sentenceLabel, 'in 45 minutes');
    });

    test('overdue label uses compact duration', () {
      final info = DeadlineCalculator.compute(
        deadline: now.subtract(const Duration(hours: 2, minutes: 15)),
        status: TaskStatus.notStarted,
        isOverdueFlag: false,
        now: now,
      );
      expect(info.relativeLabel, 'Overdue by 2h 15m');
    });
  });
}
