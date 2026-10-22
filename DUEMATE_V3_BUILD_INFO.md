# DUEMATE V3 — BUILD & ARTIFACT INFORMATION

## Build Information
- **Application Name:** DueMate
- **Build Target:** Android Debug APK
- **Flutter Version:** 3.38.3 (Channel stable)
- **Dart Version:** 3.10.7
- **Gradle Task:** `assembleDebug`
- **Build Timestamp:** October 2026
- **Database Schema Version:** `schemaVersion = 3` (SQLite via Drift)

---

## Artifact Details

### 1. Primary V3 Release APK (Fresh Rebuilt & Optimized)
- **Relative Path:** `apk/DueMate-V3-debug.apk`
- **Build Output Path:** `build/app/outputs/flutter-apk/app-debug.apk`
- **Absolute Path:** `C:\Users\Ashutosh Pandey\Downloads\Remainder application\apk\DueMate-V3-debug.apk`
- **File Size:** `172,384,347 bytes` (~164.4 MB)
- **SHA-256 Checksum:**  
  `74E5C267D1098294EA7391CD66494279F6547DC272053F5B6875E265D0032B07`

### 2. Pre-V3 Working Fallback Backup
- **Relative Path:** `apk/DueMate-previous-working-backup.apk`
- **Absolute Path:** `C:\Users\Ashutosh Pandey\Downloads\Remainder application\apk\DueMate-previous-working-backup.apk`
- **File Size:** `195,494,866 bytes` (~186.4 MB)
- **SHA-256 Checksum:**  
  `908E51B6BB15184931B2F642B682343C891B280CE17A968A08D55A098EE14E8F`
- **Purpose:** Guaranteed fallback to pre-V3 working build (with task completion bug fix).

---

## Android Compatibility & Permissions
- **Min SDK:** 21 (Android 5.0 Lollipop)
- **Target SDK:** 34 (Android 14)
- **Permissions Declared in `AndroidManifest.xml`:**
  - `android.permission.POST_NOTIFICATIONS` (Android 13+ runtime notification permission)
  - `android.permission.VIBRATE` (Haptic feedback & urgent alarm vibration)
  - `android.permission.RECEIVE_BOOT_COMPLETED` (Alarm recovery after device reboot)
  - `android.permission.SCHEDULE_EXACT_ALARM` (Exact alarm scheduling on Android 12)
  - `android.permission.USE_EXACT_ALARM` (Automatic exact alarm permission on Android 13+ for reminder apps)
- **Broadcast Receivers:**
  - `com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver`
  - `com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver` (`BOOT_COMPLETED`, `MY_PACKAGE_REPLACED`, `QUICKBOOT_POWERON`)
  - `com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver`

---

## Safe Installation Instructions
To install the new build without wiping or resetting the existing SQLite database:

```powershell
# Using adb (preserves user data):
adb install -r "C:\Users\Ashutosh Pandey\Downloads\Remainder application\apk\DueMate-V3-debug.apk"
```
The `-r` flag ensures existing application data and database records are kept intact.
On first launch, Drift runs the non-destructive `onUpgrade` migration to `schemaVersion: 3`, automatically adding the 10 new configuration columns to `Tasks`.
