import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/date_x.dart';
import '../core/utils/deadline_calculator.dart';
import '../core/utils/recurrence_calculator.dart';
import '../models/enums.dart';
import '../models/reminder.dart';
import '../models/task_item.dart';
import '../models/user_settings.dart';
import 'auth_provider.dart';
import 'core_providers.dart';

/// A draft used by the task editor. Mirrors [TaskItem] but starts blank and
/// carries the requested reminder specs.
class TaskDraft {
  TaskDraft({
    this.title = '',
    this.description = '',
    this.notes = '',
    this.categoryId,
    this.priority = Priority.medium,
    this.status = TaskStatus.notStarted,
    this.deadline,
    this.recurrenceType = RecurrenceType.none,
    this.recurrenceDays = const [],
    this.reminders = const [],
    this.subtasks = const [],
    AlarmType? alarmType,
    bool? repeatUntilCompleted,
    int? repeatIntervalMinutes,
    this.maxRepeatCount = 5,
    this.customNotificationTitle,
    this.customNotificationBody,
    NotificationSound? soundChoice,
    NotificationVibration? vibrationChoice,
  })  : alarmType = alarmType ?? AlarmType.standard,
        hasExplicitAlarmType = alarmType != null,
        repeatUntilCompleted = repeatUntilCompleted ?? false,
        hasExplicitRepeatUntilCompleted = repeatUntilCompleted != null,
        repeatIntervalMinutes = repeatIntervalMinutes ?? 15,
        hasExplicitRepeatIntervalMinutes = repeatIntervalMinutes != null,
        soundChoice = soundChoice ?? NotificationSound.systemDefault,
        hasExplicitSoundChoice = soundChoice != null,
        vibrationChoice = vibrationChoice ?? NotificationVibration.standard,
        hasExplicitVibrationChoice = vibrationChoice != null;

  String title;
  String description;
  String notes;
  String? categoryId;
  Priority priority;
  TaskStatus status;
  DateTime? deadline;
  RecurrenceType recurrenceType;
  List<int> recurrenceDays;
  List<ReminderSpec> reminders;
  List<SubtaskDraft> subtasks;
  AlarmType alarmType;
  bool repeatUntilCompleted;
  int repeatIntervalMinutes;
  int maxRepeatCount;
  String? customNotificationTitle;
  String? customNotificationBody;
  NotificationSound soundChoice;
  NotificationVibration vibrationChoice;

  bool hasExplicitAlarmType;
  bool hasExplicitRepeatUntilCompleted;
  bool hasExplicitRepeatIntervalMinutes;
  bool hasExplicitSoundChoice;
  bool hasExplicitVibrationChoice;

  /// Creates a draft initialized from global [UserSettings].
  factory TaskDraft.withDefaults(
    UserSettings settings, {
    String title = '',
    String description = '',
    String notes = '',
    String? categoryId,
    Priority priority = Priority.medium,
    DateTime? deadline,
    AlarmType? alarmType,
    bool? repeatUntilCompleted,
    int? repeatIntervalMinutes,
    int maxRepeatCount = 5,
    String? customNotificationTitle,
    String? customNotificationBody,
    NotificationSound? soundChoice,
    NotificationVibration? vibrationChoice,
    RecurrenceType recurrenceType = RecurrenceType.none,
    List<int> recurrenceDays = const [],
    List<ReminderSpec> reminders = const [],
    List<SubtaskDraft> subtasks = const [],
  }) {
    final draft = TaskDraft(
      title: title,
      description: description,
      notes: notes,
      categoryId: categoryId,
      priority: priority,
      deadline: deadline,
      recurrenceType: recurrenceType,
      recurrenceDays: recurrenceDays,
      reminders: reminders,
      subtasks: subtasks,
      alarmType: alarmType ?? settings.resolvedDefaultAlarmType,
      repeatUntilCompleted:
          repeatUntilCompleted ?? settings.defaultRepeatUntilCompleted,
      repeatIntervalMinutes:
          repeatIntervalMinutes ?? settings.defaultRepeatIntervalMinutes,
      maxRepeatCount: maxRepeatCount,
      customNotificationTitle: customNotificationTitle,
      customNotificationBody: customNotificationBody,
      soundChoice: soundChoice ?? settings.resolvedDefaultSound,
      vibrationChoice: vibrationChoice ?? settings.resolvedDefaultVibration,
    );
    if (alarmType != null) draft.hasExplicitAlarmType = true;
    if (repeatUntilCompleted != null) {
      draft.hasExplicitRepeatUntilCompleted = true;
    }
    if (repeatIntervalMinutes != null) {
      draft.hasExplicitRepeatIntervalMinutes = true;
    }
    if (soundChoice != null) draft.hasExplicitSoundChoice = true;
    if (vibrationChoice != null) draft.hasExplicitVibrationChoice = true;
    return draft;
  }

  factory TaskDraft.fromTask(
    TaskItem task, {
    List<ReminderSpec> reminders = const [],
    List<SubtaskDraft> subtasks = const [],
  }) {
    final draft = TaskDraft(
      title: task.title,
      description: task.description ?? '',
      notes: task.notes ?? '',
      categoryId: task.categoryId,
      priority: task.priority,
      status: task.status,
      deadline: task.deadline,
      recurrenceType: task.recurrenceType,
      recurrenceDays: task.recurrenceWeekdays,
      reminders: reminders,
      subtasks: subtasks,
      alarmType: task.alarmType,
      repeatUntilCompleted: task.repeatUntilCompleted,
      repeatIntervalMinutes: task.repeatIntervalMinutes,
      maxRepeatCount: task.maxRepeatCount,
      customNotificationTitle: task.customNotificationTitle,
      customNotificationBody: task.customNotificationBody,
      soundChoice: task.soundChoice,
      vibrationChoice: task.vibrationChoice,
    );
    draft.hasExplicitAlarmType = true;
    draft.hasExplicitRepeatUntilCompleted = true;
    draft.hasExplicitRepeatIntervalMinutes = true;
    draft.hasExplicitSoundChoice = true;
    draft.hasExplicitVibrationChoice = true;
    return draft;
  }

  /// Validation matching the product rules (title required, repeat needs a
  /// deadline and days).
  String? validate() {
    if (title.trim().isEmpty) return 'Give your task a title.';
    if (title.trim().length > 200) return 'That title is too long.';
    final recurrenceError = RecurrenceCalculator.validate(
      type: recurrenceType,
      recurrenceDays: RecurrenceCalculator.serializeDays(recurrenceDays),
      deadline: deadline,
    );
    if (recurrenceError != null) return recurrenceError;
    return null;
  }
}

/// A subtask being edited before it is persisted.
class SubtaskDraft {
  SubtaskDraft({this.id, required this.title, this.isCompleted = false});

  /// Null for a brand-new subtask.
  final String? id;
  String title;
  bool isCompleted;
}

/// Result of a save, so the UI can surface real errors rather than guessing.
class TaskSaveResult {
  const TaskSaveResult.success() : error = null;
  const TaskSaveResult.failure(this.error);
  final String? error;
  bool get isSuccess => error == null;
}

/// All mutating operations for tasks. UI never touches repositories directly.
class TaskController {
  TaskController(this._ref);

  final Ref _ref;

  /// Creates a task from [draft] and schedules its reminders.
  Future<TaskSaveResult> createTask(TaskDraft draft) async {
    final error = draft.validate();
    if (error != null) return TaskSaveResult.failure(error);

    final now = DateTime.now();
    final taskRepo = _ref.read(taskRepositoryProvider);
    final reminderService = _ref.read(reminderServiceProvider);
    final user = _ref.read(currentUserProvider);
    final id = taskRepo.newId();

    final settings = await _ref.read(settingsRepositoryProvider).load();
    final effectiveAlarmType = draft.hasExplicitAlarmType
        ? draft.alarmType
        : settings.resolvedDefaultAlarmType;
    final effectiveRepeatUntilCompleted = draft.hasExplicitRepeatUntilCompleted
        ? draft.repeatUntilCompleted
        : settings.defaultRepeatUntilCompleted;
    final effectiveRepeatIntervalMinutes =
        draft.hasExplicitRepeatIntervalMinutes
            ? draft.repeatIntervalMinutes
            : (effectiveRepeatUntilCompleted
                ? settings.defaultRepeatIntervalMinutes
                : draft.repeatIntervalMinutes);
    final effectiveSoundChoice = draft.hasExplicitSoundChoice
        ? draft.soundChoice
        : settings.resolvedDefaultSound;
    final effectiveVibrationChoice = draft.hasExplicitVibrationChoice
        ? draft.vibrationChoice
        : settings.resolvedDefaultVibration;

    final task = TaskItem(
      id: id,
      title: draft.title.trim(),
      description: _nullable(draft.description),
      notes: _nullable(draft.notes),
      categoryId: draft.categoryId,
      priority: draft.priority,
      status: draft.status,
      deadline: draft.deadline,
      isRecurring: draft.recurrenceType.repeats,
      recurrenceType: draft.recurrenceType,
      recurrenceDays: draft.recurrenceType == RecurrenceType.customWeekly
          ? RecurrenceCalculator.serializeDays(draft.recurrenceDays)
          : null,
      userId: user?.id ?? 'default_user',
      alarmType: effectiveAlarmType,
      repeatUntilCompleted: effectiveRepeatUntilCompleted,
      repeatIntervalMinutes: effectiveRepeatIntervalMinutes,
      maxRepeatCount: draft.maxRepeatCount,
      customNotificationTitle: _nullable(draft.customNotificationTitle),
      customNotificationBody: _nullable(draft.customNotificationBody),
      soundChoice: effectiveSoundChoice,
      vibrationChoice: effectiveVibrationChoice,
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
    );

    var inserted = false;
    try {
      await taskRepo.insert(task);
      inserted = true;
      await _persistSubtasks(parentId: id, drafts: draft.subtasks);
      await reminderService.syncTask(
        task: task,
        specs: _normaliseSpecs(draft.reminders, draft.deadline),
      );
      return const TaskSaveResult.success();
    } catch (e, s) {
      debugPrint('createTask failed for ${task.id}: $e\n$s');
      if (inserted) {
        try {
          await taskRepo.delete(id);
        } catch (cleanupError) {
          debugPrint('Failed to rollback task $id: $cleanupError');
        }
      }
      return const TaskSaveResult.failure(
        'Could not save the task. Please try again.',
      );
    }
  }

  /// Updates an existing task. Cancels old notifications, then schedules new.
  Future<TaskSaveResult> updateTask(TaskItem original, TaskDraft draft) async {
    final error = draft.validate();
    if (error != null) return TaskSaveResult.failure(error);

    final updated = original.copyWith(
      title: draft.title.trim(),
      description: _nullable(draft.description),
      notes: _nullable(draft.notes),
      categoryId: draft.categoryId,
      priority: draft.priority,
      status: original.status.isClosed ? original.status : draft.status,
      deadline: draft.deadline,
      isRecurring: draft.recurrenceType.repeats,
      recurrenceType: draft.recurrenceType,
      recurrenceDays: draft.recurrenceType == RecurrenceType.customWeekly
          ? RecurrenceCalculator.serializeDays(draft.recurrenceDays)
          : null,
      alarmType: draft.alarmType,
      repeatUntilCompleted: draft.repeatUntilCompleted,
      repeatIntervalMinutes: draft.repeatIntervalMinutes,
      maxRepeatCount: draft.maxRepeatCount,
      customNotificationTitle: _nullable(draft.customNotificationTitle),
      customNotificationBody: _nullable(draft.customNotificationBody),
      soundChoice: draft.soundChoice,
      vibrationChoice: draft.vibrationChoice,
      updatedAt: DateTime.now(),
    );

    try {
      await _ref.read(taskRepositoryProvider).update(updated);
      await _persistSubtasks(parentId: original.id, drafts: draft.subtasks);
      await _ref
          .read(reminderServiceProvider)
          .syncTask(
            task: updated,
            specs: _normaliseSpecs(draft.reminders, draft.deadline),
          );
      return const TaskSaveResult.success();
    } catch (e, s) {
      debugPrint('updateTask failed for ${original.id}: $e\n$s');
      return const TaskSaveResult.failure(
        'Could not update the task. Please try again.',
      );
    }
  }

  /// Marks a task complete, cancels its reminders and, for recurring tasks,
  /// generates the next occurrence.
  Future<TaskSaveResult> completeTask(String id) async {
    final repo = _ref.read(taskRepositoryProvider);
    final task = await repo.getById(id);
    if (task == null) return const TaskSaveResult.failure('Task not found.');

    final now = DateTime.now();
    final completed = task.copyWith(
      status: TaskStatus.completed,
      completedAt: now,
      updatedAt: now,
    );

    try {
      await repo.update(completed);
      // Completing cancels every future notification for this task.
      await _ref.read(reminderServiceProvider).cancelTask(id);
      if (task.isRecurring && task.recurrenceType.repeats) {
        await _spawnNextOccurrence(task);
      }
      return const TaskSaveResult.success();
    } catch (e) {
      return const TaskSaveResult.failure('Could not complete the task.');
    }
  }

  /// Reopens a completed task (status returns to not started).
  Future<TaskSaveResult> reopenTask(String id) async {
    final repo = _ref.read(taskRepositoryProvider);
    final task = await repo.getById(id);
    if (task == null) return const TaskSaveResult.failure('Task not found.');

    final reopened = task.copyWith(
      status: TaskStatus.notStarted,
      completedAt: null,
      updatedAt: DateTime.now(),
    );
    try {
      await repo.update(reopened);
      await _ref.read(reminderServiceProvider).resyncFromStored(reopened);
      return const TaskSaveResult.success();
    } catch (e) {
      return const TaskSaveResult.failure('Could not reopen the task.');
    }
  }

  Future<TaskSaveResult> setStatus(String id, TaskStatus status) async {
    final repo = _ref.read(taskRepositoryProvider);
    final task = await repo.getById(id);
    if (task == null) return const TaskSaveResult.failure('Task not found.');

    final updated = task.copyWith(
      status: status,
      completedAt: status == TaskStatus.completed ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );
    try {
      await repo.update(updated);
      if (status.isClosed) {
        await _ref.read(reminderServiceProvider).cancelTask(id);
      } else {
        await _ref.read(reminderServiceProvider).resyncFromStored(updated);
      }
      return const TaskSaveResult.success();
    } catch (e) {
      return const TaskSaveResult.failure('Could not update the status.');
    }
  }

  /// Reschedules to a new deadline/time, preserving the reminder offsets.
  Future<TaskSaveResult> reschedule(String id, DateTime newDeadline) async {
    final repo = _ref.read(taskRepositoryProvider);
    final task = await repo.getById(id);
    if (task == null) return const TaskSaveResult.failure('Task not found.');

    final updated = task.copyWith(
      deadline: newDeadline,
      status: task.status == TaskStatus.overdue
          ? TaskStatus.notStarted
          : task.status,
      updatedAt: DateTime.now(),
    );
    try {
      await repo.update(updated);
      // resyncFromStored recomputes each reminder's absolute time from the new
      // deadline, so old alarms never linger.
      await _ref.read(reminderServiceProvider).resyncFromStored(updated);
      return const TaskSaveResult.success();
    } catch (e) {
      return const TaskSaveResult.failure('Could not reschedule the task.');
    }
  }

  TaskItem? _lastDeletedTask;
  List<TaskItem>? _lastDeletedSubtasks;
  List<TaskReminder>? _lastDeletedReminders;

  bool get canUndoDelete => _lastDeletedTask != null;
  String? get lastDeletedTaskTitle => _lastDeletedTask?.title;

  Future<TaskSaveResult> deleteTask(String id) async {
    try {
      final taskRepo = _ref.read(taskRepositoryProvider);
      final reminderRepo = _ref.read(reminderRepositoryProvider);

      final task = await taskRepo.getById(id);
      if (task != null) {
        _lastDeletedTask = task;
        _lastDeletedSubtasks = await taskRepo.getSubtasks(id);
        _lastDeletedReminders = await reminderRepo.getForTask(id);
      }

      // Cancel OS alarms before the row (and its reminders) cascade away.
      await _ref.read(reminderServiceProvider).cancelTask(id);
      await taskRepo.delete(id);
      return const TaskSaveResult.success();
    } catch (e) {
      return const TaskSaveResult.failure('Could not delete the task.');
    }
  }

  /// Restores the last deleted task, its subtasks, and its scheduled reminders.
  Future<TaskSaveResult> undoDelete() async {
    final task = _lastDeletedTask;
    if (task == null) {
      return const TaskSaveResult.failure('Nothing to restore.');
    }

    try {
      final taskRepo = _ref.read(taskRepositoryProvider);
      await taskRepo.insert(task);

      if (_lastDeletedSubtasks != null) {
        for (final subtask in _lastDeletedSubtasks!) {
          await taskRepo.insert(subtask);
        }
      }

      if (_lastDeletedReminders != null &&
          task.deadline != null &&
          !task.isClosed) {
        final reminderService = _ref.read(reminderServiceProvider);
        final specs = _lastDeletedReminders!
            .where((r) => r.kind != ReminderKind.overdue)
            .map(
              (r) => ReminderSpec(
                kind: r.kind,
                minutesBefore: r.minutesBefore,
                customAt: r.kind == ReminderKind.custom ? r.scheduledAt : null,
              ),
            )
            .toList();
        await reminderService.syncTask(task: task, specs: specs);
      }

      _lastDeletedTask = null;
      _lastDeletedSubtasks = null;
      _lastDeletedReminders = null;
      return const TaskSaveResult.success();
    } catch (e) {
      return const TaskSaveResult.failure('Could not restore the task.');
    }
  }

  /// Snoozes the task's reminder by [duration] from now, or to a [customDateTime].
  Future<TaskSaveResult> snoozeTask(
    String id,
    Duration duration, {
    DateTime? customDateTime,
    int? customRepeatIntervalMinutes,
  }) async {
    final repo = _ref.read(taskRepositoryProvider);
    final task = await repo.getById(id);
    if (task == null) return const TaskSaveResult.failure('Task not found.');

    try {
      await _ref
          .read(reminderServiceProvider)
          .snoozeTask(
            task: task,
            duration: duration,
            customDateTime: customDateTime,
            customRepeatIntervalMinutes: customRepeatIntervalMinutes,
          );
      return const TaskSaveResult.success();
    } catch (e) {
      return const TaskSaveResult.failure('Could not snooze reminder.');
    }
  }

  /// Bulk completes multiple tasks. Returns the number of completed tasks.
  Future<int> completeMultiple(List<String> ids) async {
    var count = 0;
    for (final id in ids) {
      final res = await completeTask(id);
      if (res.isSuccess) count++;
    }
    return count;
  }

  /// Bulk deletes multiple tasks. Returns the number of deleted tasks.
  Future<int> deleteMultiple(List<String> ids) async {
    var count = 0;
    for (final id in ids) {
      final res = await deleteTask(id);
      if (res.isSuccess) count++;
    }
    return count;
  }

  Future<TaskSaveResult> toggleSubtask(String id) async {
    final repo = _ref.read(taskRepositoryProvider);
    final subtask = await repo.getById(id);
    if (subtask == null) {
      return const TaskSaveResult.failure('Subtask not found.');
    }
    final complete = subtask.status != TaskStatus.completed;
    return setStatus(
      id,
      complete ? TaskStatus.completed : TaskStatus.notStarted,
    );
  }

  /// Re-evaluates overdue status and surfaces any elapsed reminders. Used by
  /// pull-to-refresh and on app resume.
  Future<void> refreshOverdue() async {
    await _ref.read(reminderServiceProvider).processDueNotifications();
  }

  // ---- Internals --------------------------------------------------------

  Future<void> _persistSubtasks({
    required String parentId,
    required List<SubtaskDraft> drafts,
  }) async {
    final repo = _ref.read(taskRepositoryProvider);
    final existing = await repo.getSubtasks(parentId);
    final existingById = {for (final e in existing) e.id: e};
    final keptIds = <String>{};

    final parentTask = await repo.getById(parentId);
    final user = _ref.read(currentUserProvider);
    final effectiveUserId = parentTask?.userId ?? user?.id ?? 'default_user';

    var order = 0;
    for (final draft in drafts) {
      final title = draft.title.trim();
      if (title.isEmpty) continue;

      if (draft.id != null && existingById.containsKey(draft.id)) {
        final original = existingById[draft.id]!;
        final next = original.copyWith(
          title: title,
          status: draft.isCompleted
              ? TaskStatus.completed
              : TaskStatus.notStarted,
          completedAt: draft.isCompleted ? DateTime.now() : null,
          sortOrder: order,
          updatedAt: DateTime.now(),
        );
        await repo.update(next);
        keptIds.add(original.id);
      } else {
        final now = DateTime.now();
        await repo.insert(
          TaskItem(
            id: repo.newId(),
            title: title,
            priority: Priority.medium,
            status: draft.isCompleted
                ? TaskStatus.completed
                : TaskStatus.notStarted,
            recurrenceType: RecurrenceType.none,
            isRecurring: false,
            parentTaskId: parentId,
            userId: effectiveUserId,
            completedAt: draft.isCompleted ? now : null,
            sortOrder: order,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
      order++;
    }

    // Remove subtasks the user deleted in the editor.
    for (final original in existing) {
      if (!keptIds.contains(original.id)) {
        await repo.delete(original.id);
      }
    }
  }

  /// Ensures the "at deadline" reminder is present when a deadline exists and
  /// no reminder was configured, so a deadline never passes silently.
  List<ReminderSpec> _normaliseSpecs(
    List<ReminderSpec> specs,
    DateTime? deadline,
  ) {
    if (deadline == null) return const [];
    if (specs.isEmpty) return const [ReminderSpec.atDeadline()];
    return specs;
  }

  /// Creates the next occurrence of a recurring task.
  Future<void> _spawnNextOccurrence(TaskItem completed) async {
    final from = completed.deadline;
    if (from == null) return;
    final next = RecurrenceCalculator.nextOccurrence(
      type: completed.recurrenceType,
      recurrenceDays: completed.recurrenceDays,
      from: from,
    );
    if (next == null) return;

    final repo = _ref.read(taskRepositoryProvider);
    // Guard against duplicate chains. Only the tasks sharing this recurrence
    // source are inspected — no full-table scan.
    final sourceId = completed.recurrenceSourceId ?? completed.id;
    final chain = await repo.getByRecurrenceSource(sourceId);
    final alreadyScheduled = chain.any(
      (t) =>
          t.id != completed.id &&
          t.status.isOpen &&
          t.deadline != null &&
          t.deadline!.isSameDay(next),
    );
    if (alreadyScheduled) return;

    final now = DateTime.now();
    final newTask = TaskItem(
      id: repo.newId(),
      title: completed.title,
      description: completed.description,
      notes: completed.notes,
      categoryId: completed.categoryId,
      priority: completed.priority,
      status: TaskStatus.notStarted,
      deadline: next,
      isRecurring: true,
      recurrenceType: completed.recurrenceType,
      recurrenceDays: completed.recurrenceDays,
      recurrenceSourceId: sourceId,
      parentTaskId: completed.parentTaskId,
      userId: completed.userId,
      alarmType: completed.alarmType,
      repeatUntilCompleted: completed.repeatUntilCompleted,
      repeatIntervalMinutes: completed.repeatIntervalMinutes,
      maxRepeatCount: completed.maxRepeatCount,
      customNotificationTitle: completed.customNotificationTitle,
      customNotificationBody: completed.customNotificationBody,
      soundChoice: completed.soundChoice,
      vibrationChoice: completed.vibrationChoice,
      sortOrder: completed.sortOrder,
      createdAt: now,
      updatedAt: now,
    );
    await repo.insert(newTask);
    final stored = await _ref.read(reminderRepositoryProvider).getForTask(completed.id);
    final specs = stored
        .where((r) => r.kind != ReminderKind.overdue)
        .map(
          (r) => ReminderSpec(
            kind: r.kind,
            minutesBefore: r.minutesBefore,
            customAt: r.kind == ReminderKind.custom ? r.scheduledAt : null,
          ),
        )
        .toList();
    await _ref.read(reminderServiceProvider).syncTask(
      task: newTask,
      specs: _normaliseSpecs(specs, next),
    );
  }

  String? _nullable(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}

final taskControllerProvider = Provider<TaskController>(
  (ref) => TaskController(ref),
);

/// Suggested default deadline for the quick-add parser.
DateTime defaultDeadlineFor(Priority priority) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, 23, 59);
}

/// Exposed so tests can use the same effective-status logic as the app.
TaskStatus effectiveStatusFor(TaskItem task, {DateTime? now}) =>
    DeadlineCalculator.effectiveStatus(
      current: task.status,
      deadline: task.deadline,
      now: now,
    );
