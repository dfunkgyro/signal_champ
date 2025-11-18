import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'terminal_station_models.dart';
import '../controllers/terminal_station_controller.dart';
import '../controllers/canvas_theme_controller.dart';
import 'package:rail_champ/models/railway_model.dart' show WifiAntenna, Transponder, TransponderType;

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

class TerminalStationPainter extends CustomPainter with CollisionVisualEffects {
  final TerminalStationController controller;
  final double cameraOffsetX;
  final double cameraOffsetY;  // FIXED: Add Y offset parameter
  final double zoom;
  final int animationTick;
  final double canvasWidth;
  final double canvasHeight;
  final CanvasThemeData themeData;  // NEW: Canvas theme support

  TerminalStationPainter({
    required this.controller,
    required this.cameraOffsetX,
    required this.cameraOffsetY,  // FIXED: Add Y offset parameter
    required this.zoom,
    required this.animationTick,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.themeData,  // NEW: Canvas theme support
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw themed background
    final backgroundPaint = Paint()
      ..color = themeData.canvasBackgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(zoom);
    canvas.translate(cameraOffsetX, cameraOffsetY);  // FIXED: Use Y offset for panning

    _drawTracks(canvas);
    _drawRouteReservations(canvas);
    _drawPlatforms(canvas);
    _drawBufferStop(canvas);
    _drawPoints(canvas);
    _drawSignals(canvas);
    _drawTrainStops(canvas);
    _drawAxleCounters(canvas);
    _drawABOccupations(canvas);
    _drawWiFiAntennas(canvas); // FIXED: Draw WiFi coverage zones
    _drawTransponders(canvas); // FIXED: Draw track transponders
    _drawMovementAuthorities(canvas); // Draw movement authority arrows before trains
    _drawTrains(canvas);
    _drawDirectionLabels(canvas);
    _drawLabels(canvas);

    drawCollisionEffects(canvas, controller, animationTick);

    canvas.restore();
  }

  // FIXED: Draw WiFi Antennas with coverage range circles
  void _drawWiFiAntennas(Canvas canvas) {
    if (!controller.cbtcDevicesEnabled) return;

    for (var antenna in controller.wifiAntennas.values) {
      // Draw coverage range circle (transparent)
      final rangePaint = Paint()
        ..color = antenna.isActive
            ? Colors.blue.withOpacity(0.08)
            : Colors.grey.withOpacity(0.05)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(antenna.x, antenna.y), 350.0, rangePaint); // 350 unit range

      // Draw range outline
      final rangeOutline = Paint()
        ..color = antenna.isActive
            ? Colors.blue.withOpacity(0.3)
            : Colors.grey.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(Offset(antenna.x, antenna.y), 350.0, rangeOutline);

      // Draw WiFi icon/antenna tower
      final antennaPaint = Paint()
        ..color = antenna.isActive ? Colors.blue : Colors.grey
        ..style = PaintingStyle.fill;

      // Antenna base
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(antenna.x, antenna.y),
          width: 8,
          height: 20,
        ),
        antennaPaint,
      );

      // Antenna signal waves (if active)
      if (antenna.isActive) {
        final wavePaint = Paint()
          ..color = Colors.blue.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        // Animated signal waves
        final waveOffset = (animationTick % 30) / 30.0;
        for (int i = 0; i < 3; i++) {
          double radius = 15.0 + (i * 8.0) + (waveOffset * 8.0);
          canvas.drawArc(
            Rect.fromCenter(
              center: Offset(antenna.x, antenna.y),
              width: radius * 2,
              height: radius * 2,
            ),
            -2.5,
            1.0,
            false,
            wavePaint,
          );
          canvas.drawArc(
            Rect.fromCenter(
              center: Offset(antenna.x, antenna.y),
              width: radius * 2,
              height: radius * 2,
            ),
            0.5,
            1.0,
            false,
            wavePaint,
          );
        }
      }

      // Label
      final textPainter = TextPainter(
        text: TextSpan(
          text: antenna.id,
          style: TextStyle(
            color: antenna.isActive ? Colors.blue : Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(antenna.x - textPainter.width / 2, antenna.y + 15));
    }
  }

  // FIXED: Draw Transponders
  void _drawTransponders(Canvas canvas) {
    if (!controller.cbtcDevicesEnabled) return;

    for (var transponder in controller.transponders.values) {
      // Color based on type
      Color color;
      switch (transponder.type) {
        case TransponderType.t1:
          color = Colors.yellow[700]!;
          break;
        case TransponderType.t2:
          color = Colors.orange[700]!;
          break;
        case TransponderType.t3:
          color = Colors.amber[700]!;
          break;
        case TransponderType.t6:
          color = Colors.lime[700]!;
          break;
      }

      final transponderPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      // Draw as diamond shape
      final path = Path();
      path.moveTo(transponder.x, transponder.y - 6);
      path.lineTo(transponder.x + 6, transponder.y);
      path.lineTo(transponder.x, transponder.y + 6);
      path.lineTo(transponder.x - 6, transponder.y);
      path.close();

      canvas.drawPath(path, transponderPaint);

      // Outline
      final outlinePaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawPath(path, outlinePaint);

      // Label
      final textPainter = TextPainter(
        text: TextSpan(
          text: transponder.id,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas,
          Offset(transponder.x - textPainter.width / 2, transponder.y + 10));
    }
  }

  void _drawAxleCounters(Canvas canvas) {
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

  void _drawABOccupations(Canvas canvas) {
    if (!controller.axleCountersVisible) return;

    final Map<String, Offset> abPositions = {
      'AB105': const Offset(500, 315),
      //'AB109': const Offset(800, 315),
      'AB100': const Offset(300, 115),
      //'AB104': const Offset(600, 115),
      'AB108': const Offset(900, 115),
      'AB106': const Offset(675, 200), // New AB106 position on crossover
      'AB111': const Offset(1000, 315), // NEW: AB111 position
    };

    for (var abId in abPositions.keys) {
      final position = abPositions[abId]!;
      final isOccupied = controller.ace.isABOccupied(abId);
      final wheelCount = controller.ace.getABWheelCount(abId);

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

      // Draw wheel count indicator when occupied
      if (isOccupied && wheelCount > 0) {
        final wheelTextPainter = TextPainter(
          text: TextSpan(
            text: '🛞 $wheelCount',
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        wheelTextPainter.layout();
        wheelTextPainter.paint(
            canvas,
            Offset(position.dx - wheelTextPainter.width / 2,
                position.dy + 12)); // Below AB label
      }

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
          case 'AB111': // NEW: Draw AB111 occupation line
            canvas.drawLine(
                const Offset(850, 315), const Offset(1150, 315), linePaint);
            break;
        }
      }
    }
  }

  void _drawRouteReservations(Canvas canvas) {
    for (var reservation in controller.routeReservations.values) {
      final signal = controller.signals[reservation.signalId];
      if (signal == null) continue;

      bool shouldShowReservation = signal.routeState == RouteState.set ||
          controller.isRoutePendingCancellation(signal.id);

      if ((signal.id == 'C28' || signal.id == 'C30' || signal.id == 'C33') &&
          signal.aspect != SignalAspect.green &&
          !controller.isRoutePendingCancellation(signal.id)) {
        shouldShowReservation = false;
      }

      if (shouldShowReservation) {
        final isPendingCancellation =
            controller.isRoutePendingCancellation(signal.id);
        final reservationColor =
            isPendingCancellation ? Colors.orange : Colors.yellow;

        for (var blockId in reservation.reservedBlocks) {
          final block = controller.blocks[blockId];
          if (block == null) continue;

          if (reservation.signalId == 'C31' &&
              reservation.trainId.contains('C31_R1')) {
            if (blockId == '112') continue;
            if (blockId == '104' ||
                blockId == '106' ||
                blockId == '108' ||
                blockId == '110') {
              _drawBlockReservation(canvas, block, reservationColor);
            }
            continue;
          }

          if (reservation.signalId == 'C31' &&
              reservation.trainId.contains('C31_R2')) {
            if (blockId == '112') continue;
            if (blockId == '106') continue;
            if (blockId == '104' || blockId == '109' || blockId == '111') {
              _drawBlockReservation(canvas, block, reservationColor);
            }
            if (blockId == 'crossover106' || blockId == 'crossover109') {
              _drawCrossoverReservation(canvas, block, reservationColor);
            }
            continue;
          }

          if (reservation.signalId == 'C30' &&
              reservation.trainId.contains('C30_R1')) {
            if (blockId == '103' || blockId == '101') continue;
            if (blockId == 'crossover106' ||
                blockId == 'crossover109' ||
                blockId == '106' ||
                blockId == '108' ||
                blockId == '110') {
              continue;
            }
            if (blockId == '105' || blockId == '107' || blockId == '109') {
              _drawBlockReservation(canvas, block, reservationColor);
            }
            continue;
          }

          if (reservation.signalId == 'C30' &&
              reservation.trainId.contains('C30_R2')) {
            if (blockId == '106' || blockId == '108' || blockId == '110')
              continue;
            if (blockId == '107' ||
                blockId == '105' ||
                blockId == '103' ||
                blockId == '101') {
              continue;
            }
            if (blockId == '104' || blockId == '109') {
              _drawBlockReservation(canvas, block, reservationColor);
            }
            if (blockId == 'crossover106' || blockId == 'crossover109') {
              _drawCrossoverReservation(canvas, block, reservationColor);
            }
            continue;
          }

          if (blockId.startsWith('crossover')) {
            _drawCrossoverReservation(canvas, block, reservationColor);
          } else {
            _drawBlockReservation(canvas, block, reservationColor);
          }
        }

        final statusText = isPendingCancellation ? ' (Releasing...)' : '';
        final textPainter = TextPainter(
          text: TextSpan(
            text:
                '${reservation.signalId} → ${reservation.trainId.replaceAll('T', '').replaceAll('route_active', 'Active')}$statusText',
            style: TextStyle(
              color: reservationColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        final firstBlock = controller.blocks[reservation.reservedBlocks.first];
        if (firstBlock != null) {
          textPainter.paint(
              canvas, Offset(firstBlock.startX + 5, firstBlock.y - 20));
        }
      }
    }
  }

  void _drawCrossoverReservation(
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

  void _drawBlockReservation(Canvas canvas, BlockSection block, Color color) {
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

  void _drawTracks(Canvas canvas) {
    // FIXED: Dynamically draw ALL blocks in the expanded 7000×1200 network
    for (var block in controller.blocks.values) {
      if (block.id.startsWith('crossover')) {
        continue; // Skip crossovers, draw them separately
      }
      _drawBlock(canvas, block);
    }
    _drawCrossoverTrack(canvas);
  }

  void _drawBlock(Canvas canvas, BlockSection block) {
    final blockPaint = Paint()
      ..color = block.occupied
          ? themeData.trackOccupiedColor.withOpacity(0.3)
          : themeData.trackColor
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
      ..color = themeData.railColor
      ..strokeWidth = 3 * themeData.strokeWidthMultiplier;

    final innerRailPaint = Paint()
      ..color = themeData.railColor
      ..strokeWidth = 2 * themeData.strokeWidthMultiplier;

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
      ..color = themeData.sleeperColor
      ..strokeWidth = 6 * themeData.strokeWidthMultiplier;

    for (double x = block.startX; x < block.endX; x += 15) {
      canvas.drawLine(
          Offset(x, block.y - 12), Offset(x, block.y + 12), sleeperPaint);
    }
  }

  void _drawCrossoverTrack(Canvas canvas) {
    // Draw ALL 5 crossovers in the expanded network
    final outerRailPaint = Paint()
      ..color = themeData.railColor
      ..strokeWidth = 3 * themeData.strokeWidthMultiplier;

    final innerRailPaint = Paint()
      ..color = themeData.railColor
      ..strokeWidth = 2 * themeData.strokeWidthMultiplier;

    final sleeperPaint = Paint()
      ..color = themeData.sleeperColor
      ..strokeWidth = 4 * themeData.strokeWidthMultiplier;

    const railSpacing = 12.0;

    

    // ═══════════════════════════════════════════════════════════════
    // 2. LEFT SECTION CROSSOVER (x=-450, connects blocks 211↔212)
    // ═══════════════════════════════════════════════════════════════
    _drawSingleCrossover(canvas, -450, 100, -350, 200, outerRailPaint,
        innerRailPaint, sleeperPaint, railSpacing);
    _drawSingleCrossover(canvas, -350, 200, -250, 300, outerRailPaint,
        innerRailPaint, sleeperPaint, railSpacing);
    _highlightCrossover(canvas, 'crossover_211_212', -350, 200);

    // ═══════════════════════════════════════════════════════════════
    // 3. MIDDLE CROSSOVER (original 78A/78B at x=600-800)
    // ═══════════════════════════════════════════════════════════════
    _drawSingleCrossover(canvas, 600, 100, 700, 200, outerRailPaint,
        innerRailPaint, sleeperPaint, railSpacing);
    _drawSingleCrossover(canvas, 700, 200, 800, 300, outerRailPaint,
        innerRailPaint, sleeperPaint, railSpacing);
    _highlightCrossover(canvas, 'crossover106', 650, 150);
    _highlightCrossover(canvas, 'crossover109', 750, 250);

    // ═══════════════════════════════════════════════════════════════
    // 4. RIGHT SECTION CROSSOVER (x=1950, connects blocks 302↔305)
    // ═══════════════════════════════════════════════════════════════
    _drawSingleCrossover(canvas, 1950, 100, 2050, 200, outerRailPaint,
        innerRailPaint, sleeperPaint, railSpacing);
    _drawSingleCrossover(canvas, 2050, 200, 2150, 300, outerRailPaint,
        innerRailPaint, sleeperPaint, railSpacing);
    _highlightCrossover(canvas, 'crossover_302_305', 2050, 200);

    
  }

  // Helper method to draw a single crossover segment with 45° angle
  void _drawSingleCrossover(Canvas canvas, double startX, double startY,
      double endX, double endY, Paint outerPaint, Paint innerPaint,
      Paint sleeperPaint, double railSpacing) {

    // Calculate perpendicular offset for rail spacing at 45° angle
    final offset = railSpacing / math.sqrt(2);

    // Outer rail (offset perpendicular to diagonal)
    final path1 = Path()
      ..moveTo(startX - offset, startY + offset)
      ..lineTo(endX - offset, endY + offset);
    canvas.drawPath(path1, outerPaint);

    // Inner rail (offset perpendicular to diagonal)
    final path2 = Path()
      ..moveTo(startX + offset, startY - offset)
      ..lineTo(endX + offset, endY - offset);
    canvas.drawPath(path2, innerPaint);

    // Draw sleepers perpendicular to track direction (135° angle)
    for (double t = 0; t <= 1.0; t += 0.1) {
      final x = startX + ((endX - startX) * t);
      final y = startY + ((endY - startY) * t);
      canvas.drawLine(
          Offset(x - 10, y + 10), Offset(x + 10, y - 10), sleeperPaint);
    }
  }

  // Helper method to highlight occupied crossover blocks
  void _highlightCrossover(Canvas canvas, String blockId, double centerX, double centerY) {
    final block = controller.blocks[blockId];
    if (block != null && block.occupied) {
      final highlightPaint = Paint()
        ..color = themeData.trackOccupiedColor.withOpacity(0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(centerX, centerY), 40, highlightPaint);
    }
  }

  void _drawPlatforms(Canvas canvas) {
    for (var platform in controller.platforms) {
      final platformPaint = Paint()
        ..color = themeData.platformColor
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
        ..color = themeData.platformEdgeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * themeData.strokeWidthMultiplier;

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

  void _drawBufferStop(Canvas canvas) {
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

  void _drawPoints(Canvas canvas) {
    for (var point in controller.points.values) {
      Color pointColor;

      // Determine point color based on state
      final ab106Occupied = controller.ace.isABOccupied('AB106');
      final isABDeadlocked =
          (point.id == '78A' || point.id == '78B') && ab106Occupied;

      if (isABDeadlocked) {
        pointColor = themeData.pointDeadlockColor; // Deadlock color
      } else if (point.lockedByAB) {
        pointColor = themeData.pointDeadlockColor; // AB deadlock
      } else if (point.locked) {
        pointColor = themeData.pointLockedColor; // Manual lock
      } else if (point.position == PointPosition.normal) {
        pointColor = themeData.pointNormalColor; // Normal position
      } else {
        pointColor = themeData.pointReverseColor; // Reverse position
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

      _drawPointGaps(canvas, point);
    }
  }

  void _drawPointGaps(Canvas canvas, Point point) {
    final gapPaint = Paint()
      ..color = themeData.pointGapColor
      ..style = PaintingStyle.fill;

    // Helper function to draw point gap based on position
    void drawGap(double x, double y, bool isUpper, bool isNormal) {
      if (isUpper) {
        // Upper track point (y=100)
        if (isNormal) {
          canvas.drawRect(Rect.fromLTWH(x - 7.5, y + 17, 50, 12), gapPaint);
        } else {
          final path = Path()
            ..moveTo(x + 5, y - 22.5)
            ..lineTo(x + 50, y - 22.5)
            ..lineTo(x + 50, y + 23)
            ..close();
          canvas.drawPath(path, gapPaint);
        }
      } else {
        // Lower track point (y=300)
        if (isNormal) {
          canvas.drawRect(Rect.fromLTWH(x - 62.5, y - 19, 50, 12), gapPaint);
        } else {
          final path = Path()
            ..moveTo(x, y - 21)
            ..lineTo(x + 37, y + 17.5)
            ..lineTo(x, y + 17.5)
            ..close();
          canvas.drawPath(path, gapPaint);
        }
      }
    }

    // ═══════════════════════════════════════════════════════════════
    // LEFT END CROSSOVER POINTS (76A, 76B)
    // ═══════════════════════════════════════════════════════════════
    if (point.id == '76A') {
      drawGap(-1000, 100, true, point.position == PointPosition.normal);
    } else if (point.id == '76B') {
      drawGap(-900, 300, false, point.position == PointPosition.normal);
    }
    // ═══════════════════════════════════════════════════════════════
    // LEFT SECTION CROSSOVER POINTS (77A, 77B)
    // ═══════════════════════════════════════════════════════════════
    else if (point.id == '77A') {
      drawGap(-450, 100, true, point.position == PointPosition.normal);
    } else if (point.id == '77B') {
      drawGap(-150, 300, false, point.position == PointPosition.normal);
    }
    // ═══════════════════════════════════════════════════════════════
    // MIDDLE CROSSOVER POINTS (78A, 78B) - Original
    // ═══════════════════════════════════════════════════════════════
    else if (point.id == '78A') {
      if (point.position == PointPosition.normal) {
        canvas.drawRect(Rect.fromLTWH(592.5, 114, 50, 12), gapPaint);
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
        canvas.drawRect(Rect.fromLTWH(757.5, 274, 50, 12), gapPaint);
      } else {
        final path = Path()
          ..moveTo(760, 279)
          ..lineTo(797, 317.5)
          ..lineTo(760, 317.5)
          ..close();
        canvas.drawPath(path, gapPaint);
      }
    }
    // ═══════════════════════════════════════════════════════════════
    // RIGHT SECTION CROSSOVER POINTS (79A, 79B)
    // ═══════════════════════════════════════════════════════════════
    else if (point.id == '79A') {
      drawGap(1950, 100, true, point.position == PointPosition.normal);
    } else if (point.id == '79B') {
      drawGap(2250, 300, false, point.position == PointPosition.normal);
    }
    // ═══════════════════════════════════════════════════════════════
    // RIGHT END CROSSOVER POINTS (80A, 80B)
    // ═══════════════════════════════════════════════════════════════
    else if (point.id == '80A') {
      drawGap(3100, 100, true, point.position == PointPosition.normal);
    } else if (point.id == '80B') {
      drawGap(3200, 300, false, point.position == PointPosition.normal);
    }
  }

  void _drawSignals(Canvas canvas) {
    if (!controller.signalsVisible) return;

    for (var signal in controller.signals.values) {
      final polePaint = Paint()
        ..color = themeData.signalPoleColor
        ..strokeWidth = 5 * themeData.strokeWidthMultiplier;

      canvas.drawLine(Offset(signal.x, signal.y),
          Offset(signal.x, signal.y - 40), polePaint);

      _drawSignalHead(canvas, signal);
    }
  }

  void _drawSignalHead(Canvas canvas, Signal signal) {
    final headPaint = Paint()
      ..color = themeData.signalPoleColor
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

    final lightColor = signal.aspect == SignalAspect.green
        ? themeData.signalGreenColor
        : themeData.signalRedColor;
    final lightPaint = Paint()
      ..color = lightColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(signal.x, signal.y - 42.5), 6, lightPaint);

    if (themeData.showGlow && signal.aspect == SignalAspect.green) {
      final glowPaint = Paint()
        ..color = themeData.signalGreenColor.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawCircle(Offset(signal.x, signal.y - 42.5), 12, glowPaint);
    }
  }

  void _drawTrainStops(Canvas canvas) {
    if (!controller.trainStopsEnabled) return;

    for (var trainStop in controller.trainStops.values) {
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

  // FIXED: Draw bellows (flexible connectors) between adjacent trains
  void _drawTrainBellows(Canvas canvas) {
    final trains = controller.trains;
    if (trains.length < 2) return;

    for (int i = 0; i < trains.length - 1; i++) {
      final train1 = trains[i];
      final train2 = trains[i + 1];

      // Only draw bellow if trains are close enough (within 80 units)
      final distance = (train1.x - train2.x).abs();
      if (distance > 80) continue;

      // Check if trains are on the same track (similar Y positions)
      if ((train1.y - train2.y).abs() > 20) continue;

      // Determine the bellow connection points
      final train1EndX = train1.direction > 0 ? train1.x + 30 : train1.x - 30;
      final train2EndX = train2.direction > 0 ? train2.x - 30 : train2.x + 30;

      // Draw bellow as a flexible connector
      final bellowPaint = Paint()
        ..color = Colors.grey[800]!
        ..style = PaintingStyle.fill;

      // Draw accordion-style bellow
      final path = Path();
      final segments = 4;
      final segmentWidth = (train2EndX - train1EndX) / segments;

      for (int j = 0; j < segments; j++) {
        final x1 = train1EndX + (j * segmentWidth);
        final x2 = train1EndX + ((j + 1) * segmentWidth);
        final amplitude = j % 2 == 0 ? 3.0 : -3.0;

        if (j == 0) {
          path.moveTo(x1, train1.y - 8);
        }

        path.lineTo(x1, train1.y - 8 + amplitude);
        path.lineTo(x2, train1.y - 8 - amplitude);
      }

      path.lineTo(train2EndX, train2.y - 8);
      path.lineTo(train2EndX, train2.y + 8);

      for (int j = segments - 1; j >= 0; j--) {
        final x1 = train1EndX + (j * segmentWidth);
        final x2 = train1EndX + ((j + 1) * segmentWidth);
        final amplitude = j % 2 == 0 ? 3.0 : -3.0;

        path.lineTo(x2, train2.y + 8 - amplitude);
        path.lineTo(x1, train2.y + 8 + amplitude);
      }

      path.lineTo(train1EndX, train1.y + 8);
      path.close();

      canvas.drawPath(path, bellowPaint);

      // Draw bellow outline
      final outlinePaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawPath(path, outlinePaint);
    }
  }

  void _drawMovementAuthorities(Canvas canvas) {
    // Get current time for animation
    final animationOffset = (DateTime.now().millisecondsSinceEpoch % 2000) / 2000.0;

    for (var train in controller.trains) {
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
      final startX = isEastbound ? trainX + 35 : trainX - 35; // Start just ahead of train
      final endX = isEastbound
          ? trainX + ma.maxDistance
          : trainX - ma.maxDistance;

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

  void _drawTrains(Canvas canvas) {
    // FIXED: Draw bellows between adjacent trains first
    _drawTrainBellows(canvas);

    for (var train in controller.trains) {
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
          ..color = themeData.trainDoorColor
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
          ..color = themeData.trainWindowColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 * themeData.strokeWidthMultiplier;

        canvas.drawRect(leftDoorRect, doorOutlinePaint);
        canvas.drawRect(rightDoorRect, doorOutlinePaint);
      } else {
        final windowPaint = Paint()..color = themeData.trainWindowColor;
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

  void _drawDirectionLabels(Canvas canvas) {
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

  void _drawLabels(Canvas canvas) {
    for (var block in controller.blocks.values) {
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

    if (controller.signalsVisible) {
      for (var signal in controller.signals.values) {
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

    for (var platform in controller.platforms) {
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

    for (var train in controller.trains) {
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

  @override
  bool shouldRepaint(TerminalStationPainter oldDelegate) {
    return oldDelegate.controller != controller ||
        oldDelegate.cameraOffsetX != cameraOffsetX ||
        oldDelegate.cameraOffsetY != cameraOffsetY ||  // FIXED: Check Y offset for repaint
        oldDelegate.zoom != zoom ||
        oldDelegate.animationTick != animationTick ||
        oldDelegate.canvasWidth != canvasWidth ||
        oldDelegate.canvasHeight != canvasHeight;
  }
}
