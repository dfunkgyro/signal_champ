import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/simulation/entities.dart';

// ============================================================================
// RAILWAY SIMULATION CONTROLLER WITH PROPER SIGNALLING
// ============================================================================

class RailwaySimulationController extends ChangeNotifier {
  final List<Train> trains = [];
  final List<BlockSection> blocks = [];
  final List<Signal> signals = [];
  final List<Platform> platforms = [];

  bool isRunning = false;
  double simulationSpeed = 1.0;
  int simulationTime = 0; // in ticks

  // Track layout constants
  static const double trackY = 300;
  static const double blockLength = 200;
  static const double overlapLength = 50;
  static const double platformLength = 150;
  static const double signalDistance = 30; // Distance before block

  RailwaySimulationController() {
    _initializeRailwayLayout();
  }

  void _initializeRailwayLayout() {
    // Create a longer track with 12 main blocks + overlap blocks
    // Layout: Platform1 - Blocks - Station - Blocks - Platform2

    double currentX = 100;

    // ===== PLATFORM 1 (WESTBOUND TERMINUS) =====
    platforms.add(Platform(
      id: 'P1',
      name: 'Platform 1 (Westbound)',
      startX: currentX,
      endX: currentX + platformLength,
      y: trackY,
    ));
    currentX += platformLength + 20;

    // ===== MAIN LINE BLOCKS (1-5) =====
    for (int i = 1; i <= 5; i++) {
      // Main block
      blocks.add(BlockSection(
        id: 'B$i',
        startX: currentX,
        endX: currentX + blockLength,
        y: trackY,
      ));

      // Signal protecting this block
      signals.add(Signal(
        id: 'S$i',
        x: currentX - signalDistance,
        y: trackY - 10,
        protectsBlockId: 'B$i',
        overlapBlockId: 'OL$i',
      ));

      currentX += blockLength;

      // Overlap block after main block
      blocks.add(BlockSection(
        id: 'OL$i',
        startX: currentX,
        endX: currentX + overlapLength,
        y: trackY,
        isOverlapBlock: true,
      ));

      currentX += overlapLength + 10;
    }

    // ===== STATION (PLATFORM 2 - CENTRAL STATION) =====
    platforms.add(Platform(
      id: 'P2',
      name: 'Central Station',
      startX: currentX,
      endX: currentX + platformLength,
      y: trackY,
    ));

    // Signal before station
    signals.add(Signal(
      id: 'S_STATION',
      x: currentX - signalDistance,
      y: trackY - 10,
      protectsBlockId: 'B_STATION',
    ));

    // Station block
    blocks.add(BlockSection(
      id: 'B_STATION',
      startX: currentX,
      endX: currentX + platformLength,
      y: trackY,
    ));

    currentX += platformLength + 20;

    // ===== MAIN LINE BLOCKS (6-10) =====
    for (int i = 6; i <= 10; i++) {
      // Main block
      blocks.add(BlockSection(
        id: 'B$i',
        startX: currentX,
        endX: currentX + blockLength,
        y: trackY,
      ));

      // Signal protecting this block
      signals.add(Signal(
        id: 'S$i',
        x: currentX - signalDistance,
        y: trackY - 10,
        protectsBlockId: 'B$i',
        overlapBlockId: 'OL$i',
      ));

      currentX += blockLength;

      // Overlap block
      blocks.add(BlockSection(
        id: 'OL$i',
        startX: currentX,
        endX: currentX + overlapLength,
        y: trackY,
        isOverlapBlock: true,
      ));

      currentX += overlapLength + 10;
    }

    // ===== PLATFORM 3 (EASTBOUND TERMINUS) =====
    platforms.add(Platform(
      id: 'P3',
      name: 'Platform 3 (Eastbound)',
      startX: currentX,
      endX: currentX + platformLength,
      y: trackY,
    ));

    // Signal before terminus
    signals.add(Signal(
      id: 'S_TERMINUS',
      x: currentX - signalDistance,
      y: trackY - 10,
      protectsBlockId: 'B_TERMINUS',
    ));

    // Terminus block
    blocks.add(BlockSection(
      id: 'B_TERMINUS',
      startX: currentX,
      endX: currentX + platformLength,
      y: trackY,
    ));

    // Initialize all signals to red (safe state)
    for (var signal in signals) {
      signal.aspect = SignalAspect.red;
    }
  }

  void addTrain({String? startPlatformId}) {
    startPlatformId ??= 'P1'; // Default to Platform 1

    final platform = platforms.firstWhere((p) => p.id == startPlatformId);

    trains.add(Train(
      id: 'T${trains.length + 1}',
      name: 'Train ${trains.length + 1}',
      x: platform.centerX,
      y: trackY,
      speed: 0,
      maxSpeed: 2.0 + (trains.length * 0.2), // Vary speeds slightly
      color: Colors.primaries[trains.length % Colors.primaries.length],
      targetPlatformId: startPlatformId == 'P1' ? 'P3' : 'P1', // Go to opposite end
      atPlatform: true,
    ));

    platform.occupied = true;
    platform.occupyingTrainId = 'T${trains.length}';

    // Update block occupation
    _updateBlockOccupation();
    notifyListeners();
  }

  void removeTrain(String id) {
    final train = trains.firstWhere((t) => t.id == id);

    // Clear platform if train is on one
    for (var platform in platforms) {
      if (platform.occupyingTrainId == train.id) {
        platform.occupied = false;
        platform.occupyingTrainId = null;
      }
    }

    trains.removeWhere((t) => t.id == id);
    _updateBlockOccupation();
    _updateSignalAspects();
    notifyListeners();
  }

  void startSimulation() {
    isRunning = true;

    // Depart all trains from platforms
    for (var train in trains) {
      if (train.atPlatform) {
        train.atPlatform = false;
        train.isMoving = true;
        train.platformStopTime = 0;

        // Clear platform
        for (var platform in platforms) {
          if (platform.occupyingTrainId == train.id) {
            platform.occupied = false;
            platform.occupyingTrainId = null;
          }
        }
      }
    }

    notifyListeners();
  }

  void pauseSimulation() {
    isRunning = false;
    notifyListeners();
  }

  void resetSimulation() {
    trains.clear();
    isRunning = false;
    simulationTime = 0;

    // Reset all blocks
    for (var block in blocks) {
      block.occupied = false;
      block.occupyingTrainId = null;
    }

    // Reset all platforms
    for (var platform in platforms) {
      platform.occupied = false;
      platform.occupyingTrainId = null;
    }

    // Reset all signals to red
    for (var signal in signals) {
      signal.aspect = SignalAspect.red;
    }

    notifyListeners();
  }

  void setSimulationSpeed(double speed) {
    simulationSpeed = speed;
    notifyListeners();
  }

  void updateSimulation() {
    if (!isRunning) return;

    simulationTime++;

    for (var train in trains) {
      if (!train.isMoving && !train.atPlatform) continue;

      // Check signal ahead
      final signalAhead = _getSignalAhead(train);
      final canProceed = _canTrainProceed(train, signalAhead);

      if (canProceed) {
        // Accelerate or maintain speed
        if (train.speed < train.maxSpeed) {
          train.speed = math.min(train.speed + 0.05, train.maxSpeed);
        }

        // Move train
        train.x += train.speed * simulationSpeed;
        train.hasStoppedAtSignal = false;
      } else {
        // Decelerate to stop at red signal
        if (train.speed > 0) {
          train.speed = math.max(train.speed - 0.1, 0);
          train.x += train.speed * simulationSpeed;
        } else {
          train.hasStoppedAtSignal = true;
        }
      }

      // Check if train reached target platform
      if (train.targetPlatformId != null) {
        final platform = platforms.firstWhere((p) => p.id == train.targetPlatformId);

        if (platform.containsPosition(train.x) && !train.atPlatform) {
          // Arrive at platform
          train.atPlatform = true;
          train.isMoving = false;
          train.speed = 0;
          train.x = platform.centerX; // Snap to center
          train.platformStopTime = 180; // Stop for 3 seconds (at 60 ticks/sec)

          platform.occupied = true;
          platform.occupyingTrainId = train.id;

          // Switch target to opposite platform
          if (train.targetPlatformId == 'P1') {
            train.targetPlatformId = 'P3';
          } else if (train.targetPlatformId == 'P3') {
            train.targetPlatformId = 'P1';
          } else {
            // At central station, continue in same direction
            train.targetPlatformId = train.targetPlatformId == 'P2' ? 'P3' : 'P2';
          }
        }
      }

      // Handle platform stop time
      if (train.atPlatform) {
        train.platformStopTime--;
        if (train.platformStopTime <= 0) {
          // Depart from platform
          train.atPlatform = false;
          train.isMoving = true;

          // Clear platform
          for (var platform in platforms) {
            if (platform.occupyingTrainId == train.id) {
              platform.occupied = false;
              platform.occupyingTrainId = null;
            }
          }
        }
      }

      // Wrap around at track ends (for testing)
      if (train.x > 3500) {
        train.x = 100;
        train.targetPlatformId = 'P3';
      }
    }

    // Update track circuits (block occupation detection)
    _updateBlockOccupation();

    // Update signal aspects based on block occupation
    _updateSignalAspects();

    notifyListeners();
  }

  void _updateBlockOccupation() {
    // Clear all blocks first
    for (var block in blocks) {
      block.occupied = false;
      block.occupyingTrainId = null;
    }

    // Detect train presence in each block (track circuit simulation)
    for (var train in trains) {
      for (var block in blocks) {
        if (block.containsPosition(train.x)) {
          block.occupied = true;
          block.occupyingTrainId = train.id;
          train.currentBlockId = block.id;
        }
      }
    }
  }

  void _updateSignalAspects() {
    // Implement two-aspect fixed block signalling logic
    for (var signal in signals) {
      final protectedBlock = blocks.firstWhere(
        (b) => b.id == signal.protectsBlockId,
        orElse: () => blocks.first,
      );

      // Check overlap block if it exists
      BlockSection? overlapBlock;
      if (signal.overlapBlockId != null) {
        overlapBlock = blocks.firstWhere(
          (b) => b.id == signal.overlapBlockId,
          orElse: () => blocks.first,
        );
      }

      // Signal logic: Show green only if protected block AND overlap are clear
      if (!protectedBlock.occupied && (overlapBlock == null || !overlapBlock.occupied)) {
        signal.aspect = SignalAspect.green;
      } else {
        signal.aspect = SignalAspect.red;
      }
    }
  }

  Signal? _getSignalAhead(Train train) {
    // Find the next signal in front of the train
    Signal? nearestSignal;
    double minDistance = double.infinity;

    for (var signal in signals) {
      if (signal.x > train.x) {
        final distance = signal.x - train.x;
        if (distance < minDistance) {
          minDistance = distance;
          nearestSignal = signal;
        }
      }
    }

    return nearestSignal;
  }

  bool _canTrainProceed(Train train, Signal? signalAhead) {
    if (signalAhead == null) return true; // No signal ahead, can proceed

    // Calculate stopping distance
    const double stoppingDistance = 80.0; // Safety margin
    final distanceToSignal = signalAhead.x - train.x;

    // If signal is red and train is approaching
    if (signalAhead.aspect == SignalAspect.red) {
      // Must stop if within stopping distance
      if (distanceToSignal <= stoppingDistance) {
        return false;
      }
      // Can continue if far enough to stop
      return distanceToSignal > stoppingDistance;
    }

    // Green signal - can proceed
    return true;
  }

  Map<String, dynamic> getSimulationStats() {
    return {
      'total_trains': trains.length,
      'moving_trains': trains.where((t) => t.isMoving).length,
      'trains_at_platforms': trains.where((t) => t.atPlatform).length,
      'occupied_blocks': blocks.where((b) => b.occupied && !b.isOverlapBlock).length,
      'total_blocks': blocks.where((b) => !b.isOverlapBlock).length,
      'green_signals': signals.where((s) => s.aspect == SignalAspect.green).length,
      'total_signals': signals.length,
      'simulation_time': simulationTime,
    };
  }
}
