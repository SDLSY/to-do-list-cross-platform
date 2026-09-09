#!/usr/bin/env bash
set -e

echo "=================================================="
echo "  🚀 正在为阿里云服务器一键部署复古待办看板服务"
echo "=================================================="

WORK_DIR="/opt/todo-sync-server"
PB_VERSION="0.40.3"
PORT=8090

# 1. 创建部署目录
echo "1. 准备运行目录: $WORK_DIR ..."
sudo mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# 2. 安装必要工具
if command -v apt-get &> /dev/null; then
    sudo apt-get update -y > /dev/null 2>&1 || true
    sudo apt-get install -y curl unzip git > /dev/null 2>&1 || true
elif command -v yum &> /dev/null; then
    sudo yum install -y curl unzip git > /dev/null 2>&1 || true
fi

# 3. 下载 PocketBase 二进制
if [ ! -f "./pocketbase" ]; then
    echo "2. 正在下载 PocketBase (v${PB_VERSION})..."
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64) PB_ARCH="amd64" ;;
        aarch64|arm64) PB_ARCH="arm64" ;;
        *) echo "未知架构: $ARCH"; exit 1 ;;
    esac
    DOWNLOAD_URL="https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_${PB_ARCH}.zip"
    curl -L -o pb_temp.zip "$DOWNLOAD_URL"
    unzip -o pb_temp.zip pocketbase
    rm pb_temp.zip
    chmod +x ./pocketbase
fi

# 4. 拉取最新的 Web 看板前端与数据迁移结构
echo "3. 正在同步最新复古看板前端与数据迁移规则..."
TEMP_REPO="/tmp/todo_repo_temp"
rm -rf "$TEMP_REPO"
git clone --depth 1 https://github.com/SDLSY/to-do-list-cross-platform.git "$TEMP_REPO"

rm -rf "$WORK_DIR/pb_public" "$WORK_DIR/pb_migrations"
cp -r "$TEMP_REPO/server/pb_public" "$WORK_DIR/"
cp -r "$TEMP_REPO/server/pb_migrations" "$WORK_DIR/"
rm -rf "$TEMP_REPO"

# 5. 执行数据迁移
echo "4. 应用数据表迁移与初始数据..."
./pocketbase migrate up

# 6. 配置 systemd 系统服务 (开机自启与后台常驻)
echo "5. 注册 systemd 系统常驻自启服务..."
SERVICE_FILE="/etc/systemd/system/todoboard.service"
sudo bash -c "cat <<EOF > $SERVICE_FILE
[Unit]
Description=Retro Kanban Todo PocketBase Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$WORK_DIR
ExecStart=$WORK_DIR/pocketbase serve --http=0.0.0.0:$PORT
Restart=always
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF"

sudo systemctl daemon-reload
sudo systemctl enable --now todoboard
sudo systemctl restart todoboard

echo "=================================================="
echo "  🎉 部署成功！待办看板已在后台常驻运行。"
echo "  Web 看板入口: http://47.116.20.106:$PORT/"
echo "  数据管理后台: http://47.116.20.106:$PORT/_/"
echo "  服务状态查看: systemctl status todoboard"
echo "=================================================="
