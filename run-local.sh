#!/usr/bin/env bash
# =================================================================
# 星探学院 · 本地一键启动脚本（macOS / Linux）
# 目录结构: 仓库根/backend + 仓库根/frontend
# 用法: cd <仓库根> && bash run-local.sh
# =================================================================
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"
FRONTEND_DIR="$PROJECT_ROOT/frontend"

BOLD='\033[1m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; CYAN='\033[36m'; NC='\033[0m'
log()  { echo -e "${CYAN}→${NC} $*"; }
ok()   { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
fail() { echo -e "${RED}✗${NC} $*"; exit 1; }

echo -e "${BOLD}🚀 星探学院 · 本地启动${NC}\n"

# ---- 0. 依赖检查 ----
command -v node >/dev/null 2>&1 || fail "未安装 Node.js — https://nodejs.org"
if [ ! -d "$BACKEND_DIR/node_modules" ]; then
  log "安装后端依赖 (npm install)..."
  (cd "$BACKEND_DIR" && npm install)
  ok "后端依赖安装完成"
else
  ok "后端依赖已存在"
fi

# ---- 1. adb reverse ----
if command -v adb >/dev/null 2>&1; then
  if adb devices 2>/dev/null | tail -n +2 | grep -q "device$"; then
    ok "检测到 Android 设备"
    adb reverse tcp:3001 tcp:3001 2>/dev/null && ok "adb reverse tcp:3001 完成"
  else
    warn "未检测到 Android 设备 — USB 连手机并开启「USB 调试」"
    warn "或改用同 WiFi 直连（见 frontend/lib/services/api_client.dart）"
  fi
else
  warn "未检测到 adb — 请安装 Android Studio 或 platform-tools"
fi

# ---- 2. 清理旧进程 ----
for port in 3001 8080; do
  PID=$(lsof -ti:"$port" 2>/dev/null || true)
  if [ -n "$PID" ]; then
    log "端口 $port 被占用，清理旧进程 $PID ..."
    kill $PID 2>/dev/null || true
    sleep 1
  fi
done

# ---- 3. 启动后端 ----
log "启动后端 API (0.0.0.0:3001)..."
(cd "$BACKEND_DIR" && nohup node src/server.js > /tmp/star-backend.log 2>&1 &)
sleep 2
if curl -s --max-time 3 http://localhost:3001/api/health >/dev/null 2>&1; then
  ok "后端 API 就绪"
else
  fail "后端启动失败，查看 /tmp/star-backend.log"
fi

# ---- 4. Flutter Web 构建产物检查 ----
WEB_BUILD="$FRONTEND_DIR/build/web"
HAVE_WEB=0
if [ -f "$WEB_BUILD/index.html" ]; then
  ok "Flutter Web 构建产物已就绪"
  HAVE_WEB=1
else
  warn "未找到 frontend/build/web — 8080 预览不可用"
  warn "需要浏览时执行: cd frontend && flutter build web"
fi

# ---- 5. 启动 fullstack server ----
if [ "$HAVE_WEB" = "1" ]; then
  log "启动 Flutter UI + API 代理 (0.0.0.0:8080)..."
  (cd "$BACKEND_DIR" && nohup node serve-web.js > /tmp/star-web.log 2>&1 &)
  sleep 2
  if curl -s --max-time 3 -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null | grep -q "200"; then
    ok "Flutter UI 就绪"
  else
    warn "8080 启动异常，检查 /tmp/star-web.log"
  fi
fi

# ---- 6. 摘要 ----
LAN_IP=$( (ifconfig 2>/dev/null | awk '/inet / && $2 != "127.0.0.1" {print $2; exit}') || (hostname -I 2>/dev/null | awk '{print $1}') )
echo ""
echo -e "${BOLD}════════════════════════════════════════════${NC}"
echo -e "${BOLD}  🎯 访问${NC}"
[ "$HAVE_WEB" = "1" ] && echo -e "   Web 预览    ${GREEN}http://localhost:8080${NC}"
echo -e "   API 直接    ${GREEN}http://localhost:3001/api${NC}"
[ -n "$LAN_IP" ] && echo -e "   局域网      ${GREEN}http://${LAN_IP}:3001/api${NC}"
echo -e ""
echo -e "${BOLD}  📱 Flutter 运行${NC}"
echo -e "   cd $FRONTEND_DIR"
echo -e "   flutter pub get && flutter run"
echo -e ""
echo -e "${BOLD}  🧪 测试账号${NC}"
echo -e "   👦 孩子端   child@demo.com / 123456"
echo -e "   👨‍👩‍👧 家长端   parent@demo.com / 123456"
echo -e ""
echo -e "${BOLD}  🛑 停止${NC}"
echo -e "   pkill -f 'node src/server.js'; pkill -f 'node serve-web.js'"
echo -e "${BOLD}════════════════════════════════════════════${NC}"
