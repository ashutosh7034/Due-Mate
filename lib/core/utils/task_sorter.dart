import '../../models/dashboard_data.dart';
import '../../models/enums.dart';
import '../../models/task_item.dart';
import '../../repositories/task_repository.dart';
import 'date_x.dart';
import 'deadline_calculator.dart';

/// Presentation-level ordering and bucketing of tasks.
///
/// Sort order for display only — the database is never reordered.
class TaskSorter {
  const TaskSorter._();

  /// Dashboard priority: overdue → urgent → due soon → high → upcoming.
  static List<TaskItem> byUrgency(List<TaskItem> tasks, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final sorted = [...tasks];
    sorted.sort((a, b) {
      final bucketA = _bucketRank(a, clock);
      final bucketB = _bucketRank(b, clock);
      if (bucketA != bucketB) return bucketA.compareTo(bucketB);

      // Same bucket: more urgent priority first.
      final priority = a.priority.weight.compareTo(b.priority.weight);
      if (priority != 0) return priority;

      // Then soonest deadline, with deadline-less tasks last.
      final da = a.deadline;
      final db = b.deadline;
      if (da == null && db == null) return a.createdAt.compareTo(b.createdAt);
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
    return sorted;
  }

  static int _bucketRank(TaskItem task, DateTime now) {
    if (task.isOverdue(now: now)) return 0;
    if (task.priority == Priority.urgent) return 1;
    final info = task.deadlineInfo(now: now);
    switch (info.bucket) {
      case DeadlineBucket.dueToday:
        return 2;
      case DeadlineBucket.dueTomorrow:
        return 3;
      case DeadlineBucket.thisWeek:
        return 4;
      case DeadlineBucket.upcoming:
        return 5;
      case DeadlineBucket.none:
        return 7;
      case DeadlineBucket.overdue:
        return 0;
      case DeadlineBucket.closed:
        return 6;
    }
  }

  /// Builds the dashboard buckets from the full (open + completed) task list.
  static DashboardData dashboard(List<TaskItem> tasks, DateTime now) {
    final open = tasks.where((t) => !t.isClosed).toList();
    final overdue = <TaskItem>[];
    final dueToday = <TaskItem>[];
    final upcoming = <TaskItem>[];
    var highPriority = 0;

    final todayStart = now.startOfDay;
    final todayEnd = now.endOfDay;

    for (final task in open) {
      if (task.priority.isImportant) highPriority++;

      if (task.isOverdue(now: now)) {
        overdue.add(task);
        continue;
      }
      final deadline = task.deadline;
      if (deadline == null) continue;

      if (!deadline.isBefore(todayStart) && !deadline.isAfter(todayEnd)) {
        dueToday.add(task);
      } else if (deadline.isAfter(todayEnd)) {
        upcoming.add(task);
      }
    }

    final completedToday = tasks
        .where(
          (t) =>
              t.status == TaskStatus.completed &&
              t.completedAt != null &&
              t.completedAt!.isSameDay(now),
        )
        .toList();

    final orderedOverdue = byUrgency(overdue, now: now);
    final orderedToday = byUrgency(dueToday, now: now);
    final orderedUpcoming = byUrgency(upcoming, now: now);

    TaskItem? next;
    for (final candidate in [...orderedToday, ...orderedUpcoming]) {
      if (candidate.deadline != null && candidate.deadline!.isAfter(now)) {
        next = candidate;
        break;
      }
    }

    return DashboardData(
      overdue: orderedOverdue,
      dueToday: orderedToday,
      upcoming: orderedUpcoming.take(5).toList(),
      completedToday: completedToday,
      totalOpen: open.length,
      highPriorityCount: highPriority,
      nextDeadline: next,
    );
  }

  /// Aggregates today's numbers for the daily summary card.
  ///
  /// Overdue tasks are counted **once** — they are excluded from the
  /// "today" bucket so [total] never double-counts them.
  static DailySummary dailySummary(List<TaskItem> tasks, DateTime now) {
    final overdue = tasks.where((t) => t.isOverdue(now: now)).toList();
    final overdueIds = overdue.map((t) => t.id).toSet();

    final today = tasks
        .where(
          (t) =>
              !t.isClosed &&
              !overdueIds.contains(t.id) &&
              t.deadline != null &&
              t.deadline!.isSameDay(now),
        )
        .toList();

    final high = today.where((t) => t.priority.isImportant).length;
    final normal = today.length - high;
    final completed = tasks
        .where(
          (t) =>
              t.status == TaskStatus.completed &&
              t.completedAt != null &&
              t.completedAt!.isSameDay(now),
        )
        .length;

    final upcoming =
        tasks
            .where(
              (t) =>
                  !t.isClosed && t.deadline != null && t.deadline!.isAfter(now),
            )
            .toList()
          ..sort((a, b) => a.deadline!.compareTo(b.deadline!));

    return DailySummary(
      total: today.length + overdue.length,
      overdue: overdue.length,
      highPriority: high,
      normal: normal,
      completed: completed,
      nextDeadline: upcoming.isEmpty ? null : upcoming.first,
    );
  }

  /// Comparator matching a [TaskSort] option for in-memory re-sorting.
  static int Function(TaskItem, TaskItem) comparator(TaskSort sort) {
    switch (sort) {
      case TaskSort.deadline:
        return (a, b) {
          if (a.deadline == null && b.deadline == null) {
            return a.createdAt.compareTo(b.createdAt);
          }
          if (a.deadline == null) return 1;
          if (b.deadline == null) return -1;
          return a.deadline!.compareTo(b.deadline!);
        };
      case TaskSort.priority:
        return (a, b) {
          final p = a.priority.weight.compareTo(b.priority.weight);
          if (p != 0) return p;
          if (a.deadline == null && b.deadline == null) return 0;
          if (a.deadline == null) return 1;
          if (b.deadline == null) return -1;
          return a.deadline!.compareTo(b.deadline!);
        };
      case TaskSort.created:
        return (a, b) => b.createdAt.compareTo(a.createdAt);
      case TaskSort.category:
        return (a, b) {
          final ac = a.categoryId ?? '~';
          final bc = b.categoryId ?? '~';
          final c = ac.compareTo(bc);
          if (c != 0) return c;
          if (a.deadline == null && b.deadline == null) return 0;
          if (a.deadline == null) return 1;
          if (b.deadline == null) return -1;
          return a.deadline!.compareTo(b.deadline!);
        };
    }
  }
}
