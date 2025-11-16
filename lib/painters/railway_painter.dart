import 'package:flutter/material.dart';
import '../models/simulation/entities.dart';

// ============================================================================
// RAILWAY PAINTER - RENDERS THE TRACK LAYOUT
// ============================================================================

class RailwayPainter extends CustomPainter {
  final List<Train> trains;
  final List<BlockSection> blocks;
  final List<Signal> signals;
  final List<Platform> platforms;
  final double cameraOffsetX;
  final double zoom;

  RailwayPainter({
    required this.trains,
    required this.blocks,
    required this.signals,
    required this.platforms,
    required this.cameraOffsetX,
    required this.zoom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // Apply camera transform
    canvas.translate(size.width / 2, 0);
    canvas.scale(zoom);
    canvas.translate(cameraOffsetX, 0);

    // Draw platforms first (yellow base layer)
    _drawPlatforms(canvas);

    // Draw blocks (track sections)
    _drawBlocks(canvas);

    // Draw signals
    _drawSignals(canvas);

    // Draw trains
    _drawTrains(canvas);

    // Draw labels
    _drawLabels(canvas);

    canvas.restore();
  }

  void _drawPlatforms(Canvas canvas) {
    for (var platform in platforms) {
      // Platform base (yellow)
      final platformPaint = Paint()
        ..color = Colors.yellow[700]!
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            platform.startX,
            platform.y - 25,
            platform.endX - platform.startX,
            50,
          ),
          const Radius.circular(8),
        ),
        platformPaint,
      );

      // Platform edge
      final edgePaint = Paint()
        ..color = Colors.amber[900]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            platform.startX,
            platform.y - 25,
            platform.endX - platform.startX,
            50,
          ),
          const Radius.circular(8),
        ),
        edgePaint,
      );

      // Platform tactile strips (safety markings)
      final stripPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 2;

      for (double x = platform.startX + 10; x < platform.endX; x += 20) {
        canvas.drawLine(
          Offset(x, platform.y - 20),
          Offset(x, platform.y - 25),
          stripPaint,
        );
        canvas.drawLine(
          Offset(x, platform.y + 20),
          Offset(x, platform.y + 25),
          stripPaint,
        );
      }
    }
  }

  void _drawBlocks(Canvas canvas) {
    for (var block in blocks) {
      // Block base
      final blockPaint = Paint()
        ..color = block.occupied
            ? (block.isOverlapBlock ? Colors.orange.withOpacity(0.3) : Colors.red.withOpacity(0.3))
            : Colors.grey[300]!
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            block.startX,
            block.y - 15,
            block.endX - block.startX,
            30,
          ),
          const Radius.circular(4),
        ),
        blockPaint,
      );

      // Block outline
      final outlinePaint = Paint()
        ..color = block.isOverlapBlock ? Colors.orange : Colors.grey[600]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = block.isOverlapBlock ? 2 : 1;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            block.startX,
            block.y - 15,
            block.endX - block.startX,
            30,
          ),
          const Radius.circular(4),
        ),
        outlinePaint,
      );

      // Rails
      final railPaint = Paint()
        ..color = Colors.grey[700]!
        ..strokeWidth = 3;

      canvas.drawLine(
        Offset(block.startX, block.y - 8),
        Offset(block.endX, block.y - 8),
        railPaint,
      );

      canvas.drawLine(
        Offset(block.startX, block.y + 8),
        Offset(block.endX, block.y + 8),
        railPaint,
      );

      // Sleepers (ties)
      final sleeperPaint = Paint()
        ..color = Colors.brown[700]!
        ..strokeWidth = 6;

      for (double x = block.startX; x < block.endX; x += 15) {
        canvas.drawLine(
          Offset(x, block.y - 12),
          Offset(x, block.y + 12),
          sleeperPaint,
        );
      }
    }
  }

  void _drawSignals(Canvas canvas) {
    for (var signal in signals) {
      // Signal pole
      final polePaint = Paint()
        ..color = Colors.grey[800]!
        ..strokeWidth = 5;

      canvas.drawLine(
        Offset(signal.x, signal.y),
        Offset(signal.x, signal.y - 50),
        polePaint,
      );

      // Signal head (casing)
      final headPaint = Paint()
        ..color = Colors.grey[900]!
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(signal.x - 12, signal.y - 65, 24, 30),
        headPaint,
      );

      // Signal light
      final lightColor = signal.aspect == SignalAspect.green
          ? Colors.green
          : Colors.red;

      final lightPaint = Paint()
        ..color = lightColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(signal.x, signal.y - 50),
        10,
        lightPaint,
      );

      // Glow effect
      if (signal.aspect == SignalAspect.green) {
        final glowPaint = Paint()
          ..color = Colors.green.withOpacity(0.4)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

        canvas.drawCircle(
          Offset(signal.x, signal.y - 50),
          15,
          glowPaint,
        );
      }

      // Light outline
      final outlinePaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(
        Offset(signal.x, signal.y - 50),
        10,
        outlinePaint,
      );
    }
  }

  void _drawTrains(Canvas canvas) {
    for (var train in trains) {
      // Train body
      final bodyPaint = Paint()
        ..color = train.color
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(train.x - 25, train.y - 14, 50, 28),
          const Radius.circular(6),
        ),
        bodyPaint,
      );

      // Train outline
      final outlinePaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(train.x - 25, train.y - 14, 50, 28),
          const Radius.circular(6),
        ),
        outlinePaint,
      );

      // Windows
      final windowPaint = Paint()
        ..color = Colors.lightBlue[100]!
        ..style = PaintingStyle.fill;

      canvas.drawRect(Rect.fromLTWH(train.x - 20, train.y - 10, 10, 8), windowPaint);
      canvas.drawRect(Rect.fromLTWH(train.x - 5, train.y - 10, 10, 8), windowPaint);
      canvas.drawRect(Rect.fromLTWH(train.x + 10, train.y - 10, 10, 8), windowPaint);

      // Wheels
      final wheelPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(train.x - 15, train.y + 14), 6, wheelPaint);
      canvas.drawCircle(Offset(train.x + 15, train.y + 14), 6, wheelPaint);

      // Direction indicator (if moving)
      if (train.isMoving && train.speed > 0) {
        final arrowPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        final path = Path()
          ..moveTo(train.x + 20, train.y)
          ..lineTo(train.x + 28, train.y)
          ..moveTo(train.x + 28, train.y)
          ..lineTo(train.x + 24, train.y - 4)
          ..moveTo(train.x + 28, train.y)
          ..lineTo(train.x + 24, train.y + 4);

        canvas.drawPath(path, arrowPaint);
      }

      // Status indicator
      if (train.atPlatform) {
        final stopPaint = Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(train.x - 20, train.y - 20), 4, stopPaint);
      } else if (train.hasStoppedAtSignal) {
        final waitPaint = Paint()
          ..color = Colors.orange
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(train.x - 20, train.y - 20), 4, waitPaint);
      }
    }
  }

  void _drawLabels(Canvas canvas) {
    // Draw platform labels
    for (var platform in platforms) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: platform.name,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          platform.centerX - textPainter.width / 2,
          platform.y + 35,
        ),
      );
    }

    // Draw block labels
    for (var block in blocks) {
      if (!block.isOverlapBlock) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: block.id,
            style: TextStyle(
              color: block.occupied ? Colors.red[700] : Colors.grey[700],
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            (block.startX + block.endX) / 2 - textPainter.width / 2,
            block.y - 35,
          ),
        );
      }
    }

    // Draw signal labels
    for (var signal in signals) {
      final aspectText = signal.aspect == SignalAspect.green ? 'G' : 'R';

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${signal.id}\n$aspectText',
          style: TextStyle(
            color: signal.aspect == SignalAspect.green
                ? Colors.green[700]
                : Colors.red[700],
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          signal.x - textPainter.width / 2,
          signal.y - 85,
        ),
      );
    }

    // Draw train labels
    for (var train in trains) {
      final statusText = train.atPlatform
          ? 'PLATFORM'
          : train.hasStoppedAtSignal
              ? 'SIGNAL'
              : '${train.speed.toStringAsFixed(1)} km/h';

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${train.name}\n$statusText',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          train.x - textPainter.width / 2,
          train.y - 35,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(RailwayPainter oldDelegate) => true;
}
