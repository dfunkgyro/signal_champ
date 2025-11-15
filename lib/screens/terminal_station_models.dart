import 'package:flutter/material.dart';
import 'collision_analysis_system.dart' as collision_system;
import 'dart:math' as math;

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
// CBTC - ATO (Automatic Train Operation) ENUMS
// ============================================================================

/// ATO Grade of Automation levels
/// GoA 0 = On-sight operation (not applicable here)
/// GoA 1 = Non-automated train operation (driver controls everything)
/// GoA 2 = Semi-automated train operation (ATO controls speed, driver operates doors)
/// GoA 3 = Driverless train operation (ATO controls speed and doors, driver monitors)
/// GoA 4 = Unattended train operation (fully automated, no staff on train)
enum ATOMode {
  manual,     // Manual mode - driver controls train (GoA 1)
  atoGoA2,    // Semi-automatic - ATO speed control, manual doors (GoA 2)
  atoGoA3,    // Driverless - ATO speed + doors, driver monitors (GoA 3)
  atoGoA4,    // Unattended - fully automatic, no driver (GoA 4)
}

/// ATO operational states during journey
enum ATOState {
  idle,           // Train stopped, no destination
  starting,       // Accelerating from stop
  cruising,       // Maintaining constant speed
  coasting,       // Rolling without power
  braking,        // Service braking
  approaching,    // Approaching platform/stop
  dwelling,       // At platform with doors open
  emergency,      // Emergency brake applied
}

// ============================================================================
// CBTC - ATS (Automatic Train Supervision) ENUMS
// ============================================================================

/// ATS train service types
enum ServiceType {
  express,        // Express service - skip some stations
  stopping,       // All-stations service
  shuttle,        // Shuttle between two terminals
  maintenance,    // Maintenance/engineering train
  test,          // Test train
}

/// ATS train status
enum TrainStatus {
  onTime,         // Operating on schedule
  early,          // Ahead of schedule
  delayed,        // Behind schedule
  outOfService,   // Not in passenger service
  faulty,         // Train has faults
}

// ============================================================================
// CBTC - COMMUNICATION ENUMS
// ============================================================================

/// Communication message types between train and wayside
enum CbtcMessageType {
  positionReport,       // Train reports position to wayside
  movementAuthority,    // Wayside sends movement authority to train
  statusUpdate,         // Train status update
  emergencyBrake,       // Emergency brake command
  doorControl,          // Door open/close command
  heartbeat,           // Keep-alive message
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

  // CBTC - Platform Screen Doors
  PlatformScreenDoor? psd; // Platform screen door system (null if not equipped)

  Platform({
    required this.id,
    required this.name,
    required this.startX,
    required this.endX,
    required this.y,
    this.occupied = false,
    this.psd,
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

  // CBTC - ATO (Automatic Train Operation) data
  ATOControlData? atoData; // ATO control information (null if not in ATO mode)

  // CBTC - Moving Block data
  MovingBlock? movingBlock; // Dynamic moving block protection

  // CBTC - Communication data
  CbtcCommunicationSession? commSession; // Communication session with wayside

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
    this.atoData,
    this.movingBlock,
    this.commSession,
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
// CBTC - ATO (Automatic Train Operation) MODELS
// ============================================================================

/// Journey plan for ATO operation - defines where train should go and stop
class ATOJourneyPlan {
  final String id;
  final List<String> plannedStops; // List of platform IDs
  final String finalDestination; // Final platform ID
  final ServiceType serviceType;
  DateTime? scheduledDepartureTime;
  final Map<String, DateTime> scheduledArrivalTimes; // Platform ID -> arrival time
  int currentStopIndex;

  ATOJourneyPlan({
    required this.id,
    required this.plannedStops,
    required this.finalDestination,
    this.serviceType = ServiceType.stopping,
    this.scheduledDepartureTime,
    Map<String, DateTime>? scheduledArrivalTimes,
    this.currentStopIndex = 0,
  }) : scheduledArrivalTimes = scheduledArrivalTimes ?? {};

  String? get currentStop =>
      currentStopIndex < plannedStops.length ? plannedStops[currentStopIndex] : null;

  String? get nextStop =>
      currentStopIndex + 1 < plannedStops.length ? plannedStops[currentStopIndex + 1] : null;

  bool get isComplete => currentStopIndex >= plannedStops.length;

  void advanceToNextStop() {
    if (!isComplete) {
      currentStopIndex++;
    }
  }
}

/// Acceleration/deceleration profile for smooth ATO operation
class ATOSpeedProfile {
  final double maxSpeed; // Maximum allowed speed (m/s)
  final double comfortableAcceleration; // Comfortable acceleration (m/s²)
  final double comfortableDeceleration; // Comfortable deceleration (m/s²)
  final double emergencyDeceleration; // Emergency braking rate (m/s²)
  final double jerkLimit; // Max rate of change of acceleration (m/s³)

  ATOSpeedProfile({
    this.maxSpeed = 25.0, // ~90 km/h
    this.comfortableAcceleration = 1.0, // 1 m/s²
    this.comfortableDeceleration = 1.2, // 1.2 m/s² (slightly higher than accel)
    this.emergencyDeceleration = 3.0, // 3 m/s²
    this.jerkLimit = 0.5, // 0.5 m/s³ for passenger comfort
  });

  /// Calculate required braking distance for given speed
  double calculateBrakingDistance(double currentSpeed, {bool emergency = false}) {
    final decel = emergency ? emergencyDeceleration : comfortableDeceleration;
    // v² = u² + 2as => s = (v² - u²) / 2a
    return (currentSpeed * currentSpeed) / (2 * decel);
  }

  /// Calculate target speed for distance to stop
  double calculateTargetSpeed(double distanceToStop) {
    // v² = u² + 2as => v = sqrt(2as)
    final targetSpeed = math.sqrt(2 * comfortableDeceleration * distanceToStop);
    return math.min(targetSpeed, maxSpeed);
  }
}

/// ATO control data attached to train
class ATOControlData {
  ATOMode mode;
  ATOState state;
  ATOJourneyPlan? journeyPlan;
  ATOSpeedProfile speedProfile;
  double targetSpeed; // Current target speed
  String? targetPlatformId; // Platform we're heading to
  double distanceToTarget; // Distance to target platform/stop
  bool doorsAutomatic; // Whether doors are under ATO control
  DateTime? dwellStartTime; // When we started dwelling at platform
  int dwellDuration; // How long to dwell (seconds)
  bool readyToDepart; // All conditions met for departure

  ATOControlData({
    this.mode = ATOMode.manual,
    this.state = ATOState.idle,
    this.journeyPlan,
    ATOSpeedProfile? speedProfile,
    this.targetSpeed = 0,
    this.targetPlatformId,
    this.distanceToTarget = 0,
    this.doorsAutomatic = false,
    this.dwellStartTime,
    this.dwellDuration = 30, // Default 30 seconds dwell
    this.readyToDepart = false,
  }) : speedProfile = speedProfile ?? ATOSpeedProfile();

  bool get isAutomatic => mode != ATOMode.manual;
  bool get isDwelling => state == ATOState.dwelling;
}

// ============================================================================
// CBTC - ATS (Automatic Train Supervision) MODELS
// ============================================================================

/// Train assignment by ATS - links train to service and route
class ATSTrainAssignment {
  final String trainId;
  final String serviceId; // Service number (e.g., "S101")
  final ServiceType serviceType;
  final ATOJourneyPlan journeyPlan;
  final DateTime assignedAt;
  TrainStatus status;
  DateTime? expectedArrivalTime; // Next expected arrival
  DateTime? actualArrivalTime; // Actual arrival
  int delaySeconds; // Positive = late, negative = early

  ATSTrainAssignment({
    required this.trainId,
    required this.serviceId,
    required this.serviceType,
    required this.journeyPlan,
    DateTime? assignedAt,
    this.status = TrainStatus.onTime,
    this.expectedArrivalTime,
    this.actualArrivalTime,
    this.delaySeconds = 0,
  }) : assignedAt = assignedAt ?? DateTime.now();

  /// Calculate delay in seconds
  void updateDelay() {
    if (expectedArrivalTime != null && actualArrivalTime != null) {
      delaySeconds = actualArrivalTime!.difference(expectedArrivalTime!).inSeconds;

      // Update status based on delay
      if (delaySeconds > 60) {
        status = TrainStatus.delayed;
      } else if (delaySeconds < -60) {
        status = TrainStatus.early;
      } else {
        status = TrainStatus.onTime;
      }
    }
  }
}

/// ATS monitoring data for a train
class ATSTrainMonitoring {
  final String trainId;
  double currentSpeed;
  double currentPosition;
  String? currentBlock;
  String? currentPlatform;
  DateTime lastUpdate;
  bool inService;
  List<String> activeFaults;
  Map<String, dynamic> telemetry; // Additional telemetry data

  ATSTrainMonitoring({
    required this.trainId,
    this.currentSpeed = 0,
    this.currentPosition = 0,
    this.currentBlock,
    this.currentPlatform,
    DateTime? lastUpdate,
    this.inService = true,
    List<String>? activeFaults,
    Map<String, dynamic>? telemetry,
  })  : lastUpdate = lastUpdate ?? DateTime.now(),
        activeFaults = activeFaults ?? [],
        telemetry = telemetry ?? {};
}

/// Route conflict detected by ATS
class ATSRouteConflict {
  final String id;
  final List<String> conflictingTrainIds;
  final List<String> conflictingBlocks;
  final String description;
  final DateTime detectedAt;
  bool resolved;
  String? resolution;

  ATSRouteConflict({
    required this.id,
    required this.conflictingTrainIds,
    required this.conflictingBlocks,
    required this.description,
    DateTime? detectedAt,
    this.resolved = false,
    this.resolution,
  }) : detectedAt = detectedAt ?? DateTime.now();
}

// ============================================================================
// CBTC - MOVING BLOCK MODELS
// ============================================================================

/// Moving Block - dynamic safety zone that moves with the train
class MovingBlock {
  final String trainId;
  double rearPosition; // Rear of train
  double frontPosition; // Front of train
  double safetyMargin; // Additional safety margin
  double blockEndPosition; // End of safe zone (where train can travel to)
  DateTime lastUpdate;

  MovingBlock({
    required this.trainId,
    required this.rearPosition,
    required this.frontPosition,
    this.safetyMargin = 50.0, // Default 50 meters safety margin
    required this.blockEndPosition,
    DateTime? lastUpdate,
  }) : lastUpdate = lastUpdate ?? DateTime.now();

  double get trainLength => frontPosition - rearPosition;
  double get totalBlockLength => blockEndPosition - rearPosition;
  double get availableDistance => blockEndPosition - frontPosition;
}

/// Braking curve calculation for moving block
class BrakingCurve {
  final double emergencyBrakingRate; // m/s²
  final double serviceBrakingRate; // m/s²
  final double reactionTime; // seconds
  final double safetyMargin; // meters

  BrakingCurve({
    this.emergencyBrakingRate = 3.0,
    this.serviceBrakingRate = 1.2,
    this.reactionTime = 2.0,
    this.safetyMargin = 20.0,
  });

  /// Calculate safe stopping distance for given speed
  double calculateStoppingDistance(double speed, {bool emergency = false}) {
    final brakingRate = emergency ? emergencyBrakingRate : serviceBrakingRate;
    final reactionDistance = speed * reactionTime;
    final brakingDistance = (speed * speed) / (2 * brakingRate);
    return reactionDistance + brakingDistance + safetyMargin;
  }

  /// Calculate safe speed for given distance
  double calculateSafeSpeed(double distance) {
    if (distance <= safetyMargin) return 0;
    final availableDistance = distance - safetyMargin;
    // Solve for v: d = vt + v²/2a
    // Using quadratic formula: v = (-t + sqrt(t² + 2ad))/1
    final discriminant = (reactionTime * reactionTime) + (2 * serviceBrakingRate * availableDistance);
    if (discriminant < 0) return 0;
    return (-reactionTime + math.sqrt(discriminant)) * serviceBrakingRate;
  }
}

// ============================================================================
// CBTC - COMMUNICATION MODELS
// ============================================================================

/// Message exchanged between train and wayside
class CbtcMessage {
  final String id;
  final CbtcMessageType type;
  final String senderId; // Train ID or "WAYSIDE"
  final String recipientId; // Train ID or "WAYSIDE"
  final DateTime timestamp;
  final Map<String, dynamic> payload;
  bool delivered;
  bool acknowledged;
  int transmissionDelay; // Simulated delay in milliseconds
  bool lost; // Simulate packet loss

  CbtcMessage({
    required this.id,
    required this.type,
    required this.senderId,
    required this.recipientId,
    DateTime? timestamp,
    Map<String, dynamic>? payload,
    this.delivered = false,
    this.acknowledged = false,
    this.transmissionDelay = 50, // Default 50ms
    this.lost = false,
  })  : timestamp = timestamp ?? DateTime.now(),
        payload = payload ?? {};
}

/// Communication session between train and wayside
class CbtcCommunicationSession {
  final String trainId;
  DateTime lastHeartbeat;
  int messagesSent;
  int messagesReceived;
  int messagesLost;
  bool isConnected;
  double signalQuality; // 0.0 to 1.0
  int averageLatency; // milliseconds

  CbtcCommunicationSession({
    required this.trainId,
    DateTime? lastHeartbeat,
    this.messagesSent = 0,
    this.messagesReceived = 0,
    this.messagesLost = 0,
    this.isConnected = true,
    this.signalQuality = 1.0,
    this.averageLatency = 50,
  }) : lastHeartbeat = lastHeartbeat ?? DateTime.now();

  double get packetLossRate =>
      messagesSent > 0 ? messagesLost / messagesSent : 0.0;

  bool get isHealthy =>
      isConnected && signalQuality > 0.7 && packetLossRate < 0.05;
}

// ============================================================================
// CBTC - PLATFORM SCREEN DOOR MODELS
// ============================================================================

/// Platform Screen Door state
enum PSDState {
  closed,     // Doors fully closed
  opening,    // Doors opening
  open,       // Doors fully open
  closing,    // Doors closing
  fault,      // Door malfunction
  locked,     // Doors locked (not in service)
}

/// Platform Screen Door model
class PlatformScreenDoor {
  final String platformId;
  PSDState state;
  bool trainDetected; // Is train at platform?
  bool trainDoorsOpen; // Are train doors open?
  bool safeToOpen; // All safety checks passed
  DateTime? lastStateChange;
  String? faultMessage;
  bool inService;

  PlatformScreenDoor({
    required this.platformId,
    this.state = PSDState.closed,
    this.trainDetected = false,
    this.trainDoorsOpen = false,
    this.safeToOpen = false,
    this.lastStateChange,
    this.faultMessage,
    this.inService = true,
  });

  /// Check if doors can be opened (safety interlock)
  bool canOpen() {
    return inService &&
        state == PSDState.closed &&
        trainDetected &&
        safeToOpen &&
        faultMessage == null;
  }

  /// Check if doors can be closed
  bool canClose() {
    return inService &&
        state == PSDState.open &&
        !trainDoorsOpen && // Train doors must close first
        faultMessage == null;
  }

  /// Open the platform screen doors
  void open() {
    if (canOpen()) {
      state = PSDState.opening;
      lastStateChange = DateTime.now();
    }
  }

  /// Close the platform screen doors
  void close() {
    if (canClose()) {
      state = PSDState.closing;
      lastStateChange = DateTime.now();
    }
  }

  /// Complete the opening/closing animation
  void completeTransition() {
    if (state == PSDState.opening) {
      state = PSDState.open;
      lastStateChange = DateTime.now();
    } else if (state == PSDState.closing) {
      state = PSDState.closed;
      lastStateChange = DateTime.now();
    }
  }
}
