import 'package:equatable/equatable.dart';

import 'enums.dart';

/// Immutable domain model for a scheduled reminder.
class TaskReminder extends Equatable {
  const TaskReminder({
    required this.id,
    required this.taskId,
    required this.kind,
    required this.scheduledAt,
    required this.notificationId,
    this.minutesBefore,
    this.enabled = true,
    this.notifiedAt,
    this.createdAt,
  });

  final String id;
  final String taskId;
  final ReminderKind kind;

  /// Only set for [ReminderKind.beforeDeadline].
  final int? minutesBefore;

  /// Absolute fire time (local).
  final DateTime scheduledAt;

  /// OS notification id used to schedule/cancel this reminder.
  final int notificationId;
  final bool enabled;

  /// When the app confirmed this reminder's moment passed.
  final DateTime? notifiedAt;
  final DateTime? createdAt;

  bool get isFuture => scheduledAt.isAfter(DateTime.now());

  bool get isDelivered => notifiedAt != null;

  /// Human label, e.g. "1 day before", "At deadline".
  String get label => ReminderPresets.labelFor(this);

  TaskReminder copyWith({
    Object? minutesBefore = _sentinel,
    DateTime? scheduledAt,
    int? notificationId,
    bool? enabled,
    Object? notifiedAt = _sentinel,
    ReminderKind? kind,
  }) {
    return TaskReminder(
      id: id,
      taskId: taskId,
      kind: kind ?? this.kind,
      minutesBefore: identical(minutesBefore, _sentinel)
          ? this.minutesBefore
          : minutesBefore as int?,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      notificationId: notificationId ?? this.notificationId,
      enabled: enabled ?? this.enabled,
      notifiedAt: identical(notifiedAt, _sentinel)
          ? this.notifiedAt
          : notifiedAt as DateTime?,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    taskId,
    kind,
    minutesBefore,
    scheduledAt,
    notificationId,
    enabled,
    notifiedAt,
    createdAt,
  ];
}

const Object _sentinel = Object();

/// A *requested* reminder, before it is materialised into a scheduled time.
///
/// The task editor produces specs; [ReminderService] turns them into persisted
/// [TaskReminder] rows with concrete `scheduledAt` values.
class ReminderSpec extends Equatable {
  const ReminderSpec({required this.kind, this.minutesBefore, this.customAt});

  const ReminderSpec.atDeadline()
    : kind = ReminderKind.atDeadline,
      minutesBefore = null,
      customAt = null;

  const ReminderSpec.before(int minutes)
    : kind = ReminderKind.beforeDeadline,
      minutesBefore = minutes,
      customAt = null;

  final ReminderKind kind;
  final int? minutesBefore;
  final DateTime? customAt;

  /// Whether this reminder may be nudged by busy hours.
  ///
  /// The *last* reminder before a deadline (and the deadline itself) is
  /// considered critical and is never moved or dropped.
  bool get isOptional =>
      kind == ReminderKind.beforeDeadline && (minutesBefore ?? 0) >= 60;

  @override
  List<Object?> get props => [kind, minutesBefore, customAt];
}

/// A single selectable reminder option.
class ReminderPreset extends Equatable {
  const ReminderPreset({
    required this.label,
    required this.minutesBefore,
    this.kind = ReminderKind.beforeDeadline,
  });

  final String label;

  /// Null for the "at deadline" / "custom" presets.
  final int? minutesBefore;
  final ReminderKind kind;

  @override
  List<Object?> get props => [label, minutesBefore, kind];
}

/// Canonical reminder presets offered in the task editor.
class ReminderPresets {
  const ReminderPresets._();

  static const ReminderPreset atDeadline = ReminderPreset(
    label: 'At deadline',
    minutesBefore: null,
    kind: ReminderKind.atDeadline,
  );

  static const List<ReminderPreset> standard = [
    ReminderPreset(label: '5 minutes before', minutesBefore: 5),
    ReminderPreset(label: '15 minutes before', minutesBefore: 15),
    ReminderPreset(label: '30 minutes before', minutesBefore: 30),
    ReminderPreset(label: '1 hour before', minutesBefore: 60),
    ReminderPreset(label: '3 hours before', minutesBefore: 180),
    ReminderPreset(label: '1 day before', minutesBefore: 1440),
    atDeadline,
  ];

  /// Default offset for new tasks, in minutes (1 hour).
  static const int defaultMinutesBefore = 60;

  static ReminderPreset? byMinutes(int? minutes) {
    if (minutes == null) return atDeadline;
    for (final p in standard) {
      if (p.minutesBefore == minutes) return p;
    }
    return null;
  }

  static String labelFor(TaskReminder reminder) {
    switch (reminder.kind) {
      case ReminderKind.atDeadline:
        return 'At deadline';
      case ReminderKind.overdue:
        return 'After deadline';
      case ReminderKind.custom:
        return 'Custom time';
      case ReminderKind.beforeDeadline:
        final preset = byMinutes(reminder.minutesBefore);
        if (preset != null) return preset.label;
        final minutes = reminder.minutesBefore ?? 0;
        if (minutes % 1440 == 0) {
          final days = minutes ~/ 1440;
          return days == 1 ? '1 day before' : '$days days before';
        }
        if (minutes % 60 == 0) {
          final hours = minutes ~/ 60;
          return hours == 1 ? '1 hour before' : '$hours hours before';
        }
        return '$minutes minutes before';
    }
  }
}
