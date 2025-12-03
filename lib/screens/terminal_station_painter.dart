import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'terminal_station_models.dart';
import '../controllers/terminal_station_controller.dart';
import '../controllers/canvas_theme_controller.dart';
import 'package:rail_champ/models/railway_model.dart'
    show WifiAntenna, Transponder, TransponderType;

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
  final double cameraOffsetY; // FIXED: Add Y offset parameter
  final double zoom;
  final int animationTick;
  final double canvasWidth;
  final double canvasHeight;
  final CanvasThemeData themeData; // NEW: Canvas theme support

  TerminalStationPainter({
    required this.controller,
    required this.cameraOffsetX,
    required this.cameraOffsetY, // FIXED: Add Y offset parameter
    required this.zoom,
    required this.animationTick,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.themeData, // NEW: Canvas theme support
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw themed background
    final backgroundPaint = Paint()
      ..color = themeData.canvasBackgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(zoom);
    canvas.translate(
        cameraOffsetX, cameraOffsetY); // FIXED: Use Y offset for panning

    // Draw grid first (if enabled)
    if (controller.gridVisible) {
      _drawGrid(canvas, size);
    }

    // Always use legacy rendering to ensure railway components always display
    // Layer system is disabled to prevent component visibility issues
    _paintLegacy(canvas, size);

    // Draw selection highlight (edit mode)
    if (controller.editModeEnabled) {
      _drawSelectionHighlight(canvas);
    }

    drawCollisionEffects(canvas, controller, animationTick);

    // Draw tooltip last (if hovered object exists)
    if (controller.tooltipsEnabled && controller.hoveredObject != null) {
      _drawTooltip(canvas);
    }

    canvas.restore();
  }

  /// Layer-aware rendering: Paint components organized by layers (bottom to top)
  void _paintWithLayers(Canvas canvas, Size size) {
    // Render layers from bottom to top (respecting z-order)
    for (final layer in controller.layers) {
      // Skip invisible layers
      if (!layer.isVisible) continue;

      // Apply layer opacity using saveLayer
      if (layer.opacity < 1.0) {
        canvas.saveLayer(
          null,
          Paint()..color = Color.fromRGBO(255, 255, 255, layer.opacity),
        );
      }

      // Draw components that belong to this layer
      _paintLayerComponents(canvas, layer);

      // Restore canvas if we applied opacity
      if (layer.opacity < 1.0) {
        canvas.restore();
      }
    }

    // Draw trains (always on top, not layer-specific)
    _drawTrains(canvas);
    _drawGhostTrains(canvas);
    _drawDirectionLabels(canvas);
    _drawLabels(canvas);
  }

  /// Paint all components belonging to a specific layer
  void _paintLayerComponents(Canvas canvas, layer) {
    final componentIds = layer.componentIds;
    if (componentIds.isEmpty) return;

    // Categorize components by type for efficient rendering
    final layerBlocks = <String>[];
    final layerSignals = <String>[];
    final layerPoints = <String>[];
    final layerPlatforms = <String>[];
    final layerStops = <String>[];
    final layerBufferStops = <String>[];
    final layerCrossovers = <String>[];
    final layerAxleCounters = <String>[];
    final layerTransponders = <String>[];
    final layerWifiAntennas = <String>[];

    for (final componentId in componentIds) {
      if (controller.blocks.containsKey(componentId)) {
        layerBlocks.add(componentId);
      } else if (controller.signals.containsKey(componentId)) {
        layerSignals.add(componentId);
      } else if (controller.points.containsKey(componentId)) {
        layerPoints.add(componentId);
      } else if (controller.crossovers.containsKey(componentId)) {
        layerCrossovers.add(componentId);
      } else if (controller.platforms.any((p) => p.id == componentId)) {
        layerPlatforms.add(componentId);
      } else if (controller.trainStops.values.any((s) => s.id == componentId)) {
        layerStops.add(componentId);
      } else if (controller.bufferStops.containsKey(componentId)) {
        layerBufferStops.add(componentId);
      } else if (controller.axleCounters.containsKey(componentId)) {
        layerAxleCounters.add(componentId);
      } else if (controller.transponders.containsKey(componentId)) {
        layerTransponders.add(componentId);
      } else if (controller.wifiAntennas.containsKey(componentId)) {
        layerWifiAntennas.add(componentId);
      }
    }

    // Draw components in proper rendering order
    _drawTracksFiltered(canvas, layerBlocks);
    _drawCrossoverTrackFiltered(canvas, layerCrossovers); // Draw crossovers
    _drawRouteReservations(canvas);
    _drawPlatformsFiltered(canvas, layerPlatforms);
    _drawBufferStopFiltered(canvas, layerBufferStops); // Fixed: use layerBufferStops
    _drawPointsFiltered(canvas, layerPoints);
    _drawSignalsFiltered(canvas, layerSignals);
    _drawTrainStopsFiltered(canvas, layerStops);
    _drawAxleCountersFiltered(canvas, layerAxleCounters);
    _drawABOccupations(canvas);
    _drawWiFiAntennasFiltered(canvas, layerWifiAntennas);
    _drawTranspondersFiltered(canvas, layerTransponders);
    _drawMovementAuthorities(canvas);
  }

  /// Legacy rendering: Draw all components in default order (no layers)
  void _paintLegacy(Canvas canvas, Size size) {
    _drawTracks(canvas);
    _drawRouteReservations(canvas);
    _drawPlatforms(canvas);
    _drawBufferStop(canvas);
    _drawPoints(canvas);
    _drawSignals(canvas);
    _drawTrainStops(canvas);
    _drawAxleCounters(canvas);
    _drawABOccupations(canvas);
    _drawWiFiAntennas(canvas);
    _drawTransponders(canvas);
    _drawMovementAuthorities(canvas);
    _drawTrains(canvas);
    _drawGhostTrains(canvas);
    _drawDirectionLabels(canvas);
    _drawLabels(canvas);
  }

  // ============================================================================
  // FILTERED DRAWING METHODS (Layer-aware rendering)
  // ============================================================================

  /// Draw only tracks (blocks) with IDs in the provided list
  void _drawTracksFiltered(Canvas canvas, List<String> blockIds) {
    for (final blockId in blockIds) {
      final block = controller.blocks[blockId];
      if (block != null && !block.id.startsWith('crossover')) {
        _drawBlock(canvas, block);
      }
    }
    // Note: Crossovers are drawn separately via _drawCrossoverTrackFiltered
  }

  /// Draw only signals with IDs in the provided list
  void _drawSignalsFiltered(Canvas canvas, List<String> signalIds) {
    for (final signalId in signalIds) {
      final signal = controller.signals[signalId];
      if (signal != null) {
        _drawSignal(canvas, signal);
      }
    }
  }

  /// Draw only points with IDs in the provided list
  void _drawPointsFiltered(Canvas canvas, List<String> pointIds) {
    for (final pointId in pointIds) {
      final point = controller.points[pointId];
      if (point != null) {
        _drawPoint(canvas, point);
      }
    }
  }

  /// Draw only platforms with IDs in the provided list
  void _drawPlatformsFiltered(Canvas canvas, List<String> platformIds) {
    for (final platformId in platformIds) {
      final platform = controller.platforms.where((p) => p.id == platformId).firstOrNull;
      if (platform != null) {
        _drawPlatform(canvas, platform);
      }
    }
  }

  /// Draw only buffer stops with IDs in the provided list
  void _drawBufferStopFiltered(Canvas canvas, List<String> bufferStopIds) {
    for (final stopId in bufferStopIds) {
      final bufferStop = controller.bufferStops[stopId];
      if (bufferStop != null) {
        // Draw individual buffer stop
        final bufferPaint = Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill;

        canvas.drawRect(
          Rect.fromLTWH(
            bufferStop.x - bufferStop.width / 2,
            bufferStop.y - bufferStop.height / 2,
            bufferStop.width,
            bufferStop.height,
          ),
          bufferPaint,
        );

        // Draw yellow diagonal stripes
        final stripePaint = Paint()
          ..color = Colors.yellow
          ..strokeWidth = 2;

        final stripeCount = (bufferStop.width / 5).floor();
        for (int i = 0; i < stripeCount; i++) {
          canvas.drawLine(
            Offset(
              bufferStop.x - bufferStop.width / 2 + (i * 5),
              bufferStop.y - bufferStop.height / 2,
            ),
            Offset(
              bufferStop.x - bufferStop.width / 2 + (i * 5),
              bufferStop.y + bufferStop.height / 2,
            ),
            stripePaint,
          );
        }
      }
    }
  }

  /// Draw only crossovers with IDs in the provided list
  /// For now, if any crossover should be shown, we draw all crossovers
  /// TODO: Refactor _drawCrossoverTrack to support filtered rendering
  void _drawCrossoverTrackFiltered(Canvas canvas, List<String> crossoverIds) {
    if (crossoverIds.isNotEmpty) {
      // Draw all crossovers if any should be shown
      // This is a temporary solution until crossover rendering is refactored
      _drawCrossoverTrack(canvas);
    }
  }

  /// Draw only train stops with IDs in the provided list
  void _drawTrainStopsFiltered(Canvas canvas, List<String> stopIds) {
    for (final stopId in stopIds) {
      final stop = controller.trainStops.values.where((s) => s.id == stopId).firstOrNull;
      if (stop != null) {
        _drawStopMarker(canvas, stop);
      }
    }
  }

  /// Draw only axle counters with IDs in the provided list
  void _drawAxleCountersFiltered(Canvas canvas, List<String> counterIds) {
    for (final counterId in counterIds) {
      final counter = controller.axleCounters[counterId];
      if (counter != null) {
        _drawAxleCounter(canvas, counter);
      }
    }
  }

  /// Draw only transponders with IDs in the provided list
  void _drawTranspondersFiltered(Canvas canvas, List<String> transponderIds) {
    for (final transponderId in transponderIds) {
      final transponder = controller.transponders[transponderId];
      if (transponder != null) {
        _drawSingleTransponder(canvas, transponder);
      }
    }
  }

  /// Draw only WiFi antennas with IDs in the provided list
  void _drawWiFiAntennasFiltered(Canvas canvas, List<String> antennaIds) {
    for (final antennaId in antennaIds) {
      final antenna = controller.wifiAntennas[antennaId];
      if (antenna != null) {
        _drawSingleWiFiAntenna(canvas, antenna);
      }
    }
  }

  // ============================================================================
  // SINGLE COMPONENT DRAWING HELPERS
  // ============================================================================

  /// Draw a single signal
  void _drawSignal(Canvas canvas, Signal signal) {
    if (!controller.signalsVisible) return;

    final polePaint = Paint()
      ..color = themeData.signalPoleColor
      ..strokeWidth = 5 * themeData.strokeWidthMultiplier;

    canvas.drawLine(Offset(signal.x, signal.y),
        Offset(signal.x, signal.y - 40), polePaint);

    _drawSignalHead(canvas, signal);
  }

  /// Draw a single point
  void _drawPoint(Canvas canvas, Point point) {
    // Extract point drawing logic from _drawPoints method
    // This will reuse the existing point rendering code
    final pointPaint = Paint()
      ..color = point.position == PointPosition.normal ? Colors.green : Colors.red
      ..strokeWidth = 4 * themeData.strokeWidthMultiplier;

    // Draw point representation (simplified - actual implementation may vary)
    canvas.drawCircle(Offset(point.x, point.y), 8, pointPaint);
  }

  /// Draw a single platform
  void _drawPlatform(Canvas canvas, Platform platform) {
    final platformPaint = Paint()
      ..color = themeData.platformColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(platform.startX, platform.y - 25,
                      platform.endX - platform.startX, 50),
        const Radius.circular(4),
      ),
      platformPaint,
    );
  }

  /// Draw a single stop marker (train stop / buffer stop)
  void _drawStopMarker(Canvas canvas, dynamic stop) {
    final stopPaint = Paint()
      ..color = stop.isBufferStop ? Colors.red : Colors.orange
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(stop.x, stop.y), 6, stopPaint);
  }

  /// Draw a single axle counter
  void _drawAxleCounter(Canvas canvas, AxleCounter counter) {
    final counterPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(counter.x, counter.y),
        width: 12,
        height: 12,
      ),
      counterPaint,
    );
  }

  /// Draw a single transponder
  void _drawSingleTransponder(Canvas canvas, Transponder transponder) {
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

    final path = Path();
    path.moveTo(transponder.x, transponder.y - 6);
    path.lineTo(transponder.x + 6, transponder.y);
    path.lineTo(transponder.x, transponder.y + 6);
    path.lineTo(transponder.x - 6, transponder.y);
    path.close();

    canvas.drawPath(path, transponderPaint);
  }

  /// Draw a single WiFi antenna
  void _drawSingleWiFiAntenna(Canvas canvas, WifiAntenna antenna) {
    if (!controller.cbtcDevicesEnabled) return;

    final rangePaint = Paint()
      ..color = antenna.isActive
          ? Colors.blue.withOpacity(0.08)
          : Colors.grey.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(antenna.x, antenna.y), 350.0, rangePaint);

    final antennaPaint = Paint()
      ..color = antenna.isActive ? Colors.blue : Colors.grey
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(antenna.x, antenna.y),
        width: 8,
        height: 20,
      ),
      antennaPaint,
    );
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

      canvas.drawCircle(
          Offset(antenna.x, antenna.y), 350.0, rangePaint); // 350 unit range

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

      // Respect flipped property - swap D1/D2 visual positions when flipped
      final d1X = counter.flipped ? counter.x + 5 : counter.x - 5;
      final d2X = counter.flipped ? counter.x - 5 : counter.x + 5;
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

    // COMPREHENSIVE AB POSITIONS - Updated with new axle counter positions
    final Map<String, Offset> abPositions = {
      'AB100': const Offset(140, 120), // ac100(380,120) ↔ ac214(-100,120)
      'AB101': const Offset(225, 320), // ac215(-100,320) ↔ ac101(550,320)
      'AB105': const Offset(502, 210), // ac106(420,140) ↔ ac105(585,280)
      'AB108': const Offset(625, 120), // ac104(550,120) ↔ ac108(700,120)
      'AB109': const Offset(740, 320), // ac107(630,320) ↔ ac109(850,320)
      'AB111': const Offset(1000, 320), // ac109(850,320) ↔ ac111(1150,320)
      'AB112': const Offset(1000, 120), // ac108(700,120) ↔ ac112(1300,120)
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

      // Draw PURPLE visualization lines when AB is OCCUPIED
      if (isOccupied) {
        final linePaint = Paint()
          ..color = Colors.purple
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;

        switch (abId) {
          case 'AB100': // ac100(380,120) ↔ ac214(-100,120)
            canvas.drawLine(
                const Offset(380, 120), const Offset(-100, 120), linePaint);
            break;
          case 'AB101': // ac215(-100,320) ↔ ac101(550,320)
            canvas.drawLine(
                const Offset(-100, 320), const Offset(550, 320), linePaint);
            break;
          case 'AB105': // ac106(420,140) ↔ ac105(585,280)
            canvas.drawLine(
                const Offset(420, 140), const Offset(585, 280), linePaint);
            break;
          case 'AB108': // ac104(550,120) ↔ ac108(700,120)
            canvas.drawLine(
                const Offset(550, 120), const Offset(700, 120), linePaint);
            break;
          case 'AB109': // ac107(630,320) ↔ ac109(850,320)
            canvas.drawLine(
                const Offset(630, 320), const Offset(850, 320), linePaint);
            break;
          case 'AB111': // ac109(850,320) ↔ ac111(1150,320)
            canvas.drawLine(
                const Offset(850, 320), const Offset(1150, 320), linePaint);
            break;
          case 'AB112': // ac108(700,120) ↔ ac112(1300,120)
            canvas.drawLine(
                const Offset(700, 120), const Offset(1300, 120), linePaint);
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
            if (blockId == '102' || blockId == '107' || blockId == '109' || blockId == '111') {
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
    // Main reservation line with enhanced width
    final reservationPaint = Paint()
      ..color = reservationColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    // Glow effect for dramatic visualization
    final glowPaint = Paint()
      ..color = reservationColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Animated pulse effect
    final pulseOpacity =
        (0.3 + (math.sin(animationTick * 0.1) * 0.2)).clamp(0.0, 1.0);
    final pulsePaint = Paint()
      ..color = reservationColor.withOpacity(pulseOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    const dashLength = 15.0;
    const gapLength = 5.0;
    const reservationOffset = 3.0; // Offset perpendicular to track direction

    if (block.id == 'crossover_211_212') {
      // LEFT SECTION: Double diamond crossover at 135-degree angle (upper-right to lower-left for westbound)
      // Crossover spans from -600 to -300 (300 units)
      // Diagonal section: -550 to -350 (200 units) at 135 degrees
      double totalDistance = math.sqrt(math.pow(200, 2) + math.pow(200, 2)); // ~283 units
      double currentDistance = 0;
      bool drawDash = true;

      // Calculate perpendicular offset for 135-degree angle (upper-right to lower-left)
      final offsetX = reservationOffset * math.cos(3 * math.pi / 4 + math.pi / 2);
      final offsetY = reservationOffset * math.sin(3 * math.pi / 4 + math.pi / 2);

      while (currentDistance < totalDistance) {
        double t1 = currentDistance / totalDistance;
        double t2 =
            math.min((currentDistance + dashLength) / totalDistance, 1.0);

        if (drawDash) {
          // Draw from upper-right (-300, 100) to lower-left (-500, 300)
          final x1 = -300 - (200 * t1) + offsetX;
          final y1 = 100 + (200 * t1) + offsetY;
          final x2 = -300 - (200 * t2) + offsetX;
          final y2 = 100 + (200 * t2) + offsetY;

          // Draw glow, main line, and pulse
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), glowPaint);
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), reservationPaint);
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), pulsePaint);
        }

        currentDistance += dashLength + gapLength;
        drawDash = !drawDash;
      }
    } else if (block.id == 'crossover106') {
      // 45-degree crossover from upper-left to lower-right
      double totalDistance = math.sqrt(math.pow(100, 2) + math.pow(100, 2));
      double currentDistance = 0;
      bool drawDash = true;

      // Calculate perpendicular offset for 45-degree angle
      final offsetX = reservationOffset * math.cos(math.pi / 4 + math.pi / 2);
      final offsetY = reservationOffset * math.sin(math.pi / 4 + math.pi / 2);

      while (currentDistance < totalDistance) {
        double t1 = currentDistance / totalDistance;
        double t2 =
            math.min((currentDistance + dashLength) / totalDistance, 1.0);

        if (drawDash) {
          final x1 = 400 + (100 * t1) + offsetX;
          final y1 = 100 + (100 * t1) + offsetY;
          final x2 = 400 + (100 * t2) + offsetX;
          final y2 = 100 + (100 * t2) + offsetY;

          // Draw glow, main line, and pulse
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), glowPaint);
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), reservationPaint);
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), pulsePaint);
        }

        currentDistance += dashLength + gapLength;
        drawDash = !drawDash;
      }
    } else if (block.id == 'crossover109') {
      // 45-degree crossover from upper-left to lower-right (continuation of crossover106)
      double totalDistance = math.sqrt(math.pow(100, 2) + math.pow(100, 2));
      double currentDistance = 0;
      bool drawDash = true;

      // Calculate perpendicular offset for 45-degree angle
      final offsetX = reservationOffset * math.cos(math.pi / 4 + math.pi / 2);
      final offsetY = reservationOffset * math.sin(math.pi / 4 + math.pi / 2);

      while (currentDistance < totalDistance) {
        double t1 = currentDistance / totalDistance;
        double t2 =
            math.min((currentDistance + dashLength) / totalDistance, 1.0);

        if (drawDash) {
          final x1 = 500 + (100 * t1) + offsetX;
          final y1 = 200 + (100 * t1) + offsetY;
          final x2 = 500 + (100 * t2) + offsetX;
          final y2 = 200 + (100 * t2) + offsetY;

          // Draw glow, main line, and pulse
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), glowPaint);
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), reservationPaint);
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), pulsePaint);
        }

        currentDistance += dashLength + gapLength;
        drawDash = !drawDash;
      }
    } else if (block.id == 'crossover_303_304') {
      // RIGHT SECTION: Double diamond crossover at 45-degree angle (upper-left to lower-right for eastbound)
      // Crossover spans from 1800 to 2100 (300 units)
      // Diagonal section: 1850 to 2050 (200 units) at 45 degrees
      double totalDistance = math.sqrt(math.pow(200, 2) + math.pow(200, 2)); // ~283 units
      double currentDistance = 0;
      bool drawDash = true;

      // Calculate perpendicular offset for 45-degree angle (upper-left to lower-right)
      final offsetX = reservationOffset * math.cos(math.pi / 4 + math.pi / 2);
      final offsetY = reservationOffset * math.sin(math.pi / 4 + math.pi / 2);

      while (currentDistance < totalDistance) {
        double t1 = currentDistance / totalDistance;
        double t2 =
            math.min((currentDistance + dashLength) / totalDistance, 1.0);

        if (drawDash) {
          // Draw from upper-left (1850, 100) to lower-right (2050, 300)
          final x1 = 1850 + (200 * t1) + offsetX;
          final y1 = 100 + (200 * t1) + offsetY;
          final x2 = 1850 + (200 * t2) + offsetX;
          final y2 = 100 + (200 * t2) + offsetY;

          // Draw glow, main line, and pulse
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), glowPaint);
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), reservationPaint);
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), pulsePaint);
        }

        currentDistance += dashLength + gapLength;
        drawDash = !drawDash;
      }
    }
  }

  void _drawBlockReservation(Canvas canvas, BlockSection block, Color color) {
    // Draw reservation between the rails (offset from centerline)
    final reservationOffset = 3.0; // Offset from track centerline

    // Main reservation line
    final reservationPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    // Glow effect for dramatic visualization
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final dashPath = Path();
    final glowPath = Path();
    double currentX = block.startX;
    const dashLength = 15.0;
    const gapLength = 5.0;

    // Draw dashed line with glow effect
    while (currentX < block.endX) {
      dashPath.moveTo(currentX, block.y + reservationOffset);
      dashPath.lineTo(math.min(currentX + dashLength, block.endX),
          block.y + reservationOffset);

      glowPath.moveTo(currentX, block.y + reservationOffset);
      glowPath.lineTo(math.min(currentX + dashLength, block.endX),
          block.y + reservationOffset);

      currentX += dashLength + gapLength;
    }

    // Draw glow first, then main line
    canvas.drawPath(glowPath, glowPaint);
    canvas.drawPath(dashPath, reservationPaint);

    // Add animated pulse effect based on animation tick
    final pulseOpacity =
        (0.3 + (math.sin(animationTick * 0.1) * 0.2)).clamp(0.0, 1.0);
    final pulsePaint = Paint()
      ..color = color.withOpacity(pulseOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawPath(dashPath, pulsePaint);
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
    // Use red color if traction current is off, otherwise use normal rail color
    // Check traction status at this block's position
    final railColor = controller
            .isTractionOnAt(block.startX + (block.endX - block.startX) / 2)
        ? themeData.railColor
        : Colors.red;

    final outerRailPaint = Paint()
      ..color = railColor
      ..strokeWidth = 3 * themeData.strokeWidthMultiplier;

    final innerRailPaint = Paint()
      ..color = railColor
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
    // Check traction status for each crossover section independently

    final sleeperPaint = Paint()
      ..color = themeData.sleeperColor
      ..strokeWidth = 4 * themeData.strokeWidthMultiplier;

    const railSpacing = 12.0;

    // ═══════════════════════════════════════════════════════════════
    // 2. LEFT SECTION - DOUBLE DIAMOND CROSSOVER (x=-600 to -300, connects blocks 210/211 to 212/213)
    // Aligned to block starts: Points at -600 and -300 on both tracks
    // Points: 76A (-600,100), 77B (-600,300), 77A (-300,100), 76B (-300,300)
    // ═══════════════════════════════════════════════════════════════
    final leftRailColor =
        controller.isTractionOnAt(-450) ? themeData.railColor : Colors.red;
    final leftOuterPaint = Paint()
      ..color = leftRailColor
      ..strokeWidth = 3 * themeData.strokeWidthMultiplier;
    final leftInnerPaint = Paint()
      ..color = leftRailColor
      ..strokeWidth = 2 * themeData.strokeWidthMultiplier;
    _drawDoubleDiamondCrossover(canvas, -600, -300, leftOuterPaint,
        leftInnerPaint, sleeperPaint, railSpacing);
    _highlightCrossover(canvas, 'crossover_211_212', -450, 200);

    // ═══════════════════════════════════════════════════════════════
    // 3. MIDDLE CROSSOVER (78A at x=400, 78B at x=600, aligned to block boundaries)
    // Points: 78A (400,100), 78B (600,300)
    // Crossover spans 400-600 with angled rendering for visual appeal
    // ═══════════════════════════════════════════════════════════════
    final midRailColor =
        controller.isTractionOnAt(500) ? themeData.railColor : Colors.red;
    final midOuterPaint = Paint()
      ..color = midRailColor
      ..strokeWidth = 3 * themeData.strokeWidthMultiplier;
    final midInnerPaint = Paint()
      ..color = midRailColor
      ..strokeWidth = 2 * themeData.strokeWidthMultiplier;
    // Draw angled crossover from 78A at 400 to 78B at 600
    _drawSingleCrossover(canvas, 400, 100, 500, 200, midOuterPaint,
        midInnerPaint, sleeperPaint, railSpacing);
    _drawSingleCrossover(canvas, 500, 200, 600, 300, midOuterPaint,
        midInnerPaint, sleeperPaint, railSpacing);
    _highlightCrossover(canvas, 'crossover106', 500, 150);
    _highlightCrossover(canvas, 'crossover109', 500, 250);

    // ═══════════════════════════════════════════════════════════════
    // 4. RIGHT SECTION - DOUBLE DIAMOND CROSSOVER (x=1800 to 2100, connects blocks 302/303 to 304/305)
    // Aligned to block starts: Points at 1800 and 2100 on both tracks
    // Points: 79A (1800,100), 80B (1800,300), 80A (2100,100), 79B (2100,300)
    // ═══════════════════════════════════════════════════════════════
    final rightRailColor =
        controller.isTractionOnAt(1950) ? themeData.railColor : Colors.red;
    final rightOuterPaint = Paint()
      ..color = rightRailColor
      ..strokeWidth = 3 * themeData.strokeWidthMultiplier;
    final rightInnerPaint = Paint()
      ..color = rightRailColor
      ..strokeWidth = 2 * themeData.strokeWidthMultiplier;
    _drawDoubleDiamondCrossover(canvas, 1800, 2100, rightOuterPaint,
        rightInnerPaint, sleeperPaint, railSpacing);
    _highlightCrossover(canvas, 'crossover_303_304', 1950, 200);
  }

  // Helper method to draw a single crossover segment with proper geometry
  void _drawSingleCrossover(
      Canvas canvas,
      double startX,
      double startY,
      double endX,
      double endY,
      Paint outerPaint,
      Paint innerPaint,
      Paint sleeperPaint,
      double railSpacing) {
    // Calculate track direction vector
    final dx = endX - startX;
    final dy = endY - startY;
    final length = math.sqrt(dx * dx + dy * dy);

    // Normalize direction vector
    final dirX = dx / length;
    final dirY = dy / length;

    // Calculate perpendicular vector (rotate 90° counterclockwise)
    // For direction (dx, dy), perpendicular is (-dy, dx)
    final perpX = -dirY * railSpacing / 2;
    final perpY = dirX * railSpacing / 2;

    // Outer rail (offset perpendicular to diagonal)
    final path1 = Path()
      ..moveTo(startX - perpX, startY - perpY)
      ..lineTo(endX - perpX, endY - perpY);
    canvas.drawPath(path1, outerPaint);

    // Inner rail (offset perpendicular to diagonal on opposite side)
    final path2 = Path()
      ..moveTo(startX + perpX, startY + perpY)
      ..lineTo(endX + perpX, endY + perpY);
    canvas.drawPath(path2, innerPaint);

    // Draw sleepers perpendicular to track direction
    // Sleeper direction is the perpendicular vector
    for (double t = 0; t <= 1.0; t += 0.1) {
      final x = startX + (dx * t);
      final y = startY + (dy * t);
      // Draw sleeper from one side to the other (perpendicular to track)
      canvas.drawLine(Offset(x - perpX * 1.5, y - perpY * 1.5),
          Offset(x + perpX * 1.5, y + perpY * 1.5), sleeperPaint);
    }
  }

  // Helper method to draw a double diamond crossover with 45° angles
  void _drawDoubleDiamondCrossover(
      Canvas canvas,
      double startX,
      double endX,
      Paint outerPaint,
      Paint innerPaint,
      Paint sleeperPaint,
      double railSpacing) {
    // Calculate positions
    final midX = (startX + endX) / 2;
    final upperY = 100.0;
    final midY = 200.0;
    final lowerY = 300.0;

    // First crossover: upper-left to lower-right (45° - main diagonal)
    _drawSingleCrossover(canvas, startX, upperY, midX, midY, outerPaint,
        innerPaint, sleeperPaint, railSpacing);
    _drawSingleCrossover(canvas, midX, midY, endX, lowerY, outerPaint,
        innerPaint, sleeperPaint, railSpacing);

    // Second crossover: lower-left to upper-right (45° - opposite diagonal)
    _drawSingleCrossover(canvas, startX, lowerY, midX, midY, outerPaint,
        innerPaint, sleeperPaint, railSpacing);
    _drawSingleCrossover(canvas, midX, midY, endX, upperY, outerPaint,
        innerPaint, sleeperPaint, railSpacing);
  }

  // Helper method to highlight occupied crossover blocks
  void _highlightCrossover(
      Canvas canvas, String blockId, double centerX, double centerY) {
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
    // FIXED: Draw all buffer stops from controller instead of hardcoded position
    for (var bufferStop in controller.bufferStops.values) {
      final bufferPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;

      // Draw buffer stop rectangle at its position
      canvas.drawRect(
        Rect.fromLTWH(
          bufferStop.x - bufferStop.width / 2,
          bufferStop.y - bufferStop.height / 2,
          bufferStop.width,
          bufferStop.height,
        ),
        bufferPaint,
      );

      // Draw yellow diagonal stripes
      final stripePaint = Paint()
        ..color = Colors.yellow
        ..strokeWidth = 2;

      final stripeCount = (bufferStop.width / 5).floor();
      for (int i = 0; i < stripeCount; i++) {
        canvas.drawLine(
          Offset(
            bufferStop.x - bufferStop.width / 2 + (i * 5),
            bufferStop.y - bufferStop.height / 2,
          ),
          Offset(
            bufferStop.x - bufferStop.width / 2 + 10 + (i * 5),
            bufferStop.y + bufferStop.height / 2,
          ),
          stripePaint,
        );
      }
    }
  }

  void _drawPoints(Canvas canvas) {
    for (var point in controller.points.values) {
      Color pointColor;

      // Determine point color based on state
      final isABDeadlocked = false; // AB106 removed - no longer used

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

    // Middle crossover points (78A, 78B) use different geometry
    if (point.id == '78A' || point.id == '78B') {
      _drawStandardCrossoverGap(canvas, point, gapPaint);
    } else {
      // Double diamond points (76A/B, 77A/B, 79A/B, 80A/B)
      _drawDoubleDiamondGap(canvas, point, gapPaint);
    }
  }

  /// Draw gap for standard crossover (78A, 78B)
  /// 78A at (400,100) - entry point on upper track
  /// 78B at (600,300) - exit point on lower track (converging side)
  void _drawStandardCrossoverGap(Canvas canvas, Point point, Paint gapPaint) {
    if (point.id == '78A') {
      // Point at end of block 102/start of block 104 (400,100)
      if (point.position == PointPosition.normal) {
        // Normal: cover straight track continuing forward (centered on point)
        canvas.drawRect(
            Rect.fromLTWH(point.x - 25, point.y + 15, 50, 12), gapPaint);
      } else {
        // Reverse: crossover active, train goes to lower track (diverging)
        final path = Path()
          ..moveTo(point.x - 3, point.y - 22.5)
          ..lineTo(point.x + 50, point.y - 22.5)
          ..lineTo(point.x + 50, point.y + 23)
          ..close();
        canvas.drawPath(path, gapPaint);
      }
    } else if (point.id == '78B') {
      // Point at end of block 105/start of block 107 (600,300) - converging side
      if (point.position == PointPosition.normal) {
        // Normal: cover straight track (centered on point)
        canvas.drawRect(
            Rect.fromLTWH(point.x - 25, point.y - 27.6, 50, 12), gapPaint);
      } else {
        // Reverse: crossover active, train comes from upper track (CONVERGING side like 76B)
        final path = Path()
          ..moveTo(point.x - 3, point.y + 21)
          ..lineTo(point.x - 50, point.y + 21)
          ..lineTo(point.x - 50, point.y - 17.5)
          ..close();
        canvas.drawPath(path, gapPaint);
      }
    }
  }

  /// Draw gap for double diamond crossover points - aligned to block starts
  /// UPDATED: All points now at block boundaries to prevent teleportation
  /// Normal gaps cover converging track, reverse gaps cover straight track
  void _drawDoubleDiamondGap(Canvas canvas, Point point, Paint gapPaint) {
    bool isNormal = point.position == PointPosition.normal;

    // Left section double diamond (points at x=-600 and x=-300)
    if (point.id == '76A') {
      // Upper entry point at -600
      if (isNormal) {
        // Normal: cover straight track continuing forward
        canvas.drawRect(
            Rect.fromLTWH(point.x - 7.5, point.y + 15, 50, 12), gapPaint);
      } else {
        // Reverse: train takes crossover to lower track
        final path = Path()
          ..moveTo(point.x - 3, point.y - 22.5)
          ..lineTo(point.x + 50, point.y - 22.5)
          ..lineTo(point.x + 50, point.y + 23)
          ..close();
        canvas.drawPath(path, gapPaint);
      }
    } else if (point.id == '77A') {
      // Upper exit point at -300
      if (isNormal) {
        // Normal: straight track from left
        canvas.drawRect(
            Rect.fromLTWH(point.x - 57.5, point.y + 15, 50, 12), gapPaint);
      } else {
        // Reverse: from crossover coming from lower track
        final path = Path()
          ..moveTo(point.x + 3, point.y - 22.5)
          ..lineTo(point.x - 50, point.y - 22.5)
          ..lineTo(point.x - 50, point.y + 23)
          ..close();
        canvas.drawPath(path, gapPaint);
      }
    } else if (point.id == '77B') {
      // Lower entry point at -600
      if (isNormal) {
        // Normal: straight track continuing forward
        canvas.drawRect(
            Rect.fromLTWH(point.x - 7.5, point.y - 27.6, 50, 12), gapPaint);
      } else {
        // Reverse: train takes crossover to upper track
        final path = Path()
          ..moveTo(point.x + 3, point.y + 21)
          ..lineTo(point.x + 50, point.y + 21)
          ..lineTo(point.x + 50, point.y - 17.5)
          ..close();
        canvas.drawPath(path, gapPaint);
      }
    } else if (point.id == '76B') {
      // Lower exit point at -300
      if (isNormal) {
        // Normal: straight track from left
        canvas.drawRect(
            Rect.fromLTWH(point.x - 57.5, point.y - 27.6, 50, 12), gapPaint);
      } else {
        // Reverse: from crossover coming from upper track
        final path = Path()
          ..moveTo(point.x - 3, point.y + 21)
          ..lineTo(point.x - 50, point.y + 21)
          ..lineTo(point.x - 50, point.y - 17.5)
          ..close();
        canvas.drawPath(path, gapPaint);
      }
    }
    // Right section double diamond (points at x=1800 and x=2100)
    else if (point.id == '79A') {
      // Upper entry point at 1800
      if (isNormal) {
        canvas.drawRect(
            Rect.fromLTWH(point.x - 7.5, point.y + 15, 50, 12), gapPaint);
      } else {
        final path = Path()
          ..moveTo(point.x - 3, point.y - 22.5)
          ..lineTo(point.x + 50, point.y - 22.5)
          ..lineTo(point.x + 50, point.y + 23)
          ..close();
        canvas.drawPath(path, gapPaint);
      }
    } else if (point.id == '80A') {
      // Upper exit point at 2100
      if (isNormal) {
        canvas.drawRect(
            Rect.fromLTWH(point.x - 57.5, point.y + 15, 50, 12), gapPaint);
      } else {
        final path = Path()
          ..moveTo(point.x + 3, point.y - 22.5)
          ..lineTo(point.x - 50, point.y - 22.5)
          ..lineTo(point.x - 50, point.y + 23)
          ..close();
        canvas.drawPath(path, gapPaint);
      }
    } else if (point.id == '80B') {
      // Lower entry point at 1800
      if (isNormal) {
        canvas.drawRect(
            Rect.fromLTWH(point.x - 7.5, point.y - 27.6, 50, 12), gapPaint);
      } else {
        final path = Path()
          ..moveTo(point.x + 3, point.y + 21)
          ..lineTo(point.x + 50, point.y + 21)
          ..lineTo(point.x + 50, point.y - 17.5)
          ..close();
        canvas.drawPath(path, gapPaint);
      }
    } else if (point.id == '79B') {
      // Lower exit point at 2100
      if (isNormal) {
        canvas.drawRect(
            Rect.fromLTWH(point.x - 57.5, point.y - 27.6, 50, 12), gapPaint);
      } else {
        final path = Path()
          ..moveTo(point.x - 3, point.y + 21)
          ..lineTo(point.x - 50, point.y + 21)
          ..lineTo(point.x - 50, point.y - 17.5)
          ..close();
        canvas.drawPath(path, gapPaint);
      }
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

    bool pointerWest = signal.direction == SignalDirection.west;

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

    // Determine signal light color based on aspect
    Color lightColor;
    if (signal.aspect == SignalAspect.green) {
      lightColor = themeData.signalGreenColor;
    } else if (signal.aspect == SignalAspect.blue) {
      lightColor = Colors.blue;
    } else {
      lightColor = themeData.signalRedColor;
    }

    final lightPaint = Paint()
      ..color = lightColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(signal.x, signal.y - 42.5), 6, lightPaint);

    // Add glow effect for green and blue signals
    if (themeData.showGlow &&
        (signal.aspect == SignalAspect.green ||
            signal.aspect == SignalAspect.blue)) {
      final glowColor = signal.aspect == SignalAspect.green
          ? themeData.signalGreenColor
          : Colors.blue;
      final glowPaint = Paint()
        ..color = glowColor.withOpacity(0.4)
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
    final animationOffset =
        (DateTime.now().millisecondsSinceEpoch % 2000) / 2000.0;

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
      final startX =
          isEastbound ? trainX + 35 : trainX - 35; // Start just ahead of train
      final endX =
          isEastbound ? trainX + ma.maxDistance : trainX - ma.maxDistance;

      // Draw base path with gradient using train's color
      // Color matches the CBTC mode: AUTO/PM = green, RM = yellow/amber
      Color reservationColor;
      if (train.cbtcMode == CbtcMode.auto || train.cbtcMode == CbtcMode.pm) {
        reservationColor = Colors.green;
      } else if (train.cbtcMode == CbtcMode.rm) {
        reservationColor = Colors.amber;
      } else {
        reservationColor = train.color; // Fallback to train's assigned color
      }

      final gradient = LinearGradient(
        colors: [
          reservationColor.withOpacity(0.6),
          reservationColor.withOpacity(0.3),
          reservationColor.withOpacity(0.1),
        ],
        stops: const [0.0, 0.7, 1.0],
      );

      final pathPaint = Paint()
        ..shader = gradient.createShader(Rect.fromPoints(
          Offset(startX, trainY - 5), // Centered on track
          Offset(endX, trainY + 5), // Centered on track
        ))
        ..style = PaintingStyle.fill;

      // Draw the main authority path as a rounded rectangle centered on the track
      final pathRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          isEastbound ? startX : endX,
          trainY - 5, // Centered on track (5 units above train center)
          isEastbound ? endX : startX,
          trainY + 5, // Centered on track (5 units below train center)
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

        // Draw arrow chevron with matching color
        final arrowPaint = Paint()
          ..color = reservationColor.withOpacity(opacity * 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;

        final arrowSize = 6.0;
        final arrowY = trainY; // Centered on track

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

      // Determine train color based on CBTC mode and NCT state
      Color trainColor;
      Color outlineColor;
      double outlineWidth;

      // NCT trains flash red (alternating every 500ms)
      final isFlashingRed = train.isNCT &&
          (DateTime.now().millisecondsSinceEpoch ~/ 500) % 2 == 0;

      if (isFlashingRed) {
        // NCT flashing red
        trainColor = Colors.red;
        outlineColor = Colors.red[900]!;
        outlineWidth = 4;
      } else if (train.isCbtcTrain && train.cbtcMode == CbtcMode.storage) {
        // Storage mode: Green train
        trainColor = Colors.green[600]!;
        outlineColor = Colors.green[900]!;
        outlineWidth = 2;
      } else if (train.isCbtcTrain && train.cbtcMode == CbtcMode.off) {
        // Off mode: White train
        trainColor = Colors.white;
        outlineColor = Colors.grey[800]!;
        outlineWidth = 2;
      } else {
        // Normal color
        trainColor = train.color;
        outlineColor = train.controlMode == TrainControlMode.manual
            ? Colors.blue
            : Colors.black;
        outlineWidth = train.controlMode == TrainControlMode.manual ? 3 : 2;
      }

      final bodyPaint = Paint()
        ..color = trainColor
        ..style = PaintingStyle.fill;

      final outlinePaint = Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = outlineWidth;

      // Determine number of cars based on train type
      int carCount = 1;
      if (train.trainType == TrainType.m2 ||
          train.trainType == TrainType.cbtcM2) {
        carCount = 2;
      } else if (train.trainType == TrainType.m4 ||
          train.trainType == TrainType.cbtcM4) {
        carCount = 4;
      } else if (train.trainType == TrainType.m8 ||
          train.trainType == TrainType.cbtcM8) {
        carCount = 8;
      }

      final isMultiCar = carCount > 1;

      if (isMultiCar) {
        // Draw multiple coupled train cars with individual carriage alignment
        final couplingPaint = Paint()
          ..color = Colors.grey[700]!
          ..style = PaintingStyle.fill;

        const double carWidth = 50.0;
        const double couplingWidth = 8.0;
        const double carHeight = 30.0;

        // Update carriage positions for independent alignment with path-based positioning
        train.updateCarriagePositions(controller.calculatePathPosition);

        // Draw each carriage at its individual position and rotation
        for (int i = 0; i < train.carriages.length; i++) {
          final carriage = train.carriages[i];

          // Save canvas state for individual carriage rotation
          canvas.save();

          // Apply individual carriage rotation if it differs from train rotation
          if (carriage.rotation != 0.0) {
            canvas.translate(carriage.x, carriage.y);
            canvas.rotate(carriage.rotation);
            canvas.translate(-carriage.x, -carriage.y);
          }

          // Draw shadow for depth
          final shadowPaint = Paint()
            ..color = Colors.black.withOpacity(0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                  carriage.x - 24, carriage.y - 13, carWidth, carHeight),
              const Radius.circular(6),
            ),
            shadowPaint,
          );

          // Draw car body centered on carriage position
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                  carriage.x - 25, carriage.y - 15, carWidth, carHeight),
              const Radius.circular(6),
            ),
            bodyPaint,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                  carriage.x - 25, carriage.y - 15, carWidth, carHeight),
              const Radius.circular(6),
            ),
            outlinePaint,
          );

          // Draw windows on each carriage
          final windowPaint = Paint()
            ..color = themeData.trainWindowColor
            ..style = PaintingStyle.fill;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(carriage.x - 18, carriage.y - 10, 10, 6),
              const Radius.circular(2),
            ),
            windowPaint,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(carriage.x + 8, carriage.y - 10, 10, 6),
              const Radius.circular(2),
            ),
            windowPaint,
          );

          canvas.restore();

          // Draw coupling between cars (except after last car)
          if (i < train.carriages.length - 1) {
            final nextCarriage = train.carriages[i + 1];
            final couplingX = (carriage.x + nextCarriage.x) / 2;
            final couplingY = (carriage.y + nextCarriage.y) / 2;

            canvas.drawRect(
              Rect.fromLTWH(couplingX - 4, couplingY - 4, couplingWidth, 8),
              couplingPaint,
            );
          }
        }
      } else {
        // Draw shadow for single train
        final shadowPaint = Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(train.x - 29, train.y - 13, 60, 30),
            const Radius.circular(6),
          ),
          shadowPaint,
        );

        // Draw single train body for M1 trains
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(train.x - 30, train.y - 15, 60, 30),
            const Radius.circular(6),
          ),
          bodyPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(train.x - 30, train.y - 15, 60, 30),
            const Radius.circular(6),
          ),
          outlinePaint,
        );
      }

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
      } else if (!isMultiCar) {
        // Windows for closed doors - only for single-car trains
        // Multi-car trains already have windows drawn in the carriage loop
        final windowPaint = Paint()..color = themeData.trainWindowColor;
        // M1 train - draw windows on single car
        canvas.drawRect(
            Rect.fromLTWH(train.x - 22, train.y - 10, 12, 8), windowPaint);
        canvas.drawRect(
            Rect.fromLTWH(train.x - 6, train.y - 10, 12, 8), windowPaint);
        canvas.drawRect(
            Rect.fromLTWH(train.x + 10, train.y - 10, 12, 8), windowPaint);
      }

      // Wheels (2 wheels per car) - Follow carriage positions and rotations
      final wheelPaint = Paint()..color = Colors.black;
      if (isMultiCar) {
        // Multi-car train - draw wheels for each carriage using carriage positions
        for (int i = 0; i < train.carriages.length; i++) {
          final carriage = train.carriages[i];

          // Save canvas state for individual wheel rotation
          canvas.save();

          // Apply carriage rotation to wheels
          if (carriage.rotation != 0.0) {
            canvas.translate(carriage.x, carriage.y);
            canvas.rotate(carriage.rotation);
            canvas.translate(-carriage.x, -carriage.y);
          }

          // Draw two wheels per carriage, positioned relative to carriage center
          canvas.drawCircle(
              Offset(carriage.x - 13, carriage.y + 15), 6, wheelPaint);
          canvas.drawCircle(
              Offset(carriage.x + 13, carriage.y + 15), 6, wheelPaint);

          canvas.restore();
        }
      } else {
        // M1 train - draw wheels on single car (2 wheels)
        canvas.drawCircle(Offset(train.x - 18, train.y + 15), 6, wheelPaint);
        canvas.drawCircle(Offset(train.x + 18, train.y + 15), 6, wheelPaint);
      }

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

  void _drawGhostTrains(Canvas canvas) {
    // Only draw ghost trains if visibility is enabled
    if (!controller.showGhostTrains || controller.ghostTrains.isEmpty) return;

    for (var ghost in controller.ghostTrains) {
      // Draw ghost train as semi-transparent shadow
      final ghostPaint = Paint()
        ..color = Colors.purple.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      final outlinePaint = Paint()
        ..color = Colors.purple.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      // Determine if M2 type (double unit)
      final isM2 = ghost.trainType == TrainType.m2 ||
          ghost.trainType == TrainType.cbtcM2;

      if (isM2) {
        // Draw two cars for M2 ghost train
        // First car
        final car1Rect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(ghost.x - 13, ghost.y),
            width: 20,
            height: 12,
          ),
          const Radius.circular(4),
        );
        canvas.drawRRect(car1Rect, ghostPaint);
        canvas.drawRRect(car1Rect, outlinePaint);

        // Second car
        final car2Rect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(ghost.x + 13, ghost.y),
            width: 20,
            height: 12,
          ),
          const Radius.circular(4),
        );
        canvas.drawRRect(car2Rect, ghostPaint);
        canvas.drawRRect(car2Rect, outlinePaint);
      } else {
        // Draw single car for M1 ghost train
        final carRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(ghost.x, ghost.y),
            width: 22,
            height: 12,
          ),
          const Radius.circular(4),
        );
        canvas.drawRRect(carRect, ghostPaint);
        canvas.drawRRect(carRect, outlinePaint);
      }

      // Draw "GHOST" label above train
      final textPainter = TextPainter(
        text: TextSpan(
          text: '👻',
          style: TextStyle(
            fontSize: 12,
            color: Colors.purple.withOpacity(0.7),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(ghost.x - textPainter.width / 2, ghost.y - 20),
      );

      // Draw service ID label
      if (ghost.serviceId.isNotEmpty) {
        final serviceTextPainter = TextPainter(
          text: TextSpan(
            text: ghost.serviceId
                .substring(0, math.min(8, ghost.serviceId.length)),
            style: TextStyle(
              fontSize: 8,
              color: Colors.purple.withOpacity(0.6),
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        serviceTextPainter.layout();
        serviceTextPainter.paint(
          canvas,
          Offset(ghost.x - serviceTextPainter.width / 2, ghost.y + 10),
        );
      }

      // Draw door indicator if doors are open
      if (ghost.doorsOpen) {
        final doorPaint = Paint()
          ..color = Colors.yellow.withOpacity(0.6)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(ghost.x, ghost.y - 10), 3, doorPaint);
      }
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

    // Draw point/switch labels
    for (var point in controller.points.values) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: point.id,
          style: TextStyle(
            color: point.position == PointPosition.normal
                ? Colors.green[700]
                : Colors.red[700],
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(point.x - textPainter.width / 2, point.y - 50));
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

  // ============================================================================
  // GRID DRAWING
  // ============================================================================
  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final spacing = controller.gridSpacing;

    // Calculate grid bounds (expand beyond visible area)
    final gridStartX = -3500.0;
    final gridEndX = 3500.0;
    final gridStartY = -600.0;
    final gridEndY = 600.0;

    // Draw vertical lines
    for (double x = gridStartX; x <= gridEndX; x += spacing) {
      canvas.drawLine(
        Offset(x, gridStartY),
        Offset(x, gridEndY),
        gridPaint,
      );
    }

    // Draw horizontal lines
    for (double y = gridStartY; y <= gridEndY; y += spacing) {
      canvas.drawLine(
        Offset(gridStartX, y),
        Offset(gridEndX, y),
        gridPaint,
      );
    }
  }

  // ============================================================================
  // TOOLTIP DRAWING
  // ============================================================================
  void _drawTooltip(Canvas canvas) {
    final hovered = controller.hoveredObject;
    if (hovered == null) return;

    final type = hovered['type'] as String?;
    final id = hovered['id'] as String?;
    final x = hovered['x'] as double?;
    final y = hovered['y'] as double?;

    if (type == null || id == null || x == null || y == null) return;

    // Draw highlight around hovered object
    final highlightPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x, y), 25, highlightPaint);

    final outlinePaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(Offset(x, y), 25, outlinePaint);

    // Build detailed tooltip text based on object type
    String tooltipText =
        '$type: $id\nX: ${x.toStringAsFixed(1)} | Y: ${y.toStringAsFixed(1)}';

    // Add detailed information based on type
    if (type == 'Signal') {
      final signal = controller.signals[id];
      if (signal != null) {
        tooltipText += '\nAspect: ${signal.aspect.name.toUpperCase()}';
        tooltipText += '\nRoute State: ${signal.routeState.name}';
        if (signal.activeRouteId != null) {
          final activeRoute = signal.routes.firstWhere(
            (r) => r.id == signal.activeRouteId,
            orElse: () => signal.routes.first,
          );
          tooltipText += '\nActive: ${activeRoute.name}';
        }
        tooltipText += '\nRoutes Available: ${signal.routes.length}';
      }
    } else if (type == 'Crossover') {
      final crossover = controller.crossovers[id];
      if (crossover != null) {
        final name = hovered['name'] as String?;
        if (name != null && name != id) {
          tooltipText += '\nName: $name';
        }
        tooltipText += '\nType: ${crossover.type.name.toUpperCase()}';
        tooltipText += '\nBlock: ${crossover.blockId}';
        tooltipText += '\nPoints: ${crossover.pointIds.join(", ")}';
        tooltipText += '\nActive: ${crossover.isActive ? "YES" : "NO"}';
        tooltipText += '\nGap Angle: ${crossover.gapAngle.toStringAsFixed(1)}°';

        // Show point positions
        final pointPositions = <String>[];
        for (final pointId in crossover.pointIds) {
          final point = controller.points[pointId];
          if (point != null) {
            pointPositions.add('$pointId: ${point.position.name}');
          }
        }
        if (pointPositions.isNotEmpty) {
          tooltipText += '\n${pointPositions.join(" | ")}';
        }
      }
    } else if (type == 'Point') {
      final point = controller.points[id];
      if (point != null) {
        final name = hovered['name'] as String?;
        if (name != null && name != id) {
          tooltipText += '\nName: $name';
        }
        tooltipText += '\nPosition: ${point.position.name.toUpperCase()}';
        // Add WKR relay information
        final wkrStatus =
            point.position == PointPosition.normal ? 'NWP (DOWN)' : 'RWP (UP)';
        tooltipText += '\nWKR Relay: $id WKR - $wkrStatus';
        tooltipText += '\nLocked: ${point.locked ? "YES" : "NO"}';
        if (point.lockedByAB) {
          tooltipText += '\nLocked by AB System';
        }
        // Show crossover relationship
        if (point.crossoverId != null) {
          tooltipText += '\nPart of Crossover: ${point.crossoverId}';
        }
      }
    } else if (type == 'Train') {
      final train = controller.trains
          .firstWhere((t) => t.id == id, orElse: () => controller.trains.first);
      tooltipText += '\nName: ${train.name}';
      tooltipText += '\nVIN: ${train.vin}';
      tooltipText += '\nSpeed: ${train.speed.toStringAsFixed(1)} m/s';
      tooltipText += '\nTarget: ${train.targetSpeed.toStringAsFixed(1)} m/s';
      tooltipText +=
          '\nDirection: ${train.direction > 0 ? "EAST ➜" : "WEST ⬅"}';
      tooltipText += '\nControl: ${train.controlMode.name}';
      if (train.isCbtcEquipped) {
        tooltipText += '\nCBTC Mode: ${train.cbtcMode.name.toUpperCase()}';
      }
      // Show destination for all trains
      if (train.smcDestination != null) {
        tooltipText += '\nDestination: ${train.smcDestination}';
      }
      if (train.currentBlockId != null) {
        tooltipText += '\nBlock: ${train.currentBlockId}';
      }
      if (train.emergencyBrake) {
        tooltipText += '\n⚠️  EMERGENCY BRAKE ACTIVE';
      }
    } else if (type == 'Block') {
      final block = controller.blocks[id];
      if (block != null) {
        tooltipText += '\nOccupied: ${block.occupied ? "YES" : "NO"}';
        // Add TR relay information
        final trStatus =
            block.occupied ? 'DOWN (Train Present)' : 'UP (Track Clear)';
        tooltipText += '\nTR Relay: ${id}TR - $trStatus';
        if (block.occupyingTrainId != null) {
          tooltipText += '\nTrain: ${block.occupyingTrainId}';
        }
        if (block.name != null) {
          tooltipText += '\nName: ${block.name}';
        }
      }
    } else if (type == 'Platform') {
      final platform = hovered['name'] as String?;
      if (platform != null) {
        tooltipText += '\nName: $platform';
      }
      final platformObj = controller.platforms.firstWhere(
        (p) => p.id == id,
        orElse: () => controller.platforms.first,
      );
      tooltipText += '\nLength: ${(platformObj.endX - platformObj.startX).toStringAsFixed(1)}m';
      tooltipText += '\nStart: ${platformObj.startX.toStringAsFixed(1)}';
      tooltipText += '\nEnd: ${platformObj.endX.toStringAsFixed(1)}';
    } else if (type == 'Train Stop') {
      final stopActive = hovered['active'] as String?;
      tooltipText += '\nActive: ${stopActive ?? "Unknown"}';
      final stop = controller.trainStops[id];
      if (stop != null) {
        tooltipText += '\nPlatform Zone Marker';
        tooltipText += '\nAutomatic Stopping Point';
      }
    } else if (type == 'Buffer Stop') {
      tooltipText += '\nEnd of Track Marker';
      tooltipText += '\nPhysical Buffer Protection';
      final buffer = controller.bufferStops[id];
      if (buffer != null) {
        // Infer orientation from position: left side faces east, right side faces west
        final isEastFacing = buffer.x < 0;
        tooltipText += '\nOrientation: ${isEastFacing ? "East Facing" : "West Facing"}';
      }
    } else if (type == 'Axle Counter') {
      final blockId = hovered['blockId'] as String?;
      if (blockId != null) {
        tooltipText += '\nBlock: $blockId';
      }
      final counter = controller.axleCounters[id];
      if (counter != null) {
        tooltipText += '\nCount: ${counter.count}';
        tooltipText += '\nD1 Sensor: ${counter.d1Active ? "ACTIVE" : "Inactive"}';
        tooltipText += '\nD2 Sensor: ${counter.d2Active ? "ACTIVE" : "Inactive"}';
        if (counter.lastDirection.isNotEmpty) {
          // lastDirection is a String like 'Eastbound', 'Westbound', 'D1', or 'D2'
          final isEast = counter.lastDirection.contains('East') || counter.lastDirection == 'D1';
          tooltipText += '\nLast Direction: ${isEast ? "East ➜" : "West ⬅"}';
        }
        tooltipText += '\nDetection Range: 15.0 units';
      }
    } else if (type == 'Transponder') {
      final transponder = controller.transponders[id];
      if (transponder != null) {
        tooltipText += '\nType: ${transponder.type}';
        tooltipText += '\nTrack Position Marker';
        tooltipText += '\nCBTC Communication Point';
      }
    } else if (type == 'WiFi Antenna') {
      final antenna = controller.wifiAntennas[id];
      if (antenna != null) {
        tooltipText += '\nStatus: ${antenna.isActive ? "ACTIVE" : "Inactive"}';
        tooltipText += '\nCoverage Range: 350.0 units';
        tooltipText += '\nCBTC Wireless Communication';
        tooltipText += '\nTrain-to-Wayside Data Link';
      }
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: tooltipText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final tooltipPadding = 8.0;
    final tooltipWidth = textPainter.width + tooltipPadding * 2;
    final tooltipHeight = textPainter.height + tooltipPadding * 2;
    final tooltipX = x + 30;
    final tooltipY = y - tooltipHeight / 2;

    // Draw tooltip background with 50% opacity as requested
    final tooltipBgPaint = Paint()
      ..color = Colors.black.withOpacity(0.5) // 50% opacity
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(tooltipX, tooltipY, tooltipWidth, tooltipHeight),
        const Radius.circular(4),
      ),
      tooltipBgPaint,
    );

    // Draw tooltip border with 50% opacity
    final tooltipBorderPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.5) // 50% opacity
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(tooltipX, tooltipY, tooltipWidth, tooltipHeight),
        const Radius.circular(4),
      ),
      tooltipBorderPaint,
    );

    // Draw text
    textPainter.paint(
        canvas, Offset(tooltipX + tooltipPadding, tooltipY + tooltipPadding));
  }

  // ============================================================================
  // SELECTION HIGHLIGHT DRAWING (EDIT MODE)
  // ============================================================================
  void _drawSelectionHighlight(Canvas canvas) {
    if (controller.selectedComponentId == null ||
        controller.selectedComponentType == null) {
      return;
    }

    final String type = controller.selectedComponentType!;
    final String id = controller.selectedComponentId!;
    double? x;
    double? y;

    // Get position based on component type
    switch (type.toLowerCase()) {
      case 'signal':
        final signal = controller.signals[id];
        if (signal != null) {
          x = signal.x;
          y = signal.y;
        }
        break;

      case 'point':
        final point = controller.points[id];
        if (point != null) {
          x = point.x;
          y = point.y;
        }
        break;

      case 'platform':
        try {
          final platform = controller.platforms.firstWhere((p) => p.id == id);
          // Use midpoint for platforms
          x = platform.startX + (platform.endX - platform.startX) / 2;
          y = platform.y;
        } catch (e) {
          // Platform not found
        }
        break;

      case 'trainstop':
        final trainStop = controller.trainStops[id];
        if (trainStop != null) {
          x = trainStop.x;
          y = trainStop.y;
        }
        break;

      case 'bufferstop':
        // FIXED: Buffer stops are now dynamically positioned
        final bufferStop = controller.bufferStops[id];
        if (bufferStop != null) {
          x = bufferStop.x;
          y = bufferStop.y;
        }
        break;

      case 'axlecounter':
        final axleCounter = controller.axleCounters[id];
        if (axleCounter != null) {
          x = axleCounter.x;
          y = axleCounter.y;
        }
        break;

      case 'transponder':
        final transponder = controller.transponders[id];
        if (transponder != null) {
          x = transponder.x;
          y = transponder.y;
        }
        break;

      case 'wifiantenna':
        final antenna = controller.wifiAntennas[id];
        if (antenna != null) {
          x = antenna.x;
          y = antenna.y;
        }
        break;

      default:
        return;
    }

    // If we found a position, draw the selection highlight
    if (x != null && y != null) {
      // IMPROVED: Draw professional bounding box instead of circle
      final double boxSize = 40.0; // Bounding box size
      final double handleSize = 8.0; // Corner handle size

      // Draw bounding box rectangle with dashed border
      final boxPaint = Paint()
        ..color = Colors.cyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final boxRect = Rect.fromCenter(
        center: Offset(x, y),
        width: boxSize * 2,
        height: boxSize * 2,
      );

      // Dashed rect effect
      _drawDashedRect(canvas, boxRect, boxPaint, dashWidth: 5, dashSpace: 5);

      // Semi-transparent fill
      final fillPaint = Paint()
        ..color = Colors.cyan.withOpacity(0.15)
        ..style = PaintingStyle.fill;
      canvas.drawRect(boxRect, fillPaint);

      // Draw 4 corner handles
      final handlePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final handleOutlinePaint = Paint()
        ..color = Colors.cyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      // Top-left
      _drawHandle(canvas, Offset(boxRect.left, boxRect.top), handleSize,
          handlePaint, handleOutlinePaint);
      // Top-right
      _drawHandle(canvas, Offset(boxRect.right, boxRect.top), handleSize,
          handlePaint, handleOutlinePaint);
      // Bottom-left
      _drawHandle(canvas, Offset(boxRect.left, boxRect.bottom), handleSize,
          handlePaint, handleOutlinePaint);
      // Bottom-right
      _drawHandle(canvas, Offset(boxRect.right, boxRect.bottom), handleSize,
          handlePaint, handleOutlinePaint);

      // Draw component info label above bounding box
      final labelText = '$type: $id';
      final textPainter = TextPainter(
        text: TextSpan(
          text: labelText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.cyan,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Draw label background
      final labelBgPaint = Paint()
        ..color = Colors.cyan
        ..style = PaintingStyle.fill;
      final labelRect = Rect.fromLTWH(
        x - textPainter.width / 2 - 4,
        boxRect.top - 20,
        textPainter.width + 8,
        16,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(3)),
        labelBgPaint,
      );

      // Draw label text
      textPainter.paint(
          canvas, Offset(x - textPainter.width / 2, boxRect.top - 18));

      // Draw coordinates below bounding box
      final coordText = '(${x.toInt()}, ${y.toInt()})';
      final coordPainter = TextPainter(
        text: TextSpan(
          text: coordText,
          style: TextStyle(
            color: Colors.cyan.shade700,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      coordPainter.layout();
      coordPainter.paint(
          canvas, Offset(x - coordPainter.width / 2, boxRect.bottom + 4));
    }

    // Draw platform resize handles if platform is selected
    if (type.toLowerCase() == 'platform') {
      _drawPlatformResizeHandles(canvas, id);
    }
  }

  /// Draw resize handles for selected platform
  void _drawPlatformResizeHandles(Canvas canvas, String platformId) {
    try {
      final platform =
          controller.platforms.firstWhere((p) => p.id == platformId);

      // Draw resize handles at left and right edges
      final handleSize = 12.0;
      final handlePaint = Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.fill;

      final handleOutlinePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      // Left handle
      final leftHandleRect = Rect.fromCenter(
        center: Offset(platform.startX, platform.y),
        width: handleSize,
        height: handleSize,
      );
      canvas.drawRect(leftHandleRect, handlePaint);
      canvas.drawRect(leftHandleRect, handleOutlinePaint);

      // Right handle
      final rightHandleRect = Rect.fromCenter(
        center: Offset(platform.endX, platform.y),
        width: handleSize,
        height: handleSize,
      );
      canvas.drawRect(rightHandleRect, handlePaint);
      canvas.drawRect(rightHandleRect, handleOutlinePaint);

      // Draw width dimension line above platform
      final dimensionY = platform.y - 30;
      final dimensionPaint = Paint()
        ..color = Colors.cyan.withOpacity(0.7)
        ..strokeWidth = 1.5;

      // Dimension line
      canvas.drawLine(
        Offset(platform.startX, dimensionY),
        Offset(platform.endX, dimensionY),
        dimensionPaint,
      );

      // End caps
      canvas.drawLine(
        Offset(platform.startX, dimensionY - 5),
        Offset(platform.startX, dimensionY + 5),
        dimensionPaint,
      );
      canvas.drawLine(
        Offset(platform.endX, dimensionY - 5),
        Offset(platform.endX, dimensionY + 5),
        dimensionPaint,
      );

      // Width text
      final width = platform.endX - platform.startX;
      final textSpan = TextSpan(
        text: '${width.toStringAsFixed(0)} units',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black.withOpacity(0.7),
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (platform.startX + platform.endX) / 2 - textPainter.width / 2,
          dimensionY - textPainter.height - 5,
        ),
      );
    } catch (e) {
      // Platform not found
    }
  }

  @override
  bool shouldRepaint(TerminalStationPainter oldDelegate) {
    return controller != oldDelegate.controller ||
        cameraOffsetX != oldDelegate.cameraOffsetX ||
        cameraOffsetY != oldDelegate.cameraOffsetY ||
        zoom != oldDelegate.zoom ||
        animationTick != oldDelegate.animationTick ||
        canvasWidth != oldDelegate.canvasWidth ||
        canvasHeight != oldDelegate.canvasHeight ||
        themeData != oldDelegate.themeData;
  }

  // Helper method to draw dashed rectangle
  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint,
      {double dashWidth = 5, double dashSpace = 5}) {
    // Top edge
    _drawDashedLine(canvas, Offset(rect.left, rect.top),
        Offset(rect.right, rect.top), paint, dashWidth, dashSpace);
    // Right edge
    _drawDashedLine(canvas, Offset(rect.right, rect.top),
        Offset(rect.right, rect.bottom), paint, dashWidth, dashSpace);
    // Bottom edge
    _drawDashedLine(canvas, Offset(rect.right, rect.bottom),
        Offset(rect.left, rect.bottom), paint, dashWidth, dashSpace);
    // Left edge
    _drawDashedLine(canvas, Offset(rect.left, rect.bottom),
        Offset(rect.left, rect.top), paint, dashWidth, dashSpace);
  }

  // Helper method to draw dashed line
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint,
      double dashWidth, double dashSpace) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final dashCount = (distance / (dashWidth + dashSpace)).floor();

    for (int i = 0; i < dashCount; i++) {
      final t1 = (i * (dashWidth + dashSpace)) / distance;
      final t2 =
          math.min(((i * (dashWidth + dashSpace)) + dashWidth) / distance, 1.0);

      final x1 = start.dx + dx * t1;
      final y1 = start.dy + dy * t1;
      final x2 = start.dx + dx * t2;
      final y2 = start.dy + dy * t2;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  // Helper method to draw corner handle
  void _drawHandle(Canvas canvas, Offset center, double size, Paint fillPaint,
      Paint outlinePaint) {
    final handleRect =
        Rect.fromCenter(center: center, width: size, height: size);
    canvas.drawRect(handleRect, fillPaint);
    canvas.drawRect(handleRect, outlinePaint);
  }
}
