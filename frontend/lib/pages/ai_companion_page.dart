import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/ai_companion_service.dart';
import '../theme/app_theme.dart';

/// AI 学伴星仔对话页
class AICompanionPage extends ConsumerStatefulWidget {
  const AICompanionPage({super.key});

  @override
  ConsumerState<AICompanionPage> createState() => _AICompanionPageState();
}

class _AICompanionPageState extends ConsumerState<AICompanionPage> {
  final AICompanionService _aiService = AICompanionService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<_ChatMessage> _messages = [];
  List<String> _suggestions = [];
  String _emotion = 'happy';
  bool _isLoading = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    try {
      final greeting = await _aiService.getGreeting();
      setState(() {
        _messages.add(_ChatMessage(
          role: 'assistant',
          text: greeting['greeting'] ?? '嘿！小探险家！今天想探索什么呢？',
          emotion: greeting['star_pose'] ?? 'happy',
          time: DateTime.now(),
        ));
        _emotion = greeting['star_pose'] ?? 'happy';
      });
    } catch (_) {
      setState(() {
        _messages.add(_ChatMessage(
          role: 'assistant',
          text: '嘿！小探险家！今天想探索什么呢？',
          emotion: 'happy',
          time: DateTime.now(),
        ));
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? text]) async {
    final message = text ?? _inputController.text.trim();
    if (message.isEmpty || _isLoading) return;
    
    setState(() {
      _messages.add(_ChatMessage(
        role: 'user',
        text: message,
        time: DateTime.now(),
      ));
      _inputController.clear();
      _isLoading = true;
    });
    _scrollToBottom();
    
    try {
      final result = await _aiService.sendMessage(message: message);
      setState(() {
        _messages.add(_ChatMessage(
          role: 'assistant',
          text: result['reply'] ?? '嗯嗯...我再想想~',
          emotion: result['emotion'] ?? 'happy',
          time: DateTime.now(),
        ));
        _emotion = result['emotion'] ?? 'happy';
        _suggestions = (result['suggestions'] as List?)?.cast<String>() ?? [];
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (_) {
      setState(() {
        _messages.add(_ChatMessage(
          role: 'assistant',
          text: '哎呀，星仔的通讯器好像出问题了~',
          emotion: 'sad',
          time: DateTime.now(),
        ));
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.spaceBackground),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildMessageList()),
            if (_suggestions.isNotEmpty) _buildSuggestions(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final expression = _getExpression();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(gradient: expression.gradient),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const SizedBox(width: 8),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(child: Text(expression.emoji, style: const TextStyle(fontSize: 32))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('星仔',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('你的专属AI学伴 · ${expression.label}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wb_sunny, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text('在线', style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StarExpression _getExpression() {
    final expressions = {
      'happy': _StarExpression('😊', '开心', const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C42)])),
      'cheerful': _StarExpression('😄', '活泼', const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C42)])),
      'teaching': _StarExpression('📚', '教学中', const LinearGradient(colors: [AppTheme.cyan, AppTheme.blue])),
      'thinking': _StarExpression('🤔', '思考中', const LinearGradient(colors: [AppTheme.purple, Color(0xFFEC4899)])),
      'caring': _StarExpression('🥰', '关心你', const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)])),
      'sad': _StarExpression('😢', '小失落', const LinearGradient(colors: [Colors.grey, Colors.blueGrey])),
      'encouraging': _StarExpression('💪', '加油中', const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])),
    };
    return expressions[_emotion] ?? expressions['happy']!;
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isLoading && index == _messages.length) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    final isUser = msg.role == 'user';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: isUser
                  ? const LinearGradient(colors: [AppTheme.cyan, AppTheme.blue])
                  : const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C42)]),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(isUser ? '👦' : '⭐', style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),
          // 气泡
          Expanded(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppTheme.cyan
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.white,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(msg.time),
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C42)]),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('⭐', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(),
                const SizedBox(width: 4),
                _buildDot(delay: 0.2),
                const SizedBox(width: 4),
                _buildDot(delay: 0.4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot({double delay = 0}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Colors.white60,
        shape: BoxShape.circle,
      ),
      child: const SizedBox.shrink(),
    );
  }

  Widget _buildSuggestions() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _sendMessage(_suggestions[index]),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Text(_suggestions[index],
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.spaceBlue.withOpacity(0.95),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 语音按钮
            GestureDetector(
              onLongPressStart: (_) => setState(() => _isRecording = true),
              onLongPressEnd: (_) => setState(() => _isRecording = false),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _isRecording ? Colors.red : Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.mic, color: _isRecording ? Colors.white : Colors.white70),
              ),
            ),
            const SizedBox(width: 10),
            // 输入框
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: TextField(
                  controller: _inputController,
                  decoration: const InputDecoration(
                    hintText: '问问星仔...',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // 发送按钮
            GestureDetector(
              onTap: () => _sendMessage(),
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.cyan, AppTheme.blue]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppTheme.cyan, blurRadius: 12)],
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _ChatMessage {
  final String role; // 'user' | 'assistant'
  final String text;
  final String emotion;
  final DateTime time;

  _ChatMessage({
    required this.role,
    required this.text,
    this.emotion = 'happy',
    required this.time,
  });
}

class _StarExpression {
  final String emoji;
  final String label;
  final Gradient gradient;
  _StarExpression(this.emoji, this.label, this.gradient);
}
