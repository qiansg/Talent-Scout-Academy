import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';

/// 🔧 API 地址设置页（调试用）
/// 在"我的"页面点击头像区域 5 次可进入
class ApiSettingsPage extends StatefulWidget {
  const ApiSettingsPage({super.key});

  @override
  State<ApiSettingsPage> createState() => _ApiSettingsPageState();
}

class _ApiSettingsPageState extends State<ApiSettingsPage> {
  final ApiClient _api = ApiClient();
  final TextEditingController _controller = TextEditingController();
  bool _testing = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _controller.text = _api.baseUrl;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 测试连接
  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    
    try {
      final testDio = Dio(BaseOptions(
        baseUrl: _controller.text.trim(),
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      
      final response = await testDio.get('/health');
      if (response.data?['status'] == 'ok') {
        setState(() {
          _testSuccess = true;
          _testResult = '✅ 连接成功！后端版本: ${response.data['version'] ?? 'unknown'}';
        });
      } else {
        setState(() {
          _testSuccess = false;
          _testResult = '⚠️ 响应异常，但服务器可访问';
        });
      }
    } catch (e) {
      setState(() {
        _testSuccess = false;
        _testResult = '❌ 连接失败: ${_extractError(e.toString())}';
      });
    } finally {
      setState(() => _testing = false);
    }
  }

  String _extractError(String msg) {
    if (msg.contains('SocketException')) return '网络不可达，请检查地址和端口';
    if (msg.contains('Connection refused')) return '连接被拒绝，后端可能未启动';
    if (msg.contains('TimeoutException')) return '连接超时，请检查网络';
    if (msg.contains('404')) return '接口不存在，请确认 /api 路径';
    return '未知错误';
  }

  // 保存并应用
  Future<void> _save() async {
    await _api.setBaseUrl(_controller.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ API 地址已保存，重启应用生效')),
      );
      Navigator.pop(context);
    }
  }

  // 使用预设
  void _usePreset(String url) {
    setState(() => _controller.text = url);
  }

  // 重置
  Future<void> _reset() async {
    await _api.resetBaseUrl();
    if (mounted) {
      setState(() => _controller.text = _api.baseUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已重置为默认地址')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.spaceBackground),
        child: SafeArea(
          child: Column(
            children: [
              // 顶部栏
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('🔧 API 服务器设置',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // 当前状态
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.glassCard,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline, color: AppTheme.cyan),
                              const SizedBox(width: 8),
                              const Text('当前连接',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(_api.baseUrl,
                                      style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                          color: AppTheme.cyan)),
                                ),
                                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 地址输入
                    const Text('自定义地址',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'http://your-server:3001/api',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.cyan, width: 2),
                        ),
                        prefixIcon: const Icon(Icons.link, color: AppTheme.cyan),
                      ),
                      style: const TextStyle(fontFamily: 'monospace', color: Colors.white),
                    ),

                    const SizedBox(height: 12),

                    // 测试结果
                    if (_testResult != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _testSuccess
                              ? Colors.green.withOpacity(0.15)
                              : Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _testSuccess
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.red.withOpacity(0.3)),
                        ),
                        child: Text(_testResult!,
                            style: TextStyle(
                                color: _testSuccess ? Colors.greenAccent : Colors.redAccent,
                                fontSize: 13)),
                      ),

                    const SizedBox(height: 20),

                    // 快速预设
                    const Text('快速预设',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildPresetButton('📍 Android 模拟器', 'http://10.0.2.2:3001/api'),
                    _buildPresetButton('📍 iOS 模拟器', 'http://localhost:3001/api'),
                    _buildPresetButton('💻 Windows/Chrome', 'http://localhost:3001/api'),
                    _buildPresetButton('📶 真机（WiFi）', ApiConfig.realDevice),
                    _buildPresetButton('🔗 Ngrok 穿透', ApiConfig.tunnel),

                    const SizedBox(height: 20),

                    // 说明
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('📘 真机连接指南',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.cyan)),
                          SizedBox(height: 10),
                          Text(
                              '1. 确保手机和电脑在同一 WiFi\n'
                              '2. 电脑运行: ipconfig (Windows) 或 ifconfig (Mac/Linux)\n'
                              '3. 找到 IPv4 地址 (如 192.168.1.100)\n'
                              '4. 填入: http://那个IP:3001/api\n'
                              '5. 或用 ngrok: ngrok http 3001\n'
                              '   然后填入 https://xxx.ngrok-free.app/api',
                              style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.8)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),

              // 底部按钮
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.spaceBlue.withOpacity(0.95),
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _reset,
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('重置'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: BorderSide(color: Colors.white.withOpacity(0.2)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _testing ? null : _testConnection,
                          icon: _testing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.wifi_find),
                          label: Text(_testing ? '测试中...' : '测试连接'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.save),
                          label: const Text('保存'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.cyan,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ));
    }

  Widget _buildPresetButton(String label, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _usePreset(url),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(url,
                        style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: Colors.white54)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}
