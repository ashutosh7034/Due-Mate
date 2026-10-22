import 'package:duemate/core/database/database.dart';
import 'package:duemate/models/category.dart';
import 'package:duemate/models/enums.dart';
import 'package:duemate/models/task_item.dart';
import 'package:duemate/providers/core_providers.dart';
import 'package:duemate/repositories/category_repository.dart';
import 'package:duemate/repositories/task_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_notification_service.dart';
import 'test_database.dart';

/// Boots a widget tree backed by an in-memory database and a fake notification
/// service, so widget tests never touch the platform or real storage.
class WidgetHarness {
  WidgetHarness._(this.database, this.notifications);

  final AppDatabase database;
  final FakeNotificationService notifications;

  static Future<WidgetHarness> create() async {
    final db = openTestDatabase();
    final harness = WidgetHarness._(db, FakeNotificationService());
    // Seed default categories so widgets that read them have data.
    await CategoryRepository(db).seedDefaultsIfEmpty(defaultCategories());
    return harness;
  }

  /// Wraps [child] in the providers the app expects.
  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: MaterialApp(theme: ThemeData(useMaterial3: true), home: child),
    );
  }

  Future<void> dispose() async {
    await database.close();
  }

  TaskRepository get tasks => TaskRepository(database);
  CategoryRepository get categories => CategoryRepository(database);
}

List<Category> defaultCategories() {
  final now = DateTime(2026, 1, 1);
  return [
    Category(
      id: 'college',
      name: 'College',
      iconKey: 'school',
      color: const Color(0xFF2B4A80),
      isDefault: true,
      sortOrder: 0,
      createdAt: now,
    ),
    Category(
      id: 'work',
      name: 'Work',
      iconKey: 'work',
      color: const Color(0xFF2E9E6B),
      isDefault: true,
      sortOrder: 1,
      createdAt: now,
    ),
  ];
}

TaskItem sampleTask({
  required String id,
  required String title,
  DateTime? deadline,
  Priority priority = Priority.medium,
  TaskStatus status = TaskStatus.notStarted,
  String? categoryId,
  DateTime? completedAt,
  bool recurring = false,
}) {
  final now = DateTime(2026, 10, 7, 10, 0);
  return TaskItem(
    id: id,
    title: title,
    priority: priority,
    status: status,
    recurrenceType: recurring ? RecurrenceType.weekly : RecurrenceType.none,
    isRecurring: recurring,
    deadline: deadline,
    categoryId: categoryId,
    completedAt: completedAt,
    sortOrder: 0,
    createdAt: now,
    updatedAt: now,
  );
}

/// Pumps until there are no pending frames (bounded), so streams resolve.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

/// Unmounts the widget tree and lets Drift's stream-close microtasks run.
///
/// Drift schedules a zero-duration timer when a query stream is cancelled
/// (which Riverpod triggers when the [ProviderScope] is disposed). Without
/// this, widget tests fail with "A Timer is still pending". Call at the end of
/// every widget test, before the database is closed.
Future<void> teardownWidget(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
}
