import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/terminal_editor_models.dart';
import '../providers/terminal_editor_provider.dart';

class TerminalEditorCanvas extends StatefulWidget {
  final TransformationController controller;
  final Size canvasSize;

  const TerminalEditorCanvas({
    super.key,
    required this.controller,
    required this.canvasSize,
  });

  @override
  State<TerminalEditorCanvas> createState() => _TerminalEditorCanvasState();
}

class _TerminalEditorCanvasState extends State<TerminalEditorCanvas>
    with TickerProviderStateMixin {
  final Map<String, AnimationController> _pointControllers = {};

  bool _isAdditiveSelection() {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    return keys.contains(LogicalKeyboardKey.shiftLeft) ||
        keys.contains(LogicalKeyboardKey.shiftRight) ||
        keys.contains(LogicalKeyboardKey.controlLeft) ||
        keys.contains(LogicalKeyboardKey.controlRight);
  }

  @override
  void dispose() {
    for (final controller in _pointControllers.values) {
      controller.dispose();
    }
    _pointControllers.clear();
    super.dispose();
  }

  void _syncPointAnimations(TerminalEditorProvider provider) {
    final activeIds = provider.points.keys.toSet();
    final toRemove = _pointControllers.keys
        .where((id) => !activeIds.contains(id))
        .toList();
    for (final id in toRemove) {
      _pointControllers.remove(id)?.dispose();
    }

    for (final entry in provider.points.entries) {
      final id = entry.key;
      final point = entry.value;
      final target = point.position == PointPosition.reverse ? 1.0 : 0.0;
      final existing = _pointControllers[id];
      if (existing == null) {
        final controller = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 260),
          value: target,
        )..addListener(() {
            if (mounted) setState(() {});
          });
        _pointControllers[id] = controller;
      } else if ((existing.value - target).abs() > 0.01) {
        existing.animateTo(target, curve: Curves.easeInOut);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TerminalEditorProvider>(context);
    _syncPointAnimations(provider);
    final pointAnimations = <String, double>{
      for (final entry in _pointControllers.entries)
        entry.key: entry.value.value
    };

    return InteractiveViewer(
      transformationController: widget.controller,
      panEnabled: provider.panMode,
      scaleEnabled: true,
      minScale: 0.2,
      maxScale: 8.0,
      boundaryMargin: const EdgeInsets.all(6000),
      child: SizedBox(
        width: widget.canvasSize.width,
        height: widget.canvasSize.height,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final pos = widget.controller.toScene(details.localPosition);
            if (provider.tool == EditorTool.select ||
                provider.tool == EditorTool.move) {
              if (_isAdditiveSelection()) {
                provider.toggleSelectAt(pos);
              } else {
                provider.selectAt(pos);
              }
            } else if (provider.tool != EditorTool.marqueeSelect) {
              provider.addAt(pos);
            }
          },
          onPanStart: (details) {
            if (provider.panMode) return;
            final pos = widget.controller.toScene(details.localPosition);
            if (provider.tool == EditorTool.marqueeSelect) {
              provider.startMarquee(pos);
              return;
            }
            if (provider.tool == EditorTool.select) {
              final handle =
                  provider.handlesFirst ? provider.hitTestHandle(pos) : null;
              if (handle != null) {
                provider.setResizeHandle(handle);
              } else if (_isAdditiveSelection()) {
                provider.toggleSelectAt(pos);
              } else {
                provider.selectAt(pos);
              }
              if (provider.selected != null) {
                provider.startDrag(pos);
              }
              return;
            }
            if (provider.tool == EditorTool.move) {
              final hit = provider.hitTestAt(pos);
              if (_isAdditiveSelection()) {
                if (hit != null) {
                  provider.toggleSelectAt(pos);
                }
              } else if (hit == null || !provider.selection.contains(hit)) {
                provider.selectAt(pos);
              }
              if (provider.selected != null) {
                provider.startDrag(pos);
              }
            }
          },
          onPanUpdate: (details) {
            if (provider.panMode) return;
            final pos = widget.controller.toScene(details.localPosition);
            if (provider.tool == EditorTool.marqueeSelect) {
              provider.updateMarquee(pos);
              return;
            }
            if (provider.tool == EditorTool.select ||
                provider.tool == EditorTool.move) {
              provider.updateDrag(pos);
            }
          },
          onPanEnd: (_) {
            if (provider.panMode) return;
            if (provider.tool == EditorTool.marqueeSelect) {
              provider.endMarquee(additive: _isAdditiveSelection());
              return;
            }
            if (provider.tool == EditorTool.select ||
                provider.tool == EditorTool.move) {
              provider.endDrag();
            }
          },
          child: CustomPaint(
            painter: TerminalEditorPainter(
              provider: provider,
              pointAnimations: pointAnimations,
            ),
            size: widget.canvasSize,
          ),
        ),
      ),
    );
  }
}

class TerminalEditorPainter extends CustomPainter {
  final TerminalEditorProvider provider;
  final Map<String, double> pointAnimations;
  final bool _defaultSimulationStyle;

  static const Color _simCanvasBackground = Color(0xFFF5F5F5);
  static const Color _simTrackColor = Color(0xFFBDBDBD);
  static const Color _simTrackOccupiedColor = Color(0xFFBA68C8);
  static const Color _simRailColor = Color(0xFF616161);
  static const Color _simSleeperColor = Color(0xFF5D4037);
  static const Color _simPlatformColor = Color(0xFFFBC02D);
  static const Color _simPlatformEdgeColor = Color(0xFFFF6F00);
  static const Color _simSignalPoleColor = Color(0xFF424242);
  static const Color _simSignalRed = Color(0xFFD32F2F);
  static const Color _simSignalGreen = Color(0xFF388E3C);
  static const Color _simSignalYellow = Color(0xFFFBC02D);

  TerminalEditorPainter({
    required this.provider,
    required this.pointAnimations,
  }) : _defaultSimulationStyle =
            provider.renderStyle == BuilderRenderStyle.simulation;

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    if (provider.gridVisible && provider.snapToGrid) {
      _drawGrid(canvas, size, provider.gridSize);
    }

    for (final entry in provider.segments.entries) {
      _drawSegment(canvas, entry.key, entry.value);
    }
    for (final entry in provider.crossovers.entries) {
      _drawCrossover(canvas, entry.key, entry.value);
    }
    for (final entry in provider.platforms.entries) {
      _drawPlatform(canvas, entry.key, entry.value);
    }
    for (final entry in provider.points.entries) {
      _drawPoint(canvas, entry.key, entry.value);
    }
    for (final entry in provider.signals.entries) {
      _drawSignal(canvas, entry.key, entry.value);
    }
    for (final entry in provider.trainStops.entries) {
      _drawTrainStop(canvas, entry.key, entry.value);
    }
    for (final entry in provider.bufferStops.entries) {
      _drawBufferStop(canvas, entry.key, entry.value);
    }
    for (final entry in provider.axleCounters.entries) {
      _drawAxleCounter(canvas, entry.key, entry.value);
    }
    for (final entry in provider.transponders.entries) {
      _drawTransponder(canvas, entry.key, entry.value);
    }
    for (final entry in provider.wifiAntennas.entries) {
      _drawWifi(canvas, entry.key, entry.value);
    }
    for (final entry in provider.textAnnotations.entries) {
      _drawText(canvas, entry.key, entry.value);
    }

    _drawMarquee(canvas);
    _drawSelection(canvas);
    if (provider.guidewayDirectionsVisible) {
      _drawGuidewayDirections(canvas);
    }
    if (provider.alphaGammaVisible) {
      _drawAlphaGammaMarkers(canvas);
    }
    if (provider.compassVisible) {
      _drawCompass(canvas, size);
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _defaultSimulationStyle
          ? _simCanvasBackground
          : provider.backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _drawMarquee(Canvas canvas) {
    final rect = provider.marqueeRect;
    if (rect == null) return;
    final fill = Paint()
      ..color = const Color(0x33457B9D)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = const Color(0xFF457B9D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, stroke);
  }

  bool _isSimulationStyleFor(EditorComponentType type, String id) {
    return provider.getRenderStyleFor(type, id) ==
        BuilderRenderStyle.simulation;
  }

  void _drawGrid(Canvas canvas, Size size, double gridSize) {
    final paint = Paint()
      ..color = const Color(0xFFE2E2E2)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawSegment(Canvas canvas, String id, TrackSegment segment) {
    if (_isSimulationStyleFor(EditorComponentType.trackSegment, id)) {
      _drawSegmentSimulationStyle(canvas, segment);
      return;
    }
    final start = Offset(segment.startX, segment.startY);
    final end = segment.endPoint();
    final length = (end - start).distance;
    if (length <= 0.1) return;
    final normal = _normalVector(segment.angleDeg);
    final baseColor = segment.occupied
        ? const Color(0xFFD62828)
        : _styleBaseColor(segment.style, segment.color);
    final railColor = _styleRailColor(segment.style);
    final style = _styleConfig(segment.style);

    if (style.shadowOffset != 0) {
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..strokeWidth = style.baseWidth
        ..strokeCap = StrokeCap.round;
      final shadowOffset = normal * style.shadowOffset;
      canvas.drawLine(start + shadowOffset, end + shadowOffset, shadowPaint);
    }

    final basePaint = Paint()
      ..color = baseColor
      ..strokeWidth = style.baseWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, basePaint);

    final railPaint = Paint()
      ..color = railColor
      ..strokeWidth = style.railWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
        start + normal * style.railSpacing,
        end + normal * style.railSpacing,
        railPaint);
    canvas.drawLine(
        start - normal * style.railSpacing,
        end - normal * style.railSpacing,
        railPaint);

    if (style.guardRailSpacing != null) {
      final guardPaint = Paint()
        ..color = railColor.withOpacity(0.7)
        ..strokeWidth = style.railWidth * 0.8
        ..strokeCap = StrokeCap.round;
      final guardOffset = style.guardRailSpacing!;
      canvas.drawLine(
          start + normal * guardOffset,
          end + normal * guardOffset,
          guardPaint);
      canvas.drawLine(
          start - normal * guardOffset,
          end - normal * guardOffset,
          guardPaint);
    }

    if (style.centerLine) {
      final centerPaint = Paint()
        ..color = railColor.withOpacity(0.5)
        ..strokeWidth = style.railWidth * 0.8
        ..strokeCap = StrokeCap.round;
      _drawDashes(canvas, start, end, centerPaint,
          dashLength: 12, gapLength: 10);
    }

    if (style.showSleepers) {
      final sleeperPaint = Paint()
        ..color = style.sleeperColor
        ..strokeWidth = style.sleeperWidth
        ..strokeCap = StrokeCap.round;
      _drawSleepers(
        canvas,
        start,
        end,
        style.sleeperSpacing,
        style.sleeperLength,
        sleeperPaint,
      );
    }

    if (style.addGravelDots) {
      final dotPaint = Paint()
        ..color = baseColor.withOpacity(0.35)
        ..style = PaintingStyle.fill;
      _drawGravelDots(canvas, start, end, dotPaint);
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: segment.id,
        style: const TextStyle(
          color: Color(0xFF2D2D2D),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final center = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - 22),
    );
  }



  void _drawSegmentSimulationStyle(Canvas canvas, TrackSegment segment) {
    final start = Offset(segment.startX, segment.startY);
    final end = segment.endPoint();
    final direction = end - start;
    final length = direction.distance;
    if (length <= 0.1) return;
    final unit = direction / length;
    final perp = Offset(-unit.dy, unit.dx);

    final blockPaint = Paint()
      ..color = segment.occupied
          ? _simTrackOccupiedColor.withOpacity(0.3)
          : _simTrackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30;
    canvas.drawLine(start, end, blockPaint);

    final outerRailPaint = Paint()
      ..color = _simRailColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final innerRailPaint = Paint()
      ..color = _simRailColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const railSpacing = 12.0;
    final outerOffset = perp * (railSpacing / 2 + 8);
    final innerOffset = perp * (railSpacing / 2 - 8);

    canvas.drawLine(start + outerOffset, end + outerOffset, outerRailPaint);
    canvas.drawLine(start + innerOffset, end + innerOffset, innerRailPaint);
    canvas.drawLine(start - innerOffset, end - innerOffset, innerRailPaint);
    canvas.drawLine(start - outerOffset, end - outerOffset, outerRailPaint);

    final sleeperPaint = Paint()
      ..color = _simSleeperColor
      ..strokeWidth = 6;
    for (double d = 0; d <= length; d += 15) {
      final center = start + unit * d;
      final sleeperHalf = perp * 12;
      canvas.drawLine(center - sleeperHalf, center + sleeperHalf, sleeperPaint);
    }
  }
  void _drawCrossover(Canvas canvas, String id, Crossover crossover) {
    if (_isSimulationStyleFor(EditorComponentType.crossover, id)) {
      _drawCrossoverSimulationStyle(canvas, crossover);
      return;
    }
    final lines = provider.getCrossoverRenderLines(crossover);
    if (lines.isNotEmpty) {
      for (final line in lines) {
        if (line.length < 2) continue;
        _drawStyledTrackLine(
          canvas,
          line[0],
          line[1],
          crossover.style,
          crossover.color,
        );
      }
    } else {
      final size = 26.0;
      switch (crossover.type) {
        case CrossoverType.lefthand:
          _drawStyledTrackLine(
            canvas,
            Offset(crossover.x - size, crossover.y + size),
            Offset(crossover.x + size, crossover.y - size),
            crossover.style,
            crossover.color,
          );
          break;
        case CrossoverType.righthand:
          _drawStyledTrackLine(
            canvas,
            Offset(crossover.x - size, crossover.y - size),
            Offset(crossover.x + size, crossover.y + size),
            crossover.style,
            crossover.color,
          );
          break;
        case CrossoverType.doubleDiamond:
          _drawStyledTrackLine(
            canvas,
            Offset(crossover.x - size, crossover.y - size),
            Offset(crossover.x + size, crossover.y + size),
            crossover.style,
            crossover.color,
          );
          _drawStyledTrackLine(
            canvas,
            Offset(crossover.x - size, crossover.y + size),
            Offset(crossover.x + size, crossover.y - size),
            crossover.style,
            crossover.color,
          );
          break;
        case CrossoverType.singleSlip:
        case CrossoverType.doubleSlip:
          _drawStyledTrackLine(
            canvas,
            Offset(crossover.x - size, crossover.y),
            Offset(crossover.x + size, crossover.y),
            crossover.style,
            crossover.color,
          );
          _drawStyledTrackLine(
            canvas,
            Offset(crossover.x - size, crossover.y - size),
            Offset(crossover.x + size, crossover.y + size),
            crossover.style,
            crossover.color,
          );
          break;
      }
    }

    final ring = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(crossover.x, crossover.y), 6, ring);
  }

  void _drawCrossoverSimulationStyle(Canvas canvas, Crossover crossover) {
    final paint = Paint()
      ..color = _simRailColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final lines = provider.getCrossoverRenderLines(crossover);
    if (lines.isNotEmpty) {
      for (final line in lines) {
        if (line.length < 2) continue;
        canvas.drawLine(line[0], line[1], paint);
      }
      return;
    }
    final size = 26.0;
    canvas.drawLine(
      Offset(crossover.x - size, crossover.y - size),
      Offset(crossover.x + size, crossover.y + size),
      paint,
    );
    canvas.drawLine(
      Offset(crossover.x - size, crossover.y + size),
      Offset(crossover.x + size, crossover.y - size),
      paint,
    );
  }

  void _drawPlatform(Canvas canvas, String id, Platform platform) {
    if (_isSimulationStyleFor(EditorComponentType.platform, id)) {
      _drawPlatformSimulationStyle(canvas, platform);
      return;
    }
    final paint = Paint()
      ..color = platform.color
      ..style = PaintingStyle.fill;
    final edgePaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 3;

    final rect = Rect.fromLTWH(
      platform.startX,
      platform.y - 16,
      platform.endX - platform.startX,
      32,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      paint,
    );
    canvas.drawLine(
      Offset(platform.startX + 6, platform.y - 10),
      Offset(platform.endX - 6, platform.y - 10),
      edgePaint,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: platform.name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(platform.centerX - textPainter.width / 2, platform.y + 10),
    );
  }

  void _drawPlatformSimulationStyle(Canvas canvas, Platform platform) {
    final paint = Paint()
      ..color = _simPlatformColor
      ..style = PaintingStyle.fill;
    final edgePaint = Paint()
      ..color = _simPlatformEdgeColor
      ..strokeWidth = 3;

    final rect = Rect.fromLTWH(
      platform.startX,
      platform.y - 25,
      platform.endX - platform.startX,
      50,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      paint,
    );
    canvas.drawLine(
      Offset(platform.startX + 6, platform.y - 18),
      Offset(platform.endX - 6, platform.y - 18),
      edgePaint,
    );
  }

  void _drawPoint(Canvas canvas, String id, TrackPoint point) {
    if (_isSimulationStyleFor(EditorComponentType.point, id)) {
      _drawPointSimulationStyle(canvas, point);
      return;
    }
    final basePaint = Paint()
      ..color = point.color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final divergePaint = Paint()
      ..color = point.position == PointPosition.normal
          ? const Color(0xFF457B9D)
          : const Color(0xFFE76F51)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final mainStart = Offset(point.x - 18, point.y);
    final mainEnd = Offset(point.x + 18, point.y);
    final branchOffsets = _branchOffsets(point.orientation);
    final branchEnd =
        Offset(point.x + branchOffsets.dx, point.y + branchOffsets.dy);
    final branchStart = Offset(
      point.x + (branchOffsets.dx >= 0 ? -6 : 6),
      point.y,
    );

    canvas.drawLine(mainStart, mainEnd, basePaint);
    canvas.drawLine(branchStart, branchEnd, divergePaint);

    final t = pointAnimations[point.id] ??
        (point.position == PointPosition.reverse ? 1.0 : 0.0);

    _drawPointGaps(
      canvas,
      t,
      mainStart,
      mainEnd,
      branchStart,
      branchEnd,
      provider.gapLengthForPoint(point),
    );

    switch (point.style) {
      case PointStyle.classic:
        break;
      case PointStyle.blade:
        _drawPointBlade(canvas, t, mainStart, mainEnd, branchStart, branchEnd);
        break;
      case PointStyle.chevron:
        _drawPointChevron(canvas, t, mainStart, mainEnd, branchStart, branchEnd);
        break;
      case PointStyle.wedge:
        _drawPointWedge(canvas, t, mainStart, mainEnd, branchStart, branchEnd);
        break;
      case PointStyle.indicator:
        _drawPointIndicator(canvas, t, mainStart, mainEnd, branchStart, branchEnd);
        break;
      case PointStyle.bridge:
        _drawPointBridge(canvas, t, mainStart, mainEnd, branchStart, branchEnd);
        break;
      case PointStyle.terminalGap:
        _drawTerminalGap(
            canvas, t, mainStart, mainEnd, branchStart, branchEnd, point.orientation);
        break;
    }

    canvas.drawCircle(Offset(point.x - 4, point.y), 5,
        Paint()..color = const Color(0xFF264653));
  }

  void _drawPointSimulationStyle(Canvas canvas, TrackPoint point) {
    final mainStart = Offset(point.x - 18, point.y);
    final mainEnd = Offset(point.x + 18, point.y);
    final branchOffsets = _branchOffsets(point.orientation);
    final branchEnd =
        Offset(point.x + branchOffsets.dx, point.y + branchOffsets.dy);
    final branchStart = Offset(
      point.x + (branchOffsets.dx >= 0 ? -6 : 6),
      point.y,
    );
    final t = pointAnimations[point.id] ??
        (point.position == PointPosition.reverse ? 1.0 : 0.0);
    _drawPointGaps(
      canvas,
      t,
      mainStart,
      mainEnd,
      branchStart,
      branchEnd,
      provider.gapLengthForPoint(point),
    );
    final paint = Paint()
      ..color = point.position == PointPosition.normal
          ? _simSignalGreen
          : _simSignalRed
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(point.x, point.y), 8, paint);
  }

  void _drawSignal(Canvas canvas, String id, Signal signal) {
    if (_isSimulationStyleFor(EditorComponentType.signal, id)) {
      _drawSignalSimulationStyle(canvas, signal);
      return;
    }
    final polePaint = Paint()
      ..color = const Color(0xFF1D3557)
      ..strokeWidth = 4;
    final headPaint = Paint()
      ..color = signal.color
      ..style = PaintingStyle.fill;

    canvas.drawLine(Offset(signal.x, signal.y),
        Offset(signal.x, signal.y - 40), polePaint);

    final pointerWest = signal.direction == SignalDirection.west;
    final path = Path();
    if (pointerWest) {
      path
        ..moveTo(signal.x + 15, signal.y - 55)
        ..lineTo(signal.x - 15, signal.y - 55)
        ..lineTo(signal.x - 25, signal.y - 42.5)
        ..lineTo(signal.x - 15, signal.y - 30)
        ..lineTo(signal.x + 15, signal.y - 30)
        ..close();
    } else {
      path
        ..moveTo(signal.x - 15, signal.y - 55)
        ..lineTo(signal.x + 15, signal.y - 55)
        ..lineTo(signal.x + 25, signal.y - 42.5)
        ..lineTo(signal.x + 15, signal.y - 30)
        ..lineTo(signal.x - 15, signal.y - 30)
        ..close();
    }

    canvas.drawPath(path, headPaint);

    final lightColor = _signalColor(signal.aspect);
    final lightPaint = Paint()
      ..color = lightColor
      ..style = PaintingStyle.fill;

    final lightCenter = Offset(signal.x, signal.y - 42.5);
    canvas.drawCircle(lightCenter, 6, lightPaint);

    if (signal.aspect == SignalAspect.green ||
        signal.aspect == SignalAspect.blue ||
        signal.aspect == SignalAspect.yellow) {
      final glowPaint = Paint()
        ..color = lightColor.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(lightCenter, 12, glowPaint);
    }
  }

  void _drawSignalSimulationStyle(Canvas canvas, Signal signal) {
    final polePaint = Paint()
      ..color = _simSignalPoleColor
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(signal.x, signal.y),
      Offset(signal.x, signal.y - 40),
      polePaint,
    );

    Color lightColor = _simSignalRed;
    switch (signal.aspect) {
      case SignalAspect.green:
        lightColor = _simSignalGreen;
        break;
      case SignalAspect.yellow:
        lightColor = _simSignalYellow;
        break;
      case SignalAspect.blue:
        lightColor = _simSignalGreen;
        break;
      case SignalAspect.red:
        lightColor = _simSignalRed;
        break;
    }

    final lightPaint = Paint()
      ..color = lightColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(signal.x, signal.y - 50), 6, lightPaint);
  }

  void _drawTrainStop(Canvas canvas, String id, TrainStop stop) {
    if (_isSimulationStyleFor(EditorComponentType.trainStop, id)) {
      final paint = Paint()
        ..color = Colors.orange
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.square;
      canvas.drawLine(
        Offset(stop.x, stop.y - 12),
        Offset(stop.x, stop.y + 12),
        paint,
      );
      canvas.drawLine(
        Offset(stop.x - 10, stop.y - 12),
        Offset(stop.x + 10, stop.y - 12),
        paint,
      );
      return;
    }
    final paint = Paint()..color = stop.color;
    final rect =
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(stop.x, stop.y), width: 28, height: 18), const Radius.circular(6));
    canvas.drawRRect(rect, paint);
    canvas.drawLine(Offset(stop.x - 8, stop.y), Offset(stop.x + 8, stop.y),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2);
  }

  void _drawBufferStop(Canvas canvas, String id, BufferStop stop) {
    if (_isSimulationStyleFor(EditorComponentType.bufferStop, id)) {
      final paint = Paint()..color = Colors.red;
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(stop.x, stop.y),
          width: stop.width,
          height: stop.height,
        ),
        paint,
      );
      return;
    }
    final paint = Paint()..color = stop.color;
    final rect = Rect.fromCenter(
      center: Offset(stop.x, stop.y),
      width: stop.width,
      height: stop.height,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      paint,
    );
    final stripePaint = Paint()
      ..color = const Color(0xFFFFD166)
      ..strokeWidth = 2;
    for (double x = rect.left + 4; x < rect.right; x += 6) {
      canvas.drawLine(Offset(x, rect.top + 2), Offset(x + 3, rect.bottom - 2), stripePaint);
    }
  }

  void _drawAxleCounter(Canvas canvas, String id, AxleCounter counter) {
    if (_isSimulationStyleFor(EditorComponentType.axleCounter, id)) {
      final paint = Paint()..color = Colors.blue;
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(counter.x, counter.y),
          width: 12,
          height: 12,
        ),
        paint,
      );
      return;
    }
    final paint = Paint()..color = counter.color;
    canvas.drawCircle(Offset(counter.x - 8, counter.y), 8, paint);
    canvas.drawCircle(Offset(counter.x + 8, counter.y), 8, paint);
    canvas.drawLine(
      Offset(counter.x - 2, counter.y),
      Offset(counter.x + 2, counter.y),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2,
    );
  }

  void _drawTransponder(Canvas canvas, String id, Transponder transponder) {
    if (_isSimulationStyleFor(EditorComponentType.transponder, id)) {
      final paint = Paint()..color = _simSignalYellow;
      final path = Path()
        ..moveTo(transponder.x, transponder.y - 6)
        ..lineTo(transponder.x + 6, transponder.y)
        ..lineTo(transponder.x, transponder.y + 6)
        ..lineTo(transponder.x - 6, transponder.y)
        ..close();
      canvas.drawPath(path, paint);
      return;
    }
    final paint = Paint()..color = transponder.color;
    canvas.save();
    canvas.translate(transponder.x, transponder.y);
    canvas.rotate(math.pi / 4);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: 20, height: 20),
      paint,
    );
    canvas.restore();
  }

  void _drawWifi(Canvas canvas, String id, WifiAntenna wifi) {
    if (_isSimulationStyleFor(EditorComponentType.wifiAntenna, id)) {
      final paint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(Offset(wifi.x, wifi.y), 10, paint);
      return;
    }
    final paint = Paint()
      ..color = wifi.isActive ? wifi.color : wifi.color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final center = Offset(wifi.x, wifi.y);
    canvas.drawCircle(center, 3, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;
    canvas.drawArc(Rect.fromCircle(center: center, radius: 12), -math.pi * 0.75,
        math.pi * 1.5, false, paint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: 20), -math.pi * 0.75,
        math.pi * 1.5, false, paint);
  }

  void _drawText(Canvas canvas, String id, TextAnnotation text) {
    final useSim = _isSimulationStyleFor(EditorComponentType.textAnnotation, id);
    final background = Paint()
      ..color = useSim ? _simCanvasBackground : const Color(0xFFFFF3B0)
      ..style = PaintingStyle.fill;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(text.x, text.y), width: 140, height: 36),
      Radius.circular(useSim ? 4 : 8),
    );
    canvas.drawRRect(rect, background);
    if (!useSim) {
      canvas.drawRRect(
        rect,
        Paint()
          ..color = const Color(0xFFB08968)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: text.text,
        style: TextStyle(
          color: text.color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    );
    textPainter.layout(maxWidth: 120);
    textPainter.paint(
      canvas,
      Offset(text.x - textPainter.width / 2, text.y - textPainter.height / 2),
    );
  }

  void _drawGuidewayDirections(Canvas canvas) {
    for (final segment in provider.segments.values) {
      final start = Offset(segment.startX, segment.startY);
      final end = segment.endPoint();
      final center = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
      final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
      final dir = segment.guidewayDirection;
      final color = dir == GuidewayDirection.gd1
          ? const Color(0xFF2D6A4F)
          : const Color(0xFF9B2226);
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      const arrowLength = 26.0;
      final vector =
          Offset(math.cos(angle), math.sin(angle)) * arrowLength;
      final arrowStart = center - vector / 2;
      final arrowEnd = center + vector / 2;

      canvas.drawLine(arrowStart, arrowEnd, paint);
      final headSize = 6.0;
      final left = Offset(
        arrowEnd.dx - headSize * math.cos(angle - math.pi / 6),
        arrowEnd.dy - headSize * math.sin(angle - math.pi / 6),
      );
      final right = Offset(
        arrowEnd.dx - headSize * math.cos(angle + math.pi / 6),
        arrowEnd.dy - headSize * math.sin(angle + math.pi / 6),
      );
      canvas.drawLine(arrowEnd, left, paint);
      canvas.drawLine(arrowEnd, right, paint);

      final label = dir == GuidewayDirection.gd1 ? 'GD 1' : 'GD 0';
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(center.dx - textPainter.width / 2, center.dy + 10),
      );
    }
  }

  void _drawAlphaGammaMarkers(Canvas canvas) {
    for (final entry in provider.alphaGammaJunctions.entries) {
      final pos = entry.value;
      final paint = Paint()
        ..color = const Color(0xFF1D3557)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(pos, 10, paint);
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'α/γ',
          style: TextStyle(
            color: Color(0xFF1D3557),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
      );
    }
  }

  void _drawCompass(Canvas canvas, Size size) {
    const padding = 16.0;
    const radius = 28.0;
    final center = Offset(size.width - padding - radius, padding + radius);

    final ringPaint = Paint()
      ..color = const Color(0xFF1D3557)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final fillPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, fillPaint);
    canvas.drawCircle(center, radius, ringPaint);

    final directions = <String, Offset>{
      'N': Offset(0, -1),
      'E': Offset(1, 0),
      'S': Offset(0, 1),
      'W': Offset(-1, 0),
    };

    for (final entry in directions.entries) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: entry.key,
          style: const TextStyle(
            color: Color(0xFF1D3557),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final pos = center + entry.value * (radius - 10);
      textPainter.paint(
        canvas,
        Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
      );
    }

    final arrowPaint = Paint()
      ..color = const Color(0xFFE63946)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final arrowStart = center + const Offset(0, 6);
    final arrowEnd = center + const Offset(0, -12);
    canvas.drawLine(arrowStart, arrowEnd, arrowPaint);
    canvas.drawLine(
        arrowEnd, arrowEnd + const Offset(-4, 6), arrowPaint);
    canvas.drawLine(
        arrowEnd, arrowEnd + const Offset(4, 6), arrowPaint);
  }

  void _drawSelection(Canvas canvas) {
    if (provider.selection.isEmpty) return;

    final paint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final showHandles = provider.selection.length == 1;
    for (final selected in provider.selection) {
      switch (selected.type) {
        case EditorComponentType.trackSegment:
          final segment = provider.segments[selected.id];
          if (segment == null) continue;
          final start = Offset(segment.startX, segment.startY);
          final end = segment.endPoint();
          final rect = Rect.fromPoints(start, end).inflate(14);
          canvas.drawRect(rect, paint);
          if (showHandles) {
            _drawHandle(canvas, start);
            _drawHandle(canvas, end);
          }
          break;
        case EditorComponentType.platform:
          final platform = provider.platforms[selected.id];
          if (platform == null) continue;
          final rect = Rect.fromLTWH(
            math.min(platform.startX, platform.endX) - 10,
            platform.y - 24,
            (platform.endX - platform.startX).abs() + 20,
            48,
          );
          canvas.drawRect(rect, paint);
          if (showHandles) {
            _drawHandle(canvas, Offset(platform.startX, platform.y));
            _drawHandle(canvas, Offset(platform.endX, platform.y));
          }
          break;
        case EditorComponentType.signal:
          final signal = provider.signals[selected.id];
          if (signal == null) continue;
          canvas.drawCircle(Offset(signal.x, signal.y - 20), 18, paint);
          break;
        case EditorComponentType.point:
          final point = provider.points[selected.id];
          if (point == null) continue;
          canvas.drawCircle(Offset(point.x, point.y), 18, paint);
          break;
        case EditorComponentType.crossover:
          final xo = provider.crossovers[selected.id];
          if (xo == null) continue;
          canvas.drawCircle(Offset(xo.x, xo.y), 20, paint);
          break;
        case EditorComponentType.trainStop:
          final stop = provider.trainStops[selected.id];
          if (stop == null) continue;
          canvas.drawRect(
              Rect.fromCenter(center: Offset(stop.x, stop.y), width: 28, height: 20),
              paint);
          break;
        case EditorComponentType.bufferStop:
          final stop = provider.bufferStops[selected.id];
          if (stop == null) continue;
          canvas.drawRect(
              Rect.fromCenter(center: Offset(stop.x, stop.y), width: stop.width + 8, height: stop.height + 8),
              paint);
          break;
        case EditorComponentType.axleCounter:
          final counter = provider.axleCounters[selected.id];
          if (counter == null) continue;
          canvas.drawCircle(Offset(counter.x, counter.y), 18, paint);
          break;
        case EditorComponentType.transponder:
          final transponder = provider.transponders[selected.id];
          if (transponder == null) continue;
          canvas.drawCircle(Offset(transponder.x, transponder.y), 18, paint);
          break;
        case EditorComponentType.wifiAntenna:
          final wifi = provider.wifiAntennas[selected.id];
          if (wifi == null) continue;
          canvas.drawCircle(Offset(wifi.x, wifi.y), 22, paint);
          break;
        case EditorComponentType.textAnnotation:
          final text = provider.textAnnotations[selected.id];
          if (text == null) continue;
          canvas.drawRect(
              Rect.fromCenter(center: Offset(text.x, text.y), width: 150, height: 40),
              paint);
          break;
      }
    }
  }

  void _drawHandle(Canvas canvas, Offset center) {
    final rect = Rect.fromCenter(center: center, width: 10, height: 10);
    canvas.drawRect(
      rect,
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.cyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  Color _signalColor(SignalAspect aspect) {
    switch (aspect) {
      case SignalAspect.red:
        return const Color(0xFFE63946);
      case SignalAspect.green:
        return const Color(0xFF2ECC71);
      case SignalAspect.yellow:
        return const Color(0xFFF4D35E);
      case SignalAspect.blue:
        return const Color(0xFF3A86FF);
    }
  }

  Offset _normalVector(double angleDeg) {
    final radians = angleDeg * math.pi / 180.0;
    return Offset(-math.sin(radians), math.cos(radians));
  }

  void _drawStyledTrackLine(
    Canvas canvas,
    Offset start,
    Offset end,
    TrackStyle style,
    Color accent,
  ) {
    final length = (end - start).distance;
    if (length <= 0.1) return;
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx) * 180 / math.pi;
    final normal = _normalVector(angle);
    final config = _styleConfig(style);
    final baseColor = _styleBaseColor(style, accent);
    final railColor = _styleRailColor(style);

    if (config.shadowOffset != 0) {
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..strokeWidth = config.baseWidth
        ..strokeCap = StrokeCap.round;
      final shadowOffset = normal * config.shadowOffset;
      canvas.drawLine(start + shadowOffset, end + shadowOffset, shadowPaint);
    }

    final basePaint = Paint()
      ..color = baseColor
      ..strokeWidth = config.baseWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, basePaint);

    final railPaint = Paint()
      ..color = railColor
      ..strokeWidth = config.railWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
        start + normal * config.railSpacing,
        end + normal * config.railSpacing,
        railPaint);
    canvas.drawLine(
        start - normal * config.railSpacing,
        end - normal * config.railSpacing,
        railPaint);

    if (config.guardRailSpacing != null) {
      final guardPaint = Paint()
        ..color = railColor.withOpacity(0.7)
        ..strokeWidth = config.railWidth * 0.8
        ..strokeCap = StrokeCap.round;
      final guardOffset = config.guardRailSpacing!;
      canvas.drawLine(
          start + normal * guardOffset,
          end + normal * guardOffset,
          guardPaint);
      canvas.drawLine(
          start - normal * guardOffset,
          end - normal * guardOffset,
          guardPaint);
    }

    if (config.centerLine) {
      final centerPaint = Paint()
        ..color = railColor.withOpacity(0.5)
        ..strokeWidth = config.railWidth * 0.8
        ..strokeCap = StrokeCap.round;
      _drawDashes(canvas, start, end, centerPaint,
          dashLength: 12, gapLength: 10);
    }

    if (config.showSleepers) {
      final sleeperPaint = Paint()
        ..color = config.sleeperColor
        ..strokeWidth = config.sleeperWidth
        ..strokeCap = StrokeCap.round;
      _drawSleepers(
        canvas,
        start,
        end,
        config.sleeperSpacing,
        config.sleeperLength,
        sleeperPaint,
      );
    }

    if (config.addGravelDots) {
      final dotPaint = Paint()
        ..color = baseColor.withOpacity(0.35)
        ..style = PaintingStyle.fill;
      _drawGravelDots(canvas, start, end, dotPaint);
    }
  }

  _TrackStyleConfig _styleConfig(TrackStyle style) {
    switch (style) {
      case TrackStyle.ballast:
        return const _TrackStyleConfig(
          baseWidth: 8,
          railSpacing: 6,
          railWidth: 2.2,
          showSleepers: true,
          sleeperSpacing: 18,
          sleeperLength: 14,
          sleeperWidth: 4,
          sleeperColor: Color(0xFF5D534A),
          shadowOffset: 0,
          guardRailSpacing: null,
          centerLine: false,
          addGravelDots: false,
        );
      case TrackStyle.slab:
        return const _TrackStyleConfig(
          baseWidth: 12,
          railSpacing: 6,
          railWidth: 2.5,
          showSleepers: false,
          sleeperSpacing: 0,
          sleeperLength: 0,
          sleeperWidth: 0,
          sleeperColor: Color(0xFF000000),
          shadowOffset: 0,
          guardRailSpacing: null,
          centerLine: true,
          addGravelDots: false,
        );
      case TrackStyle.gravel:
        return const _TrackStyleConfig(
          baseWidth: 9,
          railSpacing: 6,
          railWidth: 2.0,
          showSleepers: true,
          sleeperSpacing: 22,
          sleeperLength: 12,
          sleeperWidth: 3,
          sleeperColor: Color(0xFF6B5B4A),
          shadowOffset: 0,
          guardRailSpacing: null,
          centerLine: false,
          addGravelDots: true,
        );
      case TrackStyle.bridge:
        return const _TrackStyleConfig(
          baseWidth: 7,
          railSpacing: 6,
          railWidth: 2.2,
          showSleepers: true,
          sleeperSpacing: 26,
          sleeperLength: 18,
          sleeperWidth: 3.5,
          sleeperColor: Color(0xFF3E4C59),
          shadowOffset: 3,
          guardRailSpacing: 10,
          centerLine: false,
          addGravelDots: false,
        );
      case TrackStyle.tunnel:
        return const _TrackStyleConfig(
          baseWidth: 12,
          railSpacing: 5.5,
          railWidth: 2.2,
          showSleepers: false,
          sleeperSpacing: 0,
          sleeperLength: 0,
          sleeperWidth: 0,
          sleeperColor: Color(0xFF000000),
          shadowOffset: 0,
          guardRailSpacing: null,
          centerLine: true,
          addGravelDots: false,
        );
      case TrackStyle.yard:
        return const _TrackStyleConfig(
          baseWidth: 6,
          railSpacing: 5,
          railWidth: 2.0,
          showSleepers: true,
          sleeperSpacing: 14,
          sleeperLength: 10,
          sleeperWidth: 3,
          sleeperColor: Color(0xFF4E4A45),
          shadowOffset: 0,
          guardRailSpacing: null,
          centerLine: false,
          addGravelDots: false,
        );
      case TrackStyle.service:
        return const _TrackStyleConfig(
          baseWidth: 6,
          railSpacing: 4.5,
          railWidth: 1.8,
          showSleepers: false,
          sleeperSpacing: 0,
          sleeperLength: 0,
          sleeperWidth: 0,
          sleeperColor: Color(0xFF000000),
          shadowOffset: 0,
          guardRailSpacing: null,
          centerLine: true,
          addGravelDots: false,
        );
      case TrackStyle.elevated:
        return const _TrackStyleConfig(
          baseWidth: 9,
          railSpacing: 6,
          railWidth: 2.2,
          showSleepers: true,
          sleeperSpacing: 20,
          sleeperLength: 14,
          sleeperWidth: 3,
          sleeperColor: Color(0xFF5C6B73),
          shadowOffset: 4,
          guardRailSpacing: 11,
          centerLine: false,
          addGravelDots: false,
        );
      case TrackStyle.industrial:
        return const _TrackStyleConfig(
          baseWidth: 10,
          railSpacing: 6,
          railWidth: 2.4,
          showSleepers: true,
          sleeperSpacing: 16,
          sleeperLength: 8,
          sleeperWidth: 5,
          sleeperColor: Color(0xFF6D4C41),
          shadowOffset: 0,
          guardRailSpacing: null,
          centerLine: false,
          addGravelDots: false,
        );
      case TrackStyle.metro:
        return const _TrackStyleConfig(
          baseWidth: 11,
          railSpacing: 5.5,
          railWidth: 2.2,
          showSleepers: false,
          sleeperSpacing: 0,
          sleeperLength: 0,
          sleeperWidth: 0,
          sleeperColor: Color(0xFF000000),
          shadowOffset: 0,
          guardRailSpacing: null,
          centerLine: true,
          addGravelDots: false,
        );
    }
  }

  Color _styleBaseColor(TrackStyle style, Color accent) {
    Color blend(Color base, {double amount = 0.35}) {
      return Color.lerp(base, accent, amount) ?? base;
    }
    switch (style) {
      case TrackStyle.ballast:
        return accent;
      case TrackStyle.slab:
        return blend(const Color(0xFFB0BEC5), amount: 0.2);
      case TrackStyle.gravel:
        return blend(const Color(0xFF8D6E63), amount: 0.25);
      case TrackStyle.bridge:
        return blend(const Color(0xFF37474F), amount: 0.2);
      case TrackStyle.tunnel:
        return blend(const Color(0xFF263238), amount: 0.2);
      case TrackStyle.yard:
        return accent.withOpacity(0.85);
      case TrackStyle.service:
        return blend(const Color(0xFF9E9E9E), amount: 0.2);
      case TrackStyle.elevated:
        return accent.withOpacity(0.95);
      case TrackStyle.industrial:
        return blend(const Color(0xFF6D6D6D), amount: 0.25);
      case TrackStyle.metro:
        return blend(const Color(0xFF455A64), amount: 0.25);
    }
  }

  Color _styleRailColor(TrackStyle style) {
    switch (style) {
      case TrackStyle.tunnel:
        return const Color(0xFFB0BEC5);
      case TrackStyle.metro:
        return const Color(0xFF90CAF9);
      case TrackStyle.industrial:
        return const Color(0xFFE0E0E0);
      default:
        return Colors.white.withOpacity(0.9);
    }
  }

  void _drawSleepers(
    Canvas canvas,
    Offset start,
    Offset end,
    double spacing,
    double length,
    Paint paint,
  ) {
    final total = (end - start).distance;
    if (spacing <= 0 || total <= 0) return;
    final direction = (end - start) / total;
    final normal = Offset(-direction.dy, direction.dx);
    for (double t = 0; t <= total; t += spacing) {
      final center = start + direction * t;
      canvas.drawLine(
        center - normal * (length / 2),
        center + normal * (length / 2),
        paint,
      );
    }
  }

  void _drawDashes(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    required double dashLength,
    required double gapLength,
  }) {
    final total = (end - start).distance;
    if (total <= 0) return;
    final direction = (end - start) / total;
    double t = 0;
    while (t < total) {
      final startDash = start + direction * t;
      final endDash = start + direction * math.min(t + dashLength, total);
      canvas.drawLine(startDash, endDash, paint);
      t += dashLength + gapLength;
    }
  }

  void _drawGravelDots(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    final total = (end - start).distance;
    if (total <= 0) return;
    final direction = (end - start) / total;
    final normal = Offset(-direction.dy, direction.dx);
    for (double t = 0; t <= total; t += 14) {
      final center = start + direction * t;
      canvas.drawCircle(center + normal * 2.5, 1.4, paint);
      canvas.drawCircle(center - normal * 2.5, 1.1, paint);
    }
  }

  void _drawPointGaps(
    Canvas canvas,
    double t,
    Offset mainStart,
    Offset mainEnd,
    Offset branchStart,
    Offset branchEnd,
    double gapLength,
  ) {
    final mainGap = gapLength * t;
    final branchGap = gapLength * (1 - t);
    final mainDir = (mainEnd - mainStart);
    final mainLen = mainDir.distance;
    final branchRight = branchEnd.dx >= branchStart.dx;
    if (mainLen > 0 && mainGap > 0.2) {
      final unit = mainDir / mainLen;
      final gapStart = Offset(
        (mainStart.dx + mainEnd.dx) / 2 + (branchRight ? 2 : -2),
        mainStart.dy,
      );
      final gapEnd = gapStart + unit * (branchRight ? mainGap : -mainGap);
      _eraseLineSegment(canvas, gapStart, gapEnd, 7);
    }

    final branchDir = (branchEnd - branchStart);
    final branchLen = branchDir.distance;
    if (branchLen > 0 && branchGap > 0.2) {
      final unit = branchDir / branchLen;
      final gapStart = branchStart;
      final gapEnd = gapStart + unit * branchGap;
      _eraseLineSegment(canvas, gapStart, gapEnd, 7);
    }
  }

  void _drawPointBlade(
    Canvas canvas,
    double t,
    Offset mainStart,
    Offset mainEnd,
    Offset branchStart,
    Offset branchEnd,
  ) {
    final target = Offset.lerp(mainEnd, branchEnd, t) ?? mainEnd;
    final base = branchStart;
    final paint = Paint()
      ..color = const Color(0xFF1D3557)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(base, target, paint);
  }

  void _drawPointChevron(
    Canvas canvas,
    double t,
    Offset mainStart,
    Offset mainEnd,
    Offset branchStart,
    Offset branchEnd,
  ) {
    final base = branchStart;
    final target = Offset.lerp(mainEnd, branchEnd, t) ?? mainEnd;
    final dir = (target - base);
    final len = dir.distance;
    if (len == 0) return;
    final unit = dir / len;
    final normal = Offset(-unit.dy, unit.dx);
    final tip = base + unit * 18;
    final left = tip - unit * 6 + normal * 6;
    final right = tip - unit * 6 - normal * 6;
    final paint = Paint()
      ..color = const Color(0xFF264653)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawLine(left, tip, paint);
    canvas.drawLine(right, tip, paint);
  }

  void _drawPointWedge(
    Canvas canvas,
    double t,
    Offset mainStart,
    Offset mainEnd,
    Offset branchStart,
    Offset branchEnd,
  ) {
    final base = branchStart;
    final target = Offset.lerp(mainEnd, branchEnd, t) ?? mainEnd;
    final dir = (target - base);
    final len = dir.distance;
    if (len == 0) return;
    final unit = dir / len;
    final normal = Offset(-unit.dy, unit.dx);
    final tip = base + unit * 16;
    final left = base + normal * 6;
    final right = base - normal * 6;
    final path = Path()
      ..moveTo(left.dx, left.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    final paint = Paint()
      ..color = const Color(0xFF457B9D)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  void _drawPointIndicator(
    Canvas canvas,
    double t,
    Offset mainStart,
    Offset mainEnd,
    Offset branchStart,
    Offset branchEnd,
  ) {
    final mainPos = Offset.lerp(mainStart, mainEnd, 0.6) ?? mainEnd;
    final branchPos = Offset.lerp(branchStart, branchEnd, 0.6) ?? branchEnd;
    final active = Offset.lerp(mainPos, branchPos, t) ?? mainPos;
    final inactive = t < 0.5 ? branchPos : mainPos;

    final activePaint = Paint()..color = const Color(0xFF2A9D8F);
    final inactivePaint = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(active, 5, activePaint);
    canvas.drawCircle(inactive, 5, inactivePaint);
  }

  void _drawPointBridge(
    Canvas canvas,
    double t,
    Offset mainStart,
    Offset mainEnd,
    Offset branchStart,
    Offset branchEnd,
  ) {
    final activeEnd = Offset.lerp(mainEnd, branchEnd, t) ?? mainEnd;
    final base = branchStart;
    final dir = (activeEnd - base);
    final len = dir.distance;
    if (len == 0) return;
    final unit = dir / len;
    final bridgeStart = base + unit * 2;
    final bridgeEnd = base + unit * 16;
    final paint = Paint()
      ..color = const Color(0xFF1B4965)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(bridgeStart, bridgeEnd, paint);
  }

  void _drawTerminalGap(
    Canvas canvas,
    double t,
    Offset mainStart,
    Offset mainEnd,
    Offset branchStart,
    Offset branchEnd,
    PointOrientation orientation,
  ) {
    final bool reverse = t >= 0.5;
    final gapPaint = Paint()
      ..color = const Color(0xFFF7F7F7)
      ..style = PaintingStyle.fill;

    final mainDir = (mainEnd - mainStart);
    final mainLen = mainDir.distance;
    if (mainLen == 0) return;
    final mainUnit = mainDir / mainLen;
    final mainNormal = Offset(-mainUnit.dy, mainUnit.dx);

    final branchDir = (branchEnd - branchStart);
    final branchLen = branchDir.distance;
    final branchUnit = branchLen == 0 ? Offset.zero : branchDir / branchLen;
    final branchNormal = Offset(-branchUnit.dy, branchUnit.dx);

    if (reverse) {
      // Reverse: cover straight track on converging side.
      final rectCenter = mainStart + mainDir * 0.15;
      final rect = Rect.fromCenter(
        center: rectCenter,
        width: 50,
        height: 12,
      );
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      final angle = math.atan2(mainUnit.dy, mainUnit.dx);
      canvas.rotate(angle);
      canvas.translate(-rect.center.dx, -rect.center.dy);
      canvas.drawRect(rect, gapPaint);
      canvas.restore();
    } else {
      // Normal: cover diverging branch (diagonal) with a wedge.
      final start = branchStart + branchUnit * 2;
      final path = Path()
        ..moveTo(start.dx + branchNormal.dx * -6,
            start.dy + branchNormal.dy * -6)
        ..lineTo(start.dx + branchUnit.dx * 50 + branchNormal.dx * -6,
            start.dy + branchUnit.dy * 50 + branchNormal.dy * -6)
        ..lineTo(start.dx + branchUnit.dx * 50 + branchNormal.dx * 6,
            start.dy + branchUnit.dy * 50 + branchNormal.dy * 6)
        ..lineTo(start.dx + branchNormal.dx * 6,
            start.dy + branchNormal.dy * 6)
        ..close();
      canvas.drawPath(path, gapPaint);
    }
  }

  Offset _branchOffsets(PointOrientation orientation) {
    switch (orientation) {
      case PointOrientation.upLeft:
        return const Offset(-18, -16);
      case PointOrientation.upRight:
        return const Offset(18, -16);
      case PointOrientation.downLeft:
        return const Offset(-18, 16);
      case PointOrientation.downRight:
        return const Offset(18, 16);
    }
  }

  void _eraseLineSegment(
    Canvas canvas,
    Offset start,
    Offset end,
    double width,
  ) {
    final bounds = Rect.fromPoints(start, end).inflate(width);
    canvas.saveLayer(bounds, Paint());
    final clearPaint = Paint()
      ..blendMode = BlendMode.clear
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, clearPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TerminalEditorPainter oldDelegate) {
    return oldDelegate.provider != provider ||
        oldDelegate.pointAnimations != pointAnimations;
  }
}

class _TrackStyleConfig {
  final double baseWidth;
  final double railSpacing;
  final double railWidth;
  final bool showSleepers;
  final double sleeperSpacing;
  final double sleeperLength;
  final double sleeperWidth;
  final Color sleeperColor;
  final double shadowOffset;
  final double? guardRailSpacing;
  final bool centerLine;
  final bool addGravelDots;

  const _TrackStyleConfig({
    required this.baseWidth,
    required this.railSpacing,
    required this.railWidth,
    required this.showSleepers,
    required this.sleeperSpacing,
    required this.sleeperLength,
    required this.sleeperWidth,
    required this.sleeperColor,
    required this.shadowOffset,
    required this.guardRailSpacing,
    required this.centerLine,
    required this.addGravelDots,
  });
}
