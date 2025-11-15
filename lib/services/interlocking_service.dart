import 'package:flutter/foundation.dart';
import 'package:rail_champ/screens/terminal_station_models.dart';
import 'dart:async';

// ============================================================================
// INTERLOCKING SERVICE
// Advanced railway interlocking system providing safety validation,
// conflict detection, SPAD prevention, and safety rule enforcement
// ============================================================================

/// Safety violation severity levels
enum ViolationSeverity {
  info,
  warning,
  critical,
  emergency,
}

/// Safety rule types
enum SafetyRuleType {
  spadPrevention,
  routeConflict,
  pointProtection,
  blockOccupancy,
  signalSequence,
  speedRestriction,
  platformSafety,
  derailmentPrevention,
  headOnCollision,
  rearEndCollision,
}

/// Safety violation record
class SafetyViolation {
  final String id;
  final SafetyRuleType ruleType;
  final ViolationSeverity severity;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> context;
  bool acknowledged;
  DateTime? acknowledgedAt;
  String? acknowledgedBy;

  SafetyViolation({
    required this.id,
    required this.ruleType,
    required this.severity,
    required this.description,
    DateTime? timestamp,
    Map<String, dynamic>? context,
    this.acknowledged = false,
    this.acknowledgedAt,
    this.acknowledgedBy,
  })  : timestamp = timestamp ?? DateTime.now(),
        context = context ?? {};

  void acknowledge(String operator) {
    acknowledged = true;
    acknowledgedAt = DateTime.now();
    acknowledgedBy = operator;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ruleType': ruleType.toString(),
      'severity': severity.toString(),
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'context': context,
      'acknowledged': acknowledged,
      'acknowledgedAt': acknowledgedAt?.toIso8601String(),
      'acknowledgedBy': acknowledgedBy,
    };
  }
}

/// Interlocking check result
class InterlockingCheckResult {
  final bool isValid;
  final List<String> reasons;
  final List<SafetyViolation> violations;

  InterlockingCheckResult({
    required this.isValid,
    this.reasons = const [],
    this.violations = const [],
  });

  InterlockingCheckResult.valid()
      : isValid = true,
        reasons = [],
        violations = [];

  InterlockingCheckResult.invalid({
    required List<String> reasons,
    List<SafetyViolation>? violations,
  })  : isValid = false,
        reasons = reasons,
        violations = violations ?? [];
}

/// SPAD (Signal Passed At Danger) detection record
class SPADEvent {
  final String trainId;
  final String signalId;
  final SignalAspect signalAspect;
  final double trainSpeed;
  final DateTime timestamp;
  final double distancePastSignal;
  bool resolved;

  SPADEvent({
    required this.trainId,
    required this.signalId,
    required this.signalAspect,
    required this.trainSpeed,
    DateTime? timestamp,
    required this.distancePastSignal,
    this.resolved = false,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'trainId': trainId,
      'signalId': signalId,
      'signalAspect': signalAspect.toString(),
      'trainSpeed': trainSpeed,
      'timestamp': timestamp.toIso8601String(),
      'distancePastSignal': distancePastSignal,
      'resolved': resolved,
    };
  }
}

/// Point protection rule - ensures points not moved under trains
class PointProtectionRule {
  final String pointId;
  final List<String> protectedBlocks;
  final double detectionRadius;

  PointProtectionRule({
    required this.pointId,
    required this.protectedBlocks,
    this.detectionRadius = 30.0,
  });
}

/// Comprehensive interlocking service
class InterlockingService extends ChangeNotifier {
  final List<SafetyViolation> violations = [];
  final List<SPADEvent> spadEvents = [];
  final Map<String, PointProtectionRule> pointProtectionRules = {};

  // Callbacks for system state
  Function(String blockId)? isBlockOccupiedCallback;
  Function(String signalId)? getSignalCallback;
  Function(String pointId)? getPointCallback;
  Function(String trainId)? getTrainCallback;
  Function()? getAllTrainsCallback;
  Function()? getAllSignalsCallback;
  Function()? getAllPointsCallback;

  // Safety configuration
  bool spadDetectionEnabled = true;
  bool pointProtectionEnabled = true;
  bool conflictDetectionEnabled = true;
  bool emergencyStopEnabled = true;
  double spadDetectionDistance = 10.0; // meters past signal
  double minimumTrainSeparation = 50.0; // meters

  // Statistics
  int totalViolations = 0;
  int criticalViolations = 0;
  int spadEventsCount = 0;
  int conflictsDetected = 0;

  // Emergency state
  bool _emergencyActivated = false;
  bool get emergencyActivated => _emergencyActivated;

  InterlockingService();

  /// Validate route setting against interlocking rules
  InterlockingCheckResult validateRouteSet(String signalId, SignalRoute route) {
    final reasons = <String>[];
    final safetyViolations = <SafetyViolation>[];

    // Check 1: All required blocks must be clear
    if (isBlockOccupiedCallback != null) {
      for (final blockId in route.requiredBlocksClear) {
        if (isBlockOccupiedCallback!(blockId)) {
          reasons.add('Block $blockId is occupied');
          safetyViolations.add(_createViolation(
            ruleType: SafetyRuleType.blockOccupancy,
            severity: ViolationSeverity.critical,
            description: 'Attempt to set route with occupied block $blockId',
            context: {'signalId': signalId, 'blockId': blockId},
          ));
        }
      }
    }

    // Check 2: No conflicting routes should be active
    if (conflictDetectionEnabled) {
      for (final conflictingRoute in route.conflictingRoutes) {
        if (_isRouteActive(conflictingRoute)) {
          reasons.add('Conflicting route $conflictingRoute is active');
          safetyViolations.add(_createViolation(
            ruleType: SafetyRuleType.routeConflict,
            severity: ViolationSeverity.warning,
            description: 'Route conflict with $conflictingRoute',
            context: {'signalId': signalId, 'conflictingRoute': conflictingRoute},
          ));
        }
      }
    }

    // Check 3: Points must be moveable (not under trains)
    if (pointProtectionEnabled) {
      for (final pointId in route.requiredPointPositions.keys) {
        if (!_canMovePoint(pointId)) {
          reasons.add('Point $pointId is protected (train nearby)');
          safetyViolations.add(_createViolation(
            ruleType: SafetyRuleType.pointProtection,
            severity: ViolationSeverity.critical,
            description: 'Cannot move point $pointId - train too close',
            context: {'signalId': signalId, 'pointId': pointId},
          ));
        }
      }
    }

    // Check 4: Path blocks must form a safe continuous route
    final pathValid = _validatePathContinuity(route.pathBlocks);
    if (!pathValid) {
      reasons.add('Route path is not continuous');
      safetyViolations.add(_createViolation(
        ruleType: SafetyRuleType.derailmentPrevention,
        severity: ViolationSeverity.critical,
        description: 'Route path blocks do not form continuous route',
        context: {'signalId': signalId, 'pathBlocks': route.pathBlocks},
      ));
    }

    // Record violations
    violations.addAll(safetyViolations);
    totalViolations += safetyViolations.length;
    criticalViolations += safetyViolations.where((v) => v.severity == ViolationSeverity.critical).length;

    if (reasons.isEmpty) {
      return InterlockingCheckResult.valid();
    } else {
      if (kDebugMode) {
        print('🚫 Interlocking check failed for signal $signalId:');
        for (final reason in reasons) {
          print('   - $reason');
        }
      }
      conflictsDetected++;
      return InterlockingCheckResult.invalid(
        reasons: reasons,
        violations: safetyViolations,
      );
    }
  }

  /// Validate train movement against safety rules
  InterlockingCheckResult validateTrainMovement(Train train) {
    final reasons = <String>[];
    final safetyViolations = <SafetyViolation>[];

    // Check 1: SPAD detection
    if (spadDetectionEnabled) {
      final spadCheck = _checkForSPAD(train);
      if (!spadCheck.isValid) {
        reasons.addAll(spadCheck.reasons);
        safetyViolations.addAll(spadCheck.violations);
      }
    }

    // Check 2: Train separation
    final separationCheck = _checkTrainSeparation(train);
    if (!separationCheck.isValid) {
      reasons.addAll(separationCheck.reasons);
      safetyViolations.addAll(separationCheck.violations);
    }

    // Check 3: Speed restrictions
    final speedCheck = _checkSpeedRestrictions(train);
    if (!speedCheck.isValid) {
      reasons.addAll(speedCheck.reasons);
      safetyViolations.addAll(speedCheck.violations);
    }

    // Record violations
    violations.addAll(safetyViolations);
    totalViolations += safetyViolations.length;
    criticalViolations += safetyViolations.where((v) => v.severity == ViolationSeverity.critical).length;

    if (reasons.isEmpty) {
      return InterlockingCheckResult.valid();
    } else {
      return InterlockingCheckResult.invalid(
        reasons: reasons,
        violations: safetyViolations,
      );
    }
  }

  /// Check for SPAD (Signal Passed At Danger)
  InterlockingCheckResult _checkForSPAD(Train train) {
    if (getAllSignalsCallback == null) {
      return InterlockingCheckResult.valid();
    }

    final signals = getAllSignalsCallback!();
    if (signals == null) return InterlockingCheckResult.valid();

    for (final signal in signals) {
      // Check if train is moving toward signal
      final isApproaching = _isTrainApproachingSignal(train, signal);
      if (!isApproaching) continue;

      // Check if signal is at danger
      if (signal.aspect != SignalAspect.red) continue;

      // Check if train has passed the signal
      final distancePast = _getDistancePastSignal(train, signal);
      if (distancePast > 0 && distancePast < spadDetectionDistance) {
        // SPAD detected!
        final spadEvent = SPADEvent(
          trainId: train.id,
          signalId: signal.id,
          signalAspect: signal.aspect,
          trainSpeed: train.speed,
          distancePastSignal: distancePast,
        );

        spadEvents.add(spadEvent);
        spadEventsCount++;

        final violation = _createViolation(
          ruleType: SafetyRuleType.spadPrevention,
          severity: ViolationSeverity.emergency,
          description: 'SPAD: Train ${train.name} passed signal ${signal.id} at danger',
          context: {
            'trainId': train.id,
            'signalId': signal.id,
            'speed': train.speed,
            'distancePast': distancePast,
          },
        );

        if (kDebugMode) {
          print('🚨 SPAD DETECTED: Train ${train.name} passed ${signal.id} at danger!');
        }

        return InterlockingCheckResult.invalid(
          reasons: ['SPAD: Train passed signal at danger'],
          violations: [violation],
        );
      }
    }

    return InterlockingCheckResult.valid();
  }

  /// Check train separation distances
  InterlockingCheckResult _checkTrainSeparation(Train train) {
    if (getAllTrainsCallback == null) {
      return InterlockingCheckResult.valid();
    }

    final allTrains = getAllTrainsCallback!();
    if (allTrains == null) return InterlockingCheckResult.valid();

    for (final otherTrain in allTrains) {
      if (otherTrain.id == train.id) continue;

      final distance = _getTrainDistance(train, otherTrain);
      if (distance < minimumTrainSeparation) {
        final violation = _createViolation(
          ruleType: SafetyRuleType.rearEndCollision,
          severity: ViolationSeverity.critical,
          description: 'Trains ${train.name} and ${otherTrain.name} too close: ${distance.toStringAsFixed(1)}m',
          context: {
            'train1': train.id,
            'train2': otherTrain.id,
            'distance': distance,
            'minimum': minimumTrainSeparation,
          },
        );

        return InterlockingCheckResult.invalid(
          reasons: ['Train separation below minimum safe distance'],
          violations: [violation],
        );
      }
    }

    return InterlockingCheckResult.valid();
  }

  /// Check speed restrictions
  InterlockingCheckResult _checkSpeedRestrictions(Train train) {
    // This would check against speed restriction zones
    // For now, return valid
    return InterlockingCheckResult.valid();
  }

  /// Check if a point can be safely moved
  bool _canMovePoint(String pointId) {
    final rule = pointProtectionRules[pointId];
    if (rule == null) return true; // No protection rule

    if (getAllTrainsCallback == null || isBlockOccupiedCallback == null) {
      return true; // Can't check, assume safe
    }

    // Check if any protected blocks are occupied
    for (final blockId in rule.protectedBlocks) {
      if (isBlockOccupiedCallback!(blockId)) {
        return false; // Block occupied, point is protected
      }
    }

    // Check if any trains are within detection radius
    final allTrains = getAllTrainsCallback!();
    if (allTrains != null) {
      final point = getPointCallback?.call(pointId);
      if (point != null) {
        for (final train in allTrains) {
          final distance = _calculateDistance(train.x, train.y, point.x, point.y);
          if (distance < rule.detectionRadius) {
            return false; // Train too close
          }
        }
      }
    }

    return true;
  }

  /// Validate path continuity
  bool _validatePathContinuity(List<String> pathBlocks) {
    // Simplified validation - would need track topology
    return pathBlocks.isNotEmpty;
  }

  /// Check if a route is active
  bool _isRouteActive(String routeId) {
    if (getAllSignalsCallback == null) return false;

    final signals = getAllSignalsCallback!();
    if (signals == null) return false;

    for (final signal in signals) {
      if (signal.activeRouteId == routeId && signal.routeState == RouteState.set) {
        return true;
      }
    }

    return false;
  }

  /// Check if train is approaching a signal
  bool _isTrainApproachingSignal(Train train, Signal signal) {
    // Check direction and position
    if (train.direction > 0) {
      // Eastbound - signal should be ahead
      return train.x < signal.x && (signal.x - train.x) < 100;
    } else if (train.direction < 0) {
      // Westbound - signal should be ahead
      return train.x > signal.x && (train.x - signal.x) < 100;
    }
    return false;
  }

  /// Get distance train has passed signal
  double _getDistancePastSignal(Train train, Signal signal) {
    if (train.direction > 0) {
      // Eastbound
      return train.x - signal.x;
    } else {
      // Westbound
      return signal.x - train.x;
    }
  }

  /// Calculate distance between two trains
  double _getTrainDistance(Train train1, Train train2) {
    return _calculateDistance(train1.x, train1.y, train2.x, train2.y);
  }

  /// Calculate distance between two points
  double _calculateDistance(double x1, double y1, double x2, double y2) {
    return ((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1)).abs().sqrt();
  }

  /// Create a safety violation
  SafetyViolation _createViolation({
    required SafetyRuleType ruleType,
    required ViolationSeverity severity,
    required String description,
    Map<String, dynamic>? context,
  }) {
    final id = 'VIO_${DateTime.now().millisecondsSinceEpoch}';
    return SafetyViolation(
      id: id,
      ruleType: ruleType,
      severity: severity,
      description: description,
      context: context,
    );
  }

  /// Register point protection rule
  void registerPointProtection(PointProtectionRule rule) {
    pointProtectionRules[rule.pointId] = rule;
    if (kDebugMode) {
      print('🛡️  Point protection registered for ${rule.pointId}');
    }
  }

  /// Activate emergency stop
  void activateEmergency(String reason) {
    _emergencyActivated = true;

    final violation = _createViolation(
      ruleType: SafetyRuleType.spadPrevention,
      severity: ViolationSeverity.emergency,
      description: 'Emergency activated: $reason',
      context: {'reason': reason},
    );

    violations.add(violation);
    totalViolations++;
    criticalViolations++;

    if (kDebugMode) {
      print('🚨 EMERGENCY ACTIVATED: $reason');
    }

    notifyListeners();
  }

  /// Deactivate emergency
  void deactivateEmergency(String operator) {
    _emergencyActivated = false;

    if (kDebugMode) {
      print('✅ Emergency deactivated by $operator');
    }

    notifyListeners();
  }

  /// Acknowledge violation
  void acknowledgeViolation(String violationId, String operator) {
    final violation = violations.where((v) => v.id == violationId).firstOrNull;
    if (violation != null) {
      violation.acknowledge(operator);
      notifyListeners();
    }
  }

  /// Get unacknowledged violations
  List<SafetyViolation> getUnacknowledgedViolations() {
    return violations.where((v) => !v.acknowledged).toList();
  }

  /// Get violations by severity
  List<SafetyViolation> getViolationsBySeverity(ViolationSeverity severity) {
    return violations.where((v) => v.severity == severity).toList();
  }

  /// Get active SPAD events
  List<SPADEvent> getActiveSPADEvents() {
    return spadEvents.where((e) => !e.resolved).toList();
  }

  /// Resolve SPAD event
  void resolveSPADEvent(String trainId) {
    for (final event in spadEvents) {
      if (event.trainId == trainId && !event.resolved) {
        event.resolved = true;
        if (kDebugMode) {
          print('✅ SPAD event resolved for train $trainId');
        }
      }
    }
    notifyListeners();
  }

  /// Clear old violations
  void clearOldViolations({Duration age = const Duration(hours: 24)}) {
    final cutoff = DateTime.now().subtract(age);
    violations.removeWhere((v) => v.timestamp.isBefore(cutoff) && v.acknowledged);
    spadEvents.removeWhere((e) => e.timestamp.isBefore(cutoff) && e.resolved);
    notifyListeners();
  }

  /// Get comprehensive diagnostics
  Map<String, dynamic> getDiagnostics() {
    final severityCounts = <ViolationSeverity, int>{};
    for (final violation in violations) {
      severityCounts[violation.severity] = (severityCounts[violation.severity] ?? 0) + 1;
    }

    return {
      'totalViolations': totalViolations,
      'criticalViolations': criticalViolations,
      'spadEventsCount': spadEventsCount,
      'conflictsDetected': conflictsDetected,
      'activeViolations': violations.length,
      'unacknowledgedViolations': getUnacknowledgedViolations().length,
      'activeSPADEvents': getActiveSPADEvents().length,
      'emergencyActivated': _emergencyActivated,
      'severityDistribution': severityCounts.map((k, v) =>
          MapEntry(k.toString().split('.').last, v)),
      'configurations': {
        'spadDetectionEnabled': spadDetectionEnabled,
        'pointProtectionEnabled': pointProtectionEnabled,
        'conflictDetectionEnabled': conflictDetectionEnabled,
        'emergencyStopEnabled': emergencyStopEnabled,
        'spadDetectionDistance': spadDetectionDistance,
        'minimumTrainSeparation': minimumTrainSeparation,
      },
    };
  }

  /// Export violation report
  Map<String, dynamic> exportViolationReport() {
    return {
      'generatedAt': DateTime.now().toIso8601String(),
      'totalViolations': totalViolations,
      'violations': violations.map((v) => v.toMap()).toList(),
      'spadEvents': spadEvents.map((e) => e.toMap()).toList(),
      'summary': getDiagnostics(),
    };
  }
}
