import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rail_champ/controllers/terminal_station_controller.dart';
import 'package:rail_champ/widgets/component_palette.dart';

class CanvasDropTarget extends StatelessWidget {
  final Widget child;
  final Offset Function(Offset localPosition) toCanvasCoords;

  const CanvasDropTarget({
    Key? key,
    required this.child,
    required this.toCanvasCoords,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DragTarget<ComponentType>(
      onAcceptWithDetails: (details) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox == null) return;
        final localPosition = renderBox.globalToLocal(details.offset);
        final canvasPosition = toCanvasCoords(localPosition);

        context.read<TerminalStationController>().createComponentFromPalette(
              componentType: details.data.name,
              x: canvasPosition.dx,
              y: canvasPosition.dy,
            );
      },
      builder: (context, candidateData, rejectedData) {
        return child;
      },
    );
  }
}
