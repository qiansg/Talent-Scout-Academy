const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { db } = require('../db');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// 获取家长的孩子列表及其学习数据
router.get('/children', authenticateToken, (req, res) => {
  const parentId = req.user.id;
  
  const children = db.prepare(`
    SELECT u.id, u.nickname, u.grade, u.avatar, fr.nickname as relation_nickname
    FROM users u
    JOIN family_relations fr ON u.id = fr.child_id
    WHERE fr.parent_id = ?
  `).all(parentId);
  
  // 为每个孩子获取简要数据
  const childrenWithStats = children.map(child => {
    const stats = db.prepare(`
      SELECT 
        COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed,
        COUNT(CASE WHEN status = 'in_progress' THEN 1 END) as in_progress
      FROM task_progress WHERE user_id = ?
    `).get(child.id);
    
    const coins = db.prepare('SELECT balance FROM star_coins WHERE user_id = ?').get(child.id);
    
    const lastActivity = db.prepare(`
      SELECT * FROM learning_logs WHERE user_id = ? ORDER BY created_at DESC LIMIT 1
    `).get(child.id);
    
    return {
      ...child,
      completed_tasks: stats.completed,
      in_progress_tasks: stats.in_progress,
      star_coins: coins?.balance || 0,
      last_activity: lastActivity?.created_at
    };
  });
  
  res.json({ children: childrenWithStats });
});

// 获取孩子的学习数据看板
router.get('/dashboard/:childId', authenticateToken, (req, res) => {
  const parentId = req.user.id;
  const { childId } = req.params;
  const { range = 'week' } = req.query; // day, week, month
  
  // 验证父子关系
  const relation = db.prepare(`
    SELECT * FROM family_relations WHERE parent_id = ? AND child_id = ?
  `).get(parentId, childId);
  
  if (!relation) {
    return res.status(403).json({ error: '无权查看该孩子的数据' });
  }
  
  // 计算时间范围
  const now = new Date();
  let startDate;
  if (range === 'day') {
    startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  } else if (range === 'week') {
    startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  } else {
    startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
  }
  
  const startStr = startDate.toISOString();
  
  // 学习日志
  const logs = db.prepare(`
    SELECT ll.*, t.title as task_title, t.subject
    FROM learning_logs ll
    LEFT JOIN tasks t ON ll.task_id = t.id
    WHERE ll.user_id = ? AND ll.created_at >= ?
    ORDER BY ll.created_at DESC
  `).all(childId, startStr);
  
  // 能力评估（基于学习行为的简单评估）
  const abilityScores = calculateAbilityScores(logs, childId);
  
  // 情绪趋势
  const emotionTrend = logs
    .filter(l => l.emotion)
    .map(l => ({
      time: l.created_at,
      emotion: l.emotion,
      score: emotionToScore(l.emotion)
    }));
  
  // 高压时刻（低情绪 + 低正确率）
  const pressurePoints = logs.filter(l => 
    (l.emotion === 'frustrated' || l.emotion === 'tired') || 
    (l.accuracy !== null && l.accuracy < 0.5 && l.duration_seconds > 60)
  ).map(l => ({
    time: l.created_at,
    reason: l.emotion === 'frustrated' ? '情绪低落' : 
            l.emotion === 'tired' ? '疲劳' : 
            (l.accuracy !== null && l.accuracy < 0.5 ? '正确率低' : '连续失败'),
    task: l.task_title
  }));
  
  // 总学习数据
  const totalStats = {
    total_seconds: logs.reduce((sum, l) => sum + (l.duration_seconds || 0), 0),
    completed_count: logs.filter(l => l.action === 'task_submit' && l.accuracy === 1).length,
    avg_accuracy: logs.filter(l => l.accuracy !== null && l.action === 'task_submit').reduce((sum, l, _, arr) => sum + l.accuracy / arr.length, 0) * 100 || 0,
    subjects_covered: [...new Set(logs.map(l => l.subject).filter(Boolean))]
  };
  
  // 勋章
  const badges = db.prepare(`
    SELECT b.*, ub.earned_at
    FROM user_badges ub
    JOIN badges b ON ub.badge_id = b.id
    WHERE ub.user_id = ?
    ORDER BY ub.earned_at DESC
  `).all(childId);
  
  // 星币
  const coins = db.prepare('SELECT balance, total_earned FROM star_coins WHERE user_id = ?').get(childId);
  
  res.json({
    range,
    child: db.prepare('SELECT id, nickname, grade FROM users WHERE id = ?').get(childId),
    ability_scores: abilityScores,
    emotion_trend: emotionTrend.slice(0, 20),
    pressure_points: pressurePoints.slice(0, 10),
    total_stats: totalStats,
    badges,
    star_coins: coins || { balance: 0, total_earned: 0 },
    recent_logs: logs.slice(0, 20)
  });
});

// 计算能力评分
function calculateAbilityScores(logs, childId) {
  const accuracyLogs = logs.filter(l => l.accuracy !== null && l.action === 'task_submit');
  const avgAccuracy = accuracyLogs.reduce((sum, l, _, arr) => sum + l.accuracy / arr.length, 0);
  
  // 基于学科表现估算各维度
  const subjectAccuracy = {};
  accuracyLogs.forEach(l => {
    if (!subjectAccuracy[l.subject]) subjectAccuracy[l.subject] = [];
    subjectAccuracy[l.subject].push(l.accuracy);
  });
  
  const calcAvg = arr => arr.length ? arr.reduce((a, b) => a + b, 0) / arr.length : 0.7;
  
  return {
    calculation: Math.round(calcAvg(subjectAccuracy['math'] || []) * 100),
    logic: Math.round(avgAccuracy * 100 + (accuracyLogs.length * 2)),
    spatial: Math.round((calcAvg(subjectAccuracy['science'] || []) + 0.6) * 50),
    focus: Math.min(100, Math.round((avgAccuracy * 60) + 40)),
    expression: Math.round(calcAvg(subjectAccuracy['chinese'] || subjectAccuracy['english'] || []) * 100)
  };
}

// 情绪转分数
function emotionToScore(emotion) {
  const map = { joyful: 95, happy: 80, neutral: 60, tired: 40, frustrated: 20 };
  return map[emotion] || 60;
}

// 获取/更新家长设置
router.get('/settings', authenticateToken, (req, res) => {
  const parentId = req.user.id;
  
  let settings = db.prepare('SELECT * FROM parent_settings WHERE parent_id = ?').get(parentId);
  
  if (!settings) {
    db.prepare(`
      INSERT INTO parent_settings (id, parent_id)
      VALUES (?, ?)
    `).run(uuidv4(), parentId);
    settings = db.prepare('SELECT * FROM parent_settings WHERE parent_id = ?').get(parentId);
  }
  
  res.json({ settings });
});

router.put('/settings', authenticateToken, (req, res) => {
  const parentId = req.user.id;
  const { max_daily_minutes, allowed_start_time, allowed_end_time, rest_reminder_minutes, content_filter_enabled } = req.body;
  
  db.prepare(`
    UPDATE parent_settings 
    SET max_daily_minutes = COALESCE(?, max_daily_minutes),
        allowed_start_time = COALESCE(?, allowed_start_time),
        allowed_end_time = COALESCE(?, allowed_end_time),
        rest_reminder_minutes = COALESCE(?, rest_reminder_minutes),
        content_filter_enabled = COALESCE(?, content_filter_enabled)
    WHERE parent_id = ?
  `).run(max_daily_minutes, allowed_start_time, allowed_end_time, rest_reminder_minutes, content_filter_enabled ? 1 : 0, parentId);
  
  const settings = db.prepare('SELECT * FROM parent_settings WHERE parent_id = ?').get(parentId);
  res.json({ message: '设置已更新', settings });
});

// 获取今日学习时长
router.get('/usage/:childId', authenticateToken, (req, res) => {
  const parentId = req.user.id;
  const { childId } = req.params;
  
  const relation = db.prepare(`
    SELECT * FROM family_relations WHERE parent_id = ? AND child_id = ?
  `).get(parentId, childId);
  
  if (!relation) {
    return res.status(403).json({ error: '无权查看' });
  }
  
  // 今日学习时长
  const today = new Date();
  const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate()).toISOString();
  
  const todaySeconds = db.prepare(`
    SELECT COALESCE(SUM(duration_seconds), 0) as total
    FROM learning_logs WHERE user_id = ? AND created_at >= ?
  `).get(childId, todayStart).total;
  
  const settings = db.prepare('SELECT * FROM parent_settings WHERE parent_id = ?').get(parentId);
  const maxMinutes = settings?.max_daily_minutes || 30;
  
  // 本周每天学习时长
  const weekAgo = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString();
  const dailyMinutes = db.prepare(`
    SELECT DATE(created_at) as date, COALESCE(SUM(duration_seconds), 0) / 60 as minutes
    FROM learning_logs WHERE user_id = ? AND created_at >= ?
    GROUP BY DATE(created_at)
    ORDER BY date ASC
  `).all(childId, weekAgo);
  
  res.json({
    today_seconds: todaySeconds,
    today_minutes: Math.round(todaySeconds / 60),
    max_minutes: maxMinutes,
    remaining_minutes: Math.max(0, maxMinutes - Math.round(todaySeconds / 60)),
    is_over_limit: todaySeconds / 60 >= maxMinutes,
    daily_history: dailyMinutes
  });
});

module.exports = router;
