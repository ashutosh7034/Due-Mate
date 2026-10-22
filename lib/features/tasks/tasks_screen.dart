import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/spacing.dart';
import '../../core/utils/date_x.dart';
import '../../core/utils/task_sorter.dart';
import '../../models/category.dart';
import '../../models/enums.dart';
import '../../models/task_item.dart';
import '../../providers/clock_provider.dart';
import '../../providers/task_controller.dart';
import '../../providers/task_providers.dart';
import '../../repositories/task_repository.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/task_card.dart';
import 'quick_add_sheet.dart';
import 'task_details_screen.dart';

/// The five views available in the task list.
enum TaskListView { all, today, upcoming, overdue, completed }

extension on TaskListView {
  String get label => switch (this) {
    TaskListView.all => 'All',
    TaskListView.today => 'Today',
    TaskListView.upcoming => 'Upcoming',
    TaskListView.overdue => 'Overdue',
    TaskListView.completed => 'Completed',
  };
}

/// Search + sort state for the task list.
class TaskListQuery {
  const TaskListQuery({
    this.view = TaskListView.all,
    this.sort = TaskSort.deadline,
    this.search = '',
    this.categoryId,
    this.priorities = const {},
  });

  final TaskListView view;
  final TaskSort sort;
  final String search;
  final String? categoryId;
  final Set<Priority> priorities;

  TaskListQuery copyWith({
    TaskListView? view,
    TaskSort? sort,
    String? search,
    Object? categoryId = _sentinel,
    Set<Priority>? priorities,
  }) {
    return TaskListQuery(
      view: view ?? this.view,
      sort: sort ?? this.sort,
      search: search ?? this.search,
      categoryId: identical(categoryId, _sentinel)
          ? this.categoryId
          : categoryId as String?,
      priorities: priorities ?? this.priorities,
    );
  }

  bool get hasActiveFilters => categoryId != null || priorities.isNotEmpty;

  static const Object _sentinel = Object();
}

final taskListQueryProvider =
    NotifierProvider<TaskListQueryNotifier, TaskListQuery>(
      TaskListQueryNotifier.new,
    );

class TaskListQueryNotifier extends Notifier<TaskListQuery> {
  @override
  TaskListQuery build() => const TaskListQuery();

  void setView(TaskListView view) => state = state.copyWith(view: view);

  void setSort(TaskSort sort) => state = state.copyWith(sort: sort);

  void setSearch(String search) => state = state.copyWith(search: search);

  void setCategory(String? id) => state = state.copyWith(categoryId: id);

  void togglePriority(Priority priority) {
    final next = {...state.priorities};
    if (!next.remove(priority)) next.add(priority);
    state = state.copyWith(priorities: next);
  }

  void applyFilters({
    TaskSort? sort,
    String? categoryId,
    Set<Priority>? priorities,
  }) {
    state = TaskListQuery(
      view: state.view,
      sort: sort ?? state.sort,
      search: state.search,
      categoryId: categoryId,
      priorities: priorities ?? state.priorities,
    );
  }

  void clearFilters() => state = TaskListQuery(
    view: state.view,
    sort: state.sort,
    search: state.search,
  );
}

final taskListResultsProvider = Provider<List<TaskItem>>((ref) {
  final query = ref.watch(taskListQueryProvider);
  final all = ref.watch(tasksValueProvider);
  final now = ref.watch(currentClockProvider);

  Iterable<TaskItem> filtered = all;

  // View buckets.
  switch (query.view) {
    case TaskListView.all:
      filtered = all;
    case TaskListView.today:
      filtered = all.where(
        (t) =>
            !t.isClosed &&
            t.deadline != null &&
            (t.deadline!.isSameDay(now) || t.isOverdue(now: now)),
      );
    case TaskListView.upcoming:
      filtered = all.where(
        (t) => !t.isClosed && t.deadline != null && t.deadline!.isAfter(now),
      );
    case TaskListView.overdue:
      filtered = all.where((t) => t.isOverdue(now: now));
    case TaskListView.completed:
      filtered = all.where((t) => t.status == TaskStatus.completed);
  }

  // Category + priority filters.
  if (query.categoryId != null) {
    filtered = filtered.where((t) => t.categoryId == query.categoryId);
  }
  if (query.priorities.isNotEmpty) {
    filtered = filtered.where((t) => query.priorities.contains(t.priority));
  }

  // Search across title, description and notes (case-insensitive).
  final search = query.search.trim().toLowerCase();
  if (search.isNotEmpty) {
    filtered = filtered.where((t) {
      final haystack = [
        t.title,
        t.description ?? '',
        t.notes ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(search);
    });
  }

  final list = filtered.toList();
  if (query.view == TaskListView.overdue || query.view == TaskListView.today) {
    return TaskSorter.byUrgency(list, now: now);
  }
  list.sort(TaskSorter.comparator(query.sort));
  return list;
});

/// The Tasks tab: search, filter, sort and browse every task.
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final _searchController = TextEditingController();
  bool _searchExpanded = false;
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _enterSelectionMode(String id) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (!_selectedIds.remove(id)) {
        _selectedIds.add(id);
      }
      if (_selectedIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _selectAll(List<TaskItem> tasks) {
    setState(() {
      _selectedIds.addAll(tasks.map((t) => t.id));
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _bulkComplete() async {
    final ids = _selectedIds.toList();
    final count = await ref.read(taskControllerProvider).completeMultiple(ids);
    _exitSelectionMode();
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Completed $count ${count == 1 ? 'task' : 'tasks'}.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _bulkDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${_selectedIds.length} tasks?'),
        content: const Text(
          'This will remove the selected tasks, subtasks, and their reminders. '
          'This action cannot be undone.',
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

    final ids = _selectedIds.toList();
    final count = await ref.read(taskControllerProvider).deleteMultiple(ids);
    _exitSelectionMode();
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted $count ${count == 1 ? 'task' : 'tasks'}.'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => ref.read(taskControllerProvider).undoDelete(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(taskListQueryProvider);
    final results = ref.watch(taskListResultsProvider);
    final categories = ref.watch(categoriesValueProvider);
    final progressMap = ref.watch(subtaskProgressProvider);
    final categoryById = {for (final c in categories) c.id: c};
    final progress = progressMap.value ?? const {};
    final scheme = Theme.of(context).colorScheme;

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
                if (_isSelectionMode) ...[
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Cancel selection',
                    onPressed: _exitSelectionMode,
                  ),
                  const SizedBox(width: Spacing.xs),
                  Expanded(
                    child: Text(
                      '${_selectedIds.length} selected',
                      style: AppTextStyles.headline,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Select all',
                    icon: const Icon(Icons.select_all_rounded),
                    onPressed: () => _selectAll(results),
                  ),
                ] else ...[
                  Expanded(child: Text('Tasks', style: AppTextStyles.headline)),
                  IconButton(
                    tooltip: 'Search',
                    onPressed: () {
                      setState(() => _searchExpanded = !_searchExpanded);
                      if (!_searchExpanded) {
                        _searchController.clear();
                        ref.read(taskListQueryProvider.notifier).setSearch('');
                      }
                    },
                    icon: Icon(
                      _searchExpanded
                          ? Icons.close_rounded
                          : Icons.search_rounded,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sort & filter',
                    onPressed: () => _showSortSheet(context, query),
                    icon: Badge(
                      isLabelVisible: query.hasActiveFilters,
                      smallSize: 8,
                      child: const Icon(Icons.tune_rounded),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_searchExpanded && !_isSelectionMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                0,
                Spacing.lg,
                Spacing.sm,
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search title, description or notes',
                  prefixIcon: const Icon(Icons.search_rounded),
                  isDense: true,
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(taskListQueryProvider.notifier)
                                .setSearch('');
                            setState(() {});
                          },
                        ),
                ),
                onChanged: (value) {
                  ref.read(taskListQueryProvider.notifier).setSearch(value);
                  setState(() {});
                },
              ),
            ),
          if (!_isSelectionMode) ...[
            _ViewTabs(
              selected: query.view,
              onSelected: (view) =>
                  ref.read(taskListQueryProvider.notifier).setView(view),
            ),
            if (query.hasActiveFilters)
              _ActiveFilters(query: query, categories: categories),
          ],
          Expanded(
            child: results.isEmpty
                ? _EmptyForView(
                    view: query.view,
                    isSearching: query.search.trim().isNotEmpty,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.lg,
                      Spacing.sm,
                      Spacing.lg,
                      120,
                    ),
                    itemCount: results.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: Spacing.sm),
                    itemBuilder: (context, index) {
                      final task = results[index];
                      final isSelected = _selectedIds.contains(task.id);

                      return TaskCard(
                        task: task,
                        category: categoryById[task.categoryId],
                        progress: progress[task.id],
                        showStatusPill: true,
                        isSelected: isSelected,
                        isSelectionMode: _isSelectionMode,
                        onLongPress: () {
                          if (!_isSelectionMode) {
                            _enterSelectionMode(task.id);
                          }
                        },
                        onToggleSelect: () => _toggleSelection(task.id),
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleSelection(task.id);
                          } else {
                            TaskDetailsScreen.open(context, task.id);
                          }
                        },
                        onToggleComplete: () async {
                          final controller = ref.read(taskControllerProvider);
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
                                  onPressed: () =>
                                      controller.reopenTask(task.id),
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
          if (_isSelectionMode)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.lg,
                vertical: Spacing.md,
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
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.error,
                          side: BorderSide(color: scheme.error),
                        ),
                        onPressed: _selectedIds.isEmpty ? null : _bulkDelete,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
                        label: Text('Delete (${_selectedIds.length})'),
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _selectedIds.isEmpty ? null : _bulkComplete,
                        icon: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                        ),
                        label: Text('Complete (${_selectedIds.length})'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showSortSheet(BuildContext context, TaskListQuery query) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SortFilterSheet(query: query),
    );
  }
}

class _ViewTabs extends StatelessWidget {
  const _ViewTabs({required this.selected, required this.onSelected});

  final TaskListView selected;
  final ValueChanged<TaskListView> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        itemCount: TaskListView.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: Spacing.sm),
        itemBuilder: (context, index) {
          final view = TaskListView.values[index];
          return _Chip(
            label: view.label,
            selected: view == selected,
            onTap: () => onSelected(view),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
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

class _ActiveFilters extends ConsumerWidget {
  const _ActiveFilters({required this.query, required this.categories});

  final TaskListQuery query;
  final List<Category> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final category = query.categoryId == null
        ? null
        : categories.where((c) => c.id == query.categoryId).firstOrNull;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.sm, Spacing.lg, 0),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.xs,
              children: [
                if (category != null)
                  _FilterPill(
                    label: category.name,
                    color: category.color,
                    onRemove: () => ref
                        .read(taskListQueryProvider.notifier)
                        .setCategory(null),
                  ),
                for (final priority in query.priorities)
                  _FilterPill(
                    label: '${priority.label} priority',
                    color: priority.color,
                    onRemove: () => ref
                        .read(taskListQueryProvider.notifier)
                        .togglePriority(priority),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () =>
                ref.read(taskListQueryProvider.notifier).clearFilters(),
            child: Text(
              'Clear',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.color,
    required this.onRemove,
  });

  final String label;
  final Color color;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: Spacing.md, right: Spacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.smAll,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: color)),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            icon: Icon(Icons.close_rounded, size: 14, color: color),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _EmptyForView extends StatelessWidget {
  const _EmptyForView({required this.view, required this.isSearching});

  final TaskListView view;
  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    if (isSearching) {
      return const EmptyState(
        compact: true,
        icon: Icons.search_off_rounded,
        title: 'No matching tasks',
        message: 'Try a different word, or clear your filters.',
      );
    }
    final (icon, title, message) = switch (view) {
      TaskListView.all => (
        Icons.check_circle_outline_rounded,
        'Nothing on your plate',
        'You have no tasks right now. Add one whenever you\u2019re ready.',
      ),
      TaskListView.today => (
        Icons.wb_sunny_outlined,
        'Your day is clear',
        'No tasks are due today. Enjoy the breathing room.',
      ),
      TaskListView.upcoming => (
        Icons.upcoming_rounded,
        'Nothing coming up',
        'Schedule something ahead so it doesn\u2019t sneak up on you.',
      ),
      TaskListView.overdue => (
        Icons.verified_outlined,
        'Nothing overdue',
        'Everything is on track. Keep it up.',
      ),
      TaskListView.completed => (
        Icons.task_alt_rounded,
        'No completed tasks yet',
        'Finished tasks will collect here so you can see your progress.',
      ),
    };
    return EmptyState(
      icon: icon,
      title: title,
      message: message,
      actionLabel: 'Add task',
      onAction: () => QuickAddSheet.show(context),
    );
  }
}

class _SortFilterSheet extends ConsumerStatefulWidget {
  const _SortFilterSheet({required this.query});

  final TaskListQuery query;

  @override
  ConsumerState<_SortFilterSheet> createState() => _SortFilterSheetState();
}

class _SortFilterSheetState extends ConsumerState<_SortFilterSheet> {
  late TaskSort _stagedSort;
  late Set<Priority> _stagedPriorities;
  late String? _stagedCategoryId;

  @override
  void initState() {
    super.initState();
    _stagedSort = widget.query.sort;
    _stagedPriorities = Set<Priority>.from(widget.query.priorities);
    _stagedCategoryId = widget.query.categoryId;
  }

  void _reset() {
    setState(() {
      _stagedSort = TaskSort.deadline;
      _stagedPriorities = {};
      _stagedCategoryId = null;
    });
  }

  void _apply() {
    ref.read(taskListQueryProvider.notifier).applyFilters(
          sort: _stagedSort,
          categoryId: _stagedCategoryId,
          priorities: _stagedPriorities,
        );
    Navigator.of(context).pop();
  }

  Color _priorityColor(Priority p) {
    return switch (p) {
      Priority.urgent => AppColors.priorityUrgent,
      Priority.high => AppColors.priorityHigh,
      Priority.medium => AppColors.priorityMedium,
      Priority.low => AppColors.priorityLow,
    };
  }

  IconData _priorityIcon(Priority p) {
    return switch (p) {
      Priority.urgent => Icons.error_outline_rounded,
      Priority.high => Icons.flag_rounded,
      Priority.medium => Icons.outlined_flag_rounded,
      Priority.low => Icons.arrow_downward_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final categories = ref.watch(categoriesValueProvider);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Standard Drag Handle
              const SizedBox(height: Spacing.sm),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.xl,
                  Spacing.sm,
                  Spacing.sm,
                  Spacing.xs,
                ),
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, color: scheme.primary, size: 22),
                    const SizedBox(width: Spacing.sm),
                    Text('Filters', style: AppTextStyles.title),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Scrollable filter criteria
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.xl,
                    Spacing.md,
                    Spacing.xl,
                    Spacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SORT BY SECTION
                      Text(
                        'SORT BY',
                        style: AppTextStyles.label.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      Wrap(
                        spacing: Spacing.sm,
                        runSpacing: Spacing.sm,
                        children: [
                          for (final sort in TaskSort.values)
                            ChoiceChip(
                              label: Text(_sortLabel(sort)),
                              selected: _stagedSort == sort,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _stagedSort = sort);
                                }
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: Spacing.xl),

                      // PRIORITY SECTION
                      Text(
                        'PRIORITY',
                        style: AppTextStyles.label.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      Wrap(
                        spacing: Spacing.sm,
                        runSpacing: Spacing.sm,
                        children: [
                          for (final priority in Priority.values) ...[
                            Builder(
                              builder: (context) {
                                final isSelected =
                                    _stagedPriorities.contains(priority);
                                final color = _priorityColor(priority);
                                return FilterChip(
                                  avatar: Icon(
                                    _priorityIcon(priority),
                                    size: 16,
                                    color: isSelected ? Colors.white : color,
                                  ),
                                  label: Text(priority.label),
                                  selected: isSelected,
                                  selectedColor: color,
                                  checkmarkColor: Colors.white,
                                  labelStyle: AppTextStyles.bodySmall.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : scheme.onSurface,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  side: BorderSide(
                                    color: isSelected ? color : scheme.outline,
                                  ),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _stagedPriorities.add(priority);
                                      } else {
                                        _stagedPriorities.remove(priority);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: Spacing.xl),

                      // CATEGORY SECTION
                      Text(
                        'CATEGORY',
                        style: AppTextStyles.label.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      Wrap(
                        spacing: Spacing.sm,
                        runSpacing: Spacing.sm,
                        children: [
                          ChoiceChip(
                            avatar: Icon(
                              Icons.apps_rounded,
                              size: 16,
                              color: _stagedCategoryId == null
                                  ? scheme.onPrimary
                                  : scheme.onSurfaceVariant,
                            ),
                            label: const Text('All'),
                            selected: _stagedCategoryId == null,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _stagedCategoryId = null);
                              }
                            },
                          ),
                          for (final category in categories)
                            ChoiceChip(
                              avatar: Icon(
                                category.icon,
                                size: 16,
                                color: _stagedCategoryId == category.id
                                    ? Colors.white
                                    : category.color,
                              ),
                              label: Text(category.name),
                              selected: _stagedCategoryId == category.id,
                              selectedColor: category.color,
                              labelStyle: TextStyle(
                                color: _stagedCategoryId == category.id
                                    ? Colors.white
                                    : null,
                                fontWeight: _stagedCategoryId == category.id
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              side: BorderSide(
                                color: _stagedCategoryId == category.id
                                    ? category.color
                                    : scheme.outline,
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  _stagedCategoryId =
                                      selected ? category.id : null;
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: Spacing.sm),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1),

              // Bottom Action Buttons
              Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _reset,
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: FilledButton(
                        onPressed: _apply,
                        child: const Text('Apply filters'),
                      ),
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

  String _sortLabel(TaskSort sort) => switch (sort) {
    TaskSort.deadline => 'Deadline',
    TaskSort.priority => 'Priority',
    TaskSort.created => 'Created',
    TaskSort.category => 'Category',
  };
}
