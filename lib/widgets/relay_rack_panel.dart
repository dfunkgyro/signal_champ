import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/railway_model.dart';

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
    final railwayModel = context.watch<RailwayModel>();

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
            spacing: 4,
            runSpacing: 4,
            children: railwayModel.signals.map((signal) {
              final relayName = _getSignalRelayName(signal.id);
              final isUp = signal.state == SignalState.green;
              return _buildRelayIndicator(relayName, isUp);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPointsRelaysSection(BuildContext context) {
    final railwayModel = context.watch<RailwayModel>();

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
            spacing: 4,
            runSpacing: 4,
            children: railwayModel.points.map((point) {
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
    final railwayModel = context.watch<RailwayModel>();

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
            spacing: 4,
            runSpacing: 4,
            children: railwayModel.blocks
                .where((block) => !block.isCrossover)
                .map((block) {
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
      width: 52,
      height: 65,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border.all(color: Colors.grey[800]!, width: 1),
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Relay body with label
          Container(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            ),
            child: Text(
              relayName,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Indicator light
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isUp ? Colors.green[500] : Colors.red[600],
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: (isUp ? Colors.green : Colors.red).withOpacity(0.6),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  isUp ? 'UP' : 'DN',
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
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
    // Determine relay position based on animation progress
    // Mid position occurs during animation (animationProgress > 0 and < 1)
    if (point.animationProgress > 0 && point.animationProgress < 1) {
      return 'mid';
    }
    // Otherwise return the actual position
    return point.position == PointPosition.normal ? 'normal' : 'reverse';
  }

  Widget _buildPointRelayIndicator(String relayName, String position) {
    // Determine colors based on position
    Color indicatorColor;

    if (position == 'normal') {
      indicatorColor = Colors.red[600]!;
    } else if (position == 'mid') {
      indicatorColor = Colors.orange[600]!;
    } else {
      // reverse
      indicatorColor = Colors.green[500]!;
    }

    return Container(
      width: 60,
      height: 65,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border.all(color: Colors.grey[800]!, width: 1),
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Relay body with label
          Container(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            ),
            child: Text(
              relayName,
              style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Indicator light
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: indicatorColor,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: indicatorColor.withOpacity(0.6),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  position == 'normal'
                      ? 'NWP'
                      : position == 'mid'
                          ? 'MID'
                          : 'RWP',
                  style: TextStyle(
                    fontSize: 6,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
