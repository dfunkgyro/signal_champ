# Railway Directional System Guide

## Overview

The Signal Champ railway simulation now includes a comprehensive directional system that recognizes:
- **Cardinal Directions** (North, East, South, West)
- **Guideway Directions** (GD0, GD1)
- **Junction Positions** (Alpha, Gamma)

This system ensures realistic railway operations with proper directional routing, junction management, and safety interlocking.

---

## Core Concepts

### 1. Cardinal Directions

Physical compass directions that describe the orientation of tracks, trains, and signals:

- **North (N)**: Upward direction
- **East (E)**: Rightward direction
- **South (S)**: Downward direction
- **West (W)**: Leftward direction

**Example:**
```dart
signal.cardinalDirection = CardinalDirection.north;  // Signal facing north
train.cardinalDirection = CardinalDirection.east;    // Train traveling east
```

### 2. Guideway Directions (GD)

Operational direction classification for train movement:

#### **GD0 (Guideway Direction 0)**
- Trains traveling **SOUTH** or **WEST**
- Considered the "decreasing" or "backward" direction
- Color coding: Often associated with one track direction

#### **GD1 (Guideway Direction 1)**
- Trains traveling **NORTH** or **EAST**
- Considered the "increasing" or "forward" direction
- Color coding: Often associated with opposite track direction

**Mapping:**
```
North → GD1
East  → GD1
South → GD0
West  → GD0
```

**Example:**
```dart
// A train traveling west is in GD0
if (train.cardinalDirection == CardinalDirection.west) {
  assert(train.guidewayDirection == GuidewayDirection.gd0);
  assert(train.isGD0 == true);
}

// A signal facing east controls GD1 traffic
if (signal.direction == SignalDirection.east) {
  assert(signal.guidewayDirection == GuidewayDirection.gd1);
}
```

### 3. Junction Positions (Alpha/Gamma)

At junction locations, routes are classified by their routing type:

#### **Alpha Position (α)**
- **Main/Through Route**: Straight or primary path
- Typically maintains the same GD
- Lower priority for GD changes

#### **Gamma Position (γ)**
- **Diverging Route**: Turnout or branch path
- May change GD (GD0 ↔ GD1)
- Higher likelihood of direction changes

#### **Three-Way Junctions**
At complex junctions with 3 exits:
- Trains can go **left**, **right**, or **straight**
- Each path may have different Alpha/Gamma designation
- GD allocation changes based on exit direction

**Example:**
```dart
// Junction with direction change
final junction = JunctionDirectionChange(
  junctionId: 'J01',
  position: JunctionPosition.gamma,  // Diverging route
  approachDirection: CardinalDirection.east,   // Coming from east (GD1)
  exitDirection: CardinalDirection.south,      // Exiting south (GD0)
  approachGD: GuidewayDirection.gd1,
  exitGD: GuidewayDirection.gd0,               // GD changes!
);

print(junction.changeType);  // Output: "GD1 → GD0"
print(junction.changesGD);   // Output: true
```

---

## Implementation Details

### File Structure

```
lib/
├── models/
│   ├── direction_models.dart          ← NEW: Core directional types
│   └── control_table_models.dart      ← UPDATED: Added directional fields
├── screens/
│   └── terminal_station_models.dart   ← UPDATED: Signal, Train, Block, Point with directions
├── services/
│   └── control_table_ai_service.dart  ← UPDATED: AI understands GD0/GD1 and Alpha/Gamma
└── widgets/
    └── ai_control_table_panel.dart    ← Uses directional AI
```

### Key Classes

#### `CardinalDirection` (Enum)
```dart
enum CardinalDirection {
  north, east, south, west;

  bool get isGD0;  // true for south/west
  bool get isGD1;  // true for north/east
  GuidewayDirection get guidewayDirection;
  CardinalDirection get opposite;  // N↔S, E↔W
  List<CardinalDirection> get perpendicular;  // N/S→[E,W]
}
```

#### `GuidewayDirection` (Enum)
```dart
enum GuidewayDirection {
  gd0,  // South or West
  gd1;  // North or East

  List<CardinalDirection> get cardinalDirections;
  GuidewayDirection get opposite;
  String get abbreviation;  // "GD0" or "GD1"
}
```

#### `JunctionPosition` (Enum)
```dart
enum JunctionPosition {
  alpha,   // Main/through route
  gamma,   // Diverging route
  none;    // Not at a junction

  String get abbreviation;  // "α", "γ", or "-"
}
```

#### `JunctionDirectionChange` (Class)
```dart
class JunctionDirectionChange {
  final String junctionId;
  final JunctionPosition position;
  final CardinalDirection approachDirection;
  final CardinalDirection exitDirection;
  final GuidewayDirection approachGD;
  final GuidewayDirection exitGD;

  bool get changesGD;  // true if approachGD != exitGD
  String get changeType;  // "Through", "GD0→GD1", or "GD1→GD0"
}
```

#### `JunctionConfiguration` (Class)
```dart
class JunctionConfiguration {
  final String junctionId;
  final String name;
  final List<String> pointIds;
  final Map<JunctionPosition, JunctionDirectionChange> routes;
  final bool isThreeWay;  // 3-exit junction

  bool get allowsGDChange;
  List<CardinalDirection> get possibleExitDirections;
}
```

### Model Updates

#### Signal
```dart
class Signal {
  SignalDirection direction;  // north, east, south, west
  JunctionPosition junctionPosition;  // Alpha, Gamma, or None
  String? junctionId;

  GuidewayDirection get guidewayDirection;
  bool get isAtJunction;
  String get displayInfo;  // "S01 (NORTH, GD1)"
}
```

#### Train
```dart
class Train {
  int direction;  // -1 = left/west, 1 = right/east
  CardinalDirection cardinalDirection;  // N, E, S, W

  GuidewayDirection get guidewayDirection;
  bool get isGD0;
  bool get isGD1;
  void updateCardinalFromIntDirection();
}
```

#### Point
```dart
class Point {
  String? junctionId;
  Map<PointPosition, JunctionDirectionChange>? directionChanges;

  bool get isJunctionPoint;
  JunctionDirectionChange? get currentDirectionChange;
  bool get causesGDChange;
}
```

#### BlockSection
```dart
class BlockSection {
  CardinalDirection? primaryDirection;
  bool isBidirectional;

  GuidewayDirection? get guidewayDirection;
  bool supportsDirection(CardinalDirection direction);
  bool supportsGD(GuidewayDirection gd);
}
```

#### ControlTableEntry
```dart
class ControlTableEntry {
  GuidewayDirection? requiredGD;  // Required GD for this route
  JunctionPosition? junctionPosition;  // Alpha/Gamma if at junction
  JunctionDirectionChange? directionChange;  // Direction change details
}
```

---

## AI Integration

The Control Table AI now fully understands directional concepts:

### Analysis Capabilities

The AI analyzes:
1. **GD Conflicts**: Opposing GD traffic on non-bidirectional blocks
2. **Junction Position Correctness**: Alpha/Gamma properly configured
3. **Direction Changes**: Routes with GD changes have correct junction positions
4. **Block Directional Logic**: Blocks marked with correct primary direction and GD

### Context Provided to AI

```
=== SIGNALS AND ROUTES ===
Signal S01 (Direction: NORTH, GD1) [Junction: J01, Position: α]:
  Route R1:
    Target: green
    Required GD: GD1
    Junction Position: Alpha (Main)
    Direction Change: Through (No GD change)
    Required Blocks Clear: 100, 101
    ...

=== POINTS ===
Point P1 (Main Junction) [Junction: J01]:
  Current: normal, Locked: false
  Direction Change (normal): Through (No GD change)
    Approach: east (GD1)
    Exit: east (GD1)
  ...

=== BLOCKS ===
Block 100: CLEAR (Direction: EAST, GD1)
Block 101: CLEAR (Direction: SOUTH, GD0, Bidirectional)
```

### AI Prompts Updated

Both analysis and chat system prompts include:
- Cardinal direction definitions
- GD0/GD1 concepts and rules
- Alpha/Gamma junction position explanations
- 3-way junction routing logic
- Safety rules for directional conflicts

---

## Usage Examples

### Example 1: Simple Signal with Direction

```dart
final signal = Signal(
  id: 'S01',
  x: 100,
  y: 200,
  direction: SignalDirection.north,  // Facing north = GD1
  routes: [...],
);

print(signal.guidewayDirection);  // GuidewayDirection.gd1
print(signal.displayInfo);        // "S01 (NORTH, GD1)"
```

### Example 2: Junction with Direction Change

```dart
// Point at a junction
final point = Point(
  id: 'P1',
  name: 'Main Junction',
  x: 300,
  y: 400,
  junctionId: 'J01',
  directionChanges: {
    PointPosition.normal: JunctionDirectionChange(
      junctionId: 'J01',
      position: JunctionPosition.alpha,  // Main route
      approachDirection: CardinalDirection.west,  // GD0
      exitDirection: CardinalDirection.west,      // GD0
      approachGD: GuidewayDirection.gd0,
      exitGD: GuidewayDirection.gd0,  // No change
    ),
    PointPosition.reverse: JunctionDirectionChange(
      junctionId: 'J01',
      position: JunctionPosition.gamma,  // Diverging route
      approachDirection: CardinalDirection.west,  // GD0
      exitDirection: CardinalDirection.north,     // GD1
      approachGD: GuidewayDirection.gd0,
      exitGD: GuidewayDirection.gd1,  // GD CHANGES!
    ),
  },
);

// When point is normal (main route)
point.position = PointPosition.normal;
print(point.causesGDChange);  // false

// When point is reverse (diverging route)
point.position = PointPosition.reverse;
print(point.causesGDChange);  // true
print(point.currentDirectionChange?.changeType);  // "GD0 → GD1"
```

### Example 3: Train Direction Tracking

```dart
final train = Train(
  id: 'T01',
  name: 'Express 1',
  vin: 'VIN001',
  x: 500,
  y: 600,
  speed: 40,
  targetSpeed: 60,
  direction: 1,  // Moving right
  cardinalDirection: CardinalDirection.east,  // East = GD1
  color: Colors.blue,
  controlMode: TrainControlMode.automatic,
);

print(train.guidewayDirection);  // GuidewayDirection.gd1
print(train.isGD1);              // true
print(train.isGD0);              // false

// Train changes direction
train.cardinalDirection = CardinalDirection.south;  // Now GD0
print(train.guidewayDirection);  // GuidewayDirection.gd0
```

### Example 4: Block with Direction

```dart
final block = BlockSection(
  id: '100',
  name: 'Platform 1 Approach',
  startX: 0,
  endX: 200,
  y: 100,
  primaryDirection: CardinalDirection.east,  // GD1
  isBidirectional: false,  // One-way only
);

// Check if train can use this block
final trainEast = Train(..., cardinalDirection: CardinalDirection.east);
print(block.supportsDirection(trainEast.cardinalDirection));  // true

final trainWest = Train(..., cardinalDirection: CardinalDirection.west);
print(block.supportsDirection(trainWest.cardinalDirection));  // false (safety!)
```

### Example 5: Control Table Entry with Direction

```dart
final entry = ControlTableEntry(
  id: 'S01_R1',
  signalId: 'S01',
  routeId: 'R1',
  routeName: 'Platform 1',
  targetAspect: SignalAspect.green,
  requiredGD: GuidewayDirection.gd1,  // Only for GD1 trains
  junctionPosition: JunctionPosition.alpha,  // Main route
  directionChange: null,  // No direction change
  requiredBlocksClear: ['100', '101'],
  ...
);
```

---

## Safety Rules

### 1. GD Conflict Prevention

**Rule**: Opposing GD traffic cannot use the same non-bidirectional block simultaneously.

```dart
// SAFE: Bidirectional block
final block = BlockSection(
  id: '100',
  isBidirectional: true,
  // primaryDirection is null or ignored
);

// UNSAFE: Non-bidirectional block with opposing traffic
final block1 = BlockSection(
  id: '101',
  primaryDirection: CardinalDirection.east,  // GD1
  isBidirectional: false,
);
// If a GD0 train tries to use block1, AI will flag as CRITICAL safety hazard
```

### 2. Junction Position Validation

**Rule**: Routes with GD changes MUST have correct Alpha/Gamma position.

```dart
// CORRECT: Diverging route with GD change has Gamma position
final entry = ControlTableEntry(
  id: 'S01_R2',
  junctionPosition: JunctionPosition.gamma,
  directionChange: JunctionDirectionChange(
    approachGD: GuidewayDirection.gd0,
    exitGD: GuidewayDirection.gd1,  // Changes GD
    ...
  ),
);

// INCORRECT: Main route changing GD (AI will flag as warning)
final badEntry = ControlTableEntry(
  id: 'S01_R3',
  junctionPosition: JunctionPosition.alpha,  // Wrong! Should be Gamma
  directionChange: JunctionDirectionChange(
    approachGD: GuidewayDirection.gd0,
    exitGD: GuidewayDirection.gd1,  // Changing GD on Alpha route
    ...
  ),
);
```

### 3. Block Direction Marking

**Rule**: Blocks should be marked with their operational direction unless bidirectional.

```dart
// CORRECT: Block has primary direction
final block1 = BlockSection(
  id: '100',
  primaryDirection: CardinalDirection.north,  // GD1
  isBidirectional: false,
);

// CORRECT: Bidirectional block
final block2 = BlockSection(
  id: '101',
  primaryDirection: CardinalDirection.south,  // Nominal direction
  isBidirectional: true,  // But allows both GDs
);

// INCORRECT: No direction specified for one-way block (AI will suggest adding)
final badBlock = BlockSection(
  id: '102',
  primaryDirection: null,  // Missing!
  isBidirectional: false,
);
```

---

## Directional Helper Functions

### `DirectionHelper` Class

Utility functions for direction calculations:

```dart
// Get GD from cardinal direction
final gd = DirectionHelper.getGuidewayDirection(CardinalDirection.north);
// Returns: GuidewayDirection.gd1

// Check if route changes GD
final changesGD = DirectionHelper.routeChangesGD(
  CardinalDirection.west,   // GD0
  CardinalDirection.north,  // GD1
);
// Returns: true

// Get angle between directions
final angle = DirectionHelper.getAngleDifference(
  CardinalDirection.north,
  CardinalDirection.east,
);
// Returns: 90

// Determine turn type
final turn = DirectionHelper.getTurnType(
  CardinalDirection.east,
  CardinalDirection.south,
);
// Returns: "Right"
```

---

## AI Suggestions with Direction

The AI can now generate directional-aware suggestions:

### Example AI Analysis

**Input Configuration:**
- Signal S01 facing EAST (GD1)
- Route uses blocks 100 (GD1) and 101 (no direction specified)
- Point P1 at junction but no direction change configured

**AI Output:**
```json
{
  "summary": "Found 2 directional issues and 1 optimization",
  "conflicts": [
    {
      "type": "missing_direction",
      "severity": "warning",
      "title": "Block 101 missing direction specification",
      "description": "Block 101 is used by GD1 signal S01 but has no primary direction specified",
      "affectedItems": ["101", "S01_R1"],
      "suggestion": "Add primaryDirection: EAST and set isBidirectional based on operational requirements"
    },
    {
      "type": "junction_config",
      "severity": "info",
      "title": "Point P1 junction missing direction changes",
      "description": "Point P1 is at junction J01 but has no direction change configuration",
      "affectedItems": ["P1", "J01"],
      "suggestion": "Configure directionChanges map for both normal and reverse positions"
    }
  ],
  "suggestions": [
    {
      "type": "block_direction",
      "title": "Configure Block 101 Direction",
      "description": "Set block 101 to GD1 (EAST) to match signal S01 usage",
      "priority": "medium",
      "changes": {
        "action": "update_block",
        "data": {
          "blockId": "101",
          "primaryDirection": "east",
          "isBidirectional": false
        }
      }
    }
  ]
}
```

---

## Testing Directional Logic

### Unit Test Examples

```dart
test('Train GD is correctly derived from cardinal direction', () {
  final train = Train(
    id: 'T01',
    cardinalDirection: CardinalDirection.south,
    ...
  );

  expect(train.guidewayDirection, GuidewayDirection.gd0);
  expect(train.isGD0, true);
  expect(train.isGD1, false);
});

test('Junction direction change calculates GD change correctly', () {
  final change = JunctionDirectionChange(
    junctionId: 'J01',
    position: JunctionPosition.gamma,
    approachDirection: CardinalDirection.west,
    exitDirection: CardinalDirection.north,
    approachGD: GuidewayDirection.gd0,
    exitGD: GuidewayDirection.gd1,
  );

  expect(change.changesGD, true);
  expect(change.changeType, 'GD0 → GD1');
});

test('Block supports correct GD traffic', () {
  final block = BlockSection(
    id: '100',
    primaryDirection: CardinalDirection.east,
    isBidirectional: false,
  );

  expect(block.supportsGD(GuidewayDirection.gd1), true);
  expect(block.supportsGD(GuidewayDirection.gd0), false);
});
```

---

## Migration Guide

### For Existing Layouts

1. **Update Signals**:
   - All signals now have N/E/S/W directions instead of just E/W
   - Add `junctionPosition` if signal is at a junction
   - Add `junctionId` if at a junction

2. **Update Blocks**:
   - Add `primaryDirection` (CardinalDirection)
   - Add `isBidirectional` flag
   - Existing blocks default to no direction (AI will suggest adding)

3. **Update Points**:
   - Add `junctionId` if point is at a junction
   - Add `directionChanges` map for junction points
   - Specify Alpha/Gamma routing

4. **Update Trains**:
   - Keep existing `int direction` (-1/1)
   - Add `cardinalDirection` (defaults to east)
   - Use `updateCardinalFromIntDirection()` for migration

5. **Update Control Table Entries**:
   - Add `requiredGD` if route is direction-specific
   - Add `junctionPosition` if at junction
   - Add `directionChange` if route changes GD

### Backward Compatibility

- All new fields are **optional** with sensible defaults
- Existing code continues to work
- AI will suggest adding directional information
- Gradual migration supported

---

## Future Enhancements

### Planned Features

1. **Visual Direction Indicators**:
   - Arrow overlays on signals showing GD
   - Color-coded tracks by GD (GD0 = blue, GD1 = orange)
   - Junction position markers (α/γ symbols)

2. **Automatic Direction Detection**:
   - Infer cardinal directions from track layout geometry
   - Auto-suggest junction positions based on point angles
   - Calculate GD changes automatically

3. **Direction-Based Route Validation**:
   - Real-time GD conflict warnings during route setting
   - Prevent opposing GD routes on same block
   - Junction position validation before route clearance

4. **Enhanced AI Capabilities**:
   - Suggest optimal junction configurations
   - Detect complex multi-junction GD change scenarios
   - Optimize track direction assignments

5. **Simulation Enhancements**:
   - Train behavior based on GD at junctions
   - Realistic junction routing animations
   - GD-aware collision avoidance

---

## Troubleshooting

### Common Issues

**Issue**: AI reports "Opposing GD traffic on same block"
**Solution**: Either make block bidirectional or separate GD0/GD1 traffic to different blocks

**Issue**: Junction routes not changing GD as expected
**Solution**: Verify `directionChanges` map on Point has correct approachGD/exitGD values

**Issue**: Signal shows wrong GD
**Solution**: Check `signal.direction` is set to correct CardinalDirection (N/E/S/W)

**Issue**: Train GD doesn't match track
**Solution**: Update `train.cardinalDirection` when train changes direction

---

## API Reference

### Enums

- `CardinalDirection`: north, east, south, west
- `GuidewayDirection`: gd0, gd1
- `JunctionPosition`: alpha, gamma, none

### Classes

- `JunctionDirectionChange`: Direction change at junction
- `JunctionConfiguration`: Complete junction setup
- `DirectionalTrackSegment`: Track with direction info
- `DirectionHelper`: Utility functions

### Model Fields

- `Signal.junctionPosition`: JunctionPosition
- `Signal.junctionId`: String?
- `Train.cardinalDirection`: CardinalDirection
- `Point.junctionId`: String?
- `Point.directionChanges`: Map<PointPosition, JunctionDirectionChange>?
- `BlockSection.primaryDirection`: CardinalDirection?
- `BlockSection.isBidirectional`: bool
- `ControlTableEntry.requiredGD`: GuidewayDirection?
- `ControlTableEntry.junctionPosition`: JunctionPosition?
- `ControlTableEntry.directionChange`: JunctionDirectionChange?

---

**Version**: 1.0.0
**Last Updated**: December 25, 2025
**Author**: Signal Champ Development Team
