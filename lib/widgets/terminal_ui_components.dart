import 'package:flutter/material.dart';
import 'package:rail_champ/screens/terminal_station_models.dart';
import 'dart:math' as math;

// ============================================================================
// TERMINAL UI COMPONENTS
// Reusable UI components for terminal station screen including control panels,
// status displays, and interactive widgets
// ============================================================================

/// Axle Counter Display Widget
class AxleCounterDisplay extends StatelessWidget {
  final String counterId;
  final int count;
  final bool isActive;
  final String? lastDirection;
  final DateTime? lastDetectionTime;

  const AxleCounterDisplay({
    Key? key,
    required this.counterId,
    required this.count,
    this.isActive = false,
    this.lastDirection,
    this.lastDetectionTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
        border: Border.all(
          color: isActive ? Colors.blue : Colors.grey,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            counterId.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12.0,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.blue : Colors.black,
            ),
          ),
          if (lastDirection != null) ...[
            const SizedBox(height: 4.0),
            Text(
              lastDirection!,
              style: const TextStyle(fontSize: 10.0),
            ),
          ],
        ],
      ),
    );
  }
}

/// Signal Aspect Indicator Widget
class SignalAspectIndicator extends StatelessWidget {
  final SignalAspect aspect;
  final double size;
  final bool showLabel;

  const SignalAspectIndicator({
    Key? key,
    required this.aspect,
    this.size = 30.0,
    this.showLabel = false,
  }) : super(key: key);

  Color get aspectColor {
    switch (aspect) {
      case SignalAspect.red:
        return Colors.red;
      case SignalAspect.yellow:
        return Colors.yellow;
      case SignalAspect.doubleYellow:
        return Colors.yellow;
      case SignalAspect.green:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: aspectColor,
            border: Border.all(color: Colors.black, width: 2.0),
            boxShadow: [
              BoxShadow(
                color: aspectColor.withOpacity(0.6),
                blurRadius: 8.0,
                spreadRadius: 2.0,
              ),
            ],
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 4.0),
          Text(
            aspect.toString().split('.').last,
            style: const TextStyle(fontSize: 10.0),
          ),
        ],
      ],
    );
  }
}

/// Block Occupancy Indicator
class BlockOccupancyIndicator extends StatelessWidget {
  final String blockId;
  final bool occupied;
  final int trainCount;
  final VoidCallback? onTap;

  const BlockOccupancyIndicator({
    Key? key,
    required this.blockId,
    required this.occupied,
    this.trainCount = 0,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: occupied ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3),
          border: Border.all(
            color: occupied ? Colors.red : Colors.green,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              occupied ? Icons.train : Icons.check_circle_outline,
              color: occupied ? Colors.red : Colors.green,
              size: 20.0,
            ),
            const SizedBox(width: 8.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  blockId,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.0,
                  ),
                ),
                if (trainCount > 0)
                  Text(
                    '$trainCount train${trainCount > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 10.0),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Route Control Button
class RouteControlButton extends StatelessWidget {
  final String routeId;
  final String routeName;
  final bool isActive;
  final RouteState routeState;
  final VoidCallback? onSet;
  final VoidCallback? onCancel;
  final VoidCallback? onRelease;

  const RouteControlButton({
    Key? key,
    required this.routeId,
    required this.routeName,
    this.isActive = false,
    this.routeState = RouteState.unset,
    this.onSet,
    this.onCancel,
    this.onRelease,
  }) : super(key: key);

  Color get stateColor {
    switch (routeState) {
      case RouteState.set:
        return Colors.green;
      case RouteState.cancelling:
        return Colors.orange;
      case RouteState.unset:
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: stateColor.withOpacity(0.2),
        border: Border.all(color: stateColor, width: 2.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  routeName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.0,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: stateColor,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  routeState.toString().split('.').last.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (!isActive)
                ElevatedButton.icon(
                  onPressed: onSet,
                  icon: const Icon(Icons.play_arrow, size: 16.0),
                  label: const Text('SET'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  ),
                ),
              if (isActive) ...[
                ElevatedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel, size: 16.0),
                  label: const Text('CANCEL'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onRelease,
                  icon: const Icon(Icons.check, size: 16.0),
                  label: const Text('RELEASE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Train Status Display
class TrainStatusDisplay extends StatelessWidget {
  final Train train;
  final VoidCallback? onTap;
  final bool isSelected;

  const TrainStatusDisplay({
    Key? key,
    required this.train,
    this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Container(
              width: 20.0,
              height: 20.0,
              decoration: BoxDecoration(
                color: train.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black),
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    train.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.0,
                    ),
                  ),
                  Text(
                    'VIN: ${train.vin}',
                    style: const TextStyle(fontSize: 10.0, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${train.speed.toStringAsFixed(1)} m/s',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.0,
                  ),
                ),
                Text(
                  train.direction > 0 ? 'Eastbound' : 'Westbound',
                  style: const TextStyle(fontSize: 10.0),
                ),
              ],
            ),
            const SizedBox(width: 8.0),
            Icon(
              train.direction > 0 ? Icons.arrow_forward : Icons.arrow_back,
              color: train.speed > 0 ? Colors.green : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

/// Speed Control Slider
class SpeedControlSlider extends StatelessWidget {
  final double currentSpeed;
  final double maxSpeed;
  final ValueChanged<double>? onChanged;
  final String label;

  const SpeedControlSlider({
    Key? key,
    required this.currentSpeed,
    this.maxSpeed = 3.0,
    this.onChanged,
    this.label = 'Speed',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${currentSpeed.toStringAsFixed(2)} m/s',
              style: const TextStyle(fontSize: 12.0),
            ),
          ],
        ),
        Slider(
          value: currentSpeed,
          min: 0.0,
          max: maxSpeed,
          divisions: 30,
          label: currentSpeed.toStringAsFixed(2),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Event Log Entry Widget
class EventLogEntry extends StatelessWidget {
  final String message;
  final DateTime timestamp;
  final Color? color;

  const EventLogEntry({
    Key? key,
    required this.message,
    required this.timestamp,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: color?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
        border: Border.all(color: color ?? Colors.grey),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Row(
        children: [
          Text(
            '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 10.0,
              color: Colors.grey,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12.0),
            ),
          ),
        ],
      ),
    );
  }
}

/// Collision Alarm Banner
class CollisionAlarmBanner extends StatefulWidget {
  final String message;
  final VoidCallback? onAcknowledge;

  const CollisionAlarmBanner({
    Key? key,
    required this.message,
    this.onAcknowledge,
  }) : super(key: key);

  @override
  State<CollisionAlarmBanner> createState() => _CollisionAlarmBannerState();
}

class _CollisionAlarmBannerState extends State<CollisionAlarmBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Color.lerp(
              Colors.red.withOpacity(0.8),
              Colors.red.withOpacity(0.4),
              _controller.value,
            ),
            border: Border.all(color: Colors.red, width: 3.0),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white, size: 32.0),
              const SizedBox(width: 16.0),
              Expanded(
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (widget.onAcknowledge != null)
                ElevatedButton(
                  onPressed: widget.onAcknowledge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('ACKNOWLEDGE'),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Control Panel Section
class ControlPanelSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool isCollapsible;
  final bool initiallyExpanded;

  const ControlPanelSection({
    Key? key,
    required this.title,
    required this.icon,
    required this.child,
    this.isCollapsible = true,
    this.initiallyExpanded = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isCollapsible) {
      return ExpansionTile(
        title: Row(
          children: [
            Icon(icon, size: 20.0),
            const SizedBox(width: 8.0),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        initiallyExpanded: initiallyExpanded,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: child,
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Icon(icon, size: 20.0),
                const SizedBox(width: 8.0),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: child,
          ),
        ],
      );
    }
  }
}

/// Point Position Switch Widget
class PointPositionSwitch extends StatelessWidget {
  final String pointId;
  final PointPosition position;
  final ValueChanged<PointPosition>? onChanged;
  final bool enabled;

  const PointPositionSwitch({
    Key? key,
    required this.pointId,
    required this.position,
    this.onChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Text(
            pointId,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPositionButton(
                context,
                PointPosition.normal,
                'NORMAL',
                Colors.green,
              ),
              _buildPositionButton(
                context,
                PointPosition.reverse,
                'REVERSE',
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPositionButton(
    BuildContext context,
    PointPosition targetPosition,
    String label,
    Color color,
  ) {
    final isSelected = position == targetPosition;

    return ElevatedButton(
      onPressed: enabled ? () => onChanged?.call(targetPosition) : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.grey.shade300,
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }
}
