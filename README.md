# 星探学院 Star Explorer Academy

面向小学 3-6 年级的 AI 自适应学习 App。孩子端用 Flutter（Android / iOS 一套代码），后端 Node.js + Express + SQLite。

## 目录结构

```
.
├── backend/          Node.js + Express + SQLite（端口 3001）
│   ├── src/server.js     后端入口
│   ├── src/db.js         SQLite 连接 + 建表
│   ├── src/init-db.js    种子数据（学科任务 / 徽章 / 测试账号）
│   ├── src/routes/       auth / tasks / ai-companion / parent
│   ├── serve-web.js      Flutter Web UI + /api 反向代理（端口 8080）
│   └── data/             SQLite 数据文件（首次启动自动创建）
├── frontend/         Flutter 3.24 + Riverpod + Hive
│   └── lib/
│       ├── pages/        登录 / 星图 / 学科任务 / 关卡 / AI 学伴 / 我的 / API 设置
│       ├── providers/    Riverpod 状态管理
│       └── services/     API 客户端 / 鉴权 / 任务 / AI 学伴 / Hive
├── run-local.sh      macOS / Linux 一键启动
└── run-local.bat     Windows 一键启动
```

## 前置条件

- Node.js 18+
- Flutter 3.24+（只跑后端可不需要）
- 真机调试需要 adb（Android platform-tools）

## 快速启动

### 方式一：一键脚本

```bash
# macOS / Linux
bash run-local.sh

# Windows（双击或 cmd 里执行）
run-local.bat
```

脚本会自动：安装后端依赖 → 执行 `adb reverse` → 清理 3001/8080 端口 → 启动后端 → 启动 Web 预览（若有构建产物）。

后端起来后，另开终端跑 Flutter：

```bash
cd frontend
flutter pub get
flutter run                # Android / iOS 真机
flutter run -d chrome      # 浏览器
```

### 方式二：手动

```bash
# 1. 后端
cd backend
npm install
node src/server.js         # → http://0.0.0.0:3001

# 2. Web 预览（可选，先把 Flutter Web 构建出来）
cd ../frontend && flutter pub get && flutter build web
cd ../backend && node serve-web.js   # → http://0.0.0.0:8080

# 3. Flutter 真机
cd frontend && flutter run
```

## 测试账号

| 角色 | 邮箱 | 密码 |
|---|---|---|
| 孩子端 | `child@demo.com` | `123456` |
| 家长端 | `parent@demo.com` | `123456` |

首次启动自动建库并写入种子数据；若用户表为空会自动补灌。

## 真机连接后端

`frontend/lib/services/api_client.dart` 中 `ApiConfig` 提供 5 个预设地址，`autoDetect()` 按平台自动选择：

| 场景 | 地址 | 说明 |
|---|---|---|
| Android 真机（USB） | `http://localhost:3001/api` | 需先执行 `adb reverse tcp:3001 tcp:3001` |
| 同 WiFi 直连 | `http://<你电脑的局域网IP>:3001/api` | 改 `ApiConfig.realDevice` |
| Android 模拟器 | `http://10.0.2.2:3001/api` | |
| iOS 模拟器 / 桌面 | `http://localhost:3001/api` | |
| 外网穿透 | ngrok / cloudflared 地址 | `ngrok http 3001` |

不想改代码：App 内「我的」页快速点头像 5 次 → API 设置页，可运行时切换并测试连接。

Android 已开启 `usesCleartextTraffic`，iOS 已配 ATS 白名单，本地 HTTP 可直接访问。

## API 一览

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/api/health` | 健康检查 |
| POST | `/api/auth/login` | 登录，返回 JWT |
| POST | `/api/auth/register` | 注册 |
| GET | `/api/auth/me` | 当前用户 |
| GET | `/api/subjects` | 学科列表 |
| GET | `/api/:subject/tasks` | 某学科任务列表 |
| GET | `/api/tasks/:id` | 任务详情 |
| POST | `/api/tasks/:id/complete` | 提交完成 |
| GET | `/api/badges` | 徽章列表 |
| POST | `/api/ai/chat` | AI 学伴对话 |
| GET | `/api/parent/overview` | 家长端概览 |
| GET | `/api/stats/overview` | 学习统计 |

## 常见问题

**后端启动报 `Cannot open database because the directory does not exist`**
已修复：`src/db.js` 会在打开数据库前自动创建 `data/` 目录。

**登录一直提示「邮箱或密码错误」**
确认 `backend/data/star_explorer.db` 里 users 表有数据。删掉 `data/star_explorer.db*` 后重启后端会自动重建并灌种子。

**8080 返回 404 / 提示 Flutter build not found**
仓库不含 `frontend/build/web`（构建产物）。执行 `cd frontend && flutter build web` 后重启 `serve-web.js`。

**真机连不上后端**
先确认手机与电脑同网段，或在电脑上执行 `adb reverse tcp:3001 tcp:3001` 走 USB 通道。打开 App 的 API 设置页可现场测连接。
