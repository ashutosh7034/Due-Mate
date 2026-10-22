<#
.SYNOPSIS
    Builds, tests, validates, and publishes the latest DueMate APK to apk/DueMate-Latest.apk.

.DESCRIPTION
    This script coordinates the full Flutter CI/CD pipeline locally:
    1. Resolves dependencies (flutter pub get)
    2. Runs static code analysis (flutter analyze)
    3. Runs the test suite (flutter test)
    4. Builds the debug APK (or release APK if -Release is specified)
    5. Validates non-empty output and SHA-256 hash via a staged temporary copy
    6. Atomically updates apk/DueMate-Latest.apk only after 100% verification
    7. Preserves all historical recovery backups untouched

.PARAMETER Release
    Optional switch. If specified, builds --release and targets apk/DueMate-Release-Latest.apk.
    Defaults to $false (debug build for testing).

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scripts\build_latest_apk.ps1
    Builds and publishes apk/DueMate-Latest.apk (debug mode).

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scripts\build_latest_apk.ps1 -Release
    Builds and publishes apk/DueMate-Release-Latest.apk (release mode).
#>

[CmdletBinding()]
param(
    [switch]$Release = $false
)

$ErrorActionPreference = "Stop"

# 1. Project Directory Resolution
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
Set-Location -Path $projectRoot

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " DueMate - Automated Latest APK Build and Verification" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Project Root : $projectRoot"
$modeStr = if ($Release) { 'Release (--release)' } else { 'Debug (--debug) [Default]' }
Write-Host "Build Mode   : $modeStr"
$dateStr = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
Write-Host "Timestamp    : $dateStr"
Write-Host ""

# 2. Locate Flutter Executable
$flutterCmd = "flutter"
if (-not (Get-Command "flutter" -ErrorAction SilentlyContinue)) {
    if (Test-Path "C:\src\flutter\bin\flutter.bat") {
        $flutterCmd = "C:\src\flutter\bin\flutter.bat"
    } else {
        Write-Host "ERROR: Flutter executable could not be found in PATH or at C:\src\flutter\bin\flutter.bat" -ForegroundColor Red
        exit 1
    }
}
Write-Host "Flutter Executable: $flutterCmd" -ForegroundColor DarkGray
Write-Host ""

# Helper to run Flutter commands safely with reliable exit code checking
function Invoke-FlutterStep {
    param(
        [string]$StepTitle,
        [string[]]$Arguments
    )
    $argString = $Arguments -join ' '
    Write-Host "[STEP] ${StepTitle} -> $flutterCmd $argString" -ForegroundColor Yellow
    $startTime = Get-Date

    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & $flutterCmd @Arguments
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $prevEAP

    if ($exitCode -ne 0) {
        Write-Host "`n[FAIL] Step '${StepTitle}' failed with exit code $exitCode. Aborting build pipeline." -ForegroundColor Red
        exit $exitCode
    }
    $elapsed = ((Get-Date) - $startTime).TotalSeconds.ToString("F1")
    Write-Host "[PASS] ${StepTitle} completed successfully in ${elapsed}s.`n" -ForegroundColor Green
}

# 3. Pipeline Execution: Dependencies, Analysis, Tests
Invoke-FlutterStep "1/4 Resolving dependencies" @("pub", "get")
Invoke-FlutterStep "2/4 Running static code analysis" @("analyze")
Invoke-FlutterStep "3/4 Running automated test suite" @("test")

# 4. Determine Target Paths and Build Mode
$apkDir = Join-Path $projectRoot "apk"
if (-not (Test-Path $apkDir)) {
    New-Item -ItemType Directory -Path $apkDir -Force | Out-Null
}

if ($Release) {
    $buildArg = "--release"
    $sourceApk = Join-Path $projectRoot "build\app\outputs\flutter-apk\app-release.apk"
    $targetApkName = "DueMate-Release-Latest.apk"
} else {
    $buildArg = "--debug"
    $sourceApk = Join-Path $projectRoot "build\app\outputs\flutter-apk\app-debug.apk"
    $targetApkName = "DueMate-Latest.apk"
}

$targetApk = Join-Path $apkDir $targetApkName
$tempApk = Join-Path $apkDir "$targetApkName.tmp"

# 5. Build Step
Invoke-FlutterStep "4/4 Building Android APK ($buildArg)" @("build", "apk", $buildArg)

# 6. Verify Source Build Artifact
Write-Host "[VALIDATION] Verifying source build artifact..." -ForegroundColor Yellow
if (-not (Test-Path -Path $sourceApk -PathType Leaf)) {
    Write-Host "ERROR: Expected build output '$sourceApk' does not exist." -ForegroundColor Red
    exit 1
}

$sourceItem = Get-Item $sourceApk
if ($sourceItem.Length -le 0) {
    Write-Host "ERROR: Source APK '$sourceApk' is empty (0 bytes)." -ForegroundColor Red
    exit 1
}

$sourceHash = (Get-FileHash -Path $sourceApk -Algorithm SHA256).Hash
$sourceMb = [Math]::Round($sourceItem.Length / 1MB, 2)
Write-Host "Source APK Path   : $sourceApk"
Write-Host "Source File Size  : $($sourceItem.Length) bytes ($sourceMb MB)"
Write-Host "Source SHA-256    : $sourceHash"
Write-Host "[PASS] Source artifact is valid and non-empty.`n" -ForegroundColor Green

# 7. Staged Copy to Temporary File
Write-Host "[STAGING] Copying artifact to temporary file: $tempApk..." -ForegroundColor Yellow
if (Test-Path $tempApk) {
    Remove-Item -Path $tempApk -Force
}

Copy-Item -Path $sourceApk -Destination $tempApk -Force

$tempItem = Get-Item $tempApk
$tempHash = (Get-FileHash -Path $tempApk -Algorithm SHA256).Hash

if ($tempItem.Length -ne $sourceItem.Length) {
    Remove-Item -Path $tempApk -Force -ErrorAction SilentlyContinue
    Write-Host "ERROR: Staged temporary file size does not match source. Aborting." -ForegroundColor Red
    exit 1
}

if ($tempHash -ne $sourceHash) {
    Remove-Item -Path $tempApk -Force -ErrorAction SilentlyContinue
    Write-Host "ERROR: Staged temporary file hash does not match source. Aborting." -ForegroundColor Red
    exit 1
}
Write-Host "[PASS] Staged temporary file integrity verified.`n" -ForegroundColor Green

# 8. Atomic Publication
Write-Host "[PUBLISH] Atomically replacing target: $targetApk..." -ForegroundColor Yellow
Move-Item -Path $tempApk -Destination $targetApk -Force

# 9. Final Verification
$finalItem = Get-Item $targetApk
$finalHash = (Get-FileHash -Path $targetApk -Algorithm SHA256).Hash

if ($finalHash -ne $sourceHash -or $finalItem.Length -ne $sourceItem.Length) {
    Write-Host "CRITICAL ERROR: Published APK verification failed against source artifact!" -ForegroundColor Red
    exit 1
}
Write-Host "[PASS] Target APK publication verified.`n" -ForegroundColor Green

# 10. Audit Historical Backups (Confirm untouched)
Write-Host "[AUDIT] Checking historical backups..." -ForegroundColor Yellow
$backupNames = @(
    "DueMate-previous-working-backup.apk",
    "DueMate-V3-combined-debug.apk",
    "DueMate-V3-debug.apk"
)
foreach ($bName in $backupNames) {
    $bPath = Join-Path $apkDir $bName
    if (Test-Path $bPath) {
        $bItem = Get-Item $bPath
        Write-Host "  Preserved: $bName ($($bItem.Length) bytes)" -ForegroundColor DarkGray
    } else {
        Write-Host "  Note: Backup $bName was not found." -ForegroundColor DarkYellow
    }
}
Write-Host ""

# 11. Final Build Summary
$finalMb = [Math]::Round($finalItem.Length / 1MB, 2)
Write-Host "============================================================" -ForegroundColor Green
Write-Host " SUCCESSFUL LATEST APK DEPLOYMENT" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host "Artifact   : $targetApk"
Write-Host "File Name  : $targetApkName"
Write-Host "Size       : $($finalItem.Length) bytes ($finalMb MB)"
Write-Host "SHA-256    : $finalHash"
Write-Host "Built At   : $($finalItem.LastWriteTime)"
Write-Host "Status     : Ready for testing and QA"
Write-Host "============================================================" -ForegroundColor Green
