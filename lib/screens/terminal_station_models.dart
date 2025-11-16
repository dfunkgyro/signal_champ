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
// TIMETABLE MODELS
// ============================================================================

/// Represents a scheduled stop at a platform
class TimetableStop {
  final String platformId;
  final String platformName;
  final DateTime scheduledArrival;
  final DateTime scheduledDeparture;
  final int dwellTimeSeconds; // How long to wait at the platform

  DateTime? actualArrival;
  DateTime? actualDeparture;
  bool doorsOpened = false;
  bool departed = false;

  TimetableStop({
    required this.platformId,
    required this.platformName,
    required this.scheduledArrival,
    required this.scheduledDeparture,
    required this.dwellTimeSeconds,
    this.actualArrival,
    this.actualDeparture,
    this.doorsOpened = false,
    this.departed = false,
  });

  /// How many seconds late/early the train is (negative = early, positive = late)
  int get arrivalDelaySeconds {
    if (actualArrival == null) {
      return DateTime.now().difference(scheduledArrival).inSeconds;
    }
    return actualArrival!.difference(scheduledArrival).inSeconds;
  }

  int get departureDelaySeconds {
    if (actualDeparture == null) {
      return DateTime.now().difference(scheduledDeparture).inSeconds;
    }
    return actualDeparture!.difference(scheduledDeparture).inSeconds;
  }

  /// Time remaining until scheduled departure
  int get secondsUntilDeparture {
    return scheduledDeparture.difference(DateTime.now()).inSeconds;
  }

  /// Whether the train should have already departed
  bool get shouldHaveDeparted {
    return DateTime.now().isAfter(scheduledDeparture);
  }
}

/// Represents a complete timetabled journey for a train
class TimetableEntry {
  final String id;
  final String trainId;
  final String serviceName; // e.g., "Service 101"
  final List<TimetableStop> stops;
  final DateTime startTime;
  final DateTime endTime;
  bool active;
  bool completed;
  int currentStopIndex;

  TimetableEntry({
    required this.id,
    required this.trainId,
    required this.serviceName,
    required this.stops,
    required this.startTime,
    required this.endTime,
    this.active = false,
    this.completed = false,
    this.currentStopIndex = 0,
  });

  TimetableStop? get currentStop {
    if (currentStopIndex < stops.length) {
      return stops[currentStopIndex];
    }
    return null;
  }

  TimetableStop? get nextStop {
    if (currentStopIndex + 1 < stops.length) {
      return stops[currentStopIndex + 1];
    }
    return null;
  }

  /// Overall delay in seconds (based on current or last stop)
  int get overallDelaySeconds {
    final stop = currentStop;
    if (stop != null) {
      return stop.arrivalDelaySeconds;
    }
    return 0;
  }

  /// Whether the timetable should be running now
  bool get shouldBeActive {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Progress through the timetable (0.0 to 1.0)
  double get progress {
    if (stops.isEmpty) return 0.0;
    return currentStopIndex / stops.length;
  }
}

/// Settings for timetable mode operation
class TimetableSettings {
  bool autoCloseDoors; // Whether doors close automatically after dwell time
  bool autoOpenDoors; // Whether doors open automatically at platforms
  int doorWarningTimeSeconds; // Time before warning user to close doors
  bool enableSpeedAdjustment; // Whether train adjusts speed to catch up
  double maxSpeedAdjustment; // Maximum speed multiplier when catching up (e.g., 1.2 = 120%)
  bool showLatenessDisplay; // Whether to show lateness on screen
  bool strictTiming; // Whether to enforce strict timetable adherence

  TimetableSettings({
    this.autoCloseDoors = false,
    this.autoOpenDoors = true,
    this.doorWarningTimeSeconds = 20,
    this.enableSpeedAdjustment = true,
    this.maxSpeedAdjustment = 1.2,
    this.showLatenessDisplay = true,
    this.strictTiming = false,
  });
}

/// Overall timetable schedule containing all timetabled services
class TimetableSchedule {
  final List<TimetableEntry> entries;
  TimetableSettings settings;
  bool enabled;

  TimetableSchedule({
    required this.entries,
    required this.settings,
    this.enabled = false,
  });

  /// Get active timetable for a specific train
  TimetableEntry? getActiveEntryForTrain(String trainId) {
    for (final entry in entries) {
      if (entry.trainId == trainId && entry.active && !entry.completed) {
        return entry;
      }
    }
    return null;
  }

  /// Get all active timetables
  List<TimetableEntry> get activeEntries {
    return entries.where((e) => e.active && !e.completed).toList();
  }
}
