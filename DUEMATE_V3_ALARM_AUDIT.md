# DUEMATE V3 — NOTIFICATION & ALARM ARCHITECTURE AUDIT

**Project:** DueMate Flutter Android Application  
**Location:** `C:\Users\Ashutosh Pandey\Downloads\Remainder application`  
**Date:** 22 October 2026  
**Auditor:** Senior Flutter & Android Notification Specialist  
**Status:** Audit Complete — Ready for Implementation  

---

## 1. Executive Summary

DueMate is a Flutter/Android productivity application featuring SQLite persistence via Drift, Riverpod state management, and scheduled Android notifications via `flutter_local_notifications` and `timezone`.

The application currently has **157 passing tests** with **zero Flutter analysis issues**.

The objective of **DueMate V3** is to upgrade the notification engine with:
1. **Persistent Repeating Overdue Reminders:** Repeat-until-completed policy with sensible intervals (5m, 10m, 15m, 30m, 1h, custom) and bounded repetition limits.
2. **Smart Snooze:** Configurable quick presets (5m, 10m, 15m, 30m, 1h), custom date/time, and recheck of completion status upon expiration.
3. **Per-Task Custom Notification Settings:** Custom notification title & message, sound selection (Default, Silent, Gentle Chime, Alert Horn, Bell), vibration selection (Default, Silent, Urgent, Continuous Pulse).
4. **Selectable Alarm Types:**
   - **Type A (Standard Notification):** Quiet or default notification shade alert.
   - **Type B (Sound & Vibration Alarm):** Loud, high-importance notification channel alert with urgent vibration.
   - **Type C (Alarm-Style Experience):** High-priority alert that deep-links directly into a dedicated in-app Alarm Screen with Quick Complete, Snooze, Open Task, and Dismiss controls.
5. **Safe, Bounded Scheduling Architecture:** Never scheduling thousands of alarms in advance; bounded single-step progression coordinated through `ReminderService` and app lifecycle hooks.
6. **Non-destructive Database Migration:** Upgrading schema to version 3 without resetting or dropping user data.

---

## 2. Current Architecture Audit

### 2.1 Component Overview

| Component | File Path | Current Role |
| :--- | :--- | :--- |
| **NotificationChannels** | `lib/core/notifications/notification_channels.dart` | Defines 4 static channels (`deadline_alerts_v2`, `task_reminders_v2`, `overdue_tasks_v2`, `daily_summary_v2`) with fixed sound and vibration patterns. |
| **NotificationService** | `lib/core/notifications/notification_service.dart` | Wraps `flutter_local_notifications` plugin. Handles Android 13+ POST_NOTIFICATIONS and exact alarm permissions (`canScheduleExactNotifications`). Uses `zonedSchedule` with `exactAllowWhileIdle` or `inexactAllowWhileIdle`. |
| **ReminderPlanner** | `lib/core/notifications/reminder_planner.dart` | Pure function that converts `TaskItem` + `List<ReminderSpec>` into concrete `TaskReminder` records. Handles busy-hours window and single 10-minute overdue delay. |
| **ReminderService** | `lib/core/notifications/reminder_service.dart` | Orchestrator connecting UI, database repositories, and `NotificationService`. Handles `syncTask`, `snoozeTask`, `cancelTask`, and `processDueNotifications`. |
| **Database Schema** | `lib/core/database/tables.dart` & `database.dart` | Drift SQLite database. `Tasks` table (schema v2) stores metadata, priority, status, deadline, recurrence. `Reminders` table stores scheduled times and notification IDs. `AppSettings` stores global user preferences. |
| **Android Manifest** | `android/app/src/main/AndroidManifest.xml` | Declares `POST_NOTIFICATIONS`, `VIBRATE`, `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM`, and `USE_EXACT_ALARM`. Registers `ScheduledNotificationReceiver`, `ScheduledNotificationBootReceiver`, and `ActionBroadcastReceiver`. |
| **App Lifecycle** | `lib/app.dart` & `app_bootstrap.dart` | On resume and cold boot, calls `processDueNotifications()`, which converts elapsed reminders to in-app notification center entries and sweeps overdue tasks. |

### 2.2 Current Notification ID Allocation & Cancellation
- **ID Allocation:** `NotificationService.allocateNotificationId(Set<int> taken)` generates random 32-bit positive integers (1,000 to 0x7FFFFFFF) avoiding currently scheduled IDs. Overdue sweep uses `taskId.hashCode & 0x7FFFFFFF` in range 400,000–500,000.
- **Cancellation:** `cancelTaskNotifications(taskId)` queries all reminder records for `taskId` from SQLite and cancels each via `NotificationService.cancelMany(ids)`.
- **Completion Hook:** When a task is marked completed, `cancelTask(taskId)` is invoked, wiping all scheduled OS alarms for that task. If recurring, `_spawnNextOccurrence()` creates a fresh task entity with a distinct ID.

---

## 3. Risks & Identified Gaps

1. **Absence of Persistent Overdue Repetition:**
   - Currently, once a task deadline passes, only a single "at deadline" alert and a single 10-minute overdue nudge are fired. If the user does not open the app, no subsequent alarms ring.
2. **Risk of Unbounded Alarm Flooding:**
   - Pre-scheduling dozens of repeating alarms in advance into Android's `AlarmManager` can trigger OS limits (Android limits each app to a small quota of exact alarms) and cause battery drain.
   - **Remedy:** Use a **bounded next-reminder strategy**. The app schedules *one* next overdue alarm at a time. When it fires or when the app is resumed/bootstrapped, the coordinator checks if the task is still open, increments repeat count, and schedules the next interval up to a configurable maximum count/duration.
3. **Snooze Limitations:**
   - Existing snooze only supports fixed minute durations (5m, 10m, 15m, 30m, 1h) or custom time today/tomorrow. It does not support custom date-time or repeat intervals.
4. **Missing Per-Task Customization:**
   - Tasks cannot specify custom notification titles, custom messages, individual sound choices, vibration patterns, or alarm styles.
5. **Missing In-App Alarm Dialog / Screen (Type C):**
   - Tapping an overdue alarm notification currently only navigates to `TaskDetailsScreen`. An urgent alarm style should present an actionable in-app Alarm dialog/screen with immediate Snooze and Complete actions.
6. **Database Migration Requirement:**
   - Adding new columns to `Tasks` and `Reminders` requires bumping `schemaVersion` to 3 with a non-destructive `onUpgrade` step in `database.dart`.

---

## 4. Implementation Plan (Phases 2 to 11)

### Phase 2: Repeating Overdue Reminders
- Add `AlarmType` enum: `standard`, `soundVibration`, `alarmScreen`.
- Add task fields for persistent reminders:
  - `repeatUntilCompleted`: boolean
  - `repeatIntervalMinutes`: integer (default 15)
  - `maxRepeatCount`: integer (default 10)
  - `currentRepeatCount`: integer (default 0)
- Extend `ReminderPlanner` and `ReminderService` to handle recurring overdue intervals safely.

### Phase 3: Reliable Bounded Scheduling Architecture
- Single coordinator logic: compute and schedule only the immediate next active reminder for any overdue task.
- When `processDueNotifications()` runs on app start, resume, or alarm receiver, check if task is still open and `currentRepeatCount < maxRepeatCount`. If so, schedule the next interval.
- When a task is completed, deleted, or snoozed, cancel obsolete pending alarms immediately.

### Phase 4: Smart Snooze
- Extend `SnoozeSheet` with:
  - Presets (5m, 10m, 15m, 30m, 1h).
  - Custom Date & Time picker.
  - Configurable "Remind me again" interval.
- Ensure snoozing replaces the active alarm without creating orphaned notifications.
- Rechecking completion state upon snooze expiry.

### Phase 5 & 6: Custom Notification Settings & Alarm Types
- Support custom titles, custom messages, and priority templates.
- Channel matrix for:
  - Silent notifications.
  - Standard notifications.
  - Loud alarm with urgent vibration.
- Dedicated in-app Alarm Dialog / Screen for Type C alerts providing: Task Title, Deadline, Overdue Duration, Mark Completed, Snooze, and Dismiss.

### Phase 7: Database & UI Updates
- Drift schema migration to version 3.
- Upgrade `TaskEditorSheet` with an expandable "Reminder & Alarm Settings" section.
- Upgrade `TaskDetailsScreen` with active alarm type, repeat policy, and next reminder display.
- Upgrade `NotificationsScreen` (Alerts) to distinguish scheduled, snoozed, and repeating overdue alerts.
- Upgrade `NotificationSettingsScreen` with global defaults.

### Phase 8 & 9: Correctness, Safety & Regression Tests
- Create `test/unit/alarm_engine_v3_regression_test.dart` covering all 20 test cases outlined in Phase 9.
- Ensure all 157 existing tests continue to pass.

### Phase 10 & 11: Build, QA & Verification
- Run `dart format`, `flutter analyze`, and `flutter test`.
- Build fresh debug APK (`apk/DueMate-debug.apk`), preserving backups.
- Document SHA-256 and deliver complete V3 reports.
