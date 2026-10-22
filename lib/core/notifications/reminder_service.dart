// The private field names intentionally differ from the (public) constructor
// parameter names; Dart forbids private named parameters, so the
// `prefer_initializing_formals` suggestion does not apply here.
// ignore_for_file: prefer_initializing_formals

import 'package:uuid/uuid.dart';

import '../../models/app_notification.dart';
import '../../models/enums.dart';
import '../../models/reminder.dart';
import '../../models/task_item.dart';
import '../../models/user_settings.dart';
import '../../repositories/notification_repository.dart';
import '../../repositories/reminder_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/task_repository.dart';
import '../constants/app_constants.dart';
import 'notification_service.dart';
import 'reminder_planner.dart';

/// Orchestrates everything about reminders.
///
/// This is the single entry point the UI and providers call. It:
///  * schedules OS notifications through [NotificationService],
///  * persists the plan through [ReminderRepository],
///  * creates in-app centre entries,
///  * cancels notifications when tasks are completed, edited or deleted.
///
/// The golden rule: whenever a task's deadline or reminders change, the old
/// OS notifications are cancelled *before* the new ones are scheduled.
class ReminderService {
  ReminderService({
    required NotificationService notifications,
    required ReminderRepository reminders,
    required NotificationRepository notificationCenter,
    required TaskRepository tasks,
    required SettingsRepository settings,
    Uuid? uuid,
  }) : _notifications = notifications,
       _reminders = reminders,
       _center = notificationCenter,
       _tasks = tasks,
       _settings = settings,
       _uuid = uuid ?? const Uuid();

  final NotificationService _notifications;
  final ReminderRepository _reminders;
  final NotificationRepository _center;
  final TaskRepository _tasks;
  final SettingsRepository _settings;
  final Uuid _uuid;

  /// (Re)plans and schedules all reminders for [task] from [specs].
  ///
  /// Old notifications for the task are always cancelled first.
  Future<void> syncTask({
    required TaskItem task,
    required List<ReminderSpec> specs,
  }) async {
    await _cancelTaskNotifications(task.id);

    // A closed task keeps no future notifications.
    if (task.isClosed || task.deadline == null) {
      await _reminders.deleteForTask(task.id);
      return;
    }

    final settings = await _settings.load();
    if (!settings.notificationsEnabled) {
      await _reminders.deleteForTask(task.id);
      return;
    }

    final taken = await _reminders.allNotificationIds();
    final planned = ReminderPlanner.plan(
      task: task,
      specs: specs,
      settings: settings,
      allocateId: () {
        final id = NotificationService.allocateNotificationId(taken);
        taken.add(id);
        return id;
      },
    );

    final now = DateTime.now();
    final localDeadline = task.deadline!.isUtc
        ? task.deadline!.toLocal()
        : task.deadline!;

    // If task is overdue and repeat-until-completed is active, schedule the next single bounded repeat
    if (localDeadline.isBefore(now) &&
        task.repeatUntilCompleted &&
        task.currentRepeatCount < task.maxRepeatCount) {
      if (!task.isSnoozed) {
        final nextTime = now.add(Duration(minutes: task.repeatIntervalMinutes));
        final id = NotificationService.allocateNotificationId(taken);
        taken.add(id);
        planned.add(
          TaskReminder(
            id: _uuid.v4(),
            taskId: task.id,
            kind: ReminderKind.overdue,
            scheduledAt: nextTime,
            notificationId: id,
            createdAt: now,
          ),
        );
      }
    }

    await _reminders.replaceForTask(task.id, planned);

    for (final reminder in planned) {
      if (!reminder.isFuture) continue;
      await _notifications.scheduleReminder(
        task: task,
        notificationId: reminder.notificationId,
        scheduledAt: reminder.scheduledAt,
        kind: reminder.kind,
      );
    }
  }

  /// Convenience for callers that only have the task (loads its stored specs).
  Future<void> resyncFromStored(TaskItem task) async {
    final stored = await _reminders.getForTask(task.id);
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
    await syncTask(task: task, specs: specs);
  }

  /// Cancels every OS notification belonging to [taskId].
  Future<void> cancelTask(String taskId) async {
    await _cancelTaskNotifications(taskId);
    await _reminders.deleteForTask(taskId);
  }

  /// Snoozes the task's reminder by [duration] from now, or to a [customDateTime].
  ///
  /// Schedules a genuine OS-level exact alarm and updates the task's [snoozeUntil].
  Future<void> snoozeTask({
    required TaskItem task,
    required Duration duration,
    DateTime? customDateTime,
    int? customRepeatIntervalMinutes,
  }) async {
    final now = DateTime.now();
    final snoozeAt = customDateTime ?? now.add(duration);

    final settings = await _settings.load();
    if (!settings.notificationsEnabled) return;

    // 1. Cancel previous pending reminders for this task so snooze replaces cleanly
    await _cancelTaskNotifications(task.id);
    await _reminders.deleteForTask(task.id);

    // 2. Persist snooze timestamp on the task
    final updatedTask = task.copyWith(
      snoozeUntil: snoozeAt,
      repeatIntervalMinutes:
          customRepeatIntervalMinutes ?? task.repeatIntervalMinutes,
      updatedAt: now,
    );
    await _tasks.update(updatedTask);

    // 3. Allocate unique ID and schedule the snoozed reminder
    final taken = await _reminders.allNotificationIds();
    final notificationId = NotificationService.allocateNotificationId(taken);

    final snoozedReminder = TaskReminder(
      id: _uuid.v4(),
      taskId: task.id,
      kind: ReminderKind.custom,
      scheduledAt: snoozeAt,
      notificationId: notificationId,
      createdAt: now,
    );

    await _reminders.upsert(snoozedReminder);

    await _notifications.scheduleReminder(
      task: updatedTask,
      notificationId: notificationId,
      scheduledAt: snoozeAt,
      kind: ReminderKind.custom,
    );
  }

  Future<void> _cancelTaskNotifications(String taskId) async {
    final existing = await _reminders.getForTask(taskId);
    if (existing.isNotEmpty) {
      await _notifications.cancelMany(existing.map((r) => r.notificationId));
    }
  }

  /// Re-syncs all OS notifications after a settings change (master switch,
  /// daily summary, overdue reminders).
  Future<void> applySettingsChange(UserSettings settings) async {
    final tasks = await _tasks.getTasks(filter: const TaskFilter());
    if (!settings.notificationsEnabled) {
      await _notifications.cancelAll();
      for (final task in tasks) {
        await _reminders.deleteForTask(task.id);
      }
      return;
    }
    for (final task in tasks) {
      await resyncFromStored(task);
    }
    await _syncDailySummary(settings);
  }

  /// Schedules or cancels the daily summary to match the current setting.
  Future<void> _syncDailySummary(UserSettings settings) async {
    if (settings.notificationsEnabled && settings.dailySummaryEnabled) {
      await _notifications.scheduleDailySummary(
        hour: 8,
        minute: 0,
        title: 'Good morning',
        body:
            'Here\u2019s what\u2019s due today. Open DueMate to see the list.',
      );
    } else {
      await _notifications.cancel(AppConstants.dailySummaryNotificationId);
    }
  }

  /// Public entry point used by bootstrap and settings to apply the daily
  /// summary schedule without resyncing every task.
  Future<void> syncDailySummary(UserSettings settings) =>
      _syncDailySummary(settings);

  // ---- In-app centre ----------------------------------------------------

  /// Turns elapsed reminders into in-app notification entries and manages bounded
  /// repeating reminders. Safe to call on every app start, resume, or alarm receiver.
  Future<void> processDueNotifications() async {
    final now = DateTime.now();

    // 1) Elapsed reminders -> centre entries and repeat scheduling
    final due = await _reminders.getDueUnnotified(now);
    final taken = await _reminders.allNotificationIds();

    for (final reminder in due) {
      final task = await _tasks.getById(reminder.taskId);
      await _reminders.markNotified(reminder.id, now);
      if (task == null || task.isClosed) continue;

      // Handle snooze
      if (task.snoozeUntil != null) {
        final localSnooze = task.snoozeUntil!.isUtc
            ? task.snoozeUntil!.toLocal()
            : task.snoozeUntil!;
        if (localSnooze.isAfter(now)) {
          // Still in snooze window; postpone overdue alerts until snooze expires
          continue;
        } else {
          // Snooze expired! Clear snoozeUntil
          await _tasks.update(task.copyWith(snoozeUntil: null, updatedAt: now));
        }
      }

      final isOverdueKind = reminder.kind == ReminderKind.overdue;
      final category = isOverdueKind
          ? NotificationCategory.overdue
          : (task.deadline != null &&
                    (task.deadline!.isUtc
                                ? task.deadline!.toLocal()
                                : task.deadline!)
                            .difference(now)
                            .abs() <=
                        AppConstants.dueSoonWindow
                ? NotificationCategory.dueSoon
                : NotificationCategory.upcoming);

      await _center.addIfAbsentToday(
        taskId: task.id,
        category: category,
        notification: AppNotification(
          id: _uuid.v4(),
          taskId: task.id,
          category: category,
          title: _titleForReminder(task, reminder),
          body: _bodyForReminder(task),
          createdAt: now,
        ),
      );

      // Bounded repeat-until-completed scheduling:
      // If task is overdue and incomplete, and repeatUntilCompleted is enabled
      final isOverdue = task.isOverdue(now: now);
      if (isOverdue &&
          task.repeatUntilCompleted &&
          task.currentRepeatCount < task.maxRepeatCount) {
        final nextCount = task.currentRepeatCount + 1;
        final nextTime = now.add(Duration(minutes: task.repeatIntervalMinutes));
        final nextNotifId = NotificationService.allocateNotificationId(taken);
        taken.add(nextNotifId);

        final nextReminder = TaskReminder(
          id: _uuid.v4(),
          taskId: task.id,
          kind: ReminderKind.overdue,
          scheduledAt: nextTime,
          notificationId: nextNotifId,
          createdAt: now,
        );

        await _reminders.upsert(nextReminder);
        await _tasks.update(
          task.copyWith(
            currentRepeatCount: nextCount,
            snoozeUntil: null,
            updatedAt: now,
          ),
        );

        await _notifications.scheduleReminder(
          task: task.copyWith(currentRepeatCount: nextCount),
          notificationId: nextNotifId,
          scheduledAt: nextTime,
          kind: ReminderKind.overdue,
        );
      }
    }

    // 2) Overdue sweep: mark statuses and raise one centre entry per task/day.
    await _tasks.markOverdue(now);
    final settings = await _settings.load();
    if (settings.overdueRemindersEnabled) {
      await _raiseOverdueEntries(now, settings);
    }
  }

  Future<void> _raiseOverdueEntries(DateTime now, UserSettings settings) async {
    final overdue = await _tasks.getTasks(
      filter: const TaskFilter(statuses: {TaskStatus.overdue}),
    );
    for (final task in overdue) {
      if (task.isSnoozed) continue;

      final added = await _center.addIfAbsentToday(
        taskId: task.id,
        category: NotificationCategory.overdue,
        notification: AppNotification(
          id: _uuid.v4(),
          taskId: task.id,
          category: NotificationCategory.overdue,
          title: task.customNotificationTitle ?? 'Task overdue',
          body: task.customNotificationBody ?? _overdueBody(task),
          createdAt: now,
        ),
      );
      if (added && settings.notificationsEnabled) {
        // A stable per-task id means each overdue task gets its own
        // notification, and repeated sweeps replace rather than stack.
        await _notifications.showNow(
          notificationId: _overdueNotificationId(task.id),
          title:
              task.customNotificationTitle ?? '⚠️ Task overdue: ${task.title}',
          body: task.customNotificationBody ?? _overdueBody(task),
          taskId: task.id,
          task: task,
        );
      }
    }
  }

  /// Derives a stable, positive 32-bit notification id from a task id so the
  /// overdue nudge for a given task is always the same.
  int _overdueNotificationId(String taskId) {
    final hash = taskId.hashCode & 0x7FFFFFFF;
    return (hash % 100000) + 400000;
  }

  String _titleForReminder(TaskItem task, TaskReminder reminder) {
    if (reminder.kind == ReminderKind.overdue) return 'Task overdue';
    if (reminder.kind == ReminderKind.atDeadline) {
      return 'Due now: ${task.title}';
    }
    return task.title;
  }

  String _bodyForReminder(TaskItem task) {
    final info = task.deadlineInfo();
    if (info.hasDeadline) {
      return '${task.title} is ${info.sentenceLabel}.';
    }
    return 'A reminder for ${task.title}.';
  }

  /// Reads naturally whether the task just slipped or has been overdue a while:
  /// "…was due 10 minutes ago." / "…was due today at 11:48 AM."
  String _overdueBody(TaskItem task) {
    final deadline = task.deadline;
    if (deadline == null) return '${task.title} has passed its deadline.';
    final local = deadline.isUtc ? deadline.toLocal() : deadline;
    final elapsed = DateTime.now().difference(local);
    if (elapsed.inMinutes < 60) {
      final minutes = elapsed.inMinutes.clamp(1, 59);
      return '${task.title} was due $minutes '
          '${minutes == 1 ? 'minute' : 'minutes'} ago.';
    }
    if (elapsed.inHours < 24) {
      final hours = elapsed.inHours;
      return '${task.title} was due $hours '
          '${hours == 1 ? 'hour' : 'hours'} ago.';
    }
    return '${task.title} was due on '
        '${local.day}/${local.month}.';
  }
}
