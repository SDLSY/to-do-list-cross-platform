#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "=================================================="
echo "  🚀 正在构建 Android Release APK 安装包"
echo "=================================================="

# 检查 flutter 命令
if ! command -v flutter &> /dev/null; then
    echo "❌ 错误: 未检测到 Flutter SDK，请先安装 Flutter 或配置 PATH 环境变量。"
    echo "参考文档: https://docs.flutter.dev/get-started/install"
    exit 1
fi

# 初始化 Android 脚手架（如果缺失）
if [ ! -d "android/app" ]; then
    echo "正在初始化 Android 平台脚手架..."
    flutter create --platforms=android .
fi

echo "1. 获取 Flutter 依赖..."
flutter pub get

echo "2. 开始编译 Release APK..."
flutter build apk --release

OUTPUT_APK="build/app/outputs/flutter-apk/app-release.apk"

if [ -f "$OUTPUT_APK" ]; then
    RELEASE_DIR="../release"
    mkdir -p "$RELEASE_DIR"
    cp "$OUTPUT_APK" "$RELEASE_DIR/todo-taskflow-android-release.apk"
    echo "=================================================="
    echo "✅ 构建成功！"
    echo "📦 APK 原始产物路径: client/$OUTPUT_APK"
    echo "📦 发行版安装包路径: release/todo-taskflow-android-release.apk"
    echo "=================================================="
else
    echo "❌ 构建产物未找到，请检查上面的构建日志。"
    exit 1
fi
