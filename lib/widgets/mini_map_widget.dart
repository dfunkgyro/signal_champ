import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/terminal_station_controller.dart';
import '../services/widget_preferences_service.dart';

/// Enhanced Mini map widget with customization and fixed coordinate system
class MiniMapWidgetEnhanced extends StatelessWidget {
  final double canvasWidth;
  final double canvasHeight;
  final double cameraOffsetX;
  final double cameraOffsetY;
  final double cameraZoom;
  final double viewportWidth;  // NEW: Actual viewport width
  final double viewportHeight; // NEW: Actual viewport height
  final Function(double x, double y) onNavigate;

  const MiniMapWidgetEnhanced({
    Key? key,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.cameraOffsetX,
    required this.cameraOffsetY,
    required this.cameraZoom,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.onNavigate,
  }) : super(key: key);

  /// Handle tap on minimap with improved accuracy
  void _handleTap(TapDownDetails details, BuildContext context, double mapWidth, double mapHeight) {
    try {
      final RenderBox box = context.findRenderObject() as RenderBox;
      final localPosition = box.globalToLocal(details.globalPosition);

      const headerHeight = 40.0;
      const margin = 8.0;

      // Adjust for header, margin and padding
      final adjustedX = localPosition.dx - margin;
      final adjustedY = localPosition.dy - headerHeight - margin;

      // Validate click is within map bounds
      if (adjustedX >= 0 && adjustedX <= mapWidth &&
          adjustedY >= 0 && adjustedY <= mapHeight) {

        // FIXED: Convert from minimap coordinates to canvas coordinates
        // Minimap is centered at (mapWidth/2, mapHeight/2), corresponding to canvas (0, 0)
        // Calculate position relative to minimap center
        final minimapCenterX = adjustedX - (mapWidth / 2);
        final minimapCenterY = adjustedY - (mapHeight / 2);

        // Scale to canvas coordinates
        final scaleX = canvasWidth / mapWidth;
        final scaleY = canvasHeight / mapHeight;

        // Calculate target position in canvas coordinates
        final targetCanvasX = minimapCenterX * scaleX;
        final targetCanvasY = minimapCenterY * scaleY;

        // FIXED: Negate to convert canvas position to camera offset
        // Camera offset moves the canvas opposite to viewport
        final targetCameraOffsetX = -targetCanvasX;
        final targetCameraOffsetY = -targetCanvasY;

        // Navigate to this camera offset
        onNavigate(targetCameraOffsetX, targetCameraOffsetY);
      }
    } catch (e) {
      debugPrint('MiniMap tap error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TerminalStationController, WidgetPreferencesService>(
      builder: (context, controller, prefs, _) {
        final mapWidth = prefs.minimapWidth;
        final mapHeight = prefs.minimapHeight;

        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: prefs.minimapBackgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: prefs.minimapBorderColor,
              width: prefs.minimapBorderWidth,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: prefs.minimapHeaderColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
                child: Row(
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
                  _handleTap(details, context, mapWidth, mapHeight);
                },
                child: CustomPaint(
                  size: Size(mapWidth, mapHeight),
                  painter: MiniMapPainterEnhanced(
                    controller: controller,
                    canvasWidth: canvasWidth,
                    canvasHeight: canvasHeight,
                    cameraOffsetX: cameraOffsetX,
                    cameraOffsetY: cameraOffsetY,
                    cameraZoom: cameraZoom,
                    viewportWidth: viewportWidth,
                    viewportHeight: viewportHeight,
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

class MiniMapPainterEnhanced extends CustomPainter {
  final TerminalStationController controller;
  final double canvasWidth;
  final double canvasHeight;
  final double cameraOffsetX;
  final double cameraOffsetY;
  final double cameraZoom;
  final double viewportWidth;
  final double viewportHeight;

  MiniMapPainterEnhanced({
    required this.controller,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.cameraOffsetX,
    required this.cameraOffsetY,
    required this.cameraZoom,
    required this.viewportWidth,
    required this.viewportHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Validate canvas dimensions to prevent division by zero
    if (canvasWidth <= 0 || canvasHeight <= 0) {
      _drawErrorState(canvas, size, 'Invalid canvas dimensions');
      return;
    }

    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.grey[850]!,
    );

    // CRITICAL FIX: Center the coordinate system like main canvas
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);

    // Calculate scale factors
    final scaleX = size.width / canvasWidth;
    final scaleY = size.height / canvasHeight;

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

    // FIXED: Draw viewport rectangle with correct camera transform calculation
    if (cameraZoom > 0 && viewportWidth > 0 && viewportHeight > 0) {
      // Calculate viewport size in canvas coordinates (unscaled)
      final viewportCanvasWidth = viewportWidth / cameraZoom;
      final viewportCanvasHeight = viewportHeight / cameraZoom;

      // CRITICAL FIX: The camera offset moves the canvas OPPOSITE to viewport movement
      // In main canvas: translate(center) → scale(zoom) → translate(cameraOffset)
      // This means cameraOffset moves the scaled canvas, so the viewport center is at -cameraOffset
      // We need to negate the camera offsets to get the actual viewport center in canvas coordinates
      final viewportCenterX = -cameraOffsetX;
      final viewportCenterY = -cameraOffsetY;

      // Convert viewport center from canvas coordinates to minimap coordinates
      final minimapCenterX = viewportCenterX * scaleX;
      final minimapCenterY = viewportCenterY * scaleY;

      // Calculate viewport size in minimap coordinates
      final viewportMinimapWidth = viewportCanvasWidth * scaleX;
      final viewportMinimapHeight = viewportCanvasHeight * scaleY;

      // Draw viewport rectangle centered on the correct position
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(minimapCenterX, minimapCenterY),
          width: viewportMinimapWidth,
          height: viewportMinimapHeight,
        ),
        Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    canvas.restore();
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
  bool shouldRepaint(MiniMapPainterEnhanced oldDelegate) {
    // Only repaint if something actually changed
    return oldDelegate.cameraOffsetX != cameraOffsetX ||
        oldDelegate.cameraOffsetY != cameraOffsetY ||
        oldDelegate.cameraZoom != cameraZoom ||
        oldDelegate.canvasWidth != canvasWidth ||
        oldDelegate.canvasHeight != canvasHeight ||
        oldDelegate.viewportWidth != viewportWidth ||
        oldDelegate.viewportHeight != viewportHeight ||
        _hasControllerDataChanged(oldDelegate);
  }

  /// Check if controller data has changed (trains, signals, etc.)
  bool _hasControllerDataChanged(MiniMapPainterEnhanced oldDelegate) {
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
