import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/category.dart';
import '../../models/enums.dart';
import '../../models/reminder.dart';
import '../../models/task_item.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/task_repository.dart';
import '../theme/app_colors.dart';

/// The categories every user starts with.
class DefaultCategories {
  const DefaultCategories._();

  static List<Category> build({Uuid? uuid}) {
    final id = uuid ?? const Uuid();
    final now = DateTime.now();
    Category make(String name, String icon, Color color, int order) => Category(
      id: id.v4(),
      name: name,
      iconKey: icon,
      color: color,
      isDefault: true,
      sortOrder: order,
      createdAt: now,
    );

    return [
      make('College', 'school', const Color(0xFF2B4A80), 0),
      make('Work', 'work', const Color(0xFF2E9E6B), 1),
      make('Projects', 'code', const Color(0xFF7A5BA6), 2),
      make('Personal', 'person', const Color(0xFFC9821F), 3),
      make('Meetings', 'groups', const Color(0xFF3D7EA6), 4),
      make('Finance', 'payments', const Color(0xFF4E8A6B), 5),
      make('Other', 'folder', AppColors.priorityLow, 6),
    ];
  }
}

/// Development-only sample data.
///
/// Never invoked automatically in production. Reachable from Settings → About
/// in debug builds so the app can be exercised without manual data entry.
class SeedData {
  const SeedData._();

  static Future<void> insert({
    required TaskRepository taskRepo,
    required CategoryRepository categoryRepo,
    String userId = 'default_user',
  }) async {
    final uuid = const Uuid();
    final now = DateTime.now();
    final categories = await categoryRepo.getAll();
    final byName = {for (final c in categories) c.name: c.id};

    String? cat(String name) => byName[name];

    TaskItem task({
      required String title,
      String? description,
      String? categoryId,
      required Priority priority,
      required DateTime deadline,
      TaskStatus status = TaskStatus.notStarted,
    }) {
      return TaskItem(
        id: uuid.v4(),
        title: title,
        description: description,
        categoryId: categoryId,
        priority: priority,
        status: status,
        deadline: deadline,
        isRecurring: false,
        recurrenceType: RecurrenceType.none,
        userId: userId,
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      );
    }

    final overdue = task(
      title: 'Submit MCA Project Report',
      description: 'Final PDF with plagiarism report.',
      categoryId: cat('College'),
      priority: Priority.urgent,
      deadline: now.subtract(const Duration(hours: 2, minutes: 15)),
    );
    final today = task(
      title: 'Prepare presentation',
      description: 'Slides for the seminar.',
      categoryId: cat('College'),
      priority: Priority.high,
      deadline: DateTime(now.year, now.month, now.day, 19, 0),
    );
    final tomorrow = task(
      title: 'Assignment Submission',
      description: 'Web engineering assignment 4.',
      categoryId: cat('College'),
      priority: Priority.medium,
      deadline: DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
      ).add(const Duration(days: 1)),
    );
    final completed = task(
      title: 'Pay electricity bill',
      categoryId: cat('Finance'),
      priority: Priority.medium,
      deadline: now.subtract(const Duration(days: 1)),
      status: TaskStatus.completed,
    ).copyWith(completedAt: now.subtract(const Duration(hours: 3)));

    final recurring = TaskItem(
      id: uuid.v4(),
      title: 'Weekly project review',
      description: 'Check progress with the team.',
      categoryId: cat('Work'),
      priority: Priority.medium,
      status: TaskStatus.notStarted,
      deadline: _nextMonday(now, 9),
      isRecurring: true,
      recurrenceType: RecurrenceType.weekly,
      userId: userId,
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
    );

    for (final item in [overdue, today, tomorrow, completed, recurring]) {
      await taskRepo.insert(item);
    }

    // A subtask breakdown for the presentation task.
    final subtasks = ['Research topic', 'Prepare slides', 'Add references'];
    for (var i = 0; i < subtasks.length; i++) {
      await taskRepo.insert(
        TaskItem(
          id: uuid.v4(),
          title: subtasks[i],
          priority: Priority.medium,
          status: i == 0 ? TaskStatus.completed : TaskStatus.notStarted,
          recurrenceType: RecurrenceType.none,
          isRecurring: false,
          parentTaskId: today.id,
          userId: userId,
          sortOrder: i,
          completedAt: i == 0 ? now : null,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }

  static DateTime _nextMonday(DateTime from, int hour) {
    var delta = (DateTime.monday - from.weekday) % 7;
    if (delta <= 0) delta += 7;
    final day = DateTime(
      from.year,
      from.month,
      from.day,
    ).add(Duration(days: delta));
    return DateTime(day.year, day.month, day.day, hour);
  }
}

/// Reminder specs implied by sample data (kept separate from the repository).
class SeedReminders {
  const SeedReminders._();

  static List<ReminderSpec> standard() => const [
    ReminderSpec.before(1440),
    ReminderSpec.before(180),
    ReminderSpec.before(30),
    ReminderSpec.atDeadline(),
  ];
}
