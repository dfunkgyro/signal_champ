import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/railway_model.dart';
import '../controllers/simulation_controller.dart';
import 'relay_rack_panel.dart';
import 'vcc1_console.dart';

class StatusPanel extends StatelessWidget {
  const StatusPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSignalsStatus(context),
            const SizedBox(height: 16),
            _buildPointsStatus(context),
            const SizedBox(height: 16),
            _buildBlocksStatus(context),
            const SizedBox(height: 16),
            _buildTrainInfo(context),
            const SizedBox(height: 16),
            _buildArrivalTimes(context),
            const SizedBox(height: 16),
            _buildControlTable(context),
            const SizedBox(height: 16),
            _buildEventLog(context),
            const SizedBox(height: 16),
            const Vcc1Console(),
            const SizedBox(height: 16),
            const RelayRackPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalsStatus(BuildContext context) {
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

  Widget _buildBlocksStatus(BuildContext context) {
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
                Icon(Icons.view_week, size: 16),
                SizedBox(width: 8),
                Text(
                  'Block Sections Status',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: railwayModel.blocks.map((block) {
                final isOccupied = block.occupied;
                final isCrossover = block.id.startsWith('crossover');
                return Tooltip(
                  message:
                      '${block.id}: ${isOccupied ? "OCCUPIED" : "CLEAR"}${isCrossover ? " (Crossover)" : ""}',
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOccupied
                          ? Colors.red.withOpacity(0.2)
                          : Colors.green.withOpacity(0.2),
                      border: Border.all(
                        color: isOccupied ? Colors.red : Colors.green,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      block.id,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isOccupied ? Colors.red[900] : Colors.green[900],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainInfo(BuildContext context) {
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

  Widget _buildEventLog(BuildContext context) {
    final controller = context.watch<SimulationController>();
    final events = controller.eventLog;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.list_alt, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Event Log',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${events.length} events',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 150,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[50],
              ),
              child: events.isEmpty
                  ? const Center(
                      child: Text(
                        'No events yet\nStart simulation to see events',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        return _buildEventLogItem(events[index]);
                      },
                    ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: events.isEmpty
                        ? null
                        : () {
                            controller.clearEventLog();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Event log cleared'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Clear Log'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: events.isEmpty
                        ? null
                        : () {
                            // Export functionality
                            final exportData = events.join('\n');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Exported ${events.length} events'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Export'),
                  ),
                ),
              ],
            ),
          ],
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

  Widget _buildEventLogItem(String event) {
    // Parse event to determine type and color
    Color dotColor = Colors.green;
    if (event.contains('stopped') ||
        event.contains('RED') ||
        event.contains('OCCUPIED')) {
      dotColor = Colors.red;
    } else if (event.contains('waiting') || event.contains('warning')) {
      dotColor = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              event,
              style: const TextStyle(fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
