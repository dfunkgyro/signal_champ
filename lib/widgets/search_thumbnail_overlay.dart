import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/terminal_station_controller.dart';
import '../screens/terminal_station_models.dart';

/// Thumbnail overlay for searched items
class SearchThumbnailOverlay extends StatelessWidget {
  const SearchThumbnailOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TerminalStationController>(
      builder: (context, controller, child) {
        if (controller.highlightedItemId == null) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: 100,
          left: 0,
          right: 0,
          child: Center(
            child: _buildThumbnail(context, controller),
          ),
        );
      },
    );
  }

  Widget _buildThumbnail(BuildContext context, TerminalStationController controller) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getIconForType(controller.highlightedItemType ?? ''),
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getTitle(controller),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      controller.clearHighlight();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Content
            Container(
              padding: const EdgeInsets.all(16),
              child: _buildContent(controller),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[900]!.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (controller.highlightedItemType == 'train')
                    ElevatedButton.icon(
                      onPressed: () {
                        controller.followTrain(controller.highlightedItemId!);
                      },
                      icon: const Icon(Icons.videocam, size: 16),
                      label: const Text('Follow'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: () {
                      controller.clearHighlight();
                    },
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(TerminalStationController controller) {
    final type = controller.highlightedItemType;
    final id = controller.highlightedItemId!;

    switch (type) {
      case 'train':
        final train = controller.trains.where((t) => t.id == id).firstOrNull;
        if (train == null) return _buildNotFound();
        return _buildTrainInfo(train);

      case 'signal':
        final signal = controller.signals[id];
        if (signal == null) return _buildNotFound();
        return _buildSignalInfo(signal);

      case 'block':
        final block = controller.blocks[id];
        if (block == null) return _buildNotFound();
        return _buildBlockInfo(block);

      case 'point':
        final point = controller.points[id];
        if (point == null) return _buildNotFound();
        return _buildPointInfo(point);

      default:
        return _buildNotFound();
    }
  }

  Widget _buildTrainInfo(Train train) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Type', train.type.name.toUpperCase(), Colors.blue[300]!),
        _buildInfoRow('Speed', '${train.speed.abs().toStringAsFixed(1)} km/h',
            train.speed == 0 ? Colors.red[300]! : Colors.green[300]!),
        _buildInfoRow('Position', '(${train.x.toInt()}, ${train.y.toInt()})', Colors.grey[400]!),
        _buildInfoRow('Control', train.controlMode.name.toUpperCase(), Colors.orange[300]!),
        if (train.currentBlockId != null)
          _buildInfoRow('Block', train.currentBlockId!, Colors.purple[300]!),
        if (train.destination != null && train.destination!.isNotEmpty)
          _buildInfoRow('Destination', train.destination!, Colors.cyan[300]!),
        if (train.emergencyBrake)
          _buildInfoRow('Status', 'EMERGENCY BRAKE', Colors.red[300]!),
        if (train.doorsOpen)
          _buildInfoRow('Doors', 'OPEN', Colors.yellow[300]!),
      ],
    );
  }

  Widget _buildSignalInfo(Signal signal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Aspect', signal.aspect.name.toUpperCase(),
            _getSignalColor(signal.aspect)),
        _buildInfoRow('Position', '(${signal.x.toInt()}, ${signal.y.toInt()})', Colors.grey[400]!),
        _buildInfoRow('Routes', '${signal.routes.length} available', Colors.green[300]!),
      ],
    );
  }

  Widget _buildBlockInfo(BlockSection block) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Status', block.occupied ? 'OCCUPIED' : 'CLEAR',
            block.occupied ? Colors.red[300]! : Colors.green[300]!),
        _buildInfoRow('Position', '(${block.startX.toInt()}-${block.endX.toInt()}, ${block.y.toInt()})',
            Colors.grey[400]!),
        _buildInfoRow('Length', '${(block.endX - block.startX).toInt()} units', Colors.blue[300]!),
        if (block.occupyingTrainId != null)
          _buildInfoRow('Train', block.occupyingTrainId!, Colors.purple[300]!),
      ],
    );
  }

  Widget _buildPointInfo(Point point) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Position Status', point.position == PointPosition.normal ? 'NORMAL' : 'REVERSE',
            point.position == PointPosition.normal ? Colors.green[300]! : Colors.orange[300]!),
        _buildInfoRow('Location', '(${point.x.toInt()}, ${point.y.toInt()})', Colors.grey[400]!),
        _buildInfoRow('Locked', point.locked ? 'YES' : 'NO',
            point.locked ? Colors.red[300]! : Colors.green[300]!),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Item not found',
          style: TextStyle(
            color: Colors.red,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  String _getTitle(TerminalStationController controller) {
    final type = controller.highlightedItemType ?? '';
    final id = controller.highlightedItemId ?? '';
    return '${type.toUpperCase()} $id';
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'train':
        return Icons.train;
      case 'signal':
        return Icons.traffic;
      case 'block':
        return Icons.view_module;
      case 'point':
        return Icons.merge_type;
      default:
        return Icons.info;
    }
  }

  Color _getSignalColor(SignalAspect aspect) {
    switch (aspect) {
      case SignalAspect.red:
        return Colors.red[300]!;
      case SignalAspect.green:
        return Colors.green[300]!;
      case SignalAspect.blue:
        return Colors.blue[300]!;
    }
  }
}
