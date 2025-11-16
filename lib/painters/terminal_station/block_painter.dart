import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../screens/terminal_station_models.dart';

/// Painter responsible for drawing blocks, tracks, and crossovers
class BlockPainter {
  void drawTracks(Canvas canvas, Map<String, BlockSection> blocks) {
    for (var blockId in [
      '100',
      '102',
      '104',
      '106',
      '108',
      '110',
      '112',
      '114'
    ]) {
      drawBlock(canvas, blocks[blockId]!);
    }
    for (var blockId in ['101', '103', '105', '107', '109', '111']) {
      drawBlock(canvas, blocks[blockId]!);
    }
    drawCrossoverTrack(canvas, blocks);
  }

  void drawBlock(Canvas canvas, BlockSection block) {
    final blockPaint = Paint()
      ..color =
          block.occupied ? Colors.purple.withOpacity(0.3) : Colors.grey[300]!
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            block.startX, block.y - 15, block.endX - block.startX, 30),
        const Radius.circular(4),
      ),
      blockPaint,
    );

    // Draw two running rails for each block
    final outerRailPaint = Paint()
      ..color = Colors.grey[700]!
      ..strokeWidth = 3;

    final innerRailPaint = Paint()
      ..color = Colors.grey[700]!
      ..strokeWidth = 2;

    const railSpacing = 12.0;

    // Top rail (outer)
    canvas.drawLine(Offset(block.startX, block.y - 8 - railSpacing / 2),
        Offset(block.endX, block.y - 8 - railSpacing / 2), outerRailPaint);

    // Top rail (inner)
    canvas.drawLine(Offset(block.startX, block.y - 8 + railSpacing / 2),
        Offset(block.endX, block.y - 8 + railSpacing / 2), innerRailPaint);

    // Bottom rail (outer)
    canvas.drawLine(Offset(block.startX, block.y + 8 - railSpacing / 2),
        Offset(block.endX, block.y + 8 - railSpacing / 2), outerRailPaint);

    // Bottom rail (inner)
    canvas.drawLine(Offset(block.startX, block.y + 8 + railSpacing / 2),
        Offset(block.endX, block.y + 8 + railSpacing / 2), innerRailPaint);

    final sleeperPaint = Paint()
      ..color = Colors.brown[700]!
      ..strokeWidth = 6;

    for (double x = block.startX; x < block.endX; x += 15) {
      canvas.drawLine(
          Offset(x, block.y - 12), Offset(x, block.y + 12), sleeperPaint);
    }
  }

  void drawCrossoverTrack(Canvas canvas, Map<String, BlockSection> blocks) {
    // Draw two separate rails for the crossover with proper spacing
    final outerRailPaint = Paint()
      ..color = Colors.grey[700]!
      ..strokeWidth = 3; // Thicker rails for main tracks

    final innerRailPaint = Paint()
      ..color = Colors.grey[700]!
      ..strokeWidth = 2; // Slightly thinner for inner rails

    const railSpacing = 12.0; // Space between rails

    // First crossover: 600,100 to 700,200
    // Outer rail 1 (top-left to bottom-right)
    final path1a = Path()
      ..moveTo(600 - railSpacing / 2, 100 - railSpacing / 2)
      ..lineTo(700 - railSpacing / 2, 200 - railSpacing / 2);
    canvas.drawPath(path1a, outerRailPaint);

    // Inner rail 1 (top-left to bottom-right)
    final path1b = Path()
      ..moveTo(600 + railSpacing / 2, 100 + railSpacing / 2)
      ..lineTo(700 + railSpacing / 2, 200 + railSpacing / 2);
    canvas.drawPath(path1b, innerRailPaint);

    // Second crossover: 700,200 to 800,300
    // Outer rail 2 (top-left to bottom-right)
    final path2a = Path()
      ..moveTo(700 - railSpacing / 2, 200 - railSpacing / 2)
      ..lineTo(800 - railSpacing / 2, 300 - railSpacing / 2);
    canvas.drawPath(path2a, outerRailPaint);

    // Inner rail 2 (top-left to bottom-right)
    final path2b = Path()
      ..moveTo(700 + railSpacing / 2, 200 + railSpacing / 2)
      ..lineTo(800 + railSpacing / 2, 300 + railSpacing / 2);
    canvas.drawPath(path2b, innerRailPaint);

    // Draw sleepers for both crossovers
    final sleeperPaint = Paint()
      ..color = Colors.brown[700]!
      ..strokeWidth = 4;

    for (double t = 0; t <= 1.0; t += 0.1) {
      // First crossover sleepers
      final x1 = 600 + (100 * t);
      final y1 = 100 + (100 * t);
      canvas.drawLine(
          Offset(x1 - 10, y1 + 10), Offset(x1 + 10, y1 - 10), sleeperPaint);

      // Second crossover sleepers
      final x2 = 700 + (100 * t);
      final y2 = 200 + (100 * t);
      canvas.drawLine(
          Offset(x2 - 10, y2 + 10), Offset(x2 + 10, y2 - 10), sleeperPaint);
    }

    // Highlight occupied crossover blocks
    final block106 = blocks['crossover106'];
    final block109 = blocks['crossover109'];

    if (block106 != null && block106.occupied) {
      final highlightPaint = Paint()
        ..color = Colors.purple.withOpacity(0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(650, 150), 40, highlightPaint);
    }
    if (block109 != null && block109.occupied) {
      final highlightPaint = Paint()
        ..color = Colors.purple.withOpacity(0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(750, 250), 40, highlightPaint);
    }
  }

  void drawBlockReservation(Canvas canvas, BlockSection block, Color color) {
    final reservationPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final dashPath = Path();
    double currentX = block.startX;
    const dashLength = 10.0;
    const gapLength = 5.0;

    while (currentX < block.endX) {
      dashPath.moveTo(currentX, block.y);
      dashPath.lineTo(math.min(currentX + dashLength, block.endX), block.y);
      currentX += dashLength + gapLength;
    }

    canvas.drawPath(dashPath, reservationPaint);
  }

  void drawCrossoverReservation(
      Canvas canvas, BlockSection block, Color reservationColor) {
    final reservationPaint = Paint()
      ..color = reservationColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const dashLength = 10.0;
    const gapLength = 5.0;

    if (block.id == 'crossover106') {
      double totalDistance = math.sqrt(math.pow(100, 2) + math.pow(100, 2));
      double currentDistance = 0;
      bool drawDash = true;

      while (currentDistance < totalDistance) {
        double t1 = currentDistance / totalDistance;
        double t2 =
            math.min((currentDistance + dashLength) / totalDistance, 1.0);

        if (drawDash) {
          final x1 = 600 + (100 * t1);
          final y1 = 100 + (100 * t1);
          final x2 = 600 + (100 * t2);
          final y2 = 100 + (100 * t2);
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), reservationPaint);
        }

        currentDistance += dashLength + gapLength;
        drawDash = !drawDash;
      }
    } else if (block.id == 'crossover109') {
      double totalDistance = math.sqrt(math.pow(100, 2) + math.pow(100, 2));
      double currentDistance = 0;
      bool drawDash = true;

      while (currentDistance < totalDistance) {
        double t1 = currentDistance / totalDistance;
        double t2 =
            math.min((currentDistance + dashLength) / totalDistance, 1.0);

        if (drawDash) {
          final x1 = 700 + (100 * t1);
          final y1 = 200 + (100 * t1);
          final x2 = 700 + (100 * t2);
          final y2 = 200 + (100 * t2);
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), reservationPaint);
        }

        currentDistance += dashLength + gapLength;
        drawDash = !drawDash;
      }
    }
  }
}
