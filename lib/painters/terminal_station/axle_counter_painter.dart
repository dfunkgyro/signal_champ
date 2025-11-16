import 'package:flutter/material.dart';
import '../../controllers/terminal_station_controller.dart';

/// Painter responsible for drawing axle counters and AB occupations
class AxleCounterPainter {
  void drawAxleCounters(
      Canvas canvas, TerminalStationController controller) {
    if (!controller.axleCountersVisible) return;

    for (var counter in controller.axleCounters.values) {
      final d1Paint = Paint()
        ..color = counter.d1Active ? Colors.purple : Colors.grey[700]!
        ..style = PaintingStyle.fill;

      final d2Paint = Paint()
        ..color = counter.d2Active ? Colors.purple : Colors.grey[700]!
        ..style = PaintingStyle.fill;

      final d1X = counter.x - 5;
      final d2X = counter.x + 5;
      final dY = counter.y;

      canvas.drawCircle(Offset(d1X, dY), 3, d1Paint);
      canvas.drawCircle(Offset(d2X, dY), 3, d2Paint);

      final displayLabel = counter.twinLabel ?? counter.id;
      final textPainter = TextPainter(
        text: TextSpan(
          text: displayLabel,
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
          canvas, Offset(counter.x - textPainter.width / 2, counter.y + 8));
    }
  }

  void drawABOccupations(
      Canvas canvas, TerminalStationController controller) {
    if (!controller.axleCountersVisible) return;

    final Map<String, Offset> abPositions = {
      'AB105': const Offset(500, 315),
      'AB100': const Offset(300, 115),
      'AB108': const Offset(900, 115),
      'AB106': const Offset(675, 200), // AB106 position on crossover
      'AB111': const Offset(1000, 315), // AB111 position
    };

    for (var abId in abPositions.keys) {
      final position = abPositions[abId]!;
      final isOccupied = controller.ace.isABOccupied(abId);

      final textPainter = TextPainter(
        text: TextSpan(
          text: abId,
          style: TextStyle(
            color: isOccupied ? Colors.purple : Colors.grey[600],
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(position.dx - textPainter.width / 2, position.dy));

      if (isOccupied) {
        final linePaint = Paint()
          ..color = Colors.purple
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;

        switch (abId) {
          case 'AB105':
            canvas.drawLine(
                const Offset(100, 315), const Offset(700, 315), linePaint);
            break;
          case 'AB109':
            canvas.drawLine(
                const Offset(500, 315), const Offset(700, 315), linePaint);
            break;
          case 'AB100':
            canvas.drawLine(
                const Offset(100, 115), const Offset(550, 115), linePaint);
            break;
          case 'AB104':
            canvas.drawLine(
                const Offset(550, 115), const Offset(700, 115), linePaint);
            break;
          case 'AB108':
            canvas.drawLine(
                const Offset(700, 115), const Offset(1300, 115), linePaint);
            break;
          case 'AB106':
            // Draw diagonal line along the crossover
            final path = Path()
              ..moveTo(600, 100)
              ..lineTo(800, 300);
            canvas.drawPath(path, linePaint);
            break;
          case 'AB111': // AB111 occupation line
            canvas.drawLine(
                const Offset(850, 315), const Offset(1150, 315), linePaint);
            break;
        }
      }
    }
  }
}
