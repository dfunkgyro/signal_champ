import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rail_champ/screens/terminal_station_models.dart';
import 'dart:async';

// ============================================================================
// SIGNAL CONTROL SERVICE
// Comprehensive signal management including aspect control, route setting,
// automatic signal control, and safety interlocking
// ============================================================================

/// Signal aspect change event
class SignalAspectChangeEvent {
  final String signalId;
  final SignalAspect previousAspect;
  final SignalAspect newAspect;
  final DateTime timestamp;
  final String reason;

  SignalAspectChangeEvent({
    required this.signalId,
    required this.previousAspect,
    required this.newAspect,
    DateTime? timestamp,
    required this.reason,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Signal control mode
enum SignalControlMode {
  manual,       // Manual signal control by operator
  automatic,    // Automatic signal control based on occupancy
  semiAutomatic, // Semi-automatic with operator confirmation
  restricted,   // Restricted operation mode
  emergency,    // Emergency mode - all signals to danger
}

/// Signal health status
enum SignalHealthStatus {
  operational,
  degraded,
  failed,
  maintenance,
  testing,
}

/// Enhanced signal with additional operational data
class SignalData {
  final Signal signal;
  SignalControlMode controlMode;
  SignalHealthStatus healthStatus;
  DateTime? lastAspectChange;
  DateTime? lastMaintenance;
  int aspectChanges;
  List<SignalAspectChangeEvent> changeHistory;
  bool isLocked;
  String? lockReason;
  Timer? autoRefreshTimer;

  SignalData({
    required this.signal,
    this.controlMode = SignalControlMode.automatic,
    this.healthStatus = SignalHealthStatus.operational,
    this.lastAspectChange,
    this.lastMaintenance,
    this.aspectChanges = 0,
    List<SignalAspectChangeEvent>? changeHistory,
    this.isLocked = false,
    this.lockReason,
    this.autoRefreshTimer,
  }) : changeHistory = changeHistory ?? [];

  void recordAspectChange(SignalAspect previous, SignalAspect newAspect, String reason) {
    changeHistory.add(SignalAspectChangeEvent(
      signalId: signal.id,
      previousAspect: previous,
      newAspect: newAspect,
      reason: reason,
    ));

    // Keep only last 50 changes
    if (changeHistory.length > 50) {
      changeHistory.removeAt(0);
    }

    aspectChanges++;
    lastAspectChange = DateTime.now();
  }

  bool needsMaintenance() {
    if (lastMaintenance == null) return true;
    final daysSince = DateTime.now().difference(lastMaintenance!).inDays;
    return daysSince > 180 || aspectChanges > 10000;
  }

  Map<String, dynamic> getStatus() {
    return {
      'id': signal.id,
      'aspect': signal.aspect.toString(),
      'controlMode': controlMode.toString(),
      'healthStatus': healthStatus.toString(),
      'isLocked': isLocked,
      'lockReason': lockReason,
      'aspectChanges': aspectChanges,
      'needsMaintenance': needsMaintenance(),
      'activeRoute': signal.activeRouteId,
      'routeState': signal.routeState.toString(),
    };
  }
}

/// Comprehensive signal control service
class SignalControlService extends ChangeNotifier {
  final Map<String, SignalData> _signalData = {};
  final List<SignalAspectChangeEvent> _globalHistory = [];

  // Callbacks for external dependencies
  Function(String blockId)? isBlockOccupiedCallback;
  Function(String pointId, PointPosition position)? isPointInPositionCallback;
  Function(String routeId)? isRouteConflictingCallback;

  // Performance metrics
  int totalAspectChanges = 0;
  int failedAspectChanges = 0;
  DateTime? lastUpdate;

  // Emergency mode
  bool _emergencyMode = false;
  bool get emergencyMode => _emergencyMode;

  SignalControlService();

  /// Initialize signal data
  void initializeSignal(Signal signal, {SignalControlMode controlMode = SignalControlMode.automatic}) {
    _signalData[signal.id] = SignalData(
      signal: signal,
      controlMode: controlMode,
      healthStatus: SignalHealthStatus.operational,
      lastMaintenance: DateTime.now(),
    );
  }

  /// Get signal data
  SignalData? getSignalData(String signalId) {
    return _signalData[signalId];
  }

  /// Set signal aspect with validation and logging
  bool setSignalAspect(
    String signalId,
    SignalAspect newAspect, {
    String reason = 'Manual control',
    bool force = false,
  }) {
    final signalData = _signalData[signalId];
    if (signalData == null) {
      if (kDebugMode) print('❌ Signal $signalId not found');
      failedAspectChanges++;
      return false;
    }

    final signal = signalData.signal;

    // Check if signal is locked
    if (signalData.isLocked && !force) {
      if (kDebugMode) {
        print('🔒 Signal $signalId is locked: ${signalData.lockReason}');
      }
      failedAspectChanges++;
      return false;
    }

    // Check emergency mode
    if (_emergencyMode && newAspect != SignalAspect.red && !force) {
      if (kDebugMode) {
        print('🚨 Emergency mode active - cannot clear signal $signalId');
      }
      failedAspectChanges++;
      return false;
    }

    // Check signal health
    if (signalData.healthStatus == SignalHealthStatus.failed && !force) {
      if (kDebugMode) {
        print('⚠️  Signal $signalId has failed - cannot change aspect');
      }
      failedAspectChanges++;
      return false;
    }

    final previousAspect = signal.aspect;
    signal.aspect = newAspect;

    // Record change
    signalData.recordAspectChange(previousAspect, newAspect, reason);
    _globalHistory.add(SignalAspectChangeEvent(
      signalId: signalId,
      previousAspect: previousAspect,
      newAspect: newAspect,
      reason: reason,
    ));

    // Keep global history size manageable
    if (_globalHistory.length > 200) {
      _globalHistory.removeAt(0);
    }

    totalAspectChanges++;
    lastUpdate = DateTime.now();

    if (kDebugMode) {
      print('🚦 Signal $signalId: ${previousAspect.toString().split('.').last} → ${newAspect.toString().split('.').last} ($reason)');
    }

    notifyListeners();
    return true;
  }

  /// Automatically update signal aspect based on route and occupancy
  bool updateSignalAspectAuto(String signalId) {
    final signalData = _signalData[signalId];
    if (signalData == null) return false;

    final signal = signalData.signal;

    // Skip if not in automatic mode
    if (signalData.controlMode != SignalControlMode.automatic &&
        signalData.controlMode != SignalControlMode.semiAutomatic) {
      return false;
    }

    // Emergency mode overrides all
    if (_emergencyMode) {
      return setSignalAspect(signalId, SignalAspect.red, reason: 'Emergency mode', force: true);
    }

    // If no active route, signal should be red
    if (signal.activeRouteId == null || signal.routeState != RouteState.set) {
      return setSignalAspect(signalId, SignalAspect.red, reason: 'No active route');
    }

    // Find the active route
    final route = signal.routes.firstWhere(
      (r) => r.id == signal.activeRouteId,
      orElse: () => signal.routes.first,
    );

    // Check if route is still valid
    if (!_isRouteValid(route)) {
      // Route no longer valid - clear signal
      return setSignalAspect(signalId, SignalAspect.red, reason: 'Route no longer valid');
    }

    // Determine appropriate aspect based on route conditions
    final aspect = _calculateOptimalAspect(signalId, route);
    return setSignalAspect(signalId, aspect, reason: 'Automatic update');
  }

  /// Calculate optimal signal aspect based on route conditions
  SignalAspect _calculateOptimalAspect(String signalId, SignalRoute route) {
    // Check if all route blocks are clear
    bool allBlocksClear = true;
    if (isBlockOccupiedCallback != null) {
      for (final blockId in route.pathBlocks) {
        if (isBlockOccupiedCallback!(blockId)) {
          allBlocksClear = false;
          break;
        }
      }
    }

    if (!allBlocksClear) {
      return SignalAspect.red;
    }

    // Check next signal ahead (simplified - would need track circuit info)
    // For now, use green if all blocks clear
    return SignalAspect.green;
  }

  /// Validate if a route is still valid
  bool _isRouteValid(SignalRoute route) {
    // Check all required blocks are clear
    if (isBlockOccupiedCallback != null) {
      for (final blockId in route.requiredBlocksClear) {
        if (isBlockOccupiedCallback!(blockId)) {
          return false;
        }
      }
    }

    // Check all required point positions
    if (isPointInPositionCallback != null) {
      for (final entry in route.requiredPointPositions.entries) {
        if (!isPointInPositionCallback!(entry.key, entry.value)) {
          return false;
        }
      }
    }

    // Check for conflicting routes
    if (isRouteConflictingCallback != null) {
      for (final conflictingRoute in route.conflictingRoutes) {
        if (isRouteConflictingCallback!(conflictingRoute)) {
          return false;
        }
      }
    }

    return true;
  }

  /// Lock a signal (prevent aspect changes)
  void lockSignal(String signalId, String reason) {
    final signalData = _signalData[signalId];
    if (signalData != null) {
      signalData.isLocked = true;
      signalData.lockReason = reason;

      if (kDebugMode) {
        print('🔒 Signal $signalId locked: $reason');
      }

      notifyListeners();
    }
  }

  /// Unlock a signal
  void unlockSignal(String signalId) {
    final signalData = _signalData[signalId];
    if (signalData != null) {
      signalData.isLocked = false;
      signalData.lockReason = null;

      if (kDebugMode) {
        print('🔓 Signal $signalId unlocked');
      }

      notifyListeners();
    }
  }

  /// Set signal control mode
  void setControlMode(String signalId, SignalControlMode mode) {
    final signalData = _signalData[signalId];
    if (signalData != null) {
      final previous = signalData.controlMode;
      signalData.controlMode = mode;

      if (kDebugMode) {
        print('🎛️  Signal $signalId control mode: ${previous.toString().split('.').last} → ${mode.toString().split('.').last}');
      }

      notifyListeners();
    }
  }

  /// Set signal health status
  void setHealthStatus(String signalId, SignalHealthStatus status) {
    final signalData = _signalData[signalId];
    if (signalData != null) {
      signalData.healthStatus = status;

      if (status == SignalHealthStatus.failed) {
        // Automatically set to red if failed
        setSignalAspect(signalId, SignalAspect.red, reason: 'Signal failure', force: true);
        lockSignal(signalId, 'Signal failure');
      }

      if (kDebugMode) {
        print('🏥 Signal $signalId health status: ${status.toString().split('.').last}');
      }

      notifyListeners();
    }
  }

  /// Enter emergency mode - all signals to danger
  void activateEmergencyMode(String reason) {
    _emergencyMode = true;

    if (kDebugMode) {
      print('🚨 EMERGENCY MODE ACTIVATED: $reason');
    }

    // Set all signals to red
    for (final signalData in _signalData.values) {
      setSignalAspect(
        signalData.signal.id,
        SignalAspect.red,
        reason: 'Emergency mode: $reason',
        force: true,
      );
    }

    notifyListeners();
  }

  /// Exit emergency mode
  void deactivateEmergencyMode() {
    _emergencyMode = false;

    if (kDebugMode) {
      print('✅ Emergency mode deactivated');
    }

    notifyListeners();
  }

  /// Update all automatic signals
  void updateAllAutomaticSignals() {
    for (final signalData in _signalData.values) {
      if (signalData.controlMode == SignalControlMode.automatic) {
        updateSignalAspectAuto(signalData.signal.id);
      }
    }
  }

  /// Get signals needing maintenance
  List<SignalData> getSignalsNeedingMaintenance() {
    return _signalData.values
        .where((sd) => sd.needsMaintenance())
        .toList();
  }

  /// Perform maintenance on signal
  void performMaintenance(String signalId) {
    final signalData = _signalData[signalId];
    if (signalData != null) {
      signalData.lastMaintenance = DateTime.now();
      signalData.aspectChanges = 0;
      signalData.healthStatus = SignalHealthStatus.operational;

      if (kDebugMode) {
        print('🔧 Maintenance performed on signal $signalId');
      }

      notifyListeners();
    }
  }

  /// Get signal aspect progression sequence (for approach control)
  List<SignalAspect> getAspectProgression() {
    return [
      SignalAspect.red,
      SignalAspect.yellow,
      SignalAspect.doubleYellow,
      SignalAspect.green,
    ];
  }

  /// Calculate next aspect in progression
  SignalAspect? getNextAspect(SignalAspect current) {
    final progression = getAspectProgression();
    final currentIndex = progression.indexOf(current);
    if (currentIndex < 0 || currentIndex >= progression.length - 1) {
      return null;
    }
    return progression[currentIndex + 1];
  }

  /// Calculate previous aspect in progression
  SignalAspect? getPreviousAspect(SignalAspect current) {
    final progression = getAspectProgression();
    final currentIndex = progression.indexOf(current);
    if (currentIndex <= 0) {
      return null;
    }
    return progression[currentIndex - 1];
  }

  /// Get all signals with specific aspect
  List<Signal> getSignalsByAspect(SignalAspect aspect) {
    return _signalData.values
        .where((sd) => sd.signal.aspect == aspect)
        .map((sd) => sd.signal)
        .toList();
  }

  /// Get all signals in specific control mode
  List<Signal> getSignalsByControlMode(SignalControlMode mode) {
    return _signalData.values
        .where((sd) => sd.controlMode == mode)
        .map((sd) => sd.signal)
        .toList();
  }

  /// Reset all signals to danger
  void resetAllSignals() {
    for (final signalData in _signalData.values) {
      setSignalAspect(
        signalData.signal.id,
        SignalAspect.red,
        reason: 'System reset',
        force: true,
      );
      signalData.signal.activeRouteId = null;
      signalData.signal.routeState = RouteState.unset;
    }

    if (kDebugMode) {
      print('🔄 All signals reset to danger');
    }

    notifyListeners();
  }

  /// Get comprehensive diagnostics
  Map<String, dynamic> getDiagnostics() {
    final aspectCounts = <SignalAspect, int>{};
    final modeCounts = <SignalControlMode, int>{};
    final healthCounts = <SignalHealthStatus, int>{};

    for (final signalData in _signalData.values) {
      aspectCounts[signalData.signal.aspect] =
          (aspectCounts[signalData.signal.aspect] ?? 0) + 1;
      modeCounts[signalData.controlMode] =
          (modeCounts[signalData.controlMode] ?? 0) + 1;
      healthCounts[signalData.healthStatus] =
          (healthCounts[signalData.healthStatus] ?? 0) + 1;
    }

    return {
      'totalSignals': _signalData.length,
      'totalAspectChanges': totalAspectChanges,
      'failedAspectChanges': failedAspectChanges,
      'emergencyMode': _emergencyMode,
      'lastUpdate': lastUpdate?.toIso8601String(),
      'aspectDistribution': aspectCounts.map((k, v) =>
          MapEntry(k.toString().split('.').last, v)),
      'controlModeDistribution': modeCounts.map((k, v) =>
          MapEntry(k.toString().split('.').last, v)),
      'healthDistribution': healthCounts.map((k, v) =>
          MapEntry(k.toString().split('.').last, v)),
      'signalsNeedingMaintenance': getSignalsNeedingMaintenance().length,
      'lockedSignals': _signalData.values.where((sd) => sd.isLocked).length,
    };
  }

  /// Get recent signal changes
  List<SignalAspectChangeEvent> getRecentChanges({int limit = 20}) {
    final events = List<SignalAspectChangeEvent>.from(_globalHistory);
    if (events.length > limit) {
      return events.sublist(events.length - limit);
    }
    return events;
  }

  /// Cleanup method
  void dispose() {
    for (final signalData in _signalData.values) {
      signalData.autoRefreshTimer?.cancel();
    }
    super.dispose();
  }
}
