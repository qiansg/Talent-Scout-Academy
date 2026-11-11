import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';

/// 个人中心页
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final TaskService _taskService = TaskService();
  Map<String, dynamic> _stats = {};
  List<dynamic> _badges = [];
  int _currentTab = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait<dynamic>([
        _taskService.getStats(),
        _taskService.getBadges(),
      ]);
      if (mounted) {
        setState(() {
          final statsData = results[0] as Map<String, dynamic>;
          final badgesData = results[1] as List<dynamic>;
          _stats = statsData['stats'] ?? {};
          _badges = badgesData;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider).valueOrNull!;
    
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.spaceBackground),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(auth),
              _buildTabs(),
              Expanded(child: _buildTabContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(auth) {
    final level = ((_stats['total_completed'] ?? 0) ~/ 2) + 1;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1A1F3A), Color(0xFF2D1B4E)]),
      ),
      child: Row(
        children: [
          // 头像
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.cyan, AppTheme.blue]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppTheme.cyan.withOpacity(0.3), blurRadius: 20)],
            ),
            child: const Icon(Icons.person, size: 36, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(auth.user?.nickname ?? '小探险家',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text('探险家 Lv.$level',
                        style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                // 经验条
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ((_stats['total_completed'] ?? 0) % 2) * 0.5 + 0.25,
                    backgroundColor: Colors.white10,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = ['概览', '勋章', '日志'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isActive = _currentTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentTab = i),
              child: Column(
                children: [
                  Text(
                    tabs[i],
                    style: TextStyle(
                      color: isActive ? AppTheme.cyan : Colors.white54,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 40,
                    height: 3,
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.cyan : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.cyan));
    }
    
    switch (_currentTab) {
      case 0: return _buildOverview();
      case 1: return _buildBadges();
      case 2: return _buildLogs();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildOverview() {
    final subjectStats = _stats['subject_stats'] as List? ?? [];
    final subjectNames = {'math': '数学', 'chinese': '语文', 'english': '英语', 'science': '科学'};
    final subjectIcons = {'math': '🧮', 'chinese': '📚', 'english': '🌍', 'science': '🔬'};
    final subjectColors = {'math': AppTheme.mathColor, 'chinese': AppTheme.chineseColor, 'english': AppTheme.englishColor, 'science': AppTheme.scienceColor};
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 数据卡片
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _buildStatCard('🪐', '星币', '${ref.watch(authProvider).valueOrNull!.starCoins}', Colors.yellow),
            _buildStatCard('🏅', '勋章', '${_badges.where((b) => b['earned'] == true).length}', Colors.orange),
            _buildStatCard('🎯', '任务', '${_stats['total_completed'] ?? 0}', AppTheme.cyan),
            _buildStatCard('⏱️', '学习', '${((_stats['total_seconds'] ?? 0) ~/ 60)}分', AppTheme.purple),
          ],
        ),
        const SizedBox(height: 20),
        
        // 学科进度
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.glassCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📊 各学科进度', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              for (var subject in ['math', 'chinese', 'english', 'science']) ...[
                _buildSubjectProgress(
                  subjectIcons[subject] ?? '📖',
                  subjectNames[subject] ?? subject,
                  subjectStats.firstWhere((s) => s['subject'] == subject, orElse: () => {'count': 0})['count'] ?? 0,
                  subjectColors[subject] ?? Colors.white,
                ),
                if (subject != 'science') const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        _buildSettings(),
        const SizedBox(height: 20),
        _buildLogoutButton(),
      ],
    );
  }

  Widget _buildStatCard(String icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSubjectProgress(String icon, String name, int count, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('$count 个任务', style: const TextStyle(fontSize: 12, color: Colors.white54)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: count * 0.33,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildSettings() {
    final items = [
      {'icon': Icons.settings, 'label': '账号设置', 'color': Colors.grey},
      {'icon': Icons.notifications, 'label': '消息通知', 'color': Colors.yellow},
      {'icon': Icons.security, 'label': '安全与隐私', 'color': Colors.green},
      {'icon': Icons.help_outline, 'label': '帮助中心', 'color': Colors.blue},
    ];
    
    return Container(
      decoration: AppTheme.glassCard,
      child: Column(
        children: items.map((item) {
          return ListTile(
            leading: Icon(item['icon'] as IconData, color: item['color'] as Color),
            title: Text(item['label'] as String),
            trailing: const Icon(Icons.chevron_right, color: Colors.white38),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppTheme.spaceBlue,
            title: const Text('确认退出？'),
            content: const Text('确定要退出登录吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消', style: TextStyle(color: Colors.white54)),
              ),
              TextButton(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                },
                child: const Text('退出', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('退出登录', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildBadges() {
    final earned = _badges.where((b) => b['earned'] == true).length;
    final total = _badges.length;
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('已获得 $earned / $total 枚勋章',
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _badges.length,
            itemBuilder: (context, index) {
              final badge = _badges[index];
              final isEarned = badge['earned'] == true;
              return Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: isEarned
                          ? const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C42)])
                          : const LinearGradient(colors: [Colors.white24, Colors.white12]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isEarned
                          ? [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 15)]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        badge['icon'] ?? '🏅',
                        style: TextStyle(fontSize: 32, color: isEarned ? Colors.white : Colors.white24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    badge['name'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isEarned ? Colors.white : Colors.white30,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLogs() {
    final logs = _stats['recent_logs'] as List? ?? [];
    
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📝', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('暂无学习记录', style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final accuracy = log['accuracy'] ?? 0;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.glassCard,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log['task_title'] ?? '任务',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      log['created_at'] ?? '',
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accuracy == 1
                      ? Colors.green.withOpacity(0.2)
                      : accuracy > 0
                          ? Colors.yellow.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  accuracy == 1 ? '掌握' : accuracy > 0 ? '练习' : '继续加油',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: accuracy == 1
                        ? Colors.green
                        : accuracy > 0
                            ? Colors.yellow
                            : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
