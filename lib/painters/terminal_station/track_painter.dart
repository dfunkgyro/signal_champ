import 'package:flutter/material.dart';
import '../../screens/terminal_station_models.dart';
import '../../controllers/terminal_station_controller.dart';

/// Painter responsible for drawing track infrastructure (points, platforms, buffer stops, train stops)
class TrackPainter {
  void drawPoints(
      Canvas canvas, Map<String, Point> points, TerminalStationController controller) {
    for (var point in points.values) {
      Color pointColor;

      // Determine point color based on state
      final ab106Occupied = controller.ace.isABOccupied('AB106');
      final isABDeadlocked =
          (point.id == '78A' || point.id == '78B') && ab106Occupied;

      if (isABDeadlocked) {
        pointColor =
            Colors.deepOrange; // Orange for AB106 deadlock (both points)
      } else if (point.lockedByAB) {
        pointColor = Colors.red; // Red for individual AB deadlock
      } else if (point.locked) {
        pointColor = Colors.blue; // Blue for manual lock
      } else if (point.position == PointPosition.normal) {
        pointColor = Colors.teal; // Teal for normal position
      } else {
        pointColor = Colors.green; // Green for reverse position
      }

      final pointPaint = Paint()
        ..color = pointColor
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(Offset(point.x, point.y), 12, pointPaint);

      final outlinePaint = Paint()
        ..color = point.locked || point.lockedByAB || isABDeadlocked
            ? (isABDeadlocked ? Colors.deepOrange : Colors.red)
            : Colors.teal
        ..style = PaintingStyle.stroke
        ..strokeWidth =
            point.locked || point.lockedByAB || isABDeadlocked ? 3 : 1;

      canvas.drawCircle(Offset(point.x, point.y), 12, outlinePaint);

      // Draw lock indicator
      if (point.locked || point.lockedByAB || isABDeadlocked) {
        final lockPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 2;

        canvas.drawLine(Offset(point.x - 4, point.y - 2),
            Offset(point.x + 4, point.y - 2), lockPaint);
        canvas.drawLine(Offset(point.x - 4, point.y + 2),
            Offset(point.x + 4, point.y + 2), lockPaint);

        // Draw AB deadlock indicator
        if (point.lockedByAB || isABDeadlocked) {
          final abLockPaint = Paint()
            ..color = isABDeadlocked ? Colors.deepOrange : Colors.red
            ..style = PaintingStyle.fill;
          canvas.drawCircle(Offset(point.x, point.y), 4, abLockPaint);

          // Draw "106" text for AB106 deadlock
          if (isABDeadlocked) {
            final textPainter = TextPainter(
              text: const TextSpan(
                text: '106',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 6,
                  fontWeight: FontWeight.bold,
                ),
              ),
              textDirection: TextDirection.ltr,
            );
            textPainter.layout();
            textPainter.paint(canvas, Offset(point.x - 6, point.y - 3));
          }
        }
      }

      drawPointGaps(canvas, point);
    }
  }

  void drawPointGaps(Canvas canvas, Point point) {
    final gapPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.fill;

    if (point.id == '78A') {
      if (point.position == PointPosition.normal) {
        canvas.drawRect(Rect.fromLTWH(592.5, 112, 50, 12), gapPaint);
      } else {
        final path = Path()
          ..moveTo(597, 77.5)
          ..lineTo(650, 77.5)
          ..lineTo(650, 123)
          ..close();
        canvas.drawPath(path, gapPaint);
      }
    } else if (point.id == '78B') {
      if (point.position == PointPosition.normal) {
        canvas.drawRect(Rect.fromLTWH(757.5, 277, 50, 12), gapPaint);
      } else {
        final path = Path()
          ..moveTo(760, 279)
          ..lineTo(797, 317.5)
          ..lineTo(760, 317.5)
          ..close();
        canvas.drawPath(path, gapPaint);
      }
    }
  }

  void drawPlatforms(Canvas canvas, List<Platform> platforms) {
    for (var platform in platforms) {
      final platformPaint = Paint()
        ..color = Colors.yellow[700]!
        ..style = PaintingStyle.fill;

      final yOffset = platform.y == 100 ? 40 : -40;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(platform.startX, platform.y + yOffset - 15,
              platform.endX - platform.startX, 30),
          const Radius.circular(8),
        ),
        platformPaint,
      );

      final edgePaint = Paint()
        ..color = Colors.amber[900]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(platform.startX, platform.y + yOffset - 15,
              platform.endX - platform.startX, 30),
          const Radius.circular(8),
        ),
        edgePaint,
      );
    }
  }

  void drawBufferStop(Canvas canvas) {
    final bufferPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    canvas.drawRect(const Rect.fromLTWH(1190, 285, 20, 30), bufferPaint);

    final stripePaint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 2;

    for (int i = 0; i < 5; i++) {
      canvas.drawLine(
        Offset(1190 + (i * 5), 285),
        Offset(1195 + (i * 5), 315),
        stripePaint,
      );
    }
  }

  void drawTrainStops(
      Canvas canvas, Map<String, TrainStop> trainStops, bool trainStopsEnabled) {
    if (!trainStopsEnabled) return;

    for (var trainStop in trainStops.values) {
      if (!trainStop.enabled) continue;

      final stopPaint = Paint()
        ..color = trainStop.active ? Colors.red : Colors.green
        ..style = PaintingStyle.fill
        ..strokeWidth = 3;

      final centerX = trainStop.x;
      final centerY = trainStop.y;

      canvas.drawLine(
        Offset(centerX, centerY - 12),
        Offset(centerX, centerY + 12),
        stopPaint,
      );

      canvas.drawLine(
        Offset(centerX - 8, centerY - 12),
        Offset(centerX + 8, centerY - 12),
        stopPaint,
      );

      final outlinePaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawLine(
        Offset(centerX, centerY - 12),
        Offset(centerX, centerY + 12),
        outlinePaint,
      );
      canvas.drawLine(
        Offset(centerX - 8, centerY - 12),
        Offset(centerX + 8, centerY - 12),
        outlinePaint,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: trainStop.id,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(centerX - textPainter.width / 2, centerY + 15));
    }
  }
}
