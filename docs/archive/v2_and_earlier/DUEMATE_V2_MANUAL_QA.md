# DueMate v2 — Manual QA Verification Guide

**Application:** DueMate v2  
**Date:** 14 October 2026  
**Target:** Android (Physical device or Android Emulator API 34)  

---

## 1. Quick Add & Task Creation
* **Steps:**
  1. Open DueMate. Tap **+ Add task** floating button on the Dashboard.
  2. In title, enter: `Prepare presentation tomorrow at 5pm`.
  3. Verify the parser suggests tomorrow 5:00 PM and appropriate priority.
  4. Tap **Add task**.
* **Expected Result:** Task appears immediately in Dashboard and Tasks tab. Exact notification scheduled without errors.
* **Actual Result:** Verified.

---

## 2. Snooze Reminder Flow
* **Steps:**
  1. On any overdue task or card, tap the three-dots menu (or open Task Details).
  2. Select **Snooze reminder**.
  3. Choose **15 minutes** (or custom interval).
  4. Observe the confirmation toast and Alerts screen.
* **Expected Result:** A custom exact alarm is scheduled for 15 minutes in the future. The task reflects the snoozed reminder.
* **Actual Result:** Verified via automated regression test `snooze_regression_test.dart` and UI integration.

---

## 3. Undo Deletion & Completion
* **Steps:**
  1. In the Dashboard or Tasks tab, tap the checkbox to complete a task.
  2. Observe the floating SnackBar: *"Task marked completed"* with an **Undo** button.
  3. Tap **Undo**.
  4. Delete a task from Task Details.
  5. Tap **Undo** on the deletion SnackBar.
* **Expected Result:** In both cases, the task and its subtasks/reminders are immediately restored to their previous state in SQLite and visible on screen.
* **Actual Result:** Verified via `bulk_and_undo_test.dart`.

---

## 4. Multi-Select & Bulk Actions
* **Steps:**
  1. Navigate to the **Tasks** tab.
  2. Long press any task card.
  3. Notice the selection mode activates with a counter in the AppBar.
  4. Select multiple tasks (or tap **Select all**).
  5. Tap the **Complete** icon or **Delete** icon.
* **Expected Result:** All selected tasks are processed together with confirmation and SnackBar undo support.
* **Actual Result:** Verified.

---

## 5. Data Backup & Restore
* **Steps:**
  1. Navigate to **Profile** > **Preferences** > **Data & Backup**.
  2. Tap **Export Backup (Copy JSON)**.
  3. Paste into notes or the restore input area.
  4. Notice the validation box turns green: *"Valid DueMate Backup"* with exact task and category counts.
  5. Tap **Restore & Merge Tasks**.
* **Expected Result:** Tasks and categories are safely merged without duplicating identical IDs.
* **Actual Result:** Verified via `backup_service_test.dart`.

---

## 6. Scrolling & Frame Rate in Alerts
* **Steps:**
  1. Tap the **Alerts** tab (fourth bottom bar item).
  2. Rapidly fling and scroll down the scheduled reminders and delivered history.
* **Expected Result:** Fluid 60fps scrolling without dropped frames, thanks to the new `CustomScrollView` and lazy `SliverList.separated` virtualization.
* **Actual Result:** Verified.
