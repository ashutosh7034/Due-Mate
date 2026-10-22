import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/spacing.dart';
import '../../models/category.dart';
import '../../models/task_item.dart';
import '../../providers/task_controller.dart';
import '../../providers/task_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import '../../widgets/task_card.dart';
import '../tasks/quick_add_sheet.dart';
import '../tasks/reschedule_sheet.dart';
import '../tasks/snooze_sheet.dart';
import '../tasks/task_details_screen.dart';
import 'widgets/daily_summary_card.dart';

/// The Home screen: what needs attention, right now.
///
/// Ordering is deliberately Overdue → Due today → Upcoming so the answer to
/// "what should I do next?" is at the top without any interaction.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    final summary = ref.watch(dailySummaryProvider);
    final categories = ref.watch(categoriesValueProvider);
    final progressMap = ref.watch(subtaskProgressProvider);

    final categoryById = {for (final c in categories) c.id: c};
    final progress = progressMap.value ?? const {};

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          await ref.read(taskControllerProvider).refreshOverdue();
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  Spacing.lg,
                  Spacing.lg,
                  Spacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greeting(), style: AppTextStyles.headline),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      'Here\u2019s what needs your attention.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: Spacing.xl),
                    DailySummaryCard(summary: summary),
                  ],
                ),
              ),
            ),

            if (dashboard.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Your schedule is clear',
                  message:
                      'No deadlines are pressing right now. Enjoy the breathing room, '
                      'or add something you\u2019re working towards.',
                  actionLabel: 'Add task',
                  onAction: () => QuickAddSheet.show(context),
                ),
              )
            else ...[
              if (dashboard.overdue.isNotEmpty)
                _TaskSection(
                  title: 'Overdue',
                  count: dashboard.overdue.length,
                  accent: overdueAccent(context),

                  tasks: dashboard.overdue,
                  categoryById: categoryById,
                  progress: progress,
                  showActions: true,
                ),
              if (dashboard.dueToday.isNotEmpty)
                _TaskSection(
                  title: 'Due today',
                  count: dashboard.dueToday.length,
                  accent: Theme.of(context).colorScheme.primary,
                  tasks: dashboard.dueToday,
                  categoryById: categoryById,
                  progress: progress,
                ),
              if (dashboard.upcoming.isNotEmpty)
                _TaskSection(
                  title: 'Upcoming',
                  count: dashboard.upcoming.length,
                  tasks: dashboard.upcoming,
                  categoryById: categoryById,
                  progress: progress,
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 👋';
    if (hour < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }
}

class _TaskSection extends ConsumerWidget {
  const _TaskSection({
    required this.title,
    required this.tasks,
    required this.categoryById,
    required this.progress,
    this.count,
    this.accent,
    this.showActions = false,
  });

  final String title;
  final List<TaskItem> tasks;
  final Map<String, Category?> categoryById;
  final Map<String, SubtaskProgress> progress;
  final int? count;
  final Color? accent;
  final bool showActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.xl,
            Spacing.lg,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: SectionHeader(
              title: title,
              count: count,
              accentColor: accent,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          sliver: SliverList.separated(
            itemCount: tasks.length,
            separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskCard(
                task: task,
                category: categoryById[task.categoryId],
                progress: progress[task.id],
                onTap: () => TaskDetailsScreen.open(context, task.id),
                onToggleComplete: () async {
                  final controller = ref.read(taskControllerProvider);
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
                },
                trailing: showActions ? _OverdueActions(task: task) : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Compact Complete / Snooze / Reschedule affordances shown on overdue items.
class _OverdueActions extends ConsumerWidget {
  const _OverdueActions({required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: 'Overdue actions',
      icon: Icon(
        Icons.more_vert_rounded,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onSelected: (value) async {
        final controller = ref.read(taskControllerProvider);
        switch (value) {
          case 'complete':
            await controller.completeTask(task.id);
            if (!context.mounted) break;
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
          case 'snooze':
            await SnoozeSheet.show(context, task);
          case 'reschedule':
            await RescheduleSheet.show(context, task);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'complete',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.check_rounded),
            title: Text('Complete'),
          ),
        ),
        PopupMenuItem(
          value: 'snooze',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.snooze_rounded),
            title: Text('Snooze'),
          ),
        ),
        PopupMenuItem(
          value: 'reschedule',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.event_repeat_rounded),
            title: Text('Reschedule'),
          ),
        ),
      ],
    );
  }
}

/// Visual helper shared by the dashboard and task list.
Color overdueAccentFor(BuildContext context) =>
    AppColors.overdueAccent(Theme.of(context).brightness);
