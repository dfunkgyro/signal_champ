import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../screens/terminal_station_models.dart';

/// Painter responsible for drawing movement authority arrows
class MovementAuthorityPainter {
  void drawMovementAuthorities(Canvas canvas, List<Train> trains) {
    // Get current time for animation
    final animationOffset =
        (DateTime.now().millisecondsSinceEpoch % 2000) / 2000.0;

    for (var train in trains) {
      // Only draw for CBTC trains with movement authority
      if (!train.isCbtcEquipped || train.movementAuthority == null) continue;
      if (train.cbtcMode != CbtcMode.auto &&
          train.cbtcMode != CbtcMode.pm &&
          train.cbtcMode != CbtcMode.rm) continue;

      final ma = train.movementAuthority!;
      if (ma.maxDistance <= 0) continue;

      final trainX = train.x;
      final trainY = train.y;
      final isEastbound = train.direction > 0;

      // Calculate start and end positions for the green arrow path
      final startX =
          isEastbound ? trainX + 35 : trainX - 35; // Start just ahead of train
      final endX =
          isEastbound ? trainX + ma.maxDistance : trainX - ma.maxDistance;

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
          Offset(startX, trainY - 25),
          Offset(endX, trainY - 25),
        ))
        ..style = PaintingStyle.fill;

      // Draw the main authority path as a rounded rectangle
      final pathRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          isEastbound ? startX : endX,
          trainY - 25,
          isEastbound ? endX : startX,
          trainY - 15,
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
        final arrowY = trainY - 20;

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
          Offset(endX, trainY - 30),
          Offset(endX, trainY - 10),
          Paint()
            ..color = ma.hasDestination ? Colors.blue : Colors.orange
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );

        // Draw small circle at top of line
        canvas.drawCircle(
          Offset(endX, trainY - 30),
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
            trainY - 42,
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
          trainY - 25,
          isEastbound ? endX : startX,
          trainY - 15,
        ),
        const Radius.circular(3),
      );
      canvas.drawRRect(glowRect, glowPaint);
    }
  }
}
