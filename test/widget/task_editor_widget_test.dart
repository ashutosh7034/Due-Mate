import 'package:duemate/core/theme/app_theme.dart';
import 'package:duemate/features/tasks/task_editor_sheet.dart';
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

  Widget host({String? initialTitle}) => ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(harness.database),
      notificationServiceProvider.overrideWithValue(harness.notifications),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: TaskEditorSheet(initialTitle: initialTitle)),
    ),
  );

  /// Scrolls the editor's list so the save button is realised and visible.
  Future<void> scrollToSave(WidgetTester tester, String label) async {
    await tester.scrollUntilVisible(
      find.text(label),
      400,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 20,
    );
    await tester.pump();
  }

  testWidgets('requires a title before saving', (tester) async {
    await tester.pumpWidget(host());
    await settle(tester);

    await scrollToSave(tester, 'Add task');
    await tester.tap(find.text('Add task'));
    await settle(tester);

    // The essential guarantee: nothing was persisted without a title.
    expect(await harness.tasks.getTasks(), isEmpty);

    await teardownWidget(tester);
  });

  testWidgets('creates a task with priority and a deadline', (tester) async {
    await tester.pumpWidget(host());
    await settle(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Task title'),
      'Write project report',
    );
    await settle(tester);

    // Choose High priority.
    await tester.tap(find.text('High'));
    await settle(tester);

    await scrollToSave(tester, 'Add task');
    await tester.tap(find.text('Add task'));
    await settle(tester);

    final tasks = await harness.tasks.getTasks();
    expect(tasks, hasLength(1));
    expect(tasks.first.title, 'Write project report');
    expect(tasks.first.priority, Priority.high);

    await teardownWidget(tester);
  });

  testWidgets('prefills the title when given an initial value', (tester) async {
    await tester.pumpWidget(host(initialTitle: 'Prefilled task'));
    await settle(tester);

    expect(find.text('Prefilled task'), findsOneWidget);

    await teardownWidget(tester);
  });
}
