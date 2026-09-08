#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

PORT=${1:-8090}
PB_VERSION="0.40.3"

# 检测是否已存在 pocketbase 二进制，不存在则自动下载
if [ ! -f "./pocketbase" ]; then
    echo "未检测到 PocketBase 可执行文件，正在自动下载 (v${PB_VERSION})..."
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64) PB_ARCH="amd64" ;;
        aarch64|arm64) PB_ARCH="arm64" ;;
        armv7*) PB_ARCH="armv7" ;;
        *) echo "未知架构: $ARCH"; exit 1 ;;
    esac

    DOWNLOAD_URL="https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_${PB_ARCH}.zip"
    echo "正在从 $DOWNLOAD_URL 下载..."
    curl -L -o pb_temp.zip "$DOWNLOAD_URL"
    unzip -o pb_temp.zip pocketbase
    rm pb_temp.zip
    chmod +x ./pocketbase
    echo "下载并安装完成！"
fi

echo "=================================================="
echo "  🚀 PocketBase 跨平台待办同步服务"
echo "  端口:        $PORT (监听 0.0.0.0)"
echo "  Web 看板:    http://127.0.0.1:$PORT/"
echo "  数据管理台:  http://127.0.0.1:$PORT/_/"
echo "  API 入口:    http://127.0.0.1:$PORT/api/"
echo "=================================================="

# 自动应用迁移
./pocketbase migrate up

# 启动服务
exec ./pocketbase serve --http="0.0.0.0:$PORT"
