#!/usr/bin/env bash
# =================================================================
# 星探学院 · 本地一键启动脚本（macOS / Linux）
# 用法: cd star-explorer && bash run-local.sh
# =================================================================
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"
FLUTTER_DIR="$PROJECT_ROOT/frontend"

BOLD='\033[1m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; CYAN='\033[36m'; NC='\033[0m'
log()   { echo -e "${CYAN}→${NC} $*"; }
ok()    { echo -e "${GREEN}✓${NC} $*"; }
warn()  { echo -e "${YELLOW}!${NC} $*"; }
fail()  { echo -e "${RED}✗${NC} $*"; exit 1; }

echo -e "${BOLD}🚀 星探学院 · 本地启动${NC}\n"

# ---- 1. adb reverse ----
if command -v adb &>/dev/null; then
  DEVICES=$(adb devices 2>/dev/null | tail -n +2 | grep -v 'device$' | wc -l)
  if [ "$DEVICES" -gt 0 ]; then
    DEVICE_LINE=$(adb devices 2>/dev/null | tail -n +2 | grep "device$")
    ok "检测到设备: $DEVICE_LINE"
    adb reverse tcp:3001 tcp:3001 2>/dev/null && ok "adb reverse tcp:3001 tcp:3001 ✓"
  else
    DEVICE_COUNT=$(adb devices 2>/dev/null | tail -n +2 | grep "device$" | wc -l)
    if [ "$DEVICE_COUNT" -gt 0 ]; then
      ok "设备已就绪"
      adb reverse tcp:3001 tcp:3001 2>/dev/null && ok "adb reverse 端口转发成功"
    else
      warn "未检测到 Android 设备 — 请 USB 连接手机并开启「开发者选项 → USB 调试」"
      warn "继续用同 WiFi 直连方案 (api_client.dart 需把 realDevice 改成你电脑 IP)"
    fi
  fi
else
  warn "未检测到 adb — 请先装 Android Studio 或 platform-tools"
fi

# ---- 2. 清理旧进程 ----
for port in 3001 8080; do
  if lsof -ti:"$port" 2>/dev/null; then
    log "端口 $port 被占用，清理旧进程..."
    kill "$(lsof -ti:"$port")" 2>/dev/null || true
    sleep 1
  fi
done

# ---- 3. 启动后端（后台）----
log "启动后端 API (0.0.0.0:3001)..."
cd "$BACKEND_DIR"
nohup node src/server.js > /tmp/star-backend.log 2>&1 &
BACKEND_PID=$!
sleep 2

# 后端健康检查
if curl -s --max-time 3 http://localhost:3001/api/health >/dev/null 2>&1; then
  ok "后端 API 就绪 (PID $BACKEND_PID)"
else
  fail "后端启动失败，查看 /tmp/star-backend.log"
fi

# ---- 4. 启动 fullstack server（Flutter UI + API 代理）----
log "启动 Flutter UI + API 代理 (0.0.0.0:8080)..."
cd "$BACKEND_DIR"
nohup node serve-web.js > /tmp/star-web.log 2>&1 &
WEB_PID=$!
sleep 2

if curl -s --max-time 3 -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null | grep -q "200"; then
  ok "Flutter UI 就绪 (PID $WEB_PID)"
else
  warn "Flutter UI 端口 8080 可能被占用，检查 /tmp/star-web.log"
fi

# ---- 5. Flutter SDK ----
if command -v flutter &>/dev/null; then
  echo ""
  log "Flutter 可用 — 现在可以:"
  echo "   cd $FLUTTER_DIR && flutter run             # 真机/模拟器"
  echo "   cd $FLUTTER_DIR && flutter run -d chrome   # 浏览器预览"
else
  warn "Flutter SDK 未在 PATH"
  echo "   安装: https://docs.flutter.dev/get-started/install"
fi

# ---- 6. 最终摘要 ----
LAN_IP=$(ifconfig 2>/dev/null | awk '/inet / && $2 != "127.0.0.1" {print $2; exit}' || hostname -I 2>/dev/null | awk '{print $1}')
echo ""
echo -e "${BOLD}════════════════════════════════════════════${NC}"
echo -e "${BOLD}  🎯 访问方式${NC}"
echo -e "   Web 预览    ${GREEN}http://localhost:8080${NC}"
echo -e "   API 直接    ${GREEN}http://localhost:3001/api${NC}"
[ -n "$LAN_IP" ] && echo -e "   局域网      ${GREEN}http://${LAN_IP}:8080${NC}"
echo -e ""
echo -e "${BOLD}  🧪 测试账号${NC}"
echo -e "   👦 孩子端   child@demo.com / 123456"
echo -e "   👨‍👩‍👧 家长端   parent@demo.com / 123456"
echo -e ""
echo -e "${BOLD}  🛠️ 日志${NC}"
echo -e "   后端 /tmp/star-backend.log"
echo -e "   UI   /tmp/star-web.log"
echo -e ""
echo -e "${BOLD}  🛑 停止${NC}"
echo -e "   kill $BACKEND_PID $WEB_PID"
echo -e "${BOLD}════════════════════════════════════════════${NC}"
