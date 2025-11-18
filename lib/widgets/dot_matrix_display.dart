import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/terminal_station_controller.dart';
import '../screens/terminal_station_models.dart';
import 'dart:math' as math;

/// Dot Matrix Train Information Display
class DotMatrixDisplay extends StatefulWidget {
  const DotMatrixDisplay({Key? key}) : super(key: key);

  @override
  State<DotMatrixDisplay> createState() => _DotMatrixDisplayState();
}

class _DotMatrixDisplayState extends State<DotMatrixDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _currentMessageIndex = 0;
  final List<String> _alerts = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TerminalStationController>(
      builder: (context, controller, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: Colors.grey[700]!, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[600], size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'TRAIN INFORMATION',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Current time
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[700]!, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time, color: Colors.green[400], size: 16),
                    const SizedBox(width: 8),
                    _DotMatrixText(
                      text: _formatTime(controller.currentTime),
                      color: Colors.green[400]!,
                      fontSize: 18,
                      bold: true,
                    ),
                  ],
                ),
              ),

              // Scrollable train arrivals
              Expanded(
                child: Container(
                  color: Colors.black,
                  child: controller.trains.isEmpty
                      ? Center(
                          child: _DotMatrixText(
                            text: 'NO TRAINS SCHEDULED',
                            color: Colors.orange[300]!,
                            fontSize: 12,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: controller.trains.length,
                          itemBuilder: (context, index) {
                            final train = controller.trains[index];
                            return _buildTrainEntry(train, controller);
                          },
                        ),
                ),
              ),

              // Alerts section
              if (_hasAlerts(controller))
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[900]!.withOpacity(
                          0.3 + (_animationController.value * 0.3),
                        ),
                        border: Border(
                          top: BorderSide(color: Colors.red[700]!, width: 2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning, color: Colors.red[300], size: 20),
                              const SizedBox(width: 8),
                              _DotMatrixText(
                                text: 'ALERTS',
                                color: Colors.red[300]!,
                                fontSize: 14,
                                bold: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ..._buildAlerts(controller),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrainEntry(Train train, TerminalStationController controller) {
    final destination = _getTrainDestination(train, controller);
    final eta = _calculateETA(train, controller);
    final status = _getTrainStatus(train);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.5),
        border: Border.all(
          color: train.emergencyBrake ? Colors.red[700]! : Colors.grey[700]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Train ID and Type
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getTrainColor(train.trainType),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: _DotMatrixText(
                  text: 'TRAIN ${train.id}',
                  color: Colors.black,
                  fontSize: 12,
                  bold: true,
                ),
              ),
              const SizedBox(width: 8),
              _DotMatrixText(
                text: train.trainType.name.toUpperCase(),
                color: Colors.grey[500]!,
                fontSize: 10,
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Destination
          Row(
            children: [
              Icon(Icons.place, color: Colors.blue[300], size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: _DotMatrixText(
                  text: 'TO: $destination',
                  color: Colors.blue[300]!,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // ETA
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.green[300], size: 14),
              const SizedBox(width: 4),
              _DotMatrixText(
                text: 'ETA: $eta',
                color: Colors.green[300]!,
                fontSize: 11,
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Status
          Row(
            children: [
              Icon(
                _getStatusIcon(train),
                color: _getStatusColor(train),
                size: 14,
              ),
              const SizedBox(width: 4),
              _DotMatrixText(
                text: status,
                color: _getStatusColor(train),
                fontSize: 11,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAlerts(TerminalStationController controller) {
    final alerts = <Widget>[];

    // Collision alerts
    if (controller.collisionAlarmActive) {
      alerts.add(_buildAlert('COLLISION DETECTED', Colors.red[300]!));
    }

    // Emergency brake alerts
    final emergencyTrains = controller.trains.where((t) => t.emergencyBrake).toList();
    if (emergencyTrains.isNotEmpty) {
      alerts.add(_buildAlert(
        'EMERGENCY BRAKE: ${emergencyTrains.map((t) => t.id).join(", ")}',
        Colors.orange[300]!,
      ));
    }

    // Closed block alerts
    final closedBlocks = controller.closedBlocks.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    if (closedBlocks.isNotEmpty) {
      alerts.add(_buildAlert(
        'CLOSED BLOCKS: ${closedBlocks.join(", ")}',
        Colors.yellow[300]!,
      ));
    }

    // Deadlock alerts
    if (controller.arePointsDeadlocked) {
      alerts.add(_buildAlert('POINT DEADLOCK DETECTED', Colors.red[300]!));
    }

    return alerts;
  }

  Widget _buildAlert(String message, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.circle, color: color, size: 8),
          const SizedBox(width: 8),
          Expanded(
            child: _DotMatrixText(
              text: message,
              color: color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasAlerts(TerminalStationController controller) {
    return controller.collisionAlarmActive ||
        controller.trains.any((t) => t.emergencyBrake) ||
        controller.closedBlocks.values.any((v) => v) ||
        controller.arePointsDeadlocked;
  }

  String _getTrainDestination(Train train, TerminalStationController controller) {
    if (train.smcDestination != null && train.smcDestination!.isNotEmpty) {
      // Parse destination (format: "B:100", "P:Platform 1")
      if (train.smcDestination!.startsWith('B:')) {
        return 'BLOCK ${train.smcDestination!.substring(2)}';
      } else if (train.smcDestination!.startsWith('P:')) {
        return train.smcDestination!.substring(2).toUpperCase();
      }
      return train.smcDestination!.toUpperCase();
    }
    return 'UNKNOWN';
  }

  String _calculateETA(Train train, TerminalStationController controller) {
    if (train.speed == 0) {
      return 'STATIONARY';
    }

    if (train.smcDestination == null || train.smcDestination!.isEmpty) {
      return 'N/A';
    }

    // Simple ETA calculation based on distance and speed
    // This is a rough estimate
    final distance = _calculateDistance(train, controller);
    if (distance < 0) {
      return 'CALCULATING...';
    }

    final etaSeconds = (distance / (train.speed.abs() + 0.1)).ceil();
    if (etaSeconds < 60) {
      return '${etaSeconds}s';
    } else {
      final minutes = (etaSeconds / 60).floor();
      final seconds = etaSeconds % 60;
      return '${minutes}m ${seconds}s';
    }
  }

  double _calculateDistance(Train train, TerminalStationController controller) {
    if (train.smcDestination == null || train.smcDestination!.isEmpty) {
      return -1;
    }

    // Parse destination and calculate distance
    if (train.smcDestination!.startsWith('B:')) {
      final blockId = train.smcDestination!.substring(2);
      final block = controller.blocks[blockId];
      if (block != null) {
        final targetX = (block.startX + block.endX) / 2;
        return (targetX - train.x).abs();
      }
    }

    return -1;
  }

  String _getTrainStatus(Train train) {
    if (train.emergencyBrake) {
      return 'EMERGENCY BRAKE';
    }
    if (train.doorsOpen) {
      return 'DOORS OPEN';
    }
    if (train.speed == 0) {
      return 'STOPPED';
    }
    if (train.controlMode == TrainControlMode.automatic) {
      return 'AUTO (${train.speed.abs().toStringAsFixed(1)} km/h)';
    }
    return 'MANUAL (${train.speed.abs().toStringAsFixed(1)} km/h)';
  }

  IconData _getStatusIcon(Train train) {
    if (train.emergencyBrake) {
      return Icons.warning;
    }
    if (train.doorsOpen) {
      return Icons.door_front_door;
    }
    if (train.speed == 0) {
      return Icons.pause_circle;
    }
    return Icons.play_arrow;
  }

  Color _getStatusColor(Train train) {
    if (train.emergencyBrake) {
      return Colors.red[300]!;
    }
    if (train.doorsOpen) {
      return Colors.orange[300]!;
    }
    if (train.speed == 0) {
      return Colors.yellow[300]!;
    }
    return Colors.green[300]!;
  }

  Color _getTrainColor(TrainType type) {
    switch (type) {
      case TrainType.m1:
        return Colors.blue[400]!;
      case TrainType.m2:
        return Colors.purple[400]!;
      case TrainType.cbtcM1:
        return Colors.cyan[400]!;
      case TrainType.cbtcM2:
        return Colors.teal[400]!;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}

/// Custom dot matrix style text widget
class _DotMatrixText extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;
  final bool bold;

  const _DotMatrixText({
    required this.text,
    required this.color,
    this.fontSize = 12,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: bold ? FontWeight.bold : FontWeight.w500,
        fontFamily: 'Courier',
        letterSpacing: 1.2,
        shadows: [
          Shadow(
            color: color.withOpacity(0.5),
            blurRadius: 2,
          ),
        ],
      ),
    );
  }
}
