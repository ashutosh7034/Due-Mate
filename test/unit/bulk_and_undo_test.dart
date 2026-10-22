import 'package:drift/native.dart';
import 'package:duemate/core/database/database.dart';
import 'package:duemate/models/enums.dart';
import 'package:duemate/providers/core_providers.dart';
import 'package:duemate/providers/task_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_notification_service.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        notificationServiceProvider.overrideWithValue(
          FakeNotificationService(),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test(
    'deleteTask and undoDelete restores the deleted task completely',
    () async {
      final controller = container.read(taskControllerProvider);
      final repo = container.read(taskRepositoryProvider);

      final draft = TaskDraft(
        title: 'Task to be deleted and restored',
        priority: Priority.high,
        deadline: DateTime(2026, 10, 14, 18, 0),
      );

      final createResult = await controller.createTask(draft);
      expect(createResult.isSuccess, isTrue);

      final tasks = await repo.getTasks();
      expect(tasks, hasLength(1));
      final taskId = tasks.first.id;

      // Delete the task
      await controller.deleteTask(taskId);
      final tasksAfterDelete = await repo.getTasks();
      expect(tasksAfterDelete, isEmpty);

      // Undo delete
      final undoResult = await controller.undoDelete();
      expect(undoResult.isSuccess, isTrue);

      final restoredTask = await repo.getById(taskId);
      expect(restoredTask, isNotNull);
      expect(restoredTask!.id, taskId);
      expect(restoredTask.title, 'Task to be deleted and restored');

      final tasksAfterUndo = await repo.getTasks();
      expect(tasksAfterUndo, hasLength(1));
      expect(tasksAfterUndo.first.id, taskId);
    },
  );

  test('bulk complete marks all selected tasks completed', () async {
    final controller = container.read(taskControllerProvider);
    final repo = container.read(taskRepositoryProvider);

    await controller.createTask(TaskDraft(title: 'Task 1'));
    await controller.createTask(TaskDraft(title: 'Task 2'));
    await controller.createTask(TaskDraft(title: 'Task 3'));

    final tasks = await repo.getTasks();
    expect(tasks, hasLength(3));

    // Bulk complete task 1 and task 2
    final completedCount = await controller.completeMultiple([
      tasks[0].id,
      tasks[1].id,
    ]);
    expect(completedCount, 2);

    final t1 = await repo.getById(tasks[0].id);
    final t2 = await repo.getById(tasks[1].id);
    final t3 = await repo.getById(tasks[2].id);

    expect(t1!.isCompleted, isTrue);
    expect(t2!.isCompleted, isTrue);
    expect(t3!.isCompleted, isFalse);
  });

  test('bulk delete deletes all selected tasks', () async {
    final controller = container.read(taskControllerProvider);
    final repo = container.read(taskRepositoryProvider);

    await controller.createTask(TaskDraft(title: 'Task A'));
    await controller.createTask(TaskDraft(title: 'Task B'));
    await controller.createTask(TaskDraft(title: 'Task C'));

    final tasks = await repo.getTasks();
    expect(tasks, hasLength(3));

    final deletedCount = await controller.deleteMultiple([
      tasks[0].id,
      tasks[1].id,
    ]);
    expect(deletedCount, 2);

    final remaining = await repo.getTasks();
    expect(remaining, hasLength(1));
    expect(remaining.first.title, 'Task C');
  });
}
