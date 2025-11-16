import 'package:flutter/material.dart';
import '../../screens/terminal_station_models.dart';

/// Painter responsible for drawing trains
class TrainPainter {
  void drawTrains(Canvas canvas, List<Train> trains) {
    for (var train in trains) {
      canvas.save();
      if (train.rotation != 0.0) {
        canvas.translate(train.x, train.y);
        canvas.rotate(train.rotation);
        canvas.translate(-train.x, -train.y);
      }

      final bodyPaint = Paint()
        ..color = train.color
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(train.x - 30, train.y - 15, 60, 30),
          const Radius.circular(6),
        ),
        bodyPaint,
      );

      final outlinePaint = Paint()
        ..color = train.controlMode == TrainControlMode.manual
            ? Colors.blue
            : Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = train.controlMode == TrainControlMode.manual ? 3 : 2;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(train.x - 30, train.y - 15, 60, 30),
          const Radius.circular(6),
        ),
        outlinePaint,
      );

      if (train.doorsOpen) {
        final doorPaint = Paint()
          ..color = Colors.black
          ..style = PaintingStyle.fill;

        final leftDoorRect = Rect.fromLTWH(
          train.x - 28,
          train.y - 13,
          8,
          26,
        );

        final rightDoorRect = Rect.fromLTWH(
          train.x + 20,
          train.y - 13,
          8,
          26,
        );

        canvas.drawRect(leftDoorRect, doorPaint);
        canvas.drawRect(rightDoorRect, doorPaint);

        final doorOutlinePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        canvas.drawRect(leftDoorRect, doorOutlinePaint);
        canvas.drawRect(rightDoorRect, doorOutlinePaint);
      } else {
        final windowPaint = Paint()..color = Colors.lightBlue[100]!;
        canvas.drawRect(
            Rect.fromLTWH(train.x - 22, train.y - 10, 12, 8), windowPaint);
        canvas.drawRect(
            Rect.fromLTWH(train.x - 6, train.y - 10, 12, 8), windowPaint);
        canvas.drawRect(
            Rect.fromLTWH(train.x + 10, train.y - 10, 12, 8), windowPaint);
      }

      final wheelPaint = Paint()..color = Colors.black;
      canvas.drawCircle(Offset(train.x - 18, train.y + 15), 6, wheelPaint);
      canvas.drawCircle(Offset(train.x + 18, train.y + 15), 6, wheelPaint);

      final arrowPaint = Paint()
        ..color = train.direction > 0 ? Colors.green : Colors.orange
        ..style = PaintingStyle.fill;

      if (train.direction > 0) {
        final arrowPath = Path()
          ..moveTo(train.x + 26, train.y)
          ..lineTo(train.x + 20, train.y - 6)
          ..lineTo(train.x + 20, train.y + 6)
          ..close();
        canvas.drawPath(arrowPath, arrowPaint);
      } else {
        final arrowPath = Path()
          ..moveTo(train.x - 26, train.y)
          ..lineTo(train.x - 20, train.y - 6)
          ..lineTo(train.x - 20, train.y + 6)
          ..close();
        canvas.drawPath(arrowPath, arrowPaint);
      }

      if (train.manualStop) {
        final stopPaint = Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(train.x, train.y - 25), 8, stopPaint);
      }

      if (train.emergencyBrake) {
        final emergencyPaint = Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(train.x, train.y + 25), 8, emergencyPaint);

        final textPainter = TextPainter(
          text: const TextSpan(
              text: 'E',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(train.x - 4, train.y + 20));
      }

      if (train.controlMode == TrainControlMode.manual) {
        final badgePaint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(train.x, train.y + 25), 8, badgePaint);

        final textPainter = TextPainter(
          text: const TextSpan(
              text: 'M',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(train.x - 4, train.y + 20));
      }

      if (train.doorsOpen) {
        final doorPaint = Paint()
          ..color = Colors.orange
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(train.x, train.y - 35), 6, doorPaint);

        final textPainter = TextPainter(
          text: const TextSpan(
            text: 'D',
            style: TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(train.x - 3, train.y - 38));
      }

      canvas.restore();
    }
  }
}
