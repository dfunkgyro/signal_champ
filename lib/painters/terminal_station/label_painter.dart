import 'package:flutter/material.dart';
import '../../screens/terminal_station_models.dart';

/// Painter responsible for drawing labels
class LabelPainter {
  void drawLabels(
      Canvas canvas,
      Map<String, BlockSection> blocks,
      Map<String, Signal> signals,
      List<Platform> platforms,
      List<Train> trains,
      bool signalsVisible) {
    // Draw block labels
    for (var block in blocks.values) {
      if (!block.id.startsWith('crossover')) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: block.id,
            style: TextStyle(
              color: block.occupied ? Colors.purple[700] : Colors.grey[700],
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
            canvas,
            Offset((block.startX + block.endX) / 2 - textPainter.width / 2,
                block.y - 30));
      }
    }

    // Draw signal labels
    if (signalsVisible) {
      for (var signal in signals.values) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: signal.id,
            style: TextStyle(
              color: signal.aspect == SignalAspect.green
                  ? Colors.green[700]
                  : Colors.red[700],
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
            canvas, Offset(signal.x - textPainter.width / 2, signal.y - 70));
      }
    }

    // Draw platform labels
    for (var platform in platforms) {
      final yOffset = platform.y == 100 ? 60 : -60;
      final textPainter = TextPainter(
        text: TextSpan(
          text: platform.name,
          style: const TextStyle(
              color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
          canvas,
          Offset(
              platform.centerX - textPainter.width / 2, platform.y + yOffset));
    }

    // Draw train labels
    for (var train in trains) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: train.name,
          style: const TextStyle(
              color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(train.x - textPainter.width / 2, train.y - 30));
    }
  }

  void drawDirectionLabels(Canvas canvas) {
    final eastboundText = TextPainter(
      text: const TextSpan(
        text: 'EASTBOUND ROAD',
        style: TextStyle(
          color: Colors.green,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    eastboundText.layout();
    eastboundText.paint(canvas, const Offset(600, 50));

    final westboundText = TextPainter(
      text: const TextSpan(
        text: 'WESTBOUND ROAD',
        style: TextStyle(
          color: Colors.blue,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    westboundText.layout();
    westboundText.paint(canvas, const Offset(600, 350));
  }
}
