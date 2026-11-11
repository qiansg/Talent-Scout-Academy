const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { db } = require('../db');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// 获取所有学科
router.get('/subjects', (req, res) => {
  const subjects = [
    { key: 'math', name: '数学·逻辑星图', icon: '🧮', color: '#3B82F6', description: '飞船修复与星际导航任务' },
    { key: 'chinese', name: '语文·文字飞船', icon: '📚', color: '#EF4444', description: '汉字收集与诗词能量任务' },
    { key: 'english', name: '英语·外星语解码', icon: '🌍', color: '#10B981', description: '星际通讯与外星语翻译任务' },
    { key: 'science', name: '科学·星球实验室', icon: '🔬', color: '#8B5CF6', description: '虚拟实验与现实探索任务' }
  ];
  res.json({ subjects });
});

// 获取指定学科的任务列表
router.get('/subjects/:subject/tasks', authenticateToken, (req, res) => {
  const { subject } = req.params;
  const { grade } = req.query;
  const userId = req.user.id;
  
  let query = `
    SELECT t.*, 
      tp.status as progress_status,
      tp.score as progress_score,
      tp.completed_at as completed_at,
      b.name as badge_name,
      b.icon as badge_icon
    FROM tasks t
    LEFT JOIN task_progress tp ON t.id = tp.task_id AND tp.user_id = ?
    LEFT JOIN badges b ON t.badge_id = b.id
    WHERE t.subject = ?
  `;
  const params = [userId, subject];
  
  if (grade) {
    query += ' AND t.grade = ?';
    params.push(parseInt(grade));
  }
  
  query += ' ORDER BY t.sequence_num ASC';
  
  const tasks = db.prepare(query).all(...params);
  
  res.json({ tasks });
});

// 获取任务详情
router.get('/tasks/:taskId', authenticateToken, (req, res) => {
  const { taskId } = req.params;
  const userId = req.user.id;
  
  const task = db.prepare(`
    SELECT t.*, 
      tp.status as progress_status,
      tp.score as progress_score,
      tp.attempts,
      b.name as badge_name,
      b.icon as badge_icon,
      b.description as badge_description
    FROM tasks t
    LEFT JOIN task_progress tp ON t.id = tp.task_id AND tp.user_id = ?
    LEFT JOIN badges b ON t.badge_id = b.id
    WHERE t.id = ?
  `).get(userId, taskId);
  
  if (!task) {
    return res.status(404).json({ error: '任务不存在' });
  }
  
  // 解析场景数据
  if (task.scene_data) {
    task.scene_data = JSON.parse(task.scene_data);
  }
  
  res.json({ task });
});

// 开始任务
router.post('/tasks/:taskId/start', authenticateToken, (req, res) => {
  const { taskId } = req.params;
  const userId = req.user.id;
  
  const task = db.prepare('SELECT * FROM tasks WHERE id = ?').get(taskId);
  if (!task) {
    return res.status(404).json({ error: '任务不存在' });
  }
  
  // 创建或更新进度
  const existing = db.prepare('SELECT * FROM task_progress WHERE user_id = ? AND task_id = ?').get(userId, taskId);
  
  if (!existing) {
    db.prepare(`
      INSERT INTO task_progress (id, user_id, task_id, status, attempts)
      VALUES (?, ?, ?, 'in_progress', 1)
    `).run(uuidv4(), userId, taskId);
  } else {
    db.prepare(`
      UPDATE task_progress SET status = 'in_progress', attempts = attempts + 1
      WHERE id = ?
    `).run(existing.id);
  }
  
  // 记录学习日志
  db.prepare(`
    INSERT INTO learning_logs (id, user_id, task_id, subject, action)
    VALUES (?, ?, ?, ?, 'task_start')
  `).run(uuidv4(), userId, taskId, task.subject);
  
  res.json({ message: '任务已开始', task_id: taskId });
});

// 提交任务答案
router.post('/tasks/:taskId/submit', authenticateToken, (req, res) => {
  const { taskId } = req.params;
  const userId = req.user.id;
  const { answer, duration_seconds, emotion } = req.body;
  
  const task = db.prepare('SELECT * FROM tasks WHERE id = ?').get(taskId);
  if (!task) {
    return res.status(404).json({ error: '任务不存在' });
  }
  
  let isCorrect = false;
  let score = 0;
  let hint = '';
  
  // 简单的答案检查（实际应根据 scene_data.challenges 判断）
  if (task.scene_data) {
    const sceneData = JSON.parse(task.scene_data);
    if (sceneData.challenges && sceneData.challenges.length > 0) {
      // 检查最后一个挑战的答案
      const lastChallenge = sceneData.challenges[sceneData.challenges.length - 1];
      isCorrect = parseInt(answer) === lastChallenge.answer;
      score = isCorrect ? 100 : 0;
    }
  }
  
  // 更新进度
  const existing = db.prepare('SELECT * FROM task_progress WHERE user_id = ? AND task_id = ?').get(userId, taskId);
  
  if (isCorrect && existing?.status !== 'completed') {
    db.prepare(`
      UPDATE task_progress SET status = 'completed', score = ?, completed_at = CURRENT_TIMESTAMP
      WHERE id = ?
    `).run(score, existing.id);
    
    // 发放星币
    const coins = db.prepare('SELECT * FROM star_coins WHERE user_id = ?').get(userId);
    if (coins) {
      db.prepare(`
        UPDATE star_coins SET balance = balance + ?, total_earned = total_earned + ?, updated_at = CURRENT_TIMESTAMP
        WHERE user_id = ?
      `).run(task.reward_coins, task.reward_coins, userId);
    }
    
    // 发放勋章
    if (task.badge_id) {
      const hasBadge = db.prepare('SELECT id FROM user_badges WHERE user_id = ? AND badge_id = ?').get(userId, task.badge_id);
      if (!hasBadge) {
        db.prepare(`
          INSERT INTO user_badges (id, user_id, badge_id)
          VALUES (?, ?, ?)
        `).run(uuidv4(), userId, task.badge_id);
      }
    }
    
    // 首次完成奖励
    const firstBadge = db.prepare('SELECT id FROM user_badges WHERE user_id = ?').get(userId);
    if (!firstBadge) {
      db.prepare(`
        INSERT INTO user_badges (id, user_id, badge_id)
        VALUES (?, ?, 'badge_first_explorer')
      `).run(uuidv4(), userId);
    }
    
    hint = '太棒了！任务完成，奖励已发放！';
  } else if (isCorrect) {
    hint = '你已经完成过这个任务了！';
  } else {
    hint = '再想想看？试试使用工具测量一下！';
  }
  
  // 记录学习日志
  db.prepare(`
    INSERT INTO learning_logs (id, user_id, task_id, subject, action, duration_seconds, accuracy, emotion, details)
    VALUES (?, ?, ?, ?, 'task_submit', ?, ?, ?, ?)
  `).run(uuidv4(), userId, taskId, task.subject, duration_seconds || 0, score / 100, emotion || 'neutral', JSON.stringify({ answer, isCorrect }));
  
  res.json({
    is_correct: isCorrect,
    score,
    hint,
    rewards: isCorrect && existing?.status !== 'completed' ? {
      coins: task.reward_coins,
      badge_id: task.badge_id
    } : null
  });
});

// 获取用户的学习统计
router.get('/stats/overview', authenticateToken, (req, res) => {
  const userId = req.user.id;
  
  // 总完成数
  const totalCompleted = db.prepare(`
    SELECT COUNT(*) as count FROM task_progress WHERE user_id = ? AND status = 'completed'
  `).get(userId).count;
  
  // 各学科完成数
  const subjectStats = db.prepare(`
    SELECT t.subject, COUNT(*) as count
    FROM task_progress tp
    JOIN tasks t ON tp.task_id = t.id
    WHERE tp.user_id = ? AND tp.status = 'completed'
    GROUP BY t.subject
  `).all(userId);
  
  // 总学习时间
  const totalTime = db.prepare(`
    SELECT COALESCE(SUM(duration_seconds), 0) as total
    FROM learning_logs WHERE user_id = ?
  `).get(userId).total;
  
  // 获得的勋章
  const badges = db.prepare(`
    SELECT b.* FROM user_badges ub
    JOIN badges b ON ub.badge_id = b.id
    WHERE ub.user_id = ?
    ORDER BY ub.earned_at DESC
  `).all(userId);
  
  // 星币余额
  const coins = db.prepare('SELECT balance, total_earned FROM star_coins WHERE user_id = ?').get(userId);
  
  // 最近学习日志
  const recentLogs = db.prepare(`
    SELECT ll.*, t.title as task_title, t.subject
    FROM learning_logs ll
    LEFT JOIN tasks t ON ll.task_id = t.id
    WHERE ll.user_id = ? AND ll.action = 'task_submit'
    ORDER BY ll.created_at DESC
    LIMIT 10
  `).all(userId);
  
  res.json({
    stats: {
      total_completed: totalCompleted,
      total_seconds: totalTime,
      subject_stats: subjectStats,
      star_coins: coins || { balance: 0, total_earned: 0 },
      badges_count: badges.length
    },
    badges,
    recent_logs: recentLogs
  });
});

// 获取勋章墙
router.get('/badges', authenticateToken, (req, res) => {
  const userId = req.user.id;
  
  const allBadges = db.prepare('SELECT * FROM badges').all();
  const earnedBadges = db.prepare(`
    SELECT badge_id, earned_at FROM user_badges WHERE user_id = ?
  `).all(userId);
  
  const earnedSet = new Set(earnedBadges.map(b => b.badge_id));
  
  const result = allBadges.map(b => ({
    ...b,
    earned: earnedSet.has(b.id),
    earned_at: earnedBadges.find(eb => eb.badge_id === b.id)?.earned_at
  }));
  
  res.json({ badges: result });
});

module.exports = router;
