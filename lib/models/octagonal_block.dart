import 'dart:math' as math;
import 'dart:ui' show Offset;

/// Represents an octagonal railway block that connects at 135° or 45° angles
/// Allows users to create octagonal and irregular octagonal track layouts
class OctagonalBlock {
  final String id;
  String name;

  /// Center point of the block
  double centerX;
  double centerY;

  /// Length of the straight section
  final double length;

  /// Rotation angle in degrees (0°, 45°, 90°, 135°, 180°, 225°, 270°, 315°)
  double rotationAngle;

  /// Connection type: 'straight', 'curve_left', 'curve_right'
  final String connectionType;

  /// Whether this block is occupied
  bool occupied;
  String? occupyingTrainId;

  /// Connected blocks (up to 2 - entry and exit)
  final List<String> connectedBlockIds;

  OctagonalBlock({
    required this.id,
    required this.name,
    required this.centerX,
    required this.centerY,
    this.length = 100.0,
    this.rotationAngle = 0.0,
    this.connectionType = 'straight',
    this.occupied = false,
    this.occupyingTrainId,
    List<String>? connectedBlockIds,
  }) : connectedBlockIds = connectedBlockIds ?? [];

  /// Get the start point of this block
  Offset get startPoint {
    final radians = rotationAngle * math.pi / 180.0;
    final halfLength = length / 2;
    return Offset(
      centerX - halfLength * math.cos(radians),
      centerY - halfLength * math.sin(radians),
    );
  }

  /// Get the end point of this block
  Offset get endPoint {
    final radians = rotationAngle * math.pi / 180.0;
    final halfLength = length / 2;
    return Offset(
      centerX + halfLength * math.cos(radians),
      centerY + halfLength * math.sin(radians),
    );
  }

  /// Check if a position is within this block
  bool containsPosition(double x, double y) {
    final start = startPoint;
    final end = endPoint;

    // Calculate distance from point to line segment
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final lengthSquared = dx * dx + dy * dy;

    if (lengthSquared == 0) return false;

    // Calculate projection parameter
    var t = ((x - start.dx) * dx + (y - start.dy) * dy) / lengthSquared;
    t = t.clamp(0.0, 1.0);

    // Find closest point on line segment
    final closestX = start.dx + t * dx;
    final closestY = start.dy + t * dy;

    // Check if distance is within tolerance (20 units)
    final distanceSquared = (x - closestX) * (x - closestX) + (y - closestY) * (y - closestY);
    return distanceSquared <= 400; // 20^2
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'centerX': centerX,
      'centerY': centerY,
      'length': length,
      'rotationAngle': rotationAngle,
      'connectionType': connectionType,
      'occupied': occupied,
      'occupyingTrainId': occupyingTrainId,
      'connectedBlockIds': connectedBlockIds,
    };
  }

  /// Create from JSON
  factory OctagonalBlock.fromJson(Map<String, dynamic> json) {
    return OctagonalBlock(
      id: json['id'] as String,
      name: json['name'] as String,
      centerX: (json['centerX'] as num).toDouble(),
      centerY: (json['centerY'] as num).toDouble(),
      length: (json['length'] as num?)?.toDouble() ?? 100.0,
      rotationAngle: (json['rotationAngle'] as num?)?.toDouble() ?? 0.0,
      connectionType: json['connectionType'] as String? ?? 'straight',
      occupied: json['occupied'] as bool? ?? false,
      occupyingTrainId: json['occupyingTrainId'] as String?,
      connectedBlockIds: List<String>.from(json['connectedBlockIds'] as List? ?? []),
    );
  }

  /// Create a standard octagonal track layout with 8 blocks
  static List<OctagonalBlock> createOctagon({
    required double centerX,
    required double centerY,
    required double radius,
    required double blockLength,
    String idPrefix = 'OCT',
  }) {
    final blocks = <OctagonalBlock>[];
    final angleStep = 45.0; // 360° / 8 = 45°

    for (int i = 0; i < 8; i++) {
      final angle = i * angleStep;
      final radians = angle * math.pi / 180.0;

      // Position block at radius distance from center
      final blockCenterX = centerX + radius * math.cos(radians);
      final blockCenterY = centerY + radius * math.sin(radians);

      blocks.add(OctagonalBlock(
        id: '${idPrefix}_${i + 1}',
        name: 'Octagon Side ${i + 1}',
        centerX: blockCenterX,
        centerY: blockCenterY,
        length: blockLength,
        rotationAngle: angle,
        connectionType: 'straight',
        connectedBlockIds: [
          '${idPrefix}_${i == 0 ? 8 : i}',
          '${idPrefix}_${(i + 2) > 8 ? 1 : i + 2}',
        ],
      ));
    }

    return blocks;
  }

  /// Create a semi-circular octagon with 5 blocks
  static List<OctagonalBlock> createSemiOctagon({
    required double centerX,
    required double centerY,
    required double radius,
    required double blockLength,
    String idPrefix = 'SEMI_OCT',
  }) {
    final blocks = <OctagonalBlock>[];
    final angleStep = 45.0;

    // Create 5 blocks forming a semi-circle (180°)
    for (int i = 0; i < 5; i++) {
      final angle = i * angleStep;
      final radians = angle * math.pi / 180.0;

      final blockCenterX = centerX + radius * math.cos(radians);
      final blockCenterY = centerY + radius * math.sin(radians);

      blocks.add(OctagonalBlock(
        id: '${idPrefix}_${i + 1}',
        name: 'Semi-Octagon Side ${i + 1}',
        centerX: blockCenterX,
        centerY: blockCenterY,
        length: blockLength,
        rotationAngle: angle,
        connectionType: 'straight',
      ));
    }

    return blocks;
  }

  /// Create an irregular octagon (5 blocks semi-circular at ends + 4 blocks on sides)
  static List<OctagonalBlock> createIrregularOctagon({
    required double centerX,
    required double centerY,
    required double straightLength,
    required double curveRadius,
    required double blockLength,
    String idPrefix = 'IRR_OCT',
  }) {
    final blocks = <OctagonalBlock>[];

    // Left semi-circular end (5 blocks)
    final leftSemi = createSemiOctagon(
      centerX: centerX - straightLength / 2,
      centerY: centerY,
      radius: curveRadius,
      blockLength: blockLength,
      idPrefix: '${idPrefix}_LEFT',
    );
    blocks.addAll(leftSemi);

    // Top straight section (2 blocks)
    blocks.add(OctagonalBlock(
      id: '${idPrefix}_TOP_1',
      name: 'Top Straight 1',
      centerX: centerX - straightLength / 4,
      centerY: centerY - curveRadius,
      length: blockLength,
      rotationAngle: 0.0,
    ));
    blocks.add(OctagonalBlock(
      id: '${idPrefix}_TOP_2',
      name: 'Top Straight 2',
      centerX: centerX + straightLength / 4,
      centerY: centerY - curveRadius,
      length: blockLength,
      rotationAngle: 0.0,
    ));

    // Right semi-circular end (5 blocks)
    final rightSemi = createSemiOctagon(
      centerX: centerX + straightLength / 2,
      centerY: centerY,
      radius: curveRadius,
      blockLength: blockLength,
      idPrefix: '${idPrefix}_RIGHT',
    );
    // Flip the semi-circle
    for (var block in rightSemi) {
      block.rotationAngle += 180.0;
    }
    blocks.addAll(rightSemi);

    // Bottom straight section (2 blocks)
    blocks.add(OctagonalBlock(
      id: '${idPrefix}_BOTTOM_1',
      name: 'Bottom Straight 1',
      centerX: centerX + straightLength / 4,
      centerY: centerY + curveRadius,
      length: blockLength,
      rotationAngle: 180.0,
    ));
    blocks.add(OctagonalBlock(
      id: '${idPrefix}_BOTTOM_2',
      name: 'Bottom Straight 2',
      centerX: centerX - straightLength / 4,
      centerY: centerY + curveRadius,
      length: blockLength,
      rotationAngle: 180.0,
    ));

    return blocks;
  }
}
