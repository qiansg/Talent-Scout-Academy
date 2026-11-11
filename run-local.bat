@echo off
REM =================================================================
REM 星探学院 · 本地一键启动脚本（Windows）
REM 目录结构: 仓库根\backend + 仓库根\frontend
REM 用法: 双击运行 或 cmd 里 cd 到仓库根后 run-local.bat
REM =================================================================
setlocal enabledelayedexpansion

for /f "delims=" %%i in ("%~dp0.") do set "PROJECT_ROOT=%%~fi"
set "BACKEND_DIR=%PROJECT_ROOT%\backend"
set "FRONTEND_DIR=%PROJECT_ROOT%\frontend"

echo.
echo [0/6] 检查依赖 ...
where node >nul 2>&1
if not %ERRORLEVEL%==0 (
  echo       [!] 未安装 Node.js，请先安装 https://nodejs.org
  pause
  exit /b 1
)
if not exist "%BACKEND_DIR%\node_modules" (
  echo       安装后端依赖 npm install ...
  pushd "%BACKEND_DIR%"
  call npm install
  popd
) else (
  echo       后端依赖已存在
)

echo.
echo [1/6] adb reverse ...
where adb >nul 2>&1
if %ERRORLEVEL%==0 (
  adb devices 2>nul | findstr /r "device$" >nul
  if !ERRORLEVEL!==0 (
    adb reverse tcp:3001 tcp:3001
    echo       端口转发 tcp:3001 完成
  ) else (
    echo       未检测到设备 — 请 USB 连手机并开启 USB 调试
  )
) else (
  echo       adb 不在 PATH — 跳过
)

echo.
echo [2/6] 清理端口占用 ...
for %%p in (3001 8080) do (
  for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%%p " ^| findstr LISTENING') do (
    echo       Kill PID %%a on port %%p
    taskkill /F /PID %%a >nul 2>&1
  )
)
timeout /t 1 /nobreak >nul

echo.
echo [3/6] 启动后端 API (0.0.0.0:3001) ...
start "star-backend" /MIN cmd /c "cd /d "%BACKEND_DIR%" && node src/server.js"
timeout /t 3 /nobreak >nul
curl -s http://localhost:3001/api/health >nul 2>&1 && echo       后端就绪 || echo       后端可能未启动

echo.
echo [4/6] 检查 Flutter Web 构建产物 ...
if exist "%FRONTEND_DIR%\build\web\index.html" (
  echo       已存在 build\web
) else (
  echo       未找到 build\web — Web 预览 (8080) 不可用
  echo       需要时执行: cd frontend ^&^& flutter build web
)

echo.
echo [5/6] 启动 Flutter UI + API 代理 (0.0.0.0:8080) ...
if exist "%FRONTEND_DIR%\build\web\index.html" (
  start "star-web" /MIN cmd /c "cd /d "%BACKEND_DIR%" && node serve-web.js"
  timeout /t 2 /nobreak >nul
  curl -s -o nul -w "%%{http_code}" http://localhost:8080 | findstr "200" >nul 2>&1 && echo       UI 就绪 || echo       UI 未就绪，查看窗口日志
) else (
  echo       跳过（缺 build\web，直接用 flutter run）
)

echo.
echo [6/6] 完成
echo.
echo =====================================================
echo   🚀 星探学院
echo   API         http://localhost:3001/api
echo   Web 预览    http://localhost:8080  (需先 flutter build web)
echo   测试账号    child@demo.com / 123456
echo               parent@demo.com / 123456
echo.
echo   真机运行:
echo     cd frontend
echo     flutter pub get
echo     flutter run
echo.
echo   停止: taskkill /F /IM node.exe
echo =====================================================
echo.
pause
endlocal
