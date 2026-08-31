# Tanomon 3D - Android One-Shot Deploy PowerShell Script
# Target Device: Google Pixel 9a

$PackageName = "com.tanomon.game"
$ActivityName = "com.godot.game.GodotApp"
$OutputDir = "build/android"
$ApkPath = "$OutputDir/tanomon.apk"

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "  Tanomon 3D - Android Deploy for Pixel 9a" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

# 1. ADB確認
Write-Host "[1/4] Checking ADB Devices..." -ForegroundColor Yellow
adb devices

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] ADB command failed. Check Android SDK installation." -ForegroundColor Red
    exit 1
}

# 2. フォルダ作成
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

# 3. エクスポート
Write-Host "[2/4] Exporting Android APK..." -ForegroundColor Yellow
if (Get-Command godot -ErrorAction SilentlyContinue) {
    godot --headless --export-debug "Android" $ApkPath
} else {
    Write-Host "[INFO] 'godot' command not in PATH. Checking for existing APK..." -ForegroundColor Gray
}

if (-not (Test-Path $ApkPath)) {
    Write-Host "[ERROR] APK not found at $ApkPath" -ForegroundColor Red
    Write-Host "Please export from Godot Editor: Project -> Export -> Android -> Export Project" -ForegroundColor Red
    exit 1
}

# 4. ADB インストール
Write-Host "[3/4] Installing APK to Pixel 9a..." -ForegroundColor Yellow
adb install -r -d $ApkPath

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Installation failed. Ensure USB debugging is enabled on Pixel 9a." -ForegroundColor Red
    exit 1
}

# 5. アプリ起動
Write-Host "[4/4] Starting App on Pixel 9a..." -ForegroundColor Green
adb shell monkey -p $PackageName -c android.intent.category.LAUNCHER 1

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "  Successfully Deployed to Pixel 9a!" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Cyan
