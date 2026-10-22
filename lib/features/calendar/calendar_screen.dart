import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/spacing.dart';
import '../../core/utils/date_x.dart';
import '../../core/utils/task_sorter.dart';
import '../../models/enums.dart';
import '../../models/task_item.dart';
import '../../providers/settings_provider.dart';
import '../../providers/task_controller.dart';
import '../../providers/task_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/task_card.dart';
import '../tasks/quick_add_sheet.dart';
import '../tasks/task_details_screen.dart';

/// Month view with a per-day task list underneath.
///
/// Days are marked with a small dot whose colour encodes the "worst" state for
/// that day (overdue > high-priority > normal), keeping the month grid calm
/// rather than noisy.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksValueProvider);
    final categories = ref.watch(categoriesValueProvider);
    final settings = ref.watch(settingsProvider).value;
    final weekStartsMonday = settings?.weekStartsOnMonday ?? true;
    final categoryById = {for (final c in categories) c.id: c};

    // Bucket tasks by calendar day for quick lookup.
    final byDay = <DateTime, List<TaskItem>>{};
    for (final task in tasks) {
      final deadline = task.deadline;
      if (deadline == null) continue;
      final key = DateTime(deadline.year, deadline.month, deadline.day);
      byDay.putIfAbsent(key, () => []).add(task);
    }

    final selectedTasks = _tasksForDay(byDay, _selectedDay);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.lg,
              Spacing.lg,
              Spacing.sm,
            ),
            child: Row(
              children: [
                Text('Calendar', style: AppTextStyles.headline),
                const Spacer(),
                IconButton(
                  tooltip: 'Today',
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime.now();
                      _selectedDay = DateTime.now();
                    });
                  },
                  icon: const Icon(Icons.today_rounded),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: TableCalendar<TaskItem>(
              firstDay: DateTime.now().subtract(const Duration(days: 730)),
              lastDay: DateTime.now().add(const Duration(days: 730)),
              focusedDay: _focusedDay,
              calendarFormat: _format,
              startingDayOfWeek: weekStartsMonday
                  ? StartingDayOfWeek.monday
                  : StartingDayOfWeek.sunday,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',
                CalendarFormat.twoWeeks: '2 weeks',
                CalendarFormat.week: 'Week',
              },
              selectedDayPredicate: (day) => day.isSameDay(_selectedDay),
              eventLoader: (day) => _tasksForDay(byDay, day),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              onFormatChanged: (format) => setState(() => _format = format),
              onPageChanged: (focused) => _focusedDay = focused,
              headerStyle: HeaderStyle(
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  borderRadius: AppRadius.smAll,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                formatButtonTextStyle: AppTextStyles.caption,
                titleTextStyle: AppTextStyles.subtitle,
                leftChevronIcon: const Icon(Icons.chevron_left_rounded),
                rightChevronIcon: const Icon(Icons.chevron_right_rounded),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: AppTextStyles.caption.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                weekendStyle: AppTextStyles.caption.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
                defaultTextStyle: AppTextStyles.bodySmall,
                weekendTextStyle: AppTextStyles.bodySmall,
                markerDecoration: const BoxDecoration(shape: BoxShape.circle),
                markersMaxCount: 3,
                markersAutoAligned: false,
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return null;
                  return _DayMarkers(events: _sortBySeverity(events));
                },
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Row(
              children: [
                Text(
                  _selectedDay.isToday()
                      ? 'Today'
                      : AppDateFormat.fullDate(_selectedDay),
                  style: AppTextStyles.subtitle,
                ),
                const Spacer(),
                if (selectedTasks.isNotEmpty)
                  Text(
                    '${selectedTasks.length} '
                    '${selectedTasks.length == 1 ? 'task' : 'tasks'}',
                    style: AppTextStyles.caption.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Expanded(
            child: selectedTasks.isEmpty
                ? EmptyState(
                    compact: true,
                    icon: Icons.event_available_rounded,
                    title: 'Nothing due this day',
                    message:
                        'No deadlines on ${AppDateFormat.fullDate(_selectedDay)}.',
                    actionLabel: 'Add task',
                    onAction: () => QuickAddSheet.show(context),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.lg,
                      0,
                      Spacing.lg,
                      120,
                    ),
                    itemCount: selectedTasks.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: Spacing.sm),
                    itemBuilder: (context, index) {
                      final task = selectedTasks[index];
                      return TaskCard(
                        task: task,
                        category: categoryById[task.categoryId],
                        onTap: () => TaskDetailsScreen.open(context, task.id),
                        onToggleComplete: () => ref
                            .read(taskControllerProvider)
                            .completeTask(task.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<TaskItem> _tasksForDay(
    Map<DateTime, List<TaskItem>> byDay,
    DateTime day,
  ) {
    final key = DateTime(day.year, day.month, day.day);
    final items = byDay[key] ?? const [];
    return TaskSorter.byUrgency(items);
  }

  List<TaskItem> _sortBySeverity(List<TaskItem> tasks) {
    final sorted = [...tasks];
    sorted.sort((a, b) {
      int rank(TaskItem t) {
        if (t.isOverdue()) return 0;
        if (t.priority == Priority.urgent) return 1;
        if (t.priority == Priority.high) return 2;
        return 3;
      }

      return rank(a).compareTo(rank(b));
    });
    return sorted;
  }
}

/// Up to three coloured dots beneath a calendar day.
class _DayMarkers extends StatelessWidget {
  const _DayMarkers({required this.events});

  final List<TaskItem> events;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Positioned(
      bottom: 4,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final task in events.take(3))
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.isOverdue()
                    ? AppColors.overdueAccent(Theme.of(context).brightness)
                    : task.priority.isImportant
                    ? task.priority.color
                    : scheme.primary.withValues(alpha: 0.55),
              ),
            ),
        ],
      ),
    );
  }
}
