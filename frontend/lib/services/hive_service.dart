// ============================================================
// Hive 本地数据库初始化
// PRD 规范: 离线能力 — Hive (轻量级 NoSQL)
// 用途: 关卡进度、用户配置、离线缓存、token 持久化
// ============================================================
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Hive Box 名称常量
class HiveBoxes {
  static const String auth = 'star_auth';        // 认证信息 (token + user)
  static const String cache = 'star_cache';      // API 响应缓存
  static const String tasks = 'star_tasks';      // 关卡进度离线缓存
  static const String settings = 'star_settings'; // 用户设置
  static const String apiConfig = 'star_api_config'; // API 地址覆盖
}

class HiveKeys {
  // auth box
  static const String token = 'token';
  static const String user = 'user';
  static const String starCoins = 'star_coins';
  // apiConfig box
  static const String customApiBaseUrl = 'custom_api_base_url';
}

/// 应用启动时调用一次
Future<void> initHive() async {
  // Web 用内存路径；Mobile 用默认文档目录
  await Hive.initFlutter();

  // 打开所需 Box（lazy=false 同步打开）
  await Hive.openBox(HiveBoxes.auth);
  await Hive.openBox(HiveBoxes.cache);
  await Hive.openBox(HiveBoxes.tasks);
  await Hive.openBox(HiveBoxes.settings);
  await Hive.openBox(HiveBoxes.apiConfig);

  debugPrint('💾 Hive initialized — 5 boxes ready');
}

/// 关闭（应用退出时）
Future<void> closeHive() async {
  await Hive.close();
}
