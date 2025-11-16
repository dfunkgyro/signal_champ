import 'package:flutter/material.dart';
import 'enums.dart';
import 'movement_authority.dart';

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
