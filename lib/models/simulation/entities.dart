import 'package:flutter/material.dart';

// ============================================================================
// SIMULATION DATA MODELS
// ============================================================================

class Train {
  final String id;
  final String name;
  double x;
  double y;
  double speed;
  double maxSpeed;
  Color color;
  bool isMoving;
  String? currentBlockId;
  String? targetPlatformId;
  bool atPlatform;
  int platformStopTime; // seconds
  bool hasStoppedAtSignal;

  Train({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    this.speed = 0,
    this.maxSpeed = 2.0,
    this.color = Colors.blue,
    this.isMoving = false,
    this.currentBlockId,
    this.targetPlatformId,
    this.atPlatform = false,
    this.platformStopTime = 0,
    this.hasStoppedAtSignal = false,
  });
}

class BlockSection {
  final String id;
  final double startX;
  final double endX;
  final double y;
  bool occupied;
  String? occupyingTrainId;
  bool isOverlapBlock; // For safety overlap protection

  BlockSection({
    required this.id,
    required this.startX,
    required this.endX,
    required this.y,
    this.occupied = false,
    this.occupyingTrainId,
    this.isOverlapBlock = false,
  });

  bool containsPosition(double x) {
    return x >= startX && x <= endX;
  }
}

class Signal {
  final String id;
  final double x;
  final double y;
  SignalAspect aspect;
  String protectsBlockId; // The block this signal protects
  String? overlapBlockId; // Overlap block for safety

  Signal({
    required this.id,
    required this.x,
    required this.y,
    this.aspect = SignalAspect.red,
    required this.protectsBlockId,
    this.overlapBlockId,
  });
}

enum SignalAspect {
  red,   // Stop - block ahead occupied
  green, // Proceed - block ahead clear
}

class Platform {
  final String id;
  final String name;
  final double startX;
  final double endX;
  final double y;
  bool occupied;
  String? occupyingTrainId;

  Platform({
    required this.id,
    required this.name,
    required this.startX,
    required this.endX,
    required this.y,
    this.occupied = false,
    this.occupyingTrainId,
  });

  double get centerX => (startX + endX) / 2;

  bool containsPosition(double x) {
    return x >= startX && x <= endX;
  }
}
