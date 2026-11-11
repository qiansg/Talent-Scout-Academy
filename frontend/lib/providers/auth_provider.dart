// ============================================================
// Riverpod 状态管理 — AuthProvider
// PRD 规范: Riverpod + Riverpod Provider (类型安全, 可测试)
// 持久化: Hive (local NoSQL) — 替代 SharedPreferences
// ============================================================
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../services/auth_service.dart';
import '../services/hive_service.dart';

/// 用户模型
class UserModel {
  final String id;
  final String email;
  final String userType;
  final String nickname;
  final String avatar;
  final int? grade;

  UserModel({
    required this.id,
    required this.email,
    required this.userType,
    required this.nickname,
    required this.avatar,
    this.grade,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      userType: json['user_type']?.toString() ?? 'child',
      nickname: json['nickname']?.toString() ?? '小探险家',
      avatar: json['avatar']?.toString() ?? 'default',
      grade: json['grade'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'user_type': userType,
        'nickname': nickname,
        'avatar': avatar,
        'grade': grade,
      };
}

/// 认证状态（Riverpod Notifier 管理）
class AuthState {
  final UserModel? user;
  final String? token;
  final int starCoins;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.token,
    this.starCoins = 0,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    UserModel? user,
    String? token,
    int? starCoins,
    bool? isAuthenticated,
    bool clearUser = false,
    bool clearToken = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      token: clearToken ? null : (token ?? this.token),
      starCoins: starCoins ?? this.starCoins,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  bool get isChild => user?.userType == 'child';
  bool get isParent => user?.userType == 'parent';
}

/// Riverpod AsyncNotifier — 认证状态
final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<AuthState> {
  final AuthService _authService = AuthService();

  @override
  Future<AuthState> build() async {
    // 启动时从 Hive 恢复
    try {
      final authBox = Hive.box(HiveBoxes.auth);
      final token = authBox.get(HiveKeys.token) as String?;
      final userJson = authBox.get(HiveKeys.user) as String?;
      final coins = authBox.get(HiveKeys.starCoins, defaultValue: 0) as int;

      if (token != null && userJson != null) {
        final user = UserModel.fromJson(jsonDecode(userJson));
        return AuthState(
          token: token,
          user: user,
          starCoins: coins,
          isAuthenticated: true,
        );
      }
    } catch (_) {}
    return const AuthState();
  }

  /// 登录
  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      final result = await _authService.login(email: email, password: password);
      final token = result['token'] as String;
      final user = UserModel.fromJson(result['user'] as Map<String, dynamic>);
      final coins = result['star_coins'] ?? 0;

      // 持久化到 Hive
      final authBox = Hive.box(HiveBoxes.auth);
      await authBox.put(HiveKeys.token, token);
      await authBox.put(HiveKeys.user, jsonEncode(user.toJson()));
      await authBox.put(HiveKeys.starCoins, coins);

      state = AsyncData(AuthState(
        token: token,
        user: user,
        starCoins: coins,
        isAuthenticated: true,
      ));
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  /// 退出登录
  Future<void> logout() async {
    try {
      final authBox = Hive.box(HiveBoxes.auth);
      await authBox.deleteFromDisk();
      await Hive.openBox(HiveBoxes.auth); // 重新打开空 box
    } catch (_) {}
    state = const AsyncData(AuthState());
  }

  /// 更新星币（加）
  Future<void> addStarCoins(int amount) async {
    final current = state.valueOrNull ?? const AuthState();
    final newCoins = current.starCoins + amount;
    state = AsyncData(current.copyWith(
      starCoins: newCoins,
      isAuthenticated: current.isAuthenticated,
    ));
    try {
      await Hive.box(HiveBoxes.auth).put(HiveKeys.starCoins, newCoins);
    } catch (_) {}
  }

  /// 更新星币（直接设）
  Future<void> updateStarCoins(int coins) async {
    final current = state.valueOrNull ?? const AuthState();
    state = AsyncData(current.copyWith(
      starCoins: coins,
      isAuthenticated: current.isAuthenticated,
    ));
    try {
      await Hive.box(HiveBoxes.auth).put(HiveKeys.starCoins, coins);
    } catch (_) {}
  }
}

/// 便捷 provider: 当前登录用户（从 AsyncValue 解包）
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).valueOrNull?.user;
});

/// 便捷 provider: token
final authTokenProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).valueOrNull?.token;
});

/// 便捷 provider: 星币
final starCoinsProvider = Provider<int>((ref) {
  return ref.watch(authProvider).valueOrNull?.starCoins ?? 0;
});
