import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rail_champ/models/railway_model.dart';

class Vcc1Console extends StatelessWidget {
  const Vcc1Console({super.key});

  @override
  Widget build(BuildContext context) {
    final railwayModel = context.watch<RailwayModel>();

    if (!railwayModel.cbtcModeActive) {
      return const SizedBox.shrink();
    }

    final cbtcTrains = railwayModel.trains
        .where((train) => train.isCbtcEquipped)
        .toList();

    return Card(
      elevation: 4,
      color: Colors.black,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green[700]!, width: 3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // VCC1 Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[900],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(5),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.computer, color: Colors.green[300], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'VCC1 - Vehicle Control Computer',
                    style: TextStyle(
                      color: Colors.green[300],
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Courier',
                    ),
                  ),
                ],
              ),
            ),

            // Console Content
            Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // System Status
                  _buildConsoleLine(
                    'SYSTEM STATUS: ONLINE',
                    Colors.green[400]!,
                    bold: true,
                  ),
                  _buildConsoleLine(
                    'MODE: MOVING BLOCK SUPERVISION',
                    Colors.green[400]!,
                  ),
                  _buildConsoleLine(
                    'SAFETY DISTANCE: 200 UNITS',
                    Colors.green[400]!,
                  ),
                  const SizedBox(height: 8),

                  // Divider
                  Container(
                    height: 1,
                    color: Colors.green[700],
                  ),
                  const SizedBox(height: 8),

                  // CBTC Trains Section
                  _buildConsoleLine(
                    'CBTC TRAINS TRACKED: ${cbtcTrains.length}',
                    Colors.green[300]!,
                    bold: true,
                  ),
                  const SizedBox(height: 4),

                  if (cbtcTrains.isEmpty)
                    _buildConsoleLine(
                      '> NO CBTC TRAINS DETECTED',
                      Colors.green[600]!,
                    )
                  else
                    ...cbtcTrains.map((train) {
                      final vccControl = _isVccControlled(train);
                      final isRmMode = train.cbtcMode == CbtcMode.rm;
                      final safetyStatus = railwayModel.getVcc1SafetyStatus(train.id);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildConsoleLine(
                              '> ${train.name}',
                              vccControl ? Colors.green[300]! : Colors.green[700]!,
                              bold: true,
                            ),
                            _buildConsoleLine(
                              '  MODE: ${train.cbtcMode.name.toUpperCase()}${vccControl ? " [VCC1]" : isRmMode ? " [TRACKED ONLY]" : ""}',
                              vccControl ? Colors.green[400]! : Colors.green[700]!,
                            ),
                            _buildConsoleLine(
                              '  POSITION: ${train.x.toStringAsFixed(0)} units',
                              Colors.green[400]!,
                            ),
                            _buildConsoleLine(
                              '  BLOCK: ${train.currentBlock}',
                              Colors.green[400]!,
                            ),
                            if (isRmMode)
                              _buildConsoleLine(
                                '  SPEED: 80% (Restricted)',
                                Colors.orange[400]!,
                              ),
                            if (safetyStatus.isNotEmpty)
                              _buildConsoleLine(
                                '  ⚠ $safetyStatus',
                                Colors.yellow[600]!,
                              ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 8),
                  Container(
                    height: 1,
                    color: Colors.green[700],
                  ),
                  const SizedBox(height: 8),

                  // Block Status
                  _buildConsoleLine(
                    'BLOCK OCCUPANCY MONITOR',
                    Colors.green[300]!,
                    bold: true,
                  ),
                  const SizedBox(height: 4),

                  ...railwayModel.blocks
                      .where((block) => block.occupied)
                      .map((block) {
                    return _buildConsoleLine(
                      '> AB ${block.id}: OCCUPIED',
                      Colors.red[400]!,
                    );
                  }),

                  if (railwayModel.blocks.every((block) => !block.occupied))
                    _buildConsoleLine(
                      '> ALL BLOCKS CLEAR',
                      Colors.green[400]!,
                    ),

                  const SizedBox(height: 8),
                  Container(
                    height: 1,
                    color: Colors.green[700],
                  ),
                  const SizedBox(height: 8),

                  // Point Reservations
                  _buildConsoleLine(
                    'POINT RESERVATIONS',
                    Colors.green[300]!,
                    bold: true,
                  ),
                  const SizedBox(height: 4),

                  ...railwayModel.points.where((p) => p.reservedByVin != null).map((point) {
                    return _buildConsoleLine(
                      '> Point ${point.id}: RESERVED by ${point.reservedByVin} → ${point.reservedDestination} [${point.position.name.toUpperCase()}]',
                      Colors.yellow[400]!,
                    );
                  }),

                  if (railwayModel.points.every((p) => p.reservedByVin == null))
                    _buildConsoleLine(
                      '> NO ACTIVE RESERVATIONS',
                      Colors.green[600]!,
                    ),

                  const SizedBox(height: 8),
                  Container(
                    height: 1,
                    color: Colors.green[700],
                  ),
                  const SizedBox(height: 8),

                  // VCC1 Commands Log
                  _buildConsoleLine(
                    'ACTIVE CONSTRAINTS',
                    Colors.green[300]!,
                    bold: true,
                  ),
                  const SizedBox(height: 4),

                  ...railwayModel.getVcc1ActiveConstraints().map((constraint) {
                    return _buildConsoleLine(
                      '> $constraint',
                      Colors.cyan[300]!,
                    );
                  }),

                  if (railwayModel.getVcc1ActiveConstraints().isEmpty)
                    _buildConsoleLine(
                      '> NO ACTIVE CONSTRAINTS',
                      Colors.green[600]!,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isVccControlled(Train train) {
    return train.cbtcMode == CbtcMode.auto || train.cbtcMode == CbtcMode.pm;
  }

  Widget _buildConsoleLine(String text, Color color, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontFamily: 'Courier',
        ),
      ),
    );
  }
}
