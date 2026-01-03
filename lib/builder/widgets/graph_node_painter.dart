import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/graph_model.dart';

class GraphNodePainter extends CustomPainter {
  final GraphNodeType type;
  final bool isSelected;

  GraphNodePainter({
    required this.type,
    required this.isSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..color = isSelected ? Colors.black : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2 : 1;

    switch (type) {
      case GraphNodeType.block:
        _drawBlock(canvas, size, outline);
        break;
      case GraphNodeType.crossover:
        _drawCrossover(canvas, size, outline);
        break;
      case GraphNodeType.point:
        _drawPoint(canvas, size, outline);
        break;
      case GraphNodeType.signal:
        _drawSignal(canvas, size, outline);
        break;
      case GraphNodeType.platform:
        _drawPlatform(canvas, size, outline);
        break;
      case GraphNodeType.trainStop:
        _drawTrainStop(canvas, size, outline);
        break;
      case GraphNodeType.bufferStop:
        _drawBufferStop(canvas, size, outline);
        break;
      case GraphNodeType.axleCounter:
        _drawAxleCounter(canvas, size, outline);
        break;
      case GraphNodeType.transponder:
        _drawTransponder(canvas, size, outline);
        break;
      case GraphNodeType.wifiAntenna:
        _drawWifiAntenna(canvas, size, outline);
        break;
      case GraphNodeType.routeReservation:
        _drawRouteReservation(canvas, size, outline);
        break;
      case GraphNodeType.movementAuthority:
        _drawMovementAuthority(canvas, size, outline);
        break;
      case GraphNodeType.train:
        _drawTrain(canvas, size, outline);
        break;
      case GraphNodeType.text:
        _drawTextNote(canvas, size, outline);
        break;
    }
  }

  void _drawBlock(Canvas canvas, Size size, Paint outline) {
    final bodyPaint = Paint()..color = const Color(0xFF2E86AB);
    final railPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final sleeperPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 2;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, size.height / 2 - 14, size.width - 16, 28),
      const Radius.circular(12),
    );
    canvas.drawRRect(rect, bodyPaint);
    canvas.drawRRect(rect, outline);

    final railY1 = size.height / 2 - 6;
    final railY2 = size.height / 2 + 6;
    canvas.drawLine(Offset(18, railY1), Offset(size.width - 18, railY1), railPaint);
    canvas.drawLine(Offset(18, railY2), Offset(size.width - 18, railY2), railPaint);

    for (double x = 22; x < size.width - 22; x += 12) {
      canvas.drawLine(Offset(x, railY1 - 6), Offset(x, railY2 + 6), sleeperPaint);
    }
  }

  void _drawCrossover(Canvas canvas, Size size, Paint outline) {
    final paint = Paint()
      ..color = const Color(0xFF4C566A)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(20, size.height - 20),
      Offset(size.width - 20, 20),
      paint,
    );
    canvas.drawLine(
      Offset(20, 20),
      Offset(size.width - 20, size.height - 20),
      paint,
    );

    final ring = Paint()
      ..color = const Color(0xFFEDF2F4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 8, ring);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 8, outline);
  }

  void _drawPoint(Canvas canvas, Size size, Paint outline) {
    final trackPaint = Paint()
      ..color = const Color(0xFF2A9D8F)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final divergePaint = Paint()
      ..color = const Color(0xFFB56576)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    canvas.drawLine(Offset(12, centerY), Offset(size.width - 12, centerY), trackPaint);
    canvas.drawLine(
      Offset(size.width * 0.4, centerY),
      Offset(size.width - 14, 14),
      divergePaint,
    );

    final knobPaint = Paint()..color = const Color(0xFF264653);
    canvas.drawCircle(Offset(size.width * 0.38, centerY), 6, knobPaint);
    canvas.drawCircle(Offset(size.width * 0.38, centerY), 6, outline);
  }

  void _drawSignal(Canvas canvas, Size size, Paint outline) {
    final polePaint = Paint()
      ..color = const Color(0xFF1D3557)
      ..strokeWidth = 4;
    final headPaint = Paint()..color = const Color(0xFFE63946);
    final glowPaint = Paint()
      ..color = const Color(0xFFE63946).withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final poleX = size.width / 2;
    canvas.drawLine(Offset(poleX, size.height - 12), Offset(poleX, 12), polePaint);
    canvas.drawCircle(Offset(poleX, 20), 10, glowPaint);
    canvas.drawCircle(Offset(poleX, 20), 8, headPaint);
    canvas.drawCircle(Offset(poleX, 20), 8, outline);
  }

  void _drawPlatform(Canvas canvas, Size size, Paint outline) {
    final platformPaint = Paint()..color = const Color(0xFF6D597A);
    final edgePaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 3;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(10, size.height / 2 - 16, size.width - 20, 32),
      const Radius.circular(16),
    );
    canvas.drawRRect(rect, platformPaint);
    canvas.drawRRect(rect, outline);
    canvas.drawLine(
      Offset(16, size.height / 2 - 10),
      Offset(size.width - 16, size.height / 2 - 10),
      edgePaint,
    );
  }

  void _drawTrainStop(Canvas canvas, Size size, Paint outline) {
    final paint = Paint()..color = const Color(0xFFF4A261);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width / 2 - 24, size.height / 2 - 14, 48, 28),
      const Radius.circular(8),
    );
    canvas.drawRRect(rect, paint);
    canvas.drawRRect(rect, outline);
    final markerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(size.width / 2 - 10, size.height / 2),
      Offset(size.width / 2 + 10, size.height / 2),
      markerPaint,
    );
  }

  void _drawBufferStop(Canvas canvas, Size size, Paint outline) {
    final paint = Paint()..color = const Color(0xFFB00020);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width / 2 - 28, size.height / 2 - 14, 56, 28),
      const Radius.circular(6),
    );
    canvas.drawRRect(rect, paint);
    canvas.drawRRect(rect, outline);

    final stripePaint = Paint()
      ..color = const Color(0xFFFFD166)
      ..strokeWidth = 3;
    for (double x = rect.left + 6; x < rect.right - 4; x += 8) {
      canvas.drawLine(Offset(x, rect.top + 4), Offset(x + 4, rect.bottom - 4), stripePaint);
    }
  }

  void _drawAxleCounter(Canvas canvas, Size size, Paint outline) {
    final paint = Paint()..color = const Color(0xFF457B9D);
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center.translate(-12, 0), 10, paint);
    canvas.drawCircle(center.translate(12, 0), 10, paint);
    canvas.drawLine(center.translate(-2, 0), center.translate(2, 0), outline);
    canvas.drawCircle(center.translate(-12, 0), 10, outline);
    canvas.drawCircle(center.translate(12, 0), 10, outline);
  }

  void _drawTransponder(Canvas canvas, Size size, Paint outline) {
    final paint = Paint()..color = const Color(0xFF118AB2);
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCenter(center: center, width: 28, height: 28);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.pi / 4);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, outline);
    canvas.restore();
  }

  void _drawWifiAntenna(Canvas canvas, Size size, Paint outline) {
    final paint = Paint()
      ..color = const Color(0xFF06D6A0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final center = Offset(size.width / 2, size.height / 2 + 6);
    canvas.drawCircle(center, 4, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;
    canvas.drawArc(Rect.fromCircle(center: center, radius: 16), -math.pi * 0.75,
        math.pi * 1.5, false, paint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: 24), -math.pi * 0.75,
        math.pi * 1.5, false, paint);
  }

  void _drawRouteReservation(Canvas canvas, Size size, Paint outline) {
    final paint = Paint()
      ..color = const Color(0xFFF1C40F).withOpacity(0.35)
      ..style = PaintingStyle.fill;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(10, size.height / 2 - 14, size.width - 20, 28),
      const Radius.circular(12),
    );
    canvas.drawRRect(rect, paint);
    canvas.drawRRect(rect, outline);
  }

  void _drawMovementAuthority(Canvas canvas, Size size, Paint outline) {
    final paint = Paint()
      ..color = const Color(0xFF2ECC71)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final start = Offset(16, size.height / 2);
    final end = Offset(size.width - 20, size.height / 2);
    canvas.drawLine(start, end, paint);
    final arrowPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(end.dx - 12, end.dy - 8)
      ..lineTo(end.dx - 12, end.dy + 8)
      ..close();
    canvas.drawPath(arrowPath, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;
  }

  void _drawTrain(Canvas canvas, Size size, Paint outline) {
    final paint = Paint()..color = const Color(0xFF1D3557);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(10, size.height / 2 - 16, size.width - 20, 32),
      const Radius.circular(16),
    );
    canvas.drawRRect(rect, paint);
    canvas.drawRRect(rect, outline);

    final windowPaint = Paint()..color = const Color(0xFFE9ECEF);
    for (double x = rect.left + 10; x < rect.right - 10; x += 16) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, rect.top + 8, 10, 10),
          const Radius.circular(4),
        ),
        windowPaint,
      );
    }
  }

  void _drawTextNote(Canvas canvas, Size size, Paint outline) {
    final paint = Paint()..color = const Color(0xFFFFE08A);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(10, 10, size.width - 20, size.height - 20),
      const Radius.circular(10),
    );
    canvas.drawRRect(rect, paint);
    canvas.drawRRect(rect, outline);
    final foldPaint = Paint()..color = const Color(0xFFFFD166);
    final fold = Path()
      ..moveTo(rect.right - 12, rect.top)
      ..lineTo(rect.right, rect.top + 12)
      ..lineTo(rect.right, rect.top)
      ..close();
    canvas.drawPath(fold, foldPaint);
  }

  @override
  bool shouldRepaint(covariant GraphNodePainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.isSelected != isSelected;
  }
}
