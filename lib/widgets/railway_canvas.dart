import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/railway_model.dart';
import 'railway_canvas/railway_painter.dart';

class RailwayCanvas extends StatefulWidget {
  const RailwayCanvas({Key? key}) : super(key: key);

  @override
  State<RailwayCanvas> createState() => _RailwayCanvasState();
}

class _RailwayCanvasState extends State<RailwayCanvas> {
  Offset _cameraOffset = Offset.zero;
  double _zoom = 1.0;

  @override
  Widget build(BuildContext context) {
    final railwayModel = context.watch<RailwayModel>();

    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _cameraOffset += details.delta / _zoom;
        });
      },
      onScaleUpdate: (details) {
        setState(() {
          _zoom = (_zoom * details.scale).clamp(0.5, 3.0);
        });
      },
      child: Container(
        color: Theme.of(context).colorScheme.background,
        child: CustomPaint(
          size: Size.infinite,
          painter: RailwayPainter(
            trains: railwayModel.trains,
            blocks: railwayModel.blocks,
            signals: railwayModel.signals,
            transponders: railwayModel.transponders,
            wifiAntennas: railwayModel.wifiAntennas,
            cbtcEnabled: railwayModel.cbtcDevicesEnabled,
            cameraOffset: _cameraOffset,
            zoom: _zoom,
            theme: Theme.of(context),
          ),
        ),
      ),
    );
  }
}
