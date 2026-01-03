import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/railway_model.dart' as railway;
import '../providers/railway_provider.dart';

class CanvasView extends StatefulWidget {
  const CanvasView({super.key});

  @override
  State<CanvasView> createState() => _CanvasViewState();
}

class _CanvasViewState extends State<CanvasView> {
  final TransformationController _transformationController =
      TransformationController();
  double _scale = 1.0;
  Offset? _lastFocalPoint;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformationChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<RailwayProvider>(context, listen: false);
      if (provider.currentSvg.isEmpty && !provider.isLoading) {
        provider.initializeWithDefault();
      }
    });
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    setState(() {
      _scale = _transformationController.value.getMaxScaleOnAxis();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RailwayProvider>(context);

    return Stack(
      children: [
        GestureDetector(
          onScaleStart: (details) {
            _lastFocalPoint = details.focalPoint;
          },
          onScaleUpdate: (details) {
            if (provider.currentTool == railway.ToolMode.measure &&
                provider.isMeasuring &&
                _lastFocalPoint != null) {
              provider.updateMeasurement(details.focalPoint);
            }
            _lastFocalPoint = details.focalPoint;
          },
          onScaleEnd: (details) {
            if (provider.currentTool == railway.ToolMode.measure &&
                provider.isMeasuring) {
              provider.endMeasurement();
            }
            _lastFocalPoint = null;
          },
          onTapDown: (details) {
            if (provider.currentTool == railway.ToolMode.measure) {
              provider.startMeasurement(details.localPosition);
            } else if (provider.currentTool == railway.ToolMode.select) {
              _handleCanvasTap(details.localPosition, provider);
            }
          },
          onLongPressStart: (details) {
            if (provider.currentTool == railway.ToolMode.text) {
              provider.startDrag(
                const railway.DraggableTool(
                  id: 'text',
                  label: 'Text',
                  icon: Icons.text_fields,
                  color: Colors.purple,
                  toolMode: railway.ToolMode.text,
                ),
                details.localPosition,
              );
            }
          },
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.1,
            maxScale: 5.0,
            boundaryMargin: const EdgeInsets.all(1000),
            child: Container(
              color: Colors.white,
              child: _buildCanvasContent(provider),
            ),
          ),
        ),
        if (provider.draggedTool != null && provider.dragPosition != null)
          _buildDragOverlay(provider),
        if (provider.isLoading) _buildLoadingOverlay(),
        if (provider.errorMessage != null)
          _buildErrorOverlay(provider.errorMessage!),
        Positioned(
          bottom: 16,
          right: 16,
          child: _buildCanvasControls(provider),
        ),
        Positioned(
          top: 16,
          left: 16,
          child: _buildStatusOverlay(provider),
        ),
        if (provider.isMeasuring && provider.measureStart != null)
          _buildMeasurementOverlay(provider),
      ],
    );
  }

  Widget _buildCanvasContent(RailwayProvider provider) {
    return DragTarget<railway.DraggableTool>(
      onAccept: (tool) {
        final renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(provider.dragPosition!);
        provider.endDrag(localPosition);
      },
      onWillAccept: (data) => true,
      builder: (context, candidateData, rejectedData) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (provider.errorMessage != null) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.red[400], size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'SVG Rendering Error',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red[600]),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.currentSvg.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.track_changes, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No Track Data',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Import XML or add tracks to get started',
                  style: TextStyle(color: Colors.grey[500]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => provider.initializeWithDefault(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Sample Tracks'),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            _buildSvgDisplay(provider.currentSvg),
            ..._buildInteractiveOverlays(provider),
            ..._buildSelectionHighlights(provider),
            ..._buildTextAnnotations(provider),
            ..._buildMeasurementDisplays(provider),
          ],
        );
      },
    );
  }

  Widget _buildDragOverlay(RailwayProvider provider) {
    return Positioned(
      left: provider.dragPosition!.dx - 40,
      top: provider.dragPosition!.dy - 40,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: provider.draggedTool!.color.withOpacity(0.3),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: provider.draggedTool!.color,
            width: 2,
          ),
        ),
        child: Icon(
          provider.draggedTool!.icon,
          color: provider.draggedTool!.color,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildSvgDisplay(String svgContent) {
    try {
      if (svgContent.isEmpty) {
        return _buildEmptyState();
      }

      return SvgPicture.string(
        svgContent,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => _buildLoadingState(),
      );
    } catch (e) {
      debugPrint('SVG Rendering Error: $e');
      return _buildErrorState('Failed to render SVG: $e');
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.track_changes, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Track Elements',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add elements using the toolbox or import XML/SVG',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Generating SVG...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber, color: Colors.orange[400], size: 48),
            const SizedBox(height: 12),
            const Text(
              'SVG Display Issue',
              style: TextStyle(
                color: Color.fromRGBO(245, 124, 0, 1),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color.fromRGBO(251, 140, 0, 1)),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildInteractiveOverlays(RailwayProvider provider) {
    final widgets = <Widget>[];

    for (final block in provider.data.blocks) {
      widgets.add(
        Positioned(
          left: min(block.startX, block.endX),
          top: block.y - 15,
          child: GestureDetector(
            onTap: () {
              provider.selectElement(block, 'block');
            },
            onPanStart: (details) {
              if (provider.currentTool == railway.ToolMode.select) {
                provider.startElementDrag(details.localPosition);
              }
            },
            onPanUpdate: (details) {
              if (provider.isDraggingElement) {
                provider.updateElementDrag(details.localPosition);
              }
            },
            onPanEnd: (details) {
              if (provider.isDraggingElement) {
                provider.endElementDrag();
              }
            },
            child: Container(
              width: block.length.abs(),
              height: 30,
              color: Colors.transparent,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  decoration: BoxDecoration(
                    border: provider.selectedElement?.type == 'block' &&
                            provider.selectedElement?.element == block
                        ? Border.all(color: Colors.blue, width: 2)
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    for (final point in provider.data.points) {
      widgets.add(
        Positioned(
          left: point.x - 15,
          top: point.y - 15,
          child: GestureDetector(
            onTap: () {
              provider.selectElement(point, 'point');
            },
            onPanStart: (details) {
              if (provider.currentTool == railway.ToolMode.select) {
                provider.startElementDrag(details.localPosition);
              }
            },
            onPanUpdate: (details) {
              if (provider.isDraggingElement) {
                provider.updateElementDrag(details.localPosition);
              }
            },
            onPanEnd: (details) {
              if (provider.isDraggingElement) {
                provider.endElementDrag();
              }
            },
            child: Container(
              width: 30,
              height: 30,
              color: Colors.transparent,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  decoration: BoxDecoration(
                    border: provider.selectedElement?.type == 'point' &&
                            provider.selectedElement?.element == point
                        ? Border.all(color: Colors.green, width: 2)
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    for (final signal in provider.data.signals) {
      widgets.add(
        Positioned(
          left: signal.x - 15,
          top: signal.y - 40,
          child: GestureDetector(
            onTap: () {
              provider.selectElement(signal, 'signal');
            },
            onPanStart: (details) {
              if (provider.currentTool == railway.ToolMode.select) {
                provider.startElementDrag(details.localPosition);
              }
            },
            onPanUpdate: (details) {
              if (provider.isDraggingElement) {
                provider.updateElementDrag(details.localPosition);
              }
            },
            onPanEnd: (details) {
              if (provider.isDraggingElement) {
                provider.endElementDrag();
              }
            },
            child: Container(
              width: 30,
              height: 60,
              color: Colors.transparent,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  decoration: BoxDecoration(
                    border: provider.selectedElement?.type == 'signal' &&
                            provider.selectedElement?.element == signal
                        ? Border.all(color: Colors.red, width: 2)
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    for (final platform in provider.data.platforms) {
      widgets.add(
        Positioned(
          left: min(platform.startX, platform.endX),
          top: platform.y - 20,
          child: GestureDetector(
            onTap: () {
              provider.selectElement(platform, 'platform');
            },
            onPanStart: (details) {
              if (provider.currentTool == railway.ToolMode.select) {
                provider.startElementDrag(details.localPosition);
              }
            },
            onPanUpdate: (details) {
              if (provider.isDraggingElement) {
                provider.updateElementDrag(details.localPosition);
              }
            },
            onPanEnd: (details) {
              if (provider.isDraggingElement) {
                provider.endElementDrag();
              }
            },
            child: Container(
              width: platform.length.abs(),
              height: 40,
              color: Colors.transparent,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  decoration: BoxDecoration(
                    border: provider.selectedElement?.type == 'platform' &&
                            provider.selectedElement?.element == platform
                        ? Border.all(color: Colors.blue, width: 2)
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  List<Widget> _buildTextAnnotations(RailwayProvider provider) {
    return provider.textAnnotations.map((annotation) {
      return Positioned(
        left: annotation.position.dx - 50,
        top: annotation.position.dy - 20,
        child: GestureDetector(
          onTap: () {
            provider.selectElement(annotation, 'text');
          },
          onDoubleTap: () {
            _showEditTextDialog(context, annotation, provider);
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey),
            ),
            child: Text(
              annotation.text,
              style: TextStyle(
                fontSize: annotation.fontSize,
                color: annotation.color,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildMeasurementDisplays(RailwayProvider provider) {
    return provider.measurements.map((measurement) {
      return CustomPaint(
        painter: _MeasurementPainter(measurement: measurement),
      );
    }).toList();
  }

  Widget _buildMeasurementOverlay(RailwayProvider provider) {
    if (provider.measureStart == null || provider.measureEnd == null) {
      return const SizedBox();
    }

    return CustomPaint(
      painter: _MeasurementPainter(
        measurement: railway.Measurement(
          id: 'current',
          start: provider.measureStart!,
          end: provider.measureEnd!,
          distance: (provider.measureStart! - provider.measureEnd!).distance,
          timestamp: DateTime.now(),
        ),
        isTemporary: true,
      ),
    );
  }

  List<Widget> _buildSelectionHighlights(RailwayProvider provider) {
    final selected = provider.selectedElement;
    if (selected == null) return [];

    switch (selected.type) {
      case 'block':
        final block = selected.element as railway.Block;
        return [
          Positioned(
            left: min(block.startX, block.endX) - 5,
            top: block.y - 25,
            child: Container(
              width: block.length.abs() + 10,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 3),
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ];
      case 'point':
        final point = selected.element as railway.Point;
        return [
          Positioned(
            left: point.x - 20,
            top: point.y - 20,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ];
      case 'signal':
        final signal = selected.element as railway.Signal;
        return [
          Positioned(
            left: signal.x - 20,
            top: signal.y - 50,
            child: Container(
              width: 40,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 3),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ];
      case 'platform':
        final platform = selected.element as railway.Platform;
        return [
          Positioned(
            left: min(platform.startX, platform.endX) - 5,
            top: platform.y - 25,
            child: Container(
              width: platform.length.abs() + 10,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 3),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ];
      case 'text':
        final text = selected.element as railway.TextAnnotation;
        return [
          Positioned(
            left: text.position.dx - 55,
            top: text.position.dy - 25,
            child: Container(
              width: 110,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.purple, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ];
      default:
        return [];
    }
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay(String error) {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 20),
            const SizedBox(width: 8),
            Text(
              'Error: $error',
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvasControls(RailwayProvider provider) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildControlButton(
            icon: Icons.zoom_in,
            tooltip: 'Zoom In',
            onPressed: () {
              _transformationController.value =
                  _transformationController.value.scaled(1.2, 1.2);
            },
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            icon: Icons.zoom_out,
            tooltip: 'Zoom Out',
            onPressed: () {
              _transformationController.value =
                  _transformationController.value.scaled(0.8, 0.8);
            },
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            icon: Icons.refresh,
            tooltip: 'Reset View',
            onPressed: () {
              _transformationController.value = Matrix4.identity();
            },
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            icon: Icons.center_focus_strong,
            tooltip: 'Fit to View',
            onPressed: () {
              _transformationController.value = Matrix4.identity();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: Colors.grey[100],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOverlay(RailwayProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusItem('Zoom', '${(_scale * 100).round()}%'),
          const SizedBox(height: 4),
          _buildStatusItem('Blocks', '${provider.data.blocks.length}'),
          const SizedBox(height: 4),
          _buildStatusItem('Signals', '${provider.data.signals.length}'),
          const SizedBox(height: 4),
          _buildStatusItem('Points', '${provider.data.points.length}'),
          const SizedBox(height: 4),
          _buildStatusItem('Platforms', '${provider.data.platforms.length}'),
          if (provider.currentTool == railway.ToolMode.measure &&
              provider.isMeasuring &&
              provider.measureStart != null &&
              provider.measureEnd != null) ...[
            const SizedBox(height: 4),
            _buildStatusItem('Measuring',
                '${(provider.measureStart! - provider.measureEnd!).distance.toStringAsFixed(1)} units'),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _handleCanvasTap(Offset position, RailwayProvider provider) {
    bool elementSelected = false;

    for (final block in provider.data.blocks) {
      final blockRect = Rect.fromLTWH(
        min(block.startX, block.endX),
        block.y - 15,
        block.length.abs(),
        30,
      );
      if (blockRect.contains(position)) {
        provider.selectElement(block, 'block');
        elementSelected = true;
        return;
      }
    }

    for (final point in provider.data.points) {
      final pointRect = Rect.fromCircle(
        center: Offset(point.x, point.y),
        radius: 15,
      );
      if (pointRect.contains(position)) {
        provider.selectElement(point, 'point');
        elementSelected = true;
        return;
      }
    }

    for (final signal in provider.data.signals) {
      final signalRect = Rect.fromLTWH(
        signal.x - 15,
        signal.y - 40,
        30,
        60,
      );
      if (signalRect.contains(position)) {
        provider.selectElement(signal, 'signal');
        elementSelected = true;
        return;
      }
    }

    for (final platform in provider.data.platforms) {
      final platformRect = Rect.fromLTWH(
        min(platform.startX, platform.endX),
        platform.y - 20,
        platform.length.abs(),
        40,
      );
      if (platformRect.contains(position)) {
        provider.selectElement(platform, 'platform');
        elementSelected = true;
        return;
      }
    }

    for (final text in provider.textAnnotations) {
      final textRect = Rect.fromLTWH(
        text.position.dx - 50,
        text.position.dy - 20,
        100,
        40,
      );
      if (textRect.contains(position)) {
        provider.selectElement(text, 'text');
        elementSelected = true;
        return;
      }
    }

    if (!elementSelected) {
      provider.clearSelection();
    }
  }

  void _showEditTextDialog(BuildContext context,
      railway.TextAnnotation annotation, RailwayProvider provider) {
    final controller = TextEditingController(text: annotation.text);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Text'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter text...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.updateTextAnnotation(annotation.id, controller.text);
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
          if (provider.selectedElement?.type == 'text')
            TextButton(
              onPressed: () {
                provider.deleteTextAnnotation(annotation.id);
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
        ],
      ),
    );
  }
}

class _MeasurementPainter extends CustomPainter {
  final railway.Measurement measurement;
  final bool isTemporary;

  _MeasurementPainter({required this.measurement, this.isTemporary = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isTemporary ? Colors.blue : Colors.green
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = (isTemporary ? Colors.blue : Colors.green).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    canvas.drawLine(measurement.start, measurement.end, paint);

    final path = Path()
      ..moveTo(measurement.start.dx, measurement.start.dy)
      ..lineTo(measurement.end.dx, measurement.end.dy);

    canvas.drawPath(path, fillPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '${measurement.distance.toStringAsFixed(1)} units',
        style: TextStyle(
          color: isTemporary ? Colors.blue : Colors.green,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    final textOffset = Offset(
      (measurement.start.dx + measurement.end.dx) / 2 - textPainter.width / 2,
      (measurement.start.dy + measurement.end.dy) / 2 - textPainter.height / 2,
    );

    final backgroundRect = Rect.fromLTWH(
      textOffset.dx - 4,
      textOffset.dy - 2,
      textPainter.width + 8,
      textPainter.height + 4,
    );

    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawRect(backgroundRect, backgroundPaint);
    canvas.drawRect(backgroundRect, paint);
    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
