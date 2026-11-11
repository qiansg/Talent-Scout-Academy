import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'star_map_page.dart';
import 'ai_companion_page.dart';
import 'profile_page.dart';

/// 登录页面
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      await ref.read(authProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (mounted) {
        // 登录成功后，AuthWrapper 会自动跳转
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _error = _extractError(e.toString());
        _isLoading = false;
      });
    }
  }

  String _extractError(String errorStr) {
    // 简化错误信息
    if (errorStr.contains('401')) return '邮箱或密码错误';
    if (errorStr.contains('400')) return '请输入正确的邮箱和密码';
    if (errorStr.contains('409')) return '该邮箱已注册';
    return '登录失败，请稍后再试';
  }

  void _fillDemo(String type) {
    if (type == 'child') {
      _emailController.text = 'child@demo.com';
      _passwordController.text = '123456';
    } else {
      _emailController.text = 'parent@demo.com';
      _passwordController.text = '123456';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.spaceBackground),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 60),
                
                // Logo 区域
                _buildLogo(),
                
                const SizedBox(height: 40),
                
                // 登录表单
                _buildForm(),
                
                const SizedBox(height: 24),
                
                // 快速登录按钮
                _buildQuickLogin(),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.cyan, AppTheme.blue, AppTheme.purple],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.cyan.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.star, color: Colors.yellowAccent, size: 50),
        ),
        const SizedBox(height: 20),
        Text(
          '星探学院',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [Color(0xFFFFE066), Color(0xFFFF8C42)],
              ).createShader(const Rect.fromLTWH(0, 0, 200, 50)),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '在探索中学习，在创造中成长',
          style: TextStyle(color: Colors.white60, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassCard,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '欢迎回来，小探险家！',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // 错误提示
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                  ],
                ),
              ),
            if (_error != null) const SizedBox(height: 16),

            // 邮箱
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: '邮箱',
                hintText: 'your@email.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return '请输入邮箱';
                if (!value.contains('@')) return '邮箱格式不正确';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 密码
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '密码',
                hintText: '请输入密码',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return '请输入密码';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // 登录按钮
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.rocket_launch_rounded),
                label: Text(_isLoading ? '登录中...' : '启动飞船'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cyan,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: AppTheme.cyan.withOpacity(0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLogin() {
    return Column(
      children: [
        const Text('快速体验', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDemoButton('👦 孩子体验', () => _fillDemo('child')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDemoButton('👨‍👩‍👧 家长体验', () => _fillDemo('parent'), isParent: true),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDemoButton(String label, VoidCallback onTap, {bool isParent = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: isParent
                ? [const Color(0xFF8B5CF6).withOpacity(0.3), const Color(0xFFEC4899).withOpacity(0.3)]
                : [AppTheme.cyan.withOpacity(0.3), AppTheme.blue.withOpacity(0.3)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isParent
                ? const Color(0xFF8B5CF6).withOpacity(0.4)
                : AppTheme.cyan.withOpacity(0.4),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
