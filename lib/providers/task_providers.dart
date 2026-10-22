import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/task_sorter.dart';
import '../models/category.dart';
import '../models/dashboard_data.dart';
import '../models/reminder.dart';
import '../models/task_item.dart';
import '../repositories/task_repository.dart';
import 'auth_provider.dart';
import 'clock_provider.dart';
import 'core_providers.dart';

/// Live list of every top-level task (open and closed), deadline-ordered for current user.
final allTasksProvider = StreamProvider<List<TaskItem>>((ref) {
  final user = ref.watch(currentUserProvider);
  return ref
      .watch(taskRepositoryProvider)
      .watchTasks(
        filter: TaskFilter(
          includeCompleted: true,
          userId: user?.id ?? 'default_user',
        ),
        sort: TaskSort.deadline,
      );
});

/// Same data as [allTasksProvider] but synchronously readable.
final tasksValueProvider = Provider<List<TaskItem>>((ref) {
  return ref.watch(allTasksProvider).value ?? const [];
});

/// All categories.
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchAll();
});

final categoriesValueProvider = Provider<List<Category>>((ref) {
  return ref.watch(categoriesProvider).value ?? const [];
});

final categoryByIdProvider = Provider.family<Category?, String>((ref, id) {
  final categories = ref.watch(categoriesValueProvider);
  for (final category in categories) {
    if (category.id == id) return category;
  }
  return null;
});

/// A single task, live.
final taskByIdProvider = StreamProvider.family<TaskItem?, String>((ref, id) {
  return ref.watch(taskRepositoryProvider).watchById(id);
});

/// Subtasks of a task.
final subtasksProvider = StreamProvider.family<List<TaskItem>, String>((
  ref,
  parentId,
) {
  return ref.watch(taskRepositoryProvider).watchSubtasks(parentId);
});

/// Reminders stored for a task.

final remindersForTaskProvider =
    StreamProvider.family<List<TaskReminder>, String>((ref, taskId) {
      return ref.watch(reminderRepositoryProvider).watchForTask(taskId);
    });

/// All reminders across tasks.
final allRemindersProvider = StreamProvider<List<TaskReminder>>((ref) {
  return ref.watch(reminderRepositoryProvider).watchAll();
});

/// Subtask progress for every top-level task, keyed by parent id.
///
/// A single derived provider — rather than a family keyed by a list — so the
/// query runs once per data change instead of once per widget rebuild.
final subtaskProgressProvider = FutureProvider<Map<String, SubtaskProgress>>((
  ref,
) async {
  final tasks = ref.watch(tasksValueProvider);
  final ids = tasks.map((t) => t.id).toList(growable: false);
  return ref.watch(taskRepositoryProvider).progressFor(ids);
});

/// Derived dashboard data — refreshed continuously via the ticking clock.
final dashboardProvider = Provider<DashboardData>((ref) {
  final tasks = ref.watch(tasksValueProvider);
  final clock = ref.watch(currentClockProvider);
  return TaskSorter.dashboard(tasks, clock);
});

/// Derived daily summary — refreshed continuously via the ticking clock.
final dailySummaryProvider = Provider<DailySummary>((ref) {
  final tasks = ref.watch(tasksValueProvider);
  final clock = ref.watch(currentClockProvider);
  return TaskSorter.dailySummary(tasks, clock);
});

/// The task the user is focusing on, if Focus Mode is active.
class FocusedTaskId extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String id) => state = id;

  void clear() => state = null;
}

final focusedTaskIdProvider = NotifierProvider<FocusedTaskId, String?>(
  FocusedTaskId.new,
);
