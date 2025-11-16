import 'package:flutter/material.dart';
import '../../screens/terminal_station_models.dart';

/// Painter responsible for drawing signals
class SignalPainter {
  void drawSignals(Canvas canvas, Map<String, Signal> signals,
      bool signalsVisible) {
    if (!signalsVisible) return;

    for (var signal in signals.values) {
      final polePaint = Paint()
        ..color = Colors.grey[800]!
        ..strokeWidth = 5;

      canvas.drawLine(Offset(signal.x, signal.y),
          Offset(signal.x, signal.y - 40), polePaint);

      drawSignalHead(canvas, signal);
    }
  }

  void drawSignalHead(Canvas canvas, Signal signal) {
    final headPaint = Paint()
      ..color = Colors.grey[900]!
      ..style = PaintingStyle.fill;

    bool pointerWest = signal.id == 'C30' || signal.id == 'C28';

    if (pointerWest) {
      final path = Path()
        ..moveTo(signal.x + 15, signal.y - 55)
        ..lineTo(signal.x - 15, signal.y - 55)
        ..lineTo(signal.x - 25, signal.y - 42.5)
        ..lineTo(signal.x - 15, signal.y - 30)
        ..lineTo(signal.x + 15, signal.y - 30)
        ..close();
      canvas.drawPath(path, headPaint);
    } else {
      final path = Path()
        ..moveTo(signal.x - 15, signal.y - 55)
        ..lineTo(signal.x + 15, signal.y - 55)
        ..lineTo(signal.x + 25, signal.y - 42.5)
        ..lineTo(signal.x + 15, signal.y - 30)
        ..lineTo(signal.x - 15, signal.y - 30)
        ..close();
      canvas.drawPath(path, headPaint);
    }

    final lightColor =
        signal.aspect == SignalAspect.green ? Colors.green : Colors.red;
    final lightPaint = Paint()
      ..color = lightColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(signal.x, signal.y - 42.5), 6, lightPaint);

    if (signal.aspect == SignalAspect.green) {
      final glowPaint = Paint()
        ..color = Colors.green.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawCircle(Offset(signal.x, signal.y - 42.5), 12, glowPaint);
    }
  }
}
