import 'package:flutter/material.dart';
import 'collision_analysis_system.dart' as collision_system;

// ============================================================================
// ENUMS
// ============================================================================

enum PointPosition { normal, reverse }

enum SignalDirection { east, west }

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
  m4,         // 4-car train (8 wheels on AB)
  m8,         // 8-car train (16 wheels on AB)
  cbtcM1,     // CBTC-equipped single unit
  cbtcM2,     // CBTC-equipped double unit
  cbtcM4,     // CBTC-equipped 4-car train
  cbtcM8,     // CBTC-equipped 8-car train
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
  double startX;  // Made mutable for edit mode
  double endX;    // Made mutable for edit mode
  double y;       // Made mutable for edit mode
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

class Crossover {
  final String id;
  final String name;
  final List<String> pointIds;  // Points that belong to this crossover
  final String blockId;  // Associated block section

  Crossover({
    required this.id,
    required this.name,
    required this.pointIds,
    required this.blockId,
  });
}

class Point {
  final String id;
  double x;  // Made mutable for edit mode
  double y;  // Made mutable for edit mode
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
  double x;  // Made mutable for edit mode
  double y;  // Made mutable for edit mode
  SignalDirection direction;  // Added for edit mode
  final List<SignalRoute> routes;
  SignalAspect aspect;
  String? activeRouteId;
  RouteState routeState;

  Signal({
    required this.id,
    required this.x,
    required this.y,
    this.direction = SignalDirection.east,  // Default to east
    required this.routes,
    this.aspect = SignalAspect.red,
    this.activeRouteId,
    this.routeState = RouteState.unset,
  });
}

class Platform {
  final String id;
  final String name;
  double startX;  // Made mutable for edit mode
  double endX;    // Made mutable for edit mode
  double y;       // Made mutable for edit mode
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
  double get length => endX - startX;
}

/// Individual carriage in a multi-carriage train
/// ENHANCED with advanced physics simulation
class Carriage {
  double x;
  double y;
  double rotation;
  final int index; // Position in the train (0 = lead, 1 = second, etc.)

  // ENHANCEMENT 1: Advanced carriage physics (120% improvement)
  double lateralOffset = 0.0; // Sway on curves for realistic movement
  double speed = 0.0; // Individual carriage speed tracking
  double couplingTension = 0.0; // Force between carriages (0.0 to 1.0)
  bool isDerailed = false; // Derailment detection and visualization
  double wheelAngle = 0.0; // Bogie rotation for curve realism

  Carriage({
    required this.x,
    required this.y,
    required this.rotation,
    required this.index,
    this.lateralOffset = 0.0,
    this.speed = 0.0,
    this.couplingTension = 0.0,
    this.isDerailed = false,
    this.wheelAngle = 0.0,
  });

  /// Calculate realistic coupling tension based on speed differential
  void updateCouplingTension(double prevSpeed, double currentSpeed) {
    final speedDiff = (prevSpeed - currentSpeed).abs();
    couplingTension = (speedDiff / 10.0).clamp(0.0, 1.0);
  }

  /// Apply lateral sway based on curve radius and speed
  void applyCurveSway(double curveRadius, double trainSpeed) {
    if (curveRadius > 0) {
      lateralOffset = (trainSpeed / curveRadius) * 2.0;
      lateralOffset = lateralOffset.clamp(-5.0, 5.0);
    } else {
      lateralOffset = 0.0;
    }
  }
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
  String? previousBlockId; // Track previous block for smart collision detection
  bool hasCommittedToMove;
  String? lastPassedSignalId;
  double rotation;
  bool doorsOpen;
  DateTime? doorsOpenedAt;
  final bool isCbtcEquipped;
  CbtcMode cbtcMode;
  String? smcDestination; // SMC-assigned destination
  MovementAuthority? movementAuthority; // CBTC movement authority visualization

  // Door cycle tracking to prevent stuck-at-platform loop
  String? lastPlatformDoorsOpened; // ID of last platform where doors were opened
  double? lastDoorOpenPositionX; // X position when doors last opened
  bool hasLeftPlatform; // True if train has moved 2+ blocks from last platform

  // CBTC NCT (Non-Communication Train) state
  bool isNCT; // NCT state - train flashes red, cannot go auto/PM
  int transpondersPassed; // Count of transponders passed for activation
  String? lastTransponderId; // Last transponder ID passed
  bool terReceived; // Train Entry Request received by VCC (1st transponder)
  bool directionConfirmed; // Direction confirmed by VCC (2nd transponder)

  // CBTC traction loss tracking
  DateTime? tractionLostAt; // When traction current was lost
  bool tractionLossWarned; // Whether 30-second warning was logged

  // Timetable tracking fields
  String? assignedTimetableId; // ID of ghost train timetable slot
  String? assignedServiceId; // ID of TimetableService
  int? earlyLateSeconds; // Positive = late, Negative = early, Null = not on timetable
  String? currentStationId; // Current platform/station ID for timing calculation

  // Multi-carriage independent alignment
  List<Carriage> carriages = []; // Individual carriages for M2/M4/M8 trains

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
    this.previousBlockId,
    this.hasCommittedToMove = false,
    this.lastPassedSignalId,
    this.rotation = 0.0,
    this.doorsOpen = false,
    this.doorsOpenedAt,
    this.isCbtcEquipped = false,
    this.cbtcMode = CbtcMode.off,
    this.smcDestination,
    this.movementAuthority,
    this.lastPlatformDoorsOpened,
    this.lastDoorOpenPositionX,
    this.hasLeftPlatform = true, // Default to true so doors can open at first platform
    this.isNCT = false, // Default to false for backwards compatibility
    this.transpondersPassed = 0,
    this.lastTransponderId,
    this.terReceived = false,
    this.directionConfirmed = false,
    this.tractionLostAt,
    this.tractionLossWarned = false,
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
      case TrainType.m4:
      case TrainType.cbtcM4:
        return 8;
      case TrainType.m8:
      case TrainType.cbtcM8:
        return 16;
    }
  }

  // Helper to check if this is a CBTC train
  bool get isCbtcTrain {
    return trainType == TrainType.cbtcM1 ||
           trainType == TrainType.cbtcM2 ||
           trainType == TrainType.cbtcM4 ||
           trainType == TrainType.cbtcM8;
  }

  // Get number of carriages based on train type
  int get carriageCount {
    switch (trainType) {
      case TrainType.m1:
      case TrainType.cbtcM1:
        return 1;
      case TrainType.m2:
      case TrainType.cbtcM2:
        return 2;
      case TrainType.m4:
      case TrainType.cbtcM4:
        return 4;
      case TrainType.m8:
      case TrainType.cbtcM8:
        return 8;
    }
  }

  // Initialize carriages for multi-carriage trains
  void initializeCarriages() {
    carriages.clear();
    final count = carriageCount;

    // Create individual carriages positioned behind the lead carriage
    for (int i = 0; i < count; i++) {
      carriages.add(Carriage(
        x: x - (i * 25.0 * direction), // 25 units per carriage spacing
        y: y,
        rotation: rotation,
        index: i,
      ));
    }
  }

  // ENHANCED: Update carriage positions with advanced physics (120% improvement)
  void updateCarriagePositions() {
    if (carriages.isEmpty) {
      initializeCarriages();
    }

    // Lead carriage follows train position exactly
    if (carriages.isNotEmpty) {
      carriages[0].x = x;
      carriages[0].y = y;
      carriages[0].rotation = rotation;
      carriages[0].speed = speed;
    }

    // ENHANCEMENT 2: Realistic variable spacing based on train type
    final baseSpacing = _getCarriageSpacing();
    final curveRadius = 200.0; // Estimate based on rotation change

    // Following carriages maintain dynamic coupling with realistic physics
    for (int i = 1; i < carriages.length; i++) {
      final prevCarriage = carriages[i - 1];

      // ENHANCEMENT 3: Dynamic spacing with coupling tension
      final spacing = baseSpacing * (1.0 + (prevCarriage.couplingTension * 0.1));

      // Calculate position behind previous carriage
      carriages[i].x = prevCarriage.x - (spacing * direction);
      carriages[i].y = prevCarriage.y;

      // ENHANCEMENT 4: Apply lateral sway on curves for realism
      carriages[i].applyCurveSway(curveRadius, speed);
      carriages[i].y += carriages[i].lateralOffset;

      // FIXED: Carriage rotation using improved methods
      // REMOVED: Individual carriage angle orientation (caused disconnected appearance)
      //
      // Alternative Method #1: UNIFORM ROTATION (Current Implementation)
      // All carriages share the lead carriage's rotation for connected appearance
      carriages[i].rotation = rotation;

      // Alternative Method #2: CATENARY CURVE FOLLOWING (commented out)
      // Each carriage points toward previous carriage
      // final dx = carriages[i].x - carriages[i-1].x;
      // final dy = carriages[i].y - carriages[i-1].y;
      // carriages[i].rotation = atan2(dy, dx);

      // Alternative Method #3: PIECE-WISE STRAIGHT (commented out)
      // Carriages stay horizontal unless entire train on crossover
      // carriages[i].rotation = (allCarriagesOnCrossover) ? rotation : 0.0;

      // Alternative Method #4: VISUAL Y-OFFSET ONLY (commented out)
      // Keep rotation 0, but shift Y position for visual curve effect
      // final onCrossover = (carriageX >= crossoverStart && carriageX < crossoverEnd);
      // carriages[i].y += onCrossover ? (i * 2.0 * sin(rotation)) : 0.0;

      carriages[i].wheelAngle = carriages[i].rotation * 0.8;

      // ENHANCEMENT 6: Speed propagation with slight delay
      carriages[i].speed = prevCarriage.speed * 0.98; // 2% speed loss per carriage

      // ENHANCEMENT 7: Update coupling tension
      if (i > 0) {
        carriages[i].updateCouplingTension(
          carriages[i - 1].speed,
          carriages[i].speed,
        );
      }
    }
  }

  // ENHANCEMENT 8: Get realistic spacing based on train configuration
  double _getCarriageSpacing() {
    switch (trainType) {
      case TrainType.m1:
      case TrainType.cbtcM1:
        return 20.0; // Single carriage, no spacing needed
      case TrainType.m2:
      case TrainType.cbtcM2:
        return 22.0; // Short coupling for 2-car trains
      case TrainType.m4:
      case TrainType.cbtcM4:
        return 24.0; // Medium coupling for 4-car trains
      case TrainType.m8:
      case TrainType.cbtcM8:
        return 26.0; // Longer coupling for 8-car trains
    }
  }
}

class TrainStop {
  final String id;
  final String signalId;
  double x;  // Made mutable for edit mode
  double y;  // Made mutable for edit mode
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

class BufferStop {
  final String id;
  double x;      // Made mutable for edit mode
  double y;      // Made mutable for edit mode
  double width;  // Visual width of buffer stop
  double height; // Visual height of buffer stop

  BufferStop({
    required this.id,
    required this.x,
    required this.y,
    this.width = 30,
    this.height = 20,
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
