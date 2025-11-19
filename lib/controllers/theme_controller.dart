import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/design_tokens.dart';

enum AppTheme {
  railway,
  midnight,
  sunset,
  forest,
  ocean,
  monochrome,
  highContrast,
}

class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  AppTheme _currentTheme = AppTheme.railway;
  
  ThemeMode get themeMode => _themeMode;
  AppTheme get currentTheme => _currentTheme;
  
  ThemeController() {
    _loadPreferences();
  }
  
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt('theme_mode') ?? 0;
    final themeIndex = prefs.getInt('app_theme') ?? 0;
    
    _themeMode = ThemeMode.values[themeModeIndex];
    _currentTheme = AppTheme.values[themeIndex];
    notifyListeners();
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    notifyListeners();
  }
  
  Future<void> setAppTheme(AppTheme theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('app_theme', theme.index);
    notifyListeners();
  }
  
  ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _getColorScheme(_currentTheme, Brightness.light),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }
  
  ThemeData getDarkTheme() {
    final colorScheme = _getColorScheme(_currentTheme, Brightness.dark);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surfaceDark, // OLED black
      cardColor: AppColors.surfaceDarkElevated,
      dialogBackgroundColor: AppColors.surfaceDarkElevated,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      cardTheme: CardTheme(
        elevation: AppElevation.level2,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.medium,
        ),
        color: AppColors.surfaceDarkElevated,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: AppElevation.level2,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.medium,
          ),
          textStyle: AppTypography.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.grey800,
        border: OutlineInputBorder(
          borderRadius: AppBorderRadius.medium,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.medium,
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
      ),
      dividerColor: AppColors.grey800,
      dividerTheme: DividerThemeData(
        color: AppColors.grey800,
        thickness: 1,
        space: AppSpacing.sm,
      ),
    );
  }
  
  ColorScheme _getColorScheme(AppTheme theme, Brightness brightness) {
    switch (theme) {
      case AppTheme.railway:
        return _railwayScheme(brightness);
      case AppTheme.midnight:
        return _midnightScheme(brightness);
      case AppTheme.sunset:
        return _sunsetScheme(brightness);
      case AppTheme.forest:
        return _forestScheme(brightness);
      case AppTheme.ocean:
        return _oceanScheme(brightness);
      case AppTheme.monochrome:
        return _monochromeScheme(brightness);
      case AppTheme.highContrast:
        return _highContrastScheme(brightness);
    }
  }
  
  ColorScheme _railwayScheme(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return ColorScheme.dark(
        primary: const Color(0xFF42A5F5), // Brighter blue for visibility
        primaryContainer: const Color(0xFF1565C0),
        secondary: const Color(0xFFFF9E40), // Warm orange
        secondaryContainer: const Color(0xFFE65100),
        surface: AppColors.surfaceDark,
        onSurface: Colors.white,
        surfaceTint: Colors.transparent,
        error: AppColors.error,
        onError: Colors.white,
        background: AppColors.surfaceDark,
        onBackground: Colors.white,
      );
    } else {
      return ColorScheme.light(
        primary: const Color(0xFF1976D2),
        primaryContainer: const Color(0xFFBBDEFB),
        secondary: const Color(0xFFFF6F00),
        secondaryContainer: const Color(0xFFFFE0B2),
        surface: Colors.white,
        onSurface: Colors.black87,
        error: AppColors.error,
      );
    }
  }

  ColorScheme _midnightScheme(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return ColorScheme.dark(
        primary: const Color(0xFF90CAF9), // Light blue for dark bg
        primaryContainer: const Color(0xFF0D47A1),
        secondary: const Color(0xFFB39DDB), // Soft purple
        secondaryContainer: const Color(0xFF512DA8),
        surface: AppColors.black, // Pure black for OLED
        onSurface: const Color(0xFFE3F2FD),
        surfaceTint: Colors.transparent,
        error: AppColors.errorLight,
        background: AppColors.black,
        onBackground: const Color(0xFFE3F2FD),
      );
    } else {
      return ColorScheme.light(
        primary: const Color(0xFF0D47A1),
        primaryContainer: const Color(0xFFE3F2FD),
        secondary: const Color(0xFF7E57C2),
        secondaryContainer: const Color(0xFFEDE7F6),
        surface: Colors.white,
        onSurface: Colors.black87,
      );
    }
  }
  
  ColorScheme _sunsetScheme(Brightness brightness) {
    return ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF5722),
      brightness: brightness,
      primary: const Color(0xFFFF5722),
      secondary: const Color(0xFFFF9800),
    );
  }
  
  ColorScheme _forestScheme(Brightness brightness) {
    return ColorScheme.fromSeed(
      seedColor: const Color(0xFF388E3C),
      brightness: brightness,
      primary: const Color(0xFF388E3C),
      secondary: const Color(0xFF8BC34A),
    );
  }
  
  ColorScheme _oceanScheme(Brightness brightness) {
    return ColorScheme.fromSeed(
      seedColor: const Color(0xFF0097A7),
      brightness: brightness,
      primary: const Color(0xFF0097A7),
      secondary: const Color(0xFF00BCD4),
    );
  }
  
  ColorScheme _monochromeScheme(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return ColorScheme.dark(
        primary: AppColors.grey300,
        primaryContainer: AppColors.grey700,
        secondary: AppColors.grey400,
        secondaryContainer: AppColors.grey600,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.grey100,
        surfaceTint: Colors.transparent,
        background: AppColors.black,
        onBackground: AppColors.grey100,
        error: AppColors.grey500,
      );
    } else {
      return ColorScheme.light(
        primary: AppColors.grey900,
        primaryContainer: AppColors.grey200,
        secondary: AppColors.grey700,
        secondaryContainer: AppColors.grey300,
        surface: Colors.white,
        onSurface: AppColors.grey900,
        background: AppColors.grey50,
        onBackground: AppColors.grey900,
      );
    }
  }

  ColorScheme _highContrastScheme(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return ColorScheme.dark(
        primary: const Color(0xFFFFEB3B), // Bright yellow
        primaryContainer: const Color(0xFFF57F17),
        secondary: const Color(0xFF00E5FF), // Cyan
        secondaryContainer: const Color(0xFF00B8D4),
        surface: AppColors.black, // Pure black
        onSurface: Colors.white,
        surfaceTint: Colors.transparent,
        background: AppColors.black,
        onBackground: Colors.white,
        error: const Color(0xFFFF1744), // Bright red
        onError: Colors.white,
      );
    } else {
      return const ColorScheme.light(
        primary: Color(0xFF000000), // Pure black
        primaryContainer: Color(0xFFE0E0E0),
        secondary: Color(0xFF0D47A1), // Dark blue
        secondaryContainer: Color(0xFFBBDEFB),
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF000000),
        background: Color(0xFFFFFFFF),
        onBackground: Color(0xFF000000),
        error: Color(0xFFD32F2F),
        onError: Color(0xFFFFFFFF),
      );
    }
  }
  
  Map<String, Color> getCustomColors() {
    switch (_currentTheme) {
      case AppTheme.railway:
        return {
          'trackColor': const Color(0xFF424242),
          'platformColor': const Color(0xFF9E9E9E),
          'signalRed': const Color(0xFFD32F2F),
          'signalGreen': const Color(0xFF388E3C),
        };
      case AppTheme.sunset:
        return {
          'trackColor': const Color(0xFF5D4037),
          'platformColor': const Color(0xFFBCAAA4),
          'signalRed': const Color(0xFFD84315),
          'signalGreen': const Color(0xFF689F38),
        };
      default:
        return {
          'trackColor': const Color(0xFF424242),
          'platformColor': const Color(0xFF9E9E9E),
          'signalRed': const Color(0xFFD32F2F),
          'signalGreen': const Color(0xFF388E3C),
        };
    }
  }
}
