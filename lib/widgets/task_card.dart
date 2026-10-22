import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_text_styles.dart';
import '../core/theme/spacing.dart';
import '../core/utils/deadline_calculator.dart';
import '../models/category.dart';
import '../models/task_item.dart';
import '../providers/clock_provider.dart';
import 'priority_badge.dart';
import 'status_pill.dart';

/// The primary task row used across Home, Tasks and Calendar.
///
/// It is intentionally information-dense but calm: a completion control, the
/// title, one deadline line and one meta line. Optional trailing actions let
/// the dashboard show Complete/Reschedule on overdue items.
class TaskCard extends ConsumerWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.category,
    this.progress,
    this.onTap,
    this.onLongPress,
    this.onToggleComplete,
    this.onToggleSelect,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.trailing,
    this.showStatusPill = false,
    this.highlightOverdue = true,
  });

  final TaskItem task;
  final Category? category;
  final SubtaskProgress? progress;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onToggleSelect;
  final bool isSelected;
  final bool isSelectionMode;
  final Widget? trailing;
  final bool showStatusPill;
  final bool highlightOverdue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clock = ref.watch(currentClockProvider);
    final info = task.deadlineInfo(now: clock);
    final overdue = highlightOverdue && info.isOverdue;
    final completed = task.isCompleted;

    final overdueColor = isDark
        ? const Color(0xFFE98A85)
        : const Color(0xFFC0453F);

    return Semantics(
      button: onTap != null,
      label: _semanticsLabel(info),
      child: Material(
        color: isSelected
            ? scheme.primaryContainer.withValues(alpha: 0.35)
            : scheme.surfaceContainerLow,
        borderRadius: AppRadius.lgAll,
        child: InkWell(
          onTap: isSelectionMode ? onToggleSelect : onTap,
          onLongPress: onLongPress,
          borderRadius: AppRadius.lgAll,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.lgAll,
              border: Border.all(
                color: isSelected
                    ? scheme.primary
                    : (overdue && !completed
                          ? overdueColor.withValues(alpha: 0.35)
                          : scheme.outline),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(
              Spacing.sm,
              Spacing.md,
              Spacing.lg,
              Spacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) => onToggleSelect?.call(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  )
                else
                  _CompletionControl(
                    completed: completed,
                    onPressed: onToggleComplete,
                    color: overdue && !completed ? overdueColor : null,
                  ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.subtitle.copyWith(
                                color: completed
                                    ? scheme.onSurfaceVariant
                                    : scheme.onSurface,
                                decoration: completed
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (trailing != null) ...[
                            const SizedBox(width: Spacing.sm),
                            trailing!,
                          ],
                        ],
                      ),
                      if (task.description != null &&
                          task.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.description!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: Spacing.sm),
                      _MetaRow(
                        task: task,
                        category: category,
                        info: info,
                        overdue: overdue,
                        progress: progress,
                        showStatusPill: showStatusPill,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _semanticsLabel(DeadlineInfo info) {
    final buffer = StringBuffer(task.title);
    buffer.write(', ${task.priority.label} priority');
    if (info.hasDeadline) buffer.write(', ${info.calendarLabel}');
    if (info.isOverdue) buffer.write(', overdue');
    if (task.isCompleted) buffer.write(', completed');
    return buffer.toString();
  }
}

class _CompletionControl extends StatelessWidget {
  const _CompletionControl({
    required this.completed,
    this.onPressed,
    this.color,
  });

  final bool completed;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = color ?? scheme.primary;

    return Semantics(
      label: completed ? 'Mark as not completed' : 'Mark as completed',
      child: InkResponse(
        onTap: onPressed,
        radius: 24,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: completed ? accent : Colors.transparent,
              border: Border.all(
                color: completed ? accent : scheme.outline,
                width: 1.8,
              ),
            ),
            child: completed
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.task,
    required this.info,
    required this.overdue,
    required this.showStatusPill,
    this.category,
    this.progress,
  });

  final TaskItem task;
  final Category? category;
  final DeadlineInfo info;
  final bool overdue;
  final bool showStatusPill;
  final SubtaskProgress? progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final parts = <Widget>[];

    if (info.hasDeadline) {
      parts.add(
        DeadlineLabel(
          label: task.isCompleted ? info.calendarLabel : info.relativeLabel,
          isOverdue: overdue,
          isDueSoon: info.isDueToday || info.isDueTomorrow,
          icon: overdue ? Icons.warning_amber_rounded : Icons.schedule_rounded,
        ),
      );
    } else {
      parts.add(
        Text(
          'No deadline',
          style: AppTextStyles.caption.copyWith(color: scheme.onSurfaceVariant),
        ),
      );
    }

    if (category != null) {
      parts.add(_dot(scheme));
      parts.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category!.icon, size: 13, color: category!.color),
            const SizedBox(width: 4),
            Text(
              category!.name,
              style: AppTextStyles.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    } else {
      parts.add(_dot(scheme));
      parts.add(PriorityBadge(priority: task.priority));
    }

    if (task.isRecurring) {
      parts.add(_dot(scheme));
      parts.add(
        Icon(Icons.repeat_rounded, size: 13, color: scheme.onSurfaceVariant),
      );
    }

    if (progress != null && progress!.hasSubtasks) {
      parts.add(_dot(scheme));
      parts.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.checklist_rounded,
              size: 13,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              progress!.label,
              style: AppTextStyles.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: parts,
          ),
        ),
        if (showStatusPill)
          Padding(
            padding: const EdgeInsets.only(left: Spacing.xs),
            child: StatusPill(status: task.status, dense: true),
          ),
      ],
    );
  }

  Widget _dot(ColorScheme scheme) => Container(
    width: 3,
    height: 3,
    decoration: BoxDecoration(
      color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
      shape: BoxShape.circle,
    ),
  );
}

/// A slim linear progress indicator used for subtask progress.
class SubtaskProgressBar extends StatelessWidget {
  const SubtaskProgressBar({super.key, required this.progress});

  final SubtaskProgress progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: progress.fraction,
        minHeight: 5,
        backgroundColor: scheme.surfaceContainerHighest,
      ),
    );
  }
}
