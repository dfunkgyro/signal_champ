import 'package:flutter/material.dart';
import 'collision_analysis_system.dart' as collision_system;

// ============================================================================
// ENUMS
// ============================================================================

enum PointPosition { normal, reverse }

enum SignalAspect { red, green }

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
  sb,        // Stand By mode - yellow
  ism,       // Isolated Station Mode - purple
  csm,       // Cut Section Mode - red
  off,       // Off mode - white
  storage    // Storage mode - green
}

// MA1, MA2, MA3 - Movement Authority Levels
enum MALevel {
  ma1,  // Primary Movement Authority - Full ATP protection
  ma2,  // Secondary Movement Authority - Reduced speed with warning
  ma3,  // Emergency Movement Authority - Minimal safe distance
}

// ATP (Automatic Train Protection) States
enum ATPState {
  normal,           // Normal operation
  warning,          // Approaching limit
  intervention,     // ATP applying brakes
  emergency,        // Emergency brake applied
  override,         // Driver override (restricted)
}

// ============================================================================
// MODELS
// ============================================================================

// MA1, MA2, MA3 - Enhanced Movement Authority with ATP
class MovementAuthority {
  final double maxDistance; // Maximum distance the green arrow extends
  final String? limitReason; // Why the arrow stopped (obstacle, destination, etc.)
  final bool hasDestination; // Whether train has a destination

  // MA1, MA2, MA3 Enhanced Features
  final MALevel level; // MA level: MA1 (full), MA2 (reduced), MA3 (emergency)
  final double targetSpeed; // Target speed at this MA
  final double brakingDistance; // Safe braking distance
  final Map<double, double> speedProfile; // Distance -> Max Speed mapping
  final double gradientCompensation; // Grade compensation factor
  final bool atpEnforced; // Whether ATP is actively enforcing this MA

  MovementAuthority({
    required this.maxDistance,
    this.limitReason,
    this.hasDestination = false,
    this.level = MALevel.ma1,
    this.targetSpeed = 0.0,
    this.brakingDistance = 200.0,
    this.speedProfile = const {},
    this.gradientCompensation = 0.0,
    this.atpEnforced = true,
  });

  // Calculate safe speed at given distance
  double getSafeSpeedAt(double distance) {
    if (speedProfile.isEmpty) {
      return targetSpeed;
    }

    // Find closest speed profile point
    double closestDist = maxDistance;
    double safeSpeed = targetSpeed;

    for (var entry in speedProfile.entries) {
      if (distance <= entry.key && entry.key < closestDist) {
        closestDist = entry.key;
        safeSpeed = entry.value;
      }
    }

    return safeSpeed;
  }

  // Check if speed is safe for current distance to MA limit
  bool isSpeedSafe(double currentSpeed, double distanceToLimit) {
    double safeSpeed = getSafeSpeedAt(distanceToLimit);
    return currentSpeed <= safeSpeed;
  }
}

class BlockSection {
  final String id;
  final double startX;
  final double endX;
  final double y;
  bool occupied;
  String? occupyingTrainId;

  BlockSection({
    required this.id,
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

  // MA1, MA2, MA3 Enhanced Features
  ATPState atpState; // Current ATP state
  MovementAuthority? ma1; // Primary Movement Authority
  MovementAuthority? ma2; // Secondary Movement Authority (fallback)
  MovementAuthority? ma3; // Emergency Movement Authority (last resort)
  double maxAllowedSpeed; // Maximum speed allowed by track/signal
  double gradePercentage; // Current track grade (positive = uphill)

  Train({
    required this.id,
    required this.name,
    required this.vin,
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
    this.atpState = ATPState.normal,
    this.ma1,
    this.ma2,
    this.ma3,
    this.maxAllowedSpeed = 80.0,
    this.gradePercentage = 0.0,
  });
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

  CollisionRecoveryPlan({
    required this.collisionId,
    required this.trainsInvolved,
    required this.reverseInstructions,
    required this.blocksToClear,
    required this.state,
  }) : detectedAt = DateTime.now();
}

// ============================================================================
// SMC - Station Management Computer Models
// ============================================================================

class SMCDestination {
  final String destinationId;
  final String platformId;
  final List<String> routePath; // Sequence of block IDs to traverse
  final double estimatedDistance;
  final double recommendedSpeed;
  final DateTime assignedAt;
  bool isActive;

  SMCDestination({
    required this.destinationId,
    required this.platformId,
    required this.routePath,
    required this.estimatedDistance,
    required this.recommendedSpeed,
    required this.assignedAt,
    this.isActive = true,
  });
}

class SpeedRestriction {
  final String id;
  final double startX;
  final double endX;
  final double maxSpeed;
  final String reason;
  final bool temporary;

  SpeedRestriction({
    required this.id,
    required this.startX,
    required this.endX,
    required this.maxSpeed,
    required this.reason,
    this.temporary = false,
  });

  bool appliesToPosition(double x) {
    return x >= startX && x <= endX;
  }
}

class TrackGrade {
  final double startX;
  final double endX;
  final double gradePercentage; // Positive = uphill, Negative = downhill

  TrackGrade({
    required this.startX,
    required this.endX,
    required this.gradePercentage,
  });

  bool appliesToPosition(double x) {
    return x >= startX && x <= endX;
  }
}
