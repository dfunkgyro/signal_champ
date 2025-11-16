import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models/railway_model.dart';

class RailwayPainter extends CustomPainter {
  final List<Train> trains;
  final List<BlockSection> blocks;
  final List<Signal> signals;
  final List<Transponder> transponders;
  final List<WifiAntenna> wifiAntennas;
  final bool cbtcEnabled;
  final Offset cameraOffset;
  final double zoom;
  final ThemeData theme;

  RailwayPainter({
    required this.trains,
    required this.blocks,
    required this.signals,
    required this.transponders,
    required this.wifiAntennas,
    required this.cbtcEnabled,
    required this.cameraOffset,
    required this.zoom,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Apply camera transform
    canvas.save();
    canvas.translate(
      size.width / 2 + cameraOffset.dx,
      size.height / 2 + cameraOffset.dy,
    );
    canvas.scale(zoom);
    canvas.translate(-size.width / 2, -size.height / 2);

    // Draw grid
    _drawGrid(canvas, size);

    // Draw blocks (track sections)
    _drawBlocks(canvas);

    // Draw CBTC movement authority arrows (before trains so they appear behind)
    if (cbtcEnabled) {
      _drawMovementAuthorities(canvas);
    }

    // Draw CBTC devices if enabled
    if (cbtcEnabled) {
      _drawTransponders(canvas);
      _drawWifiAntennas(canvas);
    }

    // Draw signals
    _drawSignals(canvas);

    // Draw trains
    _drawTrains(canvas);

    // Draw labels
    _drawLabels(canvas);

    canvas.restore();
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = theme.colorScheme.onBackground.withOpacity(0.1)
      ..strokeWidth = 1;

    const gridSize = 50.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  void _drawBlocks(Canvas canvas) {
    for (final block in blocks) {
      // Track base - closed tracks are red, occupied are red-ish, normal are grey
      Color trackColor;
      if (block.closedBySmc) {
        trackColor = Colors.red; // Solid red for closed tracks
      } else if (block.occupied) {
        trackColor = Colors.red.withOpacity(0.3);
      } else {
        trackColor = Colors.grey[700]!;
      }

      final trackPaint = Paint()
        ..color = trackColor
        ..style = PaintingStyle.fill;

      final trackRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          block.startX,
          block.y - 10,
          block.endX - block.startX,
          20,
        ),
        const Radius.circular(4),
      );

      canvas.drawRRect(trackRect, trackPaint);

      // Track outline
      final outlinePaint = Paint()
        ..color = theme.colorScheme.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawRRect(trackRect, outlinePaint);

      // Rails
      final railPaint = Paint()
        ..color = Colors.grey[600]!
        ..strokeWidth = 3;

      // Top rail
      canvas.drawLine(
        Offset(block.startX, block.y - 6),
        Offset(block.endX, block.y - 6),
        railPaint,
      );

      // Bottom rail
      canvas.drawLine(
        Offset(block.startX, block.y + 6),
        Offset(block.endX, block.y + 6),
        railPaint,
      );

      // Sleepers (ties)
      final sleeperPaint = Paint()
        ..color = Colors.brown[700]!
        ..strokeWidth = 4;

      for (double x = block.startX; x < block.endX; x += 15) {
        canvas.drawLine(
          Offset(x, block.y - 8),
          Offset(x, block.y + 8),
          sleeperPaint,
        );
      }
    }
  }

  void _drawSignals(Canvas canvas) {
    for (final signal in signals) {
      // Signal pole
      final polePaint = Paint()
        ..color = Colors.grey[800]!
        ..strokeWidth = 4;

      canvas.drawLine(
        Offset(signal.x, signal.y),
        Offset(signal.x, signal.y - 40),
        polePaint,
      );

      // Get color from signal state enum
      final signalColor = _getSignalColor(signal.state);

      // Signal light
      final lightPaint = Paint()
        ..color = signalColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(signal.x, signal.y - 50),
        8,
        lightPaint,
      );

      // Light outline
      final outlinePaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(
        Offset(signal.x, signal.y - 50),
        8,
        outlinePaint,
      );

      // Glow effect when green or blue
      if (signal.state == SignalState.green || signal.state == SignalState.blue) {
        final glowPaint = Paint()
          ..color = signalColor.withOpacity(0.3)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          Offset(signal.x, signal.y - 50),
          12,
          glowPaint,
        );
      }
    }
  }

  void _drawTrains(Canvas canvas) {
    for (final train in trains) {
      canvas.save();
      canvas.translate(train.x, train.y);
      canvas.rotate(train.angle * math.pi / 180);

      // Train body
      final bodyPaint = Paint()
        ..color = train.color
        ..style = PaintingStyle.fill;

      final trainRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-20, -8, 40, 16),
        const Radius.circular(4),
      );

      canvas.drawRRect(trainRect, bodyPaint);

      // Train outline
      final outlinePaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawRRect(trainRect, outlinePaint);

      // Windows
      final windowPaint = Paint()
        ..color = Colors.lightBlue[100]!
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        const Rect.fromLTWH(-15, -5, 8, 6),
        windowPaint,
      );
      canvas.drawRect(
        const Rect.fromLTWH(-3, -5, 8, 6),
        windowPaint,
      );
      canvas.drawRect(
        const Rect.fromLTWH(9, -5, 8, 6),
        windowPaint,
      );

      // Wheels
      final wheelPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill;

      canvas.drawCircle(const Offset(-12, 8), 4, wheelPaint);
      canvas.drawCircle(const Offset(12, 8), 4, wheelPaint);

      // Direction indicator
      if (train.speed > 0) {
        final arrowPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawLine(
          const Offset(15, 0),
          const Offset(20, 0),
          arrowPaint,
        );
        canvas.drawLine(
          const Offset(20, 0),
          const Offset(17, -3),
          arrowPaint,
        );
        canvas.drawLine(
          const Offset(20, 0),
          const Offset(17, 3),
          arrowPaint,
        );
      }

      canvas.restore();
    }
  }

  void _drawLabels(Canvas canvas) {
    final textStyle = TextStyle(
      color: theme.colorScheme.onBackground,
      fontSize: 12,
    );

    // Draw block labels
    for (final block in blocks) {
      final textSpan = TextSpan(
        text: block.id,
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (block.startX + block.endX) / 2 - textPainter.width / 2,
          block.y + 15,
        ),
      );
    }

    // Draw signal labels
    for (final signal in signals) {
      final textSpan = TextSpan(
        text: signal.id,
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          signal.x - textPainter.width / 2,
          signal.y - 65,
        ),
      );
    }

    // Draw train labels
    for (final train in trains) {
      final textSpan = TextSpan(
        text: '${train.name} (${train.speed.toStringAsFixed(1)})',
        style: textStyle.copyWith(fontWeight: FontWeight.bold),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          train.x - textPainter.width / 2,
          train.y - 25,
        ),
      );
    }
  }

  Color _getSignalColor(SignalState state) {
    switch (state) {
      case SignalState.green:
        return Colors.green;
      case SignalState.yellow:
        return Colors.orange;
      case SignalState.red:
        return Colors.red;
      case SignalState.blue:
        return Colors.blue;
    }
  }

  void _drawTransponders(Canvas canvas) {
    for (final transponder in transponders) {
      // Draw transponder as a yellow rectangular tag on the track
      final tagPaint = Paint()
        ..color = _getTransponderColor(transponder.type)
        ..style = PaintingStyle.fill;

      final tagRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(transponder.x, transponder.y),
          width: 12,
          height: 8,
        ),
        const Radius.circular(2),
      );

      canvas.drawRRect(tagRect, tagPaint);

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawRRect(tagRect, borderPaint);

      // Draw label
      final textPainter = TextPainter(
        text: TextSpan(
          text: transponder.type.name.toUpperCase(),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 6,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          transponder.x - textPainter.width / 2,
          transponder.y - textPainter.height / 2,
        ),
      );
    }
  }

  Color _getTransponderColor(TransponderType type) {
    switch (type) {
      case TransponderType.t1:
        return Colors.yellow[600]!;
      case TransponderType.t2:
        return Colors.orange[600]!;
      case TransponderType.t3:
        return Colors.amber[700]!;
      case TransponderType.t6:
        return Colors.lime[600]!;
    }
  }

  void _drawWifiAntennas(Canvas canvas) {
    for (final antenna in wifiAntennas) {
      // Draw antenna pole
      final polePaint = Paint()
        ..color = Colors.grey[700]!
        ..strokeWidth = 2;

      canvas.drawLine(
        Offset(antenna.x, antenna.y - 10),
        Offset(antenna.x, antenna.y + 10),
        polePaint,
      );

      // Draw antenna dish/box
      final antennaPaint = Paint()
        ..color = antenna.isActive ? Colors.blue[700]! : Colors.grey[500]!
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(antenna.x, antenna.y - 10),
        6,
        antennaPaint,
      );

      // Draw wifi signal waves if active
      if (antenna.isActive) {
        final wavePaint = Paint()
          ..color = Colors.blue[300]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        // Draw 3 signal arcs
        for (int i = 1; i <= 3; i++) {
          final radius = 4.0 + (i * 3.0);
          canvas.drawArc(
            Rect.fromCenter(
              center: Offset(antenna.x, antenna.y - 10),
              width: radius * 2,
              height: radius * 2,
            ),
            -math.pi * 0.75,
            math.pi * 1.5,
            false,
            wavePaint,
          );
        }
      }

      // Draw label
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'WiFi',
          style: TextStyle(
            color: antenna.isActive ? Colors.blue[900] : Colors.grey[700],
            fontSize: 7,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          antenna.x - textPainter.width / 2,
          antenna.y + 12,
        ),
      );
    }
  }

  void _drawMovementAuthorities(Canvas canvas) {
    // Get current time for animation
    final animationOffset = (DateTime.now().millisecondsSinceEpoch % 2000) / 2000.0;

    for (final train in trains) {
      // Only draw for CBTC trains with movement authority
      if (!train.isCbtcEquipped || train.movementAuthority == null) continue;
      if (train.cbtcMode != CbtcMode.auto &&
          train.cbtcMode != CbtcMode.pm &&
          train.cbtcMode != CbtcMode.rm) continue;

      final ma = train.movementAuthority!;
      if (ma.maxDistance <= 0) continue;

      final trainX = train.x;
      final trainY = train.y;
      final isEastbound = train.direction == Direction.east;

      // Calculate start and end positions for the green arrow path
      final startX = isEastbound ? trainX + 25 : trainX - 25; // Start just ahead of train
      final endX = isEastbound
          ? trainX + ma.maxDistance
          : trainX - ma.maxDistance;

      // Draw base green path with gradient
      final gradient = LinearGradient(
        colors: [
          Colors.green.withOpacity(0.6),
          Colors.green.withOpacity(0.3),
          Colors.green.withOpacity(0.1),
        ],
        stops: const [0.0, 0.7, 1.0],
      );

      final pathPaint = Paint()
        ..shader = gradient.createShader(Rect.fromPoints(
          Offset(startX, trainY - 20),
          Offset(endX, trainY - 20),
        ))
        ..style = PaintingStyle.fill;

      // Draw the main authority path as a rounded rectangle
      final pathRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          isEastbound ? startX : endX,
          trainY - 20,
          isEastbound ? endX : startX,
          trainY - 10,
        ),
        const Radius.circular(3),
      );
      canvas.drawRRect(pathRect, pathPaint);

      // Draw animated flowing arrows along the path
      final arrowCount = (ma.maxDistance / 80).ceil().clamp(1, 25);
      for (int i = 0; i < arrowCount; i++) {
        // Calculate arrow position with animation
        final progress = (i / arrowCount) + animationOffset;
        final normalizedProgress = progress % 1.0;

        final arrowX = isEastbound
            ? startX + (ma.maxDistance * normalizedProgress)
            : startX - (ma.maxDistance * normalizedProgress);

        // Fade out arrows near the end
        final opacity = (1.0 - normalizedProgress).clamp(0.3, 1.0);

        // Draw arrow chevron
        final arrowPaint = Paint()
          ..color = Colors.green.withOpacity(opacity * 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;

        final arrowSize = 6.0;
        final arrowY = trainY - 15;

        if (isEastbound) {
          // Right-pointing arrow
          canvas.drawLine(
            Offset(arrowX - arrowSize, arrowY - arrowSize),
            Offset(arrowX, arrowY),
            arrowPaint,
          );
          canvas.drawLine(
            Offset(arrowX - arrowSize, arrowY + arrowSize),
            Offset(arrowX, arrowY),
            arrowPaint,
          );
        } else {
          // Left-pointing arrow
          canvas.drawLine(
            Offset(arrowX + arrowSize, arrowY - arrowSize),
            Offset(arrowX, arrowY),
            arrowPaint,
          );
          canvas.drawLine(
            Offset(arrowX + arrowSize, arrowY + arrowSize),
            Offset(arrowX, arrowY),
            arrowPaint,
          );
        }
      }

      // Draw destination marker or obstacle indicator at the end
      if (ma.limitReason != null) {
        final endMarkerPaint = Paint()
          ..color = ma.hasDestination ? Colors.blue : Colors.orange
          ..style = PaintingStyle.fill;

        // Draw vertical line at the limit
        canvas.drawLine(
          Offset(endX, trainY - 25),
          Offset(endX, trainY - 5),
          Paint()
            ..color = ma.hasDestination ? Colors.blue : Colors.orange
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );

        // Draw small circle at top of line
        canvas.drawCircle(
          Offset(endX, trainY - 25),
          4,
          endMarkerPaint,
        );

        // Draw limit reason text (small)
        final reasonPainter = TextPainter(
          text: TextSpan(
            text: ma.limitReason!.length > 20
                ? '${ma.limitReason!.substring(0, 17)}...'
                : ma.limitReason!,
            style: TextStyle(
              color: ma.hasDestination ? Colors.blue[900] : Colors.orange[900],
              fontSize: 8,
              fontWeight: FontWeight.bold,
              backgroundColor: Colors.white.withOpacity(0.8),
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        reasonPainter.layout();
        reasonPainter.paint(
          canvas,
          Offset(
            endX - reasonPainter.width / 2,
            trainY - 35,
          ),
        );
      }

      // Draw glow effect around the path for extra visibility
      final glowPaint = Paint()
        ..color = Colors.green.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      final glowRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          isEastbound ? startX : endX,
          trainY - 20,
          isEastbound ? endX : startX,
          trainY - 10,
        ),
        const Radius.circular(3),
      );
      canvas.drawRRect(glowRect, glowPaint);
    }
  }

  @override
  bool shouldRepaint(RailwayPainter oldDelegate) {
    return true; // Always repaint for animations
  }
}
