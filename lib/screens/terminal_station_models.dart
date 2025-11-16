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
  off,       // Off mode - white
  storage    // Storage mode - green
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
// STATION MODEL (FOR TIMETABLE SYSTEM)
// ============================================================================

/// Represents a station in the railway network
/// Stations are the named stopping points where trains call according to timetables
class Station {
  final String id; // e.g., 'MA1', 'MA2', 'MA3'
  final String name; // e.g., 'Mainline Station 1'
  final String platformId; // Platform ID (e.g., 'P1', 'P2')
  final double x; // X coordinate of station center
  final double y; // Y coordinate of station center
  bool occupied; // Whether a train is currently at this station

  Station({
    required this.id,
    required this.name,
    required this.platformId,
    required this.x,
    required this.y,
    this.occupied = false,
  });

  @override
  String toString() => 'Station($id: $name at Platform $platformId)';
}

// ============================================================================
// TIMETABLE STOP MODEL
// ============================================================================

/// Represents a single stop in a timetable
class TimetableStop {
  final String stationId; // Station where the train stops
  final Duration? arrivalTime; // Scheduled arrival time (null for origin)
  final Duration? departureTime; // Scheduled departure time (null for terminus)
  final Duration dwellTime; // How long to dwell at station (doors open)
  final String platformId; // Which platform to use at this station

  TimetableStop({
    required this.stationId,
    this.arrivalTime,
    this.departureTime,
    required this.dwellTime,
    required this.platformId,
  });

  /// Returns true if this is the origin station (no arrival time)
  bool get isOrigin => arrivalTime == null;

  /// Returns true if this is the terminus station (no departure time)
  bool get isTerminus => departureTime == null;

  @override
  String toString() {
    if (isOrigin) {
      return 'Origin: $stationId (depart: $departureTime, dwell: $dwellTime)';
    } else if (isTerminus) {
      return 'Terminus: $stationId (arrive: $arrivalTime)';
    } else {
      return 'Stop: $stationId (arrive: $arrivalTime, depart: $departureTime, dwell: $dwellTime)';
    }
  }
}

// ============================================================================
// TIMETABLE ENTRY MODEL
// ============================================================================

/// Represents a complete timetable for a train service
/// Defines the sequence of stations and timing
class TimetableEntry {
  final String id; // Unique timetable ID (e.g., 'TT001')
  final String trainServiceNumber; // Service number (e.g., '101')
  final List<TimetableStop> stops; // Sequence of stops

  TimetableEntry({
    required this.id,
    required this.trainServiceNumber,
    required this.stops,
  });

  /// Returns the origin station ID (first stop)
  String get originStation => stops.first.stationId;

  /// Returns the terminus station ID (last stop)
  String get terminusStation => stops.last.stationId;

  /// Gets the next stop after the given station
  /// Returns null if at terminus or station not found
  TimetableStop? getNextStop(String currentStationId) {
    final currentIndex = stops.indexWhere((stop) => stop.stationId == currentStationId);

    if (currentIndex == -1 || currentIndex == stops.length - 1) {
      return null; // Not found or at terminus
    }

    return stops[currentIndex + 1];
  }

  /// Gets the stop for a given station ID
  TimetableStop? getStop(String stationId) {
    try {
      return stops.firstWhere((stop) => stop.stationId == stationId);
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() => 'Timetable($id: Service $trainServiceNumber, $originStation → $terminusStation)';
}

// ============================================================================
// GHOST TRAIN MODEL
// ============================================================================

/// Represents a "ghost train" - a timetable that can be assigned to a real train
/// This allows timetables to exist independently and be assigned to physical trains
class GhostTrain {
  final String id; // Unique ghost train ID
  final String timetableId; // Reference to timetable
  final String serviceNumber; // Service number from timetable
  String? currentStationId; // Current station in the timetable sequence
  bool assignedToRealTrain; // Whether this ghost train is assigned to a real train
  String? realTrainId; // ID of the real train (if assigned)

  GhostTrain({
    required this.id,
    required this.timetableId,
    required this.serviceNumber,
    this.currentStationId,
    this.assignedToRealTrain = false,
    this.realTrainId,
  });

  @override
  String toString() {
    if (assignedToRealTrain) {
      return 'GhostTrain($id: Service $serviceNumber, assigned to $realTrainId, at $currentStationId)';
    } else {
      return 'GhostTrain($id: Service $serviceNumber, unassigned, at $currentStationId)';
    }
  }
}

// ============================================================================
// TIMETABLE ROUTE MODEL
// ============================================================================

/// Maps station-to-station journeys to signal routes
/// This bridges the gap between timetable (stations) and signaling system (routes)
class TimetableRoute {
  final String fromStationId; // Origin station
  final String toStationId; // Destination station
  final String signalId; // Signal that controls this route
  final String routeId; // Specific route ID (e.g., 'C31_R1')
  final List<String> requiredBlocks; // Blocks that must be clear

  TimetableRoute({
    required this.fromStationId,
    required this.toStationId,
    required this.signalId,
    required this.routeId,
    required this.requiredBlocks,
  });

  @override
  String toString() => 'Route($fromStationId → $toStationId via $signalId:$routeId)';
}
