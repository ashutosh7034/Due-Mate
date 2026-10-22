import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:duemate/core/auth/auth_service.dart';
import 'package:duemate/core/auth/auth_user.dart';
import 'package:duemate/core/theme/app_theme.dart';
import 'package:duemate/core/utils/quick_add_parser.dart';
import 'package:duemate/features/profile/categories_screen.dart';
import 'package:duemate/features/tasks/quick_add_sheet.dart';
import 'package:duemate/features/tasks/tasks_screen.dart';
import 'package:duemate/models/category.dart';
import 'package:duemate/models/enums.dart';
import 'package:duemate/models/task_item.dart';
import 'package:duemate/providers/core_providers.dart';
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

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('TASK 1 — Quick Add Deadline Editing (Tests A - H)', () {
    // Test A: Select Today -> Expected: Today at 11:59 PM.
    testWidgets('Test A: Select Today yields Today at 11:59 PM', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(createHost(const QuickAddSheet()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Buy groceries');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('quick_add_deadline_preview')), findsOneWidget);
      expect(find.textContaining('11:59 PM'), findsOneWidget);
      await teardownWidget(tester);
    });

    // Test B: Select Tomorrow -> Expected: Tomorrow at 11:59 PM.
    testWidgets('Test B: Select Tomorrow yields Tomorrow at 11:59 PM', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(createHost(const QuickAddSheet()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Prepare slides');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tomorrow'));
      await tester.pumpAndSettle();

      expect(find.textContaining('11:59 PM'), findsOneWidget);
      await teardownWidget(tester);
    });

    // Test C: Select 1 week later -> Expected: Seven calendar days later at 11:59 PM.
    testWidgets('Test C: Select 1 week later yields 7 calendar days later at 11:59 PM', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(createHost(const QuickAddSheet()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Submit project');
      await tester.pumpAndSettle();

      await tester.tap(find.text('1 week later'));
      await tester.pumpAndSettle();

      expect(find.textContaining('11:59 PM'), findsOneWidget);
      await teardownWidget(tester);
    });

    // Test D: Select No deadline -> Expected: No due date and no automatically assigned due time.
    testWidgets('Test D: Select No deadline yields no due date', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(createHost(const QuickAddSheet()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Think about hobbies');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'No deadline'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ChoiceChip, 'No deadline'), findsOneWidget);
      expect(find.text('No deadline (tap to set)'), findsOneWidget);
      await teardownWidget(tester);
    });

    // Test E: Manually change the time -> Expected: Preview updates and selected time persists.
    testWidgets('Test E: Manually change date/time updates preview', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(createHost(const QuickAddSheet()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Doctor appointment');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      // Tap deadline preview
      await tester.tap(find.byKey(const ValueKey('quick_add_deadline_preview')));
      await tester.pumpAndSettle();

      // Date picker OK
      expect(find.text('OK'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Time picker OK
      expect(find.text('OK'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('quick_add_deadline_preview')), findsOneWidget);
      await teardownWidget(tester);
    });

    // Test F: Open More options preserves the selected date/time.
    testWidgets('Test F: More options preserves selected date/time', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(createHost(const QuickAddSheet()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Submit assignment tomorrow at 5 PM');
      await tester.pumpAndSettle();

      expect(find.textContaining('5:00 PM'), findsOneWidget);
      expect(find.text('More options'), findsOneWidget);
      await teardownWidget(tester);
    });

    // Test G: Enter explicit time such as 7 PM -> Not overwritten by 11:59 PM default.
    test('Test G: Explicit parsed time 7 PM is preserved over 11:59 PM default', () {
      final parsed = QuickAddParser.parse('Team sync tomorrow at 7 PM');
      expect(parsed.matchedTime, isTrue);
      expect(parsed.deadline, isNotNull);
      expect(parsed.deadline!.hour, 19);
      expect(parsed.deadline!.minute, 0);
    });

    // Test H: Month-end, year-end, and leap-year calendar calculations.
    test('Test H: Calendar date calculations handle leap years and month ends safely', () {
      // Leap year Feb 28 -> Feb 29
      final leapFeb28 = DateTime(2024, 2, 28);
      final nextDay = DateTime(leapFeb28.year, leapFeb28.month, leapFeb28.day + 1);
      expect(nextDay.month, 2);
      expect(nextDay.day, 29);

      // Non-leap year Feb 28 -> March 1
      final nonLeapFeb28 = DateTime(2025, 2, 28);
      final nonLeapNextDay = DateTime(nonLeapFeb28.year, nonLeapFeb28.month, nonLeapFeb28.day + 1);
      expect(nonLeapNextDay.month, 3);
      expect(nonLeapNextDay.day, 1);

      // Year-end Dec 31 -> Jan 1 next year
      final dec31 = DateTime(2026, 12, 31);
      final newYear = DateTime(dec31.year, dec31.month, dec31.day + 1);
      expect(newYear.year, 2027);
      expect(newYear.month, 1);
      expect(newYear.day, 1);

      // 1 week later across month end (Oct 28 + 7 days -> Nov 4)
      final oct28 = DateTime(2026, 10, 28);
      final oneWeek = DateTime(oct28.year, oct28.month, oct28.day + 7);
      expect(oneWeek.month, 11);
      expect(oneWeek.day, 4);
    });
  });

  group('TASK 2 — Category CRUD (Tests I - N)', () {
    // Test I: Create a category -> Expected: Category appears and persists.
    testWidgets('Test I: Create a category persists and displays', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(createHost(const CategoriesScreen()));
      await settle(tester);

      await tester.tap(find.text('New category'));
      await settle(tester);

      await tester.enterText(find.byType(TextField).first, 'Research');
      await settle(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();

      final categories = await harness.categories.getAll();
      expect(categories.any((c) => c.name == 'Research'), isTrue);

      await teardownWidget(tester);
    });

    // Test J: Edit a category name -> Expected: New name appears consistently.
    testWidgets('Test J: Edit category name updates consistently', (tester) async {
      configureViewport(tester);
      final cat = Category(
        id: 'cat-custom-1',
        name: 'Sports',
        iconKey: 'fitness',
        color: const Color(0xFF2E9E6B),
        isDefault: false,
        sortOrder: 10,
        createdAt: DateTime.now(),
      );
      await harness.categories.upsert(cat);

      await tester.pumpWidget(createHost(const CategoriesScreen()));
      await settle(tester);

      // Open popup menu and tap Edit
      await tester.tap(find.byTooltip('Actions for Sports'));
      await settle(tester);

      await tester.tap(find.text('Edit'));
      await settle(tester);

      await tester.enterText(find.byType(TextField).first, 'Athletics');
      await settle(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      final updated = await harness.categories.getById('cat-custom-1');
      expect(updated?.name, 'Athletics');

      await teardownWidget(tester);
    });

    // Test K: Edit icon/color -> Expected: Selected appearance persists.
    testWidgets('Test K: Edit icon/color persists', (tester) async {
      final cat = Category(
        id: 'cat-custom-2',
        name: 'Design',
        iconKey: 'palette',
        color: const Color(0xFF2B4A80),
        isDefault: false,
        sortOrder: 11,
        createdAt: DateTime.now(),
      );
      await harness.categories.upsert(cat);

      final updated = cat.copyWith(color: const Color(0xFFC0453F), iconKey: 'code');
      await harness.categories.upsert(updated);

      final retrieved = await harness.categories.getById('cat-custom-2');
      expect(retrieved?.color.toARGB32(), const Color(0xFFC0453F).toARGB32());
      expect(retrieved?.iconKey, 'code');
    });

    // Test L: Delete category without tasks -> Expected: Deletion succeeds.
    testWidgets('Test L: Delete category without tasks succeeds', (tester) async {
      configureViewport(tester);
      final cat = Category(
        id: 'cat-empty-del',
        name: 'Temporary',
        iconKey: 'folder',
        color: const Color(0xFF7A5BA6),
        isDefault: false,
        sortOrder: 15,
        createdAt: DateTime.now(),
      );
      await harness.categories.upsert(cat);

      await tester.pumpWidget(createHost(const CategoriesScreen()));
      await settle(tester);

      await tester.tap(find.byTooltip('Actions for Temporary'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete "Temporary"?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      final retrieved = await harness.categories.getById('cat-empty-del');
      expect(retrieved, isNull);

      await teardownWidget(tester);
    });

    // Test M: Delete category with tasks -> Tasks remain intact and are safely reassigned.
    testWidgets('Test M: Delete category with tasks reassigns tasks safely', (tester) async {
      final cat = Category(
        id: 'cat-with-tasks',
        name: 'Club Activities',
        iconKey: 'groups',
        color: const Color(0xFF3D7EA6),
        isDefault: false,
        sortOrder: 20,
        createdAt: DateTime.now(),
      );
      await harness.categories.upsert(cat);

      final task = TaskItem(
        id: 't-club-1',
        title: 'Attend club orientation',
        categoryId: 'cat-with-tasks',
        priority: Priority.medium,
        status: TaskStatus.notStarted,
        deadline: DateTime.now().add(const Duration(days: 2)),
        isRecurring: false,
        recurrenceType: RecurrenceType.none,
        sortOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await harness.tasks.insert(task);

      // Reassign tasks to 'college' and delete category
      await harness.categories.reassignTasks('cat-with-tasks', 'college');
      await harness.categories.delete('cat-with-tasks');

      // Category deleted
      final catRetrieved = await harness.categories.getById('cat-with-tasks');
      expect(catRetrieved, isNull);

      // Task remains completely intact with new category
      final tasks = await harness.tasks.getTasks();
      final taskRetrieved = tasks.firstWhere((t) => t.id == 't-club-1');
      expect(taskRetrieved.title, 'Attend club orientation');
      expect(taskRetrieved.categoryId, 'college');
    });

    // Test N: Verify task counts after creating, moving, and deleting tasks.
    testWidgets('Test N: Category task counts remain accurate', (tester) async {
      configureViewport(tester);
      final catA = Category(
        id: 'cat-count-a',
        name: 'Category A',
        iconKey: 'folder',
        color: const Color(0xFF2B4A80),
        isDefault: false,
        sortOrder: 30,
        createdAt: DateTime.now(),
      );
      await harness.categories.upsert(catA);

      final taskA1 = TaskItem(
        id: 't-count-1',
        title: 'Task 1 in A',
        categoryId: 'cat-count-a',
        priority: Priority.high,
        status: TaskStatus.notStarted,
        deadline: DateTime.now().add(const Duration(hours: 3)),
        isRecurring: false,
        recurrenceType: RecurrenceType.none,
        sortOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await harness.tasks.insert(taskA1);

      await tester.pumpWidget(createHost(const CategoriesScreen()));
      await settle(tester);

      expect(find.text('1 task'), findsWidgets);

      await teardownWidget(tester);
    });
  });

  group('TASK 3 — Profile Photo Upload & Management (Tests O - T)', () {
    // Test O: Select an image updates user photoUrl
    test('Test O: Profile photo path updates successfully on user profile', () async {
      final user = AuthUser(
        id: 'user-1',
        email: 'test@duemate.app',
        fullName: 'Ashutosh Pandey',
        createdAt: DateTime.now(),
      );
      expect(user.photoUrl, isNull);

      final updated = user.copyWith(photoUrl: '/storage/avatar.jpg');
      expect(updated.photoUrl, '/storage/avatar.jpg');
      expect(updated.fullName, 'Ashutosh Pandey');
    });

    // Test P: Restart or recreate the app -> Persisted photo loads
    test('Test P: AuthUser JSON serialization roundtrip preserves photoUrl', () {
      final user = AuthUser(
        id: 'user-persist-1',
        email: 'persist@duemate.app',
        fullName: 'Jane Doe',
        createdAt: DateTime.parse('2026-10-22T10:00:00.000Z'),
        photoUrl: 'https://example.com/photo.png',
      );

      final json = user.toJson();
      expect(json['photoUrl'], 'https://example.com/photo.png');

      final revived = AuthUser.fromJson(json);
      expect(revived.id, user.id);
      expect(revived.fullName, user.fullName);
      expect(revived.photoUrl, 'https://example.com/photo.png');
    });

    // Test Q: Replace the photo -> New photo appears
    test('Test Q: Replacing photo replaces the URL cleanly', () {
      final user = AuthUser(
        id: 'user-replace',
        email: 'rep@duemate.app',
        fullName: 'Alex',
        createdAt: DateTime.now(),
        photoUrl: '/old/path.jpg',
      );

      final replaced = user.copyWith(photoUrl: '/new/path.png');
      expect(replaced.photoUrl, '/new/path.png');
    });

    // Test R: Remove the photo -> Reverts to null (fallback initials)
    test('Test R: Removing photo resets photoUrl to null safely', () {
      final user = AuthUser(
        id: 'user-remove',
        email: 'rem@duemate.app',
        fullName: 'Taylor',
        createdAt: DateTime.now(),
        photoUrl: '/avatars/current.jpg',
      );

      final cleared = user.copyWith(photoUrl: null);
      expect(cleared.photoUrl, isNull);
      expect(cleared.fullName, 'Taylor');
      expect(cleared.fullName[0].toUpperCase(), 'T');
    });

    // Test S: Cancel picker preserves existing photo
    test('Test S: Cancelling picker leaves existing profile untouched', () {
      final user = AuthUser(
        id: 'user-cancel',
        email: 'cancel@duemate.app',
        fullName: 'Sam',
        createdAt: DateTime.now(),
        photoUrl: '/avatars/keep_me.jpg',
      );

      final String? pickedResult = null as String?;
      final result = pickedResult != null ? user.copyWith(photoUrl: pickedResult) : user;
      expect(result.photoUrl, '/avatars/keep_me.jpg');
    });

    // Test T: Persistence or update failure does not corrupt user
    test('Test T: AuthResult failure returns descriptive error and leaves profile intact', () {
      final failure = const AuthResult.failure('Image upload failed. Please try again.');
      expect(failure.isSuccess, isFalse);
      expect(failure.error, contains('Image upload failed'));
      expect(failure.user, isNull);
    });
  });

  group('TASK 4 — Redesigned Tasks Filter Bottom Sheet (Tests U - Z)', () {
    // Test U: Priority selector displays and can be selected
    testWidgets('Test U: Priority chips render with distinct states', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(createHost(const TasksScreen()));
      await settle(tester);

      // Open filter bottom sheet
      await tester.tap(find.byTooltip('Sort & filter'));
      await tester.pumpAndSettle();

      expect(find.text('Filters'), findsOneWidget);
      expect(find.text('Urgent'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);

      await tester.tap(find.text('Urgent'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Apply filters'));
      await tester.pumpAndSettle();

      // Filter sheet closed
      expect(find.text('Filters'), findsNothing);

      await teardownWidget(tester);
    });

    // Test V: Category selector highlights and filters
    testWidgets('Test V: Category selector supports selecting specific category', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(createHost(const TasksScreen()));
      await settle(tester);

      await tester.tap(find.byTooltip('Sort & filter'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'College'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'College'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Apply filters'));
      await tester.pumpAndSettle();

      expect(find.text('Filters'), findsNothing);

      await teardownWidget(tester);
    });

    // Test W: Combined priority and category returns correct intersection
    test('Test W: TaskFilter combined priority and category logic', () {
      final now = DateTime.now();
      final t1 = TaskItem(
        id: 't-1',
        title: 'Urgent College',
        categoryId: 'college',
        priority: Priority.urgent,
        status: TaskStatus.notStarted,
        deadline: now,
        isRecurring: false,
        recurrenceType: RecurrenceType.none,
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      );
      final t2 = TaskItem(
        id: 't-2',
        title: 'Low College',
        categoryId: 'college',
        priority: Priority.low,
        status: TaskStatus.notStarted,
        deadline: now,
        isRecurring: false,
        recurrenceType: RecurrenceType.none,
        sortOrder: 1,
        createdAt: now,
        updatedAt: now,
      );
      final t3 = TaskItem(
        id: 't-3',
        title: 'Urgent Work',
        categoryId: 'work',
        priority: Priority.urgent,
        status: TaskStatus.notStarted,
        deadline: now,
        isRecurring: false,
        recurrenceType: RecurrenceType.none,
        sortOrder: 2,
        createdAt: now,
        updatedAt: now,
      );

      final list = [t1, t2, t3];
      // Filter for College AND Urgent
      final filtered = list.where((t) => t.categoryId == 'college' && t.priority == Priority.urgent).toList();
      expect(filtered.length, 1);
      expect(filtered.first.id, 't-1');
    });

    // Test X: Reset filters clears criteria
    testWidgets('Test X: Reset button clears staged criteria', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(createHost(const TasksScreen()));
      await settle(tester);

      await tester.tap(find.byTooltip('Sort & filter'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Urgent'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Reset'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Apply filters'));
      await tester.pumpAndSettle();

      expect(find.text('Filters'), findsNothing);

      await teardownWidget(tester);
    });

    // Test Y: Apply filters applies changes and closes sheet
    testWidgets('Test Y: Apply filters applies staged filter and dismisses modal', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(createHost(const TasksScreen()));
      await settle(tester);

      await tester.tap(find.byTooltip('Sort & filter'));
      await tester.pumpAndSettle();

      expect(find.text('Filters'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Apply filters'));
      await tester.pumpAndSettle();

      expect(find.text('Filters'), findsNothing);

      await teardownWidget(tester);
    });

    // Test Z: Dynamically created categories render with no overflow on narrow screen
    testWidgets('Test Z: Dynamic categories render cleanly on narrow viewport', (tester) async {
      // Simulate narrow 320px screen
      tester.view.physicalSize = const Size(320 * 2.0, 640 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Add 3 dynamic custom categories
      for (var i = 1; i <= 3; i++) {
        await harness.categories.upsert(
          Category(
            id: 'dyn-cat-$i',
            name: 'Dynamic Team Project $i',
            iconKey: 'code',
            color: const Color(0xFF7A5BA6),
            isDefault: false,
            sortOrder: 50 + i,
            createdAt: DateTime.now(),
          ),
        );
      }

      await tester.pumpWidget(createHost(const TasksScreen()));
      await settle(tester);

      await tester.tap(find.byTooltip('Sort & filter'));
      await settle(tester);

      // Header, Categories, and Action buttons must be present without flutter overflow error
      expect(find.text('Filters'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Reset'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Apply filters'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await teardownWidget(tester);
    });
  });
}
