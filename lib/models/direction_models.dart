/// Direction models for railway guideway and junction management
/// Defines cardinal directions, guideway directions (GD0/GD1), and junction positions (Alpha/Gamma)

/// Cardinal directions for track and train orientation
enum CardinalDirection {
  north,
  east,
  south,
  west;

  /// Check if this direction is GD0 (South or West)
  bool get isGD0 => this == CardinalDirection.south || this == CardinalDirection.west;

  /// Check if this direction is GD1 (North or East)
  bool get isGD1 => this == CardinalDirection.north || this == CardinalDirection.east;

  /// Get the guideway direction for this cardinal direction
  GuidewayDirection get guidewayDirection {
    return isGD0 ? GuidewayDirection.gd0 : GuidewayDirection.gd1;
  }

  /// Get opposite direction (for reverse movement)
  CardinalDirection get opposite {
    switch (this) {
      case CardinalDirection.north:
        return CardinalDirection.south;
      case CardinalDirection.south:
        return CardinalDirection.north;
      case CardinalDirection.east:
        return CardinalDirection.west;
      case CardinalDirection.west:
        return CardinalDirection.east;
    }
  }

  /// Get perpendicular directions (for junction branching)
  List<CardinalDirection> get perpendicular {
    switch (this) {
      case CardinalDirection.north:
      case CardinalDirection.south:
        return [CardinalDirection.east, CardinalDirection.west];
      case CardinalDirection.east:
      case CardinalDirection.west:
        return [CardinalDirection.north, CardinalDirection.south];
    }
  }

  /// Convert to display string
  String get displayName {
    switch (this) {
      case CardinalDirection.north:
        return 'North';
      case CardinalDirection.east:
        return 'East';
      case CardinalDirection.south:
        return 'South';
      case CardinalDirection.west:
        return 'West';
    }
  }

  /// Convert to abbreviation
  String get abbreviation {
    switch (this) {
      case CardinalDirection.north:
        return 'N';
      case CardinalDirection.east:
        return 'E';
      case CardinalDirection.south:
        return 'S';
      case CardinalDirection.west:
        return 'W';
    }
  }

  /// Parse from string
  static CardinalDirection? fromString(String value) {
    switch (value.toLowerCase()) {
      case 'north':
      case 'n':
        return CardinalDirection.north;
      case 'east':
      case 'e':
        return CardinalDirection.east;
      case 'south':
      case 's':
        return CardinalDirection.south;
      case 'west':
      case 'w':
        return CardinalDirection.west;
      default:
        return null;
    }
  }
}

/// Guideway Direction - defines the operational direction of travel
/// GD0: Trains traveling South or West (decreasing direction)
/// GD1: Trains traveling North or East (increasing direction)
enum GuidewayDirection {
  gd0, // South or West
  gd1; // North or East

  /// Get cardinal directions that correspond to this GD
  List<CardinalDirection> get cardinalDirections {
    switch (this) {
      case GuidewayDirection.gd0:
        return [CardinalDirection.south, CardinalDirection.west];
      case GuidewayDirection.gd1:
        return [CardinalDirection.north, CardinalDirection.east];
    }
  }

  /// Get opposite guideway direction
  GuidewayDirection get opposite {
    return this == GuidewayDirection.gd0 ? GuidewayDirection.gd1 : GuidewayDirection.gd0;
  }

  /// Convert to display string
  String get displayName {
    switch (this) {
      case GuidewayDirection.gd0:
        return 'GD0 (South/West)';
      case GuidewayDirection.gd1:
        return 'GD1 (North/East)';
    }
  }

  /// Convert to abbreviation
  String get abbreviation {
    switch (this) {
      case GuidewayDirection.gd0:
        return 'GD0';
      case GuidewayDirection.gd1:
        return 'GD1';
    }
  }

  /// Parse from string
  static GuidewayDirection? fromString(String value) {
    switch (value.toLowerCase()) {
      case 'gd0':
      case '0':
        return GuidewayDirection.gd0;
      case 'gd1':
      case '1':
        return GuidewayDirection.gd1;
      default:
        return null;
    }
  }
}

/// Junction Position - Alpha or Gamma position at junctions
/// Alpha and Gamma positions represent different routing possibilities at junctions
/// where trains can change their guideway direction (GD0 to GD1 or vice versa)
enum JunctionPosition {
  /// Alpha position - typically the main/through route
  alpha,

  /// Gamma position - typically the diverging route
  gamma,

  /// Not at a junction position
  none;

  /// Convert to display string
  String get displayName {
    switch (this) {
      case JunctionPosition.alpha:
        return 'Alpha (Main)';
      case JunctionPosition.gamma:
        return 'Gamma (Diverging)';
      case JunctionPosition.none:
        return 'None';
    }
  }

  /// Convert to abbreviation
  String get abbreviation {
    switch (this) {
      case JunctionPosition.alpha:
        return 'α';
      case JunctionPosition.gamma:
        return 'γ';
      case JunctionPosition.none:
        return '-';
    }
  }

  /// Parse from string
  static JunctionPosition? fromString(String value) {
    switch (value.toLowerCase()) {
      case 'alpha':
      case 'α':
      case 'a':
        return JunctionPosition.alpha;
      case 'gamma':
      case 'γ':
      case 'g':
        return JunctionPosition.gamma;
      case 'none':
      case '-':
      case '':
        return JunctionPosition.none;
      default:
        return null;
    }
  }
}

/// Route direction change at a junction
/// Describes how a train's direction changes when passing through a junction
class JunctionDirectionChange {
  final String junctionId;
  final JunctionPosition position;
  final CardinalDirection approachDirection;
  final CardinalDirection exitDirection;
  final GuidewayDirection approachGD;
  final GuidewayDirection exitGD;

  JunctionDirectionChange({
    required this.junctionId,
    required this.position,
    required this.approachDirection,
    required this.exitDirection,
    required this.approachGD,
    required this.exitGD,
  });

  /// Check if this junction changes the guideway direction
  bool get changesGD => approachGD != exitGD;

  /// Get the type of junction change
  String get changeType {
    if (!changesGD) {
      return 'Through (No GD change)';
    } else if (approachGD == GuidewayDirection.gd0 && exitGD == GuidewayDirection.gd1) {
      return 'GD0 → GD1';
    } else {
      return 'GD1 → GD0';
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'junctionId': junctionId,
      'position': position.name,
      'approachDirection': approachDirection.name,
      'exitDirection': exitDirection.name,
      'approachGD': approachGD.name,
      'exitGD': exitGD.name,
      'changesGD': changesGD,
      'changeType': changeType,
    };
  }

  /// Create from JSON
  factory JunctionDirectionChange.fromJson(Map<String, dynamic> json) {
    return JunctionDirectionChange(
      junctionId: json['junctionId'] as String,
      position: JunctionPosition.values.firstWhere(
        (e) => e.name == json['position'],
        orElse: () => JunctionPosition.none,
      ),
      approachDirection: CardinalDirection.values.firstWhere(
        (e) => e.name == json['approachDirection'],
      ),
      exitDirection: CardinalDirection.values.firstWhere(
        (e) => e.name == json['exitDirection'],
      ),
      approachGD: GuidewayDirection.values.firstWhere(
        (e) => e.name == json['approachGD'],
      ),
      exitGD: GuidewayDirection.values.firstWhere(
        (e) => e.name == json['exitGD'],
      ),
    );
  }
}

/// Track segment with directional information
class DirectionalTrackSegment {
  final String blockId;
  final CardinalDirection primaryDirection;
  final GuidewayDirection primaryGD;
  final bool isBidirectional;

  DirectionalTrackSegment({
    required this.blockId,
    required this.primaryDirection,
    required this.primaryGD,
    this.isBidirectional = false,
  });

  /// Check if this track segment supports a specific direction
  bool supportsDirection(CardinalDirection direction) {
    if (isBidirectional) return true;
    return direction == primaryDirection;
  }

  /// Check if this track segment supports a specific GD
  bool supportsGD(GuidewayDirection gd) {
    if (isBidirectional) return true;
    return gd == primaryGD;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'blockId': blockId,
      'primaryDirection': primaryDirection.name,
      'primaryGD': primaryGD.name,
      'isBidirectional': isBidirectional,
    };
  }

  /// Create from JSON
  factory DirectionalTrackSegment.fromJson(Map<String, dynamic> json) {
    return DirectionalTrackSegment(
      blockId: json['blockId'] as String,
      primaryDirection: CardinalDirection.values.firstWhere(
        (e) => e.name == json['primaryDirection'],
      ),
      primaryGD: GuidewayDirection.values.firstWhere(
        (e) => e.name == json['primaryGD'],
      ),
      isBidirectional: json['isBidirectional'] as bool? ?? false,
    );
  }
}

/// Junction configuration with Alpha/Gamma positions and direction changes
class JunctionConfiguration {
  final String junctionId;
  final String name;
  final List<String> pointIds; // Points that form this junction
  final Map<JunctionPosition, JunctionDirectionChange> routes;
  final bool isThreeWay; // True if junction has 3 exits (left/right/straight)

  JunctionConfiguration({
    required this.junctionId,
    required this.name,
    required this.pointIds,
    required this.routes,
    this.isThreeWay = false,
  });

  /// Get the direction change for a specific junction position
  JunctionDirectionChange? getDirectionChange(JunctionPosition position) {
    return routes[position];
  }

  /// Get all possible exit directions from this junction
  List<CardinalDirection> get possibleExitDirections {
    return routes.values.map((r) => r.exitDirection).toList();
  }

  /// Check if this junction allows GD change
  bool get allowsGDChange {
    return routes.values.any((r) => r.changesGD);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'junctionId': junctionId,
      'name': name,
      'pointIds': pointIds,
      'routes': routes.map((key, value) => MapEntry(key.name, value.toJson())),
      'isThreeWay': isThreeWay,
    };
  }

  /// Create from JSON
  factory JunctionConfiguration.fromJson(Map<String, dynamic> json) {
    final routesMap = <JunctionPosition, JunctionDirectionChange>{};
    final routes = json['routes'] as Map<String, dynamic>?;
    if (routes != null) {
      routes.forEach((key, value) {
        final position = JunctionPosition.values.firstWhere(
          (e) => e.name == key,
          orElse: () => JunctionPosition.none,
        );
        routesMap[position] = JunctionDirectionChange.fromJson(value);
      });
    }

    return JunctionConfiguration(
      junctionId: json['junctionId'] as String,
      name: json['name'] as String,
      pointIds: List<String>.from(json['pointIds'] ?? []),
      routes: routesMap,
      isThreeWay: json['isThreeWay'] as bool? ?? false,
    );
  }
}

/// Helper class for direction calculations
class DirectionHelper {
  /// Calculate the guideway direction based on cardinal direction
  static GuidewayDirection getGuidewayDirection(CardinalDirection cardinalDir) {
    return cardinalDir.guidewayDirection;
  }

  /// Determine if a route changes GD
  static bool routeChangesGD(CardinalDirection from, CardinalDirection to) {
    return from.guidewayDirection != to.guidewayDirection;
  }

  /// Get the angle difference between two cardinal directions
  static int getAngleDifference(CardinalDirection from, CardinalDirection to) {
    final angles = {
      CardinalDirection.north: 0,
      CardinalDirection.east: 90,
      CardinalDirection.south: 180,
      CardinalDirection.west: 270,
    };

    final fromAngle = angles[from]!;
    final toAngle = angles[to]!;
    final diff = (toAngle - fromAngle).abs();

    return diff > 180 ? 360 - diff : diff;
  }

  /// Determine if a turn is left, right, or straight
  static String getTurnType(CardinalDirection from, CardinalDirection to) {
    if (from == to) return 'Straight';
    if (from == to.opposite) return 'Reverse';

    final angle = getAngleDifference(from, to);
    if (angle == 90) {
      // Determine if left or right based on clockwise rotation
      final clockwiseNext = _getClockwiseNext(from);
      return clockwiseNext == to ? 'Right' : 'Left';
    }

    return 'Unknown';
  }

  static CardinalDirection _getClockwiseNext(CardinalDirection dir) {
    switch (dir) {
      case CardinalDirection.north:
        return CardinalDirection.east;
      case CardinalDirection.east:
        return CardinalDirection.south;
      case CardinalDirection.south:
        return CardinalDirection.west;
      case CardinalDirection.west:
        return CardinalDirection.north;
    }
  }
}
