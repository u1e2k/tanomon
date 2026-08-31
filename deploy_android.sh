#!/usr/bin/env bash
set -e

echo "======================================================"
echo "  Tanomon 3D - Android One-Shot Deploy Script"
echo "  Target Device: Google Pixel 9a / Android"
echo "======================================================"

PACKAGE_NAME="com.tanomon.game"
ACTIVITY_NAME="com.godot.game.GodotApp"
OUTPUT_DIR="build/android"
APK_PATH="${OUTPUT_DIR}/tanomon.apk"

# 1. ADB デバイス確認
echo "[1/4] Checking connected Android devices..."
adb devices

# 2. ディレクトリ準備
mkdir -p "${OUTPUT_DIR}"

# 3. エクスポート
echo "[2/4] Exporting Android APK via Godot..."
if command -v godot &> /dev/null; then
    godot --headless --export-debug "Android" "${APK_PATH}"
else
    echo "[INFO] 'godot' not found in PATH. Checking existing APK..."
fi

if [ ! -f "${APK_PATH}" ]; then
    echo "[ERROR] APK not found at ${APK_PATH}. Please export APK or ensure godot is in PATH."
    exit 1
fi

# 4. インストール
echo "[3/4] Installing APK (${APK_PATH})..."
adb install -r -d "${APK_PATH}"

# 5. 起動
echo "[4/4] Launching ${PACKAGE_NAME}..."
adb shell am start -n "${PACKAGE_NAME}/${ACTIVITY_NAME}"

echo "======================================================"
echo "  Deploy Complete! Running on Pixel 9a."
echo "======================================================"
