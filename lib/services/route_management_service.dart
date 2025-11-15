import 'package:flutter/foundation.dart';
import 'package:rail_champ/screens/terminal_station_models.dart';
import 'dart:async';

// ============================================================================
// ROUTE MANAGEMENT SERVICE
// Comprehensive route setting, cancellation, release, and reservation management
// Handles interlocking, conflict detection, and automatic route control
// ============================================================================

/// Route reservation for conflict detection
class RouteReservation {
  final String id;
  final String signalId;
  final String routeId;
  final List<String> reservedBlocks;
  final Map<String, PointPosition> reservedPoints;
  final DateTime createdAt;
  DateTime? expiresAt;
  bool isActive;
  RouteReservationPriority priority;

  RouteReservation({
    required this.id,
    required this.signalId,
    required this.routeId,
    required this.reservedBlocks,
    required this.reservedPoints,
    DateTime? createdAt,
    this.expiresAt,
    this.isActive = true,
    this.priority = RouteReservationPriority.normal,
  }) : createdAt = createdAt ?? DateTime.now();

  bool isExpired() {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'signalId': signalId,
      'routeId': routeId,
      'reservedBlocks': reservedBlocks,
      'reservedPoints': reservedPoints.map((k, v) => MapEntry(k, v.toString())),
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'isActive': isActive,
      'priority': priority.toString(),
    };
  }
}

/// Priority levels for route reservations
enum RouteReservationPriority {
  low,
  normal,
  high,
  emergency,
}

/// Release states for route cancellation
enum ReleaseState {
  inactive,
  armed,
  releasing,
  released,
}

/// Route setting result
class RouteSetResult {
  final bool success;
  final String message;
  final List<String> failureReasons;
  final RouteReservation? reservation;

  RouteSetResult({
    required this.success,
    required this.message,
    this.failureReasons = const [],
    this.reservation,
  });

  RouteSetResult.success({
    String? message,
    RouteReservation? reservation,
  }) : this(
          success: true,
          message: message ?? 'Route set successfully',
          reservation: reservation,
        );

  RouteSetResult.failure({
    required String message,
    List<String>? failureReasons,
  }) : this(
          success: false,
          message: message,
          failureReasons: failureReasons ?? [],
        );
}

/// Route event for logging
class RouteEvent {
  final String signalId;
  final String? routeId;
  final RouteEventType type;
  final DateTime timestamp;
  final String? reason;
  final Map<String, dynamic>? metadata;

  RouteEvent({
    required this.signalId,
    this.routeId,
    required this.type,
    DateTime? timestamp,
    this.reason,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();
}

enum RouteEventType {
  setRequested,
  setSuccess,
  setFailed,
  cancelRequested,
  cancelSuccess,
  releaseRequested,
  releaseSuccess,
  conflictDetected,
  reservationCreated,
  reservationExpired,
}

/// Comprehensive route management service
class RouteManagementService extends ChangeNotifier {
  final Map<String, RouteReservation> activeReservations = {};
  final List<RouteEvent> eventLog = [];

  // Release/cancellation state
  final Map<String, ReleaseState> _releaseStates = {};
  final Map<String, DateTime> _releaseTimers = {};
  final Map<String, Timer> _activeTimers = {};

  // Callbacks for external dependencies
  Function(String blockId)? isBlockOccupiedCallback;
  Function(String pointId, PointPosition position)? setPointPositionCallback;
  Function(String pointId)? getPointPositionCallback;
  Function(String signalId)? getSignalCallback;
  Function(List<String> blockIds)? areBlocksClearCallback;
  Function(String signalId, String? routeId, RouteState state)? updateSignalRouteCallback;

  // Configuration
  bool selfNormalizingPoints = true;
  Duration cancellationDelay = const Duration(seconds: 3);
  Duration releaseDelay = const Duration(seconds: 2);
  Duration reservationTimeout = const Duration(minutes: 30);

  // Statistics
  int totalRoutesSet = 0;
  int totalRoutesCancelled = 0;
  int totalRoutesReleased = 0;
  int totalConflicts = 0;

  RouteManagementService();

  /// Set a route for a signal
  RouteSetResult setRoute(String signalId, String routeId) {
    final signal = getSignalCallback?.call(signalId);
    if (signal == null) {
      return RouteSetResult.failure(
        message: 'Signal $signalId not found',
        failureReasons: ['Signal not found'],
      );
    }

    // Find the route
    final route = signal.routes.where((r) => r.id == routeId).firstOrNull;
    if (route == null) {
      return RouteSetResult.failure(
        message: 'Route $routeId not found for signal $signalId',
        failureReasons: ['Route not found'],
      );
    }

    // Log event
    _logEvent(RouteEvent(
      signalId: signalId,
      routeId: routeId,
      type: RouteEventType.setRequested,
    ));

    // Check if signal already has an active route
    if (signal.activeRouteId != null && signal.routeState == RouteState.set) {
      return RouteSetResult.failure(
        message: 'Signal $signalId already has active route ${signal.activeRouteId}',
        failureReasons: ['Route already active'],
      );
    }

    // Check for conflicting routes
    final conflicts = _checkRouteConflicts(signalId, route);
    if (conflicts.isNotEmpty) {
      totalConflicts++;
      _logEvent(RouteEvent(
        signalId: signalId,
        routeId: routeId,
        type: RouteEventType.conflictDetected,
        metadata: {'conflicts': conflicts},
      ));

      return RouteSetResult.failure(
        message: 'Route conflicts detected',
        failureReasons: conflicts,
      );
    }

    // Check if all required blocks are clear
    if (areBlocksClearCallback != null) {
      if (!areBlocksClearCallback!(route.requiredBlocksClear)) {
        return RouteSetResult.failure(
          message: 'Not all required blocks are clear',
          failureReasons: ['Blocks occupied'],
        );
      }
    }

    // Check if all points can be set to required positions
    final pointSetResult = _setRequiredPoints(route.requiredPointPositions);
    if (!pointSetResult) {
      return RouteSetResult.failure(
        message: 'Failed to set points to required positions',
        failureReasons: ['Point setting failed'],
      );
    }

    // Create route reservation
    final reservation = _createReservation(signalId, routeId, route);

    // Update signal route state
    updateSignalRouteCallback?.call(signalId, routeId, RouteState.set);

    // Log success
    _logEvent(RouteEvent(
      signalId: signalId,
      routeId: routeId,
      type: RouteEventType.setSuccess,
    ));

    totalRoutesSet++;

    if (kDebugMode) {
      print('✅ Route set: Signal $signalId, Route $routeId');
    }

    notifyListeners();

    return RouteSetResult.success(
      message: 'Route $routeId set for signal $signalId',
      reservation: reservation,
    );
  }

  /// Check for route conflicts
  List<String> _checkRouteConflicts(String signalId, SignalRoute route) {
    final conflicts = <String>[];

    // Check for conflicting route IDs
    for (final conflictingRouteId in route.conflictingRoutes) {
      // Check if any reservation exists for this conflicting route
      for (final reservation in activeReservations.values) {
        if (reservation.routeId == conflictingRouteId && reservation.isActive) {
          conflicts.add('Conflicting route $conflictingRouteId is active');
        }
      }
    }

    // Check for block conflicts
    for (final blockId in route.pathBlocks) {
      for (final reservation in activeReservations.values) {
        if (reservation.reservedBlocks.contains(blockId) &&
            reservation.isActive &&
            reservation.signalId != signalId) {
          conflicts.add('Block $blockId already reserved by ${reservation.signalId}');
        }
      }
    }

    // Check for point conflicts
    for (final pointEntry in route.requiredPointPositions.entries) {
      for (final reservation in activeReservations.values) {
        if (reservation.reservedPoints.containsKey(pointEntry.key) &&
            reservation.reservedPoints[pointEntry.key] != pointEntry.value &&
            reservation.isActive &&
            reservation.signalId != signalId) {
          conflicts.add('Point ${pointEntry.key} required in conflicting position');
        }
      }
    }

    return conflicts;
  }

  /// Set required points to their positions
  bool _setRequiredPoints(Map<String, PointPosition> requiredPositions) {
    if (setPointPositionCallback == null || getPointPositionCallback == null) {
      return true; // No point control available
    }

    for (final entry in requiredPositions.entries) {
      final currentPosition = getPointPositionCallback!(entry.key);
      if (currentPosition != entry.value) {
        // Try to set point to required position
        setPointPositionCallback!(entry.key, entry.value);

        // Verify point was set
        final newPosition = getPointPositionCallback!(entry.key);
        if (newPosition != entry.value) {
          if (kDebugMode) {
            print('❌ Failed to set point ${entry.key} to ${entry.value}');
          }
          return false;
        }
      }
    }

    return true;
  }

  /// Create a route reservation
  RouteReservation _createReservation(String signalId, String routeId, SignalRoute route) {
    final reservationId = 'RES_${signalId}_${DateTime.now().millisecondsSinceEpoch}';

    final reservation = RouteReservation(
      id: reservationId,
      signalId: signalId,
      routeId: routeId,
      reservedBlocks: [...route.pathBlocks, ...route.protectedBlocks],
      reservedPoints: Map.from(route.requiredPointPositions),
      expiresAt: DateTime.now().add(reservationTimeout),
    );

    activeReservations[reservationId] = reservation;

    _logEvent(RouteEvent(
      signalId: signalId,
      routeId: routeId,
      type: RouteEventType.reservationCreated,
      metadata: {'reservationId': reservationId},
    ));

    if (kDebugMode) {
      print('📋 Route reservation created: $reservationId');
    }

    return reservation;
  }

  /// Cancel a route (with delay)
  void cancelRoute(String signalId) {
    final signal = getSignalCallback?.call(signalId);
    if (signal == null) return;

    _logEvent(RouteEvent(
      signalId: signalId,
      routeId: signal.activeRouteId,
      type: RouteEventType.cancelRequested,
    ));

    if (signal.activeRouteId == null) {
      if (kDebugMode) {
        print('⚠️  No active route to cancel for signal $signalId');
      }
      return;
    }

    // Start cancellation timer
    _releaseStates[signalId] = ReleaseState.armed;
    _releaseTimers[signalId] = DateTime.now().add(cancellationDelay);

    _activeTimers[signalId]?.cancel();
    _activeTimers[signalId] = Timer(cancellationDelay, () {
      _executeCancellation(signalId);
    });

    if (kDebugMode) {
      print('⏱️  Route cancellation armed for signal $signalId (${cancellationDelay.inSeconds}s)');
    }

    notifyListeners();
  }

  /// Execute route cancellation
  void _executeCancellation(String signalId) {
    final signal = getSignalCallback?.call(signalId);
    if (signal == null) return;

    final routeId = signal.activeRouteId;

    // Clear reservation
    _clearReservationForSignal(signalId);

    // Normalize points if enabled
    if (selfNormalizingPoints && routeId != null) {
      final route = signal.routes.where((r) => r.id == routeId).firstOrNull;
      if (route != null) {
        _normalizePoints(route.requiredPointPositions);
      }
    }

    // Update signal state
    updateSignalRouteCallback?.call(signalId, null, RouteState.unset);

    _releaseStates[signalId] = ReleaseState.inactive;
    _releaseTimers.remove(signalId);
    _activeTimers[signalId]?.cancel();
    _activeTimers.remove(signalId);

    totalRoutesCancelled++;

    _logEvent(RouteEvent(
      signalId: signalId,
      routeId: routeId,
      type: RouteEventType.cancelSuccess,
    ));

    if (kDebugMode) {
      print('❌ Route cancelled for signal $signalId');
    }

    notifyListeners();
  }

  /// Release a route (for trains that have passed)
  void releaseRoute(String signalId) {
    final signal = getSignalCallback?.call(signalId);
    if (signal == null) return;

    _logEvent(RouteEvent(
      signalId: signalId,
      routeId: signal.activeRouteId,
      type: RouteEventType.releaseRequested,
    ));

    if (signal.activeRouteId == null) {
      if (kDebugMode) {
        print('⚠️  No active route to release for signal $signalId');
      }
      return;
    }

    // Immediate release (train has passed)
    _clearReservationForSignal(signalId);

    // Normalize points if enabled
    final routeId = signal.activeRouteId;
    if (selfNormalizingPoints && routeId != null) {
      final route = signal.routes.where((r) => r.id == routeId).firstOrNull;
      if (route != null) {
        _normalizePoints(route.requiredPointPositions);
      }
    }

    // Update signal state
    updateSignalRouteCallback?.call(signalId, null, RouteState.unset);

    totalRoutesReleased++;

    _logEvent(RouteEvent(
      signalId: signalId,
      routeId: routeId,
      type: RouteEventType.releaseSuccess,
    ));

    if (kDebugMode) {
      print('✅ Route released for signal $signalId');
    }

    notifyListeners();
  }

  /// Clear reservation for a signal
  void _clearReservationForSignal(String signalId) {
    activeReservations.removeWhere((id, res) => res.signalId == signalId);
  }

  /// Normalize points to default position (typically normal/straight)
  void _normalizePoints(Map<String, PointPosition> points) {
    if (setPointPositionCallback == null) return;

    for (final pointId in points.keys) {
      // Set to normal position
      setPointPositionCallback!(pointId, PointPosition.normal);

      if (kDebugMode) {
        print('🔄 Point $pointId normalized to NORMAL');
      }
    }
  }

  /// Check if a route is active for a signal
  bool isRouteActive(String signalId) {
    final signal = getSignalCallback?.call(signalId);
    if (signal == null) return false;

    return signal.activeRouteId != null && signal.routeState == RouteState.set;
  }

  /// Get active reservation for a signal
  RouteReservation? getReservationForSignal(String signalId) {
    return activeReservations.values
        .where((res) => res.signalId == signalId && res.isActive)
        .firstOrNull;
  }

  /// Get all conflicting reservations for a route
  List<RouteReservation> getConflictingReservations(String signalId, SignalRoute route) {
    final conflicts = <RouteReservation>[];

    for (final reservation in activeReservations.values) {
      if (!reservation.isActive || reservation.signalId == signalId) continue;

      // Check block conflicts
      for (final blockId in route.pathBlocks) {
        if (reservation.reservedBlocks.contains(blockId)) {
          conflicts.add(reservation);
          break;
        }
      }
    }

    return conflicts;
  }

  /// Clean up expired reservations
  void cleanupExpiredReservations() {
    final expired = activeReservations.entries
        .where((entry) => entry.value.isExpired())
        .map((entry) => entry.key)
        .toList();

    for (final id in expired) {
      final reservation = activeReservations[id]!;
      activeReservations.remove(id);

      _logEvent(RouteEvent(
        signalId: reservation.signalId,
        routeId: reservation.routeId,
        type: RouteEventType.reservationExpired,
        metadata: {'reservationId': id},
      ));

      if (kDebugMode) {
        print('⏰ Reservation expired: $id');
      }
    }

    if (expired.isNotEmpty) {
      notifyListeners();
    }
  }

  /// Get release state for a signal
  ReleaseState getReleaseState(String signalId) {
    return _releaseStates[signalId] ?? ReleaseState.inactive;
  }

  /// Get release countdown for a signal
  int getReleaseCountdown(String signalId) {
    final releaseTime = _releaseTimers[signalId];
    if (releaseTime == null) return 0;

    final remaining = releaseTime.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Log an event
  void _logEvent(RouteEvent event) {
    eventLog.add(event);

    // Keep log size manageable
    if (eventLog.length > 500) {
      eventLog.removeAt(0);
    }
  }

  /// Get recent events
  List<RouteEvent> getRecentEvents({int limit = 50}) {
    final events = List<RouteEvent>.from(eventLog);
    if (events.length > limit) {
      return events.sublist(events.length - limit);
    }
    return events;
  }

  /// Reset all routes
  void resetAllRoutes() {
    // Cancel all active timers
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }

    activeReservations.clear();
    _releaseStates.clear();
    _releaseTimers.clear();
    _activeTimers.clear();

    if (kDebugMode) {
      print('🔄 All routes reset');
    }

    notifyListeners();
  }

  /// Get comprehensive diagnostics
  Map<String, dynamic> getDiagnostics() {
    return {
      'totalRoutesSet': totalRoutesSet,
      'totalRoutesCancelled': totalRoutesCancelled,
      'totalRoutesReleased': totalRoutesReleased,
      'totalConflicts': totalConflicts,
      'activeReservations': activeReservations.length,
      'activeTimers': _activeTimers.length,
      'selfNormalizingPoints': selfNormalizingPoints,
      'reservations': activeReservations.values.map((r) => r.toMap()).toList(),
    };
  }

  /// Cleanup
  @override
  void dispose() {
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }
}
