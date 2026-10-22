# DueMate v2 — Automated & Integration Test Report

**Date:** 14 October 2026  
**Execution Environment:** Windows PowerShell, Flutter 3.47.5, Dart 3.13.4  
**Target Hardware / Device:** Android Emulator (Pixel 8a, Android 14 / API 34, `emulator-5554`)  
**Overall Result:** **PASS (100% pass rate — 145/145 tests passed)**  

---

## 1. Exact Verification Commands Executed

### A. Code Formatting
```powershell
& "C:\src\flutter\bin\dart.bat" format --output=none --set-exit-if-changed lib test
```
* **Exit Code:** `0`
* **Result:** `Formatted 102 files (0 changed) in 0.49 seconds.`

### B. Static Code Analysis
```powershell
& "C:\src\flutter\bin\flutter.bat" analyze
```
* **Exit Code:** `0`
* **Result:** `Analyzing Remainder application... No issues found! (ran in 3.8s)`

### C. Automated Test Suite
```powershell
& "C:\src\flutter\bin\flutter.bat" test
```
* **Exit Code:** `0`
* **Total Tests Executed:** **145**
* **Passed:** **145**
* **Failed:** **0**
* **Duration:** ~5 seconds

---

## 2. Test Breakdown by Domain

| Test Suite / Area | File | Test Count | Result |
|---|---|---|---|
| **Snooze Alarms Regression** | `test/unit/snooze_regression_test.dart` | 2 | **PASS** |
| **Bulk Actions & Undo** | `test/unit/bulk_and_undo_test.dart` | 3 | **PASS** |
| **Backup & Restore Service** | `test/unit/backup_service_test.dart` | 3 | **PASS** |
| **Notification Scheduling** | `test/unit/notification_scheduling_regression_test.dart` | 4 | **PASS** |
| **Task Creation & Safety** | `test/unit/task_creation_regression_test.dart` | 3 | **PASS** |
| **Notification Flow & Channels**| `test/unit/notification_flow_test.dart` | 5 | **PASS** |
| **Countdown Consistency** | `test/unit/countdown_consistency_test.dart` | 3 | **PASS** |
| **Alerts & Filter Logic** | `test/unit/alerts_filter_regression_test.dart` | 4 | **PASS** |
| **Reminder Service & Planning** | `test/unit/reminder_service_test.dart` | 12 | **PASS** |
| **Reminder Planner** | `test/unit/reminder_planner_test.dart` | 18 | **PASS** |
| **Task Repository & SQLite** | `test/unit/task_repository_test.dart` | 22 | **PASS** |
| **Deadline Calculator** | `test/unit/deadline_calculator_test.dart` | 15 | **PASS** |
| **Recurrence Calculator** | `test/unit/recurrence_calculator_test.dart` | 12 | **PASS** |
| **Quick Add Parser** | `test/unit/quick_add_parser_test.dart` | 8 | **PASS** |
| **Task Sorter & Urgency** | `test/unit/task_sorter_test.dart` | 10 | **PASS** |
| **Settings & Repositories** | `test/unit/settings_repository_test.dart` | 6 | **PASS** |
| **Auth Service** | `test/unit/auth_service_test.dart` | 5 | **PASS** |
| **Widget & UI Integration** | `test/widget/*` | 10 | **PASS** |
| **Total** | | **145** | **100% PASS** |

---

## 3. Platform & Notification Verification Evidence

### Device Information
* **Target Device:** `emulator-5554` (Pixel 8a, Android 14 / API 34).
* **Package Name:** `com.deadline.deadline`.
* **Rendering Engine:** Impeller (OpenGLES backend).

### Cold Launch Benchmark
* **Command:** `adb shell am start-activity -W -n com.deadline.deadline/com.deadline.deadline.MainActivity`
* **Total Time:** **4,907 ms** (Down from 4,957 ms baseline).
* **Wait Time:** **4,924 ms** (Down from 4,976 ms baseline).
* **Launch State:** `COLD`.
* **Status:** `ok`.

### Notification System Health
* Exact alarms permitted: `USE_EXACT_ALARM` & `SCHEDULE_EXACT_ALARM` active in `AndroidManifest.xml`.
* High-priority notification channels active: `deadline_alerts_v2`, `overdue_tasks_v2`, `daily_summary_v1`.
* Timezone support: Validated with `Asia/Calcutta` <-> `Asia/Kolkata` aliases.
