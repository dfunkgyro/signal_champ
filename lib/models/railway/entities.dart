import 'package:flutter/material.dart';
import 'enums.dart';

// ============================================================================
// RAILWAY ENTITIES
// ============================================================================

class Transponder {
  final String id;
  final TransponderType type;
  final double x;
  final double y;
  final String description;

  Transponder({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.description,
  });
}

class WifiAntenna {
  final String id;
  final double x;
  final double y;
  final bool isActive;

  WifiAntenna({
    required this.id,
    required this.x,
    required this.y,
    this.isActive = true,
  });
}

class BlockSection {
  final String id;
  final double startX;
  final double endX;
  final double y;
  final String? nextBlock;
  final String? prevBlock;
  bool occupied;
  final bool isCrossover;
  final bool isReversingArea;
  bool closedBySmc; // SMC track closure status

  BlockSection({
    required this.id,
    required this.startX,
    required this.endX,
    required this.y,
    this.nextBlock,
    this.prevBlock,
    this.occupied = false,
    this.isCrossover = false,
    this.isReversingArea = false,
    this.closedBySmc = false,
  });
}

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

class Point {
  final String id;
  final double x;
  final double y;
  PointPosition position;
  double animationProgress;
  String? reservedByVin; // VIN of train that has reserved this point
  String? reservedDestination; // Destination of reserving train

  Point({
    required this.id,
    required this.x,
    required this.y,
    this.position = PointPosition.normal,
    this.animationProgress = 0.0,
    this.reservedByVin,
    this.reservedDestination,
  });
}

class MovementAuthority {
  final double maxDistance; // Maximum distance the green arrow extends
  final String? limitReason; // Why the arrow stopped (obstacle, destination, etc.)
  final bool hasDestination; // Whether train has a destination

  MovementAuthority({
    required this.maxDistance,
    this.limitReason,
    this.hasDestination = false,
  });
}

class Train {
  final String id;
  final String name;
  final String vin; // Vehicle Identification Number
  double x;
  double y;
  double speed;
  String currentBlock;
  TrainStatus status;
  bool isSelected;
  DateTime? estimatedArrival;
  Direction direction;
  double progress;
  Color color;
  double angle;
  List<String> routeHistory;
  String stopReason;
  DateTime? lastStatusChange;
  final bool isCbtcEquipped;
  CbtcMode cbtcMode;
  String? smcDestination; // SMC-assigned destination (block ID or platform name)
  MovementAuthority? movementAuthority; // CBTC movement authority visualization

  Train({
    required this.id,
    required this.name,
    required this.vin,
    required this.x,
    required this.y,
    required this.speed,
    required this.currentBlock,
    this.status = TrainStatus.moving,
    this.isSelected = false,
    this.estimatedArrival,
    this.direction = Direction.east,
    this.progress = 0.0,
    required this.color,
    this.angle = 0.0,
    this.routeHistory = const [],
    this.stopReason = '',
    this.lastStatusChange,
    this.isCbtcEquipped = false,
    this.cbtcMode = CbtcMode.off,
    this.smcDestination,
    this.movementAuthority,
  });
}
