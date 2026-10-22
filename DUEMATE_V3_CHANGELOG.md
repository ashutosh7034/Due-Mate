# DUEMATE V3 — CHANGELOG & ARCHITECTURAL SUMMARY

## Release Overview
**Version:** DueMate V3  
**Target Platform:** Android (API 26+)  
**Framework:** Flutter / Dart  
**Storage & State:** SQLite via Drift (`schemaVersion: 3`) + Flutter Riverpod  

DueMate V3 introduces a persistent deadline alarm engine, bounded repeat-until-completed scheduling, smart multi-duration snooze workflows, per-task custom notification configurations (sound, vibration, urgency, title, message), and an interactive in-app Alarm Screen (Type C).

---

## 1. Database Schema & Non-Destructive Migration
- **Target Schema Version:** `schemaVersion = 3` (upgraded from 2).
- **Table Modified:** `Tasks`
- **New Columns Added (Non-Destructive Migration):**
  1. `alarm_type` (`INTEGER NOT NULL DEFAULT 0`): Maps to `AlarmType` (`standard`, `soundVibration`, `alarmScreen`).
  2. `repeat_until_completed` (`INTEGER NOT NULL DEFAULT 0`): Boolean flag controlling persistent overdue nudging.
  3. `repeat_interval_minutes` (`INTEGER NOT NULL DEFAULT 15`): Configurable repeat interval (5m, 10m, 15m, 30m, 60m).
  4. `max_repeat_count` (`INTEGER NOT NULL DEFAULT 5`): Configurable upper ceiling to protect battery life.
  5. `current_repeat_count` (`INTEGER NOT NULL DEFAULT 0`): Tracks delivered repeat alerts for the current occurrence.
  6. `custom_notification_title` (`TEXT NULL`): Optional user-defined notification headline.
  7. `custom_notification_body` (`TEXT NULL`): Optional user-defined notification message.
  8. `sound_choice` (`INTEGER NOT NULL DEFAULT 0`): Maps to `NotificationSound` (`systemDefault`, `silent`, `chime`, `bell`, `horn`).
  9. `vibration_choice` (`INTEGER NOT NULL DEFAULT 0`): Maps to `NotificationVibration` (`standard`, `silent`, `urgent`, `continuous`).
  10. `snooze_until` (`INTEGER NULL`): UTC timestamp marking active snooze expiration.
- **Migration Strategy:** Implemented inside `MigrationStrategy.onUpgrade` in `lib/core/database/database.dart`:
  - When `from < 3`, uses idempotent `addColumn` clauses for all 10 columns.
  - Existing user data, task statuses, categories, subtasks, and notification history are completely preserved without recreation or reset.

---

## 2. Notification Engine & Bounded Scheduling
- **Centralized Coordinator:** All scheduling flows pass through `ReminderService` and `NotificationService`.
- **Bounded Scheduling:**
  - The app never schedules infinite or hundreds of future alarms in advance.
  - Overdue repeats are scheduled strictly one-by-one: when the deadline or an active repeat elapses, `processDueNotifications()` schedules the single next reminder (up to `maxRepeatCount`).
- **Notification Channels (`lib/core/notifications/notification_channels.dart`):**
  - `task_reminders_v2`: Standard upcoming reminders with default sound/vibration.
  - `overdue_tasks_v2`: Overdue reminders with high importance.
  - `alarm_sound_vibration_v3`: High-importance alert channel with custom vibration pattern (`continuousVibrationPattern`).
  - `silent_notifications_v3`: Silent notification channel (`playSound: false`, `enableVibration: false`).
- **Alarm Types Supported:**
  - **Type A (Standard):** Standard Android status bar notification.
  - **Type B (Sound & Vibration):** Urgent alert with custom sound and distinct vibration pattern.
  - **Type C (Alarm Screen):** Dedicated high-visibility notification with custom action buttons and instant deep linking to an in-app fullscreen alarm screen.

---

## 3. Smart Snooze Engine
- **Preset Options:** 5 minutes, 10 minutes, 15 minutes, 30 minutes, 1 hour.
- **Custom Date & Time Picker:** Full date/time picker allowing any future moment.
- **Configurable Repeat Interval:** Option to set repeat interval after snooze expires.
- **Lifecycle Guarantees:**
  - Snoozing immediately cancels previous pending reminders and replaces them with an exact OS alarm.
  - `snoozeUntil` is persisted to SQLite.
  - When snooze expires, `processDueNotifications()` verifies task status before taking action.
  - Marking a snoozed task as complete immediately cancels the snoozed alarm.
  - Deleting a snoozed task cleanly cancels all associated alarms.

---

## 4. User Interface & Experience
- **Dedicated Alarm Screen (`lib/features/tasks/widgets/alarm_screen.dart`):**
  - Pulse-animated alarm icon and live overdue countdown ticker.
  - Instant action buttons: "Mark Completed", "Snooze", "Open Task", and "Dismiss Alert".
- **Task Editor (`lib/features/tasks/task_editor_sheet.dart`):**
  - Expandable "Reminder & Alarm Settings" section.
  - Radio group for Alarm Type (Standard, Sound & Vibration, Full Alarm Screen).
  - Repeat-until-completed toggle with interval chips (5m, 10m, 15m, 30m, 1h) and repeat limit chips (3x, 5x, 10x, 20x).
  - Sound and Vibration selectors.
  - Custom title and custom message fields with live preview.
- **Task Details (`lib/features/tasks/task_details_screen.dart`):**
  - Prominent "Snooze Active" banner when task is snoozed.
  - Summary rows for Alarm Type, Repeat Policy, Alert Style, and Custom Title.
  - One-tap "Edit Settings" action in the Reminders section.
- **Alerts Screen (`lib/features/notifications/notifications_screen.dart`):**
  - Added filter tabs: `Snoozed` and `Repeating`.
  - Scheduled cards display dynamic badges: `SNOOZED` and `REPEATING` with elapsed counters.
- **Global Settings (`lib/features/profile/notification_settings_screen.dart`):**
  - Added "DEFAULT ALARMS & PERSISTENT REMINDERS" configuration section allowing users to configure default alarm types, default repeat behavior, default repeat intervals, and default sounds/vibrations.

---

## 5. Backup & Restore
- `BackupService` (`lib/core/services/backup_service.dart`) updated to export and restore all 10 V3 fields.
- Backward compatibility preserved: backups created on V1 or V2 import cleanly with sensible defaults.
