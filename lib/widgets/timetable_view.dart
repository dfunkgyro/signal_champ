import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/terminal_station_controller.dart';
import '../screens/terminal_station_models.dart';

/// Scrollable timetable visualization
class TimetableView extends StatefulWidget {
  const TimetableView({Key? key}) : super(key: key);

  @override
  State<TimetableView> createState() => _TimetableViewState();
}

class _TimetableViewState extends State<TimetableView> {
  final ScrollController _scrollController = ScrollController();
  int _selectedTimeSlot = 0;
  final int _minutesPerSlot = 5;
  final int _totalSlots = 288; // 24 hours * 60 minutes / 5 minutes per slot

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TerminalStationController>(
      builder: (context, controller, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[700]!, width: 2),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[800],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'TIMETABLE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTime(controller.currentTime),
                      style: TextStyle(
                        color: Colors.green[300],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Time ruler
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[700]!, width: 1),
                  ),
                ),
                child: _buildTimeRuler(controller),
              ),

              // Timetable content
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  children: [
                    if (controller.trains.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'No trains scheduled',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    else
                      ..._buildTrainRows(controller),
                  ],
                ),
              ),

              // Footer with controls
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      color: Colors.white,
                      onPressed: () {
                        setState(() {
                          _selectedTimeSlot = (_selectedTimeSlot - 1).clamp(0, _totalSlots - 1);
                        });
                      },
                    ),
                    Text(
                      'Time: ${_getTimeSlotLabel(_selectedTimeSlot)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      color: Colors.white,
                      onPressed: () {
                        setState(() {
                          _selectedTimeSlot = (_selectedTimeSlot + 1).clamp(0, _totalSlots - 1);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeRuler(TerminalStationController controller) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 24,
      itemBuilder: (context, hour) {
        final isCurrentHour = controller.currentTime.hour == hour;
        return Container(
          width: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: Colors.grey[700]!, width: 1),
            ),
            color: isCurrentHour ? Colors.blue[900]!.withOpacity(0.3) : null,
          ),
          child: Text(
            '${hour.toString().padLeft(2, '0')}:00',
            style: TextStyle(
              color: isCurrentHour ? Colors.blue[300] : Colors.grey[400],
              fontSize: 12,
              fontWeight: isCurrentHour ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildTrainRows(TerminalStationController controller) {
    return controller.trains.map((train) {
      return _buildTrainRow(train, controller);
    }).toList();
  }

  Widget _buildTrainRow(Train train, TerminalStationController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: train.emergencyBrake ? Colors.red : Colors.grey[700]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Train info
          Container(
            width: 100,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getTrainColor(train.type).withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Train ${train.id}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  train.type.name.toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // Timeline
          Expanded(
            child: Container(
              height: 50,
              padding: const EdgeInsets.all(8),
              child: _buildTrainTimeline(train, controller),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainTimeline(Train train, TerminalStationController controller) {
    // Calculate train's position on the timeline
    final currentHour = controller.currentTime.hour;
    final currentMinute = controller.currentTime.minute;

    // Estimate journey start (simplified - assumes train started at beginning of current hour)
    final startHour = (currentHour - 1).clamp(0, 23);

    // Estimate journey duration (simplified - based on speed and distance)
    final duration = train.speed > 0 ? 2 : 1; // hours

    return CustomPaint(
      painter: _TimelinePainter(
        startHour: startHour,
        duration: duration,
        color: _getTrainColor(train.type),
        isActive: train.speed > 0,
        isEmergency: train.emergencyBrake,
        currentHour: currentHour,
        currentMinute: currentMinute,
      ),
    );
  }

  Color _getTrainColor(TrainType type) {
    switch (type) {
      case TrainType.m1:
        return Colors.blue;
      case TrainType.m2:
        return Colors.purple;
      case TrainType.cbtcM1:
        return Colors.cyan;
      case TrainType.cbtcM2:
        return Colors.teal;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _getTimeSlotLabel(int slot) {
    final minutes = slot * _minutesPerSlot;
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

/// Custom painter for train timeline
class _TimelinePainter extends CustomPainter {
  final int startHour;
  final int duration;
  final Color color;
  final bool isActive;
  final bool isEmergency;
  final int currentHour;
  final int currentMinute;

  _TimelinePainter({
    required this.startHour,
    required this.duration,
    required this.color,
    required this.isActive,
    required this.isEmergency,
    required this.currentHour,
    required this.currentMinute,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final hourWidth = size.width / 24;

    // Draw background grid
    final gridPaint = Paint()
      ..color = Colors.grey[700]!.withOpacity(0.3)
      ..strokeWidth = 1;

    for (int i = 0; i <= 24; i++) {
      final x = i * hourWidth;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    // Draw train timeline bar
    final startX = startHour * hourWidth;
    final endX = (startHour + duration) * hourWidth;
    final barHeight = size.height * 0.6;
    final barY = (size.height - barHeight) / 2;

    final barPaint = Paint()
      ..color = isEmergency
          ? Colors.red.withOpacity(0.7)
          : color.withOpacity(isActive ? 0.7 : 0.3)
      ..style = PaintingStyle.fill;

    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(startX, barY, endX - startX, barHeight),
      const Radius.circular(4),
    );
    canvas.drawRRect(barRect, barPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = isEmergency ? Colors.red : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(barRect, borderPaint);

    // Draw current time indicator
    final currentX = (currentHour + currentMinute / 60) * hourWidth;
    final indicatorPaint = Paint()
      ..color = Colors.green[400]!
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(currentX, 0),
      Offset(currentX, size.height),
      indicatorPaint,
    );
  }

  @override
  bool shouldRepaint(_TimelinePainter oldDelegate) {
    return oldDelegate.currentHour != currentHour ||
        oldDelegate.currentMinute != currentMinute ||
        oldDelegate.isActive != isActive ||
        oldDelegate.isEmergency != isEmergency;
  }
}
