const { db, initSchema } = require('./db');
const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcryptjs');

// 种子数据：数学关卡（三年级）
const mathTasks = [
  {
    id: 'math_3_001',
    subject: 'math',
    grade: 3,
    title: '长方形与正方形周长',
    description: '星际农场防护罩破损，帮工程师计算能量栅栏的长度',
    difficulty: 1,
    reward_coins: 50,
    badge_id: 'badge_repair_worker',
    scene_data: JSON.stringify({
      scene: 'space_farm',
      tool: 'measuring_tape',
      formula: 'perimeter',
      hints: ['试试测量农场的长边和短边', '长方形周长 = (长+宽)×2'],
      challenges: [
        { question: '农场长8米，宽5米，需要多长的栅栏？', answer: 26, type: 'calculate' },
        { question: '正方形边长6米，周长是多少？', answer: 24, type: 'calculate' }
      ]
    }),
    sequence_num: 1
  },
  {
    id: 'math_3_002',
    subject: 'math',
    grade: 3,
    title: '分数运算·星际加油',
    description: '飞船燃料不足，混合不同规格的燃料罐',
    difficulty: 2,
    reward_coins: 60,
    badge_id: 'badge_fuel_engineer',
    scene_data: JSON.stringify({
      scene: 'spaceship_fuel',
      tool: 'fuel_can',
      hints: ['1/4 + 1/2 = ?', '把它们变成相同的分母']
    }),
    sequence_num: 2
  },
  {
    id: 'math_3_003',
    subject: 'math',
    grade: 3,
    title: '数据拼图·天气预测',
    description: '分析星云天气数据，规划航线',
    difficulty: 2,
    reward_coins: 60,
    badge_id: 'badge_navigator',
    scene_data: JSON.stringify({
      scene: 'nebula_weather',
      tool: 'chart_builder'
    }),
    sequence_num: 3
  }
];

// 语文关卡
const chineseTasks = [
  {
    id: 'chinese_3_001',
    subject: 'chinese',
    grade: 3,
    title: '望庐山瀑布·诗能量',
    description: '收集李白的诗句碎片，重启文字引擎',
    difficulty: 1,
    reward_coins: 60,
    badge_id: 'badge_poet',
    scene_data: JSON.stringify({
      scene: 'poetry_star',
      poem: '日照香炉生紫烟，遥看瀑布挂前川。飞流直下三千尺，疑是银河落九天',
      author: '李白'
    }),
    sequence_num: 1
  },
  {
    id: 'chinese_3_002',
    subject: 'chinese',
    grade: 3,
    title: '守株待兔·成语剧场',
    description: '扮演农夫，体验成语故事',
    difficulty: 2,
    reward_coins: 50,
    badge_id: 'badge_storyteller',
    scene_data: JSON.stringify({
      scene: 'idiom_theater',
      idiom: '守株待兔'
    }),
    sequence_num: 2
  }
];

// 英语关卡
const englishTasks = [
  {
    id: 'english_3_001',
    subject: 'english',
    grade: 3,
    title: 'At the Restaurant',
    description: '在美食星球学习点餐英语',
    difficulty: 1,
    reward_coins: 60,
    badge_id: 'badge_food_translator',
    scene_data: JSON.stringify({
      scene: 'space_restaurant',
      vocabulary: ['menu', 'table', 'hamburger', 'pizza', 'salad', 'juice', 'water'],
      sentence_pattern: 'I\'d like...'
    }),
    sequence_num: 1
  }
];

// 科学关卡
const scienceTasks = [
  {
    id: 'science_3_001',
    subject: 'science',
    grade: 3,
    title: '植物的生长实验',
    description: '帮助星际花园的植物恢复生机',
    difficulty: 1,
    reward_coins: 60,
    badge_id: 'badge_green_guardian',
    scene_data: JSON.stringify({
      scene: 'space_garden',
      experiment: 'plant_growth',
      variables: ['sunlight', 'water', 'soil', 'air']
    }),
    sequence_num: 1
  }
];

// 勋章数据
const badges = [
  { id: 'badge_repair_worker', name: '维修工勋章', description: '完成长方形周长任务', icon: '🔧' },
  { id: 'badge_fuel_engineer', name: '燃料工程师', description: '掌握分数运算', icon: '⛽' },
  { id: 'badge_navigator', name: '星际领航员', description: '完成数据统计任务', icon: '🧭' },
  { id: 'badge_poet', name: '诗人勋章', description: '完成古诗学习', icon: '📜' },
  { id: 'badge_storyteller', name: '故事大王', description: '完成成语剧场', icon: '📖' },
  { id: 'badge_food_translator', name: '美食星语者', description: '完成英语餐厅任务', icon: '🍕' },
  { id: 'badge_green_guardian', name: '绿色守护者', description: '完成植物实验', icon: '🌱' },
  { id: 'badge_first_explorer', name: '初出茅庐', description: '完成第一个任务', icon: '⭐' }
];

async function seed() {
  console.log('🌱 开始初始化数据库...');
  
  initSchema();
  
  // 插入任务
  const insertTask = db.prepare(`
    INSERT OR REPLACE INTO tasks (id, subject, grade, title, description, difficulty, reward_coins, badge_id, scene_data, sequence_num)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);
  
  [...mathTasks, ...chineseTasks, ...englishTasks, ...scienceTasks].forEach(task => {
    insertTask.run(task.id, task.subject, task.grade, task.title, task.description, 
                   task.difficulty, task.reward_coins, task.badge_id, task.scene_data, task.sequence_num);
  });
  
  // 插入勋章
  const insertBadge = db.prepare(`
    INSERT OR REPLACE INTO badges (id, name, description, icon)
    VALUES (?, ?, ?, ?)
  `);
  badges.forEach(b => insertBadge.run(b.id, b.name, b.description, b.icon));
  
  // 创建测试账号
  const hashedPassword = await bcrypt.hash('123456', 10);
  
  const parentId = 'parent_demo_001';
  const childId = 'child_demo_001';
  
  const insertUser = db.prepare(`
    INSERT OR REPLACE INTO users (id, email, password_hash, user_type, nickname, avatar, grade)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `);
  
  insertUser.run(parentId, 'parent@demo.com', hashedPassword, 'parent', '星探爸爸', 'parent', null);
  insertUser.run(childId, 'child@demo.com', hashedPassword, 'child', '小星星', 'astronaut', 3);
  
  // 家庭关系
  db.prepare(`
    INSERT OR REPLACE INTO family_relations (id, parent_id, child_id, nickname)
    VALUES (?, ?, ?, ?)
  `).run(uuidv4(), parentId, childId, '小星星');
  
  // 家长设置
  db.prepare(`
    INSERT OR REPLACE INTO parent_settings (id, parent_id, max_daily_minutes, allowed_start_time, allowed_end_time)
    VALUES (?, ?, ?, ?, ?)
  `).run(uuidv4(), parentId, 30, '08:00', '21:00');
  
  // 星币账户
  db.prepare(`
    INSERT OR REPLACE INTO star_coins (id, user_id, balance, total_earned)
    VALUES (?, ?, ?, ?)
  `).run(uuidv4(), childId, 200, 200);
  
  console.log('✅ 数据库初始化完成！');
  console.log('\n🧪 测试账号：');
  console.log('  家长: parent@demo.com / 123456');
  console.log('  孩子: child@demo.com / 123456');
}

if (require.main === module) {
  seed().catch(console.error);
}

module.exports = { seed };
