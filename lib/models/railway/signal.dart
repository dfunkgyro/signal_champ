import 'enums.dart';

class Signal {
  final String id;
  final double x;
  final double y;
  SignalState state;
  int? route;
  final List<String> controlledBlocks;
  final List<String> requiredPointPositions;
  String lastStateChangeReason;

  Signal({
    required this.id,
    required this.x,
    required this.y,
    this.state = SignalState.red,
    this.route,
    required this.controlledBlocks,
    this.requiredPointPositions = const [],
    this.lastStateChangeReason = '',
  });
}
