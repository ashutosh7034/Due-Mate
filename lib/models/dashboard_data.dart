import 'package:equatable/equatable.dart';

import 'task_item.dart';

/// Everything the dashboard needs, computed once from the task list.
///
/// This is a *derived* view — it never mutates task ordering in the database.
class DashboardData extends Equatable {
  const DashboardData({
    required this.overdue,
    required this.dueToday,
    required this.upcoming,
    required this.completedToday,
    required this.totalOpen,
    required this.highPriorityCount,
    this.nextDeadline,
  });

  final List<TaskItem> overdue;
  final List<TaskItem> dueToday;
  final List<TaskItem> upcoming;
  final List<TaskItem> completedToday;
  final int totalOpen;
  final int highPriorityCount;
  final TaskItem? nextDeadline;

  bool get isEmpty =>
      overdue.isEmpty &&
      dueToday.isEmpty &&
      upcoming.isEmpty &&
      completedToday.isEmpty;

  bool get hasAnythingOpen =>
      overdue.isNotEmpty || dueToday.isNotEmpty || upcoming.isNotEmpty;

  int get openTodayCount => dueToday.length + overdue.length;

  static const empty = DashboardData(
    overdue: [],
    dueToday: [],
    upcoming: [],
    completedToday: [],
    totalOpen: 0,
    highPriorityCount: 0,
  );

  @override
  List<Object?> get props => [
    overdue,
    dueToday,
    upcoming,
    completedToday,
    totalOpen,
    highPriorityCount,
    nextDeadline,
  ];
}

/// Today's at-a-glance numbers for the "Daily summary" card.
class DailySummary extends Equatable {
  const DailySummary({
    required this.total,
    required this.overdue,
    required this.highPriority,
    required this.normal,
    required this.completed,
    this.nextDeadline,
  });

  final int total;
  final int overdue;
  final int highPriority;
  final int normal;
  final int completed;
  final TaskItem? nextDeadline;

  static const empty = DailySummary(
    total: 0,
    overdue: 0,
    highPriority: 0,
    normal: 0,
    completed: 0,
  );

  @override
  List<Object?> get props => [
    total,
    overdue,
    highPriority,
    normal,
    completed,
    nextDeadline,
  ];
}
