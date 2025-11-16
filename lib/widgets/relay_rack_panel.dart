import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/terminal_station_controller.dart';
import '../screens/terminal_station_models.dart';

class RelayRackPanel extends StatelessWidget {
  const RelayRackPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.electrical_services, size: 16),
                SizedBox(width: 8),
                Text(
                  'Relay Rack',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSignalRelaysSection(context),
            const SizedBox(height: 16),
            _buildPointsRelaysSection(context),
            const SizedBox(height: 16),
            _buildTrackRelaysSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalRelaysSection(BuildContext context) {
    final controller = context.watch<TerminalStationController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.blue[700],
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'Signal Relays',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.signals.entries.map((entry) {
              final signal = entry.value;
              final relayName = _getSignalRelayName(signal.id);
              final isUp = signal.aspect == SignalAspect.green;
              return _buildRelayIndicator(relayName, isUp);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPointsRelaysSection(BuildContext context) {
    final controller = context.watch<TerminalStationController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.blue[700],
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'Points Relays',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.points.entries.map((entry) {
              final point = entry.value;
              final relayName = _getPointRelayName(point.id);
              final position = _getPointRelayPosition(point);
              return _buildPointRelayIndicator(relayName, position);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackRelaysSection(BuildContext context) {
    final controller = context.watch<TerminalStationController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.blue[700],
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'Track Relays',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.blocks.entries.map((entry) {
              final block = entry.value;
              final relayName = _getBlockRelayName(block.id);
              final isUp = !block.occupied;
              return _buildRelayIndicator(relayName, isUp);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRelayIndicator(String relayName, bool isUp) {
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: isUp ? Colors.green[50] : Colors.red[50],
        border: Border.all(
          color: isUp ? Colors.green[700]! : Colors.red[700]!,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            relayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isUp ? Colors.green[900] : Colors.red[900],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isUp ? Colors.green[700] : Colors.red[700],
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              isUp ? 'UP' : 'DOWN',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSignalRelayName(String signalId) {
    // Remove the 'C' prefix and add 'GR' suffix
    // e.g., "C31" -> "31GR"
    if (signalId.startsWith('C')) {
      return '${signalId.substring(1)}GR';
    }
    return '${signalId}GR';
  }

  String _getBlockRelayName(String blockId) {
    // Add 'TR' suffix to block id
    // e.g., "100" -> "100TR"
    return '${blockId}TR';
  }

  String _getPointRelayName(String pointId) {
    // Add 'WKR' suffix to point id
    // e.g., "78A" -> "78A WKR"
    return '$pointId WKR';
  }

  String _getPointRelayPosition(Point point) {
    // For terminal station controller, we don't have animationProgress
    // so we just check locked state to determine if it's moving
    if (point.locked) {
      return 'mid';
    }
    // Otherwise return the actual position
    return point.position == PointPosition.normal ? 'normal' : 'reverse';
  }

  Widget _buildPointRelayIndicator(String relayName, String position) {
    // Determine colors based on position
    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (position == 'normal') {
      backgroundColor = Colors.red[50]!;
      borderColor = Colors.red[700]!;
      textColor = Colors.red[900]!;
    } else if (position == 'mid') {
      backgroundColor = Colors.orange[50]!;
      borderColor = Colors.orange[700]!;
      textColor = Colors.orange[900]!;
    } else {
      // reverse
      backgroundColor = Colors.green[50]!;
      borderColor = Colors.green[700]!;
      textColor = Colors.green[900]!;
    }

    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            relayName,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: position == 'normal'
                  ? Colors.red[700]
                  : position == 'mid'
                      ? Colors.orange[700]
                      : Colors.green[700],
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              position.toUpperCase(),
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
