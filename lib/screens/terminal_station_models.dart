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

enum RailwayTheme {
  legacy,        // Legacy Sim - original styling
  futuristic,    // Futuristic Blue Sim - blue/neon theme
  glassMorph     // Glass Morph Sim - glass morphism theme
}

// ============================================================================
// MODELS
// ============================================================================

// AI Agent helper model
class AIAgentMessage {
  final String message;
  final String category; // 'tip', 'suggestion', 'warning', 'info'
  final DateTime timestamp;

  AIAgentMessage({
    required this.message,
    required this.category,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AIAgent {
  String currentMessage;
  String category;
  bool isVisible;
  double x;
  double y;

  AIAgent({
    this.currentMessage = 'Welcome to Anthill Station! Click me for tips.',
    this.category = 'info',
    this.isVisible = true,
    this.x = 100,
    this.y = 50,
  });

  static final List<AIAgentMessage> messages = [
    AIAgentMessage(
      message: 'Try adding a train and setting it to automatic mode!',
      category: 'suggestion',
    ),
    AIAgentMessage(
      message: 'Enable CBTC devices for advanced train control features.',
      category: 'tip',
    ),
    AIAgentMessage(
      message: 'Set train destinations to Platform 1 or Platform 2 in AUTO/PM mode.',
      category: 'tip',
    ),
    AIAgentMessage(
      message: 'Toggle signals to see how CBTC trains bypass them!',
      category: 'suggestion',
    ),
    AIAgentMessage(
      message: 'Switch between different themes from the dropdown menu.',
      category: 'info',
    ),
    AIAgentMessage(
      message: 'Use Force Recovery if a collision occurs to move trains back safely.',
      category: 'tip',
    ),
    AIAgentMessage(
      message: 'Watch out for signal SPADs when operating trains manually!',
      category: 'warning',
    ),
    AIAgentMessage(
      message: 'Explore the Glass Morph theme for a modern visual experience.',
      category: 'suggestion',
    ),
    AIAgentMessage(
      message: 'Try the Futuristic Blue Sim theme for a cyber aesthetic.',
      category: 'suggestion',
    ),
    AIAgentMessage(
      message: 'Monitor block occupancy to prevent train collisions.',
      category: 'warning',
    ),
  ];

  void cycleMessage() {
    final randomMsg = (messages..shuffle()).first;
    currentMessage = randomMsg.message;
    category = randomMsg.category;
  }
}

// Theme data class to hold styling information
class RailwayThemeData {
  final Color trackColor;
  final Color platformColor;
  final Color platformEdgeColor;
  final Color signalRedColor;
  final Color signalGreenColor;
  final Color trainColor;
  final Color blockOccupiedColor;
  final Color blockClearColor;
  final Color backgroundColor;
  final Color textColor;
  final Color pointNormalColor;
  final Color pointReverseColor;
  final Color bufferStopColor;
  final Color movementAuthorityColor;
  final double glowIntensity;
  final bool hasGlow;
  final bool hasGlassMorphism;

  const RailwayThemeData({
    required this.trackColor,
    required this.platformColor,
    required this.platformEdgeColor,
    required this.signalRedColor,
    required this.signalGreenColor,
    required this.trainColor,
    required this.blockOccupiedColor,
    required this.blockClearColor,
    required this.backgroundColor,
    required this.textColor,
    required this.pointNormalColor,
    required this.pointReverseColor,
    required this.bufferStopColor,
    required this.movementAuthorityColor,
    this.glowIntensity = 0.0,
    this.hasGlow = false,
    this.hasGlassMorphism = false,
  });

  // Legacy theme (original)
  static const legacy = RailwayThemeData(
    trackColor: Colors.black,
    platformColor: Color(0xFFFBC02D), // yellow[700]
    platformEdgeColor: Color(0xFFFF6F00), // amber[900]
    signalRedColor: Colors.red,
    signalGreenColor: Colors.green,
    trainColor: Colors.blue,
    blockOccupiedColor: Colors.red,
    blockClearColor: Colors.green,
    backgroundColor: Colors.white,
    textColor: Colors.black87,
    pointNormalColor: Colors.teal,
    pointReverseColor: Colors.green,
    bufferStopColor: Colors.red,
    movementAuthorityColor: Color(0xFF00E676), // green accent
    hasGlow: false,
    hasGlassMorphism: false,
  );

  // Futuristic Blue theme
  static const futuristic = RailwayThemeData(
    trackColor: Color(0xFF0D47A1), // dark blue
    platformColor: Color(0xFF1976D2), // blue[700]
    platformEdgeColor: Color(0xFF00B0FF), // light blue accent
    signalRedColor: Color(0xFFFF1744), // red accent
    signalGreenColor: Color(0xFF00E676), // green accent
    trainColor: Color(0xFF00B8D4), // cyan accent
    blockOccupiedColor: Color(0xFFFF1744),
    blockClearColor: Color(0xFF00E676),
    backgroundColor: Color(0xFF000A1F), // very dark blue
    textColor: Color(0xFF64B5F6), // light blue
    pointNormalColor: Color(0xFF1DE9B6), // teal accent
    pointReverseColor: Color(0xFF00E676), // green accent
    bufferStopColor: Color(0xFFFF1744),
    movementAuthorityColor: Color(0xFF00E676),
    glowIntensity: 8.0,
    hasGlow: true,
    hasGlassMorphism: false,
  );

  // Glass Morph theme
  static const glassMorph = RailwayThemeData(
    trackColor: Color(0x88FFFFFF), // semi-transparent white
    platformColor: Color(0x66E1BEE7), // semi-transparent purple
    platformEdgeColor: Color(0xFFBA68C8), // purple accent
    signalRedColor: Color(0xFFEF5350), // softer red
    signalGreenColor: Color(0xFF66BB6A), // softer green
    trainColor: Color(0x99BBDEFB), // semi-transparent blue
    blockOccupiedColor: Color(0xFFEF5350),
    blockClearColor: Color(0xFF66BB6A),
    backgroundColor: Color(0xFF1A1A2E), // dark purple-ish background
    textColor: Color(0xFFEEEEEE), // light gray
    pointNormalColor: Color(0xFF80CBC4), // teal
    pointReverseColor: Color(0xFF81C784), // light green
    bufferStopColor: Color(0xFFEF5350),
    movementAuthorityColor: Color(0x8866BB6A), // semi-transparent green
    glowIntensity: 4.0,
    hasGlow: true,
    hasGlassMorphism: true,
  );

  static RailwayThemeData getTheme(RailwayTheme theme) {
    switch (theme) {
      case RailwayTheme.legacy:
        return legacy;
      case RailwayTheme.futuristic:
        return futuristic;
      case RailwayTheme.glassMorph:
        return glassMorph;
    }
  }
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
