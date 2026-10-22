import 'package:duemate/core/notifications/reminder_planner.dart';
import 'package:duemate/models/enums.dart';
import 'package:duemate/models/reminder.dart';
import 'package:duemate/models/task_item.dart';
import 'package:duemate/models/user_settings.dart';
import 'package:flutter_test/flutter_test.dart';

TaskItem buildTask(DateTime deadline) => TaskItem(
  id: 'task-1',
  title: 'Submit project',
  priority: Priority.high,
  status: TaskStatus.notStarted,
  recurrenceType: RecurrenceType.none,
  isRecurring: false,
  sortOrder: 0,
  deadline: deadline,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  // Fixed now to keep planning deterministic.
  final now = DateTime(2026, 10, 8, 10, 0);
  final deadline = DateTime(2026, 10, 10, 17, 0);

  int sequence = 0;
  int allocate() => ++sequence;

  setUp(() => sequence = 0);

  group('scenario 8 — multiple reminders', () {
    test('all requested offsets are scheduled, plus the overdue nudge', () {
      final task = buildTask(deadline);
      final reminderService = ReminderPlanner.plan(
        task: task,
        specs: const [
          ReminderSpec.before(1440), // 1 day
          ReminderSpec.before(180), // 3 hours
          ReminderSpec.before(30), // 30 minutes
          ReminderSpec.atDeadline(),
        ],
        settings: const UserSettings(),
        allocateId: allocate,
        now: now,
      );

      expect(reminderService, hasLength(5));
      final kinds = reminderService.map((r) => r.kind).toList(growable: false);
      expect(
        kinds.where((k) => k == ReminderKind.beforeDeadline),
        hasLength(3),
      );
      expect(kinds.where((k) => k == ReminderKind.atDeadline), hasLength(1));
      expect(kinds.where((k) => k == ReminderKind.overdue), hasLength(1));

      // Times are the expected offsets from the deadline.
      final byMinutes = {
        for (final r in reminderService.where(
          (r) => r.kind == ReminderKind.beforeDeadline,
        ))
          r.minutesBefore: r.scheduledAt,
      };
      expect(byMinutes[1440], deadline.subtract(const Duration(days: 1)));
      expect(byMinutes[180], deadline.subtract(const Duration(hours: 3)));
      expect(byMinutes[30], deadline.subtract(const Duration(minutes: 30)));
    });

    test('notification ids are unique', () {
      final tasks = ReminderPlanner.plan(
        task: buildTask(deadline),
        specs: const [
          ReminderSpec.before(60),
          ReminderSpec.before(30),
          ReminderSpec.atDeadline(),
        ],
        settings: const UserSettings(),
        allocateId: allocate,
        now: now,
      );
      final ids = tasks.map((r) => r.notificationId).toSet();
      expect(ids, hasLength(tasks.length));
    });
  });

  test('duplicate fire times are de-duplicated', () {
    final tasks = ReminderPlanner.plan(
      task: buildTask(deadline),
      // 60 and 60 both resolve to the same instant.
      specs: const [
        ReminderSpec.before(60),
        ReminderSpec.before(60),
        ReminderSpec.atDeadline(),
      ],
      settings: const UserSettings(),
      allocateId: allocate,
      now: now,
    );

    // Two "before" collapse to one; plus the deadline and overdue nudges.
    final beforeCount = tasks
        .where((r) => r.kind == ReminderKind.beforeDeadline)
        .length;
    expect(beforeCount, 1);
  });

  test('overdue nudge is omitted when disabled in settings', () {
    final tasks = ReminderPlanner.plan(
      task: buildTask(deadline),
      specs: const [ReminderSpec.atDeadline()],
      settings: const UserSettings(overdueRemindersEnabled: false),
      allocateId: allocate,
      now: now,
    );
    expect(tasks.any((r) => r.kind == ReminderKind.overdue), isFalse);
  });

  test(
    'a deadline in the past produces only past reminders (none enabled)',
    () {
      final past = now.subtract(const Duration(hours: 5));
      final tasks = ReminderPlanner.plan(
        task: buildTask(past),
        specs: const [ReminderSpec.before(60), ReminderSpec.atDeadline()],
        settings: const UserSettings(),
        allocateId: allocate,
        now: now,
      );
      // `enabled` is computed against the injected clock in the planner.
      expect(tasks.every((r) => !r.enabled), isTrue);
    },
  );

  group('busy hours', () {
    const busy = UserSettings(
      busyHoursEnabled: true,
      busyStartHour: 9,
      busyEndHour: 17,
    );

    test('an optional reminder inside busy hours is nudged to the end', () {
      // Deadline at 20:00; a 3-hour-before reminder lands at 17:00 — not busy.
      // A 6-hour-before reminder lands at 14:00 — inside busy hours.
      final task = buildTask(DateTime(2026, 10, 8, 20, 0));
      final tasks = ReminderPlanner.plan(
        task: task,
        specs: const [
          ReminderSpec.before(360), // 14:00 — busy
          ReminderSpec.before(60), // 19:00 — not busy, and critical
          ReminderSpec.atDeadline(), // 20:00 — critical
        ],
        settings: busy,
        allocateId: allocate,
        now: now,
      );

      final sixHours = tasks.firstWhere(
        (r) => r.kind == ReminderKind.beforeDeadline && r.minutesBefore == 360,
      );
      // Moved to 17:00, the end of the busy window.
      expect(sixHours.scheduledAt.hour, 17);
      expect(sixHours.scheduledAt.minute, 0);
    });

    test('the critical (closest) reminder is never moved', () {
      final task = buildTask(DateTime(2026, 10, 8, 12, 0));
      final tasks = ReminderPlanner.plan(
        task: task,
        specs: const [
          ReminderSpec.before(
            60,
          ), // 11:00 — inside busy, but closest => critical
          ReminderSpec.atDeadline(), // 12:00 — critical
        ],
        settings: busy,
        allocateId: allocate,
        now: now,
      );
      final closest = tasks.firstWhere(
        (r) => r.kind == ReminderKind.beforeDeadline && r.minutesBefore == 60,
      );
      expect(closest.scheduledAt, DateTime(2026, 10, 8, 11, 0));
    });
  });

  test('custom reminder uses its explicit time', () {
    final custom = DateTime(2026, 10, 9, 8, 30);
    final tasks = ReminderPlanner.plan(
      task: buildTask(deadline),
      specs: [ReminderSpec(kind: ReminderKind.custom, customAt: custom)],
      settings: const UserSettings(),
      allocateId: allocate,
      now: now,
    );
    final match = tasks.firstWhere((r) => r.kind == ReminderKind.custom);
    expect(match.scheduledAt, custom);
  });

  test('a task without a deadline produces no reminders', () {
    final task = buildTask(deadline).copyWith(deadline: null);
    final tasks = ReminderPlanner.plan(
      task: task,
      specs: const [ReminderSpec.atDeadline()],
      settings: const UserSettings(),
      allocateId: allocate,
      now: now,
    );
    expect(tasks, isEmpty);
  });
}
