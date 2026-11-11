import '../services/api_client.dart';

/// 认证相关 API
class AuthService {
  final _dio = ApiClient().dio;

  /// 家长注册
  Future<Map<String, dynamic>> registerParent({
    required String email,
    required String password,
    String? nickname,
  }) async {
    final response = await _dio.post(
      '/auth/register/parent',
      data: {
        'email': email,
        'password': password,
        'nickname': nickname,
      },
    );
    return response.data;
  }

  /// 为家长添加孩子
  Future<Map<String, dynamic>> addChild({
    required String nickname,
    int? grade,
  }) async {
    final response = await _dio.post(
      '/auth/register/child',
      data: {
        'nickname': nickname,
        'grade': grade,
      },
    );
    return response.data;
  }

  /// 登录
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );
    return response.data;
  }

  /// 获取当前用户
  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/auth/me');
    return response.data;
  }
}
