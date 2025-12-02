import 'railway_model.dart';

/// Maps points to their controlling blocks and validates physical locations
/// This is the SINGLE SOURCE OF TRUTH for point-block relationships
class PointBlockMapping {
  final String pointId;
  final String approachBlockId; // Block train is in when approaching point
  final String exitBlockId; // Block train enters after passing point
  final double pointX; // Physical x-coordinate of point
  final double pointY; // Physical y-coordinate of point
  final int direction; // 1 for eastbound, -1 for westbound
  final PointPosition requiredPosition; // Position required for this route

  PointBlockMapping({
    required this.pointId,
    required this.approachBlockId,
    required this.exitBlockId,
    required this.pointX,
    required this.pointY,
    required this.direction,
    required this.requiredPosition,
  });

  /// Validate that point is geometrically within the approach block's range
  bool validate(Map<String, dynamic> blocks) {
    final block = blocks[approachBlockId];
    if (block == null) {
      print('❌ Validation failed: Block $approachBlockId not found for point $pointId');
      return false;
    }

    // Check if point x is at or near block boundary
    final atStartBoundary = (pointX - block.startX).abs() < 1.0;
    final atEndBoundary = (pointX - block.endX).abs() < 1.0;
    final withinBlock = pointX >= block.startX && pointX <= block.endX;

    if (!atStartBoundary && !atEndBoundary && !withinBlock) {
      print('❌ Validation failed: Point $pointId at x=$pointX is not at boundary or within block $approachBlockId (${block.startX}-${block.endX})');
      return false;
    }

    return true;
  }

  @override
  String toString() {
    return 'Point $pointId ($pointX, $pointY): Block $approachBlockId → $exitBlockId (${direction > 0 ? 'EB' : 'WB'}, ${requiredPosition.name})';
  }
}

/// Represents a physical track connection between blocks
/// This models the real-world railway where tracks physically connect at points
class TrackConnection {
  final String fromBlockId;
  final String toBlockId;
  final String? viaPointId; // Point that controls this connection (if any)
  final PointPosition? requiredPointPosition; // Required point position for this route

  TrackConnection({
    required this.fromBlockId,
    required this.toBlockId,
    this.viaPointId,
    this.requiredPointPosition,
  });

  @override
  String toString() {
    if (viaPointId != null) {
      return '$fromBlockId → $toBlockId (via $viaPointId ${requiredPointPosition?.name})';
    }
    return '$fromBlockId → $toBlockId';
  }
}

/// Represents a railway point (turnout/switch) with its physical connections
class PointConfiguration {
  final String pointId;
  final String normalRoute; // Block ID when point is normal
  final String reverseRoute; // Block ID when point is reverse
  final String fromBlock; // The block approaching this point

  PointConfiguration({
    required this.pointId,
    required this.normalRoute,
    required this.reverseRoute,
    required this.fromBlock,
  });
}

/// Track graph representing the entire railway network topology
/// This is the "ground truth" for train routing - trains follow physical tracks
class TrackGraph {
  // Map of block ID → list of possible next blocks (with conditions)
  final Map<String, List<TrackConnection>> _eastboundConnections = {};
  final Map<String, List<TrackConnection>> _westboundConnections = {};

  // Map of point ID → their configurations
  final Map<String, PointConfiguration> _pointConfigurations = {};

  // Map of (blockId, direction) → point controlling that block's exits
  final Map<String, List<PointBlockMapping>> _pointBlockMappings = {};

  TrackGraph() {
    _buildGraph();
  }

  /// Build point-block mappings from track connections
  /// This creates the unified mapping that serves as single source of truth
  void buildPointBlockMappings(Map<String, dynamic> points, Map<String, dynamic> blocks) {
    _pointBlockMappings.clear();

    // Process eastbound connections
    for (final entry in _eastboundConnections.entries) {
      final fromBlockId = entry.key;
      for (final connection in entry.value) {
        if (connection.viaPointId != null) {
          final point = points[connection.viaPointId];
          if (point != null) {
            final mapping = PointBlockMapping(
              pointId: connection.viaPointId!,
              approachBlockId: fromBlockId,
              exitBlockId: connection.toBlockId,
              pointX: point.x.toDouble(),
              pointY: point.y.toDouble(),
              direction: 1, // Eastbound
              requiredPosition: connection.requiredPointPosition!,
            );

            // Validate the mapping
            if (!mapping.validate(blocks)) {
              print('⚠️ WARNING: Invalid point-block mapping: $mapping');
            }

            // Store by approach block
            _pointBlockMappings.putIfAbsent(fromBlockId, () => []);
            _pointBlockMappings[fromBlockId]!.add(mapping);
          }
        }
      }
    }

    // Process westbound connections
    for (final entry in _westboundConnections.entries) {
      final fromBlockId = entry.key;
      for (final connection in entry.value) {
        if (connection.viaPointId != null) {
          final point = points[connection.viaPointId];
          if (point != null) {
            final mapping = PointBlockMapping(
              pointId: connection.viaPointId!,
              approachBlockId: fromBlockId,
              exitBlockId: connection.toBlockId,
              pointX: point.x.toDouble(),
              pointY: point.y.toDouble(),
              direction: -1, // Westbound
              requiredPosition: connection.requiredPointPosition!,
            );

            // Validate the mapping
            if (!mapping.validate(blocks)) {
              print('⚠️ WARNING: Invalid point-block mapping: $mapping');
            }

            // Store by approach block
            _pointBlockMappings.putIfAbsent(fromBlockId, () => []);
            _pointBlockMappings[fromBlockId]!.add(mapping);
          }
        }
      }
    }

    print('✅ Built ${_pointBlockMappings.length} point-block mappings');
  }

  /// Get point-block mappings for a given block and direction
  List<PointBlockMapping> getPointMappingsForBlock(String blockId, int direction) {
    final mappings = _pointBlockMappings[blockId] ?? [];
    return mappings.where((m) => m.direction == direction).toList();
  }

  /// Get all point-block mappings for a specific point
  List<PointBlockMapping> getPointMappings(String pointId) {
    final results = <PointBlockMapping>[];
    for (final mappings in _pointBlockMappings.values) {
      results.addAll(mappings.where((m) => m.pointId == pointId));
    }
    return results;
  }

  /// Get the blocks that approach a specific point (for deadlock detection)
  List<String> getBlocksApproachingPoint(String pointId) {
    final blocks = <String>[];
    for (final entry in _pointBlockMappings.entries) {
      for (final mapping in entry.value) {
        if (mapping.pointId == pointId) {
          blocks.add(mapping.approachBlockId);
        }
      }
    }
    return blocks;
  }

  /// Build the complete track graph for the terminal station
  /// This defines the physical reality of the railway
  void _buildGraph() {
    _buildLeftSection();
    _buildMiddleSection();
    _buildRightSection();
  }

  /// LEFT SECTION (Blocks 200-215)
  void _buildLeftSection() {
    // ===== EASTBOUND (Upper Track 200-214) =====

    // Straight blocks (no points)
    _addEastbound('200', '202');
    _addEastbound('202', '204');
    _addEastbound('204', '206');
    _addEastbound('206', '208');

    // Block 208 → Point 76A controls routing
    _addEastbound('208', '210', viaPoint: '76A', requiredPosition: PointPosition.normal);
    _addEastbound('208', 'crossover_211_212', viaPoint: '76A', requiredPosition: PointPosition.reverse);

    // After point 76A
    _addEastbound('210', '212');
    _addEastbound('212', '214');
    _addEastbound('214', '100'); // Continue to middle section

    // Crossover eastbound exit → Point 77B controls exit
    _addEastbound('crossover_211_212', '212', viaPoint: '77B', requiredPosition: PointPosition.reverse);
    _addEastbound('crossover_211_212', '213', viaPoint: '77B', requiredPosition: PointPosition.normal);

    // Lower track eastbound (blocks 201-215)
    _addEastbound('201', '203');
    _addEastbound('203', '205');
    _addEastbound('205', '207');
    _addEastbound('207', '209');

    // Block 209 → Point 77B controls routing
    _addEastbound('209', '211', viaPoint: '77B', requiredPosition: PointPosition.normal);
    _addEastbound('209', 'crossover_211_212', viaPoint: '77B', requiredPosition: PointPosition.reverse);

    _addEastbound('211', '213');
    _addEastbound('213', '215');
    _addEastbound('215', '101'); // Continue to middle section

    // ===== WESTBOUND (Lower Track 201-215) =====

    _addWestbound('215', '213');

    // Block 213 → Point 76B controls routing
    _addWestbound('213', '211', viaPoint: '76B', requiredPosition: PointPosition.normal);
    _addWestbound('213', 'crossover_211_212', viaPoint: '76B', requiredPosition: PointPosition.reverse);

    _addWestbound('211', '209');
    _addWestbound('209', '207');
    _addWestbound('207', '205');
    _addWestbound('205', '203');
    _addWestbound('203', '201');
    _addWestbound('201', '315'); // Loop back to right section

    // Crossover westbound exit → Point 77A controls exit
    _addWestbound('crossover_211_212', '210', viaPoint: '77A', requiredPosition: PointPosition.reverse);
    _addWestbound('crossover_211_212', '211', viaPoint: '77A', requiredPosition: PointPosition.normal);

    // Upper track westbound (blocks 200-214)
    _addWestbound('214', '212');
    _addWestbound('212', '210');

    // Block 210 → Point 77A controls routing
    _addWestbound('210', '208', viaPoint: '77A', requiredPosition: PointPosition.normal);
    _addWestbound('210', 'crossover_211_212', viaPoint: '77A', requiredPosition: PointPosition.reverse);

    _addWestbound('208', '206');
    _addWestbound('206', '204');
    _addWestbound('204', '202');
    _addWestbound('202', '200');
    _addWestbound('200', '114'); // Continue to middle section
  }

  /// MIDDLE SECTION (Blocks 100-115)
  void _buildMiddleSection() {
    // ===== EASTBOUND (Upper Track 100-114) =====

    _addEastbound('100', '102');

    // Block 102 → Point 78A controls routing
    _addEastbound('102', '104', viaPoint: '78A', requiredPosition: PointPosition.normal);
    _addEastbound('102', 'crossover106', viaPoint: '78A', requiredPosition: PointPosition.reverse);

    _addEastbound('104', '106');
    _addEastbound('106', '108');
    _addEastbound('108', '110');
    _addEastbound('110', '112');
    _addEastbound('112', '114');
    _addEastbound('114', '300'); // Continue to right section

    // Crossover eastbound (committed path - no point choices)
    _addEastbound('crossover106', 'crossover109');
    _addEastbound('crossover109', '107');

    // Lower track eastbound (blocks 101-115)
    _addEastbound('101', '103');
    _addEastbound('103', '105');
    _addEastbound('105', '107');
    _addEastbound('107', '109');
    _addEastbound('109', '111');
    _addEastbound('111', '113');
    _addEastbound('113', '115');
    _addEastbound('115', '301'); // Continue to right section

    // ===== WESTBOUND (Lower Track 101-115) =====

    _addWestbound('115', '113');
    _addWestbound('113', '111');
    _addWestbound('111', '109');

    // Block 109 → Point 78B controls routing
    _addWestbound('109', '107', viaPoint: '78B', requiredPosition: PointPosition.normal);
    _addWestbound('109', 'crossover109', viaPoint: '78B', requiredPosition: PointPosition.reverse);

    _addWestbound('107', '105');
    _addWestbound('105', '103');
    _addWestbound('103', '101');
    _addWestbound('101', '215'); // Continue to left section

    // Crossover westbound (committed path - no point choices)
    _addWestbound('crossover109', 'crossover106');
    _addWestbound('crossover106', '104');

    // Upper track westbound (blocks 100-114)
    _addWestbound('114', '112');
    _addWestbound('112', '110');
    _addWestbound('110', '108');
    _addWestbound('108', '106');
    _addWestbound('106', '104');

    // Block 104 → Point 78A controls routing (westbound approach)
    _addWestbound('104', '102', viaPoint: '78A', requiredPosition: PointPosition.normal);
    _addWestbound('104', 'crossover106', viaPoint: '78A', requiredPosition: PointPosition.reverse);

    _addWestbound('102', '100');
    _addWestbound('100', '214'); // Continue to left section
  }

  /// RIGHT SECTION (Blocks 300-315)
  void _buildRightSection() {
    // ===== EASTBOUND (Upper Track 300-314) =====

    _addEastbound('300', '302');

    // Block 302 → Point 79A controls routing
    _addEastbound('302', '304', viaPoint: '79A', requiredPosition: PointPosition.normal);
    _addEastbound('302', 'crossover_303_304', viaPoint: '79A', requiredPosition: PointPosition.reverse);

    _addEastbound('304', '306');
    _addEastbound('306', '308');
    _addEastbound('308', '310');
    _addEastbound('310', '312');
    _addEastbound('312', '314');
    _addEastbound('314', '200'); // Loop back to left section

    // Crossover eastbound exit → Point 80B controls exit
    _addEastbound('crossover_303_304', '304', viaPoint: '80B', requiredPosition: PointPosition.reverse);
    _addEastbound('crossover_303_304', '305', viaPoint: '80B', requiredPosition: PointPosition.normal);

    // Lower track eastbound (blocks 301-315)
    _addEastbound('301', '303');

    // Block 303 → Point 80B controls routing
    _addEastbound('303', '305', viaPoint: '80B', requiredPosition: PointPosition.normal);
    _addEastbound('303', 'crossover_303_304', viaPoint: '80B', requiredPosition: PointPosition.reverse);

    _addEastbound('305', '307');
    _addEastbound('307', '309');
    _addEastbound('309', '311');
    _addEastbound('311', '313');
    _addEastbound('313', '315');
    _addEastbound('315', '201'); // Continue to left section

    // ===== WESTBOUND (Lower Track 301-315) =====

    _addWestbound('315', '313');
    _addWestbound('313', '311');
    _addWestbound('311', '309');
    _addWestbound('309', '307');
    _addWestbound('307', '305');

    // Block 305 → Point 79B controls routing
    _addWestbound('305', '303', viaPoint: '79B', requiredPosition: PointPosition.normal);
    _addWestbound('305', 'crossover_303_304', viaPoint: '79B', requiredPosition: PointPosition.reverse);

    _addWestbound('303', '301');
    _addWestbound('301', '115'); // Continue to middle section

    // Crossover westbound exit → Point 80A controls exit
    _addWestbound('crossover_303_304', '302', viaPoint: '80A', requiredPosition: PointPosition.reverse);
    _addWestbound('crossover_303_304', '303', viaPoint: '80A', requiredPosition: PointPosition.normal);

    // Upper track westbound (blocks 300-314)
    _addWestbound('314', '312');
    _addWestbound('312', '310');
    _addWestbound('310', '308');
    _addWestbound('308', '306');
    _addWestbound('306', '304');

    // Block 304 → Point 80A controls routing
    _addWestbound('304', '302', viaPoint: '80A', requiredPosition: PointPosition.normal);
    _addWestbound('304', 'crossover_303_304', viaPoint: '80A', requiredPosition: PointPosition.reverse);

    _addWestbound('302', '300');
    _addWestbound('300', '114'); // Continue to middle section
  }

  /// Helper to add eastbound connection
  void _addEastbound(String from, String to, {String? viaPoint, PointPosition? requiredPosition}) {
    _eastboundConnections.putIfAbsent(from, () => []);
    _eastboundConnections[from]!.add(TrackConnection(
      fromBlockId: from,
      toBlockId: to,
      viaPointId: viaPoint,
      requiredPointPosition: requiredPosition,
    ));
  }

  /// Helper to add westbound connection
  void _addWestbound(String from, String to, {String? viaPoint, PointPosition? requiredPosition}) {
    _westboundConnections.putIfAbsent(from, () => []);
    _westboundConnections[from]!.add(TrackConnection(
      fromBlockId: from,
      toBlockId: to,
      viaPointId: viaPoint,
      requiredPointPosition: requiredPosition,
    ));
  }

  /// Get next block by following physical track geometry
  /// This is the core routing function - it follows the track graph based on point positions
  String? getNextBlock(String currentBlockId, int direction, Map<String, dynamic> points) {
    final connections = direction > 0
        ? _eastboundConnections[currentBlockId]
        : _westboundConnections[currentBlockId];

    if (connections == null || connections.isEmpty) {
      return null; // No connection defined
    }

    // Find the valid connection based on current point positions
    for (final connection in connections) {
      if (connection.viaPointId == null) {
        // No point control - always valid
        return connection.toBlockId;
      }

      // Check if point is in required position
      final point = points[connection.viaPointId];
      if (point != null && point.position == connection.requiredPointPosition) {
        return connection.toBlockId;
      }
    }

    // No valid connection found (all points in wrong position)
    // This should not happen in a well-designed railway, but return null as safety
    return null;
  }

  /// Get all possible next blocks from current block (regardless of point positions)
  List<String> getPossibleNextBlocks(String currentBlockId, int direction) {
    final connections = direction > 0
        ? _eastboundConnections[currentBlockId]
        : _westboundConnections[currentBlockId];

    if (connections == null) return [];

    return connections.map((c) => c.toBlockId).toList();
  }

  /// Get the point controlling routing from this block (if any)
  String? getControllingPoint(String currentBlockId, int direction) {
    final connections = direction > 0
        ? _eastboundConnections[currentBlockId]
        : _westboundConnections[currentBlockId];

    if (connections == null || connections.isEmpty) return null;

    // Find if any connection has a point control
    for (final connection in connections) {
      if (connection.viaPointId != null) {
        return connection.viaPointId;
      }
    }

    return null;
  }

  /// Get detailed routing information for debugging
  String getRoutingInfo(String currentBlockId, int direction, Map<String, dynamic> points) {
    final connections = direction > 0
        ? _eastboundConnections[currentBlockId]
        : _westboundConnections[currentBlockId];

    if (connections == null || connections.isEmpty) {
      return 'No connections from $currentBlockId (${direction > 0 ? 'eastbound' : 'westbound'})';
    }

    final buffer = StringBuffer();
    buffer.writeln('Routes from $currentBlockId (${direction > 0 ? 'eastbound' : 'westbound'}):');

    for (final connection in connections) {
      if (connection.viaPointId == null) {
        buffer.writeln('  → ${connection.toBlockId} (direct)');
      } else {
        final point = points[connection.viaPointId];
        final currentPos = point?.position?.toString() ?? 'unknown';
        final required = connection.requiredPointPosition.toString();
        final valid = point?.position == connection.requiredPointPosition ? '✓' : '✗';
        buffer.writeln('  → ${connection.toBlockId} via ${connection.viaPointId} (need $required, current $currentPos) $valid');
      }
    }

    return buffer.toString();
  }
}
