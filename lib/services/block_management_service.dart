import 'package:flutter/foundation.dart';
import 'package:rail_champ/screens/terminal_station_models.dart';
import 'dart:async';

// ============================================================================
// BLOCK MANAGEMENT SERVICE
// Track circuit management, block occupancy detection, and section control
// ============================================================================

/// Block occupancy state
enum BlockOccupancyState {
  clear,
  occupied,
  unknown,
  failed,
}

/// Block occupancy change event
class BlockOccupancyEvent {
  final String blockId;
  final BlockOccupancyState previousState;
  final BlockOccupancyState newState;
  final DateTime timestamp;
  final String? trainId;
  final String reason;

  BlockOccupancyEvent({
    required this.blockId,
    required this.previousState,
    required this.newState,
    DateTime? timestamp,
    this.trainId,
    required this.reason,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'blockId': blockId,
      'previousState': previousState.toString(),
      'newState': newState.toString(),
      'timestamp': timestamp.toIso8601String(),
      'trainId': trainId,
      'reason': reason,
    };
  }
}

/// Track circuit health status
enum TrackCircuitHealth {
  operational,
  degraded,
  intermittent,
  failed,
}

/// Extended block data for management
class BlockData {
  final BlockSection block;
  BlockOccupancyState occupancyState;
  TrackCircuitHealth health;
  List<String> occupyingTrains;
  List<BlockOccupancyEvent> history;
  DateTime? lastStateChange;
  DateTime? lastMaintenance;

  // Detection parameters
  double detectionRadius;
  bool isProtected;
  List<String> protectingSignals;

  // Statistics
  int totalOccupancies;
  Duration totalOccupiedTime;
  DateTime? lastOccupancyStart;

  BlockData({
    required this.block,
    this.occupancyState = BlockOccupancyState.clear,
    this.health = TrackCircuitHealth.operational,
    List<String>? occupyingTrains,
    List<BlockOccupancyEvent>? history,
    this.lastStateChange,
    this.lastMaintenance,
    this.detectionRadius = 15.0,
    this.isProtected = false,
    List<String>? protectingSignals,
    this.totalOccupancies = 0,
    Duration? totalOccupiedTime,
    this.lastOccupancyStart,
  })  : occupyingTrains = occupyingTrains ?? [],
        history = history ?? [],
        protectingSignals = protectingSignals ?? [],
        totalOccupiedTime = totalOccupiedTime ?? Duration.zero;

  void recordEvent(BlockOccupancyEvent event) {
    history.add(event);
    lastStateChange = event.timestamp;

    // Keep only last 100 events
    if (history.length > 100) {
      history.removeAt(0);
    }
  }

  void addTrain(String trainId) {
    if (!occupyingTrains.contains(trainId)) {
      occupyingTrains.add(trainId);

      if (occupancyState == BlockOccupancyState.clear) {
        totalOccupancies++;
        lastOccupancyStart = DateTime.now();
      }
    }
  }

  void removeTrain(String trainId) {
    occupyingTrains.remove(trainId);

    if (occupyingTrains.isEmpty && lastOccupancyStart != null) {
      final occupiedDuration = DateTime.now().difference(lastOccupancyStart!);
      totalOccupiedTime += occupiedDuration;
      lastOccupancyStart = null;
    }
  }

  bool needsMaintenance() {
    if (lastMaintenance == null) return true;
    final daysSince = DateTime.now().difference(lastMaintenance!).inDays;
    return daysSince > 180 ||
        health != TrackCircuitHealth.operational ||
        totalOccupancies > 10000;
  }

  double getOccupancyPercentage() {
    final totalTime = totalOccupiedTime;
    if (lastOccupancyStart != null) {
      final currentOccupied = DateTime.now().difference(lastOccupancyStart!);
      final total = totalTime + currentOccupied;
      return (total.inSeconds / DateTime.now().millisecondsSinceEpoch) * 100;
    }
    return (totalTime.inSeconds / DateTime.now().millisecondsSinceEpoch) * 100;
  }

  Map<String, dynamic> getStatus() {
    return {
      'blockId': block.id,
      'occupancyState': occupancyState.toString(),
      'health': health.toString(),
      'occupyingTrains': occupyingTrains,
      'isProtected': isProtected,
      'protectingSignals': protectingSignals,
      'totalOccupancies': totalOccupancies,
      'needsMaintenance': needsMaintenance(),
      'occupied': block.occupied,
    };
  }
}

/// Block section group for managing related blocks
class BlockGroup {
  final String id;
  final String name;
  final List<String> blockIds;
  final String description;

  BlockGroup({
    required this.id,
    required this.name,
    required this.blockIds,
    this.description = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'blockIds': blockIds,
      'description': description,
    };
  }
}

/// Comprehensive block management service
class BlockManagementService extends ChangeNotifier {
  final Map<String, BlockData> _blockData = {};
  final List<BlockOccupancyEvent> _globalEvents = [];
  final Map<String, BlockGroup> _blockGroups = {};

  // Callbacks
  Function()? getAllTrainsCallback;
  Function(String blockId)? getBlockCallback;

  // Configuration
  bool automaticDetection = true;
  bool failSafeMode = true; // Assume occupied on failure
  Duration eventRetentionPeriod = const Duration(hours: 24);

  // Statistics
  int totalStateChanges = 0;
  int totalOccupancies = 0;

  BlockManagementService();

  /// Initialize block data
  void initializeBlock(
    BlockSection block, {
    double detectionRadius = 15.0,
    bool isProtected = false,
  }) {
    _blockData[block.id] = BlockData(
      block: block,
      detectionRadius: detectionRadius,
      isProtected: isProtected,
      lastMaintenance: DateTime.now(),
    );
  }

  /// Get block data
  BlockData? getBlockData(String blockId) {
    return _blockData[blockId];
  }

  /// Update block occupancy based on train detection
  void updateBlockOccupancy(String blockId, {bool forceUpdate = false}) {
    final data = _blockData[blockId];
    if (data == null) return;

    if (!automaticDetection && !forceUpdate) return;

    final previousState = data.occupancyState;
    final previousOccupied = data.block.occupied;

    // Detect trains in block
    final trainsInBlock = _detectTrainsInBlock(data);

    // Update occupying trains list
    final previousTrains = List<String>.from(data.occupyingTrains);
    data.occupyingTrains.clear();
    data.occupyingTrains.addAll(trainsInBlock);

    // Update occupancy state
    final newOccupied = trainsInBlock.isNotEmpty;
    data.block.occupied = newOccupied;

    BlockOccupancyState newState;
    if (data.health == TrackCircuitHealth.failed) {
      newState = BlockOccupancyState.failed;
      if (failSafeMode) {
        data.block.occupied = true; // Fail-safe: assume occupied
      }
    } else if (newOccupied) {
      newState = BlockOccupancyState.occupied;
    } else {
      newState = BlockOccupancyState.clear;
    }

    // Record state change if different
    if (newState != previousState || previousOccupied != newOccupied) {
      data.occupancyState = newState;

      final event = BlockOccupancyEvent(
        blockId: blockId,
        previousState: previousState,
        newState: newState,
        trainId: trainsInBlock.isNotEmpty ? trainsInBlock.first : null,
        reason: _determineChangeReason(previousTrains, trainsInBlock),
      );

      data.recordEvent(event);
      _globalEvents.add(event);

      // Keep global events manageable
      if (_globalEvents.length > 500) {
        _globalEvents.removeAt(0);
      }

      totalStateChanges++;

      if (newState == BlockOccupancyState.occupied) {
        totalOccupancies++;
        data.lastOccupancyStart = DateTime.now();
      } else if (previousState == BlockOccupancyState.occupied && data.lastOccupancyStart != null) {
        final duration = DateTime.now().difference(data.lastOccupancyStart!);
        data.totalOccupiedTime += duration;
      }

      if (kDebugMode) {
        print('🔄 Block $blockId: ${previousState.toString().split('.').last} → ${newState.toString().split('.').last} (${trainsInBlock.length} trains)');
      }

      notifyListeners();
    }
  }

  /// Detect trains in a block
  List<String> _detectTrainsInBlock(BlockData data) {
    final trainsInBlock = <String>[];

    final allTrains = getAllTrainsCallback?.call();
    if (allTrains == null) return trainsInBlock;

    final block = data.block;
    final detectionRadius = data.detectionRadius;

    for (final train in allTrains) {
      // Check if train is within block bounds
      final inXRange = train.x >= (block.startX - detectionRadius) &&
          train.x <= (block.endX + detectionRadius);
      final inYRange = (train.y - block.y).abs() < detectionRadius;

      if (inXRange && inYRange) {
        trainsInBlock.add(train.id);
        data.addTrain(train.id);
      } else {
        data.removeTrain(train.id);
      }
    }

    return trainsInBlock;
  }

  /// Determine reason for occupancy change
  String _determineChangeReason(List<String> previousTrains, List<String> currentTrains) {
    if (currentTrains.isEmpty && previousTrains.isNotEmpty) {
      return 'Train exited block';
    } else if (currentTrains.isNotEmpty && previousTrains.isEmpty) {
      return 'Train entered block';
    } else if (currentTrains.length > previousTrains.length) {
      return 'Additional train entered';
    } else if (currentTrains.length < previousTrains.length) {
      return 'Train left block';
    }
    return 'Occupancy updated';
  }

  /// Update all blocks
  void updateAllBlocks() {
    for (final blockId in _blockData.keys) {
      updateBlockOccupancy(blockId);
    }
  }

  /// Check if block is occupied
  bool isBlockOccupied(String blockId) {
    final data = _blockData[blockId];
    if (data == null) return false;

    // Update first to ensure current state
    updateBlockOccupancy(blockId);

    return data.block.occupied;
  }

  /// Check if multiple blocks are clear
  bool areBlocksClear(List<String> blockIds) {
    for (final blockId in blockIds) {
      if (isBlockOccupied(blockId)) {
        return false;
      }
    }
    return true;
  }

  /// Set block health status
  void setBlockHealth(String blockId, TrackCircuitHealth health) {
    final data = _blockData[blockId];
    if (data != null) {
      data.health = health;

      if (health == TrackCircuitHealth.failed && failSafeMode) {
        // Force occupied state for safety
        data.block.occupied = true;
        data.occupancyState = BlockOccupancyState.failed;
      }

      if (kDebugMode) {
        print('🏥 Block $blockId health: ${health.toString().split('.').last}');
      }

      notifyListeners();
    }
  }

  /// Add protecting signal to block
  void addProtectingSignal(String blockId, String signalId) {
    final data = _blockData[blockId];
    if (data != null && !data.protectingSignals.contains(signalId)) {
      data.protectingSignals.add(signalId);
      data.isProtected = true;
      notifyListeners();
    }
  }

  /// Create block group
  void createBlockGroup(BlockGroup group) {
    _blockGroups[group.id] = group;
    notifyListeners();
  }

  /// Get block group
  BlockGroup? getBlockGroup(String groupId) {
    return _blockGroups[groupId];
  }

  /// Check if all blocks in group are clear
  bool isBlockGroupClear(String groupId) {
    final group = _blockGroups[groupId];
    if (group == null) return false;

    return areBlocksClear(group.blockIds);
  }

  /// Get occupied blocks
  List<BlockSection> getOccupiedBlocks() {
    return _blockData.values
        .where((data) => data.block.occupied)
        .map((data) => data.block)
        .toList();
  }

  /// Get blocks needing maintenance
  List<BlockData> getBlocksNeedingMaintenance() {
    return _blockData.values
        .where((data) => data.needsMaintenance())
        .toList();
  }

  /// Perform maintenance on block
  void performMaintenance(String blockId) {
    final data = _blockData[blockId];
    if (data != null) {
      data.lastMaintenance = DateTime.now();
      data.totalOccupancies = 0;
      data.health = TrackCircuitHealth.operational;

      if (kDebugMode) {
        print('🔧 Maintenance performed on block $blockId');
      }

      notifyListeners();
    }
  }

  /// Get blocks by health status
  List<BlockData> getBlocksByHealth(TrackCircuitHealth health) {
    return _blockData.values
        .where((data) => data.health == health)
        .toList();
  }

  /// Get recent occupancy events
  List<BlockOccupancyEvent> getRecentEvents({int limit = 50}) {
    final events = List<BlockOccupancyEvent>.from(_globalEvents);
    if (events.length > limit) {
      return events.sublist(events.length - limit);
    }
    return events;
  }

  /// Get events for specific block
  List<BlockOccupancyEvent> getBlockEvents(String blockId, {int limit = 20}) {
    final data = _blockData[blockId];
    if (data == null) return [];

    final events = List<BlockOccupancyEvent>.from(data.history);
    if (events.length > limit) {
      return events.sublist(events.length - limit);
    }
    return events;
  }

  /// Clear old events
  void clearOldEvents() {
    final cutoff = DateTime.now().subtract(eventRetentionPeriod);
    _globalEvents.removeWhere((event) => event.timestamp.isBefore(cutoff));

    for (final data in _blockData.values) {
      data.history.removeWhere((event) => event.timestamp.isBefore(cutoff));
    }

    notifyListeners();
  }

  /// Reset all blocks to clear
  void resetAllBlocks() {
    for (final data in _blockData.values) {
      data.block.occupied = false;
      data.occupancyState = BlockOccupancyState.clear;
      data.occupyingTrains.clear();
    }

    if (kDebugMode) {
      print('🔄 All blocks reset to clear');
    }

    notifyListeners();
  }

  /// Get comprehensive diagnostics
  Map<String, dynamic> getDiagnostics() {
    final stateCounts = <BlockOccupancyState, int>{};
    final healthCounts = <TrackCircuitHealth, int>{};

    for (final data in _blockData.values) {
      stateCounts[data.occupancyState] =
          (stateCounts[data.occupancyState] ?? 0) + 1;
      healthCounts[data.health] = (healthCounts[data.health] ?? 0) + 1;
    }

    return {
      'totalBlocks': _blockData.length,
      'totalStateChanges': totalStateChanges,
      'totalOccupancies': totalOccupancies,
      'occupiedBlocks': getOccupiedBlocks().length,
      'blocksNeedingMaintenance': getBlocksNeedingMaintenance().length,
      'blockGroups': _blockGroups.length,
      'automaticDetection': automaticDetection,
      'failSafeMode': failSafeMode,
      'stateDistribution': stateCounts.map((k, v) =>
          MapEntry(k.toString().split('.').last, v)),
      'healthDistribution': healthCounts.map((k, v) =>
          MapEntry(k.toString().split('.').last, v)),
    };
  }

  /// Export block status report
  Map<String, dynamic> exportStatusReport() {
    return {
      'generatedAt': DateTime.now().toIso8601String(),
      'blocks': _blockData.values.map((data) => data.getStatus()).toList(),
      'groups': _blockGroups.values.map((group) => group.toMap()).toList(),
      'recentEvents': getRecentEvents().map((e) => e.toMap()).toList(),
      'summary': getDiagnostics(),
    };
  }
}
