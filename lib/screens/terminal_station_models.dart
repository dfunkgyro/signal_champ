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

enum RailwayArea {
  ma2,       // Left railway section
  ma1,       // Center railway section (original)
  ma3        // Right railway section
}

enum VccStatus {
  active,
  standby,
  fault,
  communicating
}

enum TimetableStatus {
  onTime,
  early,
  late,
  notScheduled
}

enum LayoutStyle {
  compact,   // Minimal UI, maximum canvas - for focused simulation viewing
  standard,  // Balanced layout - default professional view
  expanded   // Maximum information - for power users and detailed analysis
}

// ============================================================================
// LAYOUT CONFIGURATION
// ============================================================================

class LayoutConfiguration {
  final LayoutStyle style;
  final double leftPanelWidth;
  final double rightPanelWidth;
  final double topPanelHeight;
  final double controlFontSize;
  final double labelFontSize;
  final bool showDetailedInfo;
  final bool showAdvancedControls;
  final bool compactControls;
  final double zoomControlSize;
  final double defaultZoom;

  const LayoutConfiguration({
    required this.style,
    required this.leftPanelWidth,
    required this.rightPanelWidth,
    required this.topPanelHeight,
    required this.controlFontSize,
    required this.labelFontSize,
    required this.showDetailedInfo,
    required this.showAdvancedControls,
    required this.compactControls,
    required this.zoomControlSize,
    required this.defaultZoom,
  });

  static const LayoutConfiguration compact = LayoutConfiguration(
    style: LayoutStyle.compact,
    leftPanelWidth: 240.0,
    rightPanelWidth: 240.0,
    topPanelHeight: 60.0,
    controlFontSize: 11.0,
    labelFontSize: 10.0,
    showDetailedInfo: false,
    showAdvancedControls: false,
    compactControls: true,
    zoomControlSize: 36.0,
    defaultZoom: 0.7,
  );

  static const LayoutConfiguration standard = LayoutConfiguration(
    style: LayoutStyle.standard,
    leftPanelWidth: 320.0,
    rightPanelWidth: 320.0,
    topPanelHeight: 80.0,
    controlFontSize: 13.0,
    labelFontSize: 12.0,
    showDetailedInfo: true,
    showAdvancedControls: true,
    compactControls: false,
    zoomControlSize: 48.0,
    defaultZoom: 0.8,
  );

  static const LayoutConfiguration expanded = LayoutConfiguration(
    style: LayoutStyle.expanded,
    leftPanelWidth: 380.0,
    rightPanelWidth: 380.0,
    topPanelHeight: 100.0,
    controlFontSize: 14.0,
    labelFontSize: 13.0,
    showDetailedInfo: true,
    showAdvancedControls: true,
    compactControls: false,
    zoomControlSize: 56.0,
    defaultZoom: 0.9,
  );

  static LayoutConfiguration fromStyle(LayoutStyle style) {
    switch (style) {
      case LayoutStyle.compact:
        return compact;
      case LayoutStyle.standard:
        return standard;
      case LayoutStyle.expanded:
        return expanded;
    }
  }
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
  final RailwayArea area; // MA1, MA2, or MA3

  BlockSection({
    required this.id,
    required this.startX,
    required this.endX,
    required this.y,
    this.occupied = false,
    this.occupyingTrainId,
    this.area = RailwayArea.ma1, // Default to MA1 for backward compatibility
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
  final RailwayArea area;

  Point({
    required this.id,
    required this.x,
    required this.y,
    this.position = PointPosition.normal,
    this.locked = false,
    this.lockedByAB = false,
    this.area = RailwayArea.ma1,
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
  final RailwayArea area;

  Signal({
    required this.id,
    required this.x,
    required this.y,
    required this.routes,
    this.aspect = SignalAspect.red,
    this.activeRouteId,
    this.routeState = RouteState.unset,
    this.area = RailwayArea.ma1,
  });
}

class Platform {
  final String id;
  final String name;
  final double startX;
  final double endX;
  final double y;
  bool occupied;
  final RailwayArea area;

  Platform({
    required this.id,
    required this.name,
    required this.startX,
    required this.endX,
    required this.y,
    this.occupied = false,
    this.area = RailwayArea.ma1,
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
  RailwayArea currentArea; // Current railway area
  String? assignedTimetableId; // Assigned to SRS timetable
  bool runningToTimetable; // Following timetable mode

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
    this.currentArea = RailwayArea.ma1,
    this.assignedTimetableId,
    this.runningToTimetable = false,
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
// VCC (Vital Computer Controller) MODELS
// ============================================================================

class VccController {
  final String id; // vcc1, vcc2, vcc3
  final RailwayArea area;
  VccStatus status;
  final List<String> managedBlocks;
  final List<String> managedSignals;
  final Map<String, dynamic> trainData; // Shared train data
  DateTime lastHandshake;

  VccController({
    required this.id,
    required this.area,
    this.status = VccStatus.active,
    required this.managedBlocks,
    required this.managedSignals,
    Map<String, dynamic>? trainData,
  }) : trainData = trainData ?? {},
       lastHandshake = DateTime.now();

  void updateHandshake() {
    lastHandshake = DateTime.now();
  }

  bool isHealthy() {
    final timeSinceHandshake = DateTime.now().difference(lastHandshake);
    return status == VccStatus.active && timeSinceHandshake.inSeconds < 5;
  }
}

// ============================================================================
// GHOST TRAIN & TIMETABLE MODELS
// ============================================================================

class GhostTrain {
  final String id;
  final String routeId;
  double x;
  double y;
  double speed;
  int direction;
  final List<String> plannedRoute; // List of block IDs
  int currentRouteIndex;
  DateTime? scheduledArrivalTime;
  final bool isVisible; // Always false for ghost trains
  RailwayArea currentArea;

  GhostTrain({
    required this.id,
    required this.routeId,
    required this.x,
    required this.y,
    this.speed = 50.0,
    required this.direction,
    required this.plannedRoute,
    this.currentRouteIndex = 0,
    this.scheduledArrivalTime,
    this.isVisible = false,
    required this.currentArea,
  });

  String? get currentBlockId =>
      currentRouteIndex < plannedRoute.length
          ? plannedRoute[currentRouteIndex]
          : null;
}

class TimetableEntry {
  final String id;
  final String ghostTrainId;
  final String routeName;
  final List<TimetableStop> stops;
  final DateTime startTime;
  DateTime? actualStartTime;
  TimetableStatus status;
  int delaySeconds; // Positive = late, Negative = early
  String? assignedRealTrainId; // ID of real train assigned to this timetable

  TimetableEntry({
    required this.id,
    required this.ghostTrainId,
    required this.routeName,
    required this.stops,
    required this.startTime,
    this.actualStartTime,
    this.status = TimetableStatus.notScheduled,
    this.delaySeconds = 0,
    this.assignedRealTrainId,
  });

  Duration get delay => Duration(seconds: delaySeconds);

  bool get isOnTime => delaySeconds.abs() <= 30; // Within 30 seconds
  bool get hasAssignedTrain => assignedRealTrainId != null;
}

class TimetableStop {
  final String blockId;
  final String platformId;
  final RailwayArea area;
  final DateTime scheduledArrival;
  final DateTime scheduledDeparture;
  DateTime? actualArrival;
  DateTime? actualDeparture;
  final int dwellTimeSeconds;

  TimetableStop({
    required this.blockId,
    required this.platformId,
    required this.area,
    required this.scheduledArrival,
    required this.scheduledDeparture,
    this.actualArrival,
    this.actualDeparture,
    required this.dwellTimeSeconds,
  });

  int get arrivalDelaySeconds {
    if (actualArrival == null) return 0;
    return actualArrival!.difference(scheduledArrival).inSeconds;
  }

  int get departureDelaySeconds {
    if (actualDeparture == null) return 0;
    return actualDeparture!.difference(scheduledDeparture).inSeconds;
  }
}

// ============================================================================
// SRS (Schedule Regulator Subsystem) MODELS
// ============================================================================

class SrsData {
  final String id;
  final bool isActive;
  final Map<String, GhostTrain> ghostTrains;
  final Map<String, TimetableEntry> timetables;
  final List<String> activeRoutes; // MA2→MA1→MA3→MA2→MA1 cycle
  DateTime lastUpdate;
  int cycleCount;

  SrsData({
    required this.id,
    this.isActive = false,
    Map<String, GhostTrain>? ghostTrains,
    Map<String, TimetableEntry>? timetables,
    List<String>? activeRoutes,
    DateTime? lastUpdate,
    this.cycleCount = 0,
  }) : ghostTrains = ghostTrains ?? {},
       timetables = timetables ?? {},
       activeRoutes = activeRoutes ?? [],
       lastUpdate = lastUpdate ?? DateTime.now();

  int get totalGhostTrains => ghostTrains.length;
  int get assignedTrains => timetables.values
      .where((t) => t.hasAssignedTrain).length;

  bool get allOnSchedule => timetables.values
      .every((t) => t.status == TimetableStatus.onTime);
}

class GhostSignal {
  final String id;
  final RailwayArea area;
  final double x;
  final double y;
  SignalAspect aspect; // Used by ghost trains
  final bool isVisible; // Always false

  GhostSignal({
    required this.id,
    required this.area,
    required this.x,
    required this.y,
    this.aspect = SignalAspect.red,
    this.isVisible = false,
  });
}

class GhostPoint {
  final String id;
  final RailwayArea area;
  final double x;
  final double y;
  PointPosition position;
  final bool isVisible; // Always false

  GhostPoint({
    required this.id,
    required this.area,
    required this.x,
    required this.y,
    this.position = PointPosition.normal,
    this.isVisible = false,
  });
}
