# DUEMATE V3 — CLEANUP AUDIT & STORAGE OPTIMIZATION PLAN

**Date:** 22 October 2026  
**Project Name:** DueMate  
**Project Path:** `C:\Users\Ashutosh Pandey\Downloads\Remainder application`  
**Current Baseline:** V3 Persistent Deadline Alarms, Smart Snooze & Custom Notification Engine  
**Test State:** 177 passing tests, 0 Flutter analyzer issues  
**Total Initial Project Size:** **3,297.04 MB (3.22 GB)**  

---

## 1. Initial Storage Inventory

A full recursive scan of the project directory revealed the following disk consumption by category:

| Item / Directory | Type | Size (MB) | Size (Bytes) | Category / Purpose |
|---|---|---|---|---|
| `build\` | DIR | 2,508.41 MB | 2,630,262,328 | Ephemeral Gradle build artifacts, Java/C++ outputs, intermediate bundles, and 4 duplicate APKs |
| `apk\` | DIR | 559.28 MB | 586,447,093 | Stored APK releases and backups (v1, v2, and previous working build) |
| `.dart_tool\` | DIR | 214.55 MB | 224,975,183 | Dart/Flutter plugin metadata, package configs, build_runner cache |
| `android\` | DIR | 13.25 MB | 13,896,995 | Android native Gradle wrapper, manifest, and configuration (PROTECTED) |
| `lib\` | DIR | 0.77 MB | 803,640 | Application source code, Drift schema, state models, UI (PROTECTED) |
| `.idea\` | DIR | 0.17 MB | 177,101 | IDE project workspace settings |
| `test\` | DIR | 0.15 MB | 161,119 | Unit, regression, and widget test suites (PROTECTED) |
| `duemate_v2_launch.png` | FILE | 0.15 MB | 156,615 | One-time temporary screenshot from V2 milestone |
| `ios\` | DIR | 0.07 MB | 72,293 | iOS platform shell files (PROTECTED) |
| `windows\` | DIR | 0.07 MB | 70,085 | Windows platform shell files (PROTECTED) |
| `web\` | DIR | 0.04 MB | 43,567 | Web platform shell files (PROTECTED) |
| `pubspec.lock` | FILE | 0.03 MB | 33,664 | Locked package versions (PROTECTED) |
| Root Markdown Documents | FILES | ~0.10 MB | ~100,000 | Documentation reports (V2 reports, fix reports, V3 reports) |
| Configuration Files | FILES | < 0.02 MB | ~15,000 | `pubspec.yaml`, `analysis_options.yaml`, etc. (PROTECTED) |

---

## 2. Complete APK & AAB Inventory

Every `.apk` file across the project was located, measured, and cryptographically verified via SHA-256:

| # | File Path | Size (Bytes) | SHA-256 Checksum | Classification & Status |
|---|---|---|---|---|
| **1** | `build\app\outputs\flutter-apk\DueMate-V3-debug.apk` | 195,569,214 | `EA60DA857FD42E89D5F97B630D95493E22470F2C80CDD06BF2BD7807734DA795` | **Current V3 Release Artifact** — Verified working build. |
| **2** | `build\app\outputs\flutter-apk\app-debug.apk` | 195,569,214 | `EA60DA857FD42E89D5F97B630D95493E22470F2C80CDD06BF2BD7807734DA795` | **Duplicate of #1** — Standard Flutter output name. |
| **3** | `build\app\outputs\apk\debug\app-debug.apk` | 195,569,214 | `EA60DA857FD42E89D5F97B630D95493E22470F2C80CDD06BF2BD7807734DA795` | **Duplicate of #1** — Gradle internal task output. |
| **4** | `apk\DueMate-debug.apk` | 195,494,866 | `908E51B6BB15184931B2F642B682343C891B280CE17A968A08D55A098EE14E8F` | **Previous Working Build** — Build from 21-Oct-2026 (post-completion-fix, pre-V3). |
| **5** | `build\app\outputs\flutter-apk\app-debug-backup-pre-v3.apk` | 195,494,866 | `908E51B6BB15184931B2F642B682343C891B280CE17A968A08D55A098EE14E8F` | **Duplicate of #4** — Temporary pre-build safety copy in `build/`. |
| **6** | `apk\DueMate-debug-v2-backup.apk` | 195,498,786 | `F0B3A7DE0EA4BBDB6BA4A367F69CBFEFBC4A2B12436919FBBDC7F2809A0A00EF` | **Obsolete V2 Backup** — Superseded by #4 and #1. |
| **7** | `apk\DueMate-debug-v1-backup.apk` | 195,453,441 | `ECB685F0E81DB2467B2B5F1C877CDB96818CD8B35CCAC2632CEC9C08F12275C8` | **Obsolete V1 Backup** — Superseded by subsequent milestones. |

**Total APK storage:** 1,368.53 MB (~1.34 GB across 7 files).  
**No `.aab` (App Bundle) files** were present in the repository.

---

## 3. Protected Files & Directories (Do Not Delete)

The following items are critical to project functionality, tests, and build reproducibility and are strictly preserved:

1. **Application Source Code**: `lib/` (all models, repositories, providers, database tables, notifications, features, and UI).
2. **Project Configurations**: `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`.
3. **Database Definitions & Generated Code**: `lib/core/database/database.dart`, `tables.dart`, `database.g.dart`.
4. **Android Native Layer**: `android/` (including `AndroidManifest.xml`, Gradle wrapper, `build.gradle`, receivers).
5. **Regression & Unit Tests**: `test/` (all 21 test files, including 157 baseline tests and 20 V3 alarm tests).
6. **Platform Support Shells**: `ios/`, `windows/`, `web/`, `tool/generate_icons.ps1`.
7. **Current V3 Documentation & Project Guide**:
   - `README.md`
   - `DUEMATE_V3_ALARM_AUDIT.md`
   - `DUEMATE_V3_CHANGELOG.md`
   - `DUEMATE_V3_TEST_REPORT.md`
   - `DUEMATE_V3_MANUAL_QA.md`
   - `DUEMATE_V3_BUILD_INFO.md`

---

## 4. Two-Stage Cleanup Strategy

### Stage A: APK Consolidation & Safe Preservation
1. Ensure the `apk\` directory contains exactly:
   - `apk\DueMate-V3-debug.apk` (Latest verified V3 build with persistent deadline alarms, SHA-256: `EA60DA857FD42E89D5F97B630D95493E22470F2C80CDD06BF2BD7807734DA795`).
   - `apk\DueMate-previous-working-backup.apk` (Verified rollback build, SHA-256: `908E51B6BB15184931B2F642B682343C891B280CE17A968A08D55A098EE14E8F`).
2. Verify hashes of both retained APKs before deleting any artifact.
3. Remove redundant older backups from `apk\`:
   - `DueMate-debug-v1-backup.apk` (~186.4 MB)
   - `DueMate-debug-v2-backup.apk` (~186.4 MB)
   - Remove duplicate unversioned `DueMate-debug.apk` once renamed/verified.

### Stage B: Ephemeral Build & Cache Directory Cleanup
1. Run `flutter clean` to safely remove:
   - `build\` (~2,508 MB)
   - `.dart_tool\` (~215 MB)
   - Ephemeral Gradle intermediate caches, C++ compiler outputs, and duplicate APK copies in `build/app/outputs/`.
2. Run `flutter pub get` to restore project dependencies and plugin bindings.

### Stage C: Obsolete File & Documentation Archival
1. Move historical, superseded documentation into a structured archive directory `docs/archive/v2_and_earlier/`:
   - `CLEANUP_AUDIT_REPORT.md`
   - `DUEMATE_V2_AUDIT.md`
   - `DUEMATE_V2_BUILD_INFO.md`
   - `DUEMATE_V2_CHANGELOG.md`
   - `DUEMATE_V2_MANUAL_QA.md`
   - `DUEMATE_V2_TEST_REPORT.md`
   - `TASK_COMPLETION_STATUS_FIX_REPORT.md`
   - `duemate_v2_launch.png`
2. Keep root clean, retaining only current V3 documentation, `README.md`, and cleanup audit/report documents.

---

## 5. Projected Storage Savings

| Category | Initial Size | Projected Post-Cleanup | Projected Reclaimed |
|---|---|---|---|
| `build\` directory | 2,508.41 MB | ~0 MB (regenerated on build) | ~2,508 MB |
| `apk\` directory | 559.28 MB | ~373.0 MB (2 verified builds) | ~186.3 MB |
| `.dart_tool\` cache | 214.55 MB | ~25 MB (fresh pub get) | ~189.5 MB |
| Temporary screenshots & obsolete files | 0.16 MB | 0 MB (archived / cleaned) | ~0.16 MB |
| **Total Estimated Disk Savings** | | | **~2.88 GB** |

---

## 6. Verification Plan Post-Cleanup
After executing the cleanup:
1. Run `flutter pub get` (confirm clean dependency resolution).
2. Run `dart format --output=none --set-exit-if-changed lib test` (confirm code formatting integrity).
3. Run `flutter analyze` (confirm 0 errors, 0 warnings, 0 infos).
4. Run `flutter test` (confirm all 177 tests pass).
5. Build fresh debug APK `flutter build apk --debug` and verify checksum and size.
6. Generate `DUEMATE_CLEANUP_REPORT.md` detailing actual before-and-after measurements.
