import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:duemate/core/database/database.dart';
import 'package:duemate/core/theme/app_theme.dart';
import 'package:duemate/features/dashboard/dashboard_screen.dart';
import 'package:duemate/features/tasks/task_details_screen.dart';
import 'package:duemate/features/tasks/tasks_screen.dart';
import 'package:duemate/models/enums.dart';
import 'package:duemate/providers/core_providers.dart';
import 'package:duemate/providers/task_controller.dart';
import 'package:duemate/repositories/task_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/widget_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WidgetHarness harness;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    harness = await WidgetHarness.create();
  });

  tearDown(() async {
    await harness.dispose();
  });

  Widget createHost(Widget child) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(harness.database),
        notificationServiceProvider.overrideWithValue(harness.notifications),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: child),
      ),
    );
  }

  Finder tabFinder(String label) {
    return find.text(label).first;
  }

  group('Task Completion Status Regression Suite (Tests 1 - 12)', () {
    // TEST 1: Complete a task. Expected: The task is checked and marked completed.
    testWidgets('TEST 1: Complete a task marks it checked and completed', (
      tester,
    ) async {
      final task = sampleTask(
        id: 't-1',
        title: 'HPC assignment',
        status: TaskStatus.notStarted,
        deadline: DateTime.now().add(const Duration(hours: 4)),
      );
      await harness.tasks.insert(task);

      await tester.pumpWidget(createHost(const TasksScreen()));
      await settle(tester);

      expect(find.text('HPC assignment'), findsOneWidget);
      final initialTask = await harness.tasks.getById('t-1');
      expect(initialTask?.isCompleted, isFalse);

      // Tap the completion checkbox button via semantics.
      await tester.tap(find.bySemanticsLabel('Mark as completed'));
      await settle(tester);

      final completedTask = await harness.tasks.getById('t-1');
      expect(completedTask?.status, equals(TaskStatus.completed));
      expect(completedTask?.isCompleted, isTrue);
      expect(completedTask?.completedAt, isNotNull);

      // Accessibility semantics and UI state reflect completed.
      expect(find.bySemanticsLabel('Mark as not completed'), findsOneWidget);
      await teardownWidget(tester);
    });

    // TEST 2: Select All. Expected: The completed task remains checked and shows its completed styling.
    testWidgets(
      'TEST 2: Select All shows completed task checked with strikethrough and Completed pill',
      (tester) async {
        final task = sampleTask(
          id: 't-2',
          title: 'Web Engineering FA',
          status: TaskStatus.completed,
          completedAt: DateTime.now(),
          deadline: DateTime.now().add(const Duration(days: 1)),
        );
        await harness.tasks.insert(task);

        await tester.pumpWidget(createHost(const TasksScreen()));
        await settle(tester);

        // In All view by default:
        expect(find.text('Web Engineering FA'), findsOneWidget);
        expect(find.bySemanticsLabel('Mark as not completed'), findsOneWidget);

        // Status pill displays "Completed".
        expect(find.text('Completed'), findsWidgets);

        // Title text widget has lineThrough decoration.
        final textWidgets = tester.widgetList<Text>(
          find.text('Web Engineering FA'),
        );
        final titleWidget = textWidgets.first;
        expect(
          titleWidget.style?.decoration,
          equals(TextDecoration.lineThrough),
        );

        await teardownWidget(tester);
      },
    );

    // TEST 3: Select Completed. Expected: The same task appears as completed.
    testWidgets(
      'TEST 3: Select Completed shows the same task with completed state',
      (tester) async {
        final task = sampleTask(
          id: 't-3',
          title: 'Call to ketan todi',
          status: TaskStatus.completed,
          completedAt: DateTime.now(),
        );
        await harness.tasks.insert(task);

        await tester.pumpWidget(createHost(const TasksScreen()));
        await settle(tester);

        // Tap the Completed filter tab.
        await tester.tap(tabFinder('Completed'));
        await settle(tester);

        expect(find.text('Call to ketan todi'), findsOneWidget);
        expect(find.bySemanticsLabel('Mark as not completed'), findsOneWidget);

        final textWidget = tester.widget<Text>(find.text('Call to ketan todi'));
        expect(
          textWidget.style?.decoration,
          equals(TextDecoration.lineThrough),
        );

        await teardownWidget(tester);
      },
    );

    // TEST 4: Switch repeatedly between All and Completed. Expected: Completion status never changes.
    testWidgets(
      'TEST 4: Switch repeatedly between All and Completed preserves completion status',
      (tester) async {
        final task = sampleTask(
          id: 't-4',
          title: 'Preserved task',
          status: TaskStatus.completed,
          completedAt: DateTime.now(),
        );
        await harness.tasks.insert(task);

        await tester.pumpWidget(createHost(const TasksScreen()));
        await settle(tester);

        for (int i = 0; i < 4; i++) {
          // Switch to Completed.
          await tester.tap(tabFinder('Completed'));
          await settle(tester);
          expect(find.text('Preserved task'), findsOneWidget);
          expect(
            find.bySemanticsLabel('Mark as not completed'),
            findsOneWidget,
          );
          var stored = await harness.tasks.getById('t-4');
          expect(stored?.status, equals(TaskStatus.completed));

          // Switch back to All.
          await tester.tap(tabFinder('All'));
          await settle(tester);
          expect(find.text('Preserved task'), findsOneWidget);
          expect(
            find.bySemanticsLabel('Mark as not completed'),
            findsOneWidget,
          );
          stored = await harness.tasks.getById('t-4');
          expect(stored?.status, equals(TaskStatus.completed));
        }

        await teardownWidget(tester);
      },
    );

    // TEST 5: Create an incomplete task. Expected: It appears unchecked in All and does not appear in Completed.
    testWidgets(
      'TEST 5: Create an incomplete task appears unchecked in All and not in Completed',
      (tester) async {
        final task = sampleTask(
          id: 't-5',
          title: 'Incomplete assignment',
          status: TaskStatus.notStarted,
        );
        await harness.tasks.insert(task);

        await tester.pumpWidget(createHost(const TasksScreen()));
        await settle(tester);

        // In All view:
        expect(find.text('Incomplete assignment'), findsOneWidget);
        expect(find.bySemanticsLabel('Mark as completed'), findsOneWidget);

        // In Completed view:
        await tester.tap(tabFinder('Completed'));
        await settle(tester);
        expect(find.text('Incomplete assignment'), findsNothing);

        await teardownWidget(tester);
      },
    );

    // TEST 6: Complete a task and navigate to Dashboard. Expected: The completion state remains correct.
    testWidgets(
      'TEST 6: Complete a task and navigate to Dashboard preserves completion state',
      (tester) async {
        final now = DateTime.now();
        final task = sampleTask(
          id: 't-6',
          title: 'Dashboard verified task',
          status: TaskStatus.notStarted,
          deadline: DateTime(now.year, now.month, now.day, 18, 0),
        );
        await harness.tasks.insert(task);

        // 1. View task in TasksScreen and mark it completed.
        await tester.pumpWidget(createHost(const TasksScreen()));
        await settle(tester);
        expect(find.text('Dashboard verified task'), findsOneWidget);

        await tester.tap(find.bySemanticsLabel('Mark as completed'));
        await settle(tester);

        final stored = await harness.tasks.getById('t-6');
        expect(stored?.status, equals(TaskStatus.completed));
        expect(stored?.isCompleted, isTrue);

        // 2. Navigate to DashboardScreen.
        await tester.pumpWidget(createHost(const DashboardScreen()));
        await settle(tester);

        // Dashboard renders without error and reflects completed state.
        final afterNav = await harness.tasks.getById('t-6');
        expect(afterNav?.status, equals(TaskStatus.completed));
        expect(afterNav?.isCompleted, isTrue);

        await teardownWidget(tester);
      },
    );

    // TEST 7: Open Task Details for a completed task. Expected: Task Details shows the correct completion state.
    testWidgets(
      'TEST 7: Task Details shows correct completion state, lineThrough and Reopen button',
      (tester) async {
        final task = sampleTask(
          id: 't-7',
          title: 'Detailed completed task',
          status: TaskStatus.completed,
          completedAt: DateTime(2026, 10, 15, 14, 30),
        );
        await harness.tasks.insert(task);

        await tester.pumpWidget(
          createHost(const TaskDetailsScreen(taskId: 't-7')),
        );
        await settle(tester);

        expect(find.text('Detailed completed task'), findsOneWidget);
        final title = tester.widget<Text>(find.text('Detailed completed task'));
        expect(title.style?.decoration, equals(TextDecoration.lineThrough));

        // Status pill says Completed.
        expect(find.text('Completed'), findsWidgets);

        // Reopen button is shown.
        expect(find.text('Reopen Task'), findsOneWidget);

        await teardownWidget(tester);
      },
    );

    // TEST 8: Restart the application. Expected: Completion status persists after loading from SQLite.
    test(
      'TEST 8: Completion status persists in SQLite across database restart',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'duemate_test_db',
        );
        final dbFile = File('${tempDir.path}/restart_test.sqlite');

        try {
          // Session 1: Create DB, insert task, complete it.
          final db1 = AppDatabase.withExecutor(NativeDatabase(dbFile));
          final repo1 = TaskRepository(db1);
          final task = sampleTask(
            id: 't-8',
            title: 'Persistent task',
            status: TaskStatus.notStarted,
          );
          await repo1.insert(task);

          final now = DateTime.now();
          await repo1.update(
            task.copyWith(
              status: TaskStatus.completed,
              completedAt: now,
              updatedAt: now,
            ),
          );
          await db1.close();

          // Session 2: "Restart application" by opening fresh DB connection to the same SQLite file.
          final db2 = AppDatabase.withExecutor(NativeDatabase(dbFile));
          final repo2 = TaskRepository(db2);

          final loaded = await repo2.getById('t-8');
          expect(loaded, isNotNull);
          expect(loaded!.status, equals(TaskStatus.completed));
          expect(loaded.isCompleted, isTrue);
          expect(loaded.completedAt, isNotNull);

          // Query with filter including completed:
          final all = await repo2.getTasks(
            filter: const TaskFilter(includeCompleted: true),
          );
          expect(all.any((t) => t.id == 't-8' && t.isCompleted), isTrue);

          await db2.close();
        } finally {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        }
      },
    );

    // TEST 9: Undo completion. Expected: The task returns to its previous incomplete state.
    testWidgets(
      'TEST 9: Undo completion returns task to previous incomplete state',
      (tester) async {
        final task = sampleTask(
          id: 't-9',
          title: 'Undoable task',
          status: TaskStatus.notStarted,
        );
        await harness.tasks.insert(task);

        await tester.pumpWidget(createHost(const TasksScreen()));
        await settle(tester);

        // Complete the task.
        await tester.tap(find.bySemanticsLabel('Mark as completed'));
        await settle(tester);

        var stored = await harness.tasks.getById('t-9');
        expect(stored?.isCompleted, isTrue);

        // Tap Undo in the SnackBar via action callback.
        final undoFinder = find.widgetWithText(SnackBarAction, 'Undo');
        expect(undoFinder, findsOneWidget);
        final undoAction = tester.widget<SnackBarAction>(undoFinder);
        undoAction.onPressed();
        await settle(tester);

        stored = await harness.tasks.getById('t-9');
        expect(stored?.status, equals(TaskStatus.notStarted));
        expect(stored?.isCompleted, isFalse);
        expect(stored?.completedAt, isNull);

        expect(find.bySemanticsLabel('Mark as completed'), findsOneWidget);

        await teardownWidget(tester);
      },
    );

    // TEST 10: Search and sort the task list. Expected: These operations do not alter completion status.
    testWidgets(
      'TEST 10: Search and sort operations do not alter completion status',
      (tester) async {
        final completedTask = sampleTask(
          id: 't-10a',
          title: 'Alpha Assignment',
          status: TaskStatus.completed,
          completedAt: DateTime.now(),
          priority: Priority.low,
          deadline: DateTime.now().add(const Duration(days: 5)),
        );
        final openTask = sampleTask(
          id: 't-10b',
          title: 'Beta Project',
          status: TaskStatus.notStarted,
          priority: Priority.urgent,
          deadline: DateTime.now().add(const Duration(days: 1)),
        );
        await harness.tasks.insert(completedTask);
        await harness.tasks.insert(openTask);

        await tester.pumpWidget(createHost(const TasksScreen()));
        await settle(tester);

        // Verify both appear in All view with their respective states.
        expect(find.text('Alpha Assignment'), findsOneWidget);
        expect(find.text('Beta Project'), findsOneWidget);

        // Search for Alpha.
        await tester.tap(find.byTooltip('Search'));
        await settle(tester);
        await tester.enterText(find.byType(TextField), 'Alpha');
        await settle(tester);

        expect(find.text('Alpha Assignment'), findsOneWidget);
        expect(find.text('Beta Project'), findsNothing);
        expect(find.bySemanticsLabel('Mark as not completed'), findsOneWidget);

        var recordA = await harness.tasks.getById('t-10a');
        expect(recordA?.status, equals(TaskStatus.completed));

        // Clear search.
        await tester.enterText(find.byType(TextField), '');
        await settle(tester);

        // Open sort sheet and sort by priority.
        await tester.tap(find.byTooltip('Sort & filter'));
        await settle(tester);
        await tester.tap(find.text('Priority'));
        await settle(tester);

        // Dismiss sheet by tapping scrim or popping.
        final navigator = tester.state<NavigatorState>(
          find.byType(Navigator).last,
        );
        navigator.pop();
        await settle(tester);

        // Completion status remains completely intact.
        recordA = await harness.tasks.getById('t-10a');
        expect(recordA?.status, equals(TaskStatus.completed));
        final recordB = await harness.tasks.getById('t-10b');
        expect(recordB?.status, equals(TaskStatus.notStarted));

        await teardownWidget(tester);
      },
    );

    // TEST 11: Complete a task, then edit its title or deadline. Expected: The task remains completed unless explicitly reopened.
    test('TEST 11: Editing completed task title or deadline preserves completed status', () async {
      final task = sampleTask(
        id: 't-11',
        title: 'Original Title',
        status: TaskStatus.completed,
        completedAt: DateTime(2026, 10, 10, 10, 0),
        deadline: DateTime(2026, 10, 12, 18, 0),
      );
      await harness.tasks.insert(task);

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(harness.database),
          notificationServiceProvider.overrideWithValue(harness.notifications),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(taskControllerProvider);
      final newDeadline = DateTime(2026, 10, 20, 20, 0);

      final draft = TaskDraft(
        title: 'Updated Title',
        deadline: newDeadline,
        priority: Priority.high,
        status: TaskStatus
            .notStarted, // Draft default should NOT override completed
      );

      final result = await controller.updateTask(task, draft);
      expect(result.isSuccess, isTrue);

      final updated = await harness.tasks.getById('t-11');
      expect(updated, isNotNull);
      expect(updated!.title, equals('Updated Title'));
      expect(updated.deadline, equals(newDeadline));
      expect(updated.status, equals(TaskStatus.completed));
      expect(updated.isCompleted, isTrue);
      expect(updated.completedAt, equals(DateTime(2026, 10, 10, 10, 0)));
    });

    // TEST 12: Verify the status label and checkbox remain synchronized after provider refreshes and filter changes.
    testWidgets(
      'TEST 12: Status label, strikethrough, and checkbox remain synchronized across filter changes',
      (tester) async {
        final completedTask = sampleTask(
          id: 't-12',
          title: 'Synchronized task',
          status: TaskStatus.completed,
          completedAt: DateTime.now(),
        );
        await harness.tasks.insert(completedTask);

        await tester.pumpWidget(createHost(const TasksScreen()));
        await settle(tester);

        void verifySynchronized() {
          // 1. Title has strikethrough.
          final text = tester.widget<Text>(find.text('Synchronized task'));
          expect(text.style?.decoration, equals(TextDecoration.lineThrough));

          // 2. Checkbox is checked (has 'Mark as not completed' semantics).
          expect(
            find.bySemanticsLabel('Mark as not completed'),
            findsOneWidget,
          );

          // 3. Status label contains 'Completed'.
          expect(find.text('Completed'), findsWidgets);
        }

        // In All view:
        verifySynchronized();

        // Switch to Today view (should be empty for completed task):
        await tester.tap(tabFinder('Today'));
        await settle(tester);
        expect(find.text('Synchronized task'), findsNothing);

        // Switch to Completed view:
        await tester.tap(tabFinder('Completed'));
        await settle(tester);
        verifySynchronized();

        // Switch back to All view:
        await tester.tap(tabFinder('All'));
        await settle(tester);
        verifySynchronized();

        await teardownWidget(tester);
      },
    );
  });
}
