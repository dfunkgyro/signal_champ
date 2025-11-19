import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/terminal_station_controller.dart';

/// Mini map widget for quick navigation around the railway canvas
class MiniMapWidget extends StatelessWidget {
  final double canvasWidth;
  final double canvasHeight;
  final double cameraOffsetX;
  final double cameraOffsetY;
  final double cameraZoom;
  final Function(double x, double y) onNavigate;

  const MiniMapWidget({
    Key? key,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.cameraOffsetX,
    required this.cameraOffsetY,
    required this.cameraZoom,
    required this.onNavigate,
  }) : super(key: key);

  /// Handle tap on minimap with improved accuracy
  void _handleTap(TapDownDetails details, BuildContext context) {
    try {
      final RenderBox box = context.findRenderObject() as RenderBox;
      final localPosition = box.globalToLocal(details.globalPosition);

      // Constants for minimap dimensions
      const mapWidth = 280.0;
      const mapHeight = 140.0;
      const headerHeight = 40.0;
      const margin = 8.0;

      // Adjust for header, margin and padding
      final adjustedX = localPosition.dx - margin;
      final adjustedY = localPosition.dy - headerHeight - margin;

      // Validate click is within map bounds
      if (adjustedX >= 0 && adjustedX <= mapWidth &&
          adjustedY >= 0 && adjustedY <= mapHeight) {
        // Calculate ratios with bounds checking
        final xRatio = (adjustedX / mapWidth).clamp(0.0, 1.0);
        final yRatio = (adjustedY / mapHeight).clamp(0.0, 1.0);

        // Calculate target position on canvas
        final targetX = xRatio * canvasWidth;
        final targetY = yRatio * canvasHeight;

        onNavigate(targetX, targetY);
      }
    } catch (e) {
      // Silently handle tap errors to prevent crashes
      debugPrint('MiniMap tap error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TerminalStationController>(
      builder: (context, controller, _) {
        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Mini Map',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Mini map canvas
              GestureDetector(
                onTapDown: (details) {
                  _handleTap(details, context);
                },
                child: CustomPaint(
                  size: const Size(280, 140),
                  painter: MiniMapPainter(
                    controller: controller,
                    canvasWidth: canvasWidth,
                    canvasHeight: canvasHeight,
                    cameraOffsetX: cameraOffsetX,
                    cameraOffsetY: cameraOffsetY,
                    cameraZoom: cameraZoom,
                  ),
                ),
              ),

              // Legend and Stats
              Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      alignment: WrapAlignment.center,
                      children: [
                        _LegendItem(color: Colors.blue, label: 'Tracks'),
                        _LegendItem(color: Colors.green, label: 'Signals'),
                        _LegendItem(color: Colors.red, label: 'Trains'),
                        _LegendItem(color: Colors.orange, label: 'Points'),
                        _LegendItem(color: Colors.white, label: 'Viewport'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Zoom: ${cameraZoom.toStringAsFixed(1)}x | Trains: ${controller.trains.length}',
                      style: const TextStyle(color: Colors.white60, fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 9),
        ),
      ],
    );
  }
}

class MiniMapPainter extends CustomPainter {
  final TerminalStationController controller;
  final double canvasWidth;
  final double canvasHeight;
  final double cameraOffsetX;
  final double cameraOffsetY;
  final double cameraZoom;

  MiniMapPainter({
    required this.controller,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.cameraOffsetX,
    required this.cameraOffsetY,
    required this.cameraZoom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Validate canvas dimensions to prevent division by zero
    if (canvasWidth <= 0 || canvasHeight <= 0) {
      _drawErrorState(canvas, size, 'Invalid canvas dimensions');
      return;
    }

    final scaleX = size.width / canvasWidth;
    final scaleY = size.height / canvasHeight;

    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.grey[850]!,
    );

    // Draw blocks as rectangles
    for (final block in controller.blocks.values) {
      final x1 = block.startX * scaleX;
      final x2 = block.endX * scaleX;
      final y = block.y * scaleY;

      canvas.drawLine(
        Offset(x1, y),
        Offset(x2, y),
        Paint()
          ..color = block.occupied ? Colors.red.withOpacity(0.8) : Colors.blue.withOpacity(0.5)
          ..strokeWidth = 2,
      );
    }

    // Draw signals
    for (final signal in controller.signals.values) {
      final x = signal.x * scaleX;
      final y = signal.y * scaleY;

      canvas.drawCircle(
        Offset(x, y),
        2,
        Paint()..color = Colors.green,
      );
    }

    // Draw points
    for (final point in controller.points.values) {
      final x = point.x * scaleX;
      final y = point.y * scaleY;

      canvas.drawCircle(
        Offset(x, y),
        2,
        Paint()..color = Colors.orange,
      );
    }

    // Draw trains
    for (final train in controller.trains) {
      final x = train.x * scaleX;
      final y = train.y * scaleY;

      canvas.drawCircle(
        Offset(x, y),
        3,
        Paint()..color = Colors.red,
      );
    }

    // Draw viewport rectangle with validation
    if (cameraZoom > 0) {
      final viewportWidth = size.width / cameraZoom;
      final viewportHeight = size.height / cameraZoom;
      final viewportX = -cameraOffsetX / cameraZoom;
      final viewportY = -cameraOffsetY / cameraZoom;

      canvas.drawRect(
        Rect.fromLTWH(
          viewportX * scaleX,
          viewportY * scaleY,
          viewportWidth * scaleX,
          viewportHeight * scaleY,
        ),
        Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  /// Helper method to draw error state
  void _drawErrorState(Canvas canvas, Size size, String message) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.grey[850]!,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: message,
        style: const TextStyle(color: Colors.red, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: size.width);
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2),
    );
  }

  @override
  bool shouldRepaint(MiniMapPainter oldDelegate) {
    // Only repaint if something actually changed - major performance optimization
    return oldDelegate.cameraOffsetX != cameraOffsetX ||
        oldDelegate.cameraOffsetY != cameraOffsetY ||
        oldDelegate.cameraZoom != cameraZoom ||
        oldDelegate.canvasWidth != canvasWidth ||
        oldDelegate.canvasHeight != canvasHeight ||
        _hasControllerDataChanged(oldDelegate);
  }

  /// Check if controller data has changed (trains, signals, etc.)
  bool _hasControllerDataChanged(MiniMapPainter oldDelegate) {
    // Compare train count and positions
    if (controller.trains.length != oldDelegate.controller.trains.length) {
      return true;
    }

    // Compare block occupancy states
    if (controller.blocks.length != oldDelegate.controller.blocks.length) {
      return true;
    }

    for (final block in controller.blocks.values) {
      final oldBlock = oldDelegate.controller.blocks[block.id];
      if (oldBlock == null || oldBlock.occupied != block.occupied) {
        return true;
      }
    }

    return false;
  }
}
