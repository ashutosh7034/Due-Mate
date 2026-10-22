# DueMate — APK Directory & Release Artifact Management

This directory contains the verified Android application package (APK) builds for **DueMate**.

---

## 1. Primary Active Build

| File | Purpose | Build Mode | Verification Status |
|---|---|---|---|
| [`DueMate-Latest.apk`](file:///C:/Users/Ashutosh%20Pandey/Downloads/Remainder%20application/apk/DueMate-Latest.apk) | **Single current release-candidate build** containing all latest features, fixes, and tests. | Debug (`--debug`) | **Active & Verified** |

> [!IMPORTANT]
> **Testing vs Production Notice**:
> `DueMate-Latest.apk` is currently built in **debug mode** for rapid installation, development testing, and QA validation without requiring release keystore signing. Debug APKs are slightly larger due to debugging symbols and should not be uploaded directly to the Google Play Store.

---

## 2. Historical Recovery Backups (Immutable)

The following historical backups are retained for disaster recovery and rollback assurance. **Do not modify, overwrite, or delete these files**:

| File | Historical Milestone | Approximate Size | Retained For |
|---|---|---|---|
| `DueMate-previous-working-backup.apk` | Original stable V2 baseline | ~195.5 MB | Rollback to original baseline |
| `DueMate-V3-debug.apk` | V3 baseline build | ~172.4 MB | Reference point before combined features |
| `DueMate-V3-combined-debug.apk` | Intermediate combined milestone | ~172.4 MB | Reference point before 4-task master update |

---

## 3. How to Build & Update `DueMate-Latest.apk`

We provide an automated, fail-safe PowerShell script located at [`scripts/build_latest_apk.ps1`](file:///C:/Users/Ashutosh%20Pandey/Downloads/Remainder%20application/scripts/build_latest_apk.ps1).

### Standard Build (Debug — Default)
From the project root directory, run:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_latest_apk.ps1
```

The script will automatically execute the complete verification pipeline:
1. `flutter pub get` (Resolves dependencies)
2. `flutter analyze` (Ensures 0 analyzer issues)
3. `flutter test` (Executes all 227+ automated unit & widget tests)
4. `flutter build apk --debug` (Builds fresh APK artifact)
5. Validates that the artifact exists and is non-empty
6. Copies to a staged temporary file (`apk/DueMate-Latest.apk.tmp`) and verifies SHA-256 hash
7. Atomically replaces `apk/DueMate-Latest.apk` only after all steps succeed
8. Re-verifies target file integrity and reports build metrics

> [!NOTE]
> If any test or analyzer check fails, the script halts immediately and **leaves the existing `DueMate-Latest.apk` completely untouched**.

### Optional Release Build
To generate a production-ready release build when needed:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_latest_apk.ps1 -Release
```
This builds with `--release` and outputs to `apk/DueMate-Release-Latest.apk` without overwriting the debug test candidate.

---

## 4. How to Verify SHA-256 Hashes

To manually inspect or audit the SHA-256 checksum of any APK:

### Using PowerShell:
```powershell
Get-FileHash -Path .\apk\DueMate-Latest.apk -Algorithm SHA256 | Format-List
```

### Using Command Prompt (certutil):
```cmd
certutil -hashfile apk\DueMate-Latest.apk SHA256
```

---

## 5. Maintenance Policy

1. **One Latest APK**: `DueMate-Latest.apk` is the sole destination for updated builds. Do not create new timestamped or duplicate filenames in this folder.
2. **Backups Protected**: Historical backup APKs must never be removed unless explicitly requested by the project owner.
3. **Automated Verification**: Never manually copy or rename an untested `.apk` into `apk/DueMate-Latest.apk`. Always use `scripts/build_latest_apk.ps1`.
