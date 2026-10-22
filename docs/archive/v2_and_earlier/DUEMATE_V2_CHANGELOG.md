# DueMate v2 — Complete Engineering Changelog

**Release:** DueMate v2.0.0  
**Date:** 14 October 2026  
**Target Platform:** Android (API 34+ / Android 14)  

---

## 1. Summary of Changes

DueMate v2 enhances performance, refines UI/UX responsiveness, and implements high-priority features while preserving 100% of existing user data, SQLite schemas, native Android alarm scheduling, and test suite integrity.

---

## 2. Detailed File Modifications

### A. Core Architecture & Services
1. **`lib/core/services/app_bootstrap.dart`**
   - Replaced `ref.watch()` calls with `ref.read()` in `appBootstrapProvider`.
   - Prevents re-triggering bootstrap initialization (and multiple notification sweeps) whenever settings or categories update during runtime.

2. **`lib/core/database/database.dart`**
   - Added idempotent indexes:
     - `idx_tasks_category ON tasks(category_id)`
     - `idx_notifications_task ON task_notifications(task_id)`
   - Applied in both `onCreate` and `beforeOpen` callbacks to ensure zero-migration impact on existing user databases.

3. **`lib/core/notifications/reminder_service.dart`**
   - Added `snoozeTask({required TaskItem task, required Duration duration})`.
   - Schedules a custom exact alarm via `NotificationService` and persists the reminder row with `ReminderKind.custom`.

4. **`lib/core/notifications/notification_service.dart`**
   - Wrapped single-line `if` flow control in braces to conform to Dart linter rules.

5. **`lib/core/services/backup_service.dart`** *(New)*
   - Implemented `exportBackupData()`: Full JSON export of categories, tasks, subtasks, and reminders.
   - Implemented `validateBackup()`: Validates schema version, app identifier, and structure before attempting restore.
   - Implemented `restoreBackup()`: Runs in a transactional block to restore categories, top-level tasks, subtasks, and reminders. Automatically reschedules future alarms for active tasks.

### B. State Management & Controllers
6. **`lib/providers/task_controller.dart`**
   - Added deletion undo buffer: `_lastDeletedTask`, `_lastDeletedSubtasks`, `_lastDeletedReminders`.
   - Added `undoDelete()`: Re-inserts deleted task, subtasks, and restores reminders with OS alarm re-registration.
   - Added `snoozeTask(String id, Duration duration)`: Public controller entry point for snooze interactions.
   - Added `completeMultiple(List<String> ids)`: Bulk completes tasks in a single user action.
   - Added `deleteMultiple(List<String> ids)`: Bulk deletes selected tasks with undo protection.

### C. UI & Screens
7. **`lib/features/notifications/notifications_screen.dart`**
   - Migrated from eager `ListView(children: [...])` to virtualized `CustomScrollView` with `SliverList.separated`.
   - Guarantees 60fps scrolling and memory-efficient rendering when large notification histories accumulate.

8. **`lib/features/tasks/tasks_screen.dart`**
   - Connected `taskListResultsProvider` directly to `currentClockProvider` for reactive deadline recalculation.
   - Added Multi-Select Selection Mode with AppBar action bar (`Select All`, `Cancel`, `Bulk Complete`, `Bulk Delete`).
   - Integrated floating SnackBar with "Undo" action on task completion and deletion.

9. **`lib/widgets/task_card.dart`**
   - Added multi-select mode support: `isSelected`, `isSelectionMode`, `onToggleSelect`, and `onLongPress`.
   - Highlights selected cards with theme-aware border and checkbox overlay.

10. **`lib/features/tasks/snooze_sheet.dart`** *(New)*
    - Interactive modal bottom sheet providing quick snooze intervals:
      - 5 minutes
      - 10 minutes
      - 15 minutes
      - 30 minutes
      - 1 hour
      - Custom date & time picker

11. **`lib/features/dashboard/dashboard_screen.dart`**
    - Added Snooze action to overdue and task card popup menus.
    - Added interactive SnackBar with "Undo" button on task completion.

12. **`lib/features/tasks/task_details_screen.dart`**
    - Added Snooze action in header menu and a dedicated "Snooze" action button in the persistent bottom bar.
    - Added interactive SnackBar with "Undo" on completion.

13. **`lib/features/profile/data_management_screen.dart`** *(New)*
    - Full screen for backup and restoration.
    - One-tap JSON export with clipboard copy and character count.
    - Live JSON validation with feedback on task/category counts.
    - Choice of Merge mode vs Replace mode with confirmation modal.

14. **`lib/features/profile/profile_screen.dart`**
    - Added `Data & Backup` tile in the Preferences group navigating to `DataManagementScreen`.

15. **`lib/routes/app_routes.dart`**
    - Added `AppRoutes.dataManagement = '/data-management'`.

---

## 3. Automated Test Suite Additions
16. **`test/unit/snooze_regression_test.dart`** *(New)*
    - Verifies custom alarm scheduling at `now.add(duration)`.
    - Verifies persistence in SQLite reminders table.
    - Verifies respect of global notification disabled setting.

17. **`test/unit/bulk_and_undo_test.dart`** *(New)*
    - Verifies complete restoration of task, subtasks, and reminders via `undoDelete()`.
    - Verifies bulk complete and bulk delete operations across multiple task IDs.

18. **`test/unit/backup_service_test.dart`** *(New)*
    - Verifies JSON structure export matching DueMate schema.
    - Verifies rejection of corrupted, mismatched, or malformed JSON payloads.
    - Verifies transactional restore preserving parent-child subtask relationships.
