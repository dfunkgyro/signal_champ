import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'track_geometry.dart';
import 'railway_network_editor.dart';

enum SignalState { red, green, yellow, blue }

enum PointPosition { normal, reverse }

enum TrainStatus { moving, stopped, waiting, completed, reversing }

enum Direction { east, west }

enum TransponderType { t1, t2, t3, t6 }

enum CbtcMode {
  auto,      // Automatic mode - cyan
  pm,        // Protective Manual mode - orange
  rm,        // Restrictive Manual mode - brown
  off,       // Off mode - white
  storage    // Storage mode - green
}

class Transponder {
  final String id;
  final TransponderType type;
  double x;  // Made mutable for edit mode
  double y;  // Made mutable for edit mode
  final String description;

  Transponder({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.description,
  });
}

class WifiAntenna {
  final String id;
  double x;  // Made mutable for edit mode
  double y;  // Made mutable for edit mode
  bool isActive;

  WifiAntenna({
    required this.id,
    required this.x,
    required this.y,
    this.isActive = true,
  });
}

enum TrackCategory { mainLine, siding, yard, reversing, platform }

class BlockSection {
  final String id;
  double startX;         // MADE MUTABLE for editing
  double endX;           // MADE MUTABLE for editing
  double y;              // MADE MUTABLE for editing
  String? nextBlock;     // MADE MUTABLE for topology editing
  String? prevBlock;     // MADE MUTABLE for topology editing
  bool occupied;
  bool isCrossover;      // MADE MUTABLE to convert types
  final bool isReversingArea;
  bool closedBySmc;

  // NEW: Professional track attributes
  double gradient;       // Track slope in % (positive = uphill eastbound)
  double maxSpeed;       // Maximum speed in km/h for this section
  TrackCategory category;
  bool electrified;
  List<String> allowedTrainTypes; // Which train categories can use this track
  String? trackOwner;    // Railway company or authority

  BlockSection({
    required this.id,
    required this.startX,
    required this.endX,
    required this.y,
    this.nextBlock,
    this.prevBlock,
    this.occupied = false,
    this.isCrossover = false,
    this.isReversingArea = false,
    this.closedBySmc = false,
    this.gradient = 0.0,
    this.maxSpeed = 100.0, // Default 100 km/h
    this.category = TrackCategory.mainLine,
    this.electrified = true,
    List<String>? allowedTrainTypes,
    this.trackOwner,
  }) : allowedTrainTypes = allowedTrainTypes ?? ['all'];

  /// Calculate physical length of the block
  double get length => (endX - startX).abs();

  /// Update track geometry and regenerate path
  void updateGeometry({
    double? newStartX,
    double? newEndX,
    double? newY,
  }) {
    if (newStartX != null) startX = newStartX;
    if (newEndX != null) endX = newEndX;
    if (newY != null) y = newY;
  }

  /// Update track connections (topology)
  void updateConnections({
    String? newNextBlock,
    String? newPrevBlock,
  }) {
    if (newNextBlock != null) nextBlock = newNextBlock;
    if (newPrevBlock != null) prevBlock = newPrevBlock;
  }
}

enum SignalType {
  main,        // Main signal (absolute stop)
  distant,     // Distant signal (advance warning)
  shunting,    // Shunting signal (yard movements)
  repeater,    // Repeater signal (extends visibility)
  coasting,    // Coasting signal (power off for electrified trains)
  combined,    // Combined main + distant
}

enum SignalDirection { eastbound, westbound, bidirectional }

class Signal {
  final String id;
  double x;                  // MADE MUTABLE for editing
  double y;                  // MADE MUTABLE for editing
  SignalState state;
  int? route;
  List<String> controlledBlocks;         // MADE MUTABLE for editing
  List<String> requiredPointPositions;   // MADE MUTABLE for editing
  String lastStateChangeReason;

  // NEW: Professional signal attributes
  SignalType signalType;
  SignalDirection direction;
  List<SignalState> availableAspects; // What aspects this signal can display
  double sightDistance;      // Visibility distance in meters
  bool isAutomatic;          // Automatic (track circuit) vs. manual
  String? protectedRoute;    // Which route/junction this protects

  Signal({
    required this.id,
    required this.x,
    required this.y,
    this.state = SignalState.red,
    this.route,
    required this.controlledBlocks,
    this.requiredPointPositions = const [],
    this.lastStateChangeReason = '',
    this.signalType = SignalType.main,
    this.direction = SignalDirection.eastbound,
    List<SignalState>? availableAspects,
    this.sightDistance = 200.0,
    this.isAutomatic = true,
    this.protectedRoute,
  }) : availableAspects = availableAspects ??
        [SignalState.red, SignalState.yellow, SignalState.green];

  /// Move signal to new position
  void moveTo(double newX, double newY) {
    x = newX;
    y = newY;
  }

  /// Update which blocks this signal protects
  void updateControlledBlocks(List<String> newBlocks) {
    controlledBlocks = newBlocks;
  }

  /// Update point position requirements for routes
  void updatePointRequirements(List<String> newRequirements) {
    requiredPointPositions = newRequirements;
  }
}

class Point {
  final String id;
  double x;              // MADE MUTABLE for editing
  double y;              // MADE MUTABLE for editing
  PointPosition position;
  double animationProgress;
  String? reservedByVin;
  String? reservedDestination;

  // NEW: Professional point/crossover attributes
  double divergingRouteAngle;    // Angle of diverging route in degrees
  double divergingRouteRadius;   // Radius of diverging curve in meters
  double divergingSpeedLimit;    // Speed limit on diverging route (km/h)
  String? straightTrackId;       // Block ID for straight/normal route
  String? divergingTrackId;      // Block ID for diverging/reverse route
  bool isLeftHand;               // Left-hand vs. right-hand turnout

  Point({
    required this.id,
    required this.x,
    required this.y,
    this.position = PointPosition.normal,
    this.animationProgress = 0.0,
    this.reservedByVin,
    this.reservedDestination,
    this.divergingRouteAngle = 15.0,    // Default 15° turnout
    this.divergingRouteRadius = 300.0,  // Default 300m radius
    this.divergingSpeedLimit = 40.0,    // Default 40 km/h on diverging
    this.straightTrackId,
    this.divergingTrackId,
    this.isLeftHand = true,
  });

  /// Move point to new position
  void moveTo(double newX, double newY) {
    x = newX;
    y = newY;
  }

  /// Update diverging route geometry
  void updateDivergingRoute({
    double? angle,
    double? radius,
    double? speedLimit,
  }) {
    if (angle != null) divergingRouteAngle = angle;
    if (radius != null) divergingRouteRadius = radius;
    if (speedLimit != null) divergingSpeedLimit = speedLimit;
  }

  /// Update track connections
  void updateConnections({
    String? straight,
    String? diverging,
  }) {
    if (straight != null) straightTrackId = straight;
    if (diverging != null) divergingTrackId = diverging;
  }
}

class MovementAuthority {
  final double maxDistance; // Maximum distance the green arrow extends
  final String? limitReason; // Why the arrow stopped (obstacle, destination, etc.)
  final bool hasDestination; // Whether train has a destination

  MovementAuthority({
    required this.maxDistance,
    this.limitReason,
    this.hasDestination = false,
  });
}

/// Represents a single carriage in a train consist
class Carriage {
  double x;
  double y;
  double rotation; // Angle in radians
  final double offsetFromLead; // Distance behind the lead carriage (in chainage units)

  Carriage({
    required this.x,
    required this.y,
    required this.rotation,
    required this.offsetFromLead,
  });
}

class Train {
  final String id;
  final String name;
  final String vin; // Vehicle Identification Number
  double x; // Lead carriage position (for backwards compatibility)
  double y; // Lead carriage position (for backwards compatibility)
  double speed;
  String currentBlock;
  TrainStatus status;
  bool isSelected;
  DateTime? estimatedArrival;
  Direction direction;
  double progress;
  Color color;
  double angle; // Lead carriage angle (for backwards compatibility)
  List<String> routeHistory;
  String stopReason;
  DateTime? lastStatusChange;
  final bool isCbtcEquipped;
  CbtcMode cbtcMode;
  String? smcDestination; // SMC-assigned destination (block ID or platform name)
  MovementAuthority? movementAuthority; // CBTC movement authority visualization

  // NEW: Chainage-based positioning and multi-carriage support
  double chainage; // Distance traveled along current track path
  List<Carriage> carriages; // Individual carriages in the consist

  // NEW: Crossover tracking for UI visualization
  String? currentCrossoverRoute; // e.g., "104→crossover106→crossover109→109"
  bool isOnCrossover = false; // True when actively traversing a crossover

  Train({
    required this.id,
    required this.name,
    required this.vin,
    required this.x,
    required this.y,
    required this.speed,
    required this.currentBlock,
    this.status = TrainStatus.moving,
    this.isSelected = false,
    this.estimatedArrival,
    this.direction = Direction.east,
    this.progress = 0.0,
    required this.color,
    this.angle = 0.0,
    this.routeHistory = const [],
    this.stopReason = '',
    this.lastStatusChange,
    this.isCbtcEquipped = false,
    this.cbtcMode = CbtcMode.off,
    this.smcDestination,
    this.movementAuthority,
    this.chainage = 0.0,
    List<Carriage>? carriages,
  }) : carriages = carriages ?? [] {
    // Initialize carriages if not provided
    if (this.carriages.isEmpty) {
      _initializeCarriages();
    }
  }

  /// Initialize default 4-carriage consist
  void _initializeCarriages() {
    const carriageSpacing = 50.0; // Distance between carriage centers

    for (int i = 0; i < 4; i++) {
      carriages.add(Carriage(
        x: x,
        y: y,
        rotation: angle,
        offsetFromLead: i * carriageSpacing,
      ));
    }
  }

  /// Update all carriage positions based on track path
  void updateCarriagePositions(TrackPath trackPath) {
    for (int i = 0; i < carriages.length; i++) {
      final carriage = carriages[i];
      final carriageChainage = chainage - carriage.offsetFromLead;

      if (carriageChainage >= 0) {
        final position = trackPath.getPositionAtChainage(carriageChainage);
        carriage.x = position.x;
        carriage.y = position.y;
        carriage.rotation = position.tangentAngle;

        // Update lead carriage properties for backwards compatibility
        if (i == 0) {
          x = position.x;
          y = position.y;
          angle = position.tangentAngle;
        }
      }
    }
  }
}

class RailwayModel extends ChangeNotifier {
  final List<String> _eventLog = [];
  List<String> get eventLog => _eventLog;

  // Track Network Geometry System
  final TrackNetworkGeometry trackGeometry = TrackNetworkGeometry();

  // Railway Network Editor - Professional editing system
  RailwayNetworkEditor? _networkEditor;
  RailwayNetworkEditor get networkEditor {
    _networkEditor ??= RailwayNetworkEditor(
      notifyListeners: notifyListeners,
      blocks: blocks,
      signals: signals,
      points: points,
      trackGeometry: trackGeometry,
      addEvent: _addEvent,
    );
    return _networkEditor!;
  }

  // Edit Mode State
  bool _editModeEnabled = false;
  bool get editModeEnabled => _editModeEnabled;

  void toggleEditMode() {
    _editModeEnabled = !_editModeEnabled;
    if (_editModeEnabled) {
      _addEvent('🔧 Edit Mode ENABLED - Simulation paused');
      // In full implementation, would pause train movement
    } else {
      _addEvent('✅ Edit Mode DISABLED - Simulation resumed');
    }
    notifyListeners();
  }

  // CBTC System
  bool _cbtcDevicesEnabled = false;
  bool _cbtcModeActive = false;
  List<Transponder> _transponders = [];
  List<WifiAntenna> _wifiAntennas = [];

  bool get cbtcDevicesEnabled => _cbtcDevicesEnabled;
  bool get cbtcModeActive => _cbtcModeActive;
  List<Transponder> get transponders => _transponders;
  List<WifiAntenna> get wifiAntennas => _wifiAntennas;

  // Constructor
  RailwayModel() {
    // Initialize track geometry on construction
    trackGeometry.initializeDefaultGeometry();
  }

  List<BlockSection> blocks = [
    BlockSection(
        id: '100',
        startX: 0,
        endX: 200,
        y: 100,
        nextBlock: '102',
        isReversingArea: true),
    BlockSection(
        id: '102',
        startX: 200,
        endX: 400,
        y: 100,
        nextBlock: '104',
        prevBlock: '100'),
    BlockSection(
        id: '104',
        startX: 400,
        endX: 600,
        y: 100,
        nextBlock: '106',
        prevBlock: '102'),
    BlockSection(
        id: '106',
        startX: 600,
        endX: 800,
        y: 100,
        nextBlock: '108',
        prevBlock: '104'),
    BlockSection(
        id: '108',
        startX: 800,
        endX: 1000,
        y: 100,
        nextBlock: '110',
        prevBlock: '106'),
    BlockSection(
        id: '110',
        startX: 1000,
        endX: 1200,
        y: 100,
        nextBlock: '112',
        prevBlock: '108'),
    BlockSection(
        id: '112',
        startX: 1200,
        endX: 1400,
        y: 100,
        nextBlock: '114',
        prevBlock: '110'),
    BlockSection(
        id: '114',
        startX: 1400,
        endX: 1600,
        y: 100,
        prevBlock: '112',
        isReversingArea: true),
    BlockSection(
        id: '101',
        startX: 0,
        endX: 200,
        y: 300,
        nextBlock: '103',
        prevBlock: '111',
        isReversingArea: true),
    BlockSection(
        id: '103',
        startX: 200,
        endX: 400,
        y: 300,
        nextBlock: '105',
        prevBlock: '101'),
    BlockSection(
        id: '105',
        startX: 400,
        endX: 600,
        y: 300,
        nextBlock: '107',
        prevBlock: '103'),
    BlockSection(
        id: '107',
        startX: 600,
        endX: 800,
        y: 300,
        nextBlock: '109',
        prevBlock: '105'),
    BlockSection(
        id: '109',
        startX: 800,
        endX: 1000,
        y: 300,
        nextBlock: '111',
        prevBlock: '107'),
    BlockSection(
        id: '111',
        startX: 1000,
        endX: 1200,
        y: 300,
        nextBlock: '113',  // UPDATED: Can go eastbound to 113
        prevBlock: '109'),
    BlockSection(
        id: '113',
        startX: 1200,
        endX: 1400,
        y: 300,
        nextBlock: '115',
        prevBlock: '111'),
    BlockSection(
        id: '115',
        startX: 1400,
        endX: 1600,
        y: 300,
        nextBlock: '101',  // Connects to reversing area
        prevBlock: '113',
        isReversingArea: true),
    BlockSection(
        id: 'crossover106',
        startX: 400,
        endX: 500,
        y: 100,
        nextBlock: 'crossover109',
        prevBlock: '102',
        isCrossover: true),
    BlockSection(
        id: 'crossover109',
        startX: 500,
        endX: 600,
        y: 300,
        nextBlock: '107',
        prevBlock: 'crossover106',
        isCrossover: true),
  ];

  List<Signal> signals = [
    Signal(
        id: 'C31',
        x: 410,
        y: 80,
        controlledBlocks: ['104', '106', '108', '110', '112'],
        requiredPointPositions: ['78A:normal']),
    Signal(id: 'C33', x: 1210, y: 80, controlledBlocks: ['112', '114']),
    Signal(
        id: 'C28',
        x: 380,
        y: 300,
        state: SignalState.green,
        controlledBlocks: ['101', '103', '105'],
        lastStateChangeReason: 'Initial state'),
    Signal(
        id: 'C30',
        x: 980,
        y: 300,
        controlledBlocks: ['109', '111'],
        requiredPointPositions: ['78B:normal']),
  ];

  List<Point> points = [
    Point(id: '78A', x: 400, y: 100),  // End of block 102 - controls crossover entry from upper track
    Point(id: '78B', x: 600, y: 300),  // Start of block 107 - controls crossover entry from lower track
  ];

  List<Train> trains = [];
  int trainCounter = 0;
  final Random _random = Random();
  final List<Color> _trainColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.deepOrange,
  ];

  void _addEvent(String message) {
    final timestamp = DateTime.now();
    final formattedMessage = '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')} - $message';
    _eventLog.insert(0, formattedMessage);
    if (_eventLog.length > 100) {
      _eventLog.removeLast();
    }
    if (kDebugMode) {
      print('[RailwayModel] $formattedMessage');
    }
  }

  bool isBlockOccupied(String blockId) {
    return blocks.any((block) => block.id == blockId && block.occupied);
  }

  void markBlockOccupied(String blockId, bool occupied) {
    final block = blocks.firstWhere((b) => b.id == blockId);
    final wasOccupied = block.occupied;
    block.occupied = occupied;
    if (wasOccupied != occupied) {
      _addEvent('Block $blockId ${occupied ? "OCCUPIED" : "CLEARED"}');
    }
    notifyListeners();
  }

  void setSignalState(String signalId, SignalState state, {int? route}) {
    final signal = signals.firstWhere((s) => s.id == signalId);
    final oldState = signal.state;
    final oldRoute = signal.route;
    
    signal.state = state;
    if (route != null) signal.route = route;

    // Auto-set points based on signal route
    if (signalId == 'C31' && route != null) {
      if (route == 1) {
        setPointPosition('78A', PointPosition.normal);
        signal.lastStateChangeReason = 'Route 1 selected (main line via 78A normal)';
      } else if (route == 2) {
        setPointPosition('78A', PointPosition.reverse);
        setPointPosition('78B', PointPosition.reverse);
        signal.lastStateChangeReason = 'Route 2 selected (crossover via 78A+78B reverse)';
      }
    }

    if (oldState != state || oldRoute != route) {
      _addEvent('Signal $signalId set to ${state.name.toUpperCase()}' +
          (route != null ? ' Route $route' : ''));
    }

    notifyListeners();
  }

  void setPointPosition(String pointId, PointPosition position) {
    final point = points.firstWhere((p) => p.id == pointId);
    final oldPosition = point.position;
    point.position = position;

    if (oldPosition != position) {
      _addEvent('Point $pointId switched to ${position.name.toUpperCase()}');
    }

    _animatePoint(point, oldPosition);
    _updateSignalsBasedOnPoints();
    notifyListeners();
  }

  void _animatePoint(Point point, PointPosition oldPosition) async {
    point.animationProgress = 0.0;
    const totalSteps = 30;
    const stepDuration = Duration(milliseconds: 16);

    for (int i = 0; i <= totalSteps; i++) {
      await Future.delayed(stepDuration);
      point.animationProgress = i / totalSteps;
      notifyListeners();
    }
  }

  void _updateSignalsBasedOnPoints() {
    for (final signal in signals) {
      if (signal.requiredPointPositions.isEmpty) continue;

      bool pointsCorrect = true;
      List<String> incorrectPoints = [];
      
      for (final pointReq in signal.requiredPointPositions) {
        final parts = pointReq.split(':');
        final pointId = parts[0];
        final requiredPosition =
            parts[1] == 'normal' ? PointPosition.normal : PointPosition.reverse;

        final point = points.firstWhere((p) => p.id == pointId);
        if (point.position != requiredPosition) {
          pointsCorrect = false;
          incorrectPoints.add('$pointId needs ${requiredPosition.name} but is ${point.position.name}');
        }
      }

      // Special logic for C31 route 2 - requires both 78A and 78B reverse
      if (signal.id == 'C31' && signal.route == 2) {
        final point78A = points.firstWhere((p) => p.id == '78A');
        final point78B = points.firstWhere((p) => p.id == '78B');
        
        if (point78A.position != PointPosition.reverse) {
          pointsCorrect = false;
          incorrectPoints.add('78A must be REVERSE for route 2');
        }
        if (point78B.position != PointPosition.reverse) {
          pointsCorrect = false;
          incorrectPoints.add('78B must be REVERSE for route 2');
        }
      }

      final previousState = signal.state;
      
      // Update signal state based on point positions and block occupancy
      if (pointsCorrect && _areBlocksClearForSignal(signal)) {
        signal.state = SignalState.green;
        signal.lastStateChangeReason = 'All conditions met: points correct, blocks clear';
      } else {
        signal.state = SignalState.red;
        List<String> reasons = [];
        if (!pointsCorrect) {
          reasons.addAll(incorrectPoints);
        }
        if (!_areBlocksClearForSignal(signal)) {
          final occupiedBlocks = signal.controlledBlocks.where((blockId) => isBlockOccupied(blockId)).toList();
          reasons.add('Occupied blocks: ${occupiedBlocks.join(", ")}');
        }
        signal.lastStateChangeReason = reasons.join('; ');
      }

      if (previousState != signal.state) {
        _addEvent('Signal ${signal.id} changed to ${signal.state.name.toUpperCase()}: ${signal.lastStateChangeReason}');
      }
    }
  }

  bool _areBlocksClearForSignal(Signal signal) {
    for (final blockId in signal.controlledBlocks) {
      if (isBlockOccupied(blockId)) {
        return false;
      }
    }
    // For C31 route 2, also check crossover blocks
    if (signal.id == 'C31' && signal.route == 2) {
      if (isBlockOccupied('crossover106') || isBlockOccupied('crossover109')) {
        return false;
      }
    }
    return true;
  }

  void addTrain({bool isCbtc = false}) {
    if (trains.length >= 8) {
      _addEvent('Cannot add train: Maximum 8 trains reached');
      return;
    }

    if (!canCreateNewTrain()) {
      _addEvent('Cannot add train: Entry blocks occupied');
      return;
    }

    trainCounter++;
    final vin = _generateVin(trainCounter, isCbtc);
    final newTrain = Train(
      id: 'train_$trainCounter',
      name: isCbtc ? 'CBTC Train $trainCounter' : 'Train $trainCounter',
      vin: vin,
      x: 0,
      y: 85,
      speed: 2.0,
      currentBlock: '100',
      direction: Direction.east,
      color: isCbtc ? getCbtcModeColor(CbtcMode.off) : _trainColors[_random.nextInt(_trainColors.length)],
      routeHistory: ['100'],
      stopReason: '',
      lastStatusChange: DateTime.now(),
      isCbtcEquipped: isCbtc,
      cbtcMode: CbtcMode.off,
    );
    trains.add(newTrain);
    markBlockOccupied('100', true);
    _addEvent('${newTrain.name} added to block 100${isCbtc ? " (CBTC equipped)" : ""}');
    notifyListeners();
  }

  String _generateVin(int trainNumber, bool isCbtc) {
    final prefix = isCbtc ? 'CBTC' : 'TRAN';
    final timestamp = DateTime.now().millisecondsSinceEpoch % 100000;
    return '$prefix${trainNumber.toString().padLeft(3, '0')}$timestamp';
  }

  Color getCbtcModeColor(CbtcMode mode) {
    switch (mode) {
      case CbtcMode.auto:
        return Colors.cyan;
      case CbtcMode.pm:
        return Colors.orange;
      case CbtcMode.rm:
        return Colors.brown;
      case CbtcMode.off:
        return Colors.white;
      case CbtcMode.storage:
        return Colors.green;
    }
  }

  void setCbtcTrainMode(String trainId, CbtcMode mode) {
    final train = trains.firstWhere((t) => t.id == trainId);
    if (!train.isCbtcEquipped) {
      _addEvent('Cannot set CBTC mode: ${train.name} is not CBTC equipped');
      return;
    }

    final oldMode = train.cbtcMode;
    train.cbtcMode = mode;
    train.color = getCbtcModeColor(mode);

    if (oldMode != mode) {
      _addEvent('${train.name} mode changed: ${oldMode.name.toUpperCase()} → ${mode.name.toUpperCase()}');
    }
    notifyListeners();
  }

  void removeTrain(String trainId) {
    final train = trains.firstWhere((t) => t.id == trainId);
    markBlockOccupied(train.currentBlock, false);
    trains.removeWhere((t) => t.id == trainId);
    _addEvent('Train ${train.name} removed from system');
    notifyListeners();
  }

  void updateTrainProgress(String trainId, double newProgress) {
    final train = trains.firstWhere((t) => t.id == trainId);
    train.progress = newProgress.clamp(0.0, 1.0);

    // NEW: Path-constrained movement using chainage
    _updateTrainPositionAlongPath(train);

    notifyListeners();
  }

  /// Update train position using chainage along track path
  void _updateTrainPositionAlongPath(Train train) {
    final trackPath = trackGeometry.getPath(train.currentBlock);
    if (trackPath == null) {
      // Fallback to old positioning if no path defined
      _updateLegacyPosition(train);
      return;
    }

    // Calculate chainage based on progress through the block
    final totalLength = trackPath.totalLength;
    if (train.direction == Direction.east) {
      train.chainage = totalLength * train.progress;
    } else {
      // Westbound: chainage goes from end to start
      train.chainage = totalLength * (1.0 - train.progress);
    }

    // Update all carriage positions based on track path geometry
    train.updateCarriagePositions(trackPath);

    notifyListeners();
  }

  /// Legacy positioning for blocks without defined paths
  void _updateLegacyPosition(Train train) {
    final block = blocks.firstWhere((b) => b.id == train.currentBlock);

    if (train.direction == Direction.east) {
      train.x = block.startX + ((block.endX - block.startX) * train.progress);
      train.angle = 0.0;
    } else {
      train.x = block.endX - ((block.endX - block.startX) * train.progress);
      train.angle = pi;
    }
    train.y = block.y - 15;

    // Update lead carriage for legacy mode
    if (train.carriages.isNotEmpty) {
      train.carriages[0].x = train.x;
      train.carriages[0].y = train.y;
      train.carriages[0].rotation = train.angle;
    }
  }

  void moveTrainToNextBlock(String trainId) {
    final train = trains.firstWhere((t) => t.id == trainId);
    if (train.status != TrainStatus.moving) return;

    final currentBlock = blocks.firstWhere((b) => b.id == train.currentBlock);
    final nextBlockId = getNextBlock(train.currentBlock, train.direction);

    if (nextBlockId == null) {
      train.status = TrainStatus.waiting;
      train.stopReason = 'No next block available - end of line';
      _addEvent('${train.name} stopped in ${train.currentBlock}: ${train.stopReason}');
      return;
    }

    if (isBlockOccupied(nextBlockId)) {
      train.status = TrainStatus.waiting;
      train.stopReason = 'Block $nextBlockId occupied';
      _addEvent('${train.name} waiting in ${train.currentBlock}: ${train.stopReason}');
      return;
    }

    if (!_isSignalClearForBlock(train, nextBlockId)) {
      train.status = TrainStatus.waiting;
      // stopReason is set in _isSignalClearForBlock
      _addEvent('${train.name} stopped at signal in ${train.currentBlock}: ${train.stopReason}');
      return;
    }

    // All clear - move to next block
    final nextBlock = blocks.firstWhere((b) => b.id == nextBlockId);
    markBlockOccupied(train.currentBlock, false);
    train.currentBlock = nextBlockId;
    train.progress = 0.0;
    train.routeHistory.add(nextBlockId);
    train.stopReason = '';
    markBlockOccupied(nextBlockId, true);
    _addEvent('${train.name} entered block $nextBlockId');

    // Track crossover routing for UI visualization
    _updateCrossoverTracking(train, nextBlockId);

    _handleBlockTransition(train, nextBlockId);
    notifyListeners();
  }

  bool _isSignalClearForBlock(Train train, String blockId) {
    for (final signal in signals) {
      if (signal.controlledBlocks.contains(blockId)) {
        // Check if points are correctly set for this signal
        bool pointsCorrect = true;
        List<String> pointIssues = [];
        
        for (final pointReq in signal.requiredPointPositions) {
          final parts = pointReq.split(':');
          final pointId = parts[0];
          final requiredPosition = parts[1] == 'normal'
              ? PointPosition.normal
              : PointPosition.reverse;

          final point = points.firstWhere((p) => p.id == pointId);
          if (point.position != requiredPosition) {
            pointsCorrect = false;
            pointIssues.add('$pointId is ${point.position.name}, needs ${requiredPosition.name}');
          }
        }

        // Special check for C31 route 2
        if (signal.id == 'C31' && signal.route == 2) {
          final point78A = points.firstWhere((p) => p.id == '78A');
          final point78B = points.firstWhere((p) => p.id == '78B');
          
          if (point78A.position != PointPosition.reverse) {
            pointsCorrect = false;
            pointIssues.add('C31 Route 2: 78A must be REVERSE');
          }
          if (point78B.position != PointPosition.reverse) {
            pointsCorrect = false;
            pointIssues.add('C31 Route 2: 78B must be REVERSE');
          }
        }

        if (signal.state != SignalState.green) {
          train.stopReason = 'Signal ${signal.id} is ${signal.state.name.toUpperCase()}';
          return false;
        }
        
        if (!pointsCorrect) {
          train.stopReason = 'Points not set correctly: ${pointIssues.join(", ")}';
          return false;
        }

        return true;
      }
    }
    return true;
  }

  /// Update crossover tracking for UI visualization
  void _updateCrossoverTracking(Train train, String nextBlockId) {
    final isEastbound = train.direction == Direction.east;
    final currentBlock = train.currentBlock;

    // Entering crossover from block 102 eastbound
    if (currentBlock == '102' && nextBlockId == 'crossover106' && isEastbound) {
      train.currentCrossoverRoute = '102→crossover106→crossover109→107';
      train.isOnCrossover = true;
    }

    // Entering crossover from block 107 westbound
    if (currentBlock == '107' && nextBlockId == 'crossover109' && !isEastbound) {
      train.currentCrossoverRoute = '107→crossover109→crossover106→102';
      train.isOnCrossover = true;
    }

    // Exiting crossover to block 107 (eastbound complete)
    if (currentBlock == 'crossover109' && nextBlockId == '107' && isEastbound) {
      train.isOnCrossover = false;
      train.currentCrossoverRoute = null;
    }

    // Exiting crossover to block 102 (westbound complete)
    if (currentBlock == 'crossover106' && nextBlockId == '102' && !isEastbound) {
      train.isOnCrossover = false;
      train.currentCrossoverRoute = null;
    }
  }

  void _handleBlockTransition(Train train, String newBlockId) {
    // Handle train completion at terminal blocks
    if ((newBlockId == '114' && train.direction == Direction.east) ||
        (newBlockId == '101' && train.direction == Direction.west)) {
      // Train reached terminal - allow reversing or completion
      if (train.status != TrainStatus.completed) {
        train.status = TrainStatus.waiting;
        train.stopReason = 'Reached terminal block $newBlockId';
        _addEvent('${train.name} reached terminal at block $newBlockId');
      }
    }

    // Auto-reverse at terminal blocks after delay
    if ((newBlockId == '114' && train.direction == Direction.east) ||
        (newBlockId == '101' && train.direction == Direction.west)) {
      Future.delayed(const Duration(seconds: 2), () {
        if (trains.any((t) => t.id == train.id) &&
            train.status != TrainStatus.completed) {
          reverseTrainDirection(train.id);
        }
      });
    }
  }

  void setTrainSpeed(String trainId, double speed) {
    final train = trains.firstWhere((t) => t.id == trainId);
    final oldSpeed = train.speed;
    train.speed = speed.clamp(0.5, 5.0);
    if (oldSpeed != train.speed) {
      _addEvent('${train.name} speed changed to ${train.speed.toStringAsFixed(1)}');
    }
    notifyListeners();
  }

  void setTrainStatus(String trainId, TrainStatus status) {
    final train = trains.firstWhere((t) => t.id == trainId);
    final oldStatus = train.status;
    train.status = status;
    train.lastStatusChange = DateTime.now();
    if (oldStatus != status) {
      _addEvent('${train.name} status changed to ${status.name.toUpperCase()}');
    }
    notifyListeners();
  }

  void reverseTrainDirection(String trainId) {
    final train = trains.firstWhere((t) => t.id == trainId);

    // Reverse direction
    train.direction =
        train.direction == Direction.east ? Direction.west : Direction.east;

    // REALISTIC MULTI-CARRIAGE REVERSAL
    // In real trains, when direction reverses:
    // - Physical positions stay the same
    // - Front carriage becomes rear carriage
    // - Rear carriage becomes front carriage
    // - Carriage order reverses

    if (train.carriages.isNotEmpty) {
      // Reverse the carriage list order
      // [Loco, Car1, Car2, Tail] becomes [Tail, Car2, Car1, Loco]
      train.carriages = train.carriages.reversed.toList();

      // Recalculate offsetFromLead for each carriage
      // The new front carriage (former rear) becomes offset 0
      // Each subsequent carriage gets the next offset value
      const carriageSpacing = 50.0;
      for (int i = 0; i < train.carriages.length; i++) {
        train.carriages[i] = Carriage(
          x: train.carriages[i].x,
          y: train.carriages[i].y,
          rotation: train.carriages[i].rotation,
          offsetFromLead: i * carriageSpacing,
        );
      }

      // Update train's lead carriage position to match new front carriage
      if (train.carriages.isNotEmpty) {
        train.x = train.carriages[0].x;
        train.y = train.carriages[0].y;
        train.angle = train.carriages[0].rotation;
      }
    }

    train.status = TrainStatus.moving;
    train.stopReason = '';
    _addEvent('${train.name} reversed direction to ${train.direction.name.toUpperCase()}');
    notifyListeners();
  }

  void selectTrain(String trainId) {
    for (var train in trains) {
      train.isSelected = train.id == trainId;
    }
    notifyListeners();
  }

  String? getNextBlock(String currentBlock, Direction direction) {
    final isEastbound = direction == Direction.east;
    final block = blocks.firstWhere((b) => b.id == currentBlock);

    // ═══════════════════════════════════════════════════════════════════════════
    // CROSSOVER ROUTING LOGIC - All 3 crossover sections
    // Points only control routing at their location, not downstream
    // ═══════════════════════════════════════════════════════════════════════════

    // ───────────────────────────────────────────────────────────────────────────
    // LEFT CROSSOVER (West Terminal) - Points 76A/76B/77A/77B
    // ───────────────────────────────────────────────────────────────────────────

    // Block 210 (upper) eastbound approaching point 76A at x=-450
    if (currentBlock == '210' && isEastbound) {
      final point76A = points.firstWhere((p) => p.id == '76A');
      if (point76A.position == PointPosition.reverse) {
        return 'crossover_211_212'; // Diverge to crossover (upper to lower)
      }
      return '210A'; // Straight through (76A normal)
    }

    // Block 211 (lower) eastbound approaching point 77B at x=-450
    if (currentBlock == '211' && isEastbound) {
      final point77B = points.firstWhere((p) => p.id == '77B');
      if (point77B.position == PointPosition.reverse) {
        return 'crossover_211_212'; // Diverge to crossover (lower to upper)
      }
      return '211A'; // Straight through (77B normal)
    }

    // Block 212 (upper) westbound approaching point 77A at x=-300
    if (currentBlock == '212' && !isEastbound) {
      final point77A = points.firstWhere((p) => p.id == '77A');
      if (point77A.position == PointPosition.reverse) {
        return 'crossover_211_212'; // Diverge to crossover (upper to lower)
      }
      return '210A'; // Straight through (77A normal)
    }

    // Block 213 (lower) westbound approaching point 76B at x=-300
    if (currentBlock == '213' && !isEastbound) {
      final point76B = points.firstWhere((p) => p.id == '76B');
      if (point76B.position == PointPosition.reverse) {
        return 'crossover_211_212'; // Diverge to crossover (lower to upper)
      }
      return '211A'; // Straight through (76B normal)
    }

    // Block 210A (upper straight) - continues straight path
    if (currentBlock == '210A' && isEastbound) return '212';
    if (currentBlock == '210A' && !isEastbound) return '210';

    // Block 211A (lower straight) - continues straight path
    if (currentBlock == '211A' && isEastbound) return '213';
    if (currentBlock == '211A' && !isEastbound) return '211';

    // Left crossover traversal - determine exit based on entry point
    // When on crossover_211_212, check previous position to determine route
    if (currentBlock == 'crossover_211_212' && isEastbound) {
      // From 210 (upper) → 213 (lower), or from 211 (lower) → 212 (upper)
      // Need to check which point triggered entry - use point positions
      final point76A = points.firstWhere((p) => p.id == '76A');
      final point77B = points.firstWhere((p) => p.id == '77B');
      if (point76A.position == PointPosition.reverse) {
        return '213'; // Upper to lower crossover
      }
      if (point77B.position == PointPosition.reverse) {
        return '212'; // Lower to upper crossover
      }
      return '212'; // Default to upper exit
    }

    if (currentBlock == 'crossover_211_212' && !isEastbound) {
      // From 212 (upper) → 211 (lower), or from 213 (lower) → 210 (upper)
      final point77A = points.firstWhere((p) => p.id == '77A');
      final point76B = points.firstWhere((p) => p.id == '76B');
      if (point77A.position == PointPosition.reverse) {
        return '211'; // Upper to lower crossover
      }
      if (point76B.position == PointPosition.reverse) {
        return '210'; // Lower to upper crossover
      }
      return '210'; // Default to upper exit
    }

    // ───────────────────────────────────────────────────────────────────────────
    // MIDDLE CROSSOVER (Central Station) - Points 78A/78B
    // ───────────────────────────────────────────────────────────────────────────

    // Block 102 (upper) eastbound approaching point 78A at x=400
    if (currentBlock == '102' && isEastbound) {
      final point78A = points.firstWhere((p) => p.id == '78A');
      if (point78A.position == PointPosition.reverse) {
        return 'crossover106'; // Diverge to crossover (upper to lower)
      }
      return '104'; // Straight through (78A normal)
    }

    // Block 107 (lower) westbound approaching point 78B at x=600
    if (currentBlock == '107' && !isEastbound) {
      final point78B = points.firstWhere((p) => p.id == '78B');
      if (point78B.position == PointPosition.reverse) {
        return 'crossover109'; // Diverge to crossover (lower to upper)
      }
      return '105'; // Straight through (78B normal)
    }

    // Middle crossover traversal (committed path)
    if (currentBlock == 'crossover106' && isEastbound) {
      return 'crossover109';
    }

    if (currentBlock == 'crossover109' && isEastbound) {
      return '107';
    }

    if (currentBlock == 'crossover109' && !isEastbound) {
      return 'crossover106';
    }

    if (currentBlock == 'crossover106' && !isEastbound) {
      return '102';
    }

    // ───────────────────────────────────────────────────────────────────────────
    // RIGHT CROSSOVER (East Terminal) - Points 79A/79B/80A/80B
    // ───────────────────────────────────────────────────────────────────────────

    // Block 302 (upper) eastbound approaching point 79A at x=1900
    if (currentBlock == '302' && isEastbound) {
      final point79A = points.firstWhere((p) => p.id == '79A');
      if (point79A.position == PointPosition.reverse) {
        return 'crossover_303_304'; // Diverge to crossover (upper to lower)
      }
      return '304'; // Straight through (79A normal)
    }

    // Block 303 (lower) eastbound approaching point 80B at x=1900
    if (currentBlock == '303' && isEastbound) {
      final point80B = points.firstWhere((p) => p.id == '80B');
      if (point80B.position == PointPosition.reverse) {
        return 'crossover_303_304'; // Diverge to crossover (lower to upper)
      }
      return '305'; // Straight through (80B normal)
    }

    // Block 304 (upper) westbound approaching point 80A at x=2050
    if (currentBlock == '304' && !isEastbound) {
      final point80A = points.firstWhere((p) => p.id == '80A');
      if (point80A.position == PointPosition.reverse) {
        return 'crossover_303_304'; // Diverge to crossover (upper to lower)
      }
      return '302'; // Straight through (80A normal)
    }

    // Block 305 (lower) westbound approaching point 79B at x=2050
    if (currentBlock == '305' && !isEastbound) {
      final point79B = points.firstWhere((p) => p.id == '79B');
      if (point79B.position == PointPosition.reverse) {
        return 'crossover_303_304'; // Diverge to crossover (lower to upper)
      }
      return '303'; // Straight through (79B normal)
    }

    // Right crossover traversal - determine exit based on entry point
    if (currentBlock == 'crossover_303_304' && isEastbound) {
      final point79A = points.firstWhere((p) => p.id == '79A');
      final point80B = points.firstWhere((p) => p.id == '80B');
      if (point79A.position == PointPosition.reverse) {
        return '305'; // Upper to lower crossover
      }
      if (point80B.position == PointPosition.reverse) {
        return '304'; // Lower to upper crossover
      }
      return '304'; // Default to upper exit
    }

    if (currentBlock == 'crossover_303_304' && !isEastbound) {
      final point80A = points.firstWhere((p) => p.id == '80A');
      final point79B = points.firstWhere((p) => p.id == '79B');
      if (point80A.position == PointPosition.reverse) {
        return '303'; // Upper to lower crossover
      }
      if (point79B.position == PointPosition.reverse) {
        return '302'; // Lower to upper crossover
      }
      return '302'; // Default to upper exit
    }

    // Default: use block topology for all other cases
    return isEastbound ? block.nextBlock : block.prevBlock;
  }

  bool canCreateNewTrain() {
    const blocksToCheck = ['100', '102', '104'];
    return !blocksToCheck.any((blockId) => isBlockOccupied(blockId));
  }

  /// Get effective speed considering track path restrictions
  double _getEffectiveSpeed(Train train) {
    final trackPath = trackGeometry.getPath(train.currentBlock);
    if (trackPath == null) {
      // No path defined, use train's nominal speed
      return train.speed;
    }

    // Get speed limit at current chainage
    final speedLimit = trackPath.getSpeedLimitAtChainage(train.chainage);

    // Return the minimum of train speed and track speed limit
    if (speedLimit.isInfinite) {
      return train.speed;
    }
    return min(train.speed, speedLimit);
  }

  void updateAllTrainPositions() {
    // First, calculate movement authorities for all CBTC trains
    _updateMovementAuthorities();

    for (final train in trains) {
      if (train.status == TrainStatus.moving) {
        // EMERGENCY STOP: Check for obstacles for AUTO and PM mode CBTC trains
        if (train.isCbtcEquipped &&
            (train.cbtcMode == CbtcMode.auto || train.cbtcMode == CbtcMode.pm)) {
          final obstacle = checkObstacleAhead(train);
          if (obstacle != null) {
            train.status = TrainStatus.stopped;
            train.stopReason = 'EMERGENCY STOP: $obstacle';
            _addEvent('${train.name} (VIN: ${train.vin}) EMERGENCY STOP - $obstacle');
            notifyListeners();
            continue;
          }

          // Check VCC1 constraints
          if (!canVcc1AllowMovement(train.id)) {
            train.status = TrainStatus.waiting;
            // stopReason is set in canVcc1AllowMovement
            notifyListeners();
            continue;
          } else {
            // Clear stop reason if VCC1 allows movement
            if (train.stopReason.startsWith('VCC1:')) {
              train.stopReason = '';
              train.status = TrainStatus.moving;
            }
          }
        }

        // Calculate speed multiplier - RM mode trains move 20% slower
        double speedMultiplier = 1.0;
        if (train.isCbtcEquipped && train.cbtcMode == CbtcMode.rm) {
          speedMultiplier = 0.8; // 20% slower
        }

        // NEW: Enforce speed restrictions based on track path geometry
        final effectiveSpeed = _getEffectiveSpeed(train) * speedMultiplier;

        final newProgress = train.progress + (0.005 * effectiveSpeed);
        if (newProgress >= 1.0) {
          moveTrainToNextBlock(train.id);
        } else {
          updateTrainProgress(train.id, newProgress);
        }

        // Check and release point reservations if train has passed
        if (train.isCbtcEquipped && (train.cbtcMode == CbtcMode.auto || train.cbtcMode == CbtcMode.pm)) {
          _checkAndReleasePointReservations(train);
        }
      } else if (train.status == TrainStatus.stopped) {
        // Check if obstacle is cleared for stopped CBTC trains
        if (train.isCbtcEquipped &&
            (train.cbtcMode == CbtcMode.auto || train.cbtcMode == CbtcMode.pm) &&
            train.stopReason.startsWith('EMERGENCY STOP:')) {
          final obstacle = checkObstacleAhead(train);
          if (obstacle == null) {
            train.status = TrainStatus.moving;
            train.stopReason = '';
            _addEvent('${train.name} (VIN: ${train.vin}) resuming - obstacle cleared');
            notifyListeners();
          }
        }
      }
    }
  }

  // Calculate movement authority (green arrow visualization) for all CBTC trains
  void _updateMovementAuthorities() {
    for (final train in trains) {
      // Only calculate for CBTC trains in AUTO, PM, or RM modes
      if (!train.isCbtcEquipped ||
          (train.cbtcMode != CbtcMode.auto &&
           train.cbtcMode != CbtcMode.pm &&
           train.cbtcMode != CbtcMode.rm)) {
        train.movementAuthority = null;
        continue;
      }

      // Calculate maximum distance for green arrow
      train.movementAuthority = _calculateMovementAuthority(train);
    }
  }

  MovementAuthority _calculateMovementAuthority(Train train) {
    double maxDistance = 2000.0; // Default max distance
    String? limitReason;
    bool hasDestination = train.smcDestination != null;

    final trainPos = train.x;
    final direction = train.direction;

    // If train has a destination, limit to destination position
    if (hasDestination && train.smcDestination != null) {
      final destinationPos = _getDestinationPosition(train.smcDestination!);
      if (destinationPos != null) {
        final distanceToDestination = (destinationPos - trainPos).abs();
        if (distanceToDestination < maxDistance) {
          maxDistance = distanceToDestination;
          limitReason = 'Destination: ${train.smcDestination}';
        }
      }
    }

    // Check for other CBTC trains ahead
    for (final otherTrain in trains) {
      if (otherTrain.id == train.id) continue;
      if (!otherTrain.isCbtcEquipped) continue;

      final otherPos = otherTrain.x;
      bool isAhead = false;
      double distance = 0;

      if (direction == Direction.east && otherPos > trainPos) {
        isAhead = true;
        distance = otherPos - trainPos;
      } else if (direction == Direction.west && otherPos < trainPos) {
        isAhead = true;
        distance = trainPos - otherPos;
      }

      if (isAhead) {
        // Stop 200 units before the other train
        final limitDistance = distance - 200;
        if (limitDistance > 0 && limitDistance < maxDistance) {
          maxDistance = limitDistance;
          limitReason = 'CBTC Train ahead';
        }
      }

      // Also check if we need to stop before another train's movement authority
      if (otherTrain.movementAuthority != null && isAhead) {
        final otherMaEnd = direction == Direction.east
            ? otherPos + otherTrain.movementAuthority!.maxDistance
            : otherPos - otherTrain.movementAuthority!.maxDistance;

        final distanceToOtherMa = direction == Direction.east
            ? otherMaEnd - trainPos
            : trainPos - otherMaEnd;

        if (distanceToOtherMa > 0) {
          final limitDistance = distanceToOtherMa - 200;
          if (limitDistance > 0 && limitDistance < maxDistance) {
            maxDistance = limitDistance;
            limitReason = 'Other train MA';
          }
        }
      }
    }

    // Check for closed tracks ahead
    for (final block in blocks) {
      if (!block.closedBySmc) continue;

      final blockStart = block.startX;
      final blockEnd = block.endX;
      bool isAhead = false;
      double distance = 0;

      if (direction == Direction.east && blockStart > trainPos) {
        isAhead = true;
        distance = blockStart - trainPos;
      } else if (direction == Direction.west && blockEnd < trainPos) {
        isAhead = true;
        distance = trainPos - blockEnd;
      }

      if (isAhead) {
        // Stop 200 units before closed track
        final limitDistance = distance - 200;
        if (limitDistance > 0 && limitDistance < maxDistance) {
          maxDistance = limitDistance;
          limitReason = 'Closed track AB ${block.id}';
        }
      }
    }

    // Check for occupied blocks ahead
    for (final block in blocks) {
      if (!block.occupied) continue;

      final blockStart = block.startX;
      final blockEnd = block.endX;
      bool isAhead = false;
      double distance = 0;

      if (direction == Direction.east && blockStart > trainPos) {
        isAhead = true;
        distance = blockStart - trainPos;
      } else if (direction == Direction.west && blockEnd < trainPos) {
        isAhead = true;
        distance = trainPos - blockEnd;
      }

      if (isAhead) {
        // Stop 200 units before occupied block
        final limitDistance = distance - 200;
        if (limitDistance > 0 && limitDistance < maxDistance) {
          maxDistance = limitDistance;
          limitReason = 'Occupied AB ${block.id}';
        }
      }
    }

    return MovementAuthority(
      maxDistance: maxDistance.clamp(0.0, 2000.0),
      limitReason: limitReason,
      hasDestination: hasDestination,
    );
  }

  double? _getDestinationPosition(String destination) {
    // Try to find a block with the destination ID
    try {
      final block = blocks.firstWhere((b) => b.id == destination);
      // Return the middle of the block
      return (block.startX + block.endX) / 2;
    } catch (e) {
      // Destination might be a platform name, try to map it
      if (destination == 'Platform1') {
        final block = blocks.firstWhere((b) => b.id == '111');
        return (block.startX + block.endX) / 2;
      } else if (destination == 'Platform2') {
        final block = blocks.firstWhere((b) => b.id == '110');
        return (block.startX + block.endX) / 2;
      }
    }
    return null;
  }

  Point? getPoint(String pointId) {
    try {
      return points.firstWhere((p) => p.id == pointId);
    } catch (e) {
      return null;
    }
  }

  Signal? getSignal(String signalId) {
    try {
      return signals.firstWhere((s) => s.id == signalId);
    } catch (e) {
      return null;
    }
  }

  void resetAll() {
    trains.clear();
    trainCounter = 0;
    _eventLog.clear();

    for (final block in blocks) {
      block.occupied = false;
    }

    for (final signal in signals) {
      signal.state = signal.id == 'C28' ? SignalState.green : SignalState.red;
      signal.route = null;
      signal.lastStateChangeReason = 'System reset';
    }

    for (final point in points) {
      point.position = PointPosition.normal;
      point.animationProgress = 0.0;
    }

    _addEvent('System RESET - All trains removed, signals cleared');
    notifyListeners();
  }

  List<String> getTrainRouteHistory(String trainId) {
    final train = trains.firstWhere((t) => t.id == trainId);
    return train.routeHistory;
  }

  void completeTrainJourney(String trainId) {
    final train = trains.firstWhere((t) => t.id == trainId);
    train.status = TrainStatus.completed;
    train.stopReason = 'Journey completed';
    _addEvent('${train.name} journey COMPLETED');
    markBlockOccupied(train.currentBlock, false);
    notifyListeners();

    Future.delayed(const Duration(seconds: 3), () {
      if (trains.any((t) => t.id == trainId)) {
        removeTrain(trainId);
      }
    });
  }

  void clearEventLog() {
    _eventLog.clear();
    _addEvent('Event log cleared');
    notifyListeners();
  }

  // VCC1 (Vehicle Control Computer) Methods
  String getVcc1SafetyStatus(String trainId) {
    if (!_cbtcModeActive) return '';

    final train = trains.firstWhere((t) => t.id == trainId);
    if (!train.isCbtcEquipped) return '';
    if (train.cbtcMode != CbtcMode.auto && train.cbtcMode != CbtcMode.pm) {
      return '';
    }

    // Check distance to other CBTC trains
    for (final otherTrain in trains) {
      if (otherTrain.id == train.id) continue;
      if (!otherTrain.isCbtcEquipped) continue;
      if (otherTrain.cbtcMode != CbtcMode.auto &&
          otherTrain.cbtcMode != CbtcMode.pm) continue;

      final distance = (train.x - otherTrain.x).abs();
      if (distance < 200) {
        return 'SAFETY: Too close to ${otherTrain.name} (${distance.toStringAsFixed(0)} units)';
      }
    }

    // Check distance to occupied blocks
    for (final block in blocks) {
      if (!block.occupied) continue;

      final blockStart = block.startX;
      final blockEnd = block.endX;
      final trainPos = train.x;

      double distanceToBlock;
      if (trainPos < blockStart) {
        distanceToBlock = blockStart - trainPos;
      } else if (trainPos > blockEnd) {
        distanceToBlock = trainPos - blockEnd;
      } else {
        // Train is in the block
        distanceToBlock = 0;
      }

      if (distanceToBlock < 200 && distanceToBlock > 0) {
        return 'SAFETY: Approaching occupied AB ${block.id} (${distanceToBlock.toStringAsFixed(0)} units)';
      }
    }

    return '';
  }

  List<String> getVcc1ActiveConstraints() {
    if (!_cbtcModeActive) return [];

    final constraints = <String>[];
    final cbtcTrains = trains.where((t) =>
      t.isCbtcEquipped &&
      (t.cbtcMode == CbtcMode.auto || t.cbtcMode == CbtcMode.pm)
    ).toList();

    // Check train-to-train constraints
    for (int i = 0; i < cbtcTrains.length; i++) {
      for (int j = i + 1; j < cbtcTrains.length; j++) {
        final train1 = cbtcTrains[i];
        final train2 = cbtcTrains[j];
        final distance = (train1.x - train2.x).abs();

        if (distance < 200) {
          constraints.add(
            'TRAIN SEPARATION: ${train1.name} ↔ ${train2.name} = ${distance.toStringAsFixed(0)} units'
          );
        }
      }
    }

    // Check block constraints
    for (final train in cbtcTrains) {
      for (final block in blocks) {
        if (!block.occupied) continue;

        final blockStart = block.startX;
        final blockEnd = block.endX;
        final trainPos = train.x;

        double distanceToBlock;
        if (trainPos < blockStart) {
          distanceToBlock = blockStart - trainPos;
        } else if (trainPos > blockEnd) {
          distanceToBlock = trainPos - blockEnd;
        } else {
          continue; // Train is in the block
        }

        if (distanceToBlock < 200) {
          constraints.add(
            'BLOCK PROTECTION: ${train.name} → AB ${block.id} = ${distanceToBlock.toStringAsFixed(0)} units'
          );
        }
      }
    }

    return constraints;
  }

  bool canVcc1AllowMovement(String trainId) {
    if (!_cbtcModeActive) return true;

    final train = trains.firstWhere((t) => t.id == trainId);
    if (!train.isCbtcEquipped) return true;
    if (train.cbtcMode != CbtcMode.auto && train.cbtcMode != CbtcMode.pm) {
      return true;
    }

    // Check distance to other CBTC trains in AUTO or PM mode
    for (final otherTrain in trains) {
      if (otherTrain.id == train.id) continue;
      if (!otherTrain.isCbtcEquipped) continue;
      if (otherTrain.cbtcMode != CbtcMode.auto &&
          otherTrain.cbtcMode != CbtcMode.pm) continue;

      final distance = (train.x - otherTrain.x).abs();
      if (distance < 200) {
        train.stopReason = 'VCC1: Safety distance violation - too close to ${otherTrain.name}';
        return false;
      }
    }

    // Check distance to occupied blocks ahead
    final direction = train.direction;
    for (final block in blocks) {
      if (!block.occupied) continue;

      final blockStart = block.startX;
      final blockEnd = block.endX;
      final trainPos = train.x;

      // Check if block is ahead of train
      bool blockAhead = false;
      if (direction == Direction.east && blockStart > trainPos) {
        blockAhead = true;
      } else if (direction == Direction.west && blockEnd < trainPos) {
        blockAhead = true;
      }

      if (!blockAhead) continue;

      double distanceToBlock;
      if (direction == Direction.east) {
        distanceToBlock = blockStart - trainPos;
      } else {
        distanceToBlock = trainPos - blockEnd;
      }

      if (distanceToBlock < 200) {
        train.stopReason = 'VCC1: Occupied block AB ${block.id} ahead - maintaining safety distance';
        return false;
      }
    }

    return true;
  }

  // SMC (System Management Centre) Methods
  void smcCloseTrack(String blockId) {
    try {
      final block = blocks.firstWhere((b) => b.id == blockId);
      if (block.closedBySmc) {
        _addEvent('SMC: Track $blockId is already closed');
        return;
      }
      block.closedBySmc = true;
      _addEvent('SMC: Track $blockId CLOSED');
      notifyListeners();
    } catch (e) {
      _addEvent('SMC ERROR: Track $blockId not found');
    }
  }

  void smcOpenTrack(String blockId) {
    try {
      final block = blocks.firstWhere((b) => b.id == blockId);
      if (!block.closedBySmc) {
        _addEvent('SMC: Track $blockId is already open');
        return;
      }
      block.closedBySmc = false;
      _addEvent('SMC: Track $blockId OPENED');
      notifyListeners();
    } catch (e) {
      _addEvent('SMC ERROR: Track $blockId not found');
    }
  }

  List<String> getClosedTracks() {
    return blocks.where((b) => b.closedBySmc).map((b) => b.id).toList();
  }

  // SMC Destination Management
  void smcSetDestination(String vin, String destination) {
    try {
      final train = trains.firstWhere((t) => t.vin == vin);
      if (!train.isCbtcEquipped) {
        _addEvent('SMC ERROR: Train ${train.name} is not CBTC equipped');
        return;
      }
      if (train.cbtcMode != CbtcMode.auto && train.cbtcMode != CbtcMode.pm) {
        _addEvent('SMC ERROR: Train must be in AUTO or PM mode');
        return;
      }

      train.smcDestination = destination;
      _addEvent('SMC: ${train.name} (VIN: $vin) destination set to $destination');

      // Reserve points if needed
      _reservePointsForTrain(train);

      notifyListeners();
    } catch (e) {
      _addEvent('SMC ERROR: Train with VIN $vin not found');
    }
  }

  void _reservePointsForTrain(Train train) {
    if (train.smcDestination == null) return;

    final requiredPointPositions = _getRequiredPointPositions(train.currentBlock, train.smcDestination!);

    for (final pointConfig in requiredPointPositions) {
      final pointId = pointConfig['pointId'] as String;
      final requiredPosition = pointConfig['position'] as PointPosition;

      try {
        final point = points.firstWhere((p) => p.id == pointId);

        // Check if point is already reserved by another train
        if (point.reservedByVin != null && point.reservedByVin != train.vin) {
          _addEvent('Point $pointId already reserved by ${point.reservedByVin}');
          continue;
        }

        // Reserve the point
        point.reservedByVin = train.vin;
        point.reservedDestination = train.smcDestination;

        // Move point to required position
        if (point.position != requiredPosition) {
          setPointPosition(pointId, requiredPosition);
          _addEvent('Point $pointId reserved and moved for ${train.vin} → ${train.smcDestination}');
        } else {
          _addEvent('Point $pointId reserved for ${train.vin} → ${train.smcDestination}');
        }
      } catch (e) {
        // Point not found or error
      }
    }
  }

  List<Map<String, dynamic>> _getRequiredPointPositions(String fromBlock, String toBlock) {
    // Define routing logic for point positions based on destination
    final List<Map<String, dynamic>> requiredPoints = [];

    // Platform 1 routing (blocks 110-112)
    if (toBlock == '110' || toBlock == '111' || toBlock == '112' || toBlock == 'Platform1') {
      requiredPoints.add({'pointId': '78A', 'position': PointPosition.normal});
      requiredPoints.add({'pointId': '78B', 'position': PointPosition.normal});
    }

    // Platform 2 Bay routing (blocks 109-111 on lower track)
    if (toBlock == '109' || toBlock == 'Platform2') {
      requiredPoints.add({'pointId': '78A', 'position': PointPosition.reverse});
      requiredPoints.add({'pointId': '78B', 'position': PointPosition.reverse});
    }

    // Blocks 102-104 (bypass platform)
    if (toBlock == '102' || toBlock == '103' || toBlock == '104') {
      requiredPoints.add({'pointId': '78A', 'position': PointPosition.normal});
    }

    // Crossover routing
    if (toBlock == 'crossover106' || toBlock == 'crossover109') {
      requiredPoints.add({'pointId': '78A', 'position': PointPosition.reverse});
    }

    return requiredPoints;
  }

  void _releasePointReservation(Train train, String pointId) {
    try {
      final point = points.firstWhere((p) => p.id == pointId);
      if (point.reservedByVin == train.vin) {
        point.reservedByVin = null;
        point.reservedDestination = null;
        _addEvent('Point $pointId reservation released by ${train.vin}');

        // Auto-normalize if no reservation requires reverse
        _autoNormalizePoint(pointId);
      }
    } catch (e) {
      // Point not found
    }
  }

  void _autoNormalizePoint(String pointId) {
    try {
      final point = points.firstWhere((p) => p.id == pointId);

      // Don't normalize if there's an active reservation
      if (point.reservedByVin != null) return;

      // Check if any train needs this point in reverse
      bool anyTrainNeedsReverse = false;
      for (final train in trains) {
        if (!train.isCbtcEquipped) continue;
        if (train.cbtcMode != CbtcMode.auto && train.cbtcMode != CbtcMode.pm) continue;
        if (train.smcDestination == null) continue;

        final requiredPositions = _getRequiredPointPositions(train.currentBlock, train.smcDestination!);
        for (final config in requiredPositions) {
          if (config['pointId'] == pointId && config['position'] == PointPosition.reverse) {
            anyTrainNeedsReverse = true;
            break;
          }
        }
      }

      // Normalize to normal position if no train needs reverse
      if (!anyTrainNeedsReverse && point.position == PointPosition.reverse) {
        setPointPosition(pointId, PointPosition.normal);
        _addEvent('Point $pointId auto-normalized to NORMAL');
      }
    } catch (e) {
      // Point not found
    }
  }

  // Check if train has passed over a point and release reservation
  void _checkAndReleasePointReservations(Train train) {
    for (final point in points) {
      if (point.reservedByVin == train.vin) {
        // Check if train has passed the point
        final pointX = point.x;
        final trainX = train.x;

        // If train is moving east and is past the point, or west and before the point
        bool hasPassed = false;
        if (train.direction == Direction.east && trainX > pointX + 50) {
          hasPassed = true;
        } else if (train.direction == Direction.west && trainX < pointX - 50) {
          hasPassed = true;
        }

        if (hasPassed) {
          _releasePointReservation(train, point.id);
        }
      }
    }
  }

  // Check if there's an obstacle within 200 units ahead of train
  String? checkObstacleAhead(Train train) {
    if (!train.isCbtcEquipped) return null;
    if (train.cbtcMode != CbtcMode.auto && train.cbtcMode != CbtcMode.pm) {
      return null;
    }

    final trainPos = train.x;
    final direction = train.direction;

    // Check for other CBTC trains
    for (final otherTrain in trains) {
      if (otherTrain.id == train.id) continue;
      if (!otherTrain.isCbtcEquipped) continue;

      final otherPos = otherTrain.x;
      bool isAhead = false;
      double distance = 0;

      if (direction == Direction.east && otherPos > trainPos) {
        isAhead = true;
        distance = otherPos - trainPos;
      } else if (direction == Direction.west && otherPos < trainPos) {
        isAhead = true;
        distance = trainPos - otherPos;
      }

      if (isAhead && distance < 200) {
        return 'OBSTACLE: CBTC Train ${otherTrain.vin} ahead (${distance.toStringAsFixed(0)} units)';
      }
    }

    // Check for closed tracks
    for (final block in blocks) {
      if (!block.closedBySmc) continue;

      final blockStart = block.startX;
      final blockEnd = block.endX;
      bool isAhead = false;
      double distance = 0;

      if (direction == Direction.east && blockStart > trainPos) {
        isAhead = true;
        distance = blockStart - trainPos;
      } else if (direction == Direction.west && blockEnd < trainPos) {
        isAhead = true;
        distance = trainPos - blockEnd;
      } else if (trainPos >= blockStart && trainPos <= blockEnd) {
        // Train is already on closed track
        return 'OBSTACLE: On closed track AB ${block.id}';
      }

      if (isAhead && distance < 200) {
        return 'OBSTACLE: Closed track AB ${block.id} ahead (${distance.toStringAsFixed(0)} units)';
      }
    }

    // Check for occupied blocks
    for (final block in blocks) {
      if (!block.occupied) continue;

      final blockStart = block.startX;
      final blockEnd = block.endX;
      bool isAhead = false;
      double distance = 0;

      if (direction == Direction.east && blockStart > trainPos) {
        isAhead = true;
        distance = blockStart - trainPos;
      } else if (direction == Direction.west && blockEnd < trainPos) {
        isAhead = true;
        distance = trainPos - blockEnd;
      }

      if (isAhead && distance < 200) {
        return 'OBSTACLE: Occupied AB ${block.id} ahead (${distance.toStringAsFixed(0)} units)';
      }
    }

    return null;
  }

  // CBTC Methods
  void toggleCbtcDevices(bool enabled) {
    _cbtcDevicesEnabled = enabled;
    if (enabled) {
      _initializeCbtcDevices();
      _addEvent('CBTC devices ENABLED');
    } else {
      _transponders.clear();
      _wifiAntennas.clear();
      _cbtcModeActive = false;
      _addEvent('CBTC devices DISABLED');
      // Restore normal signal colors if CBTC mode was active
      _restoreNormalSignalColors();
    }
    notifyListeners();
  }

  void _initializeCbtcDevices() {
    _transponders.clear();
    _wifiAntennas.clear();

    // Upper track transponders (evenly spread across track from 0 to 1600)
    final upperY = 100.0;
    final upperTrackLength = 1600.0;
    final upperSpacing = upperTrackLength / 5; // 5 sections for 4 transponders + padding

    _transponders.add(Transponder(
      id: 'upper_t1_1',
      type: TransponderType.t1,
      x: upperSpacing * 1,
      y: upperY,
      description: 'Crossover Tag',
    ));
    _transponders.add(Transponder(
      id: 'upper_t1_2',
      type: TransponderType.t1,
      x: upperSpacing * 2,
      y: upperY,
      description: 'Crossover Tag',
    ));
    _transponders.add(Transponder(
      id: 'upper_t2',
      type: TransponderType.t2,
      x: upperSpacing * 3,
      y: upperY,
      description: 'Cross Border Tag',
    ));
    _transponders.add(Transponder(
      id: 'upper_t3',
      type: TransponderType.t3,
      x: upperSpacing * 4,
      y: upperY,
      description: 'Border Tag',
    ));

    // Lower track transponders (evenly spread)
    final lowerY = 300.0;
    final lowerTrackLength = 1200.0;
    final lowerSpacing = lowerTrackLength / 5;

    _transponders.add(Transponder(
      id: 'lower_t1_1',
      type: TransponderType.t1,
      x: lowerSpacing * 1,
      y: lowerY,
      description: 'Crossover Tag',
    ));
    _transponders.add(Transponder(
      id: 'lower_t1_2',
      type: TransponderType.t1,
      x: lowerSpacing * 2,
      y: lowerY,
      description: 'Crossover Tag',
    ));
    _transponders.add(Transponder(
      id: 'lower_t2',
      type: TransponderType.t2,
      x: lowerSpacing * 3,
      y: lowerY,
      description: 'Cross Border Tag',
    ));
    _transponders.add(Transponder(
      id: 'lower_t3',
      type: TransponderType.t3,
      x: lowerSpacing * 4,
      y: lowerY,
      description: 'Border Tag',
    ));

    // T6 tags at platform departure ends
    // Platform 1 (upper track, blocks 110-112) - departure end at block 112
    _transponders.add(Transponder(
      id: 'platform1_t6',
      type: TransponderType.t6,
      x: 1200.0, // End of block 112
      y: upperY,
      description: 'Accurate Stopping Tag - Platform 1',
    ));

    // Platform 2 Bay (lower track, blocks 109-111) - departure end at block 111
    _transponders.add(Transponder(
      id: 'platform2_t6',
      type: TransponderType.t6,
      x: 1100.0, // End of block 111
      y: lowerY,
      description: 'Accurate Stopping Tag - Platform 2',
    ));

    // WiFi Antennas - Upper track (3 antennas evenly spread)
    final upperAntennaSpacing = upperTrackLength / 4;
    for (int i = 1; i <= 3; i++) {
      _wifiAntennas.add(WifiAntenna(
        id: 'upper_wifi_$i',
        x: upperAntennaSpacing * i,
        y: upperY - 40, // Position above the track
      ));
    }

    // WiFi Antennas - Lower track (3 antennas evenly spread)
    final lowerAntennaSpacing = lowerTrackLength / 4;
    for (int i = 1; i <= 3; i++) {
      _wifiAntennas.add(WifiAntenna(
        id: 'lower_wifi_$i',
        x: lowerAntennaSpacing * i,
        y: lowerY + 40, // Position below the track
      ));
    }
  }

  void toggleCbtcMode(bool active) {
    if (!_cbtcDevicesEnabled) {
      _addEvent('Cannot activate CBTC mode: CBTC devices not enabled');
      return;
    }

    _cbtcModeActive = active;
    if (active) {
      _addEvent('CBTC mode ACTIVATED - Moving block system enabled');
      _setAllSignalsBlue();
    } else {
      _addEvent('CBTC mode DEACTIVATED - Fixed block system restored');
      _restoreNormalSignalColors();
    }
    notifyListeners();
  }

  void _setAllSignalsBlue() {
    for (final signal in signals) {
      signal.state = SignalState.blue;
      signal.lastStateChangeReason = 'CBTC moving block mode active';
    }
  }

  void _restoreNormalSignalColors() {
    // Restore signals to their proper states based on point positions and block occupancy
    for (final signal in signals) {
      signal.state = signal.id == 'C28' ? SignalState.green : SignalState.red;
      signal.lastStateChangeReason = 'CBTC mode deactivated';
    }
    _updateSignalsBasedOnPoints();
  }
}
