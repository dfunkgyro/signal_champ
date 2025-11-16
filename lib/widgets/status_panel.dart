import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/railway_model.dart';
import '../controllers/simulation_controller.dart';
import 'relay_rack_panel.dart';
import 'vcc1_console.dart';
import 'status_panel/signal_status_section.dart';
import 'status_panel/train_status_section.dart';
import 'status_panel/block_status_section.dart';
import 'status_panel/event_log_section.dart';

class StatusPanel extends StatelessWidget {
  const StatusPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final railwayModel = context.watch<RailwayModel>();
    final simulationController = context.watch<SimulationController>();

    return Container(
      color: Colors.grey[100],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SignalStatusSection(railwayModel: railwayModel),
            const SizedBox(height: 16),
            _buildPointsStatus(context),
            const SizedBox(height: 16),
            BlockStatusSection(railwayModel: railwayModel),
            const SizedBox(height: 16),
            TrainStatusSection(railwayModel: railwayModel),
            const SizedBox(height: 16),
            _buildArrivalTimes(context),
            const SizedBox(height: 16),
            _buildControlTable(context),
            const SizedBox(height: 16),
            EventLogSection(controller: simulationController),
            const SizedBox(height: 16),
            const Vcc1Console(),
            const SizedBox(height: 16),
            const RelayRackPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsStatus(BuildContext context) {
    final railwayModel = context.watch<RailwayModel>();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.change_circle, size: 16),
                SizedBox(width: 8),
                Text(
                  'Points Status',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...railwayModel.points.map((point) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: point.position == PointPosition.normal
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: point.position == PointPosition.normal
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: point.position == PointPosition.normal
                                ? Colors.red
                                : Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                point.id,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'Position: ${point.position.name.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (point.animationProgress > 0 &&
                            point.animationProgress < 1)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              value: point.animationProgress,
                              strokeWidth: 2,
                            ),
                          ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildArrivalTimes(BuildContext context) {
    final railwayModel = context.watch<RailwayModel>();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.schedule, size: 16),
                SizedBox(width: 8),
                Text(
                  'Platform Arrivals',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildArrivalTimeItem(
              'Platform 1',
              _getEstimatedArrival(railwayModel, '110', '112'),
              Icons.train,
              _hasTrainApproaching(railwayModel, '110', '112'),
            ),
            _buildArrivalTimeItem(
              'Platform 2 (Bay)',
              _getEstimatedArrival(railwayModel, '109', '111'),
              Icons.train,
              _hasTrainApproaching(railwayModel, '109', '111'),
            ),
          ],
        ),
      ),
    );
  }

  String _getEstimatedArrival(
      RailwayModel model, String block1, String block2) {
    final approaching = model.trains.where((t) =>
        (t.currentBlock == block1 || t.currentBlock == block2) &&
        t.status == TrainStatus.moving);

    if (approaching.isEmpty) return '--:--';

    // Estimate based on progress and speed
    final train = approaching.first;
    final blocksToGo = train.currentBlock == block1 ? 1 : 0;
    final progressRemaining = 1.0 - train.progress;
    final estimatedSeconds =
        ((blocksToGo + progressRemaining) / (train.speed * 0.005)) * 0.016;

    if (estimatedSeconds < 60) {
      return '${estimatedSeconds.toInt()}s';
    } else {
      return '${(estimatedSeconds / 60).toInt()}m ${(estimatedSeconds % 60).toInt()}s';
    }
  }

  bool _hasTrainApproaching(
      RailwayModel model, String block1, String block2) {
    return model.trains.any((t) =>
        (t.currentBlock == block1 || t.currentBlock == block2) &&
        t.status == TrainStatus.moving);
  }

  Widget _buildControlTable(BuildContext context) {
    final railwayModel = context.watch<RailwayModel>();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.table_chart, size: 16),
                SizedBox(width: 8),
                Text(
                  'Signal Control Table',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Table(
              border: TableBorder.all(color: Colors.grey[300]!),
              columnWidths: const {
                0: FlexColumnWidth(1.5),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[100]),
                  children: [
                    _buildTableCell('Signal', isHeader: true),
                    _buildTableCell('Required Points', isHeader: true),
                    _buildTableCell('Controlled Blocks', isHeader: true),
                    _buildTableCell('State', isHeader: true),
                  ],
                ),
                ...railwayModel.signals.map((signal) {
                  return TableRow(
                    children: [
                      _buildTableCell(
                          '${signal.id}${signal.route != null ? '\nR${signal.route}' : ''}'),
                      _buildTableCell(signal.requiredPointPositions.isEmpty
                          ? '-'
                          : signal.requiredPointPositions.join('\n')),
                      _buildTableCell(signal.controlledBlocks.join(', ')),
                      _buildTableCell(
                        signal.state.name.toUpperCase(),
                        color: _getSignalColor(signal.state),
                      ),
                    ],
                  );
                }),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Signals automatically turn red when controlled blocks are occupied or points are incorrectly set',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[800],
                      ),
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

  Widget _buildTableCell(String text,
      {bool isHeader = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  Widget _buildArrivalTimeItem(
      String platform, String time, IconData icon, bool isEstimated) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isEstimated ? Colors.green[50] : Colors.grey[50],
          border: Border.all(
            color: isEstimated ? Colors.green[200]! : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isEstimated ? Colors.green[700] : Colors.grey[600],
                size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    platform,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isEstimated ? Colors.green[800] : Colors.grey[700],
                    ),
                  ),
                  if (isEstimated && time != '--:--')
                    Text(
                      'Arriving in $time',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color.fromRGBO(67, 160, 71, 1),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              time,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isEstimated ? Colors.green[700] : Colors.grey[500],
              ),
            ),
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
}
