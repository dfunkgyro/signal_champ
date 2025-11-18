import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../models/scenario_models.dart';

class RouteDesignerCanvas extends StatefulWidget {
  final RailwayScenario scenario;
  final Function(RailwayScenario) onScenarioChanged;
  final double width;
  final double height;

  const RouteDesignerCanvas({
    super.key,
    required this.scenario,
    required this.onScenarioChanged,
    this.width = 7000,
    this.height = 1200,
  });

  @override
  State<RouteDesignerCanvas> createState() => _RouteDesignerCanvasState();
}

class _RouteDesignerCanvasState extends State<RouteDesignerCanvas> {
  double _zoom = 1.0;
  Offset _offset = Offset.zero;
  Offset _lastPanPosition = Offset.zero;

  RailwayElementType? _selectedElementType;
  dynamic _selectedElement;
  Offset? _dragStartPosition;

  // Grid settings
  static const double gridSize = 50.0;
  bool _snapToGrid = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Toolbar
        _buildToolbar(theme),

        // Canvas
        Expanded(
          child: Container(
            color: theme.colorScheme.surface,
            child: GestureDetector(
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              onTapDown: _handleTapDown,
              child: CustomPaint(
                size: Size(widget.width, widget.height),
                painter: RouteDesignerPainter(
                  scenario: widget.scenario,
                  zoom: _zoom,
                  offset: _offset,
                  selectedElement: _selectedElement,
                  showGrid: true,
                  gridSize: gridSize,
                  theme: theme,
                ),
              ),
            ),
          ),
        ),

        // Properties panel
        if (_selectedElement != null) _buildPropertiesPanel(theme),
      ],
    );
  }

  Widget _buildToolbar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: theme.colorScheme.surfaceContainerHighest,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Element type selector
            Text('Add: ', style: theme.textTheme.titleSmall),
            const SizedBox(width: 8),
            ...RailwayElementType.values.map((type) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(type.icon, size: 16),
                        const SizedBox(width: 4),
                        Text(type.displayName),
                      ],
                    ),
                    selected: _selectedElementType == type,
                    onSelected: (selected) {
                      setState(() {
                        _selectedElementType = selected ? type : null;
                        _selectedElement = null;
                      });
                    },
                  ),
                )),

            const SizedBox(width: 16),
            const VerticalDivider(),
            const SizedBox(width: 16),

            // View controls
            IconButton(
              icon: const Icon(Icons.zoom_in),
              tooltip: 'Zoom In',
              onPressed: () {
                setState(() {
                  _zoom = (_zoom * 1.2).clamp(0.5, 3.0);
                });
              },
            ),
            Text('${(_zoom * 100).toStringAsFixed(0)}%'),
            IconButton(
              icon: const Icon(Icons.zoom_out),
              tooltip: 'Zoom Out',
              onPressed: () {
                setState(() {
                  _zoom = (_zoom / 1.2).clamp(0.5, 3.0);
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.center_focus_strong),
              tooltip: 'Reset View',
              onPressed: () {
                setState(() {
                  _zoom = 1.0;
                  _offset = Offset.zero;
                });
              },
            ),

            const SizedBox(width: 16),
            const VerticalDivider(),
            const SizedBox(width: 16),

            // Grid toggle
            FilterChip(
              label: const Text('Snap to Grid'),
              avatar: Icon(_snapToGrid ? Icons.grid_on : Icons.grid_off, size: 16),
              selected: _snapToGrid,
              onSelected: (selected) {
                setState(() {
                  _snapToGrid = selected;
                });
              },
            ),

            const SizedBox(width: 16),

            // Clear selection
            if (_selectedElement != null)
              TextButton.icon(
                icon: const Icon(Icons.clear),
                label: const Text('Clear Selection'),
                onPressed: () {
                  setState(() {
                    _selectedElement = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertiesPanel(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Properties',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Delete Element',
                onPressed: _deleteSelectedElement,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildElementProperties(theme),
        ],
      ),
    );
  }

  Widget _buildElementProperties(ThemeData theme) {
    if (_selectedElement == null) return const SizedBox.shrink();

    if (_selectedElement is ScenarioTrack) {
      final track = _selectedElement as ScenarioTrack;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Track: ${track.id}'),
          Text('Start: (${track.startX.toStringAsFixed(0)}, ${track.startY.toStringAsFixed(0)})'),
          Text('End: (${track.endX.toStringAsFixed(0)}, ${track.endY.toStringAsFixed(0)})'),
        ],
      );
    } else if (_selectedElement is ScenarioSignal) {
      final signal = _selectedElement as ScenarioSignal;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Signal: ${signal.id}'),
          Text('Position: (${signal.x.toStringAsFixed(0)}, ${signal.y.toStringAsFixed(0)})'),
        ],
      );
    } else if (_selectedElement is ScenarioPoint) {
      final point = _selectedElement as ScenarioPoint;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Point: ${point.id}'),
          Text('Position: (${point.x.toStringAsFixed(0)}, ${point.y.toStringAsFixed(0)})'),
        ],
      );
    } else if (_selectedElement is ScenarioBlockSection) {
      final block = _selectedElement as ScenarioBlockSection;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Block: ${block.id}'),
          Text('Start X: ${block.startX.toStringAsFixed(0)}'),
          Text('End X: ${block.endX.toStringAsFixed(0)}'),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _lastPanPosition = details.focalPoint;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount == 1) {
      // Pan
      setState(() {
        _offset += details.focalPoint - _lastPanPosition;
        _lastPanPosition = details.focalPoint;
      });
    } else if (details.pointerCount == 2) {
      // Zoom
      setState(() {
        _zoom = (_zoom * details.scale).clamp(0.5, 3.0);
      });
    }
  }

  void _handleTapDown(TapDownDetails details) {
    final canvasPosition = _screenToCanvas(details.localPosition);

    if (_selectedElementType != null) {
      _addElement(canvasPosition);
    } else {
      _selectElement(canvasPosition);
    }
  }

  Offset _screenToCanvas(Offset screenPosition) {
    return (screenPosition - _offset) / _zoom;
  }

  Offset _snapPosition(Offset position) {
    if (!_snapToGrid) return position;

    return Offset(
      (position.dx / gridSize).round() * gridSize,
      (position.dy / gridSize).round() * gridSize,
    );
  }

  void _addElement(Offset position) {
    final snappedPos = _snapPosition(position);
    final scenario = widget.scenario;

    switch (_selectedElementType) {
      case RailwayElementType.track:
        if (_dragStartPosition == null) {
          _dragStartPosition = snappedPos;
        } else {
          final track = ScenarioTrack(
            id: 'track_${scenario.tracks.length + 1}',
            startX: _dragStartPosition!.dx,
            startY: _dragStartPosition!.dy,
            endX: snappedPos.dx,
            endY: snappedPos.dy,
          );
          widget.onScenarioChanged(
            scenario.copyWith(
              tracks: [...scenario.tracks, track],
            ),
          );
          _dragStartPosition = null;
        }
        break;

      case RailwayElementType.signal:
        final signal = ScenarioSignal(
          id: 'signal_${scenario.signals.length + 1}',
          x: snappedPos.dx,
          y: snappedPos.dy,
          controlledBlocks: [],
          requiredPointPositions: [],
        );
        widget.onScenarioChanged(
          scenario.copyWith(
            signals: [...scenario.signals, signal],
          ),
        );
        break;

      case RailwayElementType.point:
        final point = ScenarioPoint(
          id: 'point_${scenario.points.length + 1}',
          x: snappedPos.dx,
          y: snappedPos.dy,
          normalRoute: '',
          reverseRoute: '',
        );
        widget.onScenarioChanged(
          scenario.copyWith(
            points: [...scenario.points, point],
          ),
        );
        break;

      case RailwayElementType.blockSection:
        if (_dragStartPosition == null) {
          _dragStartPosition = snappedPos;
        } else {
          final block = ScenarioBlockSection(
            id: 'block_${scenario.blockSections.length + 1}',
            startX: _dragStartPosition!.dx,
            endX: snappedPos.dx,
            y: _dragStartPosition!.dy,
          );
          widget.onScenarioChanged(
            scenario.copyWith(
              blockSections: [...scenario.blockSections, block],
            ),
          );
          _dragStartPosition = null;
        }
        break;

      default:
        break;
    }

    setState(() {});
  }

  void _selectElement(Offset position) {
    final scenario = widget.scenario;

    // Check signals (point elements)
    for (final signal in scenario.signals) {
      if ((Offset(signal.x, signal.y) - position).distance < 20) {
        setState(() {
          _selectedElement = signal;
        });
        return;
      }
    }

    // Check points
    for (final point in scenario.points) {
      if ((Offset(point.x, point.y) - position).distance < 20) {
        setState(() {
          _selectedElement = point;
        });
        return;
      }
    }

    // Check tracks (line elements)
    for (final track in scenario.tracks) {
      if (_isPointNearLine(
        position,
        Offset(track.startX, track.startY),
        Offset(track.endX, track.endY),
        threshold: 10,
      )) {
        setState(() {
          _selectedElement = track;
        });
        return;
      }
    }

    // Check block sections
    for (final block in scenario.blockSections) {
      if (position.dx >= block.startX &&
          position.dx <= block.endX &&
          (position.dy - block.y).abs() < 20) {
        setState(() {
          _selectedElement = block;
        });
        return;
      }
    }

    setState(() {
      _selectedElement = null;
    });
  }

  bool _isPointNearLine(Offset point, Offset lineStart, Offset lineEnd,
      {double threshold = 10}) {
    final dx = lineEnd.dx - lineStart.dx;
    final dy = lineEnd.dy - lineStart.dy;
    final length = (Offset(dx, dy)).distance;

    if (length == 0) return false;

    final t = ((point.dx - lineStart.dx) * dx + (point.dy - lineStart.dy) * dy) /
        (length * length);

    if (t < 0 || t > 1) return false;

    final projectionX = lineStart.dx + t * dx;
    final projectionY = lineStart.dy + t * dy;

    return (Offset(point.dx - projectionX, point.dy - projectionY)).distance <=
        threshold;
  }

  void _deleteSelectedElement() {
    if (_selectedElement == null) return;

    final scenario = widget.scenario;

    if (_selectedElement is ScenarioTrack) {
      widget.onScenarioChanged(
        scenario.copyWith(
          tracks: scenario.tracks.where((t) => t != _selectedElement).toList(),
        ),
      );
    } else if (_selectedElement is ScenarioSignal) {
      widget.onScenarioChanged(
        scenario.copyWith(
          signals:
              scenario.signals.where((s) => s != _selectedElement).toList(),
        ),
      );
    } else if (_selectedElement is ScenarioPoint) {
      widget.onScenarioChanged(
        scenario.copyWith(
          points: scenario.points.where((p) => p != _selectedElement).toList(),
        ),
      );
    } else if (_selectedElement is ScenarioBlockSection) {
      widget.onScenarioChanged(
        scenario.copyWith(
          blockSections:
              scenario.blockSections.where((b) => b != _selectedElement).toList(),
        ),
      );
    }

    setState(() {
      _selectedElement = null;
    });
  }
}

class RouteDesignerPainter extends CustomPainter {
  final RailwayScenario scenario;
  final double zoom;
  final Offset offset;
  final dynamic selectedElement;
  final bool showGrid;
  final double gridSize;
  final ThemeData theme;

  RouteDesignerPainter({
    required this.scenario,
    required this.zoom,
    required this.offset,
    this.selectedElement,
    this.showGrid = true,
    this.gridSize = 50.0,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(zoom);

    // Draw grid
    if (showGrid) {
      _drawGrid(canvas, size);
    }

    // Draw tracks
    for (final track in scenario.tracks) {
      _drawTrack(canvas, track);
    }

    // Draw block sections
    for (final block in scenario.blockSections) {
      _drawBlockSection(canvas, block);
    }

    // Draw signals
    for (final signal in scenario.signals) {
      _drawSignal(canvas, signal);
    }

    // Draw points
    for (final point in scenario.points) {
      _drawPoint(canvas, point);
    }

    // Draw train spawns
    for (final spawn in scenario.trainSpawns) {
      _drawTrainSpawn(canvas, spawn);
    }

    canvas.restore();
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.colorScheme.outline.withOpacity(0.2)
      ..strokeWidth = 1;

    final width = size.width / zoom;
    final height = size.height / zoom;

    for (double x = 0; x < width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, height),
        paint,
      );
    }

    for (double y = 0; y < height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(width, y),
        paint,
      );
    }
  }

  void _drawTrack(Canvas canvas, ScenarioTrack track) {
    final paint = Paint()
      ..color = selectedElement == track
          ? theme.colorScheme.primary
          : theme.colorScheme.secondary
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(track.startX, track.startY),
      Offset(track.endX, track.endY),
      paint,
    );
  }

  void _drawBlockSection(Canvas canvas, ScenarioBlockSection block) {
    final paint = Paint()
      ..color = (selectedElement == block
              ? theme.colorScheme.primary
              : theme.colorScheme.tertiary)
          .withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTRB(
      block.startX,
      block.y - 20,
      block.endX,
      block.y + 20,
    );

    canvas.drawRect(rect, paint);

    // Draw border
    final borderPaint = Paint()
      ..color = selectedElement == block
          ? theme.colorScheme.primary
          : theme.colorScheme.tertiary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(rect, borderPaint);
  }

  void _drawSignal(Canvas canvas, ScenarioSignal signal) {
    final paint = Paint()
      ..color = selectedElement == signal
          ? theme.colorScheme.primary
          : Colors.green
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(signal.x, signal.y), 8, paint);

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(Offset(signal.x, signal.y), 8, borderPaint);
  }

  void _drawPoint(Canvas canvas, ScenarioPoint point) {
    final paint = Paint()
      ..color = selectedElement == point
          ? theme.colorScheme.primary
          : Colors.orange
      ..style = PaintingStyle.fill;

    // Draw triangle
    final path = Path()
      ..moveTo(point.x, point.y - 10)
      ..lineTo(point.x - 10, point.y + 10)
      ..lineTo(point.x + 10, point.y + 10)
      ..close();

    canvas.drawPath(path, paint);

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(path, borderPaint);
  }

  void _drawTrainSpawn(Canvas canvas, ScenarioTrainSpawn spawn) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(spawn.x, spawn.y),
        width: 40,
        height: 20,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(RouteDesignerPainter oldDelegate) {
    return oldDelegate.scenario != scenario ||
        oldDelegate.zoom != zoom ||
        oldDelegate.offset != offset ||
        oldDelegate.selectedElement != selectedElement;
  }
}
