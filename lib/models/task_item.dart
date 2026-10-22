import 'package:equatable/equatable.dart';

import '../core/utils/deadline_calculator.dart';
import '../core/utils/recurrence_calculator.dart';
import 'enums.dart';

/// Immutable domain model for a task (or subtask).
///
/// Deliberately separate from the Drift-generated row class so persistence
/// details never leak into the UI. Named `TaskItem` to avoid clashing with
/// Drift's generated `Task` data class.
class TaskItem extends Equatable {
  const TaskItem({
    required this.id,
    required this.title,
    required this.priority,
    required this.status,
    required this.recurrenceType,
    required this.isRecurring,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.notes,
    this.categoryId,
    this.deadline,
    this.recurrenceDays,
    this.recurrenceSourceId,
    this.completedAt,
    this.parentTaskId,
    this.userId = 'default_user',
    this.alarmType = AlarmType.standard,
    this.repeatUntilCompleted = false,
    this.repeatIntervalMinutes = 15,
    this.maxRepeatCount = 5,
    this.currentRepeatCount = 0,
    this.customNotificationTitle,
    this.customNotificationBody,
    this.soundChoice = NotificationSound.systemDefault,
    this.vibrationChoice = NotificationVibration.standard,
    this.snoozeUntil,
  });

  final String id;
  final String title;
  final String? description;
  final String? notes;
  final String? categoryId;
  final Priority priority;
  final TaskStatus status;
  final DateTime? deadline;
  final bool isRecurring;
  final RecurrenceType recurrenceType;

  /// CSV of ISO weekdays, only meaningful for [RecurrenceType.customWeekly].
  final String? recurrenceDays;
  final String? recurrenceSourceId;
  final DateTime? completedAt;
  final String? parentTaskId;
  final String? userId;
  final AlarmType alarmType;
  final bool repeatUntilCompleted;
  final int repeatIntervalMinutes;
  final int maxRepeatCount;
  final int currentRepeatCount;
  final String? customNotificationTitle;
  final String? customNotificationBody;
  final NotificationSound soundChoice;
  final NotificationVibration vibrationChoice;
  final DateTime? snoozeUntil;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isSubtask => parentTaskId != null;

  bool get isCompleted => status == TaskStatus.completed;

  bool get isCancelled => status == TaskStatus.cancelled;

  bool get isClosed => status.isClosed;

  bool get isOpen => !isClosed;

  bool get hasDeadline => deadline != null;

  bool get isSnoozed {
    if (snoozeUntil == null) return false;
    final local = snoozeUntil!.isUtc ? snoozeUntil!.toLocal() : snoozeUntil!;
    return local.isAfter(DateTime.now());
  }

  /// The task's live deadline view.
  DeadlineInfo deadlineInfo({DateTime? now}) => DeadlineCalculator.compute(
    deadline: deadline,
    status: status,
    isOverdueFlag: status == TaskStatus.overdue,
    now: now,
  );

  /// Convenience — the raw remaining/overdue duration.
  Duration timeToDeadline({DateTime? now}) {
    final clock = now ?? DateTime.now();
    if (deadline == null) return Duration.zero;
    final local = deadline!.isUtc ? deadline!.toLocal() : deadline!;
    return local.difference(clock);
  }

  bool isOverdue({DateTime? now}) => DeadlineCalculator.isOverdue(
    deadline: deadline,
    status: status,
    now: now,
  );

  List<int> get recurrenceWeekdays =>
      RecurrenceCalculator.parseDays(recurrenceDays);

  /// Copy with sentinel-based null handling so fields can be cleared.
  TaskItem copyWith({
    String? title,
    Object? description = _sentinel,
    Object? notes = _sentinel,
    Object? categoryId = _sentinel,
    Priority? priority,
    TaskStatus? status,
    Object? deadline = _sentinel,
    bool? isRecurring,
    RecurrenceType? recurrenceType,
    Object? recurrenceDays = _sentinel,
    Object? recurrenceSourceId = _sentinel,
    Object? completedAt = _sentinel,
    Object? parentTaskId = _sentinel,
    Object? userId = _sentinel,
    AlarmType? alarmType,
    bool? repeatUntilCompleted,
    int? repeatIntervalMinutes,
    int? maxRepeatCount,
    int? currentRepeatCount,
    Object? customNotificationTitle = _sentinel,
    Object? customNotificationBody = _sentinel,
    NotificationSound? soundChoice,
    NotificationVibration? vibrationChoice,
    Object? snoozeUntil = _sentinel,
    int? sortOrder,
    DateTime? updatedAt,
  }) {
    return TaskItem(
      id: id,
      title: title ?? this.title,
      description: identical(description, _sentinel)
          ? this.description
          : description as String?,
      notes: identical(notes, _sentinel) ? this.notes : notes as String?,
      categoryId: identical(categoryId, _sentinel)
          ? this.categoryId
          : categoryId as String?,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      deadline: identical(deadline, _sentinel)
          ? this.deadline
          : deadline as DateTime?,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceDays: identical(recurrenceDays, _sentinel)
          ? this.recurrenceDays
          : recurrenceDays as String?,
      recurrenceSourceId: identical(recurrenceSourceId, _sentinel)
          ? this.recurrenceSourceId
          : recurrenceSourceId as String?,
      completedAt: identical(completedAt, _sentinel)
          ? this.completedAt
          : completedAt as DateTime?,
      parentTaskId: identical(parentTaskId, _sentinel)
          ? this.parentTaskId
          : parentTaskId as String?,
      userId: identical(userId, _sentinel) ? this.userId : userId as String?,
      alarmType: alarmType ?? this.alarmType,
      repeatUntilCompleted: repeatUntilCompleted ?? this.repeatUntilCompleted,
      repeatIntervalMinutes:
          repeatIntervalMinutes ?? this.repeatIntervalMinutes,
      maxRepeatCount: maxRepeatCount ?? this.maxRepeatCount,
      currentRepeatCount: currentRepeatCount ?? this.currentRepeatCount,
      customNotificationTitle: identical(customNotificationTitle, _sentinel)
          ? this.customNotificationTitle
          : customNotificationTitle as String?,
      customNotificationBody: identical(customNotificationBody, _sentinel)
          ? this.customNotificationBody
          : customNotificationBody as String?,
      soundChoice: soundChoice ?? this.soundChoice,
      vibrationChoice: vibrationChoice ?? this.vibrationChoice,
      snoozeUntil: identical(snoozeUntil, _sentinel)
          ? this.snoozeUntil
          : snoozeUntil as DateTime?,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    notes,
    categoryId,
    priority,
    status,
    deadline,
    isRecurring,
    recurrenceType,
    recurrenceDays,
    recurrenceSourceId,
    completedAt,
    parentTaskId,
    userId,
    alarmType,
    repeatUntilCompleted,
    repeatIntervalMinutes,
    maxRepeatCount,
    currentRepeatCount,
    customNotificationTitle,
    customNotificationBody,
    soundChoice,
    vibrationChoice,
    snoozeUntil,
    sortOrder,
    createdAt,
    updatedAt,
  ];
}

const Object _sentinel = Object();

/// Progress of a parent task's subtasks.
class SubtaskProgress {
  const SubtaskProgress({required this.completed, required this.total});

  final int completed;
  final int total;

  int get remaining => (total - completed).clamp(0, total);

  bool get hasSubtasks => total > 0;

  double get fraction => total == 0 ? 0 : completed / total;

  int get percent => (fraction * 100).round();

  /// "3 / 5 completed"
  String get label => '$completed / $total completed';
}
