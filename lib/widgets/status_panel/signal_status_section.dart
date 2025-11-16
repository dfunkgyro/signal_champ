import 'package:flutter/material.dart';
import '../../models/railway_model.dart';

class SignalStatusSection extends StatelessWidget {
  final RailwayModel railwayModel;

  const SignalStatusSection({super.key, required this.railwayModel});

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
                Icon(Icons.traffic, size: 16),
                SizedBox(width: 8),
                Text(
                  'Signals Status',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...railwayModel.signals.map((signal) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getSignalColor(signal.state).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _getSignalColor(signal.state)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getSignalColor(signal.state),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${signal.id}${signal.route != null ? ' (Route ${signal.route})' : ''}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    'State: ${signal.state.name.toUpperCase()}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _getSignalStatusText(signal),
                              style: TextStyle(
                                fontSize: 11,
                                color: _getSignalColor(signal.state),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (signal.state == SignalState.red &&
                            signal.lastStateChangeReason.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Reason: ${signal.lastStateChangeReason}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red[900],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Color _getSignalColor(SignalState state) {
    switch (state) {
      case SignalState.green:
        return Colors.green;
      case SignalState.yellow:
        return Colors.orange;
      case SignalState.red:
        return Colors.red;
      case SignalState.blue:
        return Colors.blue;
    }
  }

  String _getSignalStatusText(Signal signal) {
    switch (signal.state) {
      case SignalState.green:
        return 'CLEAR';
      case SignalState.yellow:
        return 'CAUTION';
      case SignalState.red:
        return 'STOP';
      case SignalState.blue:
        return 'CBTC';
    }
  }
}
