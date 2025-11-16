import 'package:flutter/material.dart';
import '../../models/railway_model.dart';

class TrainStatusSection extends StatelessWidget {
  final RailwayModel railwayModel;

  const TrainStatusSection({super.key, required this.railwayModel});

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
                Icon(Icons.train, size: 16),
                SizedBox(width: 8),
                Text(
                  'Train Status',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (railwayModel.trains.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: Text(
                    'No trains in system\nClick + to add trains',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...railwayModel.trains.map((train) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: train.isSelected
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color:
                              train.isSelected ? Colors.orange : Colors.grey,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: train.color,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          train.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500),
                                        ),
                                        if (train.isCbtcEquipped) ...[
                                          const SizedBox(width: 4),
                                          Icon(Icons.sensors,
                                              size: 12, color: Colors.cyan[700]),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      'Block: ${train.currentBlock} | ${train.direction.name.toUpperCase()} | Speed: ${train.speed.toStringAsFixed(1)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (train.isCbtcEquipped)
                                      Text(
                                        'VIN: ${train.vin}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.cyan[800],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    if (train.smcDestination != null)
                                      Row(
                                        children: [
                                          Icon(Icons.flag, size: 10, color: Colors.green[700]),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Destination: ${train.smcDestination}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.green[800],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              _getTrainStatusIcon(train.status),
                            ],
                          ),
                          if (train.isCbtcEquipped) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.cyan[50],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.cyan[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.settings_remote,
                                          size: 12, color: Colors.cyan[700]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'CBTC Mode: ${_getCbtcModeName(train.cbtcMode)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.cyan[900],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: CbtcMode.values.map((mode) {
                                      final isActive = train.cbtcMode == mode;
                                      return InkWell(
                                        onTap: () {
                                          railwayModel.setCbtcTrainMode(train.id, mode);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? railwayModel.getCbtcModeColor(mode)
                                                : Colors.white,
                                            border: Border.all(
                                              color: railwayModel.getCbtcModeColor(mode),
                                              width: isActive ? 2 : 1,
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            mode.name.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: isActive
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isActive
                                                  ? (mode == CbtcMode.off
                                                      ? Colors.black
                                                      : Colors.white)
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (train.status == TrainStatus.waiting &&
                              train.stopReason.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber,
                                      size: 14, color: Colors.orange),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      train.stopReason,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
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

  Widget _getTrainStatusIcon(TrainStatus status) {
    switch (status) {
      case TrainStatus.moving:
        return const Icon(Icons.play_arrow, size: 16, color: Colors.green);
      case TrainStatus.stopped:
        return const Icon(Icons.stop, size: 16, color: Colors.red);
      case TrainStatus.waiting:
        return const Icon(Icons.pause, size: 16, color: Colors.orange);
      case TrainStatus.completed:
        return const Icon(Icons.flag, size: 16, color: Colors.purple);
      case TrainStatus.reversing:
        return const Icon(Icons.swap_horiz, size: 16, color: Colors.blue);
    }
  }

  String _getCbtcModeName(CbtcMode mode) {
    switch (mode) {
      case CbtcMode.auto:
        return 'Auto';
      case CbtcMode.pm:
        return 'PM (Protective Manual)';
      case CbtcMode.rm:
        return 'RM (Restrictive Manual - 80% Speed)';
      case CbtcMode.off:
        return 'Off';
      case CbtcMode.storage:
        return 'Storage';
    }
  }
}
