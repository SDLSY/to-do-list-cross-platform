#!/usr/bin/env bash
echo "正在停止 PocketBase 服务..."
pkill -f "pocketbase serve" || true
echo "已停止。"
