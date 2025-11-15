import 'package:flutter/material.dart';
import 'package:rail_champ/screens/terminal_station_models.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

// ============================================================================
// TERMINAL PAINTER HELPERS
// Reusable painting utilities for rendering tracks, signals, trains,
// and other railway infrastructure on the canvas
// ============================================================================

/// Track painting helper
class TrackPainter {
  /// Draw a straight track section
  static void drawStraightTrack(
    Canvas canvas,
    double startX,
    double endX,
    double y, {
    double trackWidth = 4.0,
    Color trackColor = Colors.brown,
    bool drawSleepers = true,
    int sleeperCount = 10,
  }) {
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = trackWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw main tracks
    canvas.drawLine(
      Offset(startX, y - 3),
      Offset(endX, y - 3),
      trackPaint,
    );
    canvas.drawLine(
      Offset(startX, y + 3),
      Offset(endX, y + 3),
      trackPaint,
    );

    // Draw sleepers (ties)
    if (drawSleepers) {
      final sleeperPaint = Paint()
        ..color = Colors.brown.shade600
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      final spacing = (endX - startX) / sleeperCount;
      for (int i = 0; i <= sleeperCount; i++) {
        final x = startX + (i * spacing);
        canvas.drawLine(
          Offset(x, y - 8),
          Offset(x, y + 8),
          sleeperPaint,
        );
      }
    }
  }

  /// Draw track with gradient for visual depth
  static void drawGradientTrack(
    Canvas canvas,
    double startX,
    double endX,
    double y, {
    double trackWidth = 4.0,
  }) {
    final gradient = ui.Gradient.linear(
      Offset(startX, y),
      Offset(endX, y),
      [Colors.brown.shade800, Colors.brown.shade400, Colors.brown.shade800],
      [0.0, 0.5, 1.0],
    );

    final trackPaint = Paint()
      ..shader = gradient
      ..strokeWidth = trackWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(startX, y - 3), Offset(endX, y - 3), trackPaint);
    canvas.drawLine(Offset(startX, y + 3), Offset(endX, y + 3), trackPaint);
  }
}

/// Signal painting helper
class SignalPainter {
  /// Draw a detailed signal with aspect lights
  static void drawSignal(
    Canvas canvas,
    double x,
    double y,
    SignalAspect aspect, {
    double height = 40.0,
    bool showLabel = false,
    String? signalId,
  }) {
    // Draw signal mast
    final mastPaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(x, y),
      Offset(x, y - height),
      mastPaint,
    );

    // Draw signal head
    final headRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, y - height - 15),
        width: 20.0,
        height: 30.0,
      ),
      const Radius.circular(4.0),
    );

    final headPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    canvas.drawRRect(headRect, headPaint);

    // Draw aspect lights
    _drawAspectLights(canvas, x, y - height - 15, aspect);

    // Draw label if requested
    if (showLabel && signalId != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: signalId,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 10.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y + 5));
    }
  }

  /// Draw aspect lights based on signal aspect
  static void _drawAspectLights(
    Canvas canvas,
    double x,
    double y,
    SignalAspect aspect,
  ) {
    final lightRadius = 5.0;

    switch (aspect) {
      case SignalAspect.red:
        _drawLight(canvas, x, y - 8, lightRadius, Colors.red, true);
        _drawLight(canvas, x, y, lightRadius, Colors.yellow, false);
        _drawLight(canvas, x, y + 8, lightRadius, Colors.green, false);
        break;

      case SignalAspect.yellow:
        _drawLight(canvas, x, y - 8, lightRadius, Colors.red, false);
        _drawLight(canvas, x, y, lightRadius, Colors.yellow, true);
        _drawLight(canvas, x, y + 8, lightRadius, Colors.green, false);
        break;

      case SignalAspect.doubleYellow:
        _drawLight(canvas, x - 5, y - 4, lightRadius, Colors.yellow, true);
        _drawLight(canvas, x + 5, y - 4, lightRadius, Colors.yellow, true);
        _drawLight(canvas, x, y + 8, lightRadius, Colors.green, false);
        break;

      case SignalAspect.green:
        _drawLight(canvas, x, y - 8, lightRadius, Colors.red, false);
        _drawLight(canvas, x, y, lightRadius, Colors.yellow, false);
        _drawLight(canvas, x, y + 8, lightRadius, Colors.green, true);
        break;
    }
  }

  /// Draw a single signal light
  static void _drawLight(
    Canvas canvas,
    double x,
    double y,
    double radius,
    Color color,
    bool isLit,
  ) {
    final lightPaint = Paint()
      ..color = isLit ? color : color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    if (isLit) {
      // Draw glow effect
      final glowPaint = Paint()
        ..color = color.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

      canvas.drawCircle(Offset(x, y), radius + 2, glowPaint);
    }

    canvas.drawCircle(Offset(x, y), radius, lightPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(Offset(x, y), radius, borderPaint);
  }
}

/// Train painting helper
class TrainPainter {
  /// Draw a detailed train with direction indicator
  static void drawTrain(
    Canvas canvas,
    double x,
    double y,
    Color color,
    int direction, {
    double width = 30.0,
    double height = 20.0,
    bool showDirection = true,
    String? trainName,
  }) {
    // Main train body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, y),
        width: width,
        height: height,
      ),
      const Radius.circular(4.0),
    );

    final bodyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRRect(bodyRect, bodyPaint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(bodyRect, borderPaint);

    // Windows
    final windowPaint = Paint()
      ..color = Colors.lightBlue.shade100
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromCenter(center: Offset(x - 6, y - 2), width: 6, height: 6),
      windowPaint,
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(x + 6, y - 2), width: 6, height: 6),
      windowPaint,
    );

    // Direction arrow
    if (showDirection) {
      final arrowPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final arrowPath = Path();
      if (direction > 0) {
        // Eastbound arrow (right)
        arrowPath.moveTo(x + 8, y + 4);
        arrowPath.lineTo(x + 12, y + 7);
        arrowPath.lineTo(x + 8, y + 10);
      } else {
        // Westbound arrow (left)
        arrowPath.moveTo(x - 8, y + 4);
        arrowPath.lineTo(x - 12, y + 7);
        arrowPath.lineTo(x - 8, y + 10);
      }
      canvas.drawPath(arrowPath, arrowPaint);
    }

    // Train name label
    if (trainName != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: trainName,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 8.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - height / 2 - 12));
    }
  }

  /// Draw train with motion blur effect
  static void drawMovingTrain(
    Canvas canvas,
    double x,
    double y,
    Color color,
    int direction,
    double speed, {
    double width = 30.0,
    double height = 20.0,
  }) {
    // Draw motion blur if moving
    if (speed > 0.5) {
      final blurPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, speed * 2);

      final blurRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x - (direction * speed * 5), y),
          width: width,
          height: height,
        ),
        const Radius.circular(4.0),
      );

      canvas.drawRRect(blurRect, blurPaint);
    }

    // Draw main train
    drawTrain(canvas, x, y, color, direction,
        width: width, height: height, showDirection: true);
  }
}

/// Point (switch) painting helper
class PointPainter {
  /// Draw a railway point/switch
  static void drawPoint(
    Canvas canvas,
    double x,
    double y,
    PointPosition position, {
    bool showLabel = false,
    String? pointId,
  }) {
    final paint = Paint()
      ..color = position == PointPosition.normal ? Colors.green : Colors.orange
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw main track
    canvas.drawLine(
      Offset(x - 20, y),
      Offset(x + 20, y),
      paint,
    );

    // Draw diverging track
    if (position == PointPosition.normal) {
      // Normal position - straight through
      canvas.drawLine(
        Offset(x, y),
        Offset(x + 20, y),
        paint,
      );
    } else {
      // Reverse position - diverted
      canvas.drawLine(
        Offset(x, y),
        Offset(x + 20, y - 10),
        paint,
      );
    }

    // Draw point mechanism
    final mechanismPaint = Paint()
      ..color = Colors.grey.shade700
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x, y), 6.0, mechanismPaint);

    // Draw label
    if (showLabel && pointId != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: pointId,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 10.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y + 10));
    }
  }
}

/// Platform painting helper
class PlatformPainter {
  /// Draw a platform
  static void drawPlatform(
    Canvas canvas,
    double startX,
    double endX,
    double y, {
    double height = 15.0,
    Color color = Colors.grey,
    bool showEdge = true,
    String? platformName,
  }) {
    // Platform surface
    final platformRect = Rect.fromLTRB(startX, y - height / 2, endX, y + height / 2);
    final platformPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRect(platformRect, platformPaint);

    // Platform edge
    if (showEdge) {
      final edgePaint = Paint()
        ..color = Colors.yellow
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(startX, y - height / 2),
        Offset(endX, y - height / 2),
        edgePaint,
      );
    }

    // Border
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(platformRect, borderPaint);

    // Platform name
    if (platformName != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: platformName,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final centerX = (startX + endX) / 2;
      textPainter.paint(canvas, Offset(centerX - textPainter.width / 2, y - 5));
    }
  }
}

/// Axle counter painting helper
class AxleCounterPainter {
  /// Draw an axle counter device
  static void drawAxleCounter(
    Canvas canvas,
    double x,
    double y, {
    bool isActive = false,
    int count = 0,
    bool isTwin = false,
    String? label,
  }) {
    // Device body
    final bodyPaint = Paint()
      ..color = isActive ? Colors.blue : Colors.grey
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromCenter(center: Offset(x, y), width: 16, height: 16),
      bodyPaint,
    );

    // Border
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(
      Rect.fromCenter(center: Offset(x, y), width: 16, height: 16),
      borderPaint,
    );

    // Detection markers (D1/D2 for twin counters)
    if (isTwin) {
      final markerPaint = Paint()
        ..color = isActive ? Colors.white : Colors.grey.shade300
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x - 3, y), 2.0, markerPaint);
      canvas.drawCircle(Offset(x + 3, y), 2.0, markerPaint);
    }

    // Label
    if (label != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 8.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y + 10));
    }
  }

  /// Draw axle counter with animated detection effect
  static void drawActiveAxleCounter(
    Canvas canvas,
    double x,
    double y,
    int animationTick, {
    String? label,
  }) {
    // Pulsing glow effect
    final glowRadius = 10.0 + math.sin(animationTick * 0.1) * 3.0;
    final glowPaint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);

    canvas.drawCircle(Offset(x, y), glowRadius, glowPaint);

    // Draw regular counter
    drawAxleCounter(canvas, x, y, isActive: true, label: label);
  }
}

/// Block section painting helper
class BlockPainter {
  /// Draw a block section with occupancy indication
  static void drawBlock(
    Canvas canvas,
    double startX,
    double endX,
    double y, {
    required bool occupied,
    double trackY = 0.0,
    String? blockId,
  }) {
    final blockColor = occupied
        ? Colors.red.withOpacity(0.3)
        : Colors.green.withOpacity(0.3);

    final blockPaint = Paint()
      ..color = blockColor
      ..style = PaintingStyle.fill;

    // Draw block indicator above track
    final blockRect = Rect.fromLTRB(startX, y - 30, endX, y - 10);
    canvas.drawRect(blockRect, blockPaint);

    // Border
    final borderPaint = Paint()
      ..color = occupied ? Colors.red : Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(blockRect, borderPaint);

    // Block ID label
    if (blockId != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: blockId,
          style: TextStyle(
            color: occupied ? Colors.red.shade900 : Colors.green.shade900,
            fontSize: 10.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final centerX = (startX + endX) / 2;
      textPainter.paint(canvas, Offset(centerX - textPainter.width / 2, y - 25));
    }
  }
}

/// Grid and background helper
class BackgroundPainter {
  /// Draw a grid for positioning reference
  static void drawGrid(
    Canvas canvas,
    Size size, {
    double gridSpacing = 50.0,
    Color gridColor = Colors.grey,
    double strokeWidth = 0.5,
  }) {
    final paint = Paint()
      ..color = gridColor.withOpacity(0.3)
      ..strokeWidth = strokeWidth;

    // Vertical lines
    for (double x = 0; x <= size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y <= size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  /// Draw coordinate axes for debugging
  static void drawAxes(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0;

    // X-axis
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), axisPaint);

    // Y-axis
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), axisPaint);

    // Labels
    final textStyle = const TextStyle(color: Colors.black, fontSize: 10.0);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(text: 'X', style: textStyle);
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - 20, size.height / 2 + 5));

    textPainter.text = TextSpan(text: 'Y', style: textStyle);
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 + 5, 5));
  }
}
