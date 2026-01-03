import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/graph_model.dart';
import '../providers/graph_provider.dart';
import 'graph_node_painter.dart';

class GraphCanvas extends StatefulWidget {
  const GraphCanvas({super.key});

  @override
  State<GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends State<GraphCanvas> {
  final TransformationController _controller = TransformationController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GraphProvider>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(
          constraints.maxWidth * 2,
          constraints.maxHeight * 2,
        );

        return InteractiveViewer(
          transformationController: _controller,
          minScale: 0.2,
          maxScale: 3.0,
          boundaryMargin: const EdgeInsets.all(500),
          child: SizedBox(
            width: canvasSize.width,
            height: canvasSize.height,
            child: Stack(
              children: [
                CustomPaint(
                  size: canvasSize,
                  painter: _GraphGridPainter(),
                ),
                CustomPaint(
                  size: canvasSize,
                  painter: _GraphEdgesPainter(
                    nodes: provider.data.nodes,
                    edges: provider.data.edges,
                    selectedNodeId: provider.selectedNode?.id,
                  ),
                ),
                ...provider.data.nodes.map((node) {
                  return _GraphNodeWidget(node: node);
                }).toList(),
                if (provider.errorMessage != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _ErrorBanner(
                      message: provider.errorMessage!,
                      onDismiss: provider.clearError,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GraphNodeWidget extends StatelessWidget {
  final GraphNode node;

  const _GraphNodeWidget({required this.node});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GraphProvider>(context);
    final isSelected = provider.selectedNode?.id == node.id;
    final size = _nodeSize(node.type);

    return Positioned(
      left: node.position.dx - size.width / 2,
      top: node.position.dy - size.height / 2,
      child: GestureDetector(
        onTap: () {
          if (provider.connectMode) {
            if (provider.pendingConnectionFromId == null) {
              provider.beginConnection(node);
            } else {
              provider.completeConnection(node);
            }
          } else {
            provider.selectNode(node);
          }
        },
        onPanUpdate: (details) {
          provider.updateNodePosition(
            node.id,
            node.position + details.delta,
          );
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: Container(
            width: size.width,
            height: size.height,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: CustomPaint(
                    painter: GraphNodePainter(
                      type: node.type,
                      isSelected: isSelected,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  node.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Size _nodeSize(GraphNodeType type) {
    switch (type) {
      case GraphNodeType.block:
      case GraphNodeType.platform:
      case GraphNodeType.routeReservation:
      case GraphNodeType.movementAuthority:
      case GraphNodeType.train:
        return const Size(160, 70);
      case GraphNodeType.crossover:
      case GraphNodeType.bufferStop:
        return const Size(110, 70);
      case GraphNodeType.signal:
      case GraphNodeType.wifiAntenna:
        return const Size(90, 80);
      case GraphNodeType.axleCounter:
      case GraphNodeType.transponder:
        return const Size(90, 60);
      case GraphNodeType.trainStop:
        return const Size(100, 60);
      case GraphNodeType.point:
      case GraphNodeType.text:
        return const Size(120, 70);
    }
  }
}

class _GraphGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEDEDED)
      ..strokeWidth = 1;

    const gridSize = 80.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GraphEdgesPainter extends CustomPainter {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final String? selectedNodeId;

  _GraphEdgesPainter({
    required this.nodes,
    required this.edges,
    required this.selectedNodeId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final nodeMap = {for (final node in nodes) node.id: node};
    final edgePaint = Paint()
      ..color = const Color(0xFF424242)
      ..strokeWidth = 2;

    for (final edge in edges) {
      final fromNode = nodeMap[edge.fromNodeId];
      final toNode = nodeMap[edge.toNodeId];
      if (fromNode == null || toNode == null) continue;

      final path = Path()
        ..moveTo(fromNode.position.dx, fromNode.position.dy)
        ..lineTo(toNode.position.dx, toNode.position.dy);
      canvas.drawPath(path, edgePaint);
    }

    if (selectedNodeId != null) {
      final selectedNode = nodeMap[selectedNodeId!];
      if (selectedNode != null) {
        final highlightPaint = Paint()
          ..color = const Color(0xFF1D3557)
          ..strokeWidth = 3;
        canvas.drawCircle(selectedNode.position, 6, highlightPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GraphEdgesPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.edges != edges ||
        oldDelegate.selectedNodeId != selectedNodeId;
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      color: const Color(0xFFFCE7E7),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFB00020)),
            const SizedBox(width: 8),
            Text(
              message,
              style: const TextStyle(color: Color(0xFF5F0A0A)),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: const Color(0xFFB00020),
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}
