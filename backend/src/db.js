const Database = require('better-sqlite3');
const path = require('path');

const dbPath = path.join(__dirname, '../data/star_explorer.db');
const db = new Database(dbPath);

// 启用 WAL 模式提升并发性能
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

// 创建表结构
function initSchema() {
  db.exec(`
    -- 用户表
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      email TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      user_type TEXT NOT NULL CHECK(user_type IN ('parent', 'child')),
      nickname TEXT,
      avatar TEXT DEFAULT 'default',
      grade INTEGER,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    -- 家庭关系表
    CREATE TABLE IF NOT EXISTS family_relations (
      id TEXT PRIMARY KEY,
      parent_id TEXT NOT NULL,
      child_id TEXT NOT NULL,
      nickname TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (parent_id) REFERENCES users(id),
      FOREIGN KEY (child_id) REFERENCES users(id)
    );

    -- 任务表（学科关卡）
    CREATE TABLE IF NOT EXISTS tasks (
      id TEXT PRIMARY KEY,
      subject TEXT NOT NULL CHECK(subject IN ('math', 'chinese', 'english', 'science')),
      grade INTEGER NOT NULL,
      title TEXT NOT NULL,
      description TEXT,
      difficulty INTEGER DEFAULT 1,
      reward_coins INTEGER DEFAULT 50,
      badge_id TEXT,
      scene_data TEXT,
      sequence_num INTEGER DEFAULT 0,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    -- 任务进度表
    CREATE TABLE IF NOT EXISTS task_progress (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      task_id TEXT NOT NULL,
      status TEXT DEFAULT 'not_started' CHECK(status IN ('not_started', 'in_progress', 'completed')),
      score INTEGER DEFAULT 0,
      attempts INTEGER DEFAULT 0,
      completed_at DATETIME,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id),
      FOREIGN KEY (task_id) REFERENCES tasks(id),
      UNIQUE(user_id, task_id)
    );

    -- 勋章表
    CREATE TABLE IF NOT EXISTS badges (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT,
      icon TEXT,
      subject TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    -- 用户勋章表
    CREATE TABLE IF NOT EXISTS user_badges (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      badge_id TEXT NOT NULL,
      earned_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id),
      FOREIGN KEY (badge_id) REFERENCES badges(id)
    );

    -- 星币账户表
    CREATE TABLE IF NOT EXISTS star_coins (
      id TEXT PRIMARY KEY,
      user_id TEXT UNIQUE NOT NULL,
      balance INTEGER DEFAULT 0,
      total_earned INTEGER DEFAULT 0,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id)
    );

    -- 学习日志表
    CREATE TABLE IF NOT EXISTS learning_logs (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      task_id TEXT,
      subject TEXT,
      action TEXT,
      duration_seconds INTEGER DEFAULT 0,
      accuracy REAL DEFAULT 0,
      emotion TEXT,
      details TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id)
    );

    -- AI对话记录表
    CREATE TABLE IF NOT EXISTS ai_conversations (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      role TEXT NOT NULL CHECK(role IN ('user', 'assistant')),
      message TEXT NOT NULL,
      subject TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id)
    );

    -- 创造工坊内容表
    CREATE TABLE IF NOT EXISTS creations (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      type TEXT NOT NULL CHECK(type IN ('diary', 'comic', 'drawing')),
      title TEXT,
      content TEXT,
      cover_image TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id)
    );

    -- 家长设置表
    CREATE TABLE IF NOT EXISTS parent_settings (
      id TEXT PRIMARY KEY,
      parent_id TEXT NOT NULL,
      max_daily_minutes INTEGER DEFAULT 30,
      allowed_start_time TEXT DEFAULT '08:00',
      allowed_end_time TEXT DEFAULT '21:00',
      rest_reminder_minutes INTEGER DEFAULT 20,
      content_filter_enabled INTEGER DEFAULT 1,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (parent_id) REFERENCES users(id)
    );
  `);
}

module.exports = { db, initSchema };
