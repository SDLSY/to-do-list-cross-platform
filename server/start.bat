@echo off
chcp 65001 >nul
cd /d "%~dp0"

set PORT=8090
if not "%~1"=="" set PORT=%~1
set PB_VERSION=0.40.3

if not exist "pocketbase.exe" (
    echo 未检测到 pocketbase.exe，正在自动下载 (v%PB_VERSION%)...
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/pocketbase/pocketbase/releases/download/v%PB_VERSION%/pocketbase_%PB_VERSION%_windows_amd64.zip' -OutFile 'pb_temp.zip'; Expand-Archive -Path 'pb_temp.zip' -DestinationPath '.' -Force; Remove-Item 'pb_temp.zip'"
    echo 下载完成！
)

echo ==================================================
echo   🚀 PocketBase 跨平台待办同步服务 (Windows)
echo   端口:        %PORT% (监听 0.0.0.0)
echo   Web 看板:    http://127.0.0.1:%PORT%/
echo   数据管理台:  http://127.0.0.1:%PORT/_/
echo   API 入口:    http://127.0.0.1:%PORT/api/
echo ==================================================

pocketbase.exe migrate up
pocketbase.exe serve --http="0.0.0.0:%PORT%"
pause
