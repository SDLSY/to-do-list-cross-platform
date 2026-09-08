@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo === 正在准备 Windows 客户端环境 ===
if not exist "windows" (
    echo 初始化 Windows 平台工程结构...
    flutter create --platforms=windows .
)

echo 正在获取依赖并启动 Windows 桌面端...
call flutter pub get
call flutter run -d windows
pause
