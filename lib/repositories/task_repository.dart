import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../core/database/database.dart';
import '../models/enums.dart';
import '../models/task_item.dart';
import 'mappers.dart';

/// Sort options offered in the task list.
enum TaskSort { deadline, priority, created, category }

/// A filter applied to the task list.
class TaskFilter {
  const TaskFilter({
    this.categoryId,
    this.priorities = const {},
    this.statuses = const {},
    this.search,
    this.includeCompleted = false,
    this.userId,
  });

  final String? categoryId;
  final Set<Priority> priorities;
  final Set<TaskStatus> statuses;
  final String? search;
  final bool includeCompleted;
  final String? userId;

  bool get isActive =>
      categoryId != null ||
      priorities.isNotEmpty ||
      statuses.isNotEmpty ||
      (search != null && search!.trim().isNotEmpty);

  TaskFilter copyWith({
    Object? categoryId = _sentinel,
    Set<Priority>? priorities,
    Set<TaskStatus>? statuses,
    Object? search = _sentinel,
    bool? includeCompleted,
    Object? userId = _sentinel,
  }) {
    return TaskFilter(
      categoryId: identical(categoryId, _sentinel)
          ? this.categoryId
          : categoryId as String?,
      priorities: priorities ?? this.priorities,
      statuses: statuses ?? this.statuses,
      search: identical(search, _sentinel) ? this.search : search as String?,
      includeCompleted: includeCompleted ?? this.includeCompleted,
      userId: identical(userId, _sentinel) ? this.userId : userId as String?,
    );
  }

  static const Object _sentinel = Object();
}

/// CRUD + queries for tasks and their subtasks.
///
/// This is the only class that knows how to talk to Drift for tasks. The
/// notification service observes mutations through [TaskRepository] so
/// reminders never drift out of sync with the data.
class TaskRepository {
  TaskRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  String newId() => _uuid.v4();

  // ---- Reads ------------------------------------------------------------

  /// All top-level tasks (no subtasks) matching [filter], ordered by [sort].
  ///
  /// Ordering happens at the query/sort level only — never by rewriting
  /// user data.
  Future<List<TaskItem>> getTasks({
    TaskFilter filter = const TaskFilter(),
    TaskSort sort = TaskSort.deadline,
  }) async {
    final query = _db.select(_db.tasks)..where((t) => t.parentTaskId.isNull());

    _applyFilter(query, filter);
    _applySort(query, sort);

    final rows = await query.get();
    return rows.map(Mappers.taskFromRow).toList();
  }

  /// Live stream version of [getTasks], used by the UI.
  Stream<List<TaskItem>> watchTasks({
    TaskFilter filter = const TaskFilter(),
    TaskSort sort = TaskSort.deadline,
  }) {
    final query = _db.select(_db.tasks)..where((t) => t.parentTaskId.isNull());
    _applyFilter(query, filter);
    _applySort(query, sort);
    return query.watch().map((rows) => rows.map(Mappers.taskFromRow).toList());
  }

  Future<TaskItem?> getById(String id) async {
    final row = await (_db.select(
      _db.tasks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : Mappers.taskFromRow(row);
  }

  Stream<TaskItem?> watchById(String id) =>
      (_db.select(_db.tasks)..where((t) => t.id.equals(id)))
          .watchSingleOrNull()
          .map((row) => row == null ? null : Mappers.taskFromRow(row));

  /// Direct children of [parentId], ordered by `sortOrder`.
  Future<List<TaskItem>> getSubtasks(String parentId) async {
    final rows =
        await (_db.select(_db.tasks)
              ..where((t) => t.parentTaskId.equals(parentId))
              ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
            .get();
    return rows.map(Mappers.taskFromRow).toList();
  }

  Stream<List<TaskItem>> watchSubtasks(String parentId) =>
      (_db.select(_db.tasks)
            ..where((t) => t.parentTaskId.equals(parentId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch()
          .map((rows) => rows.map(Mappers.taskFromRow).toList());

  /// Tasks that belong to the same recurrence chain as [sourceId], plus the
  /// chain's origin task (which has a null `recurrenceSourceId`). Used to
  /// avoid duplicate chains without scanning the whole table.
  Future<List<TaskItem>> getByRecurrenceSource(String sourceId) async {
    final rows =
        await (_db.select(_db.tasks)..where(
              (t) =>
                  t.recurrenceSourceId.equals(sourceId) | t.id.equals(sourceId),
            ))
            .get();
    return rows.map(Mappers.taskFromRow).toList();
  }

  /// Progress for a set of parents, keyed by parent id. One query for the
  /// whole list — avoids the N+1 problem on the dashboard.
  Future<Map<String, SubtaskProgress>> progressFor(
    Iterable<String> parentIds,
  ) async {
    if (parentIds.isEmpty) return const {};
    final ids = parentIds.toList();
    final rows = await (_db.select(
      _db.tasks,
    )..where((t) => t.parentTaskId.isIn(ids))).get();

    final totals = <String, int>{};
    final completed = <String, int>{};
    for (final row in rows) {
      final parent = row.parentTaskId;
      if (parent == null) continue;
      totals[parent] = (totals[parent] ?? 0) + 1;
      if (row.status == TaskStatus.completed) {
        completed[parent] = (completed[parent] ?? 0) + 1;
      }
    }
    return {
      for (final id in ids)
        id: SubtaskProgress(
          completed: completed[id] ?? 0,
          total: totals[id] ?? 0,
        ),
    };
  }

  /// Count of open tasks that are already past their deadline.
  Future<int> overdueCount({String? userId, DateTime? now}) async {
    final clock = now ?? DateTime.now();
    final count = _db.tasks.id.count();
    var expr =
        _db.tasks.parentTaskId.isNull() &
        _db.tasks.deadline.isNotNull() &
        _db.tasks.deadline.isSmallerThanValue(clock.toUtc()) &
        _openStatus();
    if (userId != null) {
      expr =
          expr & (_db.tasks.userId.equals(userId) | _db.tasks.userId.isNull());
    }
    final query = _db.selectOnly(_db.tasks)
      ..addColumns([count])
      ..where(expr);
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  // ---- Writes -----------------------------------------------------------

  Future<void> insert(TaskItem task) async {
    await _db.into(_db.tasks).insert(Mappers.taskToCompanion(task));
  }

  /// Inserts or replaces by primary key.
  Future<void> upsert(TaskItem task) async {
    await _db
        .into(_db.tasks)
        .insertOnConflictUpdate(Mappers.taskToCompanion(task));
  }

  /// Writes only the mutable, user-editable fields. Leaves `createdAt` and
  /// subtasks untouched.
  Future<void> update(TaskItem task) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(task.id))).write(
      TasksCompanion(
        title: Value(task.title),
        description: Value(task.description),
        notes: Value(task.notes),
        categoryId: Value(task.categoryId),
        priority: Value(task.priority),
        status: Value(task.status),
        deadline: Value(task.deadline?.toUtc()),
        isRecurring: Value(task.isRecurring),
        recurrenceType: Value(task.recurrenceType),
        recurrenceDays: Value(task.recurrenceDays),
        recurrenceSourceId: Value(task.recurrenceSourceId),
        completedAt: Value(task.completedAt?.toUtc()),
        alarmType: Value(task.alarmType),
        repeatUntilCompleted: Value(task.repeatUntilCompleted),
        repeatIntervalMinutes: Value(task.repeatIntervalMinutes),
        maxRepeatCount: Value(task.maxRepeatCount),
        currentRepeatCount: Value(task.currentRepeatCount),
        customNotificationTitle: Value(task.customNotificationTitle),
        customNotificationBody: Value(task.customNotificationBody),
        soundChoice: Value(task.soundChoice),
        vibrationChoice: Value(task.vibrationChoice),
        snoozeUntil: Value(task.snoozeUntil?.toUtc()),
        sortOrder: Value(task.sortOrder),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Deletes a task and (via FK cascade) its subtasks and reminders.
  Future<void> delete(String id) async {
    await (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();
  }

  /// Bulk status update — used by the overdue sweep.
  Future<int> markOverdue(DateTime now) async {
    return (_db.update(_db.tasks)..where(
          (t) =>
              t.parentTaskId.isNull() &
              t.deadline.isNotNull() &
              t.deadline.isSmallerThanValue(now.toUtc()) &
              t.status.isNotInValues(const [
                TaskStatus.completed,
                TaskStatus.cancelled,
                TaskStatus.overdue,
              ]),
        ))
        .write(
          TasksCompanion(
            status: const Value(TaskStatus.overdue),
            updatedAt: Value(now.toUtc()),
          ),
        );
  }

  // ---- Internals --------------------------------------------------------

  Expression<bool> _openStatus() => _db.tasks.status.isNotInValues(const [
    TaskStatus.completed,
    TaskStatus.cancelled,
  ]);

  void _applyFilter(
    SimpleSelectStatement<$TasksTable, TaskRow> query,
    TaskFilter filter,
  ) {
    query.where((t) {
      Expression<bool> expr = const Constant(true);

      if (filter.userId != null) {
        expr = expr & (t.userId.equals(filter.userId!) | t.userId.isNull());
      }
      if (filter.categoryId != null) {
        expr = expr & t.categoryId.equals(filter.categoryId!);
      }
      if (filter.priorities.isNotEmpty) {
        expr = expr & t.priority.isInValues(filter.priorities);
      }
      if (filter.statuses.isNotEmpty) {
        expr = expr & t.status.isInValues(filter.statuses);
      } else if (!filter.includeCompleted) {
        expr =
            expr &
            t.status.isNotInValues(const [
              TaskStatus.completed,
              TaskStatus.cancelled,
            ]);
      }
      final search = filter.search?.trim();
      if (search != null && search.isNotEmpty) {
        final like = '%${search.toLowerCase()}%';
        expr =
            expr &
            (t.title.lower().like(like) |
                t.description.lower().like(like) |
                t.notes.lower().like(like));
      }
      return expr;
    });
  }

  void _applySort(
    SimpleSelectStatement<$TasksTable, TaskRow> query,
    TaskSort sort,
  ) {
    switch (sort) {
      case TaskSort.deadline:
        // Tasks without a deadline sink to the bottom; ties broken by priority.
        query.orderBy([
          (t) => OrderingTerm(
            expression: t.deadline.isNull(),
            mode: OrderingMode.asc,
          ),
          (t) => OrderingTerm.asc(t.deadline),
          // Stored index is low=0 … urgent=3, so descending is most urgent first.
          (t) => OrderingTerm.desc(t.priority),
        ]);
      case TaskSort.priority:
        query.orderBy([
          (t) => OrderingTerm.desc(t.priority),
          (t) => OrderingTerm(expression: t.deadline.isNull()),
          (t) => OrderingTerm.asc(t.deadline),
        ]);
      case TaskSort.created:
        query.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
      case TaskSort.category:
        query.orderBy([
          (t) => OrderingTerm(expression: t.categoryId.isNull()),
          (t) => OrderingTerm.asc(t.categoryId),
          (t) => OrderingTerm(expression: t.deadline.isNull()),
          (t) => OrderingTerm.asc(t.deadline),
        ]);
    }
  }
}
