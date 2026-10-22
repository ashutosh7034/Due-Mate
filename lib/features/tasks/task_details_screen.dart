import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/spacing.dart';
import '../../core/utils/date_x.dart';
import '../../core/utils/deadline_calculator.dart';
import '../../models/enums.dart';
import '../../models/reminder.dart';
import '../../models/task_item.dart';
import '../../providers/clock_provider.dart';
import '../../providers/task_controller.dart';
import '../../providers/task_providers.dart';

import '../../routes/app_routes.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/task_card.dart';
import '../focus/focus_mode_screen.dart';
import 'reschedule_sheet.dart';
import 'snooze_sheet.dart';
import 'task_editor_sheet.dart';

/// The full detail view of a single task.
class TaskDetailsScreen extends ConsumerWidget {
  const TaskDetailsScreen({super.key, required this.taskId});

  final String taskId;

  static Future<void> open(BuildContext context, String taskId) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.taskDetails),
        builder: (_) => TaskDetailsScreen(taskId: taskId),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTask = ref.watch(taskByIdProvider(taskId));

    return Scaffold(
      appBar: AppBar(
        actions: [
          asyncTask.maybeWhen(
            data: (task) =>
                task == null ? const SizedBox.shrink() : _Actions(task: task),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: asyncTask.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _MissingTask(),
        data: (task) {
          if (task == null) return const _MissingTask();
          return _TaskDetailsBody(task: task);
        },
      ),
      bottomNavigationBar: asyncTask.maybeWhen(
        data: (task) => task == null ? null : _BottomActionBar(task: task),
        orElse: () => null,
      ),
    );
  }
}

class _MissingTask extends StatelessWidget {
  const _MissingTask();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 40),
            const SizedBox(height: Spacing.lg),
            Text('This task is no longer here', style: AppTextStyles.subtitle),
            const SizedBox(height: Spacing.xs),
            Text(
              'It may have been deleted.',
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskDetailsBody extends ConsumerWidget {
  const _TaskDetailsBody({required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final category = task.categoryId == null
        ? null
        : ref.watch(categoryByIdProvider(task.categoryId!));
    final subtasks = ref.watch(subtasksProvider(task.id)).value ?? const [];
    final reminders = ref.watch(remindersForTaskProvider(task.id)).value ?? [];
    final clock = ref.watch(currentClockProvider);
    final info = task.deadlineInfo(now: clock);

    final completedSubtasks = subtasks.where((s) => s.isCompleted).length;
    final progress = SubtaskProgress(
      completed: completedSubtasks,
      total: subtasks.length,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Spacing.xl,
        Spacing.sm,
        Spacing.xl,
        Spacing.xxxl,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                task.title,
                style: AppTextStyles.headline.copyWith(
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  decorationColor: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        if (task.description != null &&
            task.description!.trim().isNotEmpty) ...[
          const SizedBox(height: Spacing.sm),
          Text(
            task.description!,
            style: AppTextStyles.body.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: Spacing.lg),
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: [
            StatusPill(status: task.status),
            PriorityBadge(priority: task.priority),
            if (task.isRecurring)
              _Tag(
                icon: Icons.repeat_rounded,
                label: task.recurrenceType.label,
              ),
          ],
        ),
        if (task.isSnoozed) ...[
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            margin: const EdgeInsets.only(bottom: Spacing.md),
            decoration: BoxDecoration(
              color: scheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.snooze_rounded, color: scheme.onTertiaryContainer),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Snooze active',
                        style: AppTextStyles.subtitle.copyWith(
                          color: scheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Next reminder at ${AppDateFormat.dateAndTime(task.snoozeUntil!)}',
                        style: AppTextStyles.caption.copyWith(
                          color: scheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => SnoozeSheet.show(context, task),
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
        ],

        if (info.hasDeadline && !task.isCompleted) ...[
          _DeadlineCountdownCard(info: info, task: task),
          const SizedBox(height: Spacing.lg),
        ],

        _InfoCard(
          children: [
            _InfoRow(
              icon: Icons.schedule_rounded,
              label: 'Deadline',
              value: info.hasDeadline
                  ? AppDateFormat.dateAndTime(task.deadline!)
                  : 'No deadline',
              trailing: info.hasDeadline
                  ? DeadlineLabel(
                      label: info.relativeLabel,
                      isOverdue: info.isOverdue,
                      isDueSoon: info.isDueSoon,
                    )
                  : null,
            ),
            _InfoRow(
              icon: category?.icon ?? Icons.folder_outlined,
              iconColor: category?.color,
              label: 'Category',
              value: category?.name ?? 'Uncategorised',
            ),
            _InfoRow(
              icon: task.alarmType.icon,
              label: 'Alarm Type',
              value: task.alarmType.label,
            ),
            _InfoRow(
              icon: Icons.repeat_rounded,
              label: 'Repeat Policy',
              value: task.repeatUntilCompleted
                  ? 'Every ${task.repeatIntervalMinutes}m (${task.currentRepeatCount}/${task.maxRepeatCount} repeats sent)'
                  : 'Disabled',
            ),
            _InfoRow(
              icon: Icons.volume_up_outlined,
              label: 'Alert Style',
              value:
                  '${task.soundChoice.label} • ${task.vibrationChoice.label}',
            ),
            if (task.customNotificationTitle != null &&
                task.customNotificationTitle!.isNotEmpty)
              _InfoRow(
                icon: Icons.title_rounded,
                label: 'Custom Alert Title',
                value: task.customNotificationTitle!,
              ),
            if (task.completedAt != null)
              _InfoRow(
                icon: Icons.check_circle_outline_rounded,
                label: 'Completed',
                value: AppDateFormat.dateAndTime(task.completedAt!),
              ),
          ],
        ),

        if (progress.hasSubtasks) ...[
          const SizedBox(height: Spacing.xxl),
          _SectionTitle(
            title: 'Subtasks',
            trailing: '${progress.completed} / ${progress.total}',
          ),
          const SizedBox(height: Spacing.sm),
          SubtaskProgressBar(progress: progress),
          const SizedBox(height: Spacing.md),
          for (final subtask in subtasks) _SubtaskRow(subtask: subtask),
        ],

        const SizedBox(height: Spacing.xxl),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'REMINDERS',
              style: AppTextStyles.label.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            TextButton.icon(
              onPressed: () => TaskEditorSheet.show(context, existing: task),
              icon: const Icon(Icons.tune_rounded, size: 16),
              label: const Text('Edit Settings'),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        if (reminders.where((r) => r.enabled).isEmpty)
          Text(
            'No reminders scheduled.',
            style: AppTextStyles.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          )
        else
          for (final reminder in reminders.where((r) => r.enabled))
            _ReminderRow(reminder: reminder),

        if (task.notes != null && task.notes!.trim().isNotEmpty) ...[
          const SizedBox(height: Spacing.xxl),
          _SectionTitle(title: 'Notes'),
          const SizedBox(height: Spacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Spacing.lg),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: scheme.outline),
            ),
            child: Text(task.notes!, style: AppTextStyles.body),
          ),
        ],

        const SizedBox(height: Spacing.xxl),
        Divider(color: scheme.outline),
        const SizedBox(height: Spacing.md),
        Text(
          'Created ${AppDateFormat.dateAndTime(task.createdAt)}',
          style: AppTextStyles.caption.copyWith(color: scheme.onSurfaceVariant),
        ),
        Text(
          'Updated ${AppDateFormat.dateAndTime(task.updatedAt)}',
          style: AppTextStyles.caption.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: AppTextStyles.label.copyWith(color: scheme.onSurfaceVariant),
        ),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing!,
            style: AppTextStyles.caption.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: scheme.outline),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.sm,
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor ?? scheme.onSurfaceVariant),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(height: Spacing.xs),
                  trailing!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubtaskRow extends ConsumerWidget {
  const _SubtaskRow({required this.subtask});

  final TaskItem subtask;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: AppRadius.smAll,
      onTap: () => ref.read(taskControllerProvider).toggleSubtask(subtask.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        child: Row(
          children: [
            Icon(
              subtask.isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 22,
              color: subtask.isCompleted ? scheme.primary : scheme.outline,
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Text(
                subtask.title,
                style: AppTextStyles.bodySmall.copyWith(
                  decoration: subtask.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  color: subtask.isCompleted
                      ? scheme.onSurfaceVariant
                      : scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({required this.reminder});

  final TaskReminder reminder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isOverdueKind = reminder.kind == ReminderKind.overdue;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Row(
        children: [
          Icon(
            isOverdueKind
                ? Icons.warning_amber_rounded
                : reminder.kind == ReminderKind.atDeadline
                ? Icons.event_available_rounded
                : Icons.alarm_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: Spacing.md),
          Expanded(child: Text(reminder.label, style: AppTextStyles.bodySmall)),
          Text(
            AppDateFormat.relativeDayTime(reminder.scheduledAt),
            style: AppTextStyles.caption.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: Spacing.xs),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// App-bar overflow actions.
class _Actions extends ConsumerWidget {
  const _Actions({required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(taskControllerProvider);

    return PopupMenuButton<String>(
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            await TaskEditorSheet.show(context, existing: task);
          case 'snooze':
            await SnoozeSheet.show(context, task);
          case 'complete':
            final result = await controller.completeTask(task.id);
            if (!context.mounted) return;
            if (result.isSuccess) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Completed "${task.title}"'),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () => controller.reopenTask(task.id),
                  ),
                ),
              );
            } else {
              _snack(context, result, 'Failed');
            }
          case 'reopen':
            final result = await controller.reopenTask(task.id);
            if (!context.mounted) return;
            _snack(context, result, 'Task reopened');
          case 'progress':
            final result = await controller.setStatus(
              task.id,
              TaskStatus.inProgress,
            );
            if (!context.mounted) return;
            _snack(context, result, 'Marked in progress');
          case 'reschedule':
            await RescheduleSheet.show(context, task);
          case 'focus':
            await FocusModeScreen.open(context, task.id);
          case 'delete':
            await _confirmDelete(context, ref);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        if (task.isCompleted)
          const PopupMenuItem(value: 'reopen', child: Text('Reopen'))
        else
          const PopupMenuItem(value: 'complete', child: Text('Complete')),
        if (!task.isCompleted && task.status != TaskStatus.inProgress)
          const PopupMenuItem(
            value: 'progress',
            child: Text('Mark in progress'),
          ),
        if (task.hasDeadline && !task.isCompleted)
          const PopupMenuItem(value: 'snooze', child: Text('Snooze')),
        if (task.hasDeadline)
          const PopupMenuItem(value: 'reschedule', child: Text('Reschedule')),
        if (!task.isCompleted)
          const PopupMenuItem(
            value: 'focus',
            child: Text('Start focus session'),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Delete', style: TextStyle(color: Color(0xFFC0453F))),
        ),
      ],
    );
  }

  void _snack(BuildContext context, TaskSaveResult result, String success) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.isSuccess ? success : result.error ?? 'Failed'),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this task?'),
        content: const Text(
          'This will also remove its scheduled reminders and subtasks. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await ref.read(taskControllerProvider).deleteTask(task.id);
    if (!context.mounted) return;
    if (result.isSuccess) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${task.title}"'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => ref.read(taskControllerProvider).undoDelete(),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Could not delete the task.')),
      );
    }
  }
}

class _DeadlineCountdownCard extends StatelessWidget {
  const _DeadlineCountdownCard({required this.info, required this.task});

  final DeadlineInfo info;
  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overdue = info.isOverdue;
    final accent = overdue
        ? (isDark ? const Color(0xFFE98A85) : const Color(0xFFC0453F))
        : (info.isDueSoon
              ? (isDark ? const Color(0xFFE7B567) : const Color(0xFFC9821F))
              : scheme.primary);

    final icon = overdue
        ? Icons.warning_amber_rounded
        : (info.isDueSoon ? Icons.timer_outlined : Icons.hourglass_top_rounded);

    final title = overdue
        ? 'Task is Overdue'
        : (info.isDueToday ? 'Due Today' : 'Upcoming Deadline');
    final detail = info.relativeLabel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Spacing.sm),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.subtitle.copyWith(
                    color: accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  detail,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionBar extends ConsumerWidget {
  const _BottomActionBar({required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final controller = ref.read(taskControllerProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.sm,
        Spacing.lg,
        Spacing.lg,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => TaskEditorSheet.show(context, existing: task),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),
            ),
            if (task.hasDeadline && !task.isCompleted) ...[
              const SizedBox(width: Spacing.sm),
              IconButton.outlined(
                tooltip: 'Snooze reminder',
                onPressed: () => SnoozeSheet.show(context, task),
                icon: const Icon(Icons.snooze_rounded, size: 18),
              ),
              const SizedBox(width: Spacing.sm),
              IconButton.outlined(
                tooltip: 'Reschedule',
                onPressed: () => RescheduleSheet.show(context, task),
                icon: const Icon(Icons.event_repeat_rounded, size: 18),
              ),
            ],
            const SizedBox(width: Spacing.sm),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () async {
                  if (task.isCompleted) {
                    await controller.reopenTask(task.id);
                  } else {
                    await controller.completeTask(task.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Completed "${task.title}"'),
                        behavior: SnackBarBehavior.floating,
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () => controller.reopenTask(task.id),
                        ),
                      ),
                    );
                  }
                },
                icon: Icon(
                  task.isCompleted
                      ? Icons.replay_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 20,
                ),
                label: Text(task.isCompleted ? 'Reopen Task' : 'Complete Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
