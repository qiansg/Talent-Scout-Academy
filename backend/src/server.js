const express = require('express');
const cors = require('cors');
const path = require('path');
const os = require('os');
require('dotenv').config();

const { db, initSchema } = require('./db');
const { seed } = require('./init-db');

const authRoutes = require('./routes/auth');
const taskRoutes = require('./routes/tasks');
const aiRoutes = require('./routes/ai-companion');
const parentRoutes = require('./routes/parent');

const app = express();
const PORT = process.env.PORT || 3001;
const HOST = process.env.HOST || '0.0.0.0';

// 中间件
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// 静态文件目录
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// 健康检查
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    service: 'Star Explorer Academy API',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

// API 路由
app.use('/api/auth', authRoutes);
app.use('/api', taskRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/parent', parentRoutes);

// 错误处理中间件
app.use((err, req, res, next) => {
  console.error('❌ API 错误:', err);
  res.status(500).json({ 
    error: '服务器内部错误',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// 404 处理
app.use((req, res) => {
  res.status(404).json({ error: '接口不存在', path: req.path });
});

// 启动服务器
async function startServer() {
  try {
    // 初始化数据库
    initSchema();
    console.log('✅ 数据库连接成功');
    
    // 种子数据：只要用户表为空就重新灌（seed 内部全部 INSERT OR REPLACE，幂等）
    const userCount = db.prepare('SELECT COUNT(*) as count FROM users').get().count;
    if (process.env.SEED_DB === 'true' || userCount === 0) {
      await seed();
    }
    
    // 显式绑定 0.0.0.0，支持真机（同 WiFi）访问
    app.listen(PORT, HOST, () => {
      // 获取局域网 IP 列表
      const interfaces = os.networkInterfaces();
      const lanIps = [];
      for (const name of Object.keys(interfaces)) {
        for (const iface of interfaces[name]) {
          if (iface.family === 'IPv4' && !iface.internal) {
            lanIps.push(iface.address);
          }
        }
      }

      console.log(`\n🚀 星探学院 API 服务已启动!`);
      console.log(`📍 监听地址: ${HOST}:${PORT}`);
      console.log(`📡 本地访问: http://localhost:${PORT}`);
      console.log(`📝 API 文档: http://localhost:${PORT}/api/health`);
      if (lanIps.length > 0) {
        console.log(`\n📶 局域网访问（真机用这个）:`);
        lanIps.forEach(ip => {
          console.log(`   → http://${ip}:${PORT}/api`);
        });
      }
      console.log(`\n🧪 测试账号:`);
      console.log(`   家长: parent@demo.com / 123456`);
      console.log(`   孩子: child@demo.com / 123456\n`);
    });
  } catch (error) {
    console.error('❌ 启动失败:', error);
    process.exit(1);
  }
}

startServer();
