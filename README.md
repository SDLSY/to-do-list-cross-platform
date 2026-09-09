# 跨平台三端同步待办与看板 (Linux · Windows · Android)

一个基于 **Flutter** + **PocketBase** 构建的现代个人待办与看板系统。支持在 **Linux**、**Windows** 和 **Android** 三端无缝流转，具备本地毫秒级响应、SSE 实时同步推送、看板拖拽、状态快速推进以及双视图切换。

---

## 🏗️ 架构概览

```
  ┌─────────────────────────────────────────────────────────────┐
  │                 PocketBase 后端 (Go + SQLite)                │
  │     • RESTful API (增删改查)                                  │
  │     • SSE 实时推送流 (pb.collection('todos').subscribe)      │
  │     • Web 控制台 (http://127.0.0.1:8090/_/)                  │
  └──────────────────────────────▲──────────────────────────────┘
                                 │ 实时数据流 (SSE / HTTP)
       ┌─────────────────────────┼─────────────────────────┐
       ▼                         ▼                         ▼
┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│  Linux 桌面端 │         │ Windows 桌面端│         │  Android 移动端│
│ (Flutter GTK)│         │ (Flutter Win)│         │ (Flutter APK)│
└──────────────┘         └──────────────┘         └──────────────┘
```

- **数据模型**：任务（标题、备注、待办/进行中/已完成、三级优先级、排序权重、截止日期）。
- **同步机制**：UI 乐观更新（操作瞬间响应无需等待网络） + PocketBase 实时广播推送（多端自动刷新，无需轮询）。
- **开箱即用 Web 看板**：服务端直接内置轻量 Web 看板，浏览器访问即可体验。

---

## 📂 仓库目录结构

```text
to_list_linux_windows_android/
├── server/                          # 后端服务
│   ├── start.sh                     # Linux/macOS 一键启动脚本 (自动下载 PocketBase)
│   ├── start.bat                    # Windows 一键启动脚本 (自动下载 PocketBase)
│   ├── stop.sh                      # 停止后端进程脚本
│   ├── pb_migrations/               # 自动迁移脚本 (预设表结构与初始种子数据)
│   └── pb_public/                   # 开箱即用的响应式 Web 拖拽看板
│
├── client/                          # Flutter 跨平台客户端
│   ├── lib/
│   │   ├── models/todo.dart         # 数据模型
│   │   ├── services/                # PocketBase 客户端封装与 SSE 订阅
│   │   ├── providers/               # 状态管理与实时同步
│   │   ├── views/
│   │   │   ├── kanban/              # 3 泳道拖拽看板 (待办 / 进行中 / 已完成)
│   │   │   ├── list/                # 紧凑清单列表 (支持状态筛选、勾选)
│   │   │   └── widgets/             # 卡片、弹窗与设置组件
│   │   └── main.dart                # 应用入口与 Material 3 主题
│   ├── run_linux.sh                 # Linux 客户端一键启动脚本
│   ├── run_windows.bat              # Windows 客户端一键启动脚本
│   ├── run_android.sh               # Android 客户端一键启动脚本
│   └── pubspec.yaml                 # 客户端依赖
│
└── README.md
```

---

## 🖥️ 1. 服务端部署与启动

后端服务负责存储数据并进行三端消息广播，**无需预装 Go、Node、Docker 或数据库**，单可执行文件直接跑。

### Linux 环境启动
```bash
cd server
chmod +x start.sh
./start.sh
```
*(脚本会自动根据当前系统架构下载官方最新 PocketBase 二进制并执行迁移)*

### Windows 环境启动
双击 `server\start.bat`，或在 CMD/PowerShell 运行：
```cmd
cd server
start.bat
```

启动后终端将展示以下地址：
- **Web 看板入口**：`http://127.0.0.1:8090/`
- **数据管理控制台**：`http://127.0.0.1:8090/_/` （可在此可视化查阅或维护所有数据）
- **API 入口**：`http://127.0.0.1:8090/api/`

---

## 🚀 2. 客户端三端启动与配置指南

客户端基于 Flutter 开发。在运行前，请确保本地已安装 [Flutter SDK](https://flutter.dev/docs/get-started/install)（推荐 3.10 及以上）。

### 平台一：Linux 桌面端

#### 1. 系统依赖安装 (Ubuntu/Debian 为例)
```bash
sudo apt update
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
```

#### 2. 启动客户端
方式 A（使用封装脚本）：
```bash
cd client
./run_linux.sh
```

方式 B（手动启动）：
```bash
cd client
flutter create --platforms=linux .
flutter pub get
flutter run -d linux
```

#### 3. 配置连接
- Linux 客户端默认连接本地 `http://127.0.0.1:8090`。
- 若后端运行在远程服务器或另一台机器，点击右上角 **☁️ 同步设置**，输入服务器地址（如 `http://192.168.1.50:8090`），点击**“测试并保存”**。

---

### 平台二：Windows 桌面端

#### 1. 系统依赖准备
- 安装 Visual Studio 2022（需勾选 **“使用 C++ 的桌面开发”** 工作负载）。

#### 2. 启动客户端
方式 A（使用封装脚本）：
双击 `client\run_windows.bat`。

方式 B（手动启动）：
```cmd
cd client
flutter create --platforms=windows .
flutter pub get
flutter run -d windows
```

#### 3. 配置连接
- Windows 客户端启动后会自动连接 `http://127.0.0.1:8090`。
- 如果服务端在另一台电脑，点击右上角 **☁️ 同步设置** 修改对应 IP 即可。

---

### 平台三：Android 移动端

#### 1. 环境准备
- 开启 Android 手机的 **“开发者选项”** 并启用 **“USB 调试”**；
- 用数据线将手机连接至电脑（或启动 Android Studio 模拟器）。

#### 2. 启动或打包
方式 A（实时调试运行）：
```bash
cd client
./run_android.sh
# 或者手动:
flutter create --platforms=android .
flutter pub get
flutter run -d android
```

方式 B（打包为独立 APK 安装包）：
```bash
cd client
chmod +x build_apk.sh
./build_apk.sh
# 或者手动:
flutter build apk --release
```
打包完成后自动输出安装包至：`release/todo-taskflow-android-release.apk` (或 `client/build/app/outputs/flutter-apk/app-release.apk`)，可直接通过微信/QQ/数据线传到手机上安装。

#### 3. Android 端局域网配对与网络配置（关键）
> **注意**：由于 Android 手机是独立设备，不能直接访问 `127.0.0.1`，需连接运行后端的电脑局域网 IP。

1. 确保手机和运行 PocketBase 的电脑连接在**同一个 Wi-Fi（局域网）**下；
2. 获取电脑在局域网中的 IPv4 地址：
   - Linux: `ip addr show | grep 'inet '`
   - Windows: `ipconfig` (查看“无线局域网适配器 WLAN”的 IPv4 地址，例如 `192.168.1.108`)
3. 打开 Android 客户端，点击右上角 **☁️ 同步设置** 图标；
4. 将地址修改为电脑的局域网 IP + 端口：
   ```text
   http://192.168.1.108:8090
   ```
5. 点击**“测试并保存”**，状态变绿显示 `✅ 连接服务器成功！`，完成配对。

> **已内置配置说明**：项目在 `android/app/src/main/AndroidManifest.xml` 中已经预置了网络权限 `<uses-permission android:name="android.permission.INTERNET"/>` 和 `android:usesCleartextTraffic="true"`，允许局域网内的 HTTP 明文传输，无需额外配置证书。

---

## ⚡ 3. 验证三端实时同步

想要验证三端实时推送效果，无需繁琐准备：

1. 启动后端（`cd server && ./start.sh`）；
2. 在电脑浏览器打开 `http://127.0.0.1:8090/`（内置 Web 看板）；
3. 在手机（或另一个终端/另一台电脑）上运行客户端；
4. 在任意一端做以下任一操作：
   - 拖拽某张任务卡片到另一列；
   - 点击卡片上的 **“▶ 开始”** 或 **“✓ 完成”**；
   - 新建或删除一个任务；
5. **无需手动刷新，另一端将在几毫秒内自动响应并平滑更新画面！**

---

## ❓ 常见问题排查 (FAQ)

### Q1: 手机客户端提示“无法连接服务器”？
- **原因 1**：手机与电脑未在同一 Wi-Fi，或者路由器开启了“AP 隔离”。
- **原因 2**：电脑系统防火墙阻拦了 8090 端口。
  - Linux: 检查 `sudo ufw status`，可临时放行 `sudo ufw allow 8090`。
  - Windows: 检查 Windows Defender 防火墙，确保允许应用通过 8090 端口通信。
- **原因 3**：在 Android 模拟器运行时，访问本机的特殊回环 IP 应填写 `http://10.0.2.2:8090`。

### Q2: 如何重置或备份数据？
所有数据、表结构及配置均保存在 `server/pb_data/` 目录下：
- **备份**：直接复制 `server/pb_data` 文件夹到任意位置即可完成完整备份。
- **重置**：关闭后端服务，删除 `server/pb_data` 文件夹，重新运行 `./start.sh` 即可恢复初始状态。
