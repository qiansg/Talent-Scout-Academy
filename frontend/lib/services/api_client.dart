// ============================================================
// API 客户端 — Dio + Hive 持久化 + 多环境切换
// PRD 规范: Dio 网络层 + Hive 离线存储
// ============================================================
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'hive_service.dart';

class ApiConfig {
  static const String sameOrigin = '/api';
  static const String localhost = 'http://localhost:3001/api';
  static const String emulatorAndroid = 'http://10.0.2.2:3001/api';
  static const String emulatorIOS = 'http://localhost:3001/api';

  // 方案 A: adb reverse（USB 连接，推荐开发用，无需同 WiFi）
  //   adb reverse tcp:3001 tcp:3001
  //   真机 localhost:3001 → 电脑 localhost:3001
  static const String adbReverse = 'http://localhost:3001/api';

  // 方案 B: 同 WiFi 直连
  //   把 realDevice 改成你电脑的局域网 IP
  //   Windows → cmd: ipconfig → IPv4 地址
  //   macOS   → term: ifconfig | grep "inet " | grep -v 127
  //   Linux   → term: hostname -I
  static const String realDevice = 'http://10.58.53.78:3001/api';

  static const String tunnel = 'https://your-tunnel.ngrok-free.app/api';
  static const String production = 'https://api.starexplorer.com/api';

  static String autoDetect() {
    if (kIsWeb) return sameOrigin;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // 默认 adb reverse（USB 连接）
        // 同 WiFi 直连改 return realDevice;
        return adbReverse;
      case TargetPlatform.iOS:
        return localhost;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return localhost;
      default:
        return localhost;
    }
  }
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  Dio? _dio;
  String _baseUrl = ApiConfig.autoDetect();
  bool _initialized = false;

  Future<void> init({String? baseUrlOverride}) async {
    if (baseUrlOverride != null && baseUrlOverride.isNotEmpty) {
      _baseUrl = baseUrlOverride;
    } else {
      try {
        final savedUrl = Hive.box(HiveBoxes.apiConfig).get(HiveKeys.customApiBaseUrl) as String?;
        if (savedUrl != null && savedUrl.isNotEmpty) {
          _baseUrl = savedUrl;
        } else {
          _baseUrl = ApiConfig.autoDetect();
        }
      } catch (_) {
        _baseUrl = ApiConfig.autoDetect();
      }
    }
    _initDio();
    _initialized = true;
    debugPrint('🛰️ Star Explorer API → $_baseUrl');
  }

  void _initDio() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Token 自动注入（从 Hive 读，兼容非 Riverpod 调用场景）
    _dio!.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final token = Hive.box(HiveBoxes.auth).get(HiveKeys.token) as String?;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (_) {}
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          try {
            Hive.box(HiveBoxes.auth).deleteFromDisk();
          } catch (_) {}
        }
        if (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout) {
          debugPrint('⚠️ API 连接失败 → $_baseUrl');
        }
        handler.next(error);
      },
    ));

    if (kDebugMode) {
      _dio!.interceptors.add(LogInterceptor(
        requestHeader: false,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ));
    }
  }

  // ======== 运行时 API 地址管理 ========
  Future<void> setBaseUrl(String url, {bool persist = true}) async {
    _baseUrl = url;
    if (persist) {
      try {
        await Hive.box(HiveBoxes.apiConfig).put(HiveKeys.customApiBaseUrl, url);
      } catch (_) {}
    }
    _initDio();
    debugPrint('🔄 API 地址切换为: $url');
  }

  Future<void> resetBaseUrl() async {
    try {
      await Hive.box(HiveBoxes.apiConfig).delete(HiveKeys.customApiBaseUrl);
    } catch (_) {}
    _baseUrl = ApiConfig.autoDetect();
    _initDio();
    debugPrint('↩️ 已重置为平台默认: $_baseUrl');
  }

  Future<(bool, int?)> testConnection() async {
    try {
      final stopwatch = Stopwatch()..start();
      await Dio().get('$_baseUrl/health',
          options: Options(connectTimeout: const Duration(seconds: 5)));
      stopwatch.stop();
      return (true, stopwatch.elapsedMilliseconds);
    } catch (_) {
      return (false, null);
    }
  }

  Dio get dio {
    if (!_initialized || _dio == null) {
      _initDio();
      _initialized = true;
    }
    return _dio!;
  }

  String get baseUrl => _baseUrl;
}
