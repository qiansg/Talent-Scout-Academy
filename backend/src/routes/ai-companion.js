const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { db } = require('../db');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// 星仔的预设知识库（模拟 AI 回复）
const starCompanionKnowledge = {
  // 数学
  math: {
    greetings: [
      '嘿！小探险家！今天想探索什么数学谜题呢？',
      '数学是宇宙的语言哦！我们一起来发现吧！',
      '准备好和星仔一起修复星际飞船了吗？🚀'
    ],
    hints: {
      perimeter: [
        '让我们先测量一下农场的长边和短边吧！',
        '长方形有两条长边和两条短边哦！',
        '试试用卷尺拖动到农场边缘，数值会自动显示的！'
      ],
      fraction: [
        '分数就像把一块蛋糕分成几份一样！',
        '1/2 就是一半，1/4 就是四分之一哦！',
        '试试把燃料罐倒入主油箱，看看液面到哪里了！'
      ],
      area: [
        '面积就是一个形状能覆盖多少个小格子哦！',
        '长方形面积 = 长 × 宽，记住了吗？',
        '来数一下格子，你会发现规律的！'
      ]
    },
    praise: [
      '太棒了！你的计算能力越来越强了！🌟',
      '哇，这个思路真特别！继续保持！',
      '你已经成功修复了飞船的一部分！好厉害！'
    ],
    encourage: [
      '没关系，错误是学习的好机会嘛！',
      '再试一次，星仔相信你能做到！',
      '休息一下眼睛，看看窗外的风景再回来吧~'
    ]
  },
  // 语文
  chinese: {
    greetings: [
      '文字飞船的能量需要你的帮助哦！',
      '汉字是古老的图画，让我们一起探索吧！',
      '今天要收集哪些字宝宝呢？📚'
    ],
    praise: [
      '你的朗读真好听！文字引擎充满能量了！✨',
      '太棒了，诗能量收集完成！',
      '诗人勋章正在向你招手！'
    ],
    encourage: [
      '没关系，我们重新排列一下就好！',
      '想想故事的顺序，太阳先升起，然后...',
      '再听一遍范读音频，慢慢练习！'
    ]
  },
  // 英语
  english: {
    greetings: [
      'Hello! 外星人朋友们在等着你呢！👽',
      '英语是通往星际的钥匙！Let\'s start!',
      'Star老师今天要带你去哪里呢？'
    ],
    praise: [
      'Great job! 发音越来越标准了！🎉',
      'Perfect! 外星人顾客很满意你的服务！',
      'Your English is amazing! Keep going!'
    ],
    encourage: [
      'Don\'t worry! 慢慢来，Star会等你的！',
      '试试慢速跟读，看着口型动画！',
      '没关系，句型积木可以帮你！'
    ]
  },
  // 科学
  science: {
    greetings: [
      '实验室的灯已经亮了！开始探索吧！🔬',
      '每一个伟大的发现都从一个好问题开始！',
      '星仔已经准备好了，你呢？'
    ],
    praise: [
      '太棒了！科学家就是这样思考的！🧪',
      '你的实验结论完全正确！绿色守护者就是你！',
      '星际花园在你的帮助下重新焕发生机了！'
    ],
    encourage: [
      '科学就是不断试错的过程！再试一次！',
      '想想看，为什么这组植物长得好？',
      '观察是科学家最重要的本领哦！'
    ]
  },
  // 通用
  general: {
    help: '有什么问题都可以问星仔哦！数学、语文、英语、科学，我都懂一点点~',
    rest: '学习累了吗？让我们休息一下吧！看看远处，让眼睛放松放松~ 😊',
    bored: '有点无聊了？要不试试别的学科？或者去创造工坊画画？🎨',
    frustrated: '别着急！星仔会一直陪着你的。我们一步一步来，好吗？',
    default: '嗯，星仔在认真听哦！你想聊点什么呢？'
  }
};

// 简易关键词匹配生成回复
function generateReply(message, subject = null) {
  const msg = message.toLowerCase();
  
  // 检测情绪关键词
  if (/累|休息|困|想睡觉/.test(msg)) {
    return { text: starCompanionKnowledge.general.rest, emotion: 'caring' };
  }
  if (/难|不会|不懂|好难|做不出来/.test(msg)) {
    return { text: starCompanionKnowledge.general.frustrated, emotion: 'encouraging' };
  }
  if (/无聊|没意思|不想学/.test(msg)) {
    return { text: starCompanionKnowledge.general.bored, emotion: 'cheerful' };
  }
  if (/谢谢|真棒|好厉害|太好了/.test(msg)) {
    return { text: '嘿嘿，能帮到你星仔也很开心！继续加油哦！🌟', emotion: 'happy' };
  }
  
  // 数学相关
  if (subject === 'math' || /数学|算|周长|面积|分数|计算/.test(msg)) {
    const math = starCompanionKnowledge.math;
    if (/周长|栅栏|长方形|正方形/.test(msg)) {
      return { text: math.hints.perimeter[Math.floor(Math.random() * math.hints.perimeter.length)], emotion: 'teaching' };
    }
    if (/分数|加油|燃料|混合/.test(msg)) {
      return { text: math.hints.fraction[Math.floor(Math.random() * math.hints.fraction.length)], emotion: 'teaching' };
    }
    return { text: math.greetings[Math.floor(Math.random() * math.greetings.length)], emotion: 'cheerful' };
  }
  
  // 语文相关
  if (subject === 'chinese' || /语文|诗|字|朗读|成语/.test(msg)) {
    const cn = starCompanionKnowledge.chinese;
    return { text: cn.greetings[Math.floor(Math.random() * cn.greetings.length)], emotion: 'cheerful' };
  }
  
  // 英语相关
  if (subject === 'english' || /英语|英文|hello|hi|单词|发音/.test(msg)) {
    const en = starCompanionKnowledge.english;
    return { text: en.greetings[Math.floor(Math.random() * en.greetings.length)], emotion: 'cheerful' };
  }
  
  // 科学相关
  if (subject === 'science' || /科学|实验|植物|太阳|水/.test(msg)) {
    const sc = starCompanionKnowledge.science;
    return { text: sc.greetings[Math.floor(Math.random() * sc.greetings.length)], emotion: 'cheerful' };
  }
  
  // 默认回复
  const defaults = [
    '哇，这个问题很有意思！你可以试试这样想想...',
    '星仔在认真听哦！能再说说你的想法吗？',
    '好问题！让我们一起找找答案吧！',
    '这是个好主意！你真棒！',
    starCompanionKnowledge.general.default
  ];
  
  return { text: defaults[Math.floor(Math.random() * defaults.length)], emotion: 'curious' };
}

// 发送消息给星仔
router.post('/chat', authenticateToken, (req, res) => {
  const userId = req.user.id;
  const { message, subject } = req.body;
  
  if (!message || message.trim() === '') {
    return res.status(400).json({ error: '消息不能为空' });
  }
  
  // 生成星仔回复
  const reply = generateReply(message, subject);
  
  // 保存用户消息
  db.prepare(`
    INSERT INTO ai_conversations (id, user_id, role, message, subject)
    VALUES (?, ?, 'user', ?, ?)
  `).run(uuidv4(), userId, message, subject);
  
  // 保存星仔回复
  db.prepare(`
    INSERT INTO ai_conversations (id, user_id, role, message, subject)
    VALUES (?, ?, 'assistant', ?, ?)
  `).run(uuidv4(), userId, reply.text, subject);
  
  res.json({
    reply: reply.text,
    emotion: reply.emotion,
    suggestions: getSuggestions(subject)
  });
});

// 获取建议问题
function getSuggestions(subject) {
  const general = ['再讲一遍', '举个例子', '这是什么意思', '换个说法'];
  const bySubject = {
    math: ['为什么是这样？', '换个方法试试', '有别的规律吗？'],
    chinese: ['这个字怎么写？', '什么意思？', '能读给我听吗？'],
    english: ['发音怎么读？', '什么意思？', '还有别的说法吗？'],
    science: ['为什么会这样？', '换个实验试试', '生活中哪里有？']
  };
  
  return [...general, ...(bySubject[subject] || [])].slice(0, 4);
}

// 获取对话历史
router.get('/history', authenticateToken, (req, res) => {
  const userId = req.user.id;
  const { limit = 50 } = req.query;
  
  const conversations = db.prepare(`
    SELECT * FROM ai_conversations
    WHERE user_id = ?
    ORDER BY created_at ASC
    LIMIT ?
  `).all(userId, parseInt(limit));
  
  res.json({ conversations });
});

// 获取情绪分析（模拟）
router.get('/emotion', authenticateToken, (req, res) => {
  const userId = req.user.id;
  
  const recentLogs = db.prepare(`
    SELECT emotion, accuracy, action, created_at
    FROM learning_logs
    WHERE user_id = ?
    ORDER BY created_at DESC
    LIMIT 20
  `).all(userId);
  
  const recentConversations = db.prepare(`
    SELECT message FROM ai_conversations
    WHERE user_id = ? AND role = 'user'
    ORDER BY created_at DESC
    LIMIT 10
  `).all(userId);
  
  // 简单的情绪判断
  let emotionScore = 70; // 基础分
  let emotionLabel = 'happy';
  
  recentLogs.forEach(log => {
    if (log.accuracy === 100) emotionScore += 5;
    if (log.accuracy === 0) emotionScore -= 10;
    if (log.emotion === 'frustrated') emotionScore -= 15;
  });
  
  recentConversations.forEach(c => {
    if (/难|不会|难|累/.test(c.message)) emotionScore -= 5;
    if (/太棒|好厉害|谢谢/.test(c.message)) emotionScore += 5;
  });
  
  emotionScore = Math.max(0, Math.min(100, emotionScore));
  
  if (emotionScore >= 80) emotionLabel = 'joyful';
  else if (emotionScore >= 60) emotionLabel = 'happy';
  else if (emotionScore >= 40) emotionLabel = 'neutral';
  else if (emotionScore >= 20) emotionLabel = 'tired';
  else emotionLabel = 'frustrated';
  
  res.json({
    emotion: emotionLabel,
    score: emotionScore,
    advice: emotionScore < 40 ? '建议休息一下，活动活动！' : '状态不错，继续加油！',
    recent_logs: recentLogs
  });
});

// 星仔开场动画
router.get('/greeting', authenticateToken, (req, res) => {
  const userId = req.user.id;
  
  const user = db.prepare('SELECT nickname FROM users WHERE id = ?').get(userId);
  const hour = new Date().getHours();
  
  let greeting = '';
  if (hour < 12) greeting = '早上好';
  else if (hour < 18) greeting = '下午好';
  else greeting = '晚上好';
  
  const intros = [
    `${greeting}，${user?.nickname || '小探险家'}！今天想探索什么呢？✨`,
    `${greeting}！星际地图上又多了新的星球哦！`,
    `${greeting}！星仔已经准备好和你一起冒险了！🚀`,
    `${greeting}！让我们一起在探索中学习吧！🌟`
  ];
  
  res.json({
    greeting: intros[Math.floor(Math.random() * intros.length)],
    star_pose: ['wave', 'jump', 'think', 'cheer'][Math.floor(Math.random() * 4)]
  });
});

module.exports = router;
