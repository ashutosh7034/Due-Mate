import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/spacing.dart';
import '../../core/utils/date_x.dart';
import '../../models/app_notification.dart';
import '../../models/enums.dart';
import '../../models/reminder.dart';
import '../../models/task_item.dart';
import '../../providers/clock_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/task_providers.dart';
import '../../widgets/empty_state.dart';
import '../tasks/task_details_screen.dart';

enum AlertFilter {
  all('All'),
  upcoming('Upcoming'),
  snoozed('Snoozed'),
  repeating('Repeating'),
  dueSoon('Due soon'),
  overdue('Overdue'),
  delivered('Delivered'),
  completed('Completed');

  const AlertFilter(this.label);
  final String label;
}

/// The in-app notification and alert centre, separating scheduled upcoming
/// reminders from confirmed delivered notification history.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  AlertFilter _filter = AlertFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reminderServiceProvider).processDueNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final remindersAsync = ref.watch(allRemindersProvider);
    final tasksAsync = ref.watch(allTasksProvider);
    final unread = ref.watch(unreadNotificationCountProvider).value ?? 0;
    final clock = ref.watch(currentClockProvider);

    final tasks = tasksAsync.value ?? const [];
    final taskMap = {for (final t in tasks) t.id: t};

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.lg,
              Spacing.sm,
              Spacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Alerts', style: AppTextStyles.headline),
                      if (unread > 0)
                        Text(
                          '$unread unread in history',
                          style: AppTextStyles.caption.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (unread > 0)
                  TextButton(
                    onPressed: () =>
                        ref.read(notificationRepositoryProvider).markAllRead(),
                    child: const Text('Mark all read'),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              children: [
                for (final f in AlertFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: Spacing.sm),
                    child: _FilterChip(
                      label: f.label,
                      selected: _filter == f,
                      onTap: () => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(reminderServiceProvider)
                    .processDueNotifications();
                ref.read(currentClockProvider.notifier).refresh();
              },
              child: notificationsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Could not load alerts',
                  message: 'Something went wrong reading your notifications.',
                ),
                data: (deliveredItems) {
                  final allReminders = remindersAsync.value ?? const [];

                  // Upcoming active reminders (future, enabled, task not completed)
                  final upcomingReminders =
                      allReminders.where((r) {
                        if (!r.enabled) return false;
                        final localScheduled = r.scheduledAt.isUtc
                            ? r.scheduledAt.toLocal()
                            : r.scheduledAt;
                        if (!localScheduled.isAfter(clock)) return false;
                        final task = taskMap[r.taskId];
                        return task != null && !task.isCompleted;
                      }).toList()..sort(
                        (a, b) => a.scheduledAt.compareTo(b.scheduledAt),
                      );

                  // Filter delivered notifications
                  final filteredDelivered = deliveredItems.where((n) {
                    final task = n.taskId != null ? taskMap[n.taskId] : null;
                    switch (_filter) {
                      case AlertFilter.all:
                      case AlertFilter.delivered:
                        return true;
                      case AlertFilter.upcoming:
                      case AlertFilter.snoozed:
                      case AlertFilter.repeating:
                        return false;
                      case AlertFilter.dueSoon:
                        return n.category == NotificationCategory.dueSoon ||
                            (task != null &&
                                task.deadlineInfo(now: clock).isDueSoon);
                      case AlertFilter.overdue:
                        return n.category == NotificationCategory.overdue ||
                            (task != null &&
                                task.deadlineInfo(now: clock).isOverdue);
                      case AlertFilter.completed:
                        return n.category == NotificationCategory.completed ||
                            (task != null && task.isCompleted);
                    }
                  }).toList();

                  // Filter upcoming reminders
                  final filteredUpcoming = upcomingReminders.where((r) {
                    final task = taskMap[r.taskId];
                    switch (_filter) {
                      case AlertFilter.all:
                      case AlertFilter.upcoming:
                        return true;
                      case AlertFilter.snoozed:
                        return task != null && task.isSnoozed;
                      case AlertFilter.repeating:
                        return task != null && task.repeatUntilCompleted;
                      case AlertFilter.dueSoon:
                        return task != null &&
                            task.deadlineInfo(now: clock).isDueSoon;
                      case AlertFilter.overdue:
                        return r.kind == ReminderKind.overdue ||
                            (task != null &&
                                task.deadlineInfo(now: clock).isOverdue);
                      case AlertFilter.delivered:
                      case AlertFilter.completed:
                        return false;
                    }
                  }).toList();

                  if (filteredUpcoming.isEmpty && filteredDelivered.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.15,
                        ),
                        EmptyState(
                          icon: Icons.notifications_none_rounded,
                          title: _emptyTitleForFilter(_filter),
                          message: _emptyMessageForFilter(_filter),
                        ),
                      ],
                    );
                  }

                  return CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          Spacing.lg,
                          0,
                          Spacing.lg,
                          120,
                        ),
                        sliver: SliverMainAxisGroup(
                          slivers: [
                            if (filteredUpcoming.isNotEmpty) ...[
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: Spacing.sm,
                                  ),
                                  child: _SectionHeader(
                                    title: 'Scheduled Reminders',
                                    count: filteredUpcoming.length,
                                    badgeColor: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                ),
                              ),
                              SliverList.separated(
                                itemCount: filteredUpcoming.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: Spacing.sm),
                                itemBuilder: (context, index) {
                                  final reminder = filteredUpcoming[index];
                                  return _ScheduledReminderCard(
                                    reminder: reminder,
                                    task: taskMap[reminder.taskId],
                                    clock: clock,
                                    onTap: () {
                                      TaskDetailsScreen.open(
                                        context,
                                        reminder.taskId,
                                      );
                                    },
                                  );
                                },
                              ),
                              const SliverToBoxAdapter(
                                child: SizedBox(height: Spacing.md),
                              ),
                            ],
                            if (filteredDelivered.isNotEmpty) ...[
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: Spacing.sm,
                                  ),
                                  child: _SectionHeader(
                                    title: 'Delivered History',
                                    count: filteredDelivered.length,
                                    badgeColor: Theme.of(context)
                                        .colorScheme
                                        .secondary,
                                  ),
                                ),
                              ),
                              SliverList.separated(
                                itemCount: filteredDelivered.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: Spacing.sm),
                                itemBuilder: (context, index) {
                                  final notification = filteredDelivered[index];
                                  return _NotificationCard(
                                    notification: notification,
                                    onTap: () => _handleTap(notification),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _emptyTitleForFilter(AlertFilter filter) => switch (filter) {
    AlertFilter.all => 'Nothing to catch up on',
    AlertFilter.upcoming => 'No upcoming reminders',
    AlertFilter.snoozed => 'No snoozed reminders',
    AlertFilter.repeating => 'No repeating reminders',
    AlertFilter.dueSoon => 'No due-soon alerts',
    AlertFilter.overdue => 'No overdue alerts',
    AlertFilter.delivered => 'No delivered notification history',
    AlertFilter.completed => 'No completed alerts',
  };

  String _emptyMessageForFilter(AlertFilter filter) => switch (filter) {
    AlertFilter.all => 'Scheduled task reminders and past notification history will appear here.',
    AlertFilter.upcoming =>
      'Reminders scheduled for future deadlines will appear here.',
    AlertFilter.snoozed =>
      'Reminders currently snoozed will appear here until they expire.',
    AlertFilter.repeating =>
      'Tasks configured to repeat alarms until completed will appear here.',
    AlertFilter.dueSoon =>
      'Deadlines occurring in the next 48 hours will appear here.',
    AlertFilter.overdue => 'Tasks that passed their deadline will appear here.',
    AlertFilter.delivered =>
      'Confirmed notification records will be recorded here after delivery.',
    AlertFilter.completed =>
      'Notifications for finished tasks will appear here.',
  };

  Future<void> _handleTap(AppNotification notification) async {
    await ref.read(notificationRepositoryProvider).markRead(notification.id);
    if (notification.taskId != null && mounted) {
      await TaskDetailsScreen.open(context, notification.taskId!);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.badgeColor,
  });

  final String title;
  final int count;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: AppTextStyles.label.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: AppTextStyles.caption.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primary : scheme.surfaceContainerLow,
      borderRadius: AppRadius.smAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smAll,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.smAll,
            border: Border.all(
              color: selected ? scheme.primary : scheme.outline,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: selected ? scheme.onPrimary : scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Card showing an active scheduled reminder waiting to fire via Android AlarmManager.
class _ScheduledReminderCard extends StatelessWidget {
  const _ScheduledReminderCard({
    required this.reminder,
    required this.task,
    required this.clock,
    required this.onTap,
  });

  final TaskReminder reminder;
  final TaskItem? task;
  final DateTime clock;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOverdueKind = reminder.kind == ReminderKind.overdue;
    final isSnoozed = task?.isSnoozed ?? false;
    final isRepeating =
        (task?.repeatUntilCompleted ?? false) &&
        (task?.deadlineInfo(now: clock).isOverdue ?? false);

    final badgeText = isSnoozed
        ? 'SNOOZED'
        : (isRepeating
              ? 'REPEATING'
              : (isOverdueKind ? 'OVERDUE' : 'SCHEDULED'));

    final accent = isSnoozed
        ? (isDark ? const Color(0xFFF39C12) : const Color(0xFFD68910))
        : (isOverdueKind
              ? (isDark ? const Color(0xFFE98A85) : const Color(0xFFC0453F))
              : (reminder.kind == ReminderKind.atDeadline
                    ? (isDark
                          ? const Color(0xFFE7B567)
                          : const Color(0xFFC9821F))
                    : scheme.primary));

    final icon = isSnoozed
        ? Icons.snooze_rounded
        : (isOverdueKind
              ? Icons.warning_amber_rounded
              : (reminder.kind == ReminderKind.atDeadline
                    ? Icons.event_available_rounded
                    : Icons.alarm_rounded));

    final localScheduled = reminder.scheduledAt.isUtc
        ? reminder.scheduledAt.toLocal()
        : reminder.scheduledAt;
    final remaining = localScheduled.difference(clock);
    final remainingStr = remaining.isNegative
        ? 'due now'
        : 'in ${DurationFormat.compact(remaining)}';

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: AppRadius.lgAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          padding: const EdgeInsets.all(Spacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(icon, size: 19, color: accent),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task?.title ?? 'Task Reminder',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.subtitle.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeText,
                            style: AppTextStyles.caption.copyWith(
                              color: accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reminder.label,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${AppDateFormat.relativeDayTime(localScheduled)} ($remainingStr)',
                          style: AppTextStyles.caption.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'View task',
                          style: AppTextStyles.caption.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card showing confirmed delivered notification history from the database.
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    late final Color accent;
    switch (notification.category) {
      case NotificationCategory.overdue:
        accent = isDark ? const Color(0xFFE98A85) : const Color(0xFFC0453F);
      case NotificationCategory.dueSoon:
        accent = isDark ? const Color(0xFFE7B567) : const Color(0xFFC9821F);
      case NotificationCategory.completed:
        accent = isDark ? const Color(0xFF64D3A3) : const Color(0xFF2E9E6B);
      case NotificationCategory.upcoming:
      case NotificationCategory.system:
        accent = scheme.primary;
    }

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: AppRadius.lgAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            border: Border.all(
              color: notification.isUnread
                  ? accent.withValues(alpha: 0.5)
                  : scheme.outline,
            ),
          ),
          padding: const EdgeInsets.all(Spacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(
                  notification.category.icon,
                  size: 19,
                  color: accent,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.subtitle.copyWith(
                              fontWeight: notification.isUnread
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'DELIVERED',
                            style: AppTextStyles.caption.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        if (notification.isUnread) ...[
                          const SizedBox(width: Spacing.xs),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    Row(
                      children: [
                        Text(
                          AppDateFormat.relativeDayTime(notification.createdAt),
                          style: AppTextStyles.caption.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        if (notification.hasTask)
                          Text(
                            'View task',
                            style: AppTextStyles.caption.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
