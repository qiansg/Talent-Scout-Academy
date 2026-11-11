import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/api_client.dart';
import 'services/hive_service.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
import 'pages/login_page.dart';
import 'pages/star_map_page.dart';
import 'pages/ai_companion_page.dart';
import 'pages/profile_page.dart';
import 'pages/api_settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // PRD 规范: Hive 离线存储初始化
  await initHive();

  // API 客户端初始化（读取 Hive 保存的地址）
  await ApiClient().init();

  runApp(const ProviderScope(child: StarExplorerApp()));
}

class StarExplorerApp extends StatelessWidget {
  const StarExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '星探学院',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}

/// 根据认证状态切换首页（Riverpod AsyncValue 监听）
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);

    return authAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.cyan)),
      ),
      error: (_, __) => const LoginPage(),
      data: (auth) {
        if (!auth.isAuthenticated) return const LoginPage();
        if (auth.isParent) return const LoginPage();
        return const MainScaffold();
      },
    );
  }
}

/// 孩子端主框架（带底部导航）
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  int _profileHeaderTaps = 0;
  DateTime? _lastProfileTap;

  final _pages = const [
    StarMapPage(),
    AICompanionPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          if (_currentIndex == 2)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 100,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  final now = DateTime.now();
                  if (_lastProfileTap != null &&
                      now.difference(_lastProfileTap!).inMilliseconds < 500) {
                    _profileHeaderTaps++;
                  } else {
                    _profileHeaderTaps = 1;
                  }
                  _lastProfileTap = now;
                  if (_profileHeaderTaps >= 5) {
                    _profileHeaderTaps = 0;
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ApiSettingsPage()),
                    );
                  }
                },
                child: const SizedBox.expand(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A).withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, Icons.rocket_launch_rounded, '星际地图'),
          _buildNavItem(1, Icons.auto_awesome_rounded, '学伴'),
          _buildNavItem(2, Icons.person_rounded, '我的'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.cyan.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? AppTheme.cyan : Colors.white54, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.cyan : Colors.white54,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
