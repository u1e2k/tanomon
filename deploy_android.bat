@echo off
setlocal enabledelayedexpansion

echo ======================================================
echo   Tanomon 3D - Android One-Shot Deploy Script
echo   Target Device: Google Pixel 9a / Android
echo ======================================================

set PACKAGE_NAME=com.tanomon.game
set ACTIVITY_NAME=com.godot.game.GodotApp
set OUTPUT_DIR=build\android
set APK_PATH=%OUTPUT_DIR%\tanomon.apk

:: 1. ADB デバイスの確認
echo [1/4] Checking connected Android devices via ADB...
adb devices
if %ERRORLEVEL% neq 0 (
    echo [ERROR] ADB command failed. Please ensure Android SDK platform-tools is added to PATH.
    pause
    exit /b 1
)

:: 2. 出力フォルダ準備
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

:: 3. Godot ヘッドレスエクスポート
echo [2/4] Exporting Android APK via Godot...
where godot >nul 2>nul
if %ERRORLEVEL% equ 0 (
    godot --headless --export-debug "Android" "%APK_PATH%"
) else (
    echo [INFO] 'godot' command not in PATH. If you exported via Godot Editor, checking existing APK...
)

if not exist "%APK_PATH%" (
    echo [ERROR] APK not found at %APK_PATH%.
    echo Please export APK from Godot Editor or add godot.exe to PATH.
    pause
    exit /b 1
)

:: 4. ADB インストール
echo [3/4] Installing APK to Android device (%APK_PATH%)...
adb install -r -d "%APK_PATH%"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] ADB installation failed. Check device authorization or USB debugging settings.
    pause
    exit /b 1
)

:: 5. アプリ起動
echo [4/4] Launching %PACKAGE_NAME% on device...
adb shell monkey -p %PACKAGE_NAME% -c android.intent.category.LAUNCHER 1

echo ======================================================
echo   Deploy Complete! Running on Pixel 9a.
echo ======================================================
pause
