import 'package:duemate/core/theme/app_theme.dart';
import 'package:duemate/features/tasks/tasks_screen.dart';
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

  Widget host() => ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(harness.database),
      notificationServiceProvider.overrideWithValue(harness.notifications),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(body: TasksScreen()),
    ),
  );

  testWidgets(
    'shows all tasks (both open and completed) by default in All view',
    (tester) async {
      await harness.tasks.insert(
        sampleTask(
          id: 't1',
          title: 'Open task',
          deadline: DateTime.now().add(const Duration(days: 2)),
        ),
      );
      await harness.tasks.insert(
        sampleTask(
          id: 't2',
          title: 'Completed task',
          status: TaskStatus.completed,
          completedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(host());
      await settle(tester);

      expect(find.text('Open task'), findsOneWidget);
      expect(find.text('Completed task'), findsOneWidget);

      // Switch to the Completed view.
      await tester.tap(find.text('Completed').first);
      await settle(tester);
      expect(find.text('Completed task'), findsOneWidget);
      expect(find.text('Open task'), findsNothing);

      // Switch back to All view.
      await tester.tap(find.text('All').first);
      await settle(tester);
      expect(find.text('Open task'), findsOneWidget);
      expect(find.text('Completed task'), findsOneWidget);

      await teardownWidget(tester);
    },
  );

  testWidgets('search filters the list case-insensitively', (tester) async {
    await harness.tasks.insert(sampleTask(id: 't1', title: 'Math assignment'));
    await harness.tasks.insert(sampleTask(id: 't2', title: 'Physics lab'));

    await tester.pumpWidget(host());
    await settle(tester);

    await tester.tap(find.byTooltip('Search'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'MATH');
    await settle(tester);

    expect(find.text('Math assignment'), findsOneWidget);
    expect(find.text('Physics lab'), findsNothing);

    await teardownWidget(tester);
  });

  testWidgets('shows a helpful empty state for an empty overdue view', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await settle(tester);

    await tester.tap(find.text('Overdue'));
    await settle(tester);

    expect(find.text('Nothing overdue'), findsOneWidget);

    await teardownWidget(tester);
  });
}
