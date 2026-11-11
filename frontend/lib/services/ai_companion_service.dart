import '../services/api_client.dart';

/// AI 学伴 API
class AICompanionService {
  final _dio = ApiClient().dio;

  /// 获取开场白
  Future<Map<String, dynamic>> getGreeting() async {
    final response = await _dio.get('/ai/greeting');
    return response.data;
  }

  /// 发送消息给星仔
  Future<Map<String, dynamic>> sendMessage({
    required String message,
    String? subject,
  }) async {
    final response = await _dio.post(
      '/ai/chat',
      data: {
        'message': message,
        'subject': subject,
      },
    );
    return response.data;
  }

  /// 获取对话历史
  Future<List<dynamic>> getHistory({int limit = 50}) async {
    final response = await _dio.get(
      '/ai/history',
      queryParameters: {'limit': limit},
    );
    return response.data['conversations'] ?? [];
  }

  /// 获取情绪分析
  Future<Map<String, dynamic>> getEmotion() async {
    final response = await _dio.get('/ai/emotion');
    return response.data;
  }
}
