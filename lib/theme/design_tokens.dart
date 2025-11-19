import 'package:flutter/material.dart';

/// Design Tokens - Centralized design system constants
/// Provides consistent spacing, typography, colors, animations, and elevation across the app

// ============================================================================
// SPACING SCALE
// ============================================================================

class AppSpacing {
  AppSpacing._(); // Private constructor to prevent instantiation

  /// 4px - Minimal spacing for tight layouts
  static const double xs = 4.0;

  /// 8px - Small spacing between related elements
  static const double sm = 8.0;

  /// 12px - Default spacing for compact layouts
  static const double md = 12.0;

  /// 16px - Standard spacing between elements
  static const double lg = 16.0;

  /// 24px - Large spacing for section separation
  static const double xl = 24.0;

  /// 32px - Extra large spacing for major sections
  static const double xxl = 32.0;

  /// 48px - Maximum spacing for significant visual breaks
  static const double xxxl = 48.0;

  /// Standard padding for panels and cards
  static const EdgeInsets panelPadding = EdgeInsets.all(lg);

  /// Compact padding for dense UI elements
  static const EdgeInsets compactPadding = EdgeInsets.all(sm);

  /// Spacious padding for emphasized content
  static const EdgeInsets spaciousPadding = EdgeInsets.all(xl);
}

// ============================================================================
// TYPOGRAPHY SCALE
// ============================================================================

class AppTypography {
  AppTypography._();

  /// Display - Extra large headlines (32px, bold)
  static const TextStyle display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.2,
  );

  /// Heading 1 - Major section headers (24px, bold)
  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.3,
    height: 1.3,
  );

  /// Heading 2 - Subsection headers (20px, semi-bold)
  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
  );

  /// Heading 3 - Card headers (18px, semi-bold)
  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.4,
  );

  /// Heading 4 - Small headers (16px, medium)
  static const TextStyle h4 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.4,
  );

  /// Heading 5 - Compact headers (14px, medium)
  static const TextStyle h5 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.4,
  );

  /// Body Large - Primary content (16px, regular)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.15,
    height: 1.5,
  );

  /// Body - Default body text (14px, regular)
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.25,
    height: 1.5,
  );

  /// Body Small - Secondary content (13px, regular)
  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.25,
    height: 1.5,
  );

  /// Caption - Supplementary text (12px, regular)
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
    height: 1.4,
  );

  /// Caption Small - Minimal text (10px, regular)
  static const TextStyle captionSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.5,
    height: 1.4,
  );

  /// Button - Button text (14px, medium)
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.2,
  );

  /// Button Large - Large button text (16px, medium)
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.2,
  );

  /// Label - Form labels and tags (13px, medium)
  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.3,
  );

  /// Monospace - Code and technical data (13px, monospace)
  static const TextStyle monospace = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    fontFamily: 'monospace',
    letterSpacing: 0,
    height: 1.5,
  );
}

// ============================================================================
// SEMANTIC COLORS
// ============================================================================

class AppColors {
  AppColors._();

  // Success colors
  static const Color successLight = Color(0xFF4CAF50);
  static const Color success = Color(0xFF2E7D32);
  static const Color successDark = Color(0xFF1B5E20);

  // Warning colors
  static const Color warningLight = Color(0xFFFF9800);
  static const Color warning = Color(0xFFF57C00);
  static const Color warningDark = Color(0xFFE65100);

  // Error colors
  static const Color errorLight = Color(0xFFF44336);
  static const Color error = Color(0xFFD32F2F);
  static const Color errorDark = Color(0xFFC62828);

  // Info colors
  static const Color infoLight = Color(0xFF29B6F6);
  static const Color info = Color(0xFF0288D1);
  static const Color infoDark = Color(0xFF01579B);

  // Railway-specific colors
  static const Color trackOccupied = Color(0xFFE91E63);
  static const Color trackClear = Color(0xFF4CAF50);
  static const Color trackReserved = Color(0xFFFF9800);
  static const Color trackLocked = Color(0xFFD32F2F);

  // Signal aspects
  static const Color signalGreen = Color(0xFF4CAF50);
  static const Color signalYellow = Color(0xFFFFC107);
  static const Color signalRed = Color(0xFFF44336);
  static const Color signalBlue = Color(0xFF2196F3);
  static const Color signalWhite = Color(0xFFFFFFFF);

  // Dark mode grayscale palette
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey850 = Color(0xFF303030);
  static const Color grey900 = Color(0xFF212121);
  static const Color grey950 = Color(0xFF121212);

  // Pure black for OLED optimization
  static const Color black = Color(0xFF000000);

  // Professional dark mode surfaces
  static const Color surfaceDark = grey950;
  static const Color surfaceDarkElevated = grey900;
  static const Color surfaceDarkHighlight = grey850;

  // Overlay colors with opacity
  static Color overlay(double opacity) => Color.fromRGBO(0, 0, 0, opacity);
  static Color overlayWhite(double opacity) => Color.fromRGBO(255, 255, 255, opacity);

  // Glass effect colors
  static final Color glassBackground = Colors.white.withOpacity(0.1);
  static final Color glassBorder = Colors.white.withOpacity(0.2);
}

// ============================================================================
// ANIMATION CONSTANTS
// ============================================================================

class AppAnimations {
  AppAnimations._();

  /// Ultra fast - 100ms (for immediate feedback)
  static const Duration ultraFast = Duration(milliseconds: 100);

  /// Fast - 200ms (for quick transitions)
  static const Duration fast = Duration(milliseconds: 200);

  /// Normal - 300ms (default animation speed)
  static const Duration normal = Duration(milliseconds: 300);

  /// Slow - 500ms (for emphasized transitions)
  static const Duration slow = Duration(milliseconds: 500);

  /// Very slow - 800ms (for dramatic effects)
  static const Duration verySlow = Duration(milliseconds: 800);

  // Animation curves
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve bounce = Curves.elasticOut;
  static const Curve smooth = Curves.easeInOutCubic;

  // Railway-specific animations
  static const Duration trainMovement = Duration(milliseconds: 16); // 60 FPS
  static const Duration signalChange = Duration(milliseconds: 300);
  static const Duration panelExpand = Duration(milliseconds: 300);
}

// ============================================================================
// BORDER RADIUS
// ============================================================================

class AppBorderRadius {
  AppBorderRadius._();

  /// 4px - Minimal rounding
  static const double xs = 4.0;

  /// 8px - Small rounding
  static const double sm = 8.0;

  /// 12px - Default rounding for cards and panels
  static const double md = 12.0;

  /// 16px - Large rounding
  static const double lg = 16.0;

  /// 20px - Extra large rounding
  static const double xl = 20.0;

  /// 24px - Maximum rounding (near circular for small elements)
  static const double xxl = 24.0;

  /// Full circular
  static const double circular = 9999.0;

  // BorderRadius objects
  static final BorderRadius small = BorderRadius.circular(sm);
  static final BorderRadius medium = BorderRadius.circular(md);
  static final BorderRadius large = BorderRadius.circular(lg);
  static final BorderRadius extraLarge = BorderRadius.circular(xl);
}

// ============================================================================
// ELEVATION / SHADOW
// ============================================================================

class AppElevation {
  AppElevation._();

  /// No elevation
  static const double none = 0.0;

  /// Level 1 - Subtle elevation (1dp)
  static const double level1 = 1.0;

  /// Level 2 - Default elevation (2dp)
  static const double level2 = 2.0;

  /// Level 3 - Raised elevation (4dp)
  static const double level3 = 4.0;

  /// Level 4 - High elevation (8dp)
  static const double level4 = 8.0;

  /// Level 5 - Very high elevation (16dp)
  static const double level5 = 16.0;

  /// Level 6 - Maximum elevation (24dp)
  static const double level6 = 24.0;

  // Shadow definitions for manual use
  static List<BoxShadow> getShadow(double elevation, {Color? color}) {
    if (elevation == 0) return [];

    return [
      BoxShadow(
        color: (color ?? Colors.black).withOpacity(0.1 * (elevation / 4)),
        blurRadius: elevation * 2,
        offset: Offset(0, elevation / 2),
      ),
      BoxShadow(
        color: (color ?? Colors.black).withOpacity(0.05 * (elevation / 4)),
        blurRadius: elevation,
        offset: Offset(0, elevation / 4),
      ),
    ];
  }
}

// ============================================================================
// ICON SIZES
// ============================================================================

class AppIconSize {
  AppIconSize._();

  static const double xs = 16.0;
  static const double sm = 20.0;
  static const double md = 24.0;
  static const double lg = 32.0;
  static const double xl = 48.0;
  static const double xxl = 64.0;
}

// ============================================================================
// RESPONSIVE BREAKPOINTS
// ============================================================================

class AppBreakpoints {
  AppBreakpoints._();

  /// Mobile small (< 360px)
  static const double mobileSmall = 360.0;

  /// Mobile (< 600px)
  static const double mobile = 600.0;

  /// Tablet (< 900px)
  static const double tablet = 900.0;

  /// Desktop (< 1200px)
  static const double desktop = 1200.0;

  /// Large desktop (< 1600px)
  static const double desktopLarge = 1600.0;

  /// Extra large desktop (>= 1600px)
  static const double desktopXL = 1920.0;

  /// Check if current width is mobile
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobile;

  /// Check if current width is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < desktop;
  }

  /// Check if current width is desktop
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;

  /// Get responsive value based on screen size
  static T responsive<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width >= AppBreakpoints.desktop) {
      return desktop ?? tablet ?? mobile;
    } else if (width >= AppBreakpoints.mobile) {
      return tablet ?? mobile;
    }
    return mobile;
  }
}

// ============================================================================
// Z-INDEX / LAYER ORDERING
// ============================================================================

class AppZIndex {
  AppZIndex._();

  static const double background = 0.0;
  static const double canvas = 1.0;
  static const double content = 10.0;
  static const double panel = 100.0;
  static const double floatingButton = 500.0;
  static const double drawer = 800.0;
  static const double dialog = 900.0;
  static const double snackbar = 950.0;
  static const double tooltip = 1000.0;
}
