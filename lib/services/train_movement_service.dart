import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rail_champ/screens/terminal_station_models.dart';
import 'dart:math' as math;

// ============================================================================
// TRAIN MOVEMENT SERVICE
// Advanced train movement physics, speed control, automatic stopping,
// and intelligent train behavior management
// ============================================================================

/// Train movement profile
class MovementProfile {
  final double maxSpeed;
  final double acceleration;
  final double deceleration;
  final double emergencyBrakeRate;
  final double creeepSpeed;

  const MovementProfile({
    this.maxSpeed = 2.0,
    this.acceleration = 0.015,
    this.deceleration = 0.02,
    this.emergencyBrakeRate = 0.05,
    this.creeepSpeed = 0.2,
  });

  static const MovementProfile standard = MovementProfile();
  static const MovementProfile express = MovementProfile(
    maxSpeed: 3.0,
    acceleration: 0.02,
    deceleration: 0.025,
  );
  static const MovementProfile freight = MovementProfile(
    maxSpeed: 1.5,
    acceleration: 0.01,
    deceleration: 0.015,
  );
}

/// Train stop event
class TrainStopEvent {
  final String trainId;
  final String location;
  final DateTime arrivalTime;
  DateTime? departureTime;
  final String stopType;
  Duration get dwellTime => departureTime != null
      ? departureTime!.difference(arrivalTime)
      : DateTime.now().difference(arrivalTime);

  TrainStopEvent({
    required this.trainId,
    required this.location,
    DateTime? arrivalTime,
    this.departureTime,
    this.stopType = 'Platform',
  }) : arrivalTime = arrivalTime ?? DateTime.now();

  void depart() {
    departureTime = DateTime.now();
  }

  bool get hasLeft => departureTime != null;
}

/// Train movement state
enum TrainMovementState {
  stopped,
  accelerating,
  cruising,
  braking,
  emergencyBrake,
  approaching,
  departing,
}

/// Extended train data for movement tracking
class TrainMovementData {
  final Train train;
  MovementProfile profile;
  TrainMovementState state;
  double brakingDistance;
  double? targetStopX;
  String? targetStopId;
  List<TrainStopEvent> stopHistory;
  TrainStopEvent? currentStop;

  // Physics state
  double realSpeed;
  double acceleration;
  DateTime lastUpdateTime;
  int ticksSinceStateChange;

  // Automatic control
  bool automaticSpeedControl;
  bool automaticStoppingEnabled;
  double? nextSignalX;
  SignalAspect? nextSignalAspect;

  TrainMovementData({
    required this.train,
    MovementProfile? profile,
    this.state = TrainMovementState.stopped,
    this.brakingDistance = 0.0,
    this.targetStopX,
    this.targetStopId,
    List<TrainStopEvent>? stopHistory,
    this.currentStop,
    this.realSpeed = 0.0,
    this.acceleration = 0.0,
    DateTime? lastUpdateTime,
    this.ticksSinceStateChange = 0,
    this.automaticSpeedControl = true,
    this.automaticStoppingEnabled = true,
    this.nextSignalX,
    this.nextSignalAspect,
  })  : profile = profile ?? MovementProfile.standard,
        stopHistory = stopHistory ?? [],
        lastUpdateTime = lastUpdateTime ?? DateTime.now();

  void recordStop(String location, String stopType) {
    final stopEvent = TrainStopEvent(
      trainId: train.id,
      location: location,
      stopType: stopType,
    );
    stopHistory.add(stopEvent);
    currentStop = stopEvent;

    // Keep only last 50 stops
    if (stopHistory.length > 50) {
      stopHistory.removeAt(0);
    }
  }

  void departFromStop() {
    currentStop?.depart();
    currentStop = null;
  }

  Map<String, dynamic> getStatus() {
    return {
      'trainId': train.id,
      'state': state.toString(),
      'speed': realSpeed,
      'targetSpeed': train.targetSpeed,
      'acceleration': acceleration,
      'position': train.x,
      'direction': train.direction,
      'brakingDistance': brakingDistance,
      'targetStopX': targetStopX,
      'automaticSpeedControl': automaticSpeedControl,
      'automaticStoppingEnabled': automaticStoppingEnabled,
      'nextSignal': nextSignalX,
      'nextSignalAspect': nextSignalAspect?.toString(),
    };
  }
}

/// Comprehensive train movement service
class TrainMovementService extends ChangeNotifier {
  final Map<String, TrainMovementData> _trainData = {};

  // Callbacks
  Function()? getSignalsCallback;
  Function()? getPlatformsCallback;
  Function()? getTrainStopsCallback;
  Function(String trainId, String counterId)? onAxleCounterDetectionCallback;

  // Physics configuration
  double simulationSpeed = 1.0;
  double timeStep = 0.016; // ~60 FPS

  // Statistics
  int totalStops = 0;
  double totalDistanceTraveled = 0.0;

  TrainMovementService();

  /// Initialize train movement data
  void initializeTrain(Train train, {MovementProfile? profile}) {
    _trainData[train.id] = TrainMovementData(
      train: train,
      profile: profile,
    );
  }

  /// Get train movement data
  TrainMovementData? getTrainData(String trainId) {
    return _trainData[trainId];
  }

  /// Update train movement physics
  void updateTrainMovement(Train train) {
    final data = _trainData[train.id];
    if (data == null) {
      // Initialize if not exists
      initializeTrain(train);
      return;
    }

    final now = DateTime.now();
    final dt = now.difference(data.lastUpdateTime).inMilliseconds / 1000.0;
    data.lastUpdateTime = now;

    // Update tick counter
    data.ticksSinceStateChange++;

    // Calculate braking distance
    if (train.speed > 0) {
      data.brakingDistance = _calculateBrakingDistance(
        train.speed,
        data.profile.deceleration,
      );
    } else {
      data.brakingDistance = 0.0;
    }

    // Automatic speed control based on signals
    if (data.automaticSpeedControl) {
      _updateAutomaticSpeedControl(train, data);
    }

    // Automatic stopping at platforms/signals
    if (data.automaticStoppingEnabled) {
      _updateAutomaticStopping(train, data);
    }

    // Update movement state
    _updateMovementState(train, data);

    // Apply physics
    _applyPhysics(train, data, dt);

    // Update position
    final oldX = train.x;
    train.x += train.speed * train.direction * simulationSpeed;
    totalDistanceTraveled += (train.x - oldX).abs();

    // Ensure train stays in bounds
    train.x = train.x.clamp(0.0, 2000.0);

    notifyListeners();
  }

  /// Calculate braking distance
  double _calculateBrakingDistance(double speed, double deceleration) {
    if (deceleration <= 0) return 0.0;
    // Using physics: d = v² / (2 * a)
    return (speed * speed) / (2 * deceleration);
  }

  /// Update automatic speed control based on signal aspects
  void _updateAutomaticSpeedControl(Train train, TrainMovementData data) {
    final signals = getSignalsCallback?.call();
    if (signals == null) return;

    // Find next signal ahead of train
    Signal? nextSignal;
    double minDistance = double.infinity;

    for (final signal in signals) {
      double distance;
      if (train.direction > 0) {
        // Eastbound - look ahead
        distance = signal.x - train.x;
      } else {
        // Westbound - look ahead
        distance = train.x - signal.x;
      }

      if (distance > 0 && distance < minDistance) {
        minDistance = distance;
        nextSignal = signal;
      }
    }

    if (nextSignal != null) {
      data.nextSignalX = nextSignal.x;
      data.nextSignalAspect = nextSignal.aspect;

      // Adjust target speed based on signal aspect
      final distanceToSignal = minDistance;
      final newTargetSpeed = _calculateSpeedForSignal(
        nextSignal.aspect,
        distanceToSignal,
        data.profile,
      );

      train.targetSpeed = newTargetSpeed;

      if (kDebugMode && data.ticksSinceStateChange % 60 == 0) {
        print('🚂 ${train.name}: Signal ${nextSignal.id} at ${distanceToSignal.toStringAsFixed(1)}m, aspect: ${nextSignal.aspect.toString().split('.').last}, target speed: ${newTargetSpeed.toStringAsFixed(2)}');
      }
    } else {
      data.nextSignalX = null;
      data.nextSignalAspect = null;
    }
  }

  /// Calculate appropriate speed for signal aspect
  double _calculateSpeedForSignal(
    SignalAspect aspect,
    double distance,
    MovementProfile profile,
  ) {
    switch (aspect) {
      case SignalAspect.red:
        // Calculate speed needed to stop before signal
        if (distance < 10) return 0.0;
        final maxStopSpeed = math.sqrt(2 * profile.deceleration * (distance - 10));
        return math.min(maxStopSpeed, profile.maxSpeed);

      case SignalAspect.yellow:
        // Prepare to stop
        return profile.maxSpeed * 0.5;

      case SignalAspect.doubleYellow:
        // Reduced speed
        return profile.maxSpeed * 0.75;

      case SignalAspect.green:
        // Full speed
        return profile.maxSpeed;

      default:
        return profile.maxSpeed;
    }
  }

  /// Update automatic stopping at platforms
  void _updateAutomaticStopping(Train train, TrainMovementData data) {
    // Check train stops
    final trainStops = getTrainStopsCallback?.call();
    if (trainStops != null) {
      for (final stop in trainStops.values) {
        if (_isTrainAtStop(train, stop) && train.speed.abs() < 0.1) {
          // Train has stopped at this location
          if (data.targetStopId != stop.id) {
            data.recordStop(stop.id, 'Train Stop');
            data.targetStopId = stop.id;
            totalStops++;

            if (kDebugMode) {
              print('🛑 ${train.name} stopped at ${stop.id}');
            }

            // Auto-depart after dwell time
            Future.delayed(const Duration(seconds: 5), () {
              if (data.targetStopId == stop.id) {
                data.departFromStop();
                data.targetStopId = null;
                train.targetSpeed = data.profile.maxSpeed;

                if (kDebugMode) {
                  print('🚂 ${train.name} departing from ${stop.id}');
                }
              }
            });
          }
        }
      }
    }

    // Check platforms
    final platforms = getPlatformsCallback?.call();
    if (platforms != null) {
      for (final platform in platforms) {
        if (_isTrainAtPlatform(train, platform) && train.speed.abs() < 0.1) {
          if (data.targetStopId != platform.id) {
            data.recordStop(platform.name, 'Platform');
            data.targetStopId = platform.id;
            totalStops++;

            if (kDebugMode) {
              print('🛑 ${train.name} stopped at platform ${platform.name}');
            }

            // Auto-depart after dwell time
            Future.delayed(const Duration(seconds: 8), () {
              if (data.targetStopId == platform.id) {
                data.departFromStop();
                data.targetStopId = null;
                train.targetSpeed = data.profile.maxSpeed;

                if (kDebugMode) {
                  print('🚂 ${train.name} departing from platform ${platform.name}');
                }
              }
            });
          }
        }
      }
    }
  }

  /// Check if train is at a stop
  bool _isTrainAtStop(Train train, TrainStop stop) {
    return (train.x - stop.x).abs() < 15.0 && (train.y - stop.y).abs() < 10.0;
  }

  /// Check if train is at a platform
  bool _isTrainAtPlatform(Train train, Platform platform) {
    return train.x >= platform.startX &&
        train.x <= platform.endX &&
        (train.y - platform.y).abs() < 10.0;
  }

  /// Update movement state
  void _updateMovementState(Train train, TrainMovementData data) {
    final previousState = data.state;

    if (train.speed.abs() < 0.01) {
      data.state = TrainMovementState.stopped;
    } else if (train.targetSpeed > train.speed) {
      data.state = TrainMovementState.accelerating;
    } else if (train.targetSpeed < train.speed) {
      data.state = TrainMovementState.braking;
    } else {
      data.state = TrainMovementState.cruising;
    }

    // Reset tick counter on state change
    if (previousState != data.state) {
      data.ticksSinceStateChange = 0;
    }
  }

  /// Apply movement physics
  void _applyPhysics(Train train, TrainMovementData data, double dt) {
    final profile = data.profile;

    // Calculate acceleration based on state
    if (data.state == TrainMovementState.emergencyBrake) {
      data.acceleration = -profile.emergencyBrakeRate;
    } else if (train.speed < train.targetSpeed) {
      // Accelerate
      data.acceleration = profile.acceleration;
    } else if (train.speed > train.targetSpeed) {
      // Brake
      data.acceleration = -profile.deceleration;
    } else {
      data.acceleration = 0.0;
    }

    // Apply acceleration
    train.speed += data.acceleration * simulationSpeed;

    // Clamp speed
    train.speed = train.speed.clamp(0.0, profile.maxSpeed);

    // Round very small speeds to zero
    if (train.speed.abs() < 0.01) {
      train.speed = 0.0;
    }

    data.realSpeed = train.speed;
  }

  /// Apply emergency brake
  void applyEmergencyBrake(String trainId) {
    final data = _trainData[trainId];
    if (data != null) {
      data.state = TrainMovementState.emergencyBrake;
      data.train.targetSpeed = 0.0;

      if (kDebugMode) {
        print('🚨 Emergency brake applied to ${data.train.name}');
      }

      notifyListeners();
    }
  }

  /// Release emergency brake
  void releaseEmergencyBrake(String trainId) {
    final data = _trainData[trainId];
    if (data != null) {
      if (data.state == TrainMovementState.emergencyBrake) {
        data.state = TrainMovementState.stopped;
      }

      if (kDebugMode) {
        print('✅ Emergency brake released on ${data.train.name}');
      }

      notifyListeners();
    }
  }

  /// Set train speed
  void setTrainSpeed(String trainId, double targetSpeed) {
    final data = _trainData[trainId];
    if (data != null) {
      data.train.targetSpeed = targetSpeed.clamp(0.0, data.profile.maxSpeed);
      notifyListeners();
    }
  }

  /// Set movement profile
  void setMovementProfile(String trainId, MovementProfile profile) {
    final data = _trainData[trainId];
    if (data != null) {
      data.profile = profile;
      notifyListeners();
    }
  }

  /// Enable/disable automatic speed control
  void setAutomaticSpeedControl(String trainId, bool enabled) {
    final data = _trainData[trainId];
    if (data != null) {
      data.automaticSpeedControl = enabled;

      if (kDebugMode) {
        print('${enabled ? '✅' : '❌'} Automatic speed control ${enabled ? 'enabled' : 'disabled'} for ${data.train.name}');
      }

      notifyListeners();
    }
  }

  /// Enable/disable automatic stopping
  void setAutomaticStopping(String trainId, bool enabled) {
    final data = _trainData[trainId];
    if (data != null) {
      data.automaticStoppingEnabled = enabled;

      if (kDebugMode) {
        print('${enabled ? '✅' : '❌'} Automatic stopping ${enabled ? 'enabled' : 'disabled'} for ${data.train.name}');
      }

      notifyListeners();
    }
  }

  /// Get all trains in movement state
  List<Train> getTrainsByState(TrainMovementState state) {
    return _trainData.values
        .where((data) => data.state == state)
        .map((data) => data.train)
        .toList();
  }

  /// Get comprehensive diagnostics
  Map<String, dynamic> getDiagnostics() {
    final stateCounts = <TrainMovementState, int>{};
    for (final data in _trainData.values) {
      stateCounts[data.state] = (stateCounts[data.state] ?? 0) + 1;
    }

    return {
      'totalTrains': _trainData.length,
      'totalStops': totalStops,
      'totalDistanceTraveled': totalDistanceTraveled,
      'simulationSpeed': simulationSpeed,
      'stateDistribution': stateCounts.map((k, v) =>
          MapEntry(k.toString().split('.').last, v)),
      'trainsInMotion': _trainData.values.where((d) => d.train.speed > 0).length,
      'trainsStopped': _trainData.values.where((d) => d.train.speed == 0).length,
    };
  }

  /// Remove train
  void removeTrain(String trainId) {
    _trainData.remove(trainId);
    notifyListeners();
  }
}
