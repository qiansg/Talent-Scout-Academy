import 'package:flutter/material.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import 'task_play_page.dart';

/// 学科任务列表页
class SubjectTasksPage extends StatefulWidget {
  final String subject;
  const SubjectTasksPage({super.key, required this.subject});

  @override
  State<SubjectTasksPage> createState() => _SubjectTasksPageState();
}

class _SubjectTasksPageState extends State<SubjectTasksPage> {
  final TaskService _taskService = TaskService();
  List<dynamic> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _taskService.getSubjectTasks(widget.subject);
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _getSubjectConfig() {
    const configs = {
      'math': {'name': '数学·逻辑星图', 'icon': '🧮', 'color': AppTheme.mathColor, 'gradient': LinearGradient(colors: [AppTheme.mathColor, Color(0xFF06B6D4)])},
      'chinese': {'name': '语文·文字飞船', 'icon': '📚', 'color': AppTheme.chineseColor, 'gradient': LinearGradient(colors: [AppTheme.chineseColor, Color(0xFFEC4899)])},
      'english': {'name': '英语·外星语解码', 'icon': '🌍', 'color': AppTheme.englishColor, 'gradient': LinearGradient(colors: [AppTheme.englishColor, Color(0xFF059669)])},
      'science': {'name': '科学·星球实验室', 'icon': '🔬', 'color': AppTheme.scienceColor, 'gradient': LinearGradient(colors: [AppTheme.scienceColor, Color(0xFF6366F1)])},
    };
    return configs[widget.subject] ?? configs['math']!;
  }

  bool _isAvailable(int index) {
    if (index == 0) return true;
    return _tasks[index - 1]?['progress_status'] == 'completed';
  }

  @override
  Widget build(BuildContext context) {
    final config = _getSubjectConfig();
    final completed = _tasks.where((t) => t['progress_status'] == 'completed').length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.spaceBackground),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(config, completed),
              Expanded(child: _buildTaskList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> config, int completed) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(gradient: config['gradient']),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(config['icon'] as String, style: const TextStyle(fontSize: 40))),
          ),
          const SizedBox(height: 12),
          Text(config['name'] as String,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text('已完成 $completed / ${_tasks.length} 个任务',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.cyan));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        final available = _isAvailable(index);
        final isCompleted = task['progress_status'] == 'completed';
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: available
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskPlayPage(taskId: task['id']),
                      ),
                    ).then((_) => _loadTasks());
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isCompleted ? Colors.green.withOpacity(0.5) : Colors.white.withOpacity(0.15),
                ),
              ),
              child: Stack(
                children: [
                  Row(
                    children: [
                      // 序号
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: isCompleted
                              ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF34D399)])
                              : LinearGradient(
                                  colors: available
                                      ? [AppTheme.cyan, AppTheme.blue]
                                      : [Colors.white24, Colors.white10]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, color: Colors.white, size: 24)
                              : Text('${task['sequence_num'] ?? index + 1}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(task['title'] ?? '未知任务',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: available ? Colors.white : Colors.white30)),
                            const SizedBox(height: 4),
                            Text(task['description'] ?? '',
                                style: TextStyle(fontSize: 12, color: available ? Colors.white54 : Colors.white24),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildDifficulty(task['difficulty'] ?? 1),
                                const SizedBox(width: 12),
                                _buildReward(task['reward_coins'] ?? 0),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // 锁定遮罩
                  if (!available)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock, color: Colors.white54, size: 24),
                              SizedBox(height: 4),
                              Text('完成上一关解锁',
                                  style: TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDifficulty(int level) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => Icon(
        Icons.star,
        size: 14,
        color: i < level ? Colors.yellowAccent : Colors.white24,
      )),
    );
  }

  Widget _buildReward(int coins) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🪐', style: TextStyle(fontSize: 12)),
        const SizedBox(width: 2),
        Text('+$coins', style: const TextStyle(color: Colors.yellowAccent, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
