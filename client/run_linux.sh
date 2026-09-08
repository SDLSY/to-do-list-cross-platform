#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "=== 正在准备 Linux 客户端环境 ==="
# 如果没有原生平台脚手架，自动补全
if [ ! -d "linux" ]; then
    echo "初始化 Linux 平台工程结构..."
    flutter create --platforms=linux .
fi

echo "正在获取依赖并启动 Linux 桌面端..."
flutter pub get
exec flutter run -d linux
