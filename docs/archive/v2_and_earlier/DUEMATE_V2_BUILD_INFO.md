# DueMate v2 — Build & Artifact Information

**Date:** 14 October 2026  
**Application:** DueMate  
**Build Target:** Android Debug APK  
**Toolchain:** Flutter 3.47.5, Dart 3.13.4, Gradle 8.3  

---

## 1. Primary Artifact Delivery

* **Destination Path:** `apk\DueMate-debug.apk`
* **Absolute Path:** `C:\Users\Ashutosh Pandey\Downloads\Remainder application\apk\DueMate-debug.apk`
* **Build Type:** Debug (with Impeller OpenGL backend, Android 14 API 34 compatibility)
* **File Size:** **195,498,786 bytes** (~186.44 MB)
* **SHA-256 Hash:**  
  `F0B3A7DE0EA4BBDB6BA4A367F69CBFEFBC4A2B12436919FBBDC7F2809A0A00EF`
* **Fresh Build Source:** `build\app\outputs\flutter-apk\app-debug.apk` (Bit-for-bit verified match)
* **Build Command:** `flutter build apk --debug`
* **Timestamp:** 14 October 2026, 10:12:09 IST

---

## 2. Preserved Previous Working Backup

To comply with Non-Negotiable Rule 11 ("Keep the current working APK safe. Do not overwrite the only usable build"):

* **Backup Location:** `apk\DueMate-debug-v1-backup.apk`
* **Backup Size:** **195,453,441 bytes**
* **Backup SHA-256 Hash:**  
  `ECB685F0E81DB2467B2B5F1C877CDB96818CD8B35CCAC2632CEC9C08F12275C8`
* **Status:** Fully intact and preserved.

---

## 3. Installation & Verification

The primary artifact was installed and verified on the Android emulator (`emulator-5554`):
```powershell
adb install -r apk\DueMate-debug.apk
adb shell am start-activity -W -n com.deadline.deadline/com.deadline.deadline.MainActivity
```
* **Install Result:** `Success`
* **Launch State:** `COLD`
* **Total Launch Time:** `4,907 ms`
* **Execution Status:** `Complete / OK`
