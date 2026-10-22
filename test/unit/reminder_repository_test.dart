import 'package:duemate/core/database/database.dart';
import 'package:duemate/models/enums.dart';
import 'package:duemate/models/reminder.dart';
import 'package:duemate/models/task_item.dart';
import 'package:duemate/repositories/reminder_repository.dart';
import 'package:duemate/repositories/task_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late TaskRepository taskRepo;
  late ReminderRepository reminderRepo;

  setUp(() {
    db = openTestDatabase();
    taskRepo = TaskRepository(db);
    reminderRepo = ReminderRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<TaskItem> seedTask() async {
    final now = DateTime(2026, 10, 8, 10, 0);
    final task = TaskItem(
      id: taskRepo.newId(),
      title: 'Task',
      priority: Priority.medium,
      status: TaskStatus.notStarted,
      recurrenceType: RecurrenceType.none,
      isRecurring: false,
      deadline: now.add(const Duration(days: 1)),
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
    );
    await taskRepo.insert(task);
    return task;
  }

  TaskReminder buildReminder(
    String taskId, {
    required DateTime at,
    int notificationId = 42,
    ReminderKind kind = ReminderKind.beforeDeadline,
    int? minutesBefore = 60,
  }) {
    return TaskReminder(
      id: '${taskId}_$notificationId',
      taskId: taskId,
      kind: kind,
      minutesBefore: minutesBefore,
      scheduledAt: at,
      notificationId: notificationId,
      createdAt: DateTime(2026, 10, 8),
    );
  }

  test('replaceForTask stores the new set and removes the old', () async {
    final task = await seedTask();
    await reminderRepo.replaceForTask(task.id, [
      buildReminder(task.id, at: DateTime(2026, 10, 9, 9), notificationId: 1),
    ]);

    await reminderRepo.replaceForTask(task.id, [
      buildReminder(task.id, at: DateTime(2026, 10, 9, 8), notificationId: 2),
      buildReminder(
        task.id,
        at: DateTime(2026, 10, 9, 10),
        notificationId: 3,
        kind: ReminderKind.atDeadline,
        minutesBefore: null,
      ),
    ]);

    final stored = await reminderRepo.getForTask(task.id);
    expect(stored, hasLength(2));
    expect(stored.map((r) => r.notificationId).toSet(), {2, 3});
  });

  test('getDueUnnotified returns elapsed, unused reminders', () async {
    final task = await seedTask();
    final now = DateTime(2026, 10, 8, 12, 0);
    await reminderRepo.replaceForTask(task.id, [
      buildReminder(
        task.id,
        at: now.subtract(const Duration(minutes: 5)),
        notificationId: 10,
      ),
      buildReminder(
        task.id,
        at: now.add(const Duration(hours: 1)),
        notificationId: 11,
      ),
    ]);

    final due = await reminderRepo.getDueUnnotified(now);
    expect(due, hasLength(1));
    expect(due.first.notificationId, 10);

    await reminderRepo.markNotified(due.first.id, now);
    final after = await reminderRepo.getDueUnnotified(now);
    expect(after, isEmpty);
  });

  test('deleting a task cascades to its reminders', () async {
    final task = await seedTask();
    await reminderRepo.replaceForTask(task.id, [
      buildReminder(task.id, at: DateTime(2026, 10, 9, 9)),
    ]);

    await taskRepo.delete(task.id);
    final stored = await reminderRepo.getForTask(task.id);
    expect(stored, isEmpty);
  });

  test('allNotificationIds returns every id', () async {
    final task = await seedTask();
    await reminderRepo.replaceForTask(task.id, [
      buildReminder(task.id, at: DateTime(2026, 10, 9, 9), notificationId: 7),
      buildReminder(task.id, at: DateTime(2026, 10, 9, 10), notificationId: 8),
    ]);
    final ids = await reminderRepo.allNotificationIds();
    expect(ids, containsAll([7, 8]));
  });
}
