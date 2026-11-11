import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';

/// 关卡游玩页 - 5阶段流程
class TaskPlayPage extends ConsumerStatefulWidget {
  final String taskId;
  const TaskPlayPage({super.key, required this.taskId});

  @override
  ConsumerState<TaskPlayPage> createState() => _TaskPlayPageState();
}

class _TaskPlayPageState extends ConsumerState<TaskPlayPage> {
  final TaskService _taskService = TaskService();
  
  Map<String, dynamic>? _task;
  bool _isLoading = true;
  int _currentStage = 0;
  int _attempts = 0;
  
  // 测量
  int? _length;
  int? _width;
  final List<Map<String, String>> _formula = [];
  
  bool _showSuccess = false;
  String? _feedback;
  bool _feedbackSuccess = false;

  final _stages = [
    {'id': 'intro', 'name': '情境引入'},
    {'id': 'explore', 'name': '探索阶段'},
    {'id': 'reason', 'name': '推理阶段'},
    {'id': 'verify', 'name': '验证阶段'},
    {'id': 'summary', 'name': '总结拓展'},
  ];

  final _formulaBlocks = [
    {'id': 'L', 'label': '长'},
    {'id': 'W', 'label': '宽'},
    {'id': 'L2', 'label': '长+宽'},
    {'id': '+', 'label': '+'},
    {'id': '×', 'label': '×'},
    {'id': '2', 'label': '2'},
    {'id': '(L+W)×2', 'label': '(长+宽)×2'},
    {'id': 'L+W+L+W', 'label': '四条边相加'},
  ];

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    setState(() => _isLoading = true);
    try {
      final task = await _taskService.getTaskDetail(widget.taskId);
      await _taskService.startTask(widget.taskId);
      if (mounted) {
        setState(() {
          _task = task;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goNextStage() {
    if (_currentStage < _stages.length - 1) {
      setState(() {
        _currentStage++;
        _feedback = null;
      });
    }
  }

  void _simulateMeasure(String side) {
    final value = (8 + DateTime.now().millisecond % 4);
    setState(() {
      if (side == 'length') _length = value;
      if (side == 'width') _width = 5 + DateTime.now().millisecond % 2;
    });
  }

  void _addFormula(Map<String, String> block) {
    if (_formula.length >= 4) return;
    setState(() => _formula.add(block));
  }

  void _removeFormula(int index) {
    setState(() => _formula.removeAt(index));
  }

  Future<void> _verifyFormula() async {
    setState(() => _feedback = null);
    _attempts++;
    
    final formulaStr = _formula.map((b) => b['id']).join('');
    final isCorrect = formulaStr.contains('(L+W)×2') || formulaStr.contains('L+W+L+W');
    
    if (isCorrect) {
      final perimeter = ((_length ?? 8) + (_width ?? 5)) * 2;
      
      setState(() {
        _feedback = '太棒了！能量栅栏启动成功！';
        _feedbackSuccess = true;
      });
      
      try {
        final result = await _taskService.submitTask(
          taskId: widget.taskId,
          answer: perimeter,
          durationSeconds: 300,
          emotion: 'happy',
        );
        
        if (result['rewards'] != null && mounted) {
          ref.read(authProvider.notifier).addStarCoins(result['rewards']['coins'] ?? 0);
          await Future.delayed(const Duration(milliseconds: 1500));
          if (mounted) setState(() => _showSuccess = true);
        }
      } catch (_) {}
    } else {
      setState(() {
        _feedback = '能量过载！这个公式不太对...';
        _feedbackSuccess = false;
      });
      if (_attempts >= 2) {
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() {
          // 显示提示但不自动跳转
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.cyan)),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.spaceBackground),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildProgressBar(),
              Expanded(child: _buildContent()),
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_task?['title'] ?? '任务',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('步骤 ${_currentStage + 1}/${_stages.length}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
            child: const Text('🧮', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(_stages.length, (i) {
          return Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.symmetric(horizontal: i == 0 ? 0 : 2),
              decoration: BoxDecoration(
                color: i < _currentStage
                    ? Colors.greenAccent
                    : i == _currentStage
                        ? AppTheme.cyan
                        : Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSceneArea(),
        const SizedBox(height: 16),
        _buildStageContent(),
      ],
    );
  }

  Widget _buildSceneArea() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.spaceBlue, AppTheme.spacePurple]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // 背景星光
          const DecoratedBox(decoration: BoxDecoration()),
          
          // 阶段场景
          Center(child: _buildStageScene()),
          
          // 星仔形象
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C42)]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0xFFFF8C42), blurRadius: 15)],
              ),
              child: const Icon(Icons.star, color: Colors.white, size: 28),
            ),
          ),
          
          // 反馈
          if (_feedback != null)
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _feedbackSuccess ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_feedback!,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStageScene() {
    switch (_stages[_currentStage]['id']) {
      case 'intro':
        return const Icon(Icons.rocket_launch, size: 72, color: Colors.white70);
      case 'explore':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌾', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            if (_length != null) Text('长: $_length m', style: const TextStyle(color: Colors.blueAccent)),
            if (_width != null) Text('宽: $_width m', style: const TextStyle(color: Colors.greenAccent)),
          ],
        );
      case 'reason':
        return _formula.isEmpty
            ? const Text('从下方选择积木', style: TextStyle(color: Colors.white30))
            : Wrap(
                spacing: 8,
                children: _formula.map((b) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.cyan, AppTheme.blue]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(b['label']!,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  );
                }).toList(),
              );
      case 'verify':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt, size: 56, color: Colors.yellowAccent),
            const SizedBox(height: 8),
            const Text('能量栅栏启动中...',
                style: TextStyle(fontSize: 14, color: Colors.white70)),
          ],
        );
      case 'summary':
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, size: 56, color: Colors.yellowAccent),
            SizedBox(height: 8),
            Text('任务完成！', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStageContent() {
    switch (_stages[_currentStage]['id']) {
      case 'intro':
        return _buildIntroContent();
      case 'explore':
        return _buildExploreContent();
      case 'reason':
        return _buildReasonContent();
      case 'verify':
        return _buildVerifyContent();
      case 'summary':
        return _buildSummaryContent();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIntroContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🚀 任务背景', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('星际农场遭遇陨石撞击，防护罩破损！\n作为"星际维修工程师"，你需要计算能量栅栏的长度，帮助农场恢复防护！',
              style: const TextStyle(color: Colors.white70, height: 1.6)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.yellow.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.yellow.withOpacity(0.3)),
                  ),
                  child: const Column(
                    children: [
                      Text('奖励', style: TextStyle(color: Colors.yellowAccent, fontSize: 11)),
                      Text('⭐ 50 星币', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                  ),
                  child: const Column(
                    children: [
                      Text('勋章', style: TextStyle(color: Colors.purpleAccent, fontSize: 11)),
                      Text('🏅 维修工', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExploreContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📏 探索：使用卷尺测量',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('按住卷尺拖动到农场边缘，松开后自动显示数值',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 16),
          _buildMeasureButton('测量长边', _length, 'length', Colors.blue),
          const SizedBox(height: 10),
          _buildMeasureButton('测量短边', _width, 'width', Colors.green),
        ],
      ),
    );
  }

  Widget _buildMeasureButton(String label, int? value, String side, Color color) {
    return GestureDetector(
      onTap: () => _simulateMeasure(side),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Text('📏', style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            Text(
              value != null ? '$value m' : '未测量',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: value != null ? color : Colors.white24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🧩 推理：拼出正确公式',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('从下方选择积木，拼出计算周长的公式',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 16),
          // 已选区域
          Container(
            height: 60,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: _formula.isEmpty
                ? const Center(child: Text('点击下方积木添加...', style: TextStyle(color: Colors.white30)))
                : Row(children: [
                    for (var i = 0; i < _formula.length; i++) ...[
                      GestureDetector(
                        onTap: () => _removeFormula(i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppTheme.cyan, AppTheme.blue]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${_formula[i]['label']} ✕',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                      if (i < _formula.length - 1) const SizedBox(width: 6),
                    ],
                  ]),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _formulaBlocks.map((b) => GestureDetector(
              onTap: () => _addFormula(b),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(b['label']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyContent() {
    final perimeter = ((_length ?? 8) + (_width ?? 5)) * 2;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard,
      child: Column(
        children: [
          const Text('⚡ 验证结果', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('计算结果', style: TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 4),
                Text('周长 = $perimeter 米',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.cyan)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📝 总结与拓展', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildSummaryItem('📖 知识点', '长方形周长 = (长 + 宽) × 2', Colors.cyan),
          const SizedBox(height: 12),
          _buildSummaryItem('🎯 现实挑战', '用绳子围一围家里的书本或相框，量一量周长！', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String content, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final stage = _stages[_currentStage]['id'];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.spaceBlue.withOpacity(0.95),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 提示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.yellow.withOpacity(0.3)),
              ),
              child: const Icon(Icons.lightbulb, color: Colors.yellowAccent),
            ),
            const SizedBox(width: 12),
            
            // 主按钮
            Expanded(
              child: ElevatedButton(
                onPressed: _handleMainAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(_getButtonLabel(stage!)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getButtonLabel(String stage) {
    switch (stage) {
      case 'intro': return '🚀 开始任务';
      case 'explore': return (_length != null && _width != null) ? '开始推理 →' : '🚀 继续';
      case 'reason': return _formula.isNotEmpty ? '⚡ 启动验证' : '🚀 继续';
      case 'verify': return '查看结果 →';
      case 'summary': return '✨ 完成';
      default: return '继续';
    }
  }

  void _handleMainAction() {
    final stage = _stages[_currentStage]['id'];
    switch (stage) {
      case 'reason':
        _verifyFormula();
        break;
      case 'summary':
        Navigator.pop(context);
        break;
      default:
        _goNextStage();
    }
  }
}
