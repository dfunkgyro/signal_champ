import 'dart:math';

/// Represents a position along a track path
class TrackPosition {
  final double x;
  final double y;
  final double tangentAngle; // Angle in radians

  TrackPosition({
    required this.x,
    required this.y,
    required this.tangentAngle,
  });
}

/// Base class for track path segments
abstract class PathSegment {
  /// Get the length of this segment
  double get length;

  /// Get position at a specific distance along this segment (0.0 to length)
  TrackPosition getPositionAtDistance(double distance);

  /// Check if a distance is within this segment
  bool containsDistance(double distance) {
    return distance >= 0 && distance <= length;
  }
}

/// Straight track segment
class StraightSegment extends PathSegment {
  final double startX;
  final double startY;
  final double endX;
  final double endY;

  StraightSegment({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
  });

  @override
  double get length => sqrt(pow(endX - startX, 2) + pow(endY - startY, 2));

  @override
  TrackPosition getPositionAtDistance(double distance) {
    final progress = distance / length;
    final x = startX + (endX - startX) * progress;
    final y = startY + (endY - startY) * progress;
    final angle = atan2(endY - startY, endX - startX);

    return TrackPosition(x: x, y: y, tangentAngle: angle);
  }
}

/// Diagonal/crossover track segment (straight but at an angle)
class DiagonalSegment extends PathSegment {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double speedLimit; // Speed limit for this diverging route

  DiagonalSegment({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    this.speedLimit = 2.0, // Default lower speed for crossovers
  });

  @override
  double get length => sqrt(pow(endX - startX, 2) + pow(endY - startY, 2));

  @override
  TrackPosition getPositionAtDistance(double distance) {
    final progress = distance / length;
    final x = startX + (endX - startX) * progress;
    final y = startY + (endY - startY) * progress;
    final angle = atan2(endY - startY, endX - startX);

    return TrackPosition(x: x, y: y, tangentAngle: angle);
  }
}

/// Represents a complete track path as a sequence of segments
class TrackPath {
  final List<PathSegment> segments;
  final String pathId;

  TrackPath({
    required this.segments,
    required this.pathId,
  });

  /// Get the total length of the path
  double get totalLength {
    return segments.fold(0.0, (sum, segment) => sum + segment.length);
  }

  /// Get position at a specific chainage (distance from start of path)
  TrackPosition getPositionAtChainage(double chainage) {
    if (chainage < 0) chainage = 0;
    if (chainage > totalLength) chainage = totalLength;

    double accumulatedDistance = 0.0;

    for (final segment in segments) {
      final segmentEnd = accumulatedDistance + segment.length;

      if (chainage <= segmentEnd) {
        // Position is within this segment
        final distanceInSegment = chainage - accumulatedDistance;
        return segment.getPositionAtDistance(distanceInSegment);
      }

      accumulatedDistance = segmentEnd;
    }

    // Shouldn't reach here, but return last position if chainage exceeds path
    return segments.last.getPositionAtDistance(segments.last.length);
  }

  /// Get the speed limit at a specific chainage
  double getSpeedLimitAtChainage(double chainage) {
    double accumulatedDistance = 0.0;

    for (final segment in segments) {
      final segmentEnd = accumulatedDistance + segment.length;

      if (chainage <= segmentEnd) {
        // Position is within this segment
        if (segment is DiagonalSegment) {
          return segment.speedLimit;
        }
        return double.infinity; // No limit on straight segments
      }

      accumulatedDistance = segmentEnd;
    }

    return double.infinity;
  }

  /// Factory: Create a straight horizontal path
  factory TrackPath.straight({
    required String id,
    required double startX,
    required double endX,
    required double y,
  }) {
    return TrackPath(
      pathId: id,
      segments: [
        StraightSegment(
          startX: startX,
          startY: y,
          endX: endX,
          endY: y,
        ),
      ],
    );
  }

  /// Factory: Create a crossover path (diagonal)
  factory TrackPath.crossover({
    required String id,
    required double startX,
    required double startY,
    required double endX,
    required double endY,
    double speedLimit = 2.0,
  }) {
    return TrackPath(
      pathId: id,
      segments: [
        DiagonalSegment(
          startX: startX,
          startY: startY,
          endX: endX,
          endY: endY,
          speedLimit: speedLimit,
        ),
      ],
    );
  }

  /// Factory: Create a multi-segment crossover (e.g., crossover106 + crossover109)
  factory TrackPath.multiSegmentCrossover({
    required String id,
    required List<Map<String, dynamic>> segmentData,
  }) {
    final segments = <PathSegment>[];

    for (final data in segmentData) {
      segments.add(DiagonalSegment(
        startX: data['startX'] as double,
        startY: data['startY'] as double,
        endX: data['endX'] as double,
        endY: data['endY'] as double,
        speedLimit: (data['speedLimit'] as double?) ?? 2.0,
      ));
    }

    return TrackPath(pathId: id, segments: segments);
  }
}

/// Helper class to build and manage track paths for the entire network
class TrackNetworkGeometry {
  final Map<String, TrackPath> _paths = {};

  void addPath(TrackPath path) {
    _paths[path.pathId] = path;
  }

  TrackPath? getPath(String blockId) {
    return _paths[blockId];
  }

  bool hasPath(String blockId) {
    return _paths.containsKey(blockId);
  }

  /// Remove a path from the network
  void removePath(String blockId) {
    _paths.remove(blockId);
  }

  /// Update an existing path's geometry
  void updatePath(String blockId, TrackPath newPath) {
    _paths[blockId] = newPath;
  }

  /// Regenerate path for a block based on its current geometry
  void regeneratePathForBlock(dynamic block) {
    if (block.isCrossover) {
      // For crossovers, need special handling - keep existing for now
      // In full implementation, would calculate based on point positions
      return;
    }

    // Generate straight path based on block coordinates
    final path = TrackPath.straight(
      id: block.id,
      startX: block.startX,
      endX: block.endX,
      y: block.y,
    );
    updatePath(block.id, path);
  }

  /// Generate crossover path based on point geometry
  TrackPath generateCrossoverPath({
    required String id,
    required double startX,
    required double startY,
    required double endX,
    required double endY,
    required double speedLimit,
  }) {
    return TrackPath.crossover(
      id: id,
      startX: startX,
      startY: startY,
      endX: endX,
      endY: endY,
      speedLimit: speedLimit,
    );
  }

  /// Get all path IDs
  List<String> getAllPathIds() {
    return _paths.keys.toList();
  }

  /// Clear all paths
  void clearAll() {
    _paths.clear();
  }

  /// Initialize default track geometry for the railway
  void initializeDefaultGeometry() {
    // Upper track - straight segments
    addPath(TrackPath.straight(id: '100', startX: 0, endX: 200, y: 100));
    addPath(TrackPath.straight(id: '102', startX: 200, endX: 400, y: 100));
    addPath(TrackPath.straight(id: '104', startX: 400, endX: 600, y: 100));
    addPath(TrackPath.straight(id: '106', startX: 600, endX: 800, y: 100));
    addPath(TrackPath.straight(id: '108', startX: 800, endX: 1000, y: 100));
    addPath(TrackPath.straight(id: '110', startX: 1000, endX: 1200, y: 100));
    addPath(TrackPath.straight(id: '112', startX: 1200, endX: 1400, y: 100));
    addPath(TrackPath.straight(id: '114', startX: 1400, endX: 1600, y: 100));

    // Lower track - straight segments
    addPath(TrackPath.straight(id: '101', startX: 0, endX: 200, y: 300));
    addPath(TrackPath.straight(id: '103', startX: 200, endX: 400, y: 300));
    addPath(TrackPath.straight(id: '105', startX: 400, endX: 600, y: 300));
    addPath(TrackPath.straight(id: '107', startX: 600, endX: 800, y: 300));
    addPath(TrackPath.straight(id: '109', startX: 800, endX: 1000, y: 300));
    addPath(TrackPath.straight(id: '111', startX: 1000, endX: 1200, y: 300));
    addPath(TrackPath.straight(id: '113', startX: 1200, endX: 1400, y: 300));
    addPath(TrackPath.straight(id: '115', startX: 1400, endX: 1600, y: 300));

    // Crossover segments - diagonal paths with speed restrictions
    addPath(TrackPath.crossover(
      id: 'crossover106',
      startX: 600,
      startY: 100,
      endX: 700,
      endY: 200,
      speedLimit: 2.0, // 40% of normal speed
    ));

    addPath(TrackPath.crossover(
      id: 'crossover109',
      startX: 700,
      startY: 200,
      endX: 800,
      endY: 300,
      speedLimit: 2.0, // 40% of normal speed
    ));
  }
}
