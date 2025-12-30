import 'package:flutter/material.dart';
import 'railway_model.dart';
import 'track_geometry.dart';

/// Professional Railway Network Editor
/// Provides comprehensive editing capabilities for railway infrastructure
/// Similar to OpenTrack's graphical editor
class RailwayNetworkEditor {
  final Function() notifyListeners;
  final List<BlockSection> blocks;
  final List<Signal> signals;
  final List<Point> points;
  final TrackNetworkGeometry trackGeometry;
  final Function(String) addEvent;

  RailwayNetworkEditor({
    required this.notifyListeners,
    required this.blocks,
    required this.signals,
    required this.points,
    required this.trackGeometry,
    required this.addEvent,
  });

  // ============================================================================
  // BLOCK/TRACK EDITING
  // ============================================================================

  /// Add a new track block to the network
  BlockSection addBlock({
    required String id,
    required double startX,
    required double endX,
    required double y,
    String? nextBlock,
    String? prevBlock,
    bool isCrossover = false,
    double gradient = 0.0,
    double maxSpeed = 100.0,
    TrackCategory category = TrackCategory.mainLine,
  }) {
    // Check if ID already exists
    if (blocks.any((b) => b.id == id)) {
      addEvent('❌ Block $id already exists');
      throw Exception('Block ID $id already exists');
    }

    final newBlock = BlockSection(
      id: id,
      startX: startX,
      endX: endX,
      y: y,
      nextBlock: nextBlock,
      prevBlock: prevBlock,
      isCrossover: isCrossover,
      gradient: gradient,
      maxSpeed: maxSpeed,
      category: category,
    );

    blocks.add(newBlock);

    // Generate track path geometry
    trackGeometry.regeneratePathForBlock(newBlock);

    addEvent('✅ Added block $id');
    notifyListeners();
    return newBlock;
  }

  /// Remove a block from the network
  bool removeBlock(String blockId) {
    final block = blocks.where((b) => b.id == blockId).firstOrNull;
    if (block == null) {
      addEvent('❌ Block $blockId not found');
      return false;
    }

    // Safety check: can't remove occupied blocks
    if (block.occupied) {
      addEvent('❌ Cannot remove block $blockId: Block is occupied');
      return false;
    }

    // Update connections of adjacent blocks
    for (final otherBlock in blocks) {
      if (otherBlock.nextBlock == blockId) {
        otherBlock.nextBlock = null;
      }
      if (otherBlock.prevBlock == blockId) {
        otherBlock.prevBlock = null;
      }
    }

    // Remove from list
    blocks.removeWhere((b) => b.id == blockId);

    // Remove track path
    trackGeometry.removePath(blockId);

    addEvent('✅ Removed block $blockId');
    notifyListeners();
    return true;
  }

  /// Move a block to new position
  void moveBlock(String blockId, double deltaX, double deltaY) {
    final block = blocks.where((b) => b.id == blockId).firstOrNull;
    if (block == null) return;

    block.startX += deltaX;
    block.endX += deltaX;
    block.y += deltaY;

    // Regenerate track path with new geometry
    trackGeometry.regeneratePathForBlock(block);

    addEvent('Moved block $blockId');
    notifyListeners();
  }

  /// Resize a block
  void resizeBlock(String blockId, {double? newStartX, double? newEndX}) {
    final block = blocks.where((b) => b.id == blockId).firstOrNull;
    if (block == null) return;

    if (newStartX != null) block.startX = newStartX;
    if (newEndX != null) block.endX = newEndX;

    // Ensure startX < endX
    if (block.startX > block.endX) {
      final temp = block.startX;
      block.startX = block.endX;
      block.endX = temp;
    }

    trackGeometry.regeneratePathForBlock(block);
    addEvent('Resized block $blockId to ${block.length.toStringAsFixed(0)}m');
    notifyListeners();
  }

  /// Connect two blocks (set nextBlock/prevBlock)
  void connectBlocks(String fromBlockId, String toBlockId) {
    final fromBlock = blocks.where((b) => b.id == fromBlockId).firstOrNull;
    final toBlock = blocks.where((b) => b.id == toBlockId).firstOrNull;

    if (fromBlock == null || toBlock == null) {
      addEvent('❌ Cannot connect: block not found');
      return;
    }

    fromBlock.nextBlock = toBlockId;
    toBlock.prevBlock = fromBlockId;

    addEvent('✅ Connected $fromBlockId → $toBlockId');
    notifyListeners();
  }

  /// Disconnect blocks
  void disconnectBlocks(String fromBlockId, String toBlockId) {
    final fromBlock = blocks.where((b) => b.id == fromBlockId).firstOrNull;
    final toBlock = blocks.where((b) => b.id == toBlockId).firstOrNull;

    if (fromBlock?.nextBlock == toBlockId) {
      fromBlock!.nextBlock = null;
    }
    if (toBlock?.prevBlock == fromBlockId) {
      toBlock!.prevBlock = null;
    }

    addEvent('Disconnected $fromBlockId — $toBlockId');
    notifyListeners();
  }

  /// Edit block attributes
  void editBlockAttributes(
    String blockId, {
    double? gradient,
    double? maxSpeed,
    TrackCategory? category,
    bool? electrified,
  }) {
    final block = blocks.where((b) => b.id == blockId).firstOrNull;
    if (block == null) return;

    if (gradient != null) block.gradient = gradient;
    if (maxSpeed != null) block.maxSpeed = maxSpeed;
    if (category != null) block.category = category;
    if (electrified != null) block.electrified = electrified;

    addEvent('Updated attributes for block $blockId');
    notifyListeners();
  }

  // ============================================================================
  // SIGNAL EDITING
  // ============================================================================

  /// Add a new signal
  Signal addSignal({
    required String id,
    required double x,
    required double y,
    required List<String> controlledBlocks,
    SignalType type = SignalType.main,
    SignalDirection direction = SignalDirection.eastbound,
  }) {
    if (signals.any((s) => s.id == id)) {
      addEvent('❌ Signal $id already exists');
      throw Exception('Signal ID $id already exists');
    }

    final newSignal = Signal(
      id: id,
      x: x,
      y: y,
      controlledBlocks: controlledBlocks,
      signalType: type,
      direction: direction,
    );

    signals.add(newSignal);
    addEvent('✅ Added signal $id');
    notifyListeners();
    return newSignal;
  }

  /// Remove a signal
  bool removeSignal(String signalId) {
    final signal = signals.where((s) => s.id == signalId).firstOrNull;
    if (signal == null) {
      addEvent('❌ Signal $signalId not found');
      return false;
    }

    // Safety check: don't remove if signal is active and protecting a route
    if (signal.state == SignalState.green && signal.route != null) {
      addEvent('❌ Cannot remove signal $signalId: Active route protection');
      return false;
    }

    signals.removeWhere((s) => s.id == signalId);
    addEvent('✅ Removed signal $signalId');
    notifyListeners();
    return true;
  }

  /// Move a signal
  void moveSignal(String signalId, double newX, double newY) {
    final signal = signals.where((s) => s.id == signalId).firstOrNull;
    if (signal == null) return;

    signal.moveTo(newX, newY);
    addEvent('Moved signal $signalId to ($newX, $newY)');
    notifyListeners();
  }

  /// Edit signal attributes
  void editSignalAttributes(
    String signalId, {
    SignalType? type,
    SignalDirection? direction,
    List<String>? controlledBlocks,
    List<String>? requiredPointPositions,
  }) {
    final signal = signals.where((s) => s.id == signalId).firstOrNull;
    if (signal == null) return;

    if (type != null) signal.signalType = type;
    if (direction != null) signal.direction = direction;
    if (controlledBlocks != null) signal.updateControlledBlocks(controlledBlocks);
    if (requiredPointPositions != null) {
      signal.updatePointRequirements(requiredPointPositions);
    }

    addEvent('Updated attributes for signal $signalId');
    notifyListeners();
  }

  // ============================================================================
  // POINT/CROSSOVER EDITING
  // ============================================================================

  /// Add a new point
  Point addPoint({
    required String id,
    required double x,
    required double y,
    double divergingAngle = 15.0,
    double divergingSpeedLimit = 40.0,
  }) {
    if (points.any((p) => p.id == id)) {
      addEvent('❌ Point $id already exists');
      throw Exception('Point ID $id already exists');
    }

    final newPoint = Point(
      id: id,
      x: x,
      y: y,
      divergingRouteAngle: divergingAngle,
      divergingSpeedLimit: divergingSpeedLimit,
    );

    points.add(newPoint);
    addEvent('✅ Added point $id');
    notifyListeners();
    return newPoint;
  }

  /// Remove a point
  bool removePoint(String pointId) {
    final point = points.where((p) => p.id == pointId).firstOrNull;
    if (point == null) {
      addEvent('❌ Point $pointId not found');
      return false;
    }

    // Safety check: don't remove if point is reserved
    if (point.reservedByVin != null) {
      addEvent('❌ Cannot remove point $pointId: Reserved by ${point.reservedByVin}');
      return false;
    }

    points.removeWhere((p) => p.id == pointId);
    addEvent('✅ Removed point $pointId');
    notifyListeners();
    return true;
  }

  /// Move a point
  void movePoint(String pointId, double newX, double newY) {
    final point = points.where((p) => p.id == pointId).firstOrNull;
    if (point == null) return;

    point.moveTo(newX, newY);

    // If this point is part of a crossover, regenerate crossover geometry
    _regenerateCrossoverGeometry(pointId);

    addEvent('Moved point $pointId to ($newX, $newY)');
    notifyListeners();
  }

  /// Edit point diverging route attributes
  void editPointDivergingRoute(
    String pointId, {
    double? angle,
    double? radius,
    double? speedLimit,
  }) {
    final point = points.where((p) => p.id == pointId).firstOrNull;
    if (point == null) return;

    point.updateDivergingRoute(
      angle: angle,
      radius: radius,
      speedLimit: speedLimit,
    );

    _regenerateCrossoverGeometry(pointId);
    addEvent('Updated diverging route for point $pointId');
    notifyListeners();
  }

  /// Helper: Regenerate crossover geometry when point moves
  void _regenerateCrossoverGeometry(String pointId) {
    // Check if this point is part of crossover106 or crossover109
    if (pointId == '78A' || pointId == '78B') {
      final point78A = points.where((p) => p.id == '78A').firstOrNull;
      final point78B = points.where((p) => p.id == '78B').firstOrNull;

      if (point78A != null && point78B != null) {
        // Regenerate crossover106 path
        final path106 = trackGeometry.generateCrossoverPath(
          id: 'crossover106',
          startX: point78A.x,
          startY: point78A.y,
          endX: (point78A.x + point78B.x) / 2,
          endY: (point78A.y + point78B.y) / 2,
          speedLimit: point78A.divergingSpeedLimit,
        );
        trackGeometry.updatePath('crossover106', path106);

        // Regenerate crossover109 path
        final path109 = trackGeometry.generateCrossoverPath(
          id: 'crossover109',
          startX: (point78A.x + point78B.x) / 2,
          startY: (point78A.y + point78B.y) / 2,
          endX: point78B.x,
          endY: point78B.y,
          speedLimit: point78B.divergingSpeedLimit,
        );
        trackGeometry.updatePath('crossover109', path109);
      }
    }
  }

  // ============================================================================
  // CROSSOVER CREATION
  // ============================================================================

  /// Create a complete crossover (2 points + 2 blocks)
  void createCrossover({
    required String crossoverId,
    required double startX,
    required double startY,
    required double endX,
    required double endY,
    double speedLimit = 40.0,
  }) {
    final point1Id = '${crossoverId}_pt1';
    final point2Id = '${crossoverId}_pt2';
    final block1Id = '${crossoverId}_seg1';
    final block2Id = '${crossoverId}_seg2';

    final midX = (startX + endX) / 2;
    final midY = (startY + endY) / 2;

    // Add points
    addPoint(id: point1Id, x: startX, y: startY, divergingSpeedLimit: speedLimit);
    addPoint(id: point2Id, x: endX, y: endY, divergingSpeedLimit: speedLimit);

    // Add crossover blocks
    addBlock(
      id: block1Id,
      startX: startX,
      endX: midX,
      y: startY,
      nextBlock: block2Id,
      isCrossover: true,
      maxSpeed: speedLimit,
    );

    addBlock(
      id: block2Id,
      startX: midX,
      endX: endX,
      y: endY,
      prevBlock: block1Id,
      isCrossover: true,
      maxSpeed: speedLimit,
    );

    // Generate crossover paths
    final path1 = trackGeometry.generateCrossoverPath(
      id: block1Id,
      startX: startX,
      startY: startY,
      endX: midX,
      endY: midY,
      speedLimit: speedLimit,
    );
    trackGeometry.addPath(path1);

    final path2 = trackGeometry.generateCrossoverPath(
      id: block2Id,
      startX: midX,
      startY: midY,
      endX: endX,
      endY: endY,
      speedLimit: speedLimit,
    );
    trackGeometry.addPath(path2);

    addEvent('✅ Created crossover $crossoverId');
    notifyListeners();
  }

  // ============================================================================
  // VALIDATION & ANALYSIS
  // ============================================================================

  /// Validate network topology
  List<String> validateNetwork() {
    final issues = <String>[];

    // Check for disconnected blocks
    for (final block in blocks) {
      if (block.nextBlock != null && !blocks.any((b) => b.id == block.nextBlock)) {
        issues.add('Block ${block.id}: nextBlock "${block.nextBlock}" does not exist');
      }
      if (block.prevBlock != null && !blocks.any((b) => b.id == block.prevBlock)) {
        issues.add('Block ${block.id}: prevBlock "${block.prevBlock}" does not exist');
      }
    }

    // Check for signals protecting non-existent blocks
    for (final signal in signals) {
      for (final blockId in signal.controlledBlocks) {
        if (!blocks.any((b) => b.id == blockId)) {
          issues.add('Signal ${signal.id}: protects non-existent block "$blockId"');
        }
      }
    }

    // Check for overlapping blocks (same coordinates)
    for (int i = 0; i < blocks.length; i++) {
      for (int j = i + 1; j < blocks.length; j++) {
        if (blocks[i].y == blocks[j].y &&
            ((blocks[i].startX >= blocks[j].startX && blocks[i].startX <= blocks[j].endX) ||
             (blocks[i].endX >= blocks[j].startX && blocks[i].endX <= blocks[j].endX))) {
          issues.add('Blocks ${blocks[i].id} and ${blocks[j].id} overlap');
        }
      }
    }

    return issues;
  }

  /// Calculate total network length
  double getTotalNetworkLength() {
    return blocks.fold(0.0, (sum, block) => sum + block.length);
  }

  /// Get network statistics
  Map<String, dynamic> getNetworkStats() {
    return {
      'totalBlocks': blocks.length,
      'totalSignals': signals.length,
      'totalPoints': points.length,
      'totalLength': getTotalNetworkLength(),
      'crossovers': blocks.where((b) => b.isCrossover).length,
      'mainLineBlocks': blocks.where((b) => b.category == TrackCategory.mainLine).length,
      'electrifiedBlocks': blocks.where((b) => b.electrified).length,
    };
  }
}
