@echo off
REM =================================================================
REM 星探学院 · 本地一键启动脚本（Windows）
REM 用法: 双击运行 或 cmd 里 cd 到目录后 run-local.bat
REM =================================================================
setlocal enabledelayedexpansion

for /f "delims=" %%i in ("%~dp0.") do set "PROJECT_ROOT=%%~fi"
set "BACKEND_DIR=%PROJECT_ROOT%\star-explorer\backend"
set "FLUTTER_DIR=%PROJECT_ROOT%\frontend"

echo.
echo [1/5] adb reverse ...
where adb >nul 2>&1
if %ERRORLEVEL%==0 (
  for /f "skip=1 tokens=1" %%d in ('adb devices 2^>nul ^| findstr /r "device$"') do (
    echo       检测到设备 %%d
    adb reverse tcp:3001 tcp:3001
  )
) else (
  echo       adb 不在 PATH — 跳过
)

echo.
echo [2/5] 清理端口占用 ...
for %%p in (3001 8080) do (
  for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%%p " ^| findstr LISTENING') do (
    echo       Kill PID %%a on port %%p
    taskkill /F /PID %%a >nul 2>&1
  )
)
timeout /t 1 /nobreak >nul

echo.
echo [3/5] 启动后端 API (0.0.0.0:3001) ...
start "star-backend" /MIN cmd /c "cd /d "%BACKEND_DIR%" && node src/server.js"
timeout /t 3 /nobreak >nul
curl -s http://localhost:3001/api/health >nul 2>&1 && echo       后端就绪 || echo       后端可能未启动

echo.
echo [4/5] 启动 Flutter UI + API 代理 (0.0.0.0:8080) ...
start "star-web" /MIN cmd /c "cd /d "%BACKEND_DIR%" && node serve-web.js"
timeout /t 2 /nobreak >nul
curl -s -o nul -w "%%{http_code}" http://localhost:8080 | findstr "200" >nul 2>&1 && echo       UI 就绪 || echo       UI 可能未启动

echo.
echo =====================================================
echo   🚀 星探学院 · 已启动
echo   Web 预览    http://localhost:8080
echo   API 直接    http://localhost:3001/api
echo   测试账号    child@demo.com / 123456
echo.
echo   下一步:
echo     cd frontend ^&^& flutter run
echo     flutter run -d chrome
echo.
echo   停止: taskkill /F /IM node.exe
echo =====================================================
echo.
pause
endlocal
