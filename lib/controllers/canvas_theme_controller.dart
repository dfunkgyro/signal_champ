import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// CANVAS THEME SYSTEM
// ============================================================================
// Provides visual themes for the railway simulation canvas
// Each theme has distinct visual styling while maintaining full functionality

enum CanvasTheme {
  defaultTheme,       // Current default - professional railway style
  superFuturistic,    // Neon, glowing, high-tech aesthetic
  professionalModern, // Clean, minimal, corporate style
  simplified,         // Minimal UI, focus on essentials
  smartUserFriendly,  // High contrast, clear labels, accessible
}

class CanvasThemeData {
  // Track colors
  final Color trackColor;
  final Color trackOccupiedColor;
  final Color railColor;
  final Color sleeperColor;

  // Platform colors
  final Color platformColor;
  final Color platformEdgeColor;

  // Signal colors
  final Color signalPoleColor;
  final Color signalRedColor;
  final Color signalGreenColor;
  final Color signalYellowColor;

  // Point colors
  final Color pointNormalColor;
  final Color pointReverseColor;
  final Color pointLockedColor;
  final Color pointDeadlockColor;
  final Color pointGapColor;

  // Train colors
  final Color trainBodyColor;
  final Color trainWindowColor;
  final Color trainDoorColor;

  // Canvas background
  final Color canvasBackgroundColor;

  // WiFi & Transponder colors
  final Color wifiAntennaColor;
  final Color wifiCoverageColor;
  final Color transponderColor;

  // Movement Authority colors
  final Color movementAuthorityColor;

  // Labels & UI
  final Color labelTextColor;
  final Color labelBackgroundColor;
  final double labelFontSize;

  // Visual effects
  final bool showGlow;
  final bool showShadows;
  final double strokeWidthMultiplier;

  const CanvasThemeData({
    required this.trackColor,
    required this.trackOccupiedColor,
    required this.railColor,
    required this.sleeperColor,
    required this.platformColor,
    required this.platformEdgeColor,
    required this.signalPoleColor,
    required this.signalRedColor,
    required this.signalGreenColor,
    required this.signalYellowColor,
    required this.pointNormalColor,
    required this.pointReverseColor,
    required this.pointLockedColor,
    required this.pointDeadlockColor,
    required this.pointGapColor,
    required this.trainBodyColor,
    required this.trainWindowColor,
    required this.trainDoorColor,
    required this.canvasBackgroundColor,
    required this.wifiAntennaColor,
    required this.wifiCoverageColor,
    required this.transponderColor,
    required this.movementAuthorityColor,
    required this.labelTextColor,
    required this.labelBackgroundColor,
    this.labelFontSize = 10.0,
    this.showGlow = false,
    this.showShadows = false,
    this.strokeWidthMultiplier = 1.0,
  });
}

class CanvasThemeController extends ChangeNotifier {
  CanvasTheme _currentTheme = CanvasTheme.defaultTheme;

  CanvasTheme get currentTheme => _currentTheme;

  CanvasThemeController() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('canvas_theme') ?? 0;
    _currentTheme = CanvasTheme.values[themeIndex];
    notifyListeners();
  }

  Future<void> setCanvasTheme(CanvasTheme theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('canvas_theme', theme.index);
    notifyListeners();
  }

  CanvasThemeData getThemeData() {
    switch (_currentTheme) {
      case CanvasTheme.defaultTheme:
        return _getDefaultTheme();
      case CanvasTheme.superFuturistic:
        return _getSuperFuturisticTheme();
      case CanvasTheme.professionalModern:
        return _getProfessionalModernTheme();
      case CanvasTheme.simplified:
        return _getSimplifiedTheme();
      case CanvasTheme.smartUserFriendly:
        return _getSmartUserFriendlyTheme();
    }
  }

  String getThemeDisplayName(CanvasTheme theme) {
    switch (theme) {
      case CanvasTheme.defaultTheme:
        return 'Default (Professional Railway)';
      case CanvasTheme.superFuturistic:
        return 'Super Futuristic';
      case CanvasTheme.professionalModern:
        return 'Professional Modern';
      case CanvasTheme.simplified:
        return 'Simplified';
      case CanvasTheme.smartUserFriendly:
        return 'Smart User Friendly';
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DEFAULT THEME - Current professional railway style
  // ══════════════════════════════════════════════════════════════════════════
  CanvasThemeData _getDefaultTheme() {
    return const CanvasThemeData(
      trackColor: Color(0xFFBDBDBD),           // Grey
      trackOccupiedColor: Color(0xFFBA68C8),   // Purple with opacity
      railColor: Color(0xFF616161),             // Dark grey
      sleeperColor: Color(0xFF5D4037),          // Brown
      platformColor: Color(0xFFFBC02D),         // Yellow
      platformEdgeColor: Color(0xFFFF6F00),     // Amber
      signalPoleColor: Color(0xFF424242),       // Dark grey
      signalRedColor: Color(0xFFD32F2F),        // Red
      signalGreenColor: Color(0xFF388E3C),      // Green
      signalYellowColor: Color(0xFFFBC02D),     // Yellow
      pointNormalColor: Color(0xFF00897B),      // Teal
      pointReverseColor: Color(0xFF43A047),     // Green
      pointLockedColor: Color(0xFF1976D2),      // Blue
      pointDeadlockColor: Color(0xFFFF5722),    // Deep orange
      pointGapColor: Color(0xFFEEEEEE),         // Light grey
      trainBodyColor: Color(0xFF1976D2),        // Blue
      trainWindowColor: Color(0xFF90CAF9),      // Light blue
      trainDoorColor: Color(0xFF0D47A1),        // Dark blue
      canvasBackgroundColor: Color(0xFFF5F5F5), // Off-white
      wifiAntennaColor: Color(0xFF00BCD4),      // Cyan
      wifiCoverageColor: Color(0xFF00BCD4),     // Cyan with opacity
      transponderColor: Color(0xFFFF9800),      // Orange
      movementAuthorityColor: Color(0xFF4CAF50),// Green
      labelTextColor: Color(0xFF212121),        // Near black
      labelBackgroundColor: Color(0xFFFFFFFF),  // White
      labelFontSize: 10.0,
      showGlow: false,
      showShadows: true,
      strokeWidthMultiplier: 1.0,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SUPER FUTURISTIC THEME - Neon, glowing, high-tech aesthetic
  // ══════════════════════════════════════════════════════════════════════════
  CanvasThemeData _getSuperFuturisticTheme() {
    return const CanvasThemeData(
      trackColor: Color(0xFF1A1A2E),            // Dark blue-black
      trackOccupiedColor: Color(0xFFE94560),    // Neon pink
      railColor: Color(0xFF00FFF5),             // Cyan neon
      sleeperColor: Color(0xFF16213E),          // Dark blue
      platformColor: Color(0xFF0F3460),         // Dark blue
      platformEdgeColor: Color(0xFF00FFF5),     // Cyan neon
      signalPoleColor: Color(0xFF16213E),       // Dark blue
      signalRedColor: Color(0xFFFF0080),        // Neon pink
      signalGreenColor: Color(0xFF00FF41),      // Neon green
      signalYellowColor: Color(0xFFFFFF00),     // Bright yellow
      pointNormalColor: Color(0xFF00FFF5),      // Cyan neon
      pointReverseColor: Color(0xFF00FF41),     // Neon green
      pointLockedColor: Color(0xFF8000FF),      // Neon purple
      pointDeadlockColor: Color(0xFFFF0080),    // Neon pink
      pointGapColor: Color(0xFF0F3460),         // Dark blue
      trainBodyColor: Color(0xFF00FFF5),        // Cyan neon
      trainWindowColor: Color(0xFFFFFF00),      // Bright yellow
      trainDoorColor: Color(0xFF00FF41),        // Neon green
      canvasBackgroundColor: Color(0xFF0F0F1E), // Near black
      wifiAntennaColor: Color(0xFF8000FF),      // Neon purple
      wifiCoverageColor: Color(0xFF8000FF),     // Neon purple with opacity
      transponderColor: Color(0xFFFF0080),      // Neon pink
      movementAuthorityColor: Color(0xFF00FF41),// Neon green
      labelTextColor: Color(0xFF00FFF5),        // Cyan neon
      labelBackgroundColor: Color(0xFF1A1A2E),  // Dark blue-black
      labelFontSize: 11.0,
      showGlow: true,
      showShadows: false,
      strokeWidthMultiplier: 1.2,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PROFESSIONAL MODERN THEME - Clean, minimal, corporate style
  // ══════════════════════════════════════════════════════════════════════════
  CanvasThemeData _getProfessionalModernTheme() {
    return const CanvasThemeData(
      trackColor: Color(0xFFE0E0E0),            // Light grey
      trackOccupiedColor: Color(0xFF5C6BC0),    // Indigo
      railColor: Color(0xFF37474F),             // Blue grey dark
      sleeperColor: Color(0xFF78909C),          // Blue grey
      platformColor: Color(0xFFECEFF1),         // Blue grey light
      platformEdgeColor: Color(0xFF607D8B),     // Blue grey
      signalPoleColor: Color(0xFF263238),       // Blue grey darkest
      signalRedColor: Color(0xFFE53935),        // Red
      signalGreenColor: Color(0xFF43A047),      // Green
      signalYellowColor: Color(0xFFFDD835),     // Yellow
      pointNormalColor: Color(0xFF1E88E5),      // Blue
      pointReverseColor: Color(0xFF00ACC1),     // Cyan
      pointLockedColor: Color(0xFF3949AB),      // Indigo
      pointDeadlockColor: Color(0xFFD81B60),    // Pink
      pointGapColor: Color(0xFFFAFAFA),         // Almost white
      trainBodyColor: Color(0xFF1976D2),        // Blue
      trainWindowColor: Color(0xFFBBDEFB),      // Light blue
      trainDoorColor: Color(0xFF0D47A1),        // Dark blue
      canvasBackgroundColor: Color(0xFFFFFFFF), // Pure white
      wifiAntennaColor: Color(0xFF00897B),      // Teal
      wifiCoverageColor: Color(0xFF00897B),     // Teal with opacity
      transponderColor: Color(0xFFFB8C00),      // Orange
      movementAuthorityColor: Color(0xFF43A047),// Green
      labelTextColor: Color(0xFF212121),        // Dark grey
      labelBackgroundColor: Color(0xFFFAFAFA),  // Almost white
      labelFontSize: 9.5,
      showGlow: false,
      showShadows: false,
      strokeWidthMultiplier: 0.9,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SIMPLIFIED THEME - Minimal UI, focus on essentials
  // ══════════════════════════════════════════════════════════════════════════
  CanvasThemeData _getSimplifiedTheme() {
    return const CanvasThemeData(
      trackColor: Color(0xFFE0E0E0),            // Light grey
      trackOccupiedColor: Color(0xFF9C27B0),    // Purple
      railColor: Color(0xFF000000),             // Black
      sleeperColor: Color(0xFF757575),          // Grey
      platformColor: Color(0xFFFFEB3B),         // Yellow
      platformEdgeColor: Color(0xFF000000),     // Black
      signalPoleColor: Color(0xFF000000),       // Black
      signalRedColor: Color(0xFFF44336),        // Red
      signalGreenColor: Color(0xFF4CAF50),      // Green
      signalYellowColor: Color(0xFFFFEB3B),     // Yellow
      pointNormalColor: Color(0xFF2196F3),      // Blue
      pointReverseColor: Color(0xFF4CAF50),     // Green
      pointLockedColor: Color(0xFFFF9800),      // Orange
      pointDeadlockColor: Color(0xFFF44336),    // Red
      pointGapColor: Color(0xFFFAFAFA),         // Almost white
      trainBodyColor: Color(0xFF2196F3),        // Blue
      trainWindowColor: Color(0xFFFFFFFF),      // White
      trainDoorColor: Color(0xFF1976D2),        // Dark blue
      canvasBackgroundColor: Color(0xFFFFFFFF), // White
      wifiAntennaColor: Color(0xFF00BCD4),      // Cyan
      wifiCoverageColor: Color(0xFF00BCD4),     // Cyan with opacity
      transponderColor: Color(0xFFFF9800),      // Orange
      movementAuthorityColor: Color(0xFF4CAF50),// Green
      labelTextColor: Color(0xFF000000),        // Black
      labelBackgroundColor: Color(0xFFFFFFFF),  // White
      labelFontSize: 10.0,
      showGlow: false,
      showShadows: false,
      strokeWidthMultiplier: 1.1,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SMART USER FRIENDLY THEME - High contrast, clear labels, accessible
  // ══════════════════════════════════════════════════════════════════════════
  CanvasThemeData _getSmartUserFriendlyTheme() {
    return const CanvasThemeData(
      trackColor: Color(0xFFD7CCC8),            // Light brown
      trackOccupiedColor: Color(0xFF8E24AA),    // Purple
      railColor: Color(0xFF3E2723),             // Dark brown
      sleeperColor: Color(0xFF5D4037),          // Brown
      platformColor: Color(0xFFFFD54F),         // Amber
      platformEdgeColor: Color(0xFF000000),     // Black
      signalPoleColor: Color(0xFF212121),       // Dark grey
      signalRedColor: Color(0xFFC62828),        // Dark red
      signalGreenColor: Color(0xFF2E7D32),      // Dark green
      signalYellowColor: Color(0xFFF9A825),     // Dark yellow
      pointNormalColor: Color(0xFF0277BD),      // Dark cyan
      pointReverseColor: Color(0xFF2E7D32),     // Dark green
      pointLockedColor: Color(0xFF1565C0),      // Dark blue
      pointDeadlockColor: Color(0xFFC62828),    // Dark red
      pointGapColor: Color(0xFFFFF8E1),         // Light yellow
      trainBodyColor: Color(0xFF1565C0),        // Dark blue
      trainWindowColor: Color(0xFFFFFFFF),      // White
      trainDoorColor: Color(0xFF0D47A1),        // Darker blue
      canvasBackgroundColor: Color(0xFFFFFBE6), // Light cream
      wifiAntennaColor: Color(0xFF00838F),      // Dark cyan
      wifiCoverageColor: Color(0xFF00838F),     // Dark cyan with opacity
      transponderColor: Color(0xFFE65100),      // Dark orange
      movementAuthorityColor: Color(0xFF2E7D32),// Dark green
      labelTextColor: Color(0xFF000000),        // Black
      labelBackgroundColor: Color(0xFFFFFFFF),  // White
      labelFontSize: 11.0,
      showGlow: false,
      showShadows: true,
      strokeWidthMultiplier: 1.3,
    );
  }
}
