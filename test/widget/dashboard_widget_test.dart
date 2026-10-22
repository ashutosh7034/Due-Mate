import 'package:duemate/core/theme/app_theme.dart';
import 'package:duemate/features/dashboard/dashboard_screen.dart';
import 'package:duemate/features/shell/app_shell.dart';
import 'package:duemate/models/enums.dart';
import 'package:duemate/providers/core_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/widget_harness.dart';

void main() {
  late WidgetHarness harness;

  setUp(() async {
    harness = await WidgetHarness.create();
  });

  tearDown(() async {
    await harness.dispose();
  });

  Widget themed(Widget child) => ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(harness.database),
      notificationServiceProvider.overrideWithValue(harness.notifications),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    ),
  );

  testWidgets('shows the greeting and an empty state with no tasks', (
    tester,
  ) async {
    await tester.pumpWidget(themed(const DashboardScreen()));
    await settle(tester);

    expect(find.textContaining('Good '), findsOneWidget);
    expect(find.text('Your schedule is clear'), findsOneWidget);
    expect(find.text('Add task'), findsOneWidget);

    await teardownWidget(tester);
  });

  testWidgets('renders overdue, due today and upcoming sections', (
    tester,
  ) async {
    final now = DateTime.now();
    await harness.tasks.insert(
      sampleTask(
        id: 'overdue',
        title: 'Submit Project Report',
        deadline: now.subtract(const Duration(hours: 2)),
        priority: Priority.urgent,
      ),
    );
    await harness.tasks.insert(
      sampleTask(
        id: 'today',
        title: 'Prepare presentation',
        deadline: DateTime(now.year, now.month, now.day, 23, 30),
        priority: Priority.high,
      ),
    );
    await harness.tasks.insert(
      sampleTask(
        id: 'upcoming',
        title: 'Assignment Submission',
        deadline: now.add(const Duration(days: 3)),
      ),
    );

    await tester.pumpWidget(themed(const DashboardScreen()));
    await settle(tester);

    expect(find.text('OVERDUE'), findsOneWidget);
    expect(find.text('DUE TODAY'), findsOneWidget);
    expect(find.text('UPCOMING'), findsOneWidget);

    expect(find.text('Submit Project Report'), findsOneWidget);
    expect(find.text('Prepare presentation'), findsOneWidget);
    expect(find.text('Assignment Submission'), findsOneWidget);

    // Overdue label is present.
    expect(find.textContaining('Overdue by'), findsWidgets);

    await teardownWidget(tester);
  });

  testWidgets('tapping the completion control completes a task', (
    tester,
  ) async {
    await harness.tasks.insert(
      sampleTask(
        id: 't1',
        title: 'Finish essay',
        deadline: DateTime.now().add(const Duration(hours: 5)),
      ),
    );

    await tester.pumpWidget(themed(const DashboardScreen()));
    await settle(tester);

    expect(find.text('Finish essay'), findsOneWidget);

    // The completion control has a semantics label.
    final control = find.bySemanticsLabel('Mark as completed');
    expect(control, findsWidgets);
    await tester.tap(control.first);
    await settle(tester);

    final stored = await harness.tasks.getById('t1');
    expect(stored!.status, TaskStatus.completed);

    await teardownWidget(tester);
  });

  testWidgets('full shell builds without error and shows five destinations', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(harness.database),
          notificationServiceProvider.overrideWithValue(harness.notifications),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const AppShell()),
      ),
    );
    await settle(tester);

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Alerts'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    await teardownWidget(tester);
  });
}
