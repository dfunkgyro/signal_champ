import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    return ThemeData(
      useMaterial3: true,
      colorScheme: _getColorScheme(_currentTheme, Brightness.dark),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
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
    return ColorScheme.fromSeed(
      seedColor: const Color(0xFF1976D2),
      brightness: brightness,
      primary: const Color(0xFF1976D2),
      secondary: const Color(0xFFFF6F00),
    );
  }
  
  ColorScheme _midnightScheme(Brightness brightness) {
    return ColorScheme.fromSeed(
      seedColor: const Color(0xFF0D47A1),
      brightness: brightness,
      primary: brightness == Brightness.dark 
          ? const Color(0xFF64B5F6) 
          : const Color(0xFF0D47A1),
      secondary: const Color(0xFF9575CD),
    );
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
      return const ColorScheme.dark(
        primary: Color(0xFFEEEEEE),
        secondary: Color(0xFFBDBDBD),
      );
    } else {
      return const ColorScheme.light(
        primary: Color(0xFF212121),
        secondary: Color(0xFF757575),
      );
    }
  }
  
  ColorScheme _highContrastScheme(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const ColorScheme.dark(
        primary: Color(0xFFFFFF00),
        secondary: Color(0xFF00FFFF),
        background: Color(0xFF000000),
        surface: Color(0xFF000000),
      );
    } else {
      return const ColorScheme.light(
        primary: Color(0xFF000000),
        secondary: Color(0xFF0000FF),
        background: Color(0xFFFFFFFF),
        surface: Color(0xFFFFFFFF),
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
