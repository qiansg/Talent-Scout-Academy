// ============================================================
// 星探学院 FullStack Server
// 同时 serve Flutter Web UI + 代理 /api/* → 后端 3001
// ============================================================
const express = require('express');
const cors = require('cors');
const path = require('path');
const http = require('http');

const FLUTTER_DIR = '/workspace/star-explorer-flutter/build/web';
const BACKEND_HOST = process.env.BACKEND_HOST || '127.0.0.1';
const BACKEND_PORT = process.env.BACKEND_PORT || 3001;
const PORT = process.env.PORT || 8080;

const app = express();
app.use(cors());

// ============ API 反向代理（必须在 express.json() 之前！）============
// express.json() 会消费 POST body，导致代理的 req.pipe() 空了
app.use('/api', (req, res) => {
  const backendPath = '/api' + req.url;
  const options = {
    hostname: BACKEND_HOST,
    port: BACKEND_PORT,
    path: backendPath,
    method: req.method,
    headers: { ...req.headers, host: `${BACKEND_HOST}:${BACKEND_PORT}` },
  };

  const proxyReq = http.request(options, (proxyRes) => {
    const headers = { ...proxyRes.headers, 'Access-Control-Allow-Origin': '*' };
    res.writeHead(proxyRes.statusCode, headers);
    proxyRes.pipe(res);
  });

  proxyReq.on('error', (e) => {
    console.error('🔴 代理失败:', e.message, '→', backendPath);
    res.status(502).json({ error: '后端服务不可用', detail: e.message });
  });

  req.pipe(proxyReq);
});

// json 解析留给其他路由（代理路由不会走到这里了）
app.use(express.json({ limit: '10mb' }));

// ============ Flutter 静态页 ============
app.use(express.static(FLUTTER_DIR, { maxAge: '1h' }));
app.use((req, res) => {
  const indexPath = path.join(FLUTTER_DIR, 'index.html');
  if (require('fs').existsSync(indexPath)) {
    res.sendFile(indexPath);
  } else {
    res.status(404).send('Flutter build not found. Run: flutter build web');
  }
});

// ============ 启动 ============
app.listen(PORT, '0.0.0.0', () => {
  console.log('\n🚀 Star Explorer FullStack Server');
  console.log('  📱 Flutter UI:   http://0.0.0.0:' + PORT);
  console.log('  🔗 API 代理:     http://0.0.0.0:' + PORT + '/api/* → ' + BACKEND_HOST + ':' + BACKEND_PORT);
  console.log('  🧪 后端健康:     http://localhost:' + BACKEND_PORT + '/api/health\n');
});
