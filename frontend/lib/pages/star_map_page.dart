import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import 'subject_tasks_page.dart';
import 'profile_page.dart';

/// 星际地图首页
class StarMapPage extends ConsumerStatefulWidget {
  const StarMapPage({super.key});

  @override
  ConsumerState<StarMapPage> createState() => _StarMapPageState();
}

class _StarMapPageState extends ConsumerState<StarMapPage> {
  final TaskService _taskService = TaskService();
  List<dynamic> _subjects = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final subjects = await _taskService.getSubjects();
      final stats = await _taskService.getStats();
      if (mounted) {
        setState(() {
          _subjects = subjects;
          _stats = stats['stats'] ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.spaceBackground),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.cyan))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTopBar(),
                          const SizedBox(height: 20),
                          _buildStatsCard(),
                          const SizedBox(height: 24),
                          _buildStarMap(),
                          const SizedBox(height: 24),
                          _buildSubjectGrid(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final auth = ref.watch(authProvider).valueOrNull!;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? '早上好' : hour < 18 ? '下午好' : '晚上好';
    
    return Row(
      children: [
        // 头像
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.cyan, AppTheme.blue]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppTheme.cyan.withOpacity(0.3), blurRadius: 12)],
            ),
            child: const Icon(Icons.person, size: 28, color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$greeting！', style: const TextStyle(color: Colors.white60, fontSize: 13)),
              Text(auth.user?.nickname ?? '小探险家',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        // 星币
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: AppTheme.glassCard,
          child: Row(
            children: [
              const Text('🪐', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text('${auth.starCoins}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.yellowAccent)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    final totalCompleted = _stats['total_completed'] ?? 0;
    final badgesCount = (_stats['badges'] as List?)?.length ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C42)]),
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: const Icon(Icons.emoji_events_rounded, size: 30, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$totalCompleted 个任务',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text('已探索 $badgesCount 枚勋章', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.cyan.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('继续探索 →',
                style: TextStyle(color: AppTheme.cyan, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildStarMap() {
    final planetPositions = [
      { 'subject': 'math', 'x': 0.25, 'y': 0.30, 'size': 88 },
      { 'subject': 'chinese', 'x': 0.70, 'y': 0.25, 'size': 78 },
      { 'subject': 'science', 'x': 0.28, 'y': 0.72, 'size': 82 },
      { 'subject': 'english', 'x': 0.68, 'y': 0.68, 'size': 74 },
    ];

    return Column(
      children: [
        const Center(
          child: Text('星际地图',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        const Text('选择一个星球，开始你的探索！',
            style: TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 16),
        Container(
          height: 320,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                AppTheme.spacePurple.withOpacity(0.5),
                AppTheme.spaceBlue.withOpacity(0.3),
              ],
            ),
          ),
          child: Stack(
            children: [
              // 背景星光
              ..._buildStars(),
              
              // 连线
              CustomPaint(
                painter: OrbitPainter(planetPositions),
                size: Size.infinite,
              ),
              
              // 星球节点
              ...planetPositions.map((p) => _buildPlanet(p)),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildStars() {
    return List.generate(25, (i) {
      final left = (i * 37) % 100;
      final top = (i * 53) % 100;
      final size = (i % 3) + 1.0;
      return Positioned(
        left: left.toDouble(),
        top: top.toDouble(),
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      );
    });
  }

  Widget _buildPlanet(Map<String, dynamic> pos) {
    final subject = pos['subject'] as String;
    final config = _getSubjectConfig(subject);
    final left = pos['x'] as double;
    final top = pos['y'] as double;
    final size = pos['size'] as double;
    
    return Positioned(
      left: null,
      right: null,
      child: Align(
        alignment: Alignment(left * 2 - 1, top * 2 - 1),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SubjectTasksPage(subject: subject),
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 发光效果
              Container(
                width: size + 20,
                height: size + 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: config['color'].withOpacity(0.5),
                      blurRadius: 25,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      gradient: config['gradient'],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        config['icon'],
                        style: TextStyle(fontSize: size * 0.45),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  config['name'].split('·').first,
                  style: TextStyle(
                    color: config['color'],
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectGrid() {
    final configs = [
      {'key': 'math', 'name': '数学·逻辑星图', 'icon': '🧮', 'gradient': const LinearGradient(colors: [AppTheme.mathColor, Color(0xFF06B6D4)])},
      {'key': 'chinese', 'name': '语文·文字飞船', 'icon': '📚', 'gradient': const LinearGradient(colors: [AppTheme.chineseColor, Color(0xFFEC4899)])},
      {'key': 'english', 'name': '英语·外星语解码', 'icon': '🌍', 'gradient': const LinearGradient(colors: [AppTheme.englishColor, Color(0xFF059669)])},
      {'key': 'science', 'name': '科学·星球实验室', 'icon': '🔬', 'gradient': const LinearGradient(colors: [AppTheme.scienceColor, Color(0xFF6366F1)])},
    ];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: configs.length,
      itemBuilder: (context, index) {
        final cfg = configs[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SubjectTasksPage(subject: cfg['key'] as String),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: cfg['gradient'] as LinearGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                // 径向装饰
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(cfg['icon'] as String, style: const TextStyle(fontSize: 32)),
                      const SizedBox(height: 8),
                      Text(
                        cfg['name'] as String,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Map<String, dynamic> _getSubjectConfig(String subject) {
    final configs = {
      'math': {'name': '数学·逻辑星图', 'icon': '🧮', 'color': AppTheme.mathColor, 'gradient': const LinearGradient(colors: [AppTheme.mathColor, Color(0xFF06B6D4)])},
      'chinese': {'name': '语文·文字飞船', 'icon': '📚', 'color': AppTheme.chineseColor, 'gradient': const LinearGradient(colors: [AppTheme.chineseColor, Color(0xFFEC4899)])},
      'english': {'name': '英语·外星语解码', 'icon': '🌍', 'color': AppTheme.englishColor, 'gradient': const LinearGradient(colors: [AppTheme.englishColor, Color(0xFF059669)])},
      'science': {'name': '科学·星球实验室', 'icon': '🔬', 'color': AppTheme.scienceColor, 'gradient': const LinearGradient(colors: [AppTheme.scienceColor, Color(0xFF6366F1)])},
    };
    return configs[subject] ?? configs['math']!;
  }
}

// 连线绘制器
class OrbitPainter extends CustomPainter {
  final List<Map<String, dynamic>> positions;
  
  OrbitPainter(this.positions);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.cyan.withOpacity(0.3)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    for (var i = 0; i < positions.length; i++) {
      for (var j = i + 1; j < positions.length; j++) {
        final p1 = positions[i];
        final p2 = positions[j];
        canvas.drawLine(
          Offset(p1['x'] * size.width, p1['y'] * size.height),
          Offset(p2['x'] * size.width, p2['y'] * size.height),
          paint,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
