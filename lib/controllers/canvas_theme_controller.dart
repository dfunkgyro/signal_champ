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
  glass,              // Transparent, frosted glass aesthetic with blur effects
  blueprintWhite,     // White background with blue lines, architectural style
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
      case CanvasTheme.glass:
        return _getGlassTheme();
      case CanvasTheme.blueprintWhite:
        return _getBlueprintWhiteTheme();
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
      case CanvasTheme.glass:
        return 'Glass (Frosted Transparency)';
      case CanvasTheme.blueprintWhite:
        return 'Blueprint White (Architectural)';
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
  // SUPER FUTURISTIC THEME - Enhanced neon cyberpunk aesthetic with vivid colors
  // ══════════════════════════════════════════════════════════════════════════
  CanvasThemeData _getSuperFuturisticTheme() {
    return const CanvasThemeData(
      trackColor: Color(0xFF1A1F2E),            // Deep space blue
      trackOccupiedColor: Color(0xFFFF00FF),    // Bright neon magenta
      railColor: Color(0xFF00FFFF),             // Electric cyan
      sleeperColor: Color(0xFF0D1117),          // Almost black with blue tint
      platformColor: Color(0xFF1E2738),         // Dark slate blue
      platformEdgeColor: Color(0xFF00FFFF),     // Electric cyan glow
      signalPoleColor: Color(0xFF0F1419),       // Near black
      signalRedColor: Color(0xFFFF0055),        // Neon hot pink
      signalGreenColor: Color(0xFF00FF88),      // Neon mint green
      signalYellowColor: Color(0xFFFFFF00),     // Laser yellow
      pointNormalColor: Color(0xFF00DDFF),      // Bright cyan
      pointReverseColor: Color(0xFF00FF88),     // Neon mint
      pointLockedColor: Color(0xFFAA00FF),      // Vivid purple
      pointDeadlockColor: Color(0xFFFF0055),    // Neon hot pink
      pointGapColor: Color(0xFF1E2738),         // Dark slate
      trainBodyColor: Color(0xFF00FFFF),        // Electric cyan body
      trainWindowColor: Color(0xFFFFFF00),      // Laser yellow windows
      trainDoorColor: Color(0xFFFF00FF),        // Magenta doors for accent
      canvasBackgroundColor: Color(0xFF000000), // Pure black for maximum contrast
      wifiAntennaColor: Color(0xFFAA00FF),      // Vivid purple
      wifiCoverageColor: Color(0xFFAA00FF),     // Purple glow with opacity
      transponderColor: Color(0xFFFF0055),      // Hot pink
      movementAuthorityColor: Color(0xFF00FF88),// Neon mint
      labelTextColor: Color(0xFF00FFFF),        // Electric cyan text
      labelBackgroundColor: Color(0xFF0F1419),  // Near black with transparency
      labelFontSize: 11.0,
      showGlow: true,                            // Enhanced glow effects
      showShadows: false,                        // No shadows in cyberpunk
      strokeWidthMultiplier: 1.3,                // Thicker lines for neon effect
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

  // ══════════════════════════════════════════════════════════════════════════
  // GLASS THEME - Transparent, frosted glass aesthetic with blur effects
  // ══════════════════════════════════════════════════════════════════════════
  CanvasThemeData _getGlassTheme() {
    return const CanvasThemeData(
      trackColor: Color(0xCCE3F2FD),            // Light blue with transparency
      trackOccupiedColor: Color(0xCC9575CD),    // Purple with transparency
      railColor: Color(0xCC90A4AE),             // Blue grey with transparency
      sleeperColor: Color(0xCCB0BEC5),          // Light blue grey with transparency
      platformColor: Color(0xCCFFF9C4),         // Light yellow with transparency
      platformEdgeColor: Color(0xCC64B5F6),     // Blue with transparency
      signalPoleColor: Color(0xCC607D8B),       // Blue grey with transparency
      signalRedColor: Color(0xFFEF5350),        // Bright red (less transparent)
      signalGreenColor: Color(0xFF66BB6A),      // Bright green (less transparent)
      signalYellowColor: Color(0xFFFFEE58),     // Bright yellow (less transparent)
      pointNormalColor: Color(0xCC4FC3F7),      // Light blue with transparency
      pointReverseColor: Color(0xCC81C784),     // Light green with transparency
      pointLockedColor: Color(0xCC5C6BC0),      // Indigo with transparency
      pointDeadlockColor: Color(0xCCFF7043),    // Orange with transparency
      pointGapColor: Color(0xCCF5F5F5),         // Light grey with transparency
      trainBodyColor: Color(0xCC42A5F5),        // Blue with transparency
      trainWindowColor: Color(0xCCE1F5FE),      // Very light blue with transparency
      trainDoorColor: Color(0xCC1976D2),        // Darker blue with transparency
      canvasBackgroundColor: Color(0xFFF0F4F8), // Very light blue-grey background
      wifiAntennaColor: Color(0xCC26C6DA),      // Cyan with transparency
      wifiCoverageColor: Color(0x8026C6DA),     // Cyan with more transparency
      transponderColor: Color(0xCCFFA726),      // Orange with transparency
      movementAuthorityColor: Color(0xCC66BB6A),// Green with transparency
      labelTextColor: Color(0xFF1976D2),        // Solid dark blue
      labelBackgroundColor: Color(0xDDFFFFFF),  // White with slight transparency
      labelFontSize: 10.5,
      showGlow: true,
      showShadows: false,
      strokeWidthMultiplier: 1.0,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BLUEPRINT WHITE THEME - White background with blue lines, architectural
  // ══════════════════════════════════════════════════════════════════════════
  CanvasThemeData _getBlueprintWhiteTheme() {
    return const CanvasThemeData(
      trackColor: Color(0xFF1976D2),            // Blueprint blue
      trackOccupiedColor: Color(0xFF7B1FA2),    // Purple
      railColor: Color(0xFF0D47A1),             // Dark blue
      sleeperColor: Color(0xFF1976D2),          // Blueprint blue
      platformColor: Color(0xFFE3F2FD),         // Very light blue
      platformEdgeColor: Color(0xFF1976D2),     // Blueprint blue
      signalPoleColor: Color(0xFF0D47A1),       // Dark blue
      signalRedColor: Color(0xFFD32F2F),        // Red
      signalGreenColor: Color(0xFF388E3C),      // Green
      signalYellowColor: Color(0xFFFBC02D),     // Yellow
      pointNormalColor: Color(0xFF1976D2),      // Blueprint blue
      pointReverseColor: Color(0xFF0288D1),     // Light blue
      pointLockedColor: Color(0xFF303F9F),      // Indigo
      pointDeadlockColor: Color(0xFFC62828),    // Dark red
      pointGapColor: Color(0xFFFFFFFF),         // White
      trainBodyColor: Color(0xFF1976D2),        // Blueprint blue
      trainWindowColor: Color(0xFFE3F2FD),      // Very light blue
      trainDoorColor: Color(0xFF0D47A1),        // Dark blue
      canvasBackgroundColor: Color(0xFFFFFFFF), // Pure white (blueprint paper)
      wifiAntennaColor: Color(0xFF0288D1),      // Light blue
      wifiCoverageColor: Color(0xFF0288D1),     // Light blue with opacity
      transponderColor: Color(0xFFFF6F00),      // Dark orange
      movementAuthorityColor: Color(0xFF388E3C),// Green
      labelTextColor: Color(0xFF0D47A1),        // Dark blue
      labelBackgroundColor: Color(0xFFFFFFFF),  // White
      labelFontSize: 10.0,
      showGlow: false,
      showShadows: false,
      strokeWidthMultiplier: 0.8,
    );
  }
}
