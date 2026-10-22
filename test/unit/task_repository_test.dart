import 'package:duemate/core/database/database.dart';
import 'package:duemate/models/category.dart';
import 'package:duemate/models/enums.dart';
import 'package:duemate/models/task_item.dart';
import 'package:duemate/repositories/category_repository.dart';
import 'package:duemate/repositories/task_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late TaskRepository repo;
  late CategoryRepository categoryRepo;

  setUp(() {
    db = openTestDatabase();
    repo = TaskRepository(db);
    categoryRepo = CategoryRepository(db);
  });

  /// Categories referenced by tasks must exist (FK constraint).
  Future<void> seedCategory(String id) async {
    await categoryRepo.upsert(
      Category(
        id: id,
        name: id,
        iconKey: 'folder',
        color: const Color(0xFF2B4A80),
        createdAt: DateTime(2026, 1, 1),
      ),
    );
  }

  tearDown(() async {
    await db.close();
  });

  TaskItem buildTask({
    String? id,
    required String title,
    DateTime? deadline,
    Priority priority = Priority.medium,
    TaskStatus status = TaskStatus.notStarted,
    String? categoryId,
    String? parentTaskId,
  }) {
    final now = DateTime(2026, 10, 8, 10, 0);
    return TaskItem(
      id: id ?? repo.newId(),
      title: title,
      priority: priority,
      status: status,
      recurrenceType: RecurrenceType.none,
      isRecurring: false,
      deadline: deadline,
      categoryId: categoryId,
      parentTaskId: parentTaskId,
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('scenario 10 — persistence', () {
    test('created tasks survive a new repository instance', () async {
      await repo.insert(buildTask(title: 'Persisted task'));

      // A second repository over the same database sees the data.
      final secondRepo = TaskRepository(db);
      final tasks = await secondRepo.getTasks();
      expect(tasks, hasLength(1));
      expect(tasks.first.title, 'Persisted task');
    });

    test('insert then read back preserves every field', () async {
      final deadline = DateTime(2026, 10, 10, 17, 30);
      final task = TaskItem(
        id: repo.newId(),
        title: 'Full task',
        description: 'A description',
        notes: 'Some notes',
        priority: Priority.urgent,
        status: TaskStatus.inProgress,
        recurrenceType: RecurrenceType.weekly,
        isRecurring: true,
        deadline: deadline,
        sortOrder: 3,
        createdAt: DateTime(2026, 10, 1, 9, 0),
        updatedAt: DateTime(2026, 10, 2, 9, 0),
      );
      await repo.insert(task);

      final loaded = await repo.getById(task.id);
      expect(loaded, isNotNull);
      expect(loaded!.description, 'A description');
      expect(loaded.notes, 'Some notes');
      expect(loaded.priority, Priority.urgent);
      expect(loaded.status, TaskStatus.inProgress);
      expect(loaded.recurrenceType, RecurrenceType.weekly);
      expect(loaded.isRecurring, isTrue);
      expect(loaded.deadline, deadline);
      expect(loaded.sortOrder, 3);
    });
  });

  group('subtasks', () {
    test('subtasks are excluded from top-level queries', () async {
      final parent = buildTask(title: 'Parent');
      await repo.insert(parent);
      await repo.insert(buildTask(title: 'Child', parentTaskId: parent.id));

      final topLevel = await repo.getTasks();
      expect(topLevel, hasLength(1));
      expect(topLevel.first.title, 'Parent');

      final children = await repo.getSubtasks(parent.id);
      expect(children, hasLength(1));
      expect(children.first.title, 'Child');
    });

    test('deleting a parent cascades to its subtasks', () async {
      final parent = buildTask(title: 'Parent');
      await repo.insert(parent);
      await repo.insert(buildTask(title: 'Child', parentTaskId: parent.id));

      await repo.delete(parent.id);
      final children = await repo.getSubtasks(parent.id);
      expect(children, isEmpty);
    });

    test('progressFor counts completed vs total', () async {
      final parent = buildTask(title: 'Parent');
      await repo.insert(parent);
      await repo.insert(
        buildTask(
          title: 'c1',
          parentTaskId: parent.id,
          status: TaskStatus.completed,
        ),
      );
      await repo.insert(
        buildTask(
          title: 'c2',
          parentTaskId: parent.id,
          status: TaskStatus.completed,
        ),
      );
      await repo.insert(buildTask(title: 'c3', parentTaskId: parent.id));

      final progress = await repo.progressFor([parent.id]);
      final p = progress[parent.id]!;
      expect(p.completed, 2);
      expect(p.total, 3);
      expect(p.label, '2 / 3 completed');
      expect(p.percent, 67);
    });
  });

  group('filtering and sorting', () {
    setUp(() async {
      await seedCategory('college');
      await seedCategory('work');
      await repo.insert(
        buildTask(
          title: 'Overdue college',
          deadline: DateTime(2026, 10, 1),
          priority: Priority.high,
          categoryId: 'college',
        ),
      );
      await repo.insert(
        buildTask(
          title: 'Upcoming work',
          deadline: DateTime(2026, 12, 1),
          priority: Priority.low,
          categoryId: 'work',
        ),
      );
      await repo.insert(
        buildTask(
          title: 'Completed thing',
          deadline: DateTime(2026, 10, 2),
          status: TaskStatus.completed,
        ),
      );
    });

    test('completed tasks are hidden by default', () async {
      final tasks = await repo.getTasks();
      expect(tasks.map((t) => t.title), isNot(contains('Completed thing')));
    });

    test('includeCompleted shows them', () async {
      final tasks = await repo.getTasks(
        filter: const TaskFilter(includeCompleted: true),
      );
      expect(tasks.map((t) => t.title), contains('Completed thing'));
    });

    test('category filter', () async {
      final tasks = await repo.getTasks(
        filter: const TaskFilter(categoryId: 'college'),
      );
      expect(tasks, hasLength(1));
      expect(tasks.first.title, 'Overdue college');
    });

    test('priority filter', () async {
      final tasks = await repo.getTasks(
        filter: const TaskFilter(priorities: {Priority.high}),
      );
      expect(tasks, hasLength(1));
      expect(tasks.first.priority, Priority.high);
    });

    test('search matches title case-insensitively', () async {
      final tasks = await repo.getTasks(
        filter: const TaskFilter(search: 'WORK'),
      );
      expect(tasks, hasLength(1));
      expect(tasks.first.title, 'Upcoming work');
    });

    test('deadline sort places the earliest first', () async {
      final tasks = await repo.getTasks(sort: TaskSort.deadline);
      expect(tasks.first.title, 'Overdue college');
    });

    test('priority sort places urgent first', () async {
      final tasks = await repo.getTasks(sort: TaskSort.priority);
      expect(tasks.first.priority, Priority.high);
      expect(tasks.last.priority, Priority.low);
    });
  });

  group('markOverdue', () {
    test('flips past-deadline open tasks and leaves others alone', () async {
      final now = DateTime(2026, 10, 8, 10, 0);
      await repo.insert(
        buildTask(title: 'Late', deadline: DateTime(2026, 10, 1)),
      );
      await repo.insert(
        buildTask(title: 'Future', deadline: DateTime(2026, 10, 20)),
      );
      await repo.insert(
        buildTask(
          title: 'Done',
          deadline: DateTime(2026, 10, 1),
          status: TaskStatus.completed,
        ),
      );

      await repo.markOverdue(now);

      final all = await repo.getTasks(
        filter: const TaskFilter(includeCompleted: true),
      );
      final byTitle = {for (final t in all) t.title: t};
      expect(byTitle['Late']!.status, TaskStatus.overdue);
      expect(byTitle['Future']!.status, TaskStatus.notStarted);
      expect(byTitle['Done']!.status, TaskStatus.completed);
    });
  });

  group('updates', () {
    test('update rewrites editable fields', () async {
      final task = buildTask(title: 'Before', priority: Priority.low);
      await repo.insert(task);

      final updated = task.copyWith(
        title: 'After',
        priority: Priority.urgent,
        notes: 'Added notes',
      );
      await repo.update(updated);

      final loaded = await repo.getById(task.id);
      expect(loaded!.title, 'After');
      expect(loaded.priority, Priority.urgent);
      expect(loaded.notes, 'Added notes');
    });
  });
}
