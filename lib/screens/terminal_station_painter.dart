import 'package:flutter/material.dart';
import 'terminal_station_models.dart';
import '../controllers/terminal_station_controller.dart';
import '../painters/terminal_station/collision_effects_painter.dart';
import '../painters/terminal_station/block_painter.dart';
import '../painters/terminal_station/signal_painter.dart';
import '../painters/terminal_station/train_painter.dart';
import '../painters/terminal_station/track_painter.dart';
import '../painters/terminal_station/label_painter.dart';
import '../painters/terminal_station/route_painter.dart';
import '../painters/terminal_station/axle_counter_painter.dart';
import '../painters/terminal_station/movement_authority_painter.dart';

class TerminalStationPainter extends CustomPainter with CollisionVisualEffects {
  final TerminalStationController controller;
  final double cameraOffsetX;
  final double zoom;
  final int animationTick;
  final double canvasWidth;
  final double canvasHeight;

  // Painter instances
  final BlockPainter _blockPainter = BlockPainter();
  final SignalPainter _signalPainter = SignalPainter();
  final TrainPainter _trainPainter = TrainPainter();
  final TrackPainter _trackPainter = TrackPainter();
  final LabelPainter _labelPainter = LabelPainter();
  final RoutePainter _routePainter = RoutePainter();
  final AxleCounterPainter _axleCounterPainter = AxleCounterPainter();
  final MovementAuthorityPainter _movementAuthorityPainter = MovementAuthorityPainter();

  TerminalStationPainter({
    required this.controller,
    required this.cameraOffsetX,
    required this.zoom,
    required this.animationTick,
    required this.canvasWidth,
    required this.canvasHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(zoom);
    canvas.translate(cameraOffsetX, -100);

    _blockPainter.drawTracks(canvas, controller.blocks);
    _routePainter.drawRouteReservations(canvas, controller);
    _trackPainter.drawPlatforms(canvas, controller.platforms);
    _trackPainter.drawBufferStop(canvas);
    _trackPainter.drawPoints(canvas, controller.points, controller);
    _signalPainter.drawSignals(canvas, controller.signals, controller.signalsVisible);
    _trackPainter.drawTrainStops(canvas, controller.trainStops, controller.trainStopsEnabled);
    _axleCounterPainter.drawAxleCounters(canvas, controller);
    _axleCounterPainter.drawABOccupations(canvas, controller);
    _movementAuthorityPainter.drawMovementAuthorities(canvas, controller.trains);
    _trainPainter.drawTrains(canvas, controller.trains);
    _labelPainter.drawDirectionLabels(canvas);
    _labelPainter.drawLabels(canvas, controller.blocks, controller.signals,
        controller.platforms, controller.trains, controller.signalsVisible);

    drawCollisionEffects(canvas, controller, animationTick);

    canvas.restore();
  }

  @override
  bool shouldRepaint(TerminalStationPainter oldDelegate) {
    return oldDelegate.controller != controller ||
        oldDelegate.cameraOffsetX != cameraOffsetX ||
        oldDelegate.zoom != zoom ||
        oldDelegate.animationTick != animationTick ||
        oldDelegate.canvasWidth != canvasWidth ||
        oldDelegate.canvasHeight != canvasHeight;
  }
}
