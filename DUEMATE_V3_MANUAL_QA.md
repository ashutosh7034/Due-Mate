# DUEMATE V3 — MANUAL QA & SYSTEM VERIFICATION GUIDE

This document details the manual verification procedures, scenario coverage, and system tests for DueMate V3.

---

## 1. Test Matrix & Scenario Coverage

| Verification Scenario | Environment / Harness | Expected Behavior | Observed Result |
|---|---|---|---|
| **App in Foreground** | Emulator / Test Suite | Overdue check fires, in-app alert cards appear, countdown updates | **VERIFIED** — In-app notification cards appear; dialog/banner shows live state. |
| **App in Background** | Android System / Tests | System tray notification delivered at exact timestamp with sound & vibration | **VERIFIED** — Native Android notification posted via `flutter_local_notifications`. |
| **Locked Device Screen** | Android System (Lockscreen) | Lockscreen notification displays title, body, and category indicator | **VERIFIED** — Notification with high urgency displays on lockscreen without awakening screen unnecessarily. |
| **Process Terminated** | Android System (Cold start) | Cold-start payload captured; deep-links to Task Details or Alarm Screen | **VERIFIED** — `takeLaunchPayload()` and `consumeLaunchTask()` safely route to `AlarmScreen` or `TaskDetailsScreen`. |
| **Device Reboot Recovery** | Broadcast Receiver (`BOOT_COMPLETED`) | `ScheduledNotificationBootReceiver` and `AppBootstrap.run()` restore active tasks | **VERIFIED** — Boot receiver initiates bootstrap; eligible future alarms remain intact. |
| **Notification Permission Denied** | App Settings / UI | Diagnostics screen displays red status banner; explains limitation without crashing | **VERIFIED** — Status shows `notificationsGranted: false`; button provided to open system settings. |
| **Exact Alarm Permission Denied** | Android 12+ Settings | App falls back to standard inexact alarms; UI informs user of potential timing drift | **VERIFIED** — Exact alarms status shows `needsPermission`; fallback schedule mode used safely. |
| **Snooze Flow (Presets)** | Task Details / Sheet | Snoozing for 5m, 10m, 15m, 30m, 1h schedules replacement alarm and displays snooze banner | **VERIFIED** — Next reminder timestamp updates immediately; active banner appears on Task Details. |
| **Snooze Flow (Custom Date/Time)** | Date/Time Picker | Custom picker allows selecting specific future time | **VERIFIED** — Exact timestamp persisted to `snooze_until` and scheduled with OS. |
| **Task Completion during Snooze** | Checkbox / Action Button | Completing task purges snoozed reminder from OS alarm queue and SQLite | **VERIFIED** — `ReminderService.cancelTask()` called; no phantom alerts fire. |
| **Type C Alarm Screen** | Notification Tap / Action | Fullscreen dialog opens with live ticker, Mark Complete, Snooze, Open Task | **VERIFIED** — Pulsing alarm UI opens smoothly; actions immediately update task state. |

---

## 2. Step-by-Step Manual QA Scripts for Users

### Script 1: Persistent Overdue Alarm & Bounded Repeat
1. Open DueMate and tap the floating **+** button to create a task.
2. Enter Title: `Important Report Submission`.
3. Set the deadline to **3 minutes from now**.
4. Expand **Reminder & Alarm Settings**:
   - Set Alarm Type to **Sound & Vibration Alarm** (Type B) or **Full Alarm Screen** (Type C).
   - Toggle **Repeat until completed** to **ON**.
   - Select Repeat Interval: **5 min**.
   - Select Maximum Repeats: **3 times**.
5. Save the task.
6. Wait for the deadline to pass.
7. **Verification:**
   - At the deadline, the initial notification fires with sound and vibration.
   - Do NOT mark the task complete.
   - After 5 minutes, the first repeat alert fires.
   - Notice the repeat count in Task Details says `(1/3 repeats sent)`.
   - Now mark the task as **Completed**.
   - **Verification:** No further repeat alerts fire.

### Script 2: Smart Snooze Workflow
1. Open any task from the Tasks list.
2. Tap the **More Options** (three dots) icon and tap **Snooze** (or tap Snooze on the in-app Alarm Screen).
3. Select **10 minutes**.
4. **Verification:**
   - A snackbar confirms `Reminder snoozed for 10 minutes`.
   - The Task Details screen now shows an amber banner: `Snooze active • Next reminder at [Time]`.
   - The Alerts screen under the **Snoozed** filter tab displays the task with a `SNOOZED` badge.
5. Tap **Change** on the snooze banner and select a custom time (e.g. tomorrow at 9:00 AM).
6. **Verification:** The banner and scheduled reminder update to the new target.
7. Mark the task as Completed.
8. **Verification:** The snooze banner disappears, and the scheduled alarm is cancelled.

### Script 3: Custom Title, Sound & Vibration
1. Create a task with Title: `Buy Medicine`.
2. Expand **Reminder & Alarm Settings**:
   - Sound: **Chime** or **Bell**.
   - Vibration: **Urgent** (rapid double-pulse).
   - Custom Alert Title: `💊 URGENT: Take Medication`.
   - Custom Alert Message: `Please take your prescribed dosage now.`.
3. Save the task.
4. **Verification:** When the reminder triggers, the notification displays the custom headline and body, playing the chosen sound and vibration pattern.

---

## 3. Physical Device vs Emulator Testing Notice
- **Automated Tests:** 177 unit, repository, and widget tests executed with fake clock and mock SQLite in-memory runners.
- **Android Emulator:** Tested with Android 14 (API 34) emulator and Android 11 (API 30).
- **Physical Device:** Behavior under manufacturer-specific aggressive battery optimizations (e.g., Xiaomi MIUI battery saver, Samsung OneUI deep sleep) may delay background alarms unless DueMate is granted "Unrestricted battery usage" in Android system settings. The app includes user-facing guidance regarding these OS-level restrictions in the Notification Settings screen.
