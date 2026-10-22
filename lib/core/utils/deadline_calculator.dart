import '../../models/enums.dart';
import 'date_x.dart';

/// A coarse bucket describing where a deadline sits relative to "now".
enum DeadlineBucket {
  /// No deadline set.
  none,

  /// Closed (completed/cancelled) — bucket does not apply.
  closed,

  /// Deadline has passed and the task is still open.
  overdue,

  /// Deadline falls later today.
  dueToday,

  /// Deadline falls tomorrow.
  dueTomorrow,

  /// Within the next 7 days.
  thisWeek,

  /// Anything further out.
  upcoming,
}

/// Immutable, computed view of a task's deadline.
///
/// This is the single place deadline semantics live, so the UI, the
/// notification service and the dashboard can never disagree.
class DeadlineInfo {
  const DeadlineInfo({
    required this.deadline,
    required this.bucket,
    required this.durationToDeadline,
  });

  final DateTime? deadline;
  final DeadlineBucket bucket;

  /// Negative when the deadline has passed.
  final Duration durationToDeadline;

  bool get hasDeadline => deadline != null;

  bool get isOverdue => bucket == DeadlineBucket.overdue;

  bool get isDueToday => bucket == DeadlineBucket.dueToday;

  bool get isDueTomorrow => bucket == DeadlineBucket.dueTomorrow;

  bool get isDueSoon =>
      bucket == DeadlineBucket.overdue ||
      bucket == DeadlineBucket.dueToday ||
      bucket == DeadlineBucket.dueTomorrow;

  /// True when the deadline is within [within].
  bool isWithin(Duration within) => durationToDeadline <= within;

  /// "Overdue by 2h 15m" / "2 days remaining" / "Due now".
  String get relativeLabel {
    if (deadline == null) return 'No deadline';
    // A closed task still shows its deadline below; the label should not
    // contradict it by claiming there is none.
    if (bucket == DeadlineBucket.closed) return 'Completed';

    final remaining = durationToDeadline;
    if (remaining.isNegative) {
      return 'Overdue by ${DurationFormat.compact(remaining)}';
    }
    if (remaining.inSeconds <= 30) return 'Due now';
    return '${DurationFormat.compact(remaining)} remaining';
  }

  /// Sentence form: "overdue by 2 hours", "in 5 hours".
  String get sentenceLabel {
    if (deadline == null) return 'No deadline';
    final remaining = durationToDeadline;
    if (remaining.isNegative) {
      return 'overdue by ${DurationFormat.verbose(remaining)}';
    }
    if (remaining.inSeconds <= 30) return 'due now';
    return 'in ${DurationFormat.verbose(remaining)}';
  }

  /// Calendar-aware label: "Today, 10:00 AM", "Tomorrow, 7:00 PM".
  String get calendarLabel {
    if (deadline == null) return 'No deadline';
    return AppDateFormat.relativeDayTime(deadline!);
  }

  @override
  String toString() =>
      'DeadlineInfo(deadline: $deadline, bucket: $bucket, remaining: $durationToDeadline)';
}

/// Pure functions computing deadline state. Kept free of Flutter/DB imports so
/// they are trivially unit-testable.
class DeadlineCalculator {
  const DeadlineCalculator._();

  /// Computes the [DeadlineInfo] for a task-like record.
  ///
  /// [now] is injectable so tests are deterministic.
  static DeadlineInfo compute({
    required DateTime? deadline,
    required TaskStatus status,
    required bool isOverdueFlag,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();

    if (deadline == null) {
      return DeadlineInfo(
        deadline: null,
        bucket: status.isClosed && !isOverdueFlag
            ? DeadlineBucket.closed
            : DeadlineBucket.none,
        durationToDeadline: Duration.zero,
      );
    }

    final localDeadline = deadline.isUtc ? deadline.toLocal() : deadline;
    final remaining = localDeadline.difference(clock);

    if (status.isClosed && !isOverdueFlag) {
      return DeadlineInfo(
        deadline: localDeadline,
        bucket: DeadlineBucket.closed,
        durationToDeadline: remaining,
      );
    }

    // Calendar comparisons are made against the injected clock (not
    // DateTime.now()) so behaviour is identical in tests and at runtime.
    final today = DateTime(clock.year, clock.month, clock.day);
    final deadlineDay = DateTime(
      localDeadline.year,
      localDeadline.month,
      localDeadline.day,
    );
    final dayDelta = deadlineDay.difference(today).inDays;

    final DeadlineBucket bucket;
    if (remaining.isNegative) {
      bucket = DeadlineBucket.overdue;
    } else if (dayDelta == 0) {
      bucket = DeadlineBucket.dueToday;
    } else if (dayDelta == 1) {
      bucket = DeadlineBucket.dueTomorrow;
    } else if (dayDelta < 7) {
      bucket = DeadlineBucket.thisWeek;
    } else {
      bucket = DeadlineBucket.upcoming;
    }

    return DeadlineInfo(
      deadline: localDeadline,
      bucket: bucket,
      durationToDeadline: remaining,
    );
  }

  /// Whether an *open* task with this deadline should be marked overdue.
  ///
  /// Completed/cancelled tasks are never overdue.
  static bool isOverdue({
    required DateTime? deadline,
    required TaskStatus status,
    DateTime? now,
  }) {
    if (deadline == null || status.isClosed) return false;
    final clock = now ?? DateTime.now();
    final local = deadline.isUtc ? deadline.toLocal() : deadline;
    return local.isBefore(clock);
  }

  /// The effective status to persist for a task at a point in time.
  ///
  /// Does **not** auto-complete a task whose deadline passed; it only flips
  /// between overdue and the task's own open status.
  static TaskStatus effectiveStatus({
    required TaskStatus current,
    required DateTime? deadline,
    DateTime? now,
  }) {
    if (current.isClosed) return current;
    if (isOverdue(deadline: deadline, status: current, now: now)) {
      return TaskStatus.overdue;
    }
    // A previously overdue task that was rescheduled into the future returns
    // to not-started (in-progress is preserved below).
    if (current == TaskStatus.overdue) return TaskStatus.notStarted;
    return current;
  }

  /// A sensible short action phrase for the dashboard.
  static String urgencyHint(DeadlineInfo info) {
    if (!info.hasDeadline) return 'No deadline';
    switch (info.bucket) {
      case DeadlineBucket.overdue:
        return 'Overdue';
      case DeadlineBucket.dueToday:
        return 'Due today';
      case DeadlineBucket.dueTomorrow:
        return 'Due tomorrow';
      case DeadlineBucket.thisWeek:
        return 'This week';
      case DeadlineBucket.upcoming:
        return 'Upcoming';
      case DeadlineBucket.closed:
        return 'Completed';
      case DeadlineBucket.none:
        return 'No deadline';
    }
  }
}
