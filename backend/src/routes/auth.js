const express = require('express');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const { db } = require('../db');
const { generateToken, authenticateToken } = require('../middleware/auth');

const router = express.Router();

// 家长注册
router.post('/register/parent', async (req, res) => {
  try {
    const { email, password, nickname } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ error: '邮箱和密码不能为空' });
    }
    
    const existing = db.prepare('SELECT id FROM users WHERE email = ?').get(email);
    if (existing) {
      return res.status(409).json({ error: '该邮箱已注册' });
    }
    
    const hashedPassword = await bcrypt.hash(password, 10);
    const id = uuidv4();
    
    db.prepare(`
      INSERT INTO users (id, email, password_hash, user_type, nickname)
      VALUES (?, ?, ?, 'parent', ?)
    `).run(id, email, hashedPassword, nickname || '家长');
    
    // 创建家长设置
    db.prepare(`
      INSERT INTO parent_settings (id, parent_id)
      VALUES (?, ?)
    `).run(uuidv4(), id);
    
    const token = generateToken({ id, email, user_type: 'parent' });
    
    res.status(201).json({
      message: '注册成功',
      token,
      user: { id, email, nickname: nickname || '家长', user_type: 'parent' }
    });
  } catch (error) {
    console.error('家长注册错误:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

// 为家长添加孩子账号
router.post('/register/child', authenticateToken, async (req, res) => {
  try {
    const { nickname, grade } = req.body;
    const parentId = req.user.id;
    
    const childId = uuidv4();
    const childEmail = `child_${childId.slice(0, 8)}@star.local`;
    const hashedPassword = await bcrypt.hash('temporary123', 10);
    
    db.prepare(`
      INSERT INTO users (id, email, password_hash, user_type, nickname, grade)
      VALUES (?, ?, ?, 'child', ?, ?)
    `).run(childId, childEmail, hashedPassword, nickname || '小探险家', grade || 3);
    
    // 建立家庭关系
    db.prepare(`
      INSERT INTO family_relations (id, parent_id, child_id, nickname)
      VALUES (?, ?, ?, ?)
    `).run(uuidv4(), parentId, childId, nickname);
    
    // 创建星币账户
    db.prepare(`
      INSERT INTO star_coins (id, user_id, balance)
      VALUES (?, ?, 100)
    `).run(uuidv4(), childId);
    
    res.status(201).json({
      message: '孩子账号创建成功',
      temp_password: 'temporary123',
      child: { id: childId, email: childEmail, nickname, grade }
    });
  } catch (error) {
    console.error('添加孩子错误:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

// 登录
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ error: '邮箱和密码不能为空' });
    }
    
    const user = db.prepare('SELECT * FROM users WHERE email = ?').get(email);
    if (!user) {
      return res.status(401).json({ error: '邮箱或密码错误' });
    }
    
    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
      return res.status(401).json({ error: '邮箱或密码错误' });
    }
    
    const token = generateToken(user);
    
    // 获取家庭信息（家长账号返回孩子列表）
    let familyInfo = null;
    if (user.user_type === 'parent') {
      const children = db.prepare(`
        SELECT u.id, u.nickname, u.grade, u.avatar, fr.id as relation_id
        FROM users u
        JOIN family_relations fr ON u.id = fr.child_id
        WHERE fr.parent_id = ?
      `).all(user.id);
      familyInfo = { children };
    } else {
      const parent = db.prepare(`
        SELECT u.id, u.nickname, u.email
        FROM users u
        JOIN family_relations fr ON u.id = fr.parent_id
        WHERE fr.child_id = ?
      `).get(user.id);
      familyInfo = { parent };
    }
    
    // 获取星币余额（孩子）
    let starCoins = null;
    if (user.user_type === 'child') {
      const coins = db.prepare('SELECT balance FROM star_coins WHERE user_id = ?').get(user.id);
      starCoins = coins?.balance || 0;
    }
    
    res.json({
      message: '登录成功',
      token,
      user: {
        id: user.id,
        email: user.email,
        nickname: user.nickname,
        user_type: user.user_type,
        avatar: user.avatar,
        grade: user.grade
      },
      family: familyInfo,
      star_coins: starCoins
    });
  } catch (error) {
    console.error('登录错误:', error);
    res.status(500).json({ error: '服务器内部错误' });
  }
});

// 获取当前用户信息
router.get('/me', authenticateToken, (req, res) => {
  const user = db.prepare('SELECT id, email, nickname, user_type, avatar, grade FROM users WHERE id = ?').get(req.user.id);
  
  if (!user) {
    return res.status(404).json({ error: '用户不存在' });
  }
  
  res.json({ user });
});

module.exports = router;
