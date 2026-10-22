import '../../models/enums.dart';
import '../../models/reminder.dart';
import '../../models/task_item.dart';
import '../../models/user_settings.dart';

/// Pure planning logic: turns a task + requested reminder specs into concrete,
/// de-duplicated [TaskReminder] rows.
///
/// Contains **no** platform or database code so all of the tricky rules
/// (busy-hours nudging, critical-reminder protection, de-duplication) can be
/// unit tested deterministically.
class ReminderPlanner {
  const ReminderPlanner._();

  /// Delay after the deadline before the single overdue nudge.
  ///
  /// Deliberately not immediate: the at-deadline alert already fired, so a
  /// short grace period keeps the overdue nudge from feeling like spam.
  static const Duration overdueDelay = Duration(minutes: 10);

  /// Builds the reminder rows for [task].
  ///
  /// [allocateId] must return a unique, positive 32-bit notification id.
  /// [now] is injectable for tests.
  static List<TaskReminder> plan({
    required TaskItem task,
    required List<ReminderSpec> specs,
    required UserSettings settings,
    required int Function() allocateId,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final deadline = task.deadline;
    if (deadline == null) return const [];

    final localDeadline = deadline.isUtc ? deadline.toLocal() : deadline;

    final resolved = <_ResolvedSpec>[];
    for (final spec in specs) {
      final at = _resolveTime(spec, localDeadline);
      if (at == null) continue;
      resolved.add(_ResolvedSpec(spec: spec, at: at));
    }

    // Mark the last "before" reminder and the at-deadline reminder as critical.
    final beforeSpecs =
        resolved
            .where((r) => r.spec.kind == ReminderKind.beforeDeadline)
            .toList()
          ..sort((a, b) => a.at.compareTo(b.at));
    final criticalIds = <ReminderSpec>{};
    if (beforeSpecs.isNotEmpty) {
      criticalIds.add(beforeSpecs.last.spec); // closest to the deadline
    }
    for (final r in resolved) {
      if (r.spec.kind == ReminderKind.atDeadline) criticalIds.add(r.spec);
    }

    // Apply busy hours only to optional reminders, never to critical ones.
    final adjusted = resolved.map((r) {
      final isCritical = criticalIds.contains(r.spec);
      final at = _applyBusyHours(
        original: r.at,
        deadline: localDeadline,
        settings: settings,
        isCritical: isCritical,
      );
      return _ResolvedSpec(spec: r.spec, at: at);
    }).toList();

    // Overdue nudge (only if enabled and it would fire in the future).
    final effectiveSpecs = [...adjusted];
    if (settings.overdueRemindersEnabled) {
      effectiveSpecs.add(
        _ResolvedSpec(
          spec: const ReminderSpec(
            kind: ReminderKind.overdue,
            minutesBefore: null,
          ),
          at: localDeadline.add(overdueDelay),
        ),
      );
    }

    // De-duplicate identical fire times (a very common user mistake), keeping
    // the more "important" kind.
    final byTime = <int, _ResolvedSpec>{};
    for (final r in effectiveSpecs) {
      final key = r.at.millisecondsSinceEpoch;
      final existing = byTime[key];
      if (existing == null || _rank(r.spec.kind) < _rank(existing.spec.kind)) {
        byTime[key] = r;
      }
    }

    final planned = byTime.values.toList()
      ..sort((a, b) => a.at.compareTo(b.at));

    return [
      for (final r in planned)
        TaskReminder(
          id: '${task.id}:${r.spec.kind.name}:${r.spec.minutesBefore ?? 'x'}:${r.at.millisecondsSinceEpoch}',
          taskId: task.id,
          kind: r.spec.kind,
          minutesBefore: r.spec.minutesBefore,
          scheduledAt: r.at,
          notificationId: allocateId(),
          enabled: r.at.isAfter(clock),
          createdAt: clock,
        ),
    ];
  }

  static DateTime? _resolveTime(ReminderSpec spec, DateTime deadline) {
    switch (spec.kind) {
      case ReminderKind.beforeDeadline:
        final minutes = spec.minutesBefore;
        if (minutes == null) return null;
        return deadline.subtract(Duration(minutes: minutes));
      case ReminderKind.atDeadline:
        return deadline;
      case ReminderKind.custom:
        return spec.customAt;
      case ReminderKind.overdue:
        return deadline.add(overdueDelay);
    }
  }

  /// If an optional reminder lands inside busy hours, nudge it to the end of
  /// the busy window — unless that would push it past the deadline, in which
  /// case it is left alone (better early-ish than after the deadline).
  static DateTime _applyBusyHours({
    required DateTime original,
    required DateTime deadline,
    required UserSettings settings,
    required bool isCritical,
  }) {
    if (isCritical || !settings.busyHoursEnabled) return original;
    if (!_withinBusyHours(original, settings)) return original;

    final end = DateTime(
      original.year,
      original.month,
      original.day,
      settings.busyEndHour,
    );
    // If the busy window crosses midnight, the end is the next morning.
    final endAdjusted = end.isAfter(original)
        ? end
        : end.add(const Duration(days: 1));
    if (endAdjusted.isBefore(deadline)) {
      return endAdjusted;
    }
    return original;
  }

  static bool _withinBusyHours(DateTime at, UserSettings settings) {
    final hour = at.hour;
    final start = settings.busyStartHour;
    final end = settings.busyEndHour;
    if (start == end) return false;
    if (start < end) {
      return hour >= start && hour < end;
    }
    // Window wraps past midnight.
    return hour >= start || hour < end;
  }

  static int _rank(ReminderKind kind) => switch (kind) {
    ReminderKind.overdue => 0,
    ReminderKind.atDeadline => 1,
    ReminderKind.beforeDeadline => 2,
    ReminderKind.custom => 3,
  };
}

class _ResolvedSpec {
  const _ResolvedSpec({required this.spec, required this.at});
  final ReminderSpec spec;
  final DateTime at;
}
