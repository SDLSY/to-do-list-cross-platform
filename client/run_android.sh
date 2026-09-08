#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "=== 正在准备 Android 客户端环境 ==="
if [ ! -d "android/app" ]; then
    echo "初始化 Android 平台工程结构..."
    flutter create --platforms=android .
fi

echo "正在检测已连接的 Android 设备 / 模拟器..."
flutter devices

echo "正在获取依赖并启动 Android 应用..."
flutter pub get
exec flutter run -d android
