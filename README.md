# Deadline

**Remember what matters. Finish on time.**

Deadline is an offline-first reminder and deadline-management app for students
and professionals who juggle college, work, projects, personal and
administrative tasks. Its primary job is **deadline awareness** and **reliable
reminders** — not just keeping a list.

Built with Flutter, targeting Android first (iOS and web also configured).

---

## Features

- **Dashboard** — overdue / due today / upcoming, at a glance, ordered by what
  needs attention first.
- **Quick add** — type "Submit assignment tomorrow at 7 PM" and the app parses
  the title, date and priority. No AI service required.
- **Full task editor** — description, category, priority, deadline, multiple
  reminders, repeat rules and subtasks.
- **Reliable local notifications** — several reminders per task, a deadline
  alert and a single overdue nudge. Scheduled with the device alarm service so
  they fire when the app is closed, and restored after a reboot.
- **Reminder hygiene** — editing a deadline cancels the old alarms and
  schedules new ones; completing or deleting a task cancels its reminders.
- **Recurring tasks** — daily, weekly, monthly and custom weekdays.
- **Calendar** — month view with per-day tasks and severity markers.
- **Notification centre** — upcoming, due soon, overdue, completed and system
  alerts, each linked back to its task.
- **Busy hours** — optional reminders are nudged out of your busy window;
  critical reminders and deadline alerts are never suppressed.
- **Focus mode** — a simple 25-minute timer for one task.
- **Categories**, search, filters and sorting.
- **Light and dark themes** from a single centralised theme system.

## Architecture

```
lib/
  core/            theme, constants, utils, database, notifications, services
  models/          immutable domain models + enums
  repositories/    Drift-backed data access + mappers
  providers/       Riverpod state layer (streams, controllers)
  features/        onboarding, dashboard, tasks, calendar, notifications,
                   profile, focus, shell
  widgets/         shared, reusable UI
  routes/          route-name constants
  app.dart         root widget, theme + gates
  main.dart        entry point
```

- **State management:** Riverpod (the only state framework used).
- **Database:** Drift (SQLite) with typed tables, foreign keys, indexes and a
  migration strategy. One database, no Firebase required.
- **Notifications:** `flutter_local_notifications` + `timezone`.

### Key design rules

- Deadline logic (`core/utils/deadline_calculator.dart`) and reminder planning
  (`core/notifications/reminder_planner.dart`) are **pure functions** with no
  Flutter or database imports, so the hard rules are unit-tested.
- The UI never talks to the database directly — it goes through repositories
  and controllers.
- Dashboard ordering happens at presentation level; task rows in the database
  are never reordered for display.

## Reliability of reminders

- On Android, exact alarms are used when the OS permits; otherwise the app
  degrades to an inexact, power-safe schedule rather than pretending.
- Notification receivers are declared in `AndroidManifest.xml` so alarms
  survive a reboot or app update.
- When a task's deadline changes, its old notifications are cancelled **before**
  new ones are scheduled.
- Completing, cancelling or deleting a task cancels all of its future
  notifications.
- The in-app notification centre is protected against duplicate entries (one
  per task, per category, per day).

## Running the app

Prerequisites: Flutter (stable), the Android SDK, and a device or emulator.

```bash
flutter pub get

# Generate the Drift database code after changing any table.
dart run build_runner build

flutter analyze
flutter test

# Run on a connected Android device or emulator:
flutter run

# Or build an installable APK:
flutter build apk --debug
# output: build/app/outputs/flutter-apk/app-debug.apk

flutter build apk --release
```

To run the reminder test on a device:

1. Create a task with a reminder ~1–2 minutes in the future.
2. Lock the phone / close the app.
3. Confirm the notification appears.

This exact flow was verified on an Android emulator (Pixel 8a, API 36): the
`RTC_WAKEUP` alarm is registered with the OS, fires while the device is locked,
and the notification is delivered with the app closed.

## Development utilities

In **debug builds only**, `Profile → About` offers "Add sample tasks" and
"Reset all data". These are never shown in release builds, and the app never
ships with fake tasks.

## Tech notes

- Schema changes must be handled through Drift migrations (`schemaVersion` +
  `onUpgrade` in `lib/core/database/database.dart`). Never delete the database
  to change the schema.
- Product name, colours and typography are centralised
  (`lib/core/theme`, `lib/core/constants/app_constants.dart`) so the app can be
  re-branded easily.
