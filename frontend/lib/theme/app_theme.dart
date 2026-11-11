import 'package:flutter/material.dart';

/// 星探学院 统一主题配置
class AppTheme {
  // 品牌色 - 星空主题
  static const Color spaceDark = Color(0xFF0B0E1A);
  static const Color spaceBlue = Color(0xFF1A1F3A);
  static const Color spacePurple = Color(0xFF2D1B4E);
  
  static const Color cyan = Color(0xFF00D4FF);
  static const Color blue = Color(0xFF3B82F6);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color pink = Color(0xFFFF6B9D);
  static const Color gold = Color(0xFFFFD700);
  static const Color orange = Color(0xFFFF8C42);
  
  // 学科颜色
  static const Color mathColor = Color(0xFF3B82F6);     // 数学 - 蓝
  static const Color chineseColor = Color(0xFFEF4444);  // 语文 - 红
  static const Color englishColor = Color(0xFF10B981);  // 英语 - 绿
  static const Color scienceColor = Color(0xFF8B5CF6);  // 科学 - 紫
  
  // 文字颜色
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xB3FFFFFF);   // 70% opacity
  static const Color textTertiary = Color(0x80FFFFFF);     // 50% opacity
  static const Color textHint = Color(0x66FFFFFF);        // 40% opacity
  
  // 背景渐变
  static const LinearGradient spaceBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [spaceDark, spaceBlue, spacePurple],
  );
  
  // 按钮渐变
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [cyan, blue],
  );
  
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFFE066), orange],
  );
  
  // Glass 卡片样式
  static BoxDecoration glassCard = BoxDecoration(
    color: Colors.white.withOpacity(0.1),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white.withOpacity(0.2)),
  );
  
  // 获取 Material ThemeData
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: spaceDark,
      fontFamily: 'NotoSansSC',
      
      colorScheme: const ColorScheme.dark(
        primary: cyan,
        secondary: purple,
        tertiary: gold,
        surface: spaceBlue,
        background: spaceDark,
      ),
      
      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      // 按钮
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cyan,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      
      // 输入框
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        hintStyle: const TextStyle(color: textHint),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: cyan, width: 2),
        ),
      ),
      
      // 文字主题
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 14, color: textSecondary),
        bodySmall: TextStyle(fontSize: 12, color: textTertiary),
      ),
    );
  }
  
  // 通用间距
  static const double spacingXS = 4;
  static const double spacingSM = 8;
  static const double spacingMD = 16;
  static const double spacingLG = 24;
  static const double spacingXL = 32;
  
  // 圆角
  static const double radiusSM = 8;
  static const double radiusMD = 16;
  static const double radiusLG = 24;
  static const double radiusXL = 32;
}
