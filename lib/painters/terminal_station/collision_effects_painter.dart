import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../screens/terminal_station_models.dart';
import '../../controllers/terminal_station_controller.dart';

// Collision Visual Effects Mixin
mixin CollisionVisualEffects {
  void drawCollisionEffects(
      Canvas canvas, TerminalStationController controller, int animationTick) {
    if (!controller.collisionAlarmActive) return;

    final recoveryPlans = controller.getActiveRecoveryPlans();

    for (var recoveryPlan in recoveryPlans) {
      for (var trainId in recoveryPlan.trainsInvolved) {
        try {
          final train = controller.trains.firstWhere((t) => t.id == trainId);

          _drawCollisionSparkles(canvas, train, animationTick);

          if (recoveryPlan.state == CollisionRecoveryState.recovery) {
            _drawRecoveryGuidance(canvas, train, recoveryPlan, controller);
          }

          _drawWarningCircle(canvas, train, animationTick);
        } catch (e) {
          // Train removed, skip
        }
      }

      _drawRecoveryProgress(canvas, recoveryPlan);
    }
  }

  void _drawCollisionSparkles(Canvas canvas, Train train, int animationTick) {
    final sparklePaint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(DateTime.now().millisecond + train.x.toInt());

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30.0 + (animationTick * 3)) * (math.pi / 180);
      final distance = 25 + (animationTick % 20) * 1.5;
      final offsetX = train.x + math.cos(angle) * distance;
      final offsetY = train.y + math.sin(angle) * distance;
      final opacity = math.max(0.0, 1.0 - ((animationTick % 20) / 20.0));
      final size = 2.0 + random.nextDouble() * 3.0;
      final color = i % 2 == 0
          ? Colors.orange.withOpacity(opacity)
          : Colors.red.withOpacity(opacity);

      sparklePaint.color = color;
      canvas.drawCircle(Offset(offsetX, offsetY), size, sparklePaint);
    }

    if (animationTick % 40 < 5) {
      final flashPaint = Paint()
        ..color = Colors.white.withOpacity(0.6 - (animationTick % 40) * 0.12)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(train.x, train.y), 40.0, flashPaint);
    }
  }

  void _drawWarningCircle(Canvas canvas, Train train, int animationTick) {
    final warningPaint = Paint()
      ..color =
          Colors.red.withOpacity(0.3 + (math.sin(animationTick * 0.1) * 0.2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final radius = 35.0 + math.sin(animationTick * 0.15) * 5.0;
    canvas.drawCircle(Offset(train.x, train.y), radius, warningPaint);

    final innerPaint = Paint()
      ..color = Colors.orange.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset(train.x, train.y), radius - 10, innerPaint);
  }

  void _drawRecoveryGuidance(Canvas canvas, Train train,
      CollisionRecoveryPlan plan, TerminalStationController controller) {
    final targetBlockId = plan.reverseInstructions[train.id];
    if (targetBlockId == null) return;

    final targetBlock = controller.blocks[targetBlockId];
    if (targetBlock == null) return;

    final arrowPaint = Paint()
      ..color = Colors.green.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final targetX =
        targetBlock.startX + (targetBlock.endX - targetBlock.startX) / 2;
    final targetY = targetBlock.y;

    final path = Path();
    path.moveTo(train.x, train.y - 30);
    final controlX = (train.x + targetX) / 2;
    final controlY = train.y - 50;
    path.quadraticBezierTo(controlX, controlY, targetX, targetY - 30);
    canvas.drawPath(path, arrowPaint);

    final arrowHeadPaint = Paint()
      ..color = Colors.green.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final arrowPath = Path();
    arrowPath.moveTo(targetX, targetY - 30);
    arrowPath.lineTo(targetX - 10, targetY - 45);
    arrowPath.lineTo(targetX + 10, targetY - 45);
    arrowPath.close();
    canvas.drawPath(arrowPath, arrowHeadPaint);

    final targetIndicatorPaint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(targetX, targetY), 20.0, targetIndicatorPaint);

    final crosshairPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(targetX - 15, targetY),
        Offset(targetX + 15, targetY), crosshairPaint);
    canvas.drawLine(Offset(targetX, targetY - 15),
        Offset(targetX, targetY + 15), crosshairPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'SAFE ZONE',
        style: TextStyle(
            color: Colors.green.shade700,
            fontSize: 10,
            fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
        canvas, Offset(targetX - textPainter.width / 2, targetY + 25));
  }

  void _drawRecoveryProgress(Canvas canvas, CollisionRecoveryPlan plan) {
    final x = 100.0;
    final y = 50.0;

    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, 250, 70), const Radius.circular(8));
    canvas.drawRRect(bgRect, bgPaint);

    final borderPaint = Paint()
      ..color = _getRecoveryStateColor(plan.state)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(bgRect, borderPaint);

    final titlePainter = TextPainter(
      text: const TextSpan(
        text: '🔧 COLLISION RECOVERY',
        style: TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout();
    titlePainter.paint(canvas, Offset(x + 10, y + 8));

    final statePainter = TextPainter(
      text: TextSpan(
        text: 'State: ${_getRecoveryStateText(plan.state)}',
        style:
            TextStyle(color: _getRecoveryStateColor(plan.state), fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    );
    statePainter.layout();
    statePainter.paint(canvas, Offset(x + 10, y + 28));

    final trainsPainter = TextPainter(
      text: TextSpan(
        text: 'Trains: ${plan.trainsInvolved.join(", ")}',
        style: const TextStyle(color: Colors.white70, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    );
    trainsPainter.layout();
    trainsPainter.paint(canvas, Offset(x + 10, y + 48));
  }

  Color _getRecoveryStateColor(CollisionRecoveryState state) {
    switch (state) {
      case CollisionRecoveryState.detected:
        return Colors.red;
      case CollisionRecoveryState.recovery:
        return Colors.orange;
      case CollisionRecoveryState.resolved:
        return Colors.green;
      case CollisionRecoveryState.manualOverride:
        return Colors.blue;
      case CollisionRecoveryState.none:
        return Colors.grey;
    }
  }

  String _getRecoveryStateText(CollisionRecoveryState state) {
    switch (state) {
      case CollisionRecoveryState.detected:
        return 'DETECTED';
      case CollisionRecoveryState.recovery:
        return 'RECOVERING...';
      case CollisionRecoveryState.resolved:
        return 'RESOLVED';
      case CollisionRecoveryState.manualOverride:
        return 'MANUAL CONTROL';
      case CollisionRecoveryState.none:
        return 'NONE';
    }
  }
}
