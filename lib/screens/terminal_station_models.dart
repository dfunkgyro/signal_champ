import 'package:flutter/material.dart';
import 'collision_analysis_system.dart' as collision_system;

// ============================================================================
// ENUMS
// ============================================================================

enum PointPosition { normal, reverse }

enum SignalAspect { red, green, blue }

enum RouteState { unset, setting, set, releasing }

enum TrainControlMode { automatic, manual }

enum CollisionRecoveryState {
  none,
  detected,
  recovery,
  resolved,
  manualOverride
}

enum ReleaseState { inactive, counting, completed }

enum CbtcMode {
  auto,      // Automatic mode - cyan
  pm,        // Protective Manual mode - orange
  rm,        // Restrictive Manual mode - brown
  off,       // Off mode - white
  storage    // Storage mode - green
}

enum TrainType {
  m1,         // Single train unit (2 wheels on AB)
  m2,         // Double train unit (4 wheels on AB)
  cbtcM1,     // CBTC-equipped single unit
  cbtcM2,     // CBTC-equipped double unit
}

// ============================================================================
// MODELS
// ============================================================================

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

class BlockSection {
  final String id;
  final String? name;  // Optional display name for crossovers and special sections
  final double startX;
  final double endX;
  final double y;
  bool occupied;
  String? occupyingTrainId;

  BlockSection({
    required this.id,
    this.name,
    required this.startX,
    required this.endX,
    required this.y,
    this.occupied = false,
    this.occupyingTrainId,
  });

  bool containsPosition(double x, double y) {
    return x >= startX && x <= endX && (this.y - y).abs() < 50;
  }

  double get centerX => startX + (endX - startX) / 2;
}

class Point {
  final String id;
  final double x;
  final double y;
  PointPosition position;
  bool locked;
  bool lockedByAB;

  Point({
    required this.id,
    required this.x,
    required this.y,
    this.position = PointPosition.normal,
    this.locked = false,
    this.lockedByAB = false,
  });
}

class SignalRoute {
  final String id;
  final String name;
  final List<String> requiredBlocksClear;
  final Map<String, PointPosition> requiredPointPositions;
  final List<String> conflictingRoutes;
  final List<String> pathBlocks;
  final List<String> protectedBlocks;

  SignalRoute({
    required this.id,
    required this.name,
    required this.requiredBlocksClear,
    required this.requiredPointPositions,
    this.conflictingRoutes = const [],
    required this.pathBlocks,
    required this.protectedBlocks,
  });
}

class Signal {
  final String id;
  final double x;
  final double y;
  final List<SignalRoute> routes;
  SignalAspect aspect;
  String? activeRouteId;
  RouteState routeState;

  Signal({
    required this.id,
    required this.x,
    required this.y,
    required this.routes,
    this.aspect = SignalAspect.red,
    this.activeRouteId,
    this.routeState = RouteState.unset,
  });
}

class Platform {
  final String id;
  final String name;
  final double startX;
  final double endX;
  final double y;
  bool occupied;

  Platform({
    required this.id,
    required this.name,
    required this.startX,
    required this.endX,
    required this.y,
    this.occupied = false,
  });

  double get centerX => startX + (endX - startX) / 2;
}

class Train {
  final String id;
  final String name;
  final String vin; // Vehicle Identification Number
  final TrainType trainType; // Type of train (M1, M2, CBTC M1, CBTC M2)
  double x;
  double y;
  double speed;
  double targetSpeed;
  int direction;
  Color color;
  TrainControlMode controlMode;
  bool manualStop;
  bool emergencyBrake;
  String? currentBlockId;
  bool hasCommittedToMove;
  String? lastPassedSignalId;
  double rotation;
  bool doorsOpen;
  DateTime? doorsOpenedAt;
  final bool isCbtcEquipped;
  CbtcMode cbtcMode;
  String? smcDestination; // SMC-assigned destination
  MovementAuthority? movementAuthority; // CBTC movement authority visualization

  // Timetable tracking fields
  String? assignedTimetableId; // ID of ghost train timetable slot
  String? assignedServiceId; // ID of TimetableService
  int? earlyLateSeconds; // Positive = late, Negative = early, Null = not on timetable
  String? currentStationId; // Current platform/station ID for timing calculation

  Train({
    required this.id,
    required this.name,
    required this.vin,
    this.trainType = TrainType.m1, // Default to M1
    required this.x,
    required this.y,
    required this.speed,
    required this.targetSpeed,
    required this.direction,
    required this.color,
    required this.controlMode,
    this.manualStop = false,
    this.emergencyBrake = false,
    this.currentBlockId,
    this.hasCommittedToMove = false,
    this.lastPassedSignalId,
    this.rotation = 0.0,
    this.doorsOpen = false,
    this.doorsOpenedAt,
    this.isCbtcEquipped = false,
    this.cbtcMode = CbtcMode.off,
    this.smcDestination,
    this.movementAuthority,
    this.assignedTimetableId,
    this.assignedServiceId,
    this.earlyLateSeconds,
    this.currentStationId,
  });

  // Helper to get wheel count based on train type
  int get wheelCount {
    switch (trainType) {
      case TrainType.m1:
      case TrainType.cbtcM1:
        return 2;
      case TrainType.m2:
      case TrainType.cbtcM2:
        return 4;
    }
  }

  // Helper to check if this is a CBTC train
  bool get isCbtcTrain {
    return trainType == TrainType.cbtcM1 || trainType == TrainType.cbtcM2;
  }
}

class TrainStop {
  final String id;
  final String signalId;
  final double x;
  final double y;
  bool enabled;
  bool active;

  TrainStop({
    required this.id,
    required this.signalId,
    required this.x,
    required this.y,
    this.enabled = true,
    this.active = false,
  });
}

class RouteReservation {
  final String id;
  final String signalId;
  final String trainId;
  final List<String> reservedBlocks;
  final DateTime createdAt;

  RouteReservation({
    required this.id,
    required this.signalId,
    required this.trainId,
    required this.reservedBlocks,
    required this.createdAt,
  });

  Color get reservationColor => Colors.yellow;
}

class CollisionIncident {
  final String id;
  final DateTime timestamp;
  final List<String> trainsInvolved;
  final String location;
  final collision_system.CollisionSeverity severity;
  final List<collision_system.CollisionCause> rootCauses;
  final collision_system.Responsibility responsibility;
  final String specificParty;
  final List<CollisionEvent> leadingEvents;
  final Map<String, dynamic> systemStateAtCollision;
  final List<String> preventionRecommendations;
  final String forensicSummary;

  CollisionIncident({
    required this.id,
    required this.timestamp,
    required this.trainsInvolved,
    required this.location,
    required this.severity,
    required this.rootCauses,
    required this.responsibility,
    required this.specificParty,
    required this.leadingEvents,
    required this.systemStateAtCollision,
    required this.preventionRecommendations,
    required this.forensicSummary,
  });
}

class CollisionEvent {
  final String trainId;
  final DateTime timestamp;
  final String description;
  final String location;
  final double trainSpeed;
  final Map<String, dynamic> systemState;

  CollisionEvent({
    required this.trainId,
    required this.timestamp,
    required this.description,
    required this.location,
    required this.trainSpeed,
    required this.systemState,
  });
}

class CollisionRecoveryPlan {
  final String collisionId;
  final List<String> trainsInvolved;
  final Map<String, String> reverseInstructions;
  final List<String> blocksToClear;
  final DateTime detectedAt;
  DateTime? resolvedAt;
  CollisionRecoveryState state;
  int recoveryProgressSeconds = 0;
  final Map<String, double> collisionPositions; // Store X position where each train collided
  final Map<String, double> targetRecoveryPositions; // Target position 20 units back

  CollisionRecoveryPlan({
    required this.collisionId,
    required this.trainsInvolved,
    required this.reverseInstructions,
    required this.blocksToClear,
    required this.state,
    Map<String, double>? collisionPositions,
    Map<String, double>? targetRecoveryPositions,
  }) : detectedAt = DateTime.now(),
       collisionPositions = collisionPositions ?? {},
       targetRecoveryPositions = targetRecoveryPositions ?? {};
}

// ============================================================================
// TIMETABLE MODELS
// ============================================================================

class TimetableService {
  final String id;
  final String trainName;
  final TrainType trainType;
  final String startBlock;
  final String endBlock;
  final List<String> stops; // Block IDs where train stops
  final DateTime scheduledTime;
  bool isCompleted;
  String? assignedTrainId;

  TimetableService({
    required this.id,
    required this.trainName,
    required this.trainType,
    required this.startBlock,
    required this.endBlock,
    required this.stops,
    required this.scheduledTime,
    this.isCompleted = false,
    this.assignedTrainId,
  });
}

class Timetable {
  final List<TimetableService> services;
  bool isActive;

  Timetable({
    required this.services,
    this.isActive = false,
  });
}

// ============================================================================
// GHOST TRAIN MODELS
// ============================================================================

class GhostTrain {
  final String id;
  final String serviceId; // Associated TimetableService ID
  final String name;
  final TrainType trainType;
  double x; // Current position (invisible to user)
  double y;
  double speed;
  int direction;
  String? currentBlockId;
  String? currentPlatformId;
  DateTime? platformArrivalTime; // When ghost train arrived at current platform
  bool doorsOpen;
  DateTime? doorsOpenedAt;
  List<String> remainingStops; // Platforms still to visit
  bool hasCompletedService;
  String? assignedRealTrainId; // ID of real train assigned to this slot

  // Scheduled timing for each platform
  Map<String, DateTime> scheduledPlatformTimes; // platformId -> scheduled arrival time

  GhostTrain({
    required this.id,
    required this.serviceId,
    required this.name,
    required this.trainType,
    required this.x,
    required this.y,
    required this.speed,
    required this.direction,
    this.currentBlockId,
    this.currentPlatformId,
    this.platformArrivalTime,
    this.doorsOpen = false,
    this.doorsOpenedAt,
    required this.remainingStops,
    this.hasCompletedService = false,
    this.assignedRealTrainId,
    required this.scheduledPlatformTimes,
  });

  // Check if ghost train is available for assignment
  bool get isAvailable => assignedRealTrainId == null && !hasCompletedService;

  // Calculate early/late seconds at current platform
  int? getEarlyLateSeconds() {
    if (currentPlatformId == null || platformArrivalTime == null) return null;
    final scheduled = scheduledPlatformTimes[currentPlatformId];
    if (scheduled == null) return null;
    return platformArrivalTime!.difference(scheduled).inSeconds;
  }
}
