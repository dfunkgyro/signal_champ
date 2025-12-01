import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rail_champ/controllers/terminal_station_controller.dart';
import 'package:rail_champ/widgets/component_palette.dart';

/// Wraps the railway canvas to accept component drops from the palette
class CanvasDropTarget extends StatefulWidget {
  final Widget child;
  final Offset offset;  // Current pan/zoom offset
  final double scale;   // Current zoom scale

  const CanvasDropTarget({
    Key? key,
    required this.child,
    required this.offset,
    required this.scale,
  }) : super(key: key);

  @override
  State<CanvasDropTarget> createState() => _CanvasDropTargetState();
}

class _CanvasDropTargetState extends State<CanvasDropTarget> {
  ComponentType? _draggedComponent;
  Offset? _dropPosition;

  @override
  Widget build(BuildContext context) {
    return Consumer<TerminalStationController>(
      builder: (context, controller, child) {
        return DragTarget<ComponentType>(
          onWillAcceptWithDetails: (data) {
            setState(() {
              _draggedComponent = data.data;
            });
            return controller.editModeEnabled && controller.activeLayer != null;
          },
          onAcceptWithDetails: (data) {
            if (_dropPosition == null) return;

            // Convert screen coordinates to canvas coordinates
            final canvasX = (_dropPosition!.dx - widget.offset.dx) / widget.scale;
            final canvasY = (_dropPosition!.dy - widget.offset.dy) / widget.scale;

            // Create the component at the drop position
            final componentType = _getComponentTypeString(data.data);
            controller.createComponentFromPalette(
              componentType: componentType,
              x: canvasX,
              y: canvasY,
            );

            setState(() {
              _draggedComponent = null;
              _dropPosition = null;
            });

            // Show success feedback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Added ${data.data.displayName} to canvas'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 1),
              ),
            );
          },
          onLeave: (data) {
            setState(() {
              _draggedComponent = null;
              _dropPosition = null;
            });
          },
          onMove: (details) {
            setState(() {
              _dropPosition = details.offset;
            });
          },
          builder: (context, candidateData, rejectedData) {
            return Stack(
              children: [
                // Original canvas
                child!,

                // Drop indicator
                if (_draggedComponent != null && _dropPosition != null)
                  Positioned(
                    left: _dropPosition!.dx - 25,
                    top: _dropPosition!.dy - 25,
                    child: IgnorePointer(
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _draggedComponent!.color.withOpacity(0.3),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _draggedComponent!.color,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          _draggedComponent!.icon,
                          color: _draggedComponent!.color,
                          size: 24,
                        ),
                      ),
                    ),
                  ),

                // Drag instructions overlay
                if (_draggedComponent != null)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _draggedComponent!.color,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _draggedComponent!.icon,
                                color: _draggedComponent!.color,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Adding ${_draggedComponent!.displayName}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (controller.activeLayer != null)
                                    Text(
                                      'Layer: ${controller.activeLayer!.name}',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  /// Convert ComponentType enum to string for controller
  String _getComponentTypeString(ComponentType type) {
    switch (type) {
      case ComponentType.block:
        return 'block';
      case ComponentType.signal:
        return 'signal';
      case ComponentType.point:
        return 'point';
      case ComponentType.crossover:
        return 'crossover';
      case ComponentType.platform:
        return 'platform';
      case ComponentType.trainStop:
        return 'trainstop';
      case ComponentType.bufferStop:
        return 'bufferstop';
      case ComponentType.axleCounter:
        return 'axlecounter';
      case ComponentType.transponder:
        return 'transponder';
      case ComponentType.wifiAntenna:
        return 'wifiantenna';
    }
  }
}
