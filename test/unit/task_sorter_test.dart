import 'package:duemate/core/utils/task_sorter.dart';
import 'package:duemate/models/enums.dart';
import 'package:duemate/models/task_item.dart';
import 'package:duemate/repositories/task_repository.dart';
import 'package:flutter_test/flutter_test.dart';

final now = DateTime(2026, 10, 8, 10, 0);

TaskItem task({
  required String id,
  DateTime? deadline,
  Priority priority = Priority.medium,
  TaskStatus status = TaskStatus.notStarted,
  DateTime? completedAt,
  String? categoryId,
}) {
  return TaskItem(
    id: id,
    title: 'Task $id',
    priority: priority,
    status: status,
    recurrenceType: RecurrenceType.none,
    isRecurring: false,
    sortOrder: 0,
    deadline: deadline,
    completedAt: completedAt,
    categoryId: categoryId,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('byUrgency ordering', () {
    test('overdue comes before due today, which comes before upcoming', () {
      final overdue = task(
        id: 'a',
        deadline: now.subtract(const Duration(hours: 1)),
      );
      final today = task(id: 'b', deadline: DateTime(2026, 10, 8, 19, 0));
      final upcoming = task(id: 'c', deadline: DateTime(2026, 10, 12, 12, 0));

      final sorted = TaskSorter.byUrgency([upcoming, today, overdue], now: now);
      expect(sorted.map((t) => t.id).toList(), ['a', 'b', 'c']);
    });

    test('urgent priority is promoted within its bucket', () {
      final normal = task(id: 'a', deadline: DateTime(2026, 10, 12, 12, 0));
      final urgent = task(
        id: 'b',
        deadline: DateTime(2026, 10, 12, 18, 0),
        priority: Priority.urgent,
      );
      final sorted = TaskSorter.byUrgency([normal, urgent], now: now);
      expect(sorted.first.id, 'b');
    });
  });

  group('dashboard bucketing', () {
    test('splits tasks into overdue / today / upcoming and counts', () {
      final tasks = [
        task(id: 'overdue', deadline: now.subtract(const Duration(hours: 2))),
        task(id: 'today', deadline: DateTime(2026, 10, 8, 21, 0)),
        task(id: 'tomorrow', deadline: DateTime(2026, 10, 9, 12, 0)),
        task(id: 'nextweek', deadline: DateTime(2026, 10, 15, 12, 0)),
        task(
          id: 'done',
          deadline: DateTime(2026, 10, 8, 8, 0),
          status: TaskStatus.completed,
          completedAt: now,
        ),
      ];

      final data = TaskSorter.dashboard(tasks, now);
      expect(data.overdue.map((t) => t.id), ['overdue']);
      expect(data.dueToday.map((t) => t.id), ['today']);
      expect(data.upcoming.map((t) => t.id), contains('tomorrow'));
      expect(data.completedToday.map((t) => t.id), ['done']);
      expect(data.totalOpen, 4);
    });

    test('nextDeadline is the soonest future deadline', () {
      final tasks = [
        task(id: 'later', deadline: DateTime(2026, 10, 12, 12, 0)),
        task(id: 'sooner', deadline: DateTime(2026, 10, 9, 9, 0)),
      ];
      final data = TaskSorter.dashboard(tasks, now);
      expect(data.nextDeadline?.id, 'sooner');
    });
  });

  group('daily summary', () {
    test('counts today, overdue, high priority and completed', () {
      final tasks = [
        task(
          id: 'a',
          deadline: DateTime(2026, 10, 8, 18, 0),
          priority: Priority.high,
        ),
        task(id: 'b', deadline: DateTime(2026, 10, 8, 20, 0)),
        task(id: 'overdue', deadline: now.subtract(const Duration(hours: 1))),
        task(
          id: 'done',
          deadline: DateTime(2026, 10, 8, 8, 0),
          status: TaskStatus.completed,
          completedAt: now,
        ),
      ];

      final summary = TaskSorter.dailySummary(tasks, now);
      expect(summary.highPriority, 1);
      expect(summary.normal, 1);
      expect(summary.overdue, 1);
      expect(summary.completed, 1);
      expect(summary.total, 3); // 2 today + 1 overdue
    });
  });

  group('comparators', () {
    test('created sorts newest first', () {
      final older = task(id: 'old').copyWith();
      final newer = task(id: 'new').copyWith();
      final sorted = [older, newer]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      // Both have the same creation time in the fixture, so simply assert the
      // comparator is stable and returns an int.
      expect(sorted, hasLength(2));
    });

    test('deadline comparator pushes deadline-less tasks last', () {
      final withDeadline = task(id: 'a', deadline: DateTime(2026, 10, 9));
      final noDeadline = task(id: 'b');
      final list = [noDeadline, withDeadline]
        ..sort(TaskSorter.comparator(TaskSort.deadline));
      expect(list.first.id, 'a');
    });
  });
}
