import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rail_champ/screens/collision_analysis_system.dart';
import 'package:rail_champ/screens/terminal_station_models.dart'
    hide CollisionIncident;
import 'package:rail_champ/models/railway_model.dart' show WifiAntenna, Transponder, TransponderType;  // FIXED: Only import WiFi/Transponder types
import 'dart:async';
import 'dart:math' as math;

// ============================================================================
// AXLE COUNTER MODEL
// ============================================================================
class AxleCounter {
  final String id;
  final String blockId;
  final double x;
  final double y;
  int count;
  DateTime? lastDetectionTime;
  bool d1Active;
  bool d2Active;
  String lastDirection;
  final bool isTwin;
  final String? twinLabel;
  String? lastTrainDetected;
  DateTime? lastTrainDetectionTime;

  AxleCounter({
    required this.id,
    required this.blockId,
    required this.x,
    required this.y,
    this.count = 0,
    this.lastDetectionTime,
    this.d1Active = false,
    this.d2Active = false,
    this.lastDirection = '',
    this.isTwin = false,
    this.twinLabel,
    this.lastTrainDetected,
    this.lastTrainDetectionTime,
  });
}

// ============================================================================
// AXLE COUNTER CALCULATION METHOD ENUMS
// ============================================================================

enum AB109CalculationMethod {
  simple,
  flowBalance,
  exitTracking,
  fullJunction,
  conservative,
}

enum AB104CalculationMethod {
  simple,
  flowBalance,
  exitTracking,
  fullJunction,
  conservative,
}

// ============================================================================
// AXLE COUNTER EVALUATOR (ACE) - LARGE IMBALANCE ALLOWANCE VERSION
// ============================================================================
class AxleCounterEvaluator {
  final Map<String, AxleCounter> axleCounters;
  final Map<String, int> abResults;

  // Track bidirectional movement states
  final Map<String, int> _lastCounterValues = {};
  final Map<String, bool> _sectionOccupancyStates = {};

  // Maximum allowed imbalance before reset
  static const int MAX_IMBALANCE = 511;

  AxleCounterEvaluator(this.axleCounters) : abResults = {};

  // BIDIRECTIONAL MOVEMENT HANDLING METHOD
  void updateABOccupations() {
    abResults.clear();

    // Get all counter values
    final ac100 = axleCounters['ac100']?.count ?? 0;
    final ac104 = axleCounters['ac104']?.count ?? 0;
    final ac108 = axleCounters['ac108']?.count ?? 0;
    final ac112 = axleCounters['ac112']?.count ?? 0;
    final ac101 = axleCounters['ac101']?.count ?? 0;
    final ac105 = axleCounters['ac105']?.count ?? 0;
    final ac106 = axleCounters['ac106']?.count ?? 0;
    final ac107 = axleCounters['ac107']?.count ?? 0;
    final ac109 = axleCounters['ac109']?.count ?? 0;
    final ac111 = axleCounters['ac111']?.count ?? 0;

    // Update AB sections with bidirectional handling
    abResults['AB100'] = _calculateBidirectionalSection('AB100', ac100, ac104);
    abResults['AB100'] = _calculateBidirectionalSection('AB100', ac104, ac100);
    abResults['AB105'] = _calculateBidirectionalSection('AB105', ac105, ac101);
    abResults['AB105'] = _calculateBidirectionalSection('AB105', ac101, ac105);
    abResults['AB106'] = _calculateBidirectionalSection('AB106', ac106, ac107);
    abResults['AB106'] = _calculateBidirectionalSection('AB106', ac107, ac106);
    abResults['AB108'] = _calculateBidirectionalSection('AB108', ac108, ac112);
    abResults['AB108'] = _calculateBidirectionalSection('AB108', ac112, ac108);
    abResults['AB111'] = _calculateBidirectionalSection('AB111', ac109, ac111);
    abResults['AB111'] = _calculateBidirectionalSection('AB111', ac111, ac109);

    // Remove AB104 and AB109 from results
    abResults.remove('AB104');
    abResults.remove('AB109');

    // SIMPLE LOGIC FOR AB111 - Only track ac109 for entry/exit
    abResults['AB111'] = _calculateAB111Simple(ac109);

    print(
        '🔢 ACE Results: ${abResults.entries.map((e) => '${e.key}=${e.value}').join(', ')}');
  }

// ULTRA-SIMPLE AB111 CALCULATION - Only track ac109
  int _calculateAB111Simple(int ac109) {
    // Initialize tracking
    final result = ac109 % 2 == 1 ? 1 : 0;

    if (result == 1) {
      print('🚂 AB111: OCCUPIED (ac109:$ac109 is ODD)');
    } else {
      print('🚂 AB111: CLEAR (ac109:$ac109 is EVEN)');
    }

    return result;
  }

// Add these instance variables to the AxleCounterEvaluator class:
  int? _lastAC109Count;
  int _ab111EntryCount = 0;

  // BIDIRECTIONAL SECTION CALCULATION
  int _calculateBidirectionalSection(
      String sectionId, int entryCounter, int exitCounter) {
    final difference = (entryCounter - exitCounter).abs();

    // Check if we need to reset due to exceeding maximum imbalance
    if (difference > MAX_IMBALANCE) {
      _resetCountersForSection(sectionId);
      print(
          '🔄 $sectionId COUNTERS RESET: Exceeded maximum imbalance of $MAX_IMBALANCE');
      return 0;
    }

    // Initialize last values if not present
    _lastCounterValues['${sectionId}_entry'] ??= entryCounter;
    _lastCounterValues['${sectionId}_exit'] ??= exitCounter;
    _sectionOccupancyStates[sectionId] ??= false;

    final lastEntry = _lastCounterValues['${sectionId}_entry']!;
    final lastExit = _lastCounterValues['${sectionId}_exit']!;

    bool entryIncreased = entryCounter > lastEntry;
    bool exitIncreased = exitCounter > lastExit;
    bool entryDecreased = entryCounter < lastEntry;
    bool exitDecreased = exitCounter < lastExit;

    bool currentOccupancy = _sectionOccupancyStates[sectionId]!;

    if (exitCounter > entryCounter) {
      // This indicates bidirectional movement through the exit counter
      // Train entered via exit counter, so section should be occupied
      // until the counts equalize again
      print('🔄 $sectionId: Bidirectional movement detected via exit counter');
      return 1;
    }

    // Normal case: section occupied if entry counter ahead of exit counter
    final result = entryCounter > exitCounter ? 1 : 0;

    // Debug output to understand the logic
    if (result == 1) {
      print(
          '📊 $sectionId: OCCUPIED (entry:$entryCounter > exit:$exitCounter)');
    } else {
      print('📊 $sectionId: CLEAR (entry:$entryCounter == exit:$exitCounter)');
    }

    // State machine for bidirectional movement
    if (currentOccupancy) {
      // Section is currently occupied
      if (exitIncreased) {
        // Train exited the section
        currentOccupancy = false;
        print('🚂 $sectionId: Train EXITED via exit counter');
      } else if (entryDecreased && entryCounter == exitCounter) {
        // Train exited via entry counter (bidirectional movement)
        currentOccupancy = false;
        print('🚂 $sectionId: Train EXITED via entry counter (bidirectional)');
      }
    } else {
      // Section is currently unoccupied
      if (entryIncreased) {
        // Train entered the section
        currentOccupancy = true;
        print('🚂 $sectionId: Train ENTERED via entry counter');
      } else if (exitDecreased && exitCounter < entryCounter) {
        // Train entered via exit counter (bidirectional movement)
        currentOccupancy = true;
        print('🚂 $sectionId: Train ENTERED via exit counter (bidirectional)');
      }
    }

    // Update state
    _sectionOccupancyStates[sectionId] = currentOccupancy;
    _lastCounterValues['${sectionId}_entry'] = entryCounter;
    _lastCounterValues['${sectionId}_exit'] = exitCounter;

    return currentOccupancy ? 1 : 0;
  }

  String? findNearestAxleCounter(double trainX, double trainY) {
    String? nearestCounter;
    double minDistance = 50.0; // Increased detection range

    for (final counter in axleCounters.values) {
      final distance = math.sqrt(
          math.pow(trainX - counter.x, 2) + math.pow(trainY - counter.y, 2));
      if (distance < minDistance) {
        minDistance = distance;
        nearestCounter = counter.id;
      }
    }

    // Debug output
    if (nearestCounter != null) {
      final counter = axleCounters[nearestCounter]!;
      final actualDistance = math.sqrt(
          math.pow(trainX - counter.x, 2) + math.pow(trainY - counter.y, 2));
      print(
          '🔍 Train at ($trainX, $trainY) detected by $nearestCounter (distance: ${actualDistance.toStringAsFixed(1)})');
    }

    return nearestCounter;
  }

  // Reset counters when imbalance exceeds maximum
  void _resetCountersForSection(String sectionId) {
    switch (sectionId) {
      case 'AB100':
        axleCounters['ac100']?.count = 0;
        axleCounters['ac104']?.count = 0;
        break;
      case 'AB105':
        axleCounters['ac101']?.count = 0;
        axleCounters['ac105']?.count = 0;
        break;
      case 'AB106':
        axleCounters['ac106']?.count = 0;
        axleCounters['ac107']?.count = 0;
        break;
      case 'AB108':
        axleCounters['ac108']?.count = 0;
        axleCounters['ac112']?.count = 0;
        break;
      case 'AB111':
        axleCounters['ac109']?.count = 0;
        axleCounters['ac111']?.count = 0;
        _lastAC109Count = 0;
        _ab111EntryCount = 0;
        break;
    }
  }

  // Global reset method
  void resetAllCounters() {
    for (var counter in axleCounters.values) {
      counter.count = 0;
    }
    _lastCounterValues.clear();
    _sectionOccupancyStates.clear();
    print('🔄 ALL AXLE COUNTERS RESET TO ZERO');
  }

  // Check if any section is approaching the maximum imbalance
  Map<String, dynamic> getImbalanceStatus() {
    final ac100 = axleCounters['ac100']?.count ?? 0;
    final ac104 = axleCounters['ac104']?.count ?? 0;
    final ac101 = axleCounters['ac101']?.count ?? 0;
    final ac105 = axleCounters['ac105']?.count ?? 0;
    final ac106 = axleCounters['ac106']?.count ?? 0;
    final ac107 = axleCounters['ac107']?.count ?? 0;
    final ac108 = axleCounters['ac108']?.count ?? 0;
    final ac112 = axleCounters['ac112']?.count ?? 0;
    final ac109 = axleCounters['ac109']?.count ?? 0;
    final ac111 = axleCounters['ac111']?.count ?? 0;

    return {
      'AB100': {
        'counters': [ac100, ac104],
        'difference': (ac100 - ac104).abs(),
        'max_imbalance': MAX_IMBALANCE,
        'remaining': MAX_IMBALANCE - (ac100 - ac104).abs(),
        'percentage':
            (((ac100 - ac104).abs() / MAX_IMBALANCE) * 100).toStringAsFixed(1) +
                '%',
        'needs_reset': (ac100 - ac104).abs() > MAX_IMBALANCE,
      },
      'AB105': {
        'counters': [ac101, ac105],
        'difference': (ac101 - ac105).abs(),
        'max_imbalance': MAX_IMBALANCE,
        'remaining': MAX_IMBALANCE - (ac101 - ac105).abs(),
        'percentage':
            (((ac101 - ac105).abs() / MAX_IMBALANCE) * 100).toStringAsFixed(1) +
                '%',
        'needs_reset': (ac101 - ac105).abs() > MAX_IMBALANCE,
      },
      'AB106': {
        'counters': [ac106, ac107],
        'difference': (ac106 - ac107).abs(),
        'max_imbalance': MAX_IMBALANCE,
        'remaining': MAX_IMBALANCE - (ac106 - ac107).abs(),
        'percentage':
            (((ac106 - ac107).abs() / MAX_IMBALANCE) * 100).toStringAsFixed(1) +
                '%',
        'needs_reset': (ac106 - ac107).abs() > MAX_IMBALANCE,
      },
      'AB108': {
        'counters': [ac108, ac112],
        'difference': (ac108 - ac112).abs(),
        'max_imbalance': MAX_IMBALANCE,
        'remaining': MAX_IMBALANCE - (ac108 - ac112).abs(),
        'percentage':
            (((ac108 - ac112).abs() / MAX_IMBALANCE) * 100).toStringAsFixed(1) +
                '%',
        'needs_reset': (ac108 - ac112).abs() > MAX_IMBALANCE,
      },
      'AB111': {
        'counters': [ac109, ac111],
        'difference': (ac109 - ac111).abs(),
        'max_imbalance': MAX_IMBALANCE,
        'remaining': MAX_IMBALANCE - (ac109 - ac111).abs(),
        'percentage':
            (((ac109 - ac111).abs() / MAX_IMBALANCE) * 100).toStringAsFixed(1) +
                '%',
        'needs_reset': (ac109 - ac111).abs() > MAX_IMBALANCE,
      },
    };
  }

  // Enhanced axle counter update with bidirectional tracking and wheel count
  void updateAxleCounter(String counterId, int direction, bool isEntering, {int wheelCount = 2}) {
    final counter = axleCounters[counterId];
    if (counter == null) return;

    final oldCount = counter.count;

    if (isEntering) {
      counter.count += wheelCount;
      counter.lastDirection = direction > 0 ? 'Eastbound' : 'Westbound';
      counter.lastDetectionTime = DateTime.now();
      print(
          '🚂 ENTRY: $counterId detected train entry ($wheelCount wheels) - Count: $oldCount → ${counter.count}');
    } else {
      counter.count = math.max(0, counter.count - wheelCount);
      counter.lastDirection = direction > 0 ? 'Eastbound' : 'Westbound';
      counter.lastDetectionTime = DateTime.now();
      print(
          '🚂 EXIT: $counterId detected train exit ($wheelCount wheels) - Count: $oldCount → ${counter.count}');
    }

    // Update AB occupations with bidirectional checking
    updateABOccupations();

    // Check imbalance status
    final imbalanceStatus = getImbalanceStatus();

    // Debug output with imbalance info
    for (var abId in ['AB100', 'AB105', 'AB106', 'AB108', 'AB111']) {
      final status = imbalanceStatus[abId]!;
      print(
          '📊 $abId: ${abResults[abId]} (Diff: ${status['difference']}/${MAX_IMBALANCE}) ${abResults[abId]! > 0 ? '🔴 OCCUPIED' : '🟢 CLEAR'}');
    }

    // Warn if approaching maximum imbalance
    for (var abId in ['AB100', 'AB105', 'AB106', 'AB108', 'AB111']) {
      final status = imbalanceStatus[abId]!;
      if (status['difference']! > MAX_IMBALANCE * 0.8) {
        print(
            '⚠️  $abId approaching maximum imbalance: ${status['difference']}/$MAX_IMBALANCE');
      }
    }
  }

  bool isABOccupied(String abId) {
    updateABOccupations();
    return abResults[abId] != null && abResults[abId]! > 0;
  }

  // Get the wheel count for a specific AB section
  int getABWheelCount(String abId) {
    updateABOccupations();
    return abResults[abId] ?? 0;
  }

  // Manual reset method for individual sections
  void resetSection(String sectionName) {
    _resetCountersForSection(sectionName);
    _sectionOccupancyStates[sectionName] = false;
    updateABOccupations();
    print('🔄 $sectionName counters manually reset');
  }

  // Individual AB reset methods
  void resetAB(String abId) {
    switch (abId) {
      case 'AB100':
        axleCounters['ac100']?.count = 0;
        axleCounters['ac104']?.count = 0;
        break;
      case 'AB105':
        axleCounters['ac101']?.count = 0;
        axleCounters['ac105']?.count = 0;
        break;
      case 'AB106':
        axleCounters['ac106']?.count = 0;
        axleCounters['ac107']?.count = 0;
        break;
      case 'AB108':
        axleCounters['ac108']?.count = 0;
        axleCounters['ac112']?.count = 0;
        break;
      case 'AB111':
        axleCounters['ac109']?.count = 0;
        axleCounters['ac111']?.count = 0;
        break;
    }
    _sectionOccupancyStates[abId] = false;
    abResults[abId] = 0;
  }

  void resetAll() {
    for (var counter in axleCounters.values) {
      counter.count = 0;
    }
    _lastCounterValues.clear();
    _sectionOccupancyStates.clear();
    abResults.clear();
  }

  // Alias method for compatibility
  void resetIndividualAB(String abId) {
    resetAB(abId);
  }
}

// ============================================================================
// TERMINAL STATION CONTROLLER - FIXED VERSION
// ============================================================================

class TerminalStationController extends ChangeNotifier {
  final List<Train> trains = [];
  final Map<String, BlockSection> blocks = {};
  final Map<String, Point> points = {};
  final Map<String, Signal> signals = {};
  final List<Platform> platforms = [];
  final Map<String, TrainStop> trainStops = {};
  final List<String> eventLog = [];

  // FIXED: Add CBTC infrastructure
  final Map<String, WifiAntenna> wifiAntennas = {};
  final Map<String, Transponder> transponders = {};
  final CollisionAnalysisSystem _collisionSystem = CollisionAnalysisSystem();
  final Map<String, bool> _pendingRouteCancellations = {};
  final Map<String, DateTime> _pendingCancellationTimers = {};
  ReleaseState releaseState = ReleaseState.inactive;
  DateTime? releaseStartTime;
  int releaseCountdown = 0;
  Timer? _cancellationTimer;
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();

  final Map<String, AxleCounter> axleCounters = {};
  late AxleCounterEvaluator ace;
  bool axleCountersVisible = true;
  bool signalsVisible = true;

  Duration _simulationRunningTime = Duration.zero;
  Timer? _simulationTimer;
  DateTime? _simulationStartTime;

  bool collisionAlarmActive = false;
  CollisionIncident? currentCollisionIncident;

  final Map<String, CollisionRecoveryPlan> _activeCollisionRecoveries = {};
  Timer? _recoveryProgressTimer;

  bool isRunning = false;
  double simulationSpeed = 1.0;
  int tickCount = 0;
  int nextTrainNumber = 1;
  bool trainStopsEnabled = true;

  final Map<String, RouteReservation> routeReservations = {};
  bool selfNormalizingPoints = true;

  // FIXED: CBTC system properties
  bool cbtcDevicesEnabled = false;
  bool cbtcModeActive = false;

  // Timetable system
  Timetable? timetable;
  Timer? _timetableTimer;
  bool timetableActive = false;
  final List<GhostTrain> ghostTrains = []; // Invisible scheduled trains for timetable
  bool showGhostTrains = false; // Visibility toggle for ghost trains (hidden by default)

  bool _spadAlarmActive = false;
  CollisionIncident? _currentSpadIncident;
  String? _spadTrainStopId;

  bool get spadAlarmActive => _spadAlarmActive;
  CollisionIncident? get currentSpadIncident => _currentSpadIncident;
  String? get spadTrainStopId => _spadTrainStopId;

  // ============================================================================
  // NEW FEATURES - Tooltip, Grid, Traction Current, AI Agent, Relay Rack
  // ============================================================================

  // Tooltip system
  Map<String, dynamic>? hoveredObject;
  bool tooltipsEnabled = true;

  // Grid system
  bool gridVisible = false;
  double gridSpacing = 100.0;

  // Traction current system - split into 3 sections
  bool tractionCurrentOn = true; // For backwards compatibility
  bool tractionWestOn = true;    // West section: x < -200
  bool tractionCentralOn = true; // Central section: -200 <= x <= 1800
  bool tractionEastOn = true;    // East section: x > 1800

  // Signalling System Manager (formerly AI Agent)
  bool signallingSystemManagerVisible = false;
  Offset signallingSystemManagerPosition = const Offset(50, 50);
  double signallingSystemManagerOpacity = 1.0;
  double signallingSystemManagerWidth = 175.0;
  double signallingSystemManagerHeight = 250.0;
  Color signallingSystemManagerColor = Colors.blue; // Customizable color
  int signallingSystemManagerDesignType = 0; // 0-3: Different design styles
  bool signallingSystemManagerCompactMode = false; // Compact view option
  bool signallingSystemManagerAutoScroll = true; // Auto-scroll chat

  // Legacy aliases for backward compatibility
  bool get aiAgentVisible => signallingSystemManagerVisible;
  set aiAgentVisible(bool value) => signallingSystemManagerVisible = value;
  Offset get aiAgentPosition => signallingSystemManagerPosition;
  set aiAgentPosition(Offset value) => signallingSystemManagerPosition = value;
  double get aiAgentOpacity => signallingSystemManagerOpacity;
  set aiAgentOpacity(double value) => signallingSystemManagerOpacity = value;
  double get aiAgentWidth => signallingSystemManagerWidth;
  set aiAgentWidth(double value) => signallingSystemManagerWidth = value;
  double get aiAgentHeight => signallingSystemManagerHeight;
  set aiAgentHeight(double value) => signallingSystemManagerHeight = value;

  // Camera controls for search and follow
  double cameraOffsetX = 0;
  double cameraOffsetY = 0;
  double cameraZoom = 0.8;
  String? followingTrainId; // ID of train being followed
  String? highlightedItemId; // ID of currently highlighted item
  String? highlightedItemType; // Type of highlighted item (train, signal, block, point)

  // Relay rack panel
  bool relayRackVisible = false;

  // Point machine state (for relay rack WKR status)
  Map<String, String> pointMachineStates = {}; // pointId -> 'normal', 'reverse', 'mid'
  Map<String, DateTime> pointThrowStartTimes = {}; // Track when points started moving

  // Block closing system - closed blocks emergency brake auto trains
  Map<String, bool> closedBlocks = {}; // blockId -> true if closed

  // Point reservation system - reserved points stay in position
  Map<String, PointPosition> reservedPoints = {}; // pointId -> reserved position

  bool _isTrainEnteringSection(String counterId, Train train) {
    // Simple logic based on train direction
    // Eastbound trains (direction > 0) are entering when moving right
    // Westbound trains (direction < 0) are entering when moving left
    if (train.y < 200) {
      // Upper track (Eastbound)
      return train.direction > 0;
    } else {
      // Lower track (Westbound)
      return train.direction < 0;
    }
  }

  Duration get simulationRunningTime => _simulationRunningTime;
  DateTime get currentTime => _currentTime;

  String getFormattedRunningTime() {
    final duration = _simulationRunningTime;
    final hours = duration.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  void updateTrainAxleCounters(Train train) {
    final nearestCounter = ace.findNearestAxleCounter(train.x, train.y);

    if (nearestCounter != null) {
      final isEntering = _isTrainEnteringSection(nearestCounter, train);
      ace.updateAxleCounter(nearestCounter, train.direction, isEntering, wheelCount: train.wheelCount);
      notifyListeners();
    }
  }

  void _startSimulationTimer() {
    _simulationStartTime = DateTime.now().subtract(_simulationRunningTime);
    _simulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_simulationStartTime != null) {
        _simulationRunningTime =
            DateTime.now().difference(_simulationStartTime!);
        notifyListeners();
      }
    });
  }

  void _stopSimulationTimer() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  void _resetSimulationTimer() {
    _stopSimulationTimer();
    _simulationRunningTime = Duration.zero;
    _simulationStartTime = null;
  }

  bool isRoutePendingCancellation(String signalId) {
    return _pendingRouteCancellations[signalId] == true;
  }

  // ============================================================================
  // SIGNAL VISIBILITY TOGGLE
  // ============================================================================

  void toggleSignalsVisibility() {
    signalsVisible = !signalsVisible;
    _logEvent(signalsVisible ? '✅ Signals enabled' : '❌ Signals disabled');
    notifyListeners();
  }

  // FIXED: CBTC toggle methods
  void toggleCbtcDevices(bool enabled) {
    cbtcDevicesEnabled = enabled;
    if (!enabled) {
      cbtcModeActive = false;  // Disable mode if devices are disabled
    }
    _logEvent(enabled
        ? '📡 CBTC devices ENABLED (Transponders + WiFi)'
        : '📡 CBTC devices DISABLED');
    notifyListeners();
  }

  void toggleCbtcMode(bool active) {
    if (!cbtcDevicesEnabled) {
      _logEvent('⚠️ Cannot activate CBTC mode: Devices not enabled');
      return;
    }
    cbtcModeActive = active;

    // Set all signals to blue when CBTC mode is active
    if (active) {
      for (final signal in signals.values) {
        signal.aspect = SignalAspect.blue;
      }
      _logEvent('🚄 CBTC Mode ACTIVATED - Moving block signaling enabled, all signals BLUE');
    } else {
      // Restore normal signal aspects when CBTC mode is deactivated
      for (final signal in signals.values) {
        signal.aspect = SignalAspect.red;
      }
      _logEvent('🚄 CBTC Mode DEACTIVATED - Fixed block signaling, signals restored');
    }

    notifyListeners();
  }

  void toggleWifiAntenna(String wifiId) {
    final wifi = wifiAntennas[wifiId];
    if (wifi == null) {
      _logEvent('⚠️ WiFi antenna $wifiId not found');
      return;
    }
    wifi.isActive = !wifi.isActive;
    _logEvent(wifi.isActive
        ? '📡 WiFi $wifiId ENABLED'
        : '📡 WiFi $wifiId DISABLED');

    // If WiFi is turned OFF, check for CBTC trains in range and set them to NCT
    if (!wifi.isActive) {
      const wifiRange = 300.0; // WiFi coverage range
      for (var train in trains) {
        if (!train.isCbtcTrain) continue;
        if (train.cbtcMode == CbtcMode.off || train.cbtcMode == CbtcMode.storage) continue;

        // Check if train is within range of this WiFi antenna
        final distance = math.sqrt(
          math.pow(train.x - wifi.x, 2) + math.pow(train.y - wifi.y, 2)
        );

        if (distance <= wifiRange) {
          // Check if train has other WiFi coverage
          bool hasOtherWifi = false;
          for (var otherWifi in wifiAntennas.values) {
            if (otherWifi.id == wifiId || !otherWifi.isActive) continue;
            final otherDistance = math.sqrt(
              math.pow(train.x - otherWifi.x, 2) + math.pow(train.y - otherWifi.y, 2)
            );
            if (otherDistance <= wifiRange) {
              hasOtherWifi = true;
              break;
            }
          }

          // If no other WiFi coverage, set train to NCT
          if (!hasOtherWifi) {
            train.isNCT = true;
            train.transpondersPassed = 0;
            train.terReceived = false;
            train.directionConfirmed = false;
            train.lastTransponderId = null;
            train.tractionLostAt = null; // Clear traction tracking
            train.tractionLossWarned = false;
            _logEvent('🚨 NCT ALERT: ${train.name} lost WiFi communication (antenna $wifiId disabled)');
            _logEvent('ℹ️  Switch to RM mode and pass over 2 transponders to reactivate');
          }
        }
      }
    }

    notifyListeners();
  }

  // ============================================================================
  // NEW FEATURE TOGGLES - Grid, Traction, Tooltips, AI Agent, Relay Rack
  // ============================================================================

  void toggleGrid() {
    gridVisible = !gridVisible;
    _logEvent(gridVisible ? '🔲 Grid ENABLED' : '🔲 Grid DISABLED');
    notifyListeners();
  }

  void toggleTractionCurrent() {
    tractionCurrentOn = !tractionCurrentOn;
    tractionWestOn = tractionCurrentOn;
    tractionCentralOn = tractionCurrentOn;
    tractionEastOn = tractionCurrentOn;

    if (!tractionCurrentOn) {
      // Apply emergency brake to all trains
      for (var train in trains) {
        train.emergencyBrake = true;
        train.speed = 0;
        train.targetSpeed = 0;
      }
      _logEvent('⚡ TRACTION CURRENT OFF (ALL SECTIONS) - All trains emergency braked');
    } else {
      // Release emergency brake (but trains won't move until signals allow)
      for (var train in trains) {
        train.emergencyBrake = false;
      }
      _logEvent('⚡ TRACTION CURRENT ON (ALL SECTIONS) - Normal operations resumed');
    }
    notifyListeners();
  }

  void toggleTractionWest() {
    tractionWestOn = !tractionWestOn;
    if (!tractionWestOn) {
      // Apply emergency brake to trains in west section (x < -200)
      for (var train in trains) {
        if (train.x < -200) {
          train.emergencyBrake = true;
          train.speed = 0;
          train.targetSpeed = 0;
        }
      }
      _logEvent('⚡ TRACTION CURRENT OFF (WEST SECTION) - West trains emergency braked');
    } else {
      // Release emergency brake for west trains
      for (var train in trains) {
        if (train.x < -200) {
          train.emergencyBrake = false;
        }
      }
      _logEvent('⚡ TRACTION CURRENT ON (WEST SECTION) - West section resumed');
    }
    notifyListeners();
  }

  void toggleTractionCentral() {
    tractionCentralOn = !tractionCentralOn;
    if (!tractionCentralOn) {
      // Apply emergency brake to trains in central section (-200 <= x <= 1800)
      for (var train in trains) {
        if (train.x >= -200 && train.x <= 1800) {
          train.emergencyBrake = true;
          train.speed = 0;
          train.targetSpeed = 0;
        }
      }
      _logEvent('⚡ TRACTION CURRENT OFF (CENTRAL SECTION) - Central trains emergency braked');
    } else {
      // Release emergency brake for central trains
      for (var train in trains) {
        if (train.x >= -200 && train.x <= 1800) {
          train.emergencyBrake = false;
        }
      }
      _logEvent('⚡ TRACTION CURRENT ON (CENTRAL SECTION) - Central section resumed');
    }
    notifyListeners();
  }

  void toggleTractionEast() {
    tractionEastOn = !tractionEastOn;
    if (!tractionEastOn) {
      // Apply emergency brake to trains in east section (x > 1800)
      for (var train in trains) {
        if (train.x > 1800) {
          train.emergencyBrake = true;
          train.speed = 0;
          train.targetSpeed = 0;
        }
      }
      _logEvent('⚡ TRACTION CURRENT OFF (EAST SECTION) - East trains emergency braked');
    } else {
      // Release emergency brake for east trains
      for (var train in trains) {
        if (train.x > 1800) {
          train.emergencyBrake = false;
        }
      }
      _logEvent('⚡ TRACTION CURRENT ON (EAST SECTION) - East section resumed');
    }
    notifyListeners();
  }

  // Check if traction is on for a specific position
  bool isTractionOnAt(double x) {
    if (x < -200) return tractionWestOn;
    if (x > 1800) return tractionEastOn;
    return tractionCentralOn;
  }

  void toggleTooltips() {
    tooltipsEnabled = !tooltipsEnabled;
    _logEvent(tooltipsEnabled ? '💬 Tooltips ENABLED' : '💬 Tooltips DISABLED');
    notifyListeners();
  }

  void toggleGhostTrainsVisibility() {
    showGhostTrains = !showGhostTrains;
    _logEvent(showGhostTrains ? '👻 Ghost Trains VISIBLE' : '👻 Ghost Trains HIDDEN');
    notifyListeners();
  }

  void toggleAiAgent() {
    signallingSystemManagerVisible = !signallingSystemManagerVisible;
    _logEvent(signallingSystemManagerVisible ? '🚦 Signalling System Manager ENABLED' : '🚦 Signalling System Manager DISABLED');
    notifyListeners();
  }

  void toggleSignallingSystemManager() {
    signallingSystemManagerVisible = !signallingSystemManagerVisible;
    _logEvent(signallingSystemManagerVisible ? '🚦 Signalling System Manager ENABLED' : '🚦 Signalling System Manager DISABLED');
    notifyListeners();
  }

  void toggleRelayRack() {
    relayRackVisible = !relayRackVisible;
    _logEvent(relayRackVisible ? '🔌 Relay Rack ENABLED' : '🔌 Relay Rack DISABLED');
    notifyListeners();
  }

  void updateAiAgentPosition(Offset newPosition) {
    signallingSystemManagerPosition = newPosition;
    notifyListeners();
  }

  void updateSignallingSystemManagerPosition(Offset newPosition) {
    signallingSystemManagerPosition = newPosition;
    notifyListeners();
  }

  void updateAiAgentSize(double width, double height) {
    signallingSystemManagerWidth = width.clamp(150.0, 600.0);
    signallingSystemManagerHeight = height.clamp(200.0, 800.0);
    notifyListeners();
  }

  void updateSignallingSystemManagerSize(double width, double height) {
    signallingSystemManagerWidth = width.clamp(150.0, 600.0);
    signallingSystemManagerHeight = height.clamp(200.0, 800.0);
    notifyListeners();
  }

  void updateAiAgentOpacity(double opacity) {
    signallingSystemManagerOpacity = opacity.clamp(0.1, 1.0);
    notifyListeners();
  }

  void updateSignallingSystemManagerOpacity(double opacity) {
    signallingSystemManagerOpacity = opacity.clamp(0.1, 1.0);
    notifyListeners();
  }

  void updateSignallingSystemManagerColor(Color color) {
    signallingSystemManagerColor = color;
    _logEvent('🎨 Signalling System Manager color changed');
    notifyListeners();
  }

  void updateSignallingSystemManagerDesignType(int designType) {
    signallingSystemManagerDesignType = designType.clamp(0, 3);
    _logEvent('🎨 Signalling System Manager design changed to type $designType');
    notifyListeners();
  }

  void toggleSignallingSystemManagerCompactMode() {
    signallingSystemManagerCompactMode = !signallingSystemManagerCompactMode;
    _logEvent(signallingSystemManagerCompactMode ? '📦 Compact mode ENABLED' : '📦 Compact mode DISABLED');
    notifyListeners();
  }

  void toggleSignallingSystemManagerAutoScroll() {
    signallingSystemManagerAutoScroll = !signallingSystemManagerAutoScroll;
    _logEvent(signallingSystemManagerAutoScroll ? '📜 Auto-scroll ENABLED' : '📜 Auto-scroll DISABLED');
    notifyListeners();
  }

  // Camera control methods
  void updateCameraPosition(double offsetX, double offsetY, double zoom) {
    cameraOffsetX = offsetX;
    cameraOffsetY = offsetY;
    cameraZoom = zoom.clamp(0.3, 3.0);
    notifyListeners();
  }

  void panToPosition(double x, double y, {double? zoom, double? viewportWidth, double? viewportHeight}) {
    // If viewport dimensions are provided, center the position in viewport
    if (viewportWidth != null && viewportHeight != null) {
      final targetZoom = zoom ?? cameraZoom;
      // Calculate offset to center item in viewport
      // Camera offset = -(item position) + (viewport center / zoom)
      cameraOffsetX = -x + (viewportWidth / 2) / targetZoom;
      cameraOffsetY = -y + (viewportHeight / 2) / targetZoom;
    } else {
      // Legacy behavior - simple offset
      cameraOffsetX = -x;
      cameraOffsetY = -y;
    }

    if (zoom != null) {
      cameraZoom = zoom.clamp(0.3, 3.0);
    }
    notifyListeners();
  }

  void followTrain(String trainId) {
    followingTrainId = trainId;
    final train = trains.where((t) => t.id == trainId).firstOrNull;
    if (train != null) {
      panToPosition(train.x, train.y);
    }
    notifyListeners();
  }

  void stopFollowingTrain() {
    followingTrainId = null;
    notifyListeners();
  }

  /// Disable auto-follow mode (alias for stopFollowingTrain for clarity)
  void disableAutoFollow() {
    stopFollowingTrain();
  }

  void highlightItem(String itemId, String itemType) {
    highlightedItemId = itemId;
    highlightedItemType = itemType;
    notifyListeners();
  }

  void clearHighlight() {
    highlightedItemId = null;
    highlightedItemType = null;
    notifyListeners();
  }

  void setHoveredObject(Map<String, dynamic>? object) {
    hoveredObject = object;
    notifyListeners();
  }

  // ============================================================================
  // BLOCK CLOSING SYSTEM
  // ============================================================================

  void closeBlock(String blockId) {
    closedBlocks[blockId] = true;
    _logEvent('🚫 Block $blockId CLOSED');
    notifyListeners();
  }

  void openBlock(String blockId) {
    closedBlocks.remove(blockId);
    _logEvent('✅ Block $blockId OPENED');
    notifyListeners();
  }

  bool isBlockClosed(String blockId) {
    return closedBlocks[blockId] ?? false;
  }

  void toggleBlockClosed(String blockId) {
    if (isBlockClosed(blockId)) {
      openBlock(blockId);
    } else {
      closeBlock(blockId);
    }
  }

  // Get relay status for signals (GR - proceed relay)
  String getSignalGRStatus(String signalId) {
    final signal = signals[signalId];
    if (signal == null) return 'Unknown';
    return signal.aspect == SignalAspect.green ? 'Up' : 'Down';
  }

  // Get relay status for points (WKR - point machine relay)
  String getPointWKRStatus(String pointId) {
    // Check if point is currently throwing (mid state)
    final throwStartTime = pointThrowStartTimes[pointId];
    if (throwStartTime != null) {
      final elapsed = DateTime.now().difference(throwStartTime).inMilliseconds;
      if (elapsed < 2000) { // Points take 2 seconds to throw
        return 'Mid';
      } else {
        // Throwing complete, remove from tracking
        pointThrowStartTimes.remove(pointId);
      }
    }

    final point = points[pointId];
    if (point == null) return 'Unknown';
    return point.position == PointPosition.normal ? 'Normal' : 'Reverse';
  }

  // Get relay status for track blocks (TR - track relay)
  String getBlockTRStatus(String blockId) {
    final block = blocks[blockId];
    if (block == null) return 'Unknown';
    return block.occupied ? 'Occupied' : 'Clear';
  }

  // ============================================================================
  // COLLISION RECOVERY METHODS
  // ============================================================================

  bool _isTrainInCollisionRecovery(String trainId) {
    return _activeCollisionRecoveries.values.any((plan) =>
        plan.trainsInvolved.contains(trainId) &&
        plan.state != CollisionRecoveryState.resolved);
  }

  bool _isTrainInSPADRecovery(String trainId) {
    return _spadAlarmActive &&
        _currentSpadIncident?.trainsInvolved.contains(trainId) == true;
  }

  CollisionRecoveryPlan? _getRecoveryPlanForTrain(String trainId) {
    for (var plan in _activeCollisionRecoveries.values) {
      if (plan.trainsInvolved.contains(trainId)) {
        return plan;
      }
    }
    return null;
  }

  List<CollisionRecoveryPlan> getActiveRecoveryPlans() {
    return _activeCollisionRecoveries.values.toList();
  }

  void _handleCollisionRecovery(Train train, CollisionRecoveryPlan plan) {
    switch (plan.state) {
      case CollisionRecoveryState.detected:
        if (DateTime.now().difference(plan.detectedAt).inSeconds > 1) {
          plan.state = CollisionRecoveryState.recovery;
          _logEvent('🔄 Starting recovery for ${train.name}');
        }
        break;

      case CollisionRecoveryState.recovery:
        _executeRecoveryMovement(train, plan);
        break;

      case CollisionRecoveryState.resolved:
        break;

      case CollisionRecoveryState.manualOverride:
        break;

      case CollisionRecoveryState.none:
        break;
    }
  }

  void _executeRecoveryMovement(Train train, CollisionRecoveryPlan plan) {
    final targetPosition = plan.targetRecoveryPositions[train.id];
    if (targetPosition == null) return;

    // Reverse direction if moving forward
    if (train.direction > 0) {
      train.direction = -1;
      _logEvent('🔄 ${train.name} reversing for collision recovery (moving 20 units back)');
    }

    train.emergencyBrake = false;
    train.targetSpeed = 3.0;

    // Move train backwards
    train.x += train.speed * train.direction * simulationSpeed * 2.0;

    // Check if train has reached target position (20 units back from collision)
    if (train.x <= targetPosition) {
      _logEvent('✅ ${train.name} reached safe position (20 units back from collision)');
      train.x = targetPosition; // Snap to exact position
      train.targetSpeed = 0;
      train.speed = 0;
      train.emergencyBrake = false;
      train.direction = 1; // Restore forward direction

      _checkRecoveryCompletion(plan);
    }
  }

  void _checkRecoveryCompletion(CollisionRecoveryPlan plan) {
    bool allTrainsSafe = true;

    for (var trainId in plan.trainsInvolved) {
      final train = trains.firstWhere((t) => t.id == trainId);
      final targetPosition = plan.targetRecoveryPositions[trainId];

      // Check if train has reached target position and stopped
      if (targetPosition == null ||
          train.x > targetPosition ||
          train.speed > 0) {
        allTrainsSafe = false;
        break;
      }
    }

    if (allTrainsSafe) {
      plan.state = CollisionRecoveryState.resolved;
      plan.resolvedAt = DateTime.now();
      _logEvent('🎉 Collision recovery completed for ${plan.collisionId}');

      Future.delayed(const Duration(seconds: 1), () {
        _activeCollisionRecoveries.remove(plan.collisionId);
        if (_activeCollisionRecoveries.isEmpty) {
          collisionAlarmActive = false;
          currentCollisionIncident = null;
        }
        notifyListeners();
      });
    }
  }

  void startAutomaticCollisionRecovery() {
    if (!collisionAlarmActive) return;

    for (var recoveryPlan in _activeCollisionRecoveries.values) {
      recoveryPlan.state = CollisionRecoveryState.recovery;

      for (var trainId in recoveryPlan.trainsInvolved) {
        final train = trains.firstWhere((t) => t.id == trainId);
        train.emergencyBrake = false;
        _logEvent('🤖 Automatic recovery started for ${train.name}');
      }
    }

    notifyListeners();
  }

  void startManualCollisionRecovery() {
    if (!collisionAlarmActive) return;

    for (var recoveryPlan in _activeCollisionRecoveries.values) {
      recoveryPlan.state = CollisionRecoveryState.manualOverride;

      for (var trainId in recoveryPlan.trainsInvolved) {
        final train = trains.firstWhere((t) => t.id == trainId);
        train.emergencyBrake = false;
        train.controlMode = TrainControlMode.manual;
        _logEvent('🎮 Manual recovery enabled for ${train.name}');
      }
    }

    notifyListeners();
  }

  void forceCollisionResolution() {
    _activeCollisionRecoveries.clear();
    collisionAlarmActive = false;
    currentCollisionIncident = null;

    for (var train in trains) {
      train.emergencyBrake = false;
    }

    _logEvent('🔄 All collisions force-resolved by user');
    notifyListeners();
  }

  // SIMPLIFIED COLLISION RECOVERY - Single button, moves trains 20 units back
  void executeSimplifiedCollisionRecovery() {
    if (!collisionAlarmActive || currentCollisionIncident == null) return;

    final trainsInvolved = currentCollisionIncident!.trainsInvolved;

    // Find the trains involved
    final collisionTrains = trains.where((t) => trainsInvolved.contains(t.id)).toList();

    if (collisionTrains.length >= 2) {
      // Move each train 20 units backwards in opposite directions
      for (var train in collisionTrains) {
        // Move 20 units opposite to current direction
        if (train.direction > 0) {
          // Was moving right, move left
          train.x -= 20;
        } else {
          // Was moving left, move right
          train.x += 20;
        }

        // Release emergency brake but keep train stopped
        train.emergencyBrake = false;
        train.speed = 0;
        train.targetSpeed = 0;

        _logEvent('🔄 ${train.name} moved 20 units back for collision recovery');
      }
    }

    // Auto-generate collision report (no acknowledgment needed)
    _logEvent('📋 Collision report generated automatically');

    // Clear collision state
    _activeCollisionRecoveries.clear();
    collisionAlarmActive = false;
    currentCollisionIncident = null;

    _logEvent('✅ Simplified collision recovery complete');
    notifyListeners();
  }

  // ============================================================================
  // POINT DEADLOCK METHODS
  // ============================================================================

  bool _arePointsDeadlocked() {
    final point78A = points['78A'];
    final point78B = points['78B'];

    bool point78ADeadlocked = false;
    bool point78BDeadlocked = false;

    // Check AB104 occupation for point 78A deadlock
    if (ace.isABOccupied('AB104')) {
      point78ADeadlocked = true;
      if (!point78A!.locked) {
        _logEvent('🔒 Point 78A deadlocked: AB104 occupied');
        point78A.locked = true;
        point78A.lockedByAB = true;
      }
    } else {
      // AB104 is clear, remove deadlock if it was set by AB occupation
      if (point78A!.locked &&
          point78A.lockedByAB &&
          !ace.isABOccupied('AB106')) {
        point78A.locked = false;
        point78A.lockedByAB = false;
        _logEvent('🔓 Point 78A unlocked: AB104 clear');
      }
    }

    // Check AB109 occupation for point 78B deadlock
    if (ace.isABOccupied('AB109')) {
      point78BDeadlocked = true;
      if (!point78B!.locked) {
        _logEvent('🔒 Point 78B deadlocked: AB109 occupied');
        point78B.locked = true;
        point78B.lockedByAB = true;
      }
    } else {
      // AB109 is clear, remove deadlock if it was set by AB occupation
      if (point78B!.locked &&
          point78B.lockedByAB &&
          !ace.isABOccupied('AB106')) {
        point78B.locked = false;
        point78B.lockedByAB = false;
        _logEvent('🔓 Point 78B unlocked: AB109 clear');
      }
    }

    // Check AB106 occupation for both points deadlock
    if (ace.isABOccupied('AB106')) {
      point78ADeadlocked = true;
      point78BDeadlocked = true;

      if (!point78A!.locked) {
        _logEvent('🔒 Point 78A deadlocked: AB106 occupied');
        point78A.locked = true;
        point78A.lockedByAB = true;
      }

      if (!point78B!.locked) {
        _logEvent('🔒 Point 78B deadlocked: AB106 occupied');
        point78B.locked = true;
        point78B.lockedByAB = true;
      }
    } else {
      // AB106 is clear, remove deadlock if it was set by AB106 occupation only
      if (point78A!.locked &&
          point78A.lockedByAB &&
          !ace.isABOccupied('AB104')) {
        point78A.locked = false;
        point78A.lockedByAB = false;
        _logEvent('🔓 Point 78A unlocked: AB106 clear');
      }

      if (point78B!.locked &&
          point78B.lockedByAB &&
          !ace.isABOccupied('AB109')) {
        point78B.locked = false;
        point78B.lockedByAB = false;
        _logEvent('🔓 Point 78B unlocked: AB106 clear');
      }
    }

    return point78ADeadlocked || point78BDeadlocked;
  }

  // Public getter for point deadlock status
  bool get arePointsDeadlocked => _arePointsDeadlocked();

  bool _isPointDeadlockedByAB(String pointId) {
    switch (pointId) {
      case '78A':
        return ace.isABOccupied('AB104') || ace.isABOccupied('AB106');
      case '78B':
        return ace.isABOccupied('AB109') || ace.isABOccupied('AB106');
      default:
        return false;
    }
  }

  Map<String, bool> getABDeadlockStatus() {
    return {
      'point78A': _isPointDeadlockedByAB('78A'),
      'point78B': _isPointDeadlockedByAB('78B'),
      'ab104': ace.isABOccupied('AB104'),
      'ab106': ace.isABOccupied('AB106'),
      'ab109': ace.isABOccupied('AB109'),
    };
  }

  // Add this method to reset individual train emergency brakes
  void resetTrainEmergencyBrake(String trainId) {
    final train = trains.firstWhere((t) => t.id == trainId);
    train.emergencyBrake = false;
    _logEvent('🔄 ${train.name} emergency brake reset');
    notifyListeners();
  }

  // Add this method to reset ACE
  void resetACE() {
    ace.resetAll();
    _logEvent('🔄 Axle Counter Evaluator (ACE) reset');
    notifyListeners();
  }

  bool isABOccupied(String abId) {
    return ace.isABOccupied(abId);
  }

  // Add this method to check train stops
  void _checkTrainStops() {
    for (var train in trains) {
      if (train.controlMode == TrainControlMode.manual) {
        for (var trainStop in trainStops.values) {
          if (trainStop.enabled && trainStop.active) {
            final distance = (train.x - trainStop.x).abs();
            if (distance < 30 && (train.y - trainStop.y).abs() < 30) {
              if (train.speed > 0) {
                _handleTrainStopSPAD(train, trainStop);
              }
            }
          }
        }
      }
    }
  }

  // Add this method to update axle counters
  void _updateAxleCounters() {
    for (var train in trains) {
      for (var counter in axleCounters.values) {
        final distance = math.sqrt(math.pow(train.x - counter.x, 2) +
            math.pow(train.y - counter.y, 2));

        if (distance < 50) {
          // Train is near the axle counter
          if (!counter.d1Active && train.direction > 0) {
            counter.d1Active = true;
            counter.count++;
            counter.lastDetectionTime = DateTime.now();
            counter.lastDirection = 'D1';
            _logEvent(
                '🔢 ${counter.id} detected train ${train.name} via D1 - Count: ${counter.count}');
          } else if (!counter.d2Active && train.direction < 0) {
            counter.d2Active = true;
            counter.count++;
            counter.lastDetectionTime = DateTime.now();
            counter.lastDirection = 'D2';
            _logEvent(
                '🔢 ${counter.id} detected train ${train.name} via D2 - Count: ${counter.count}');
          }
        } else {
          // Reset detection when train moves away
          if (counter.d1Active && train.direction > 0) {
            counter.d1Active = false;
          }
          if (counter.d2Active && train.direction < 0) {
            counter.d2Active = false;
          }
        }
      }
    }

    // Update ACE results using the corrected method
    ace.updateABOccupations();
  }

  // ============================================================================
  // CBTC MOVEMENT AUTHORITY
  // ============================================================================

  void _updateMovementAuthorities() {
    for (var train in trains) {
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

    // CBTC Emergency Brake: Pull back reservation immediately
    if (train.emergencyBrake) {
      return MovementAuthority(
        maxDistance: 0.0,
        limitReason: '⚠️  EMERGENCY BRAKE ACTIVE',
        hasDestination: hasDestination,
      );
    }

    final trainPos = train.x;
    final direction = train.direction;

    // Check for other CBTC trains ahead
    for (var otherTrain in trains) {
      if (otherTrain.id == train.id) continue;
      if (!otherTrain.isCbtcEquipped) continue;

      final otherPos = otherTrain.x;
      bool isAhead = false;
      double distance = 0;

      if (direction > 0 && otherPos > trainPos) {
        isAhead = true;
        distance = otherPos - trainPos;
      } else if (direction < 0 && otherPos < trainPos) {
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
        final otherMaEnd = direction > 0
            ? otherPos + otherTrain.movementAuthority!.maxDistance
            : otherPos - otherTrain.movementAuthority!.maxDistance;

        final distanceToOtherMa = direction > 0
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

    // Check for occupied blocks ahead
    for (var block in blocks.values) {
      if (!block.occupied || block.occupyingTrainId == train.id) continue;

      final blockStart = block.startX;
      final blockEnd = block.endX;
      bool isAhead = false;
      double distance = 0;

      if (direction > 0 && blockStart > trainPos) {
        isAhead = true;
        distance = blockStart - trainPos;
      } else if (direction < 0 && blockEnd < trainPos) {
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

    // Check for signals at danger
    for (var signal in signals.values) {
      if (signal.aspect != SignalAspect.red) continue;

      final signalPos = signal.x;
      bool isAhead = false;
      double distance = 0;

      if (direction > 0 && signalPos > trainPos) {
        isAhead = true;
        distance = signalPos - trainPos;
      } else if (direction < 0 && signalPos < trainPos) {
        isAhead = true;
        distance = trainPos - signalPos;
      }

      if (isAhead) {
        // Stop 50 units before red signal
        final limitDistance = distance - 50;
        if (limitDistance > 0 && limitDistance < maxDistance) {
          maxDistance = limitDistance;
          limitReason = 'Signal ${signal.id} at danger';
        }
      }
    }

    // Check for points in wrong position for destination (CBTC AUTO/PM mode only)
    if ((train.cbtcMode == CbtcMode.auto || train.cbtcMode == CbtcMode.pm) &&
        train.smcDestination != null) {
      for (var point in points.values) {
        final pointPos = point.x;
        bool isAhead = false;
        double distance = 0;

        if (direction > 0 && pointPos > trainPos) {
          isAhead = true;
          distance = pointPos - trainPos;
        } else if (direction < 0 && pointPos < trainPos) {
          isAhead = true;
          distance = trainPos - pointPos;
        }

        if (isAhead) {
          // TODO: Check if point position is correct for train's destination
          // For now, we assume point correctness is handled by route setting
          // This is a placeholder for future route-based point validation
          // If point is wrong for destination:
          //   Stop 20 units before the point
          //   Train will resume when point is corrected

          // Example logic (needs route integration):
          // if (point is wrong for destination route) {
          //   final limitDistance = distance - 20;
          //   if (limitDistance > 0 && limitDistance < maxDistance) {
          //     maxDistance = limitDistance;
          //     limitReason = 'Point ${point.id} wrong position';
          //   }
          // }
        }
      }
    }

    // Limit to 4 blocks ahead maximum for CBTC trains
    final blocksAhead = _countBlocksAhead(train, maxDistance);
    if (blocksAhead > 4) {
      // Find the end of the 4th block ahead
      final fourthBlockEnd = _getFourthBlockEndPosition(train);
      if (fourthBlockEnd != null && fourthBlockEnd < maxDistance) {
        maxDistance = fourthBlockEnd;
        limitReason = 'CBTC limit: 4 blocks max';
      }
    }

    return MovementAuthority(
      maxDistance: maxDistance.clamp(0.0, 2000.0),
      limitReason: limitReason,
      hasDestination: hasDestination,
    );
  }

  // Count how many blocks are ahead within a given distance
  int _countBlocksAhead(Train train, double distance) {
    int count = 0;
    final trainPos = train.x;
    final direction = train.direction;

    for (var block in blocks.values) {
      bool isAhead = false;

      if (direction > 0) {
        // Eastbound - check blocks to the right
        if (block.startX > trainPos && block.startX <= trainPos + distance) {
          isAhead = true;
        }
      } else {
        // Westbound - check blocks to the left
        if (block.endX < trainPos && block.endX >= trainPos - distance) {
          isAhead = true;
        }
      }

      if (isAhead) {
        count++;
      }
    }

    return count;
  }

  // Get the end position of the 4th block ahead
  double? _getFourthBlockEndPosition(Train train) {
    final trainPos = train.x;
    final direction = train.direction;

    // Collect blocks ahead and sort by distance
    final blocksAhead = <MapEntry<String, BlockSection>>[];

    for (var entry in blocks.entries) {
      final block = entry.value;
      bool isAhead = false;

      if (direction > 0) {
        // Eastbound - check blocks to the right
        if (block.startX > trainPos) {
          isAhead = true;
        }
      } else {
        // Westbound - check blocks to the left
        if (block.endX < trainPos) {
          isAhead = true;
        }
      }

      if (isAhead) {
        blocksAhead.add(entry);
      }
    }

    // Sort by distance from train
    blocksAhead.sort((a, b) {
      final distA = direction > 0
          ? a.value.startX - trainPos
          : trainPos - a.value.endX;
      final distB = direction > 0
          ? b.value.startX - trainPos
          : trainPos - b.value.endX;
      return distA.compareTo(distB);
    });

    // Get the 4th block if it exists
    if (blocksAhead.length >= 4) {
      final fourthBlock = blocksAhead[3].value;
      return direction > 0 ? fourthBlock.endX : fourthBlock.startX;
    }

    return null;
  }

  // ============================================================================
  // SPAD HANDLING
  // ============================================================================

  void _handleTrainStopSPAD(Train train, TrainStop trainStop) {
    train.emergencyBrake = true;
    train.targetSpeed = 0;
    train.speed = 0;

    _logEvent(
        '🚨 SPAD DETECTED: ${train.name} passed TrainStop ${trainStop.id}');

    final incident = _collisionSystem.analyzeCollision(
      trainsInvolved: [train.id],
      location: 'TrainStop ${trainStop.id}',
      currentSystemState: _captureSystemState(),
    );

    _currentSpadIncident = CollisionIncident(
      id: incident.id,
      timestamp: incident.timestamp,
      trainsInvolved: incident.trainsInvolved,
      location: 'TrainStop ${trainStop.id} - SPAD Incident',
      severity: CollisionSeverity.minor,
      rootCauses: [CollisionCause.signalPassedAtDanger],
      responsibility: Responsibility.trainDriver,
      specificParty: 'Driver of ${train.name} (manual mode)',
      leadingEvents: incident.leadingEvents,
      systemStateAtCollision: incident.systemStateAtCollision,
      preventionRecommendations: [
        'Implement additional driver training on signal awareness',
        'Consider installing Automatic Train Protection (ATP) system',
        'Review driver attention monitoring procedures',
        'Install SPAD detection and prevention systems'
      ],
      forensicSummary: _createSPADSummary(train, trainStop, incident),
    );

    _spadAlarmActive = true;
    _spadTrainStopId = trainStop.id;

    trainStop.enabled = false;

    notifyListeners();
  }

  String _createSPADSummary(
      Train train, TrainStop trainStop, CollisionIncident incident) {
    final buffer = StringBuffer();

    buffer.writeln('SPAD (SIGNAL PASSED AT DANGER) INCIDENT REPORT');
    buffer.writeln('=' * 60);
    buffer.writeln();
    buffer.writeln('INCIDENT OVERVIEW:');
    buffer.writeln('Train: ${train.name}');
    buffer.writeln('TrainStop: ${trainStop.id}');
    buffer.writeln('Location: ${trainStop.signalId} protection zone');
    buffer.writeln('Time: ${DateTime.now().toIso8601String()}');
    buffer.writeln();
    buffer.writeln('ROOT CAUSE:');
    buffer.writeln('• Signal Passed At Danger (SPAD)');
    buffer.writeln('• Manual mode train failed to stop at activated TrainStop');
    buffer.writeln('• Driver operational error');
    buffer.writeln();
    buffer.writeln('IMMEDIATE ACTIONS:');
    buffer.writeln('• Emergency brake applied automatically');
    buffer.writeln('• TrainStop ${trainStop.id} disabled temporarily');
    buffer.writeln('• SPAD investigation required');
    buffer.writeln();
    buffer.writeln('RESPONSIBILITY:');
    buffer.writeln('• Train Driver: Failed to observe and obey TrainStop');
    buffer.writeln();
    buffer.writeln('PREVENTION RECOMMENDATIONS:');
    buffer.writeln('• Enhanced driver training on signal awareness');
    buffer.writeln('• ATP system implementation');
    buffer.writeln('• Regular competency assessments');
    buffer.writeln('• Improved signal sighting assessments');

    return buffer.toString();
  }

  void acknowledgeSPADAlarm() {
    _spadAlarmActive = false;
    _currentSpadIncident = null;
    _spadTrainStopId = null;
    notifyListeners();
  }

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  TerminalStationController() {
    _initializeLayout();
    _initializeClock();
    _initializeTimetable();
    ace = AxleCounterEvaluator(axleCounters);
  }

  void _initializeAxleCounters() {
    // LEFT SECTION AXLE COUNTERS (196-215) - Extended with buffer stops
    // Upper track (196-214) eastbound
    axleCounters['ac198'] = AxleCounter(id: 'ac198', blockId: '198', x: -1750, y: 120);
    axleCounters['ac196'] = AxleCounter(id: 'ac196', blockId: '196', x: -1650, y: 120);
    axleCounters['ac200'] = AxleCounter(id: 'ac200', blockId: '200', x: -1500, y: 120);
    axleCounters['ac202'] = AxleCounter(id: 'ac202', blockId: '202', x: -1300, y: 120);
    axleCounters['ac204'] = AxleCounter(id: 'ac204', blockId: '204', x: -1100, y: 120);
    axleCounters['ac206'] = AxleCounter(id: 'ac206', blockId: '206', x: -900, y: 120);
    axleCounters['ac208'] = AxleCounter(id: 'ac208', blockId: '208', x: -700, y: 120);
    axleCounters['ac210'] = AxleCounter(id: 'ac210', blockId: '210', x: -500, y: 120);
    axleCounters['ac212'] = AxleCounter(id: 'ac212', blockId: '212', x: -300, y: 120);
    axleCounters['ac214'] = AxleCounter(id: 'ac214', blockId: '214', x: -100, y: 120);

    // Lower track (197-215) westbound
    axleCounters['ac199'] = AxleCounter(id: 'ac199', blockId: '199', x: -1750, y: 320);
    axleCounters['ac197'] = AxleCounter(id: 'ac197', blockId: '197', x: -1650, y: 320);
    axleCounters['ac201'] = AxleCounter(id: 'ac201', blockId: '201', x: -1500, y: 320);
    axleCounters['ac203'] = AxleCounter(id: 'ac203', blockId: '203', x: -1300, y: 320);
    axleCounters['ac205'] = AxleCounter(id: 'ac205', blockId: '205', x: -1100, y: 320);
    axleCounters['ac207'] = AxleCounter(id: 'ac207', blockId: '207', x: -900, y: 320);
    axleCounters['ac209'] = AxleCounter(id: 'ac209', blockId: '209', x: -700, y: 320);
    axleCounters['ac211'] = AxleCounter(id: 'ac211', blockId: '211', x: -500, y: 320);
    axleCounters['ac213'] = AxleCounter(id: 'ac213', blockId: '213', x: -300, y: 320);
    axleCounters['ac215'] = AxleCounter(id: 'ac215', blockId: '215', x: -100, y: 320);

    // Left section crossover - crossover_left removed, only crossover_211_212 remains
    axleCounters['ac_cx211_212'] = AxleCounter(id: 'ac_cx211_212', blockId: 'crossover_211_212', x: -375, y: 200);

    // MIDDLE SECTION AXLE COUNTERS (100-115) - Original
    axleCounters['ac100'] = AxleCounter(id: 'ac100', blockId: '100', x: 100, y: 120);
    axleCounters['ac104'] = AxleCounter(id: 'ac104', blockId: '104', x: 550, y: 120);
    axleCounters['ac108'] = AxleCounter(id: 'ac108', blockId: '108', x: 700, y: 120);
    axleCounters['ac112'] = AxleCounter(id: 'ac112', blockId: '112', x: 1300, y: 120);

    axleCounters['ac101'] = AxleCounter(id: 'ac101', blockId: '101', x: 100, y: 320);
    axleCounters['ac105'] = AxleCounter(id: 'ac105', blockId: '105', x: 700, y: 320);
    axleCounters['ac109'] = AxleCounter(id: 'ac109', blockId: '109', x: 850, y: 320);
    axleCounters['ac111'] = AxleCounter(id: 'ac111', blockId: '111', x: 1150, y: 320);

    // Middle section crossovers
    axleCounters['ac106'] = AxleCounter(
      id: 'ac106',
      blockId: 'crossover106',
      x: 630,
      y: 150,
      isTwin: false,
      twinLabel: 'ac106',
    );
    axleCounters['ac107'] = AxleCounter(
      id: 'ac107',
      blockId: 'crossover109',
      x: 770,
      y: 250,
      isTwin: false,
      twinLabel: 'ac107',
    );

    // RIGHT SECTION AXLE COUNTERS (300-319) - Extended with buffer stops
    // Upper track (300-318) eastbound
    axleCounters['ac300'] = AxleCounter(id: 'ac300', blockId: '300', x: 1700, y: 120);
    axleCounters['ac302'] = AxleCounter(id: 'ac302', blockId: '302', x: 1900, y: 120);
    axleCounters['ac304'] = AxleCounter(id: 'ac304', blockId: '304', x: 2100, y: 120);
    axleCounters['ac306'] = AxleCounter(id: 'ac306', blockId: '306', x: 2300, y: 120);
    axleCounters['ac308'] = AxleCounter(id: 'ac308', blockId: '308', x: 2500, y: 120);
    axleCounters['ac310'] = AxleCounter(id: 'ac310', blockId: '310', x: 2700, y: 120);
    axleCounters['ac312'] = AxleCounter(id: 'ac312', blockId: '312', x: 2900, y: 120);
    axleCounters['ac314'] = AxleCounter(id: 'ac314', blockId: '314', x: 3100, y: 120);
    axleCounters['ac316'] = AxleCounter(id: 'ac316', blockId: '316', x: 3250, y: 120);
    axleCounters['ac318'] = AxleCounter(id: 'ac318', blockId: '318', x: 3350, y: 120);

    // Lower track (301-319) westbound
    axleCounters['ac301'] = AxleCounter(id: 'ac301', blockId: '301', x: 1700, y: 320);
    axleCounters['ac303'] = AxleCounter(id: 'ac303', blockId: '303', x: 1900, y: 320);
    axleCounters['ac305'] = AxleCounter(id: 'ac305', blockId: '305', x: 2100, y: 320);
    axleCounters['ac307'] = AxleCounter(id: 'ac307', blockId: '307', x: 2300, y: 320);
    axleCounters['ac309'] = AxleCounter(id: 'ac309', blockId: '309', x: 2500, y: 320);
    axleCounters['ac311'] = AxleCounter(id: 'ac311', blockId: '311', x: 2700, y: 320);
    axleCounters['ac313'] = AxleCounter(id: 'ac313', blockId: '313', x: 2900, y: 320);
    axleCounters['ac315'] = AxleCounter(id: 'ac315', blockId: '315', x: 3100, y: 320);
    axleCounters['ac317'] = AxleCounter(id: 'ac317', blockId: '317', x: 3250, y: 320);
    axleCounters['ac319'] = AxleCounter(id: 'ac319', blockId: '319', x: 3350, y: 320);

    // Right section crossover - UPDATED to match renamed crossover
    axleCounters['ac_cx303_304'] = AxleCounter(id: 'ac_cx303_304', blockId: 'crossover_303_304', x: 1975, y: 200);

    _logEvent('🔢 Initialized ${axleCounters.length} axle counters across all sections');
  }

  void _initializeClock() {
    _currentTime = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentTime = DateTime.now();
      notifyListeners();
    });
  }

  void _initializeTimetable() {
    // Create a default timetable with sample services
    final now = DateTime.now();
    // Timetable starts empty - user must add trains manually
    // Service trains 001, 002, 003 removed as per user request
    timetable = Timetable(
      services: [
        // No default services - user adds trains manually
      ],
    );
  }

  void toggleTimetableActive() {
    timetableActive = !timetableActive;

    if (timetableActive) {
      _startTimetableService();
      _logEvent('📅 Timetable service activated');
    } else {
      _stopTimetableService();
      _logEvent('📅 Timetable service deactivated');
    }
    notifyListeners();
  }

  void _startTimetableService() {
    _timetableTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _processTimetable();
    });
  }

  void _stopTimetableService() {
    _timetableTimer?.cancel();
    _timetableTimer = null;
  }

  void _processTimetable() {
    if (timetable == null || !timetableActive) return;

    final now = DateTime.now();

    // Update ghost trains
    _updateGhostTrains();

    // Update early/late timers for assigned trains
    _updateEarlyLateTimers();

    // Handle automated timetable train behaviors
    _processAutomatedTimetableTrains();

    for (var service in timetable!.services) {
      if (service.isCompleted) continue;

      // Check if it's time to dispatch this service
      if (now.isAfter(service.scheduledTime) &&
          service.assignedTrainId == null) {
        _dispatchTimetableService(service);
      }

      // Check if assigned train has completed journey
      if (service.assignedTrainId != null) {
        try {
          final train = trains.firstWhere((t) => t.id == service.assignedTrainId);
          if (train.currentBlockId == service.endBlock && train.speed == 0) {
            service.isCompleted = true;
            _logEvent('✅ ${service.trainName} service completed');
          }
        } catch (e) {
          // Train not found, possibly removed
        }
      }
    }
  }

  void _updateGhostTrains() {
    if (ghostTrains.isEmpty) return;

    for (var ghost in ghostTrains) {
      if (ghost.hasCompletedService) continue;

      // Simulate ghost train movement (2.0 speed)
      ghost.x += 2.0 * ghost.direction * simulationSpeed;

      // Update current block
      _updateGhostTrainBlock(ghost);

      // Check platform arrival
      _checkGhostTrainPlatformArrival(ghost);

      // Handle platform dwell (20 seconds)
      if (ghost.doorsOpen && ghost.doorsOpenedAt != null) {
        final dwellTime = DateTime.now().difference(ghost.doorsOpenedAt!);
        if (dwellTime.inSeconds >= 20) {
          ghost.doorsOpen = false;
          ghost.doorsOpenedAt = null;
          ghost.platformArrivalTime = null;
          ghost.currentPlatformId = null;
          ghost.speed = 2.0;
        }
      }
    }
  }

  void _updateGhostTrainBlock(GhostTrain ghost) {
    for (var block in blocks.values) {
      if (ghost.x >= block.startX && ghost.x <= block.endX &&
          (ghost.y - block.y).abs() < 50) {
        ghost.currentBlockId = block.id;
        break;
      }
    }
  }

  void _checkGhostTrainPlatformArrival(GhostTrain ghost) {
    if (ghost.doorsOpen) return;

    for (var platform in platforms) {
      if (ghost.x >= platform.startX && ghost.x <= platform.endX &&
          (ghost.y - platform.y).abs() < 50) {
        // Ghost arrived at platform
        ghost.currentPlatformId = platform.id;
        ghost.platformArrivalTime = DateTime.now();
        ghost.doorsOpen = true;
        ghost.doorsOpenedAt = DateTime.now();
        ghost.speed = 0;

        // Remove from remaining stops if applicable
        if (ghost.currentBlockId != null && ghost.remainingStops.contains(ghost.currentBlockId)) {
          ghost.remainingStops.remove(ghost.currentBlockId);
        }

        break;
      }
    }
  }

  void _updateEarlyLateTimers() {
    for (var train in trains) {
      if (train.assignedTimetableId == null) continue;

      try {
        final ghost = ghostTrains.firstWhere((g) => g.id == train.assignedTimetableId);

        // Update current station
        final platformId = _getPlatformForTrain(train);
        if (platformId != null) {
          train.currentStationId = platformId;

          // Calculate early/late if at platform
          final scheduled = ghost.scheduledPlatformTimes[platformId];
          if (scheduled != null && train.speed == 0) {
            final actual = DateTime.now();
            train.earlyLateSeconds = actual.difference(scheduled).inSeconds;
          }
        }
      } catch (e) {
        // Ghost train not found
      }
    }
  }

  void _processAutomatedTimetableTrains() {
    for (var train in trains) {
      if (train.assignedTimetableId == null) continue;
      if (train.controlMode != TrainControlMode.automatic) continue;

      // Auto door management at platforms
      final atPlatform = _isTrainAtPlatform(train);
      if (atPlatform && !train.doorsOpen && train.speed == 0) {
        // Auto open doors
        train.doorsOpen = true;
        train.doorsOpenedAt = DateTime.now();
        _logEvent('🚪 ${train.name} doors auto-opened');
      }

      // Auto close doors after 20 seconds and depart
      if (train.doorsOpen && train.doorsOpenedAt != null) {
        final dwellTime = DateTime.now().difference(train.doorsOpenedAt!);
        if (dwellTime.inSeconds >= 20) {
          train.doorsOpen = false;
          train.doorsOpenedAt = null;
          train.manualStop = false;
          train.targetSpeed = 2.0;

          // Auto set next signal
          final signalAhead = _getSignalAhead(train);
          if (signalAhead != null && signalAhead.routes.isNotEmpty) {
            final route = signalAhead.routes.first;
            setRoute(signalAhead.id, route.id);
          }

          _logEvent('🚪 ${train.name} doors auto-closed, resuming journey');
        }
      }
    }
  }

  void _dispatchTimetableService(TimetableService service) {
    // Create and add train
    final blockInfo = blocks[service.startBlock];
    if (blockInfo == null) return;

    final trainId = 'AUTO-${service.id}';
    final train = Train(
      id: trainId,
      name: service.trainName,
      vin: 'VIN-${trainId}',
      trainType: service.trainType,
      x: blockInfo.startX + 20,
      y: blockInfo.y,
      speed: 0,
      targetSpeed: 0,
      direction: 1,
      color: Colors.primaries[trains.length % Colors.primaries.length],
      controlMode: service.trainType == TrainType.cbtcM1 || service.trainType == TrainType.cbtcM2
          ? TrainControlMode.automatic
          : TrainControlMode.automatic,
      isCbtcEquipped: service.trainType == TrainType.cbtcM1 || service.trainType == TrainType.cbtcM2,
      cbtcMode: service.trainType == TrainType.cbtcM1 || service.trainType == TrainType.cbtcM2
          ? CbtcMode.auto
          : CbtcMode.off,
      smcDestination: 'B:${service.endBlock}',
    );

    trains.add(train);
    service.assignedTrainId = trainId;

    // Auto-depart the train
    departAutoTrain(trainId);

    // Auto-set signals and points for the route
    _autoSetRouteForTrain(train, service);

    _logEvent('🚂 Auto-dispatched: ${service.trainName} from ${service.startBlock} to ${service.endBlock}');
    notifyListeners();
  }

  void _autoSetRouteForTrain(Train train, TimetableService service) {
    // Simple auto-route setting - set first signal ahead to green
    final signalAhead = _getSignalAhead(train);
    if (signalAhead != null && signalAhead.routes.isNotEmpty) {
      final route = signalAhead.routes.first;
      setRoute(signalAhead.id, route.id);
      _logEvent('🚦 Auto-set route ${route.id} for signal ${signalAhead.id}');
    }

    // Auto-normalize points if needed
    if (selfNormalizingPoints) {
      for (var point in points.values) {
        if (!point.locked) {
          point.position = PointPosition.normal;
        }
      }
    }
  }

  // ============================================================================
  // GHOST TRAIN AND TIMETABLE ASSIGNMENT METHODS
  // ============================================================================

  void assignTrainToTimetableSlot(String trainId, String ghostTrainId) {
    try {
      final train = trains.firstWhere((t) => t.id == trainId);
      final ghost = ghostTrains.firstWhere((g) => g.id == ghostTrainId);

      if (!ghost.isAvailable) {
        _logEvent('⚠️ Ghost train $ghostTrainId is not available');
        return;
      }

      // Assign train to ghost slot
      train.assignedTimetableId = ghostTrainId;
      train.assignedServiceId = ghost.serviceId;
      ghost.assignedRealTrainId = trainId;

      _logEvent('📋 ${train.name} assigned to timetable slot $ghostTrainId (${ghost.name})');
      notifyListeners();
    } catch (e) {
      _logEvent('❌ Failed to assign train to timetable: $e');
    }
  }

  void unassignTrainFromTimetable(String trainId) {
    try {
      final train = trains.firstWhere((t) => t.id == trainId);

      if (train.assignedTimetableId == null) {
        _logEvent('⚠️ ${train.name} is not assigned to timetable');
        return;
      }

      // Find and clear ghost train assignment
      final ghost = ghostTrains.firstWhere(
        (g) => g.id == train.assignedTimetableId,
        orElse: () => throw Exception('Ghost train not found'),
      );

      ghost.assignedRealTrainId = null;
      final oldSlot = train.assignedTimetableId;

      // Clear train assignment
      train.assignedTimetableId = null;
      train.assignedServiceId = null;
      train.earlyLateSeconds = null;
      train.currentStationId = null;

      _logEvent('📋 ${train.name} unassigned from timetable slot $oldSlot');
      notifyListeners();
    } catch (e) {
      _logEvent('❌ Failed to unassign train from timetable: $e');
    }
  }

  void reassignTrainToTimetableSlot(String trainId, String newGhostTrainId) {
    try {
      final train = trains.firstWhere((t) => t.id == trainId);

      // Unassign from current slot if any
      if (train.assignedTimetableId != null) {
        unassignTrainFromTimetable(trainId);
      }

      // Assign to new slot
      assignTrainToTimetableSlot(trainId, newGhostTrainId);
    } catch (e) {
      _logEvent('❌ Failed to reassign train: $e');
    }
  }

  List<GhostTrain> getAvailableGhostTrains() {
    return ghostTrains.where((g) => g.isAvailable).toList();
  }

  void generateGhostTrainsForAllServices() {
    ghostTrains.clear();

    if (timetable == null) return;

    int ghostId = 1;
    final now = DateTime.now();

    for (var service in timetable!.services) {
      // Generate multiple ghost trains for continuous service
      // Create ghost trains every 2 minutes for each service
      for (int i = 0; i < 10; i++) {
        final scheduledDeparture = service.scheduledTime.add(Duration(minutes: i * 2));

        // Map platform IDs from stop blocks
        final Map<String, DateTime> platformTimes = {};
        for (int stopIndex = 0; stopIndex < service.stops.length; stopIndex++) {
          final stopBlock = service.stops[stopIndex];
          final platform = _getPlatformForBlock(stopBlock);
          if (platform != null) {
            // Estimate arrival time: 30 seconds per stop
            platformTimes[platform.id] = scheduledDeparture.add(Duration(seconds: stopIndex * 30));
          }
        }

        final startBlock = blocks[service.startBlock];
        if (startBlock == null) continue;

        final ghost = GhostTrain(
          id: 'GHOST-${service.id}-$ghostId',
          serviceId: service.id,
          name: '${service.trainName} #$ghostId',
          trainType: service.trainType,
          x: startBlock.startX + 20,
          y: startBlock.y,
          speed: 0,
          direction: startBlock.y == 100 ? 1 : -1,
          remainingStops: List.from(service.stops),
          scheduledPlatformTimes: platformTimes,
        );

        ghostTrains.add(ghost);
        ghostId++;
      }
    }

    _logEvent('👻 Generated ${ghostTrains.length} ghost trains for ${timetable!.services.length} services');
    notifyListeners();
  }

  Platform? _getPlatformForBlock(String blockId) {
    final block = blocks[blockId];
    if (block == null) return null;

    for (var platform in platforms) {
      if ((block.startX >= platform.startX && block.startX <= platform.endX) ||
          (block.endX >= platform.startX && block.endX <= platform.endX)) {
        if ((block.y - platform.y).abs() < 50) {
          return platform;
        }
      }
    }
    return null;
  }

  void _initializeLayout() {
    _initializeAxleCounters();

    // MIRRORED TERMINAL STATION DESIGN - 3 sections with continuous loop
    // Total canvas: 3200 units wide (-1600 to 3200)

    // ═══════════════════════════════════════════════════════════════════════
    // LEFT SECTION (-1800 to 0) - Extended with buffer stops
    // ═══════════════════════════════════════════════════════════════════════
    // Upper track (y=100) - Eastbound →
    blocks['198'] = BlockSection(id: '198', startX: -1800, endX: -1700, y: 100);  // NEW: Buffer approach
    blocks['196'] = BlockSection(id: '196', startX: -1700, endX: -1600, y: 100);  // NEW: Buffer stop
    blocks['200'] = BlockSection(id: '200', startX: -1600, endX: -1400, y: 100);
    blocks['202'] = BlockSection(id: '202', startX: -1400, endX: -1200, y: 100);
    blocks['204'] = BlockSection(id: '204', startX: -1200, endX: -1000, y: 100);
    blocks['206'] = BlockSection(id: '206', startX: -1000, endX: -800, y: 100);
    blocks['208'] = BlockSection(id: '208', startX: -800, endX: -600, y: 100);
    blocks['210'] = BlockSection(id: '210', startX: -600, endX: -400, y: 100);
    blocks['212'] = BlockSection(id: '212', startX: -400, endX: -200, y: 100);
    blocks['214'] = BlockSection(id: '214', startX: -200, endX: 0, y: 100);

    // Lower track (y=300) - Westbound ←
    blocks['199'] = BlockSection(id: '199', startX: -1800, endX: -1700, y: 300);  // NEW: Buffer approach
    blocks['197'] = BlockSection(id: '197', startX: -1700, endX: -1600, y: 300);  // NEW: Buffer stop
    blocks['201'] = BlockSection(id: '201', startX: -1600, endX: -1400, y: 300);
    blocks['203'] = BlockSection(id: '203', startX: -1400, endX: -1200, y: 300);
    blocks['205'] = BlockSection(id: '205', startX: -1200, endX: -1000, y: 300);
    blocks['207'] = BlockSection(id: '207', startX: -1000, endX: -800, y: 300);
    blocks['209'] = BlockSection(id: '209', startX: -800, endX: -600, y: 300);
    blocks['211'] = BlockSection(id: '211', startX: -600, endX: -400, y: 300);
    blocks['213'] = BlockSection(id: '213', startX: -400, endX: -200, y: 300);
    blocks['215'] = BlockSection(id: '215', startX: -200, endX: 0, y: 300);

    // ═══════════════════════════════════════════════════════════════════════
    // MIDDLE SECTION (0 to 1600) - Original terminal (KEEP AS IS)
    // ═══════════════════════════════════════════════════════════════════════
    // Upper track (y=100) - Eastbound →
    blocks['100'] = BlockSection(id: '100', startX: 0, endX: 200, y: 100);
    blocks['102'] = BlockSection(id: '102', startX: 200, endX: 400, y: 100);
    blocks['104'] = BlockSection(id: '104', startX: 400, endX: 600, y: 100);
    blocks['106'] = BlockSection(id: '106', startX: 600, endX: 800, y: 100);
    blocks['108'] = BlockSection(id: '108', startX: 800, endX: 1000, y: 100);
    blocks['110'] = BlockSection(id: '110', startX: 1000, endX: 1200, y: 100);
    blocks['112'] = BlockSection(id: '112', startX: 1200, endX: 1400, y: 100);
    blocks['114'] = BlockSection(id: '114', startX: 1400, endX: 1600, y: 100);

    // Lower track (y=300) - Westbound ←
    blocks['101'] = BlockSection(id: '101', startX: 0, endX: 200, y: 300);
    blocks['103'] = BlockSection(id: '103', startX: 200, endX: 400, y: 300);
    blocks['105'] = BlockSection(id: '105', startX: 400, endX: 600, y: 300);
    blocks['107'] = BlockSection(id: '107', startX: 600, endX: 800, y: 300);
    blocks['109'] = BlockSection(id: '109', startX: 800, endX: 1000, y: 300);
    blocks['111'] = BlockSection(id: '111', startX: 1000, endX: 1200, y: 300);
    blocks['113'] = BlockSection(id: '113', startX: 1200, endX: 1400, y: 300);
    blocks['115'] = BlockSection(id: '115', startX: 1400, endX: 1600, y: 300);

    // ═══════════════════════════════════════════════════════════════════════
    // RIGHT SECTION (1600 to 3400) - Extended with buffer stops
    // ═══════════════════════════════════════════════════════════════════════
    // Upper track (y=100) - Eastbound →
    blocks['300'] = BlockSection(id: '300', startX: 1600, endX: 1800, y: 100);
    blocks['302'] = BlockSection(id: '302', startX: 1800, endX: 2000, y: 100);
    blocks['304'] = BlockSection(id: '304', startX: 2000, endX: 2200, y: 100);
    blocks['306'] = BlockSection(id: '306', startX: 2200, endX: 2400, y: 100);
    blocks['308'] = BlockSection(id: '308', startX: 2400, endX: 2600, y: 100);
    blocks['310'] = BlockSection(id: '310', startX: 2600, endX: 2800, y: 100);
    blocks['312'] = BlockSection(id: '312', startX: 2800, endX: 3000, y: 100);
    blocks['314'] = BlockSection(id: '314', startX: 3000, endX: 3200, y: 100);
    blocks['316'] = BlockSection(id: '316', startX: 3200, endX: 3300, y: 100);  // NEW: Buffer approach
    blocks['318'] = BlockSection(id: '318', startX: 3300, endX: 3400, y: 100);  // NEW: Buffer stop

    // Lower track (y=300) - Westbound ←
    blocks['301'] = BlockSection(id: '301', startX: 1600, endX: 1800, y: 300);
    blocks['303'] = BlockSection(id: '303', startX: 1800, endX: 2000, y: 300);
    blocks['305'] = BlockSection(id: '305', startX: 2000, endX: 2200, y: 300);
    blocks['307'] = BlockSection(id: '307', startX: 2200, endX: 2400, y: 300);
    blocks['309'] = BlockSection(id: '309', startX: 2400, endX: 2600, y: 300);
    blocks['311'] = BlockSection(id: '311', startX: 2600, endX: 2800, y: 300);
    blocks['313'] = BlockSection(id: '313', startX: 2800, endX: 3000, y: 300);
    blocks['315'] = BlockSection(id: '315', startX: 3000, endX: 3200, y: 300);
    blocks['317'] = BlockSection(id: '317', startX: 3200, endX: 3300, y: 300);  // NEW: Buffer approach
    blocks['319'] = BlockSection(id: '319', startX: 3300, endX: 3400, y: 300);  // NEW: Buffer stop

    // ═══════════════════════════════════════════════════════════════════════
    // CROSSOVERS - 4 total for flexible routing
    // ═══════════════════════════════════════════════════════════════════════
    // Left Section Crossover (connects blocks 211↔212) - MOVED from 206-207 area
    // Allows train from block 209→211 (lower track) to cross to block 212 (upper track)
    blocks['crossover_211_212'] = BlockSection(
      id: 'crossover_211_212',
      name: 'West Terminal Double Diamond',
      startX: -450,
      endX: -300,
      y: 200,
    );

    // Middle Crossover (original 78A/78B)
    blocks['crossover106'] = BlockSection(
      id: 'crossover106',
      name: 'Central Station Crossover Upper',
      startX: 600,
      endX: 700,
      y: 150,
    );
    blocks['crossover109'] = BlockSection(
      id: 'crossover109',
      name: 'Central Station Crossover Lower',
      startX: 700,
      endX: 800,
      y: 250,
    );

    // Right Section Crossover (connects blocks 303↔304) - MOVED from 314 area
    // Allows train from block 301→303 (lower track) to cross to block 304 (upper track)
    blocks['crossover_303_304'] = BlockSection(
      id: 'crossover_303_304',
      name: 'East Terminal Double Diamond',
      startX: 1900,
      endX: 2050,
      y: 200,
    );

    // ═══════════════════════════════════════════════════════════════════════
    // POINTS - 10 points total (4 for each double diamond crossover + 2 for middle)
    // ═══════════════════════════════════════════════════════════════════════

    // Left section points - DOUBLE DIAMOND CROSSOVER (4 points)
    // 45-degree crossovers with proper 200-unit span for correct geometry
    points['76A'] = Point(id: '76A', x: -550, y: 100);  // Start of double diamond
    points['76B'] = Point(id: '76B', x: -550, y: 300);  // Start of double diamond
    points['77A'] = Point(id: '77A', x: -350, y: 100);  // End of double diamond (200 units span)
    points['77B'] = Point(id: '77B', x: -350, y: 300);  // End of double diamond (200 units span)

    // Middle points (crossover106/109) - Standard crossover
    points['78A'] = Point(id: '78A', x: 600, y: 100);
    points['78B'] = Point(id: '78B', x: 800, y: 300);

    // Right section points - DOUBLE DIAMOND CROSSOVER (4 points)
    // 45-degree crossovers with proper 200-unit span for correct geometry
    points['79A'] = Point(id: '79A', x: 1900, y: 100);  // Start of double diamond
    points['79B'] = Point(id: '79B', x: 1900, y: 300);  // Start of double diamond
    points['80A'] = Point(id: '80A', x: 2100, y: 100);  // End of double diamond (200 units span)
    points['80B'] = Point(id: '80B', x: 2100, y: 300);  // End of double diamond (200 units span)

    // ═══════════════════════════════════════════════════════════════════════
    // PLATFORMS - 6 total (2 at each location)
    // ═══════════════════════════════════════════════════════════════════════
    // Left End Station
    platforms.add(Platform(
        id: 'P1', name: 'West Terminal Platform 1', startX: -1200, endX: -800, y: 100));
    platforms.add(Platform(
        id: 'P2', name: 'West Terminal Platform 2', startX: -1200, endX: -800, y: 300));

    // Middle Station (original)
    platforms.add(Platform(
        id: 'P3', name: 'Central Terminal Platform 1', startX: 800, endX: 1200, y: 100));
    platforms.add(Platform(
        id: 'P4', name: 'Central Terminal Platform 2', startX: 1000, endX: 1200, y: 300));  // FIXED: Moved to x: 1000

    // Right End Station
    platforms.add(Platform(
        id: 'P5', name: 'East Terminal Platform 1', startX: 2400, endX: 2800, y: 100));
    platforms.add(Platform(
        id: 'P6', name: 'East Terminal Platform 2', startX: 2400, endX: 2800, y: 300));

    // ═══════════════════════════════════════════════════════════════════════
    // SIGNALS - Comprehensive coverage across all 3 sections
    // ═══════════════════════════════════════════════════════════════════════

    // LEFT SECTION SIGNALS (200-215)
    // Upper track eastbound signals
    signals['L01'] = Signal(
      id: 'L01',
      x: -1710,  // FIXED: 10 units from end of block 198 (before block 200)
      y: 80,
      routes: [
        SignalRoute(
          id: 'L01_R1',
          name: 'West Entry',
          requiredBlocksClear: ['200', '202'],
          requiredPointPositions: {},
          pathBlocks: ['200', '202'],
          protectedBlocks: ['200', '202'],
        ),
      ],
    );

    signals['L02'] = Signal(
      id: 'L02',
      x: -1010,  // FIXED: 10 units from end of block 204 (before block 202)
      y: 320,  // FIXED: Changed to 320 to face correct direction (westbound on lower track)
      routes: [
        SignalRoute(
          id: 'L02_R1',
          name: 'West Platform 1 Departure',
          requiredBlocksClear: ['204', '206'],
          requiredPointPositions: {},
          pathBlocks: ['204', '206'],
          protectedBlocks: ['204', '206'],
        ),
      ],
    );

    signals['L03'] = Signal(
      id: 'L03',
      x: -810,  // FIXED: 10 units from end of block 206 (before block 208)
      y: 80,
      routes: [
        SignalRoute(
          id: 'L03_R1',
          name: 'To Central (Straight)',
          requiredBlocksClear: ['208', '210', '212'],
          requiredPointPositions: {'76A': PointPosition.normal, '77A': PointPosition.normal},
          pathBlocks: ['208', '210', '212'],
          protectedBlocks: ['208', '210', '212'],
        ),
        SignalRoute(
          id: 'L03_R2',
          name: 'To Central via Crossover (Diverging)',
          requiredBlocksClear: ['208', 'crossover_211_212', '211'],
          requiredPointPositions: {'76A': PointPosition.reverse, '76B': PointPosition.reverse},
          pathBlocks: ['208', 'crossover_211_212', '211'],
          protectedBlocks: ['crossover_211_212', '211'],
        ),
      ],
    );

    signals['L04'] = Signal(
      id: 'L04',
      x: -100,
      y: 320,  // FIXED: Changed to 320 to face correct direction (westbound on lower track)
      routes: [
        SignalRoute(
          id: 'L04_R1',
          name: 'West Exit',
          requiredBlocksClear: ['214', '100'],
          requiredPointPositions: {},
          pathBlocks: ['214', '100'],
          protectedBlocks: ['214', '100'],
        ),
      ],
    );

    // Lower track westbound signals
    signals['L05'] = Signal(
      id: 'L05',
      x: -200,
      y: 80,  // FIXED: Changed to 80 to face correct direction (eastbound on upper track)
      routes: [
        SignalRoute(
          id: 'L05_R1',
          name: 'From Central',
          requiredBlocksClear: ['215', '213'],
          requiredPointPositions: {},
          pathBlocks: ['215', '213'],
          protectedBlocks: ['215', '213'],
        ),
      ],
    );

    signals['L06'] = Signal(
      id: 'L06',
      x: -1010,  // FIXED: 10 units from end of block 205 (before block 203)
      y: 80,  // FIXED: Changed to 80 to face correct direction (eastbound on upper track)
      routes: [
        SignalRoute(
          id: 'L06_R1',
          name: 'West Platform 2 Departure (Straight)',
          requiredBlocksClear: ['211', '209', '207'],
          requiredPointPositions: {'76B': PointPosition.normal, '77B': PointPosition.normal},
          pathBlocks: ['211', '209', '207'],
          protectedBlocks: ['211', '209', '207'],
        ),
        SignalRoute(
          id: 'L06_R2',
          name: 'West Platform 2 via Crossover (Diverging)',
          requiredBlocksClear: ['crossover_211_212', '210', '208'],
          requiredPointPositions: {'76A': PointPosition.reverse, '77A': PointPosition.reverse},
          pathBlocks: ['crossover_211_212', '210', '208'],
          protectedBlocks: ['crossover_211_212', '210', '208'],
        ),
      ],
    );

    signals['L07'] = Signal(
      id: 'L07',
      x: -1710,  // FIXED: 10 units from end of block 199 (before block 201)
      y: 320,
      routes: [
        SignalRoute(
          id: 'L07_R1',
          name: 'West Loop',
          requiredBlocksClear: ['205', '203', '201'],
          requiredPointPositions: {},  // FIXED: Removed reference to deleted point 76B
          pathBlocks: ['205', '203', '201'],
          protectedBlocks: ['205', '203', '201'],
        ),
      ],
    );

    // MIDDLE SECTION SIGNALS (100-115)
    // Upper track eastbound signals
    signals['C31'] = Signal(
      id: 'C31',
      x: 390,
      y: 80,
      routes: [
        SignalRoute(
          id: 'C31_R1',
          name: 'Main Route (Straight)',
          requiredBlocksClear: ['106', '108', '110'],
          requiredPointPositions: {'78A': PointPosition.normal},
          pathBlocks: ['104', '106', '108', '110'],
          protectedBlocks: ['106', '108', '110'],
        ),
        SignalRoute(
          id: 'C31_R2',
          name: 'Via Crossover (Diverging)',
          requiredBlocksClear: ['crossover106', '109', '107'],
          requiredPointPositions: {'78A': PointPosition.reverse, '78B': PointPosition.reverse},
          pathBlocks: ['104', 'crossover106', '109', '107'],
          protectedBlocks: ['crossover106', '109', '107'],
        ),
      ],
    );

    signals['C33'] = Signal(
      id: 'C33',
      x: 1190,  // FIXED: 10 units from end of block 110 (before block 112)
      y: 80,
      routes: [
        SignalRoute(
          id: 'C33_R1',
          name: 'Platform Departure',
          requiredBlocksClear: ['112', '114'],
          requiredPointPositions: {},
          pathBlocks: ['112', '114'],
          protectedBlocks: ['112', '114'],
        ),
      ],
    );

    signals['C01'] = Signal(
      id: 'C01',
      x: 50,
      y: 80,
      routes: [
        SignalRoute(
          id: 'C01_R1',
          name: 'Central Entry',
          requiredBlocksClear: ['100', '102'],
          requiredPointPositions: {},
          pathBlocks: ['100', '102'],
          protectedBlocks: ['100', '102'],
        ),
      ],
    );

    // REMOVED C02 - was within 20 units of C30 (duplicate)

    // Lower track westbound signals
    signals['C30'] = Signal(
      id: 'C30',
      x: 1000,
      y: 320,
      routes: [
        SignalRoute(
          id: 'C30_R1',
          name: 'Platform 2 Departure',
          requiredBlocksClear: ['109', '107', '105'],
          requiredPointPositions: {'78B': PointPosition.normal},
          pathBlocks: ['109', '107', '105'],
          protectedBlocks: ['109', '107', '105'],
        ),
        SignalRoute(
          id: 'C30_R2',
          name: 'To East via Crossover',
          requiredBlocksClear: ['114', '300'],
          requiredPointPositions: {'78B': PointPosition.reverse},
          pathBlocks: ['114', '300'],
          protectedBlocks: ['114', '300'],
        ),
      ],
    );

    signals['C03'] = Signal(
      id: 'C03',
      x: 1190,  // FIXED: 10 units from end of block 111 (before block 113)
      y: 320,
      routes: [
        SignalRoute(
          id: 'C03_R1',
          name: 'From East',
          requiredBlocksClear: ['115', '113'],
          requiredPointPositions: {},
          pathBlocks: ['115', '113'],
          protectedBlocks: ['115', '113'],
        ),
      ],
    );

    signals['C04'] = Signal(
      id: 'C04',
      x: 290,  // MOVED: 100 units left from 390 to avoid conflict with C31
      y: 80,  // FIXED: Changed to 80 to face correct direction (eastbound on upper track)
      routes: [
        SignalRoute(
          id: 'C04_R1',
          name: 'To West',
          requiredBlocksClear: ['101', '215'],
          requiredPointPositions: {},
          pathBlocks: ['101', '215'],
          protectedBlocks: ['101', '215'],
        ),
      ],
    );

    // RIGHT SECTION SIGNALS (300-315)
    // Upper track eastbound signals
    signals['R01'] = Signal(
      id: 'R01',
      x: 1790,  // FIXED: 10 units from end of block 300 (before block 312)
      y: 80,
      routes: [
        SignalRoute(
          id: 'R01_R1',
          name: 'East Entry (Straight)',
          requiredBlocksClear: ['300', '302'],
          requiredPointPositions: {'79A': PointPosition.normal, '80A': PointPosition.normal},
          pathBlocks: ['300', '302'],
          protectedBlocks: ['300', '302'],
        ),
        SignalRoute(
          id: 'R01_R2',
          name: 'East Entry via Crossover (Diverging)',
          requiredBlocksClear: ['crossover_303_304', '303', '301'],
          requiredPointPositions: {'79A': PointPosition.reverse, '79B': PointPosition.reverse},
          pathBlocks: ['crossover_303_304', '303', '301'],
          protectedBlocks: ['crossover_303_304', '303', '301'],
        ),
      ],
    );

    signals['R02'] = Signal(
      id: 'R02',
      x: 2590,  // FIXED: 10 units from end of block 308 (before block 306)
      y: 320,  // FIXED: Changed to 320 to face correct direction (westbound on lower track)
      routes: [
        SignalRoute(
          id: 'R02_R1',
          name: 'East Platform 1 Departure',
          requiredBlocksClear: ['304', '306'],
          requiredPointPositions: {},
          pathBlocks: ['304', '306'],
          protectedBlocks: ['304', '306'],
        ),
      ],
    );

    signals['R03'] = Signal(
      id: 'R03',
      x: 2790,  // FIXED: 10 units from end of block 310 (before block 302)
      y: 80,
      routes: [
        SignalRoute(
          id: 'R03_R1',
          name: 'To East Loop',
          requiredBlocksClear: ['308', '310', '312'],
          requiredPointPositions: {},
          pathBlocks: ['308', '310', '312'],
          protectedBlocks: ['308', '310', '312'],
        ),
      ],
    );

    signals['R04'] = Signal(
      id: 'R04',
      x: 3290,  // FIXED: 10 units from end of block 316 (before block 314)
      y: 320,  // FIXED: Changed to 320 to face correct direction (westbound on lower track)
      routes: [
        SignalRoute(
          id: 'R04_R1',
          name: 'East Loop Entry',
          requiredBlocksClear: ['314', '316'],
          requiredPointPositions: {},  // FIXED: Removed reference to deleted point 80A
          pathBlocks: ['314', '316'],
          protectedBlocks: ['314', '316'],
        ),
      ],
    );

    // Lower track westbound signals
    signals['R05'] = Signal(
      id: 'R05',
      x: 2790,  // FIXED: 10 units from end of block 311 (before block 313)
      y: 320,
      routes: [
        SignalRoute(
          id: 'R05_R1',
          name: 'From East Loop',
          requiredBlocksClear: ['315', '313'],
          requiredPointPositions: {},
          pathBlocks: ['315', '313'],
          protectedBlocks: ['315', '313'],
        ),
      ],
    );

    signals['R06'] = Signal(
      id: 'R06',
      x: 2490,  // MOVED: 100 units left from 2590 to avoid conflict with R02
      y: 320,
      routes: [
        SignalRoute(
          id: 'R06_R1',
          name: 'East Platform 2 Departure',
          requiredBlocksClear: ['311', '309', '307'],
          requiredPointPositions: {},
          pathBlocks: ['311', '309', '307'],
          protectedBlocks: ['311', '309', '307'],
        ),
      ],
    );

    signals['R07'] = Signal(
      id: 'R07',
      x: 1990,  // FIXED: 10 units from end of block 303 (before block 301)
      y: 320,
      routes: [
        SignalRoute(
          id: 'R07_R1',
          name: 'To Central (Straight)',
          requiredBlocksClear: ['305', '303', '301'],
          requiredPointPositions: {'79B': PointPosition.normal, '80B': PointPosition.normal},
          pathBlocks: ['305', '303', '301'],
          protectedBlocks: ['305', '303', '301'],
        ),
        SignalRoute(
          id: 'R07_R2',
          name: 'To Central via Crossover (Diverging)',
          requiredBlocksClear: ['crossover_303_304', '304', '302'],
          requiredPointPositions: {'80A': PointPosition.reverse, '80B': PointPosition.reverse},
          pathBlocks: ['crossover_303_304', '304', '302'],
          protectedBlocks: ['crossover_303_304', '304', '302'],
        ),
      ],
    );

    signals['R08'] = Signal(
      id: 'R08',
      x: 1590,  // FIXED: 10 units from end of block 115 (before block 113)
      y: 80,  // FIXED: Changed to 80 to face correct direction (eastbound on upper track)
      routes: [
        SignalRoute(
          id: 'R08_R1',
          name: 'East Exit',
          requiredBlocksClear: ['301', '115'],
          requiredPointPositions: {},
          pathBlocks: ['301', '115'],
          protectedBlocks: ['301', '115'],
        ),
      ],
    );

    // TRAIN STOPS for all signals - UPDATED to match new signal positions
    trainStops['TL01'] = TrainStop(id: 'TL01', signalId: 'L01', x: -1710, y: 120);
    trainStops['TL02'] = TrainStop(id: 'TL02', signalId: 'L02', x: -1010, y: 340);
    trainStops['TL03'] = TrainStop(id: 'TL03', signalId: 'L03', x: -810, y: 120);
    trainStops['TL04'] = TrainStop(id: 'TL04', signalId: 'L04', x: -100, y: 340);
    trainStops['TL05'] = TrainStop(id: 'TL05', signalId: 'L05', x: -200, y: 120);
    trainStops['TL06'] = TrainStop(id: 'TL06', signalId: 'L06', x: -1010, y: 120);
    trainStops['TL07'] = TrainStop(id: 'TL07', signalId: 'L07', x: -1710, y: 340);

    trainStops['T31'] = TrainStop(id: 'T31', signalId: 'C31', x: 400, y: 120);
    trainStops['T33'] = TrainStop(id: 'T33', signalId: 'C33', x: 1190, y: 120);
    trainStops['T30'] = TrainStop(id: 'T30', signalId: 'C30', x: 1000, y: 340);  // FIXED: Match C30 signal x-position
    trainStops['TC01'] = TrainStop(id: 'TC01', signalId: 'C01', x: 50, y: 120);
    // REMOVED TC02 - was within 20 units of T30 (duplicate, C02 signal removed)
    trainStops['TC03'] = TrainStop(id: 'TC03', signalId: 'C03', x: 1190, y: 340);
    trainStops['TC04'] = TrainStop(id: 'TC04', signalId: 'C04', x: 290, y: 120);  // MOVED: Match C04 signal position

    trainStops['TR01'] = TrainStop(id: 'TR01', signalId: 'R01', x: 1790, y: 120);
    trainStops['TR02'] = TrainStop(id: 'TR02', signalId: 'R02', x: 2590, y: 340);
    trainStops['TR03'] = TrainStop(id: 'TR03', signalId: 'R03', x: 2790, y: 120);
    trainStops['TR04'] = TrainStop(id: 'TR04', signalId: 'R04', x: 3290, y: 340);
    trainStops['TR05'] = TrainStop(id: 'TR05', signalId: 'R05', x: 2790, y: 340);
    trainStops['TR06'] = TrainStop(id: 'TR06', signalId: 'R06', x: 2490, y: 340);  // MOVED: Match R06 signal position
    trainStops['TR07'] = TrainStop(id: 'TR07', signalId: 'R07', x: 1990, y: 340);
    trainStops['TR08'] = TrainStop(id: 'TR08', signalId: 'R08', x: 1590, y: 120);

    // ═══════════════════════════════════════════════════════════════════════
    // CBTC INFRASTRUCTURE - WiFi and Transponders with individual control
    // ═══════════════════════════════════════════════════════════════════════
    // LEFT SECTION WiFi Coverage
    wifiAntennas['W_L1'] = WifiAntenna(id: 'W_L1', x: -1500, y: 200, isActive: true);
    wifiAntennas['W_L2'] = WifiAntenna(id: 'W_L2', x: -1200, y: 200, isActive: true);
    wifiAntennas['W_L3'] = WifiAntenna(id: 'W_L3', x: -800, y: 200, isActive: true);
    wifiAntennas['W_L4'] = WifiAntenna(id: 'W_L4', x: -400, y: 200, isActive: true);
    wifiAntennas['W_L5'] = WifiAntenna(id: 'W_L5', x: -100, y: 200, isActive: true);

    // MIDDLE SECTION WiFi Coverage
    wifiAntennas['W_C1'] = WifiAntenna(id: 'W_C1', x: 100, y: 200, isActive: true);
    wifiAntennas['W_C2'] = WifiAntenna(id: 'W_C2', x: 400, y: 200, isActive: true);
    wifiAntennas['W_C3'] = WifiAntenna(id: 'W_C3', x: 800, y: 200, isActive: true);
    wifiAntennas['W_C4'] = WifiAntenna(id: 'W_C4', x: 1000, y: 200, isActive: true);
    wifiAntennas['W_C5'] = WifiAntenna(id: 'W_C5', x: 1400, y: 200, isActive: true);

    // RIGHT SECTION WiFi Coverage
    wifiAntennas['W_R1'] = WifiAntenna(id: 'W_R1', x: 1700, y: 200, isActive: true);
    wifiAntennas['W_R2'] = WifiAntenna(id: 'W_R2', x: 2000, y: 200, isActive: true);
    wifiAntennas['W_R3'] = WifiAntenna(id: 'W_R3', x: 2400, y: 200, isActive: true);
    wifiAntennas['W_R4'] = WifiAntenna(id: 'W_R4', x: 2600, y: 200, isActive: true);
    wifiAntennas['W_R5'] = WifiAntenna(id: 'W_R5', x: 3000, y: 200, isActive: true);

    // ═══════════════════════════════════════════════════════════════════════
    // TRANSPONDER TAGS - Comprehensive CBTC positioning system
    // ═══════════════════════════════════════════════════════════════════════

    // T6: Accurate stopping tags - 25 units from end of each platform
    // West Terminal Platforms (endX: -800)
    transponders['T6_P1'] = Transponder(id: 'T6_P1', type: TransponderType.t6, x: -800 + 25, y: 100, description: 'T6 - Accurate Stopping Tag P1');
    transponders['T6_P2'] = Transponder(id: 'T6_P2', type: TransponderType.t6, x: -800 + 25, y: 300, description: 'T6 - Accurate Stopping Tag P2');

    // Central Terminal Platforms (endX: 1200)
    transponders['T6_P3'] = Transponder(id: 'T6_P3', type: TransponderType.t6, x: 1200 + 25, y: 100, description: 'T6 - Accurate Stopping Tag P3');
    transponders['T6_P4'] = Transponder(id: 'T6_P4', type: TransponderType.t6, x: 1200 + 25, y: 300, description: 'T6 - Accurate Stopping Tag P4');

    // East Terminal Platforms (endX: 2800)
    transponders['T6_P5'] = Transponder(id: 'T6_P5', type: TransponderType.t6, x: 2800 + 25, y: 100, description: 'T6 - Accurate Stopping Tag P5');
    transponders['T6_P6'] = Transponder(id: 'T6_P6', type: TransponderType.t6, x: 2800 + 25, y: 300, description: 'T6 - Accurate Stopping Tag P6');

    // T1 tags at extreme ends (before stations)
    transponders['T1_WEST_END_UP'] = Transponder(id: 'T1_WEST_END_UP', type: TransponderType.t1, x: -1400, y: 100, description: 'T1 - West End Tag Upper');
    transponders['T1_WEST_END_LOW'] = Transponder(id: 'T1_WEST_END_LOW', type: TransponderType.t1, x: -1400, y: 300, description: 'T1 - West End Tag Lower');
    transponders['T1_EAST_END_UP'] = Transponder(id: 'T1_EAST_END_UP', type: TransponderType.t1, x: 3000, y: 100, description: 'T1 - East End Tag Upper');
    transponders['T1_EAST_END_LOW'] = Transponder(id: 'T1_EAST_END_LOW', type: TransponderType.t1, x: 3000, y: 300, description: 'T1 - East End Tag Lower');

    // T1 tags at crossover junctions
    // West crossover (-550 to -450)
    transponders['T1_XO_WEST_1'] = Transponder(id: 'T1_XO_WEST_1', type: TransponderType.t1, x: -550, y: 100, description: 'T1 - West Crossover Tag');
    transponders['T1_XO_WEST_2'] = Transponder(id: 'T1_XO_WEST_2', type: TransponderType.t1, x: -550, y: 300, description: 'T1 - West Crossover Tag');
    transponders['T1_XO_WEST_3'] = Transponder(id: 'T1_XO_WEST_3', type: TransponderType.t1, x: -450, y: 100, description: 'T1 - West Crossover Tag');
    transponders['T1_XO_WEST_4'] = Transponder(id: 'T1_XO_WEST_4', type: TransponderType.t1, x: -450, y: 300, description: 'T1 - West Crossover Tag');

    // Middle crossover (600 to 800)
    transponders['T1_XO_MID_1'] = Transponder(id: 'T1_XO_MID_1', type: TransponderType.t1, x: 600, y: 100, description: 'T1 - Middle Crossover Tag');
    transponders['T1_XO_MID_2'] = Transponder(id: 'T1_XO_MID_2', type: TransponderType.t1, x: 600, y: 300, description: 'T1 - Middle Crossover Tag');
    transponders['T1_XO_MID_3'] = Transponder(id: 'T1_XO_MID_3', type: TransponderType.t1, x: 800, y: 100, description: 'T1 - Middle Crossover Tag');
    transponders['T1_XO_MID_4'] = Transponder(id: 'T1_XO_MID_4', type: TransponderType.t1, x: 800, y: 300, description: 'T1 - Middle Crossover Tag');

    // East crossover (1900 to 2000)
    transponders['T1_XO_EAST_1'] = Transponder(id: 'T1_XO_EAST_1', type: TransponderType.t1, x: 1900, y: 100, description: 'T1 - East Crossover Tag');
    transponders['T1_XO_EAST_2'] = Transponder(id: 'T1_XO_EAST_2', type: TransponderType.t1, x: 1900, y: 300, description: 'T1 - East Crossover Tag');
    transponders['T1_XO_EAST_3'] = Transponder(id: 'T1_XO_EAST_3', type: TransponderType.t1, x: 2000, y: 100, description: 'T1 - East Crossover Tag');
    transponders['T1_XO_EAST_4'] = Transponder(id: 'T1_XO_EAST_4', type: TransponderType.t1, x: 2000, y: 300, description: 'T1 - East Crossover Tag');

    // Transponder pattern between West and Central stations
    // Pattern: T1, T1, T1, T2 (cross border), T3 (border), T2 (cross border), T1, T1, T1
    // Distance from West end of P1 (-800) to Central start of P3 (800) = 1600 units
    final westToCentralDist = 1600.0;
    final westToCentralStart = -800.0 + 25; // After P1 T6 tag
    final spacing1 = westToCentralDist / 10; // Divide into 10 segments for 9 tags

    transponders['T1_WC_1_UP'] = Transponder(id: 'T1_WC_1_UP', type: TransponderType.t1, x: westToCentralStart + spacing1 * 1, y: 100, description: 'T1 - Crossover Tag');
    transponders['T1_WC_1_LOW'] = Transponder(id: 'T1_WC_1_LOW', type: TransponderType.t1, x: westToCentralStart + spacing1 * 1, y: 300, description: 'T1 - Crossover Tag');

    transponders['T1_WC_2_UP'] = Transponder(id: 'T1_WC_2_UP', type: TransponderType.t1, x: westToCentralStart + spacing1 * 2, y: 100, description: 'T1 - Crossover Tag');
    transponders['T1_WC_2_LOW'] = Transponder(id: 'T1_WC_2_LOW', type: TransponderType.t1, x: westToCentralStart + spacing1 * 2, y: 300, description: 'T1 - Crossover Tag');

    transponders['T1_WC_3_UP'] = Transponder(id: 'T1_WC_3_UP', type: TransponderType.t1, x: westToCentralStart + spacing1 * 3, y: 100, description: 'T1 - Crossover Tag');
    transponders['T1_WC_3_LOW'] = Transponder(id: 'T1_WC_3_LOW', type: TransponderType.t1, x: westToCentralStart + spacing1 * 3, y: 300, description: 'T1 - Crossover Tag');

    transponders['T2_WC_1_UP'] = Transponder(id: 'T2_WC_1_UP', type: TransponderType.t2, x: westToCentralStart + spacing1 * 4, y: 100, description: 'T2 - Cross Border Tag');
    transponders['T2_WC_1_LOW'] = Transponder(id: 'T2_WC_1_LOW', type: TransponderType.t2, x: westToCentralStart + spacing1 * 4, y: 300, description: 'T2 - Cross Border Tag');

    transponders['T3_WC_UP'] = Transponder(id: 'T3_WC_UP', type: TransponderType.t3, x: westToCentralStart + spacing1 * 5, y: 100, description: 'T3 - Border Tag');
    transponders['T3_WC_LOW'] = Transponder(id: 'T3_WC_LOW', type: TransponderType.t3, x: westToCentralStart + spacing1 * 5, y: 300, description: 'T3 - Border Tag');

    transponders['T2_WC_2_UP'] = Transponder(id: 'T2_WC_2_UP', type: TransponderType.t2, x: westToCentralStart + spacing1 * 6, y: 100, description: 'T2 - Cross Border Tag');
    transponders['T2_WC_2_LOW'] = Transponder(id: 'T2_WC_2_LOW', type: TransponderType.t2, x: westToCentralStart + spacing1 * 6, y: 300, description: 'T2 - Cross Border Tag');

    transponders['T1_WC_4_UP'] = Transponder(id: 'T1_WC_4_UP', type: TransponderType.t1, x: westToCentralStart + spacing1 * 7, y: 100, description: 'T1 - Crossover Tag');
    transponders['T1_WC_4_LOW'] = Transponder(id: 'T1_WC_4_LOW', type: TransponderType.t1, x: westToCentralStart + spacing1 * 7, y: 300, description: 'T1 - Crossover Tag');

    transponders['T1_WC_5_UP'] = Transponder(id: 'T1_WC_5_UP', type: TransponderType.t1, x: westToCentralStart + spacing1 * 8, y: 100, description: 'T1 - Crossover Tag');
    transponders['T1_WC_5_LOW'] = Transponder(id: 'T1_WC_5_LOW', type: TransponderType.t1, x: westToCentralStart + spacing1 * 8, y: 300, description: 'T1 - Crossover Tag');

    transponders['T1_WC_6_UP'] = Transponder(id: 'T1_WC_6_UP', type: TransponderType.t1, x: westToCentralStart + spacing1 * 9, y: 100, description: 'T1 - Crossover Tag');
    transponders['T1_WC_6_LOW'] = Transponder(id: 'T1_WC_6_LOW', type: TransponderType.t1, x: westToCentralStart + spacing1 * 9, y: 300, description: 'T1 - Crossover Tag');

    // Transponder pattern between Central and East stations
    // Distance from Central end of P3 (1200) to East start of P5 (2400) = 1200 units
    final centralToEastDist = 1200.0;
    final centralToEastStart = 1200.0 + 25; // After P3 T6 tag
    final spacing2 = centralToEastDist / 10;

    transponders['T1_CE_1_UP'] = Transponder(id: 'T1_CE_1_UP', type: TransponderType.t1, x: centralToEastStart + spacing2 * 1, y: 100, description: 'T1 - Crossover Tag');
    transponders['T1_CE_1_LOW'] = Transponder(id: 'T1_CE_1_LOW', type: TransponderType.t1, x: centralToEastStart + spacing2 * 1, y: 300, description: 'T1 - Crossover Tag');

    transponders['T1_CE_2_UP'] = Transponder(id: 'T1_CE_2_UP', type: TransponderType.t1, x: centralToEastStart + spacing2 * 2, y: 100, description: 'T1 - Crossover Tag');
    transponders['T1_CE_2_LOW'] = Transponder(id: 'T1_CE_2_LOW', type: TransponderType.t1, x: centralToEastStart + spacing2 * 2, y: 300, description: 'T1 - Crossover Tag');

    transponders['T1_CE_3_UP'] = Transponder(id: 'T1_CE_3_UP', type: TransponderType.t1, x: centralToEastStart + spacing2 * 3, y: 100, description: 'T1 - Crossover Tag');
    transponders['T1_CE_3_LOW'] = Transponder(id: 'T1_CE_3_LOW', type: TransponderType.t1, x: centralToEastStart + spacing2 * 3, y: 300, description: 'T1 - Crossover Tag');

    transponders['T2_CE_1_UP'] = Transponder(id: 'T2_CE_1_UP', type: TransponderType.t2, x: centralToEastStart + spacing2 * 4, y: 100, description: 'T2 - Cross Border Tag');
    transponders['T2_CE_1_LOW'] = Transponder(id: 'T2_CE_1_LOW', type: TransponderType.t2, x: centralToEastStart + spacing2 * 4, y: 300, description: 'T2 - Cross Border Tag');

    transponders['T3_CE_UP'] = Transponder(id: 'T3_CE_UP', type: TransponderType.t3, x: centralToEastStart + spacing2 * 5, y: 100, description: 'T3 - Border Tag');
    transponders['T3_CE_LOW'] = Transponder(id: 'T3_CE_LOW', type: TransponderType.t3, x: centralToEastStart + spacing2 * 5, y: 300, description: 'T3 - Border Tag');

    transponders['T2_CE_2_UP'] = Transponder(id: 'T2_CE_2_UP', type: TransponderType.t2, x: centralToEastStart + spacing2 * 6, y: 100, description: 'T2 - Cross Border Tag');
    transponders['T2_CE_2_LOW'] = Transponder(id: 'T2_CE_2_LOW', type: TransponderType.t2, x: centralToEastStart + spacing2 * 6, y: 300, description: 'T2 - Cross Border Tag');

    transponders['T1_CE_4_UP'] = Transponder(id: 'T1_CE_4_UP', type: TransponderType.t1, x: centralToEastStart + spacing2 * 7, y: 100, description: 'T1 - Crossover Tag');
    transponders['T1_CE_4_LOW'] = Transponder(id: 'T1_CE_4_LOW', type: TransponderType.t1, x: centralToEastStart + spacing2 * 7, y: 300, description: 'T1 - Crossover Tag');

    transponders['T1_CE_5_UP'] = Transponder(id: 'T1_CE_5_UP', type: TransponderType.t1, x: centralToEastStart + spacing2 * 8, y: 100, description: 'T1 - Crossover Tag');
    transponders['T1_CE_5_LOW'] = Transponder(id: 'T1_CE_5_LOW', type: TransponderType.t1, x: centralToEastStart + spacing2 * 8, y: 300, description: 'T1 - Crossover Tag');

    transponders['T1_CE_6_UP'] = Transponder(id: 'T1_CE_6_UP', type: TransponderType.t1, x: centralToEastStart + spacing2 * 9, y: 100, description: 'T1 - Crossover Tag');
    transponders['T1_CE_6_LOW'] = Transponder(id: 'T1_CE_6_LOW', type: TransponderType.t1, x: centralToEastStart + spacing2 * 9, y: 300, description: 'T1 - Crossover Tag');

    _logEvent(
        '🚉 MIRRORED TERMINAL STATION INITIALIZED: 3 stations, 6 platforms, ${signals.length} signals, ${points.length} points, ${blocks.length} blocks, ${trainStops.length} train stops, ${wifiAntennas.length} WiFi antennas, ${transponders.length} transponders');
  }

  // ============================================================================
  // DOUBLE DIAMOND CROSSOVER ROUTING (PLACEHOLDER - INCOMPLETE)
  // ============================================================================

  /// TODO: Implement double diamond crossover routing logic
  /// This method should handle train routing through double diamond crossovers
  ///
  /// Requirements:
  /// 1. Define point machines for 77c, 77d, 77e, 77f (left crossover)
  /// 2. Define point machines for 79c, 79d, 79e, 79f (right crossover)
  /// 3. Create diamond crossing objects (45° and 135° diamonds)
  /// 4. Define track circuits for crossover sections
  /// 5. Implement route calculation through crossovers
  /// 6. Add speed limits for different routes (straight: 80, cross: 60, turn: 40)
  /// 7. Handle point locking and route reservation
  ///
  /// Route possibilities for each crossover:
  /// - R77_EW_Straight: East-West straight through (77c:normal, 77d:normal, diamond_45)
  /// - R77_EW_Cross: East-West crossover (77c:reverse, 77d:reverse, diamond_135)
  /// - R77_NS_Straight: North-South straight (77e:normal, 77f:normal, diamond_45)
  /// - R77_NS_Cross: North-South crossover (77e:reverse, 77f:reverse, diamond_135)
  /// - R77_Turn_NW/NE/SW/SE: Turning movements
  void _initializeDoubleDiamondCrossovers() {
    // TODO: Implement point machine definitions
    // Example structure:
    // points['77c'] = Point(
    //   id: '77c',
    //   x: -575.7,
    //   y: 173.8,
    //   type: PointType.leftHand,
    //   position: PointPosition.normal,
    // );

    // TODO: Implement diamond crossing objects
    // diamonds['diamond_45_left'] = Diamond(
    //   id: 'diamond_45',
    //   angle: 45,
    //   x: -500,
    //   y: 200,
    //   speedLimit: 25,
    // );

    // TODO: Implement track circuits for crossover sections
    // blocks['TR_77A'] = BlockSection(
    //   id: 'TR_77A',
    //   startX: -600,
    //   endX: -550,
    //   y: 100,
    //   isCrossover: true,
    // );

    // TODO: Define routes through crossovers
    // This will allow trains to actually traverse the double diamond

    _logEvent('⚠️ Double diamond crossover routing NOT IMPLEMENTED - visual only');
  }

  /// TODO: Calculate route through double diamond crossover
  /// Returns the route ID if a valid path exists, null otherwise
  String? _calculateCrossoverRoute(
    String trainId,
    String fromBlock,
    String toBlock,
    String crossoverId,
  ) {
    // TODO: Implement route calculation logic
    // 1. Determine which crossover (left/middle/right)
    // 2. Check point positions required
    // 3. Verify track circuits are clear
    // 4. Return appropriate route ID (R77_EW_Straight, etc.)

    return null; // Placeholder - not implemented
  }

  /// TODO: Apply speed limit based on crossover route
  double _getCrossoverSpeedLimit(String routeId) {
    // TODO: Return appropriate speed limit based on route type
    // Straight routes: 80 m/s
    // Cross routes: 60 m/s
    // Turn routes: 40 m/s

    return 80.0; // Placeholder - default to straight route speed
  }

  // ============================================================================
  // CLOCK METHODS
  // ============================================================================

  String getCurrentTime() {
    return '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}:${_currentTime.second.toString().padLeft(2, '0')}';
  }

  String getCurrentDate() {
    return '${_currentTime.day}/${_currentTime.month}/${_currentTime.year}';
  }

  // ============================================================================
  // TRAIN STOP METHODS
  // ============================================================================

  void toggleTrainStop(String trainStopId) {
    final trainStop = trainStops[trainStopId];
    if (trainStop != null) {
      trainStop.enabled = !trainStop.enabled;
      _logEvent(
          '${trainStop.enabled ? '🔴' : '⚪'} TrainStop $trainStopId ${trainStop.enabled ? 'ENABLED' : 'DISABLED'}');
      notifyListeners();
    }
  }

  void toggleAllTrainStops() {
    trainStopsEnabled = !trainStopsEnabled;
    for (var trainStop in trainStops.values) {
      trainStop.enabled = trainStopsEnabled;
    }
    _logEvent(trainStopsEnabled
        ? '🔴 All TrainStops ENABLED'
        : '⚪ All TrainStops DISABLED');
    notifyListeners();
  }

  void _updateTrainStops() {
    for (var trainStop in trainStops.values) {
      final signal = signals[trainStop.signalId];
      if (signal != null) {
        trainStop.active = signal.aspect == SignalAspect.red;
      }
    }
  }

  void toggleAxleCounterVisibility() {
    axleCountersVisible = !axleCountersVisible;
    _logEvent(axleCountersVisible
        ? '✅ Axle counters enabled'
        : '❌ Axle counters disabled');
    notifyListeners();
  }

  void resetIndividualAB(String abId) {
    ace.resetAB(abId);
    ace.resetIndividualAB(abId);
    _logEvent('🔄 Reset $abId and associated axle counters');
    notifyListeners();
  }

  // ============================================================================
  // ROUTE RESERVATION SYSTEM
  // ============================================================================

  void _createRouteReservation(
      String signalId, String trainId, List<String> blocks) {
    final reservationId =
        '${signalId}_${trainId}_${DateTime.now().millisecondsSinceEpoch}';

    List<String> reservedBlocks = List.from(blocks);

    if (signalId == 'C31' && !reservedBlocks.contains('104')) {
      reservedBlocks.add('104');
    }

    if (signalId == 'C30' && !reservedBlocks.contains('109')) {
      reservedBlocks.add('109');
    }

    if (signalId == 'C30' &&
        trainId.contains('C30_R2') &&
        !reservedBlocks.contains('104')) {
      reservedBlocks.add('104');
    }

    final reservation = RouteReservation(
      id: reservationId,
      signalId: signalId,
      trainId: trainId,
      reservedBlocks: reservedBlocks,
      createdAt: DateTime.now(),
    );

    routeReservations[reservationId] = reservation;
    _logEvent(
        '🟢 Route reservation created: $signalId → ${reservedBlocks.join(', ')} for $trainId');
    notifyListeners();
  }

  void _clearRouteReservation(String reservationId) {
    routeReservations.remove(reservationId);
    notifyListeners();
  }

  void _clearExpiredReservations() {
    final now = DateTime.now();
    routeReservations.removeWhere((id, reservation) {
      final shouldRemove =
          now.difference(reservation.createdAt).inSeconds > 120;
      if (shouldRemove) {
        _logEvent(
            '🟡 Route reservation expired: ${reservation.signalId} for ${reservation.trainId}');
      }
      return shouldRemove;
    });
  }

  bool _isBlockReservedForTrain(String blockId, String trainId) {
    for (var reservation in routeReservations.values) {
      if (reservation.reservedBlocks.contains(blockId) &&
          reservation.trainId != trainId) {
        return true;
      }
    }
    return false;
  }

  // ============================================================================
  // POINT DEADLOCK PROTECTION
  // ============================================================================

  bool _arePointsMovable() {
    final deadlockBlocks = {'104', '106', '107', '109'};
    for (var blockId in deadlockBlocks) {
      if (blocks[blockId]?.occupied == true) {
        return false;
      }
    }
    return true;
  }

  // ============================================================================
  // DOOR CONTROL METHODS
  // ============================================================================

  bool _isTrainAtPlatform(Train train) {
    for (var platform in platforms) {
      if (train.x >= platform.startX &&
          train.x <= platform.endX &&
          (train.y - platform.y).abs() < 50) {
        return true;
      }
    }
    return false;
  }

  String? _getPlatformForTrain(Train train) {
    for (var platform in platforms) {
      if (train.x >= platform.startX &&
          train.x <= platform.endX &&
          (train.y - platform.y).abs() < 50) {
        return platform.id;
      }
    }
    return null;
  }

  void openTrainDoors(String trainId) {
    final train = trains.firstWhere((t) => t.id == trainId);
    final platformId = _getPlatformForTrain(train);

    if (platformId == null) {
      _logEvent('❌ Cannot open doors: ${train.name} is not at a platform');
      return;
    }

    if (train.doorsOpen) {
      _logEvent('⚠️ ${train.name} doors are already open at $platformId');
      return;
    }

    train.doorsOpen = true;
    train.doorsOpenedAt = DateTime.now();
    train.targetSpeed = 0;
    train.speed = 0;
    train.manualStop = true;

    _logEvent('🚪 ${train.name} doors OPENED at $platformId');
    notifyListeners();
  }

  void closeTrainDoors(String trainId) {
    final train = trains.firstWhere((t) => t.id == trainId);

    if (!train.doorsOpen) {
      _logEvent('⚠️ ${train.name} doors are already closed');
      return;
    }

    train.doorsOpen = false;
    train.doorsOpenedAt = null;
    train.manualStop = false;

    _logEvent('🚪 ${train.name} doors CLOSED');
    notifyListeners();
  }

  void toggleTrainDoors(String trainId) {
    final train = trains.firstWhere((t) => t.id == trainId);

    if (train.doorsOpen) {
      closeTrainDoors(trainId);
    } else {
      openTrainDoors(trainId);
    }
  }

  // Auto door open for trains at platforms in automatic mode
  void _checkAutoTrainDoorsAtPlatforms() {
    for (var train in trains) {
      // Only auto-open for trains in automatic mode
      if (train.controlMode != TrainControlMode.automatic) continue;

      // Skip if doors are already open
      if (train.doorsOpen) continue;

      // Check if train is at a platform
      for (var platform in platforms) {
        final atPlatform = train.x >= platform.startX &&
                          train.x <= platform.endX &&
                          (train.y - platform.y).abs() < 20;

        if (atPlatform) {
          // Check if train is stopped or nearly stopped
          if (train.speed.abs() < 0.5) {
            // Auto-open doors
            train.doorsOpen = true;
            train.doorsOpenedAt = DateTime.now();
            train.manualStop = true; // Keep train stopped while doors open
            _logEvent('🚪 ${train.name} doors AUTO-OPENED at ${platform.name}');
            notifyListeners();
            break;
          }
        }
      }
    }
  }

  void _checkDoorAutoClose() {
    final now = DateTime.now();
    for (var train in trains) {
      if (train.doorsOpen && train.doorsOpenedAt != null) {
        final duration = now.difference(train.doorsOpenedAt!);
        if (duration.inSeconds >= 20) {
          closeTrainDoors(train.id);
          _logEvent('⏰ ${train.name} doors auto-closed after 20 seconds');

          // Auto-continue journey after door closes
          if (train.manualStop) {
            train.manualStop = false;
            _logEvent('🚂 ${train.name} resuming journey after door closure');
          }
        }
      }
    }
  }

  // ============================================================================
  // COLLISION SYSTEM METHODS
  // ============================================================================

  void _checkCollisions() {
    for (var i = 0; i < trains.length; i++) {
      for (var j = i + 1; j < trains.length; j++) {
        final train1 = trains[i];
        final train2 = trains[j];

        final distance = math.sqrt(math.pow(train1.x - train2.x, 2) +
            math.pow(train1.y - train2.y, 2));

        if (distance < 80 && distance > 30) {
          _logEvent(
              '⚠️ NEAR MISS: ${train1.name} & ${train2.name} - ${distance.toStringAsFixed(1)} units apart');
        }

        if (distance < 30) {
          _handleCollision([train1.id, train2.id],
              'Block ${train1.currentBlockId ?? "Unknown"}');
          return;
        }
      }
    }
  }

  void _handleCollision(List<String> trainIds, String location) {
    final collisionId = 'COL-${DateTime.now().millisecondsSinceEpoch}';

    for (var id in trainIds) {
      final train = trains.firstWhere((t) => t.id == id);
      train.speed = 0;
      train.targetSpeed = 0;
      train.emergencyBrake = true;
    }

    final recoveryPlan = _generateRecoveryPlan(trainIds, location, collisionId);
    _activeCollisionRecoveries[collisionId] = recoveryPlan;

    final incident = _collisionSystem.analyzeCollision(
      trainsInvolved: trainIds,
      location: location,
      currentSystemState: _captureSystemState(),
    );

    currentCollisionIncident = incident;
    collisionAlarmActive = true;

    _logEvent(
        '💥 COLLISION: ${trainIds.join(" & ")} at $location - Recovery available');

    notifyListeners();
  }

  CollisionRecoveryPlan _generateRecoveryPlan(
      List<String> trainIds, String location, String collisionId) {
    final reverseInstructions = <String, String>{};
    final blocksToClear = <String>[];
    final collisionPositions = <String, double>{};
    final targetRecoveryPositions = <String, double>{};

    for (var trainId in trainIds) {
      final train = trains.firstWhere((t) => t.id == trainId);
      final safeBlock = _findSafeReverseBlock(train);
      reverseInstructions[trainId] = safeBlock;
      blocksToClear.add(train.currentBlockId ?? 'unknown');

      // Store collision position and calculate target 20 units back
      collisionPositions[trainId] = train.x;
      targetRecoveryPositions[trainId] = train.x - 20.0;
    }

    return CollisionRecoveryPlan(
      collisionId: collisionId,
      trainsInvolved: trainIds,
      reverseInstructions: reverseInstructions,
      blocksToClear: blocksToClear,
      state: CollisionRecoveryState.detected,
      collisionPositions: collisionPositions,
      targetRecoveryPositions: targetRecoveryPositions,
    );
  }

  String _findSafeReverseBlock(Train train) {
    final currentBlockId = train.currentBlockId;
    if (currentBlockId == null) return '100';

    final upperBlockSequence = [
      '100',
      '102',
      '104',
      '106',
      '108',
      '110',
      '112',
      '114'
    ];
    final lowerBlockSequence = ['105', '103', '101', '109', '107'];

    List<String> sequence =
        train.y < 200 ? upperBlockSequence : lowerBlockSequence;

    final currentIndex = sequence.indexOf(currentBlockId);

    if (currentIndex > 0) {
      return sequence[currentIndex - 1];
    }

    return train.y < 200 ? '100' : '105';
  }

  void _handleBufferCollision(String trainId) {
    final collisionId = 'BUF-${DateTime.now().millisecondsSinceEpoch}';
    final train = trains.firstWhere((t) => t.id == trainId);

    train.x = 1190;
    train.speed = 0;
    train.targetSpeed = 0;
    train.emergencyBrake = true;

    final recoveryPlan = CollisionRecoveryPlan(
      collisionId: collisionId,
      trainsInvolved: [trainId],
      reverseInstructions: {trainId: '112'},
      blocksToClear: [train.currentBlockId ?? '114'],
      state: CollisionRecoveryState.detected,
      collisionPositions: {trainId: train.x},
      targetRecoveryPositions: {trainId: train.x - 20.0},
    );
    _activeCollisionRecoveries[collisionId] = recoveryPlan;

    final incident = _collisionSystem.analyzeCollision(
      trainsInvolved: [trainId],
      location: 'Buffer Stop - Platform 2',
      currentSystemState: {
        'isBufferCollision': true,
        'location': 'Buffer Stop',
        'trains': {
          trainId: {'speed': train.speed}
        }
      },
    );

    currentCollisionIncident = incident;
    collisionAlarmActive = true;
    _logEvent('💥 ${train.name} HIT BUFFER STOPS - Recovery available');

    notifyListeners();
  }

  Map<String, dynamic> _captureSystemState() {
    return {
      'trains': {
        for (var train in trains)
          train.id: {
            'x': train.x,
            'y': train.y,
            'speed': train.speed,
            'direction': train.direction,
            'manualMode': train.controlMode == TrainControlMode.manual,
            'block': train.currentBlockId,
            'emergencyBrake': train.emergencyBrake,
            'doorsOpen': train.doorsOpen,
          }
      },
      'signals': {
        for (var signal in signals.entries)
          signal.key: signal.value.aspect.name,
      },
      'points': {
        for (var point in points.entries) point.key: point.value.position.name,
      },
      'occupiedBlocks': blocks.entries
          .where((e) => e.value.occupied)
          .map((e) => e.key)
          .toList(),
      'routeReservations': routeReservations.length,
      'trainStops': {
        for (var stop in trainStops.entries)
          stop.key: {
            'enabled': stop.value.enabled,
            'active': stop.value.active,
          }
      },
      'axleCounters': {
        for (var counter in axleCounters.entries)
          counter.key: {
            'count': counter.value.count,
            'd1Active': counter.value.d1Active,
            'd2Active': counter.value.d2Active,
          }
      },
    };
  }

  void acknowledgeCollisionAlarm() {
    // Move collided trains back 20 units in opposite directions for recovery
    if (currentCollisionIncident != null && currentCollisionIncident!.trainsInvolved.length >= 2) {
      final train1Id = currentCollisionIncident!.trainsInvolved[0];
      final train2Id = currentCollisionIncident!.trainsInvolved[1];

      final train1 = trains.firstWhere(
        (t) => t.id == train1Id,
        orElse: () => trains.first,
      );
      final train2 = trains.firstWhere(
        (t) => t.id == train2Id,
        orElse: () => trains.first,
      );

      // Move train 1 back 20 units in opposite direction
      train1.x -= 20 * train1.direction;
      train1.speed = 0;
      train1.targetSpeed = 0;
      train1.emergencyBrake = true;

      // Move train 2 back 20 units in opposite direction
      train2.x -= 20 * train2.direction;
      train2.speed = 0;
      train2.targetSpeed = 0;
      train2.emergencyBrake = true;

      _logEvent('🔧 COLLISION RECOVERY: ${train1.name} and ${train2.name} moved back 20 units');
      _updateBlockOccupation();
    }

    collisionAlarmActive = false;
    currentCollisionIncident = null;
    notifyListeners();
  }

  List<CollisionIncident> getRecentIncidents() {
    return _collisionSystem.getRecentIncidents();
  }

  // ============================================================================
  // SMART TRAIN ADDITION
  // ============================================================================

  List<String> getSafeBlocksForTrainAdd() {
    final excludedBlocks = {
      '104',
      '106',
      '107',
      '109',
      'crossover106',
      'crossover109'
    };

    return blocks.entries
        .where((entry) =>
            !entry.value.occupied &&
            !excludedBlocks.contains(entry.key) &&
            !_isBlockReserved(entry.key))
        .map((entry) => entry.key)
        .toList()
      ..sort();
  }

  bool _isBlockReserved(String blockId) {
    return routeReservations.values
        .any((reservation) => reservation.reservedBlocks.contains(blockId));
  }

  void addTrainToBlock(String blockId, {
    TrainType trainType = TrainType.m1,
    String? destination,
    bool assignToTimetable = false,
  }) {
    final safeBlocks = getSafeBlocksForTrainAdd();
    if (!safeBlocks.contains(blockId)) {
      _logEvent(
          '❌ Cannot add train: Block $blockId is not safe for train addition');
      return;
    }

    final block = blocks[blockId];
    if (block == null) return;

    int direction = 1;

    if (blockId == '114' || blockId == '111') {
      direction = -1;
    }

    if (block.y == 300 && !['111'].contains(blockId)) {
      direction = -1;
    }

    final isCbtc = trainType == TrainType.cbtcM1 || trainType == TrainType.cbtcM2;

    final train = Train(
      id: 'T$nextTrainNumber',
      name: 'Train $nextTrainNumber',
      vin: _generateVin(nextTrainNumber, isCbtc),
      trainType: trainType,
      x: _getInitialXForBlock(blockId),
      y: block.y,
      speed: 0,
      targetSpeed: 0,
      direction: direction,
      color: Colors.primaries[nextTrainNumber % Colors.primaries.length],
      controlMode: TrainControlMode.automatic,
      manualStop: false,
      isCbtcEquipped: isCbtc,
      cbtcMode: isCbtc ? CbtcMode.rm : CbtcMode.off, // Start CBTC trains in RM mode
      smcDestination: destination,
      isNCT: isCbtc && destination != null, // NCT if CBTC with destination
      transpondersPassed: 0,
      terReceived: false,
      directionConfirmed: false,
    );

    trains.add(train);

    // Log NCT alert if CBTC train starts in NCT state
    if (train.isNCT) {
      _logEvent('🚨 NCT ALERT: ${train.name} is a Non-Communication Train (newly added)');
      _logEvent('ℹ️  Put train in RM mode and pass over 2 transponders to activate');
    }

    // If assign to timetable, find next available ghost train slot
    if (assignToTimetable && ghostTrains.isNotEmpty) {
      final availableGhost = ghostTrains.firstWhere(
        (g) => g.isAvailable,
        orElse: () => ghostTrains.first, // Fallback if none available
      );

      if (availableGhost.isAvailable) {
        assignTrainToTimetableSlot(train.id, availableGhost.id);
      }
    }

    nextTrainNumber++;
    _updateBlockOccupation();

    String trackType = block.y == 100 ? 'EASTBOUND road' : 'WESTBOUND road';
    String typeStr = _getTrainTypeDisplayName(trainType);
    String destStr = destination != null ? ' to $destination' : '';
    String ttStr = assignToTimetable ? ' [TIMETABLED]' : '';
    _logEvent(
        '🚂 Train ${nextTrainNumber - 1} ($typeStr) added at block $blockId ($trackType)$destStr$ttStr');

    // Reminder for users who may forget to start the simulator
    if (trains.length == 1) {
      _logEvent('💡 REMINDER: Click ▶️ PLAY button to start the simulator');
    }

    notifyListeners();
  }

  String _getTrainTypeDisplayName(TrainType type) {
    switch (type) {
      case TrainType.m1:
        return 'M1';
      case TrainType.m2:
        return 'M2';
      case TrainType.cbtcM1:
        return 'CBTC M1';
      case TrainType.cbtcM2:
        return 'CBTC M2';
    }
  }

  double _getInitialXForBlock(String blockId) {
    final block = blocks[blockId];
    if (block == null) return 50;

    return block.startX + (block.endX - block.startX) / 2;
  }

  String _generateVin(int trainNumber, bool isCbtc) {
    final prefix = isCbtc ? 'CBTC' : 'TRAN';
    final timestamp = DateTime.now().millisecondsSinceEpoch % 100000;
    return '$prefix${trainNumber.toString().padLeft(3, '0')}$timestamp';
  }

  // ============================================================================
  // AUTO TRAIN CONTROLS
  // ============================================================================

  void departAutoTrain(String id) {
    final train = trains.firstWhere((t) => t.id == id);
    if (train.controlMode != TrainControlMode.automatic) {
      _logEvent('❌ Train ${train.name} is not in AUTO mode');
      return;
    }

    train.manualStop = false;
    train.emergencyBrake = false;
    train.targetSpeed = 2.0;
    _logEvent('🚦 ${train.name} AUTO DEPART - released');
    notifyListeners();
  }

  void emergencyBrakeAutoTrain(String id) {
    final train = trains.firstWhere((t) => t.id == id);
    if (train.controlMode != TrainControlMode.automatic) {
      _logEvent('❌ Train ${train.name} is not in AUTO mode');
      return;
    }

    train.emergencyBrake = true;
    train.targetSpeed = 0;
    train.speed = 0;
    _logEvent('🛑 ${train.name} EMERGENCY BRAKE - engaged');
    notifyListeners();
  }

  void emergencyBrakeAll() {
    for (var train in trains) {
      train.emergencyBrake = true;
      train.targetSpeed = 0;
      train.speed = 0;
    }
    _logEvent('🚨 EMERGENCY BRAKE ALL - All trains stopped');
    notifyListeners();
  }

  // ============================================================================
  // POINT LOCK/UNLOCK FUNCTIONALITY
  // ============================================================================

  void togglePointLock(String pointId) {
    final point = points[pointId];
    if (point == null) return;

    // Check if point is deadlocked by AB occupation
    if (_isPointDeadlockedByAB(pointId)) {
      final ab106Occupied = ace.isABOccupied('AB106');
      final specificAB = pointId == '78A'
          ? (ab106Occupied ? 'AB106' : 'AB104')
          : (ab106Occupied ? 'AB106' : 'AB109');

      _logEvent(
          '❌ Point $pointId cannot move: Deadlocked by $specificAB occupation');
      return;
    }

    // Check traditional deadlock (trains in critical blocks)
    if (!_arePointsMovable() && !point.locked) {
      _logEvent(
          '❌ Points deadlocked: Train occupying critical block (104, 106, 107, or 109)');
      return;
    }

    point.locked = !point.locked;
    point.lockedByAB = false;

    _logEvent(point.locked
        ? '🔒 Point $pointId LOCKED'
        : '🔓 Point $pointId UNLOCKED');

    _updateSignalAspects();
    notifyListeners();
  }

  void swingPoint(String pointId) {
    final point = points[pointId];
    if (point == null) return;

    // Check if point is reserved
    if (reservedPoints.containsKey(pointId)) {
      _logEvent('🔒 Point $pointId is RESERVED in ${reservedPoints[pointId]!.name} - cannot swing');
      return;
    }

    // Check if point is locked
    if (point.locked) {
      _logEvent('❌ Point $pointId is LOCKED - cannot swing');
      return;
    }

    // Check if point is deadlocked by AB occupation
    if (_isPointDeadlockedByAB(pointId)) {
      final ab106Occupied = ace.isABOccupied('AB106');
      final specificAB = pointId == '78A'
          ? (ab106Occupied ? 'AB106' : 'AB104')
          : (ab106Occupied ? 'AB106' : 'AB109');

      _logEvent(
          '❌ Point $pointId cannot swing: Deadlocked by $specificAB occupation');
      return;
    }

    // Check traditional deadlock (trains in critical blocks)
    if (!_arePointsMovable()) {
      _logEvent(
          '❌ Points deadlocked: Train occupying critical block (104, 106, 107, or 109)');
      return;
    }

    // Track point throw start time for relay rack "mid" state
    pointThrowStartTimes[pointId] = DateTime.now();

    // Toggle position
    point.position = point.position == PointPosition.normal
        ? PointPosition.reverse
        : PointPosition.normal;

    _logEvent(point.position == PointPosition.normal
        ? '🔀 Point $pointId swung to NORMAL'
        : '🔀 Point $pointId swung to REVERSE');

    _updateSignalAspects();
    notifyListeners();
  }

  void toggleSelfNormalizingPoints() {
    selfNormalizingPoints = !selfNormalizingPoints;
    _logEvent(selfNormalizingPoints
        ? '🔄 Self-normalizing points ENABLED'
        : '⏸️ Self-normalizing points DISABLED');
    notifyListeners();
  }

  // ============================================================================
  // POINT RESERVATION SYSTEM
  // ============================================================================

  void reservePoint(String pointId, PointPosition position) {
    final point = points[pointId];
    if (point == null) {
      _logEvent('⚠️ Point $pointId not found');
      return;
    }

    reservedPoints[pointId] = position;

    // Set the point to the reserved position
    point.position = position;

    _logEvent('🔒 Point $pointId RESERVED in ${position.name.toUpperCase()}');
    _updateSignalAspects();
    notifyListeners();
  }

  void unreservePoint(String pointId) {
    if (!reservedPoints.containsKey(pointId)) {
      _logEvent('⚠️ Point $pointId is not reserved');
      return;
    }

    reservedPoints.remove(pointId);
    _logEvent('🔓 Point $pointId UNRESERVED');
    notifyListeners();
  }

  bool isPointReserved(String pointId) {
    return reservedPoints.containsKey(pointId);
  }

  PointPosition? getPointReservation(String pointId) {
    return reservedPoints[pointId];
  }

  void togglePointReservation(String pointId, PointPosition position) {
    if (isPointReserved(pointId)) {
      unreservePoint(pointId);
    } else {
      reservePoint(pointId, position);
    }
  }

  // ============================================================================
  // ROUTE SETTING
  // ============================================================================

  void setRoute(String signalId, String routeId) {
    final signal = signals[signalId];
    if (signal == null) return;

    final route = signal.routes.firstWhere((r) => r.id == routeId);

    if (signal.activeRouteId == routeId &&
        signal.routeState == RouteState.set) {
      _logEvent('⚠️ Route ${route.name} already set');
      return;
    }

    // Check AB deadlocks before setting route
    for (var pointEntry in route.requiredPointPositions.entries) {
      final pointId = pointEntry.key;
      final requiredPosition = pointEntry.value;
      final point = points[pointId];

      if (point != null && point.position != requiredPosition) {
        if (_isPointDeadlockedByAB(pointId)) {
          final abId = pointId == '78A' ? 'AB104/AB106' : 'AB109/AB106';
          _logEvent(
              '❌ Cannot set route: Point $pointId deadlocked by $abId occupation');
          return;
        }
      }
    }

    if (!_checkRouteConflicts(signalId, route)) {
      return;
    }

    bool blocksClear = true;
    for (var blockId in route.requiredBlocksClear) {
      if (blocks[blockId]?.occupied == true) {
        blocksClear = false;
        break;
      }
    }

    if (!blocksClear) {
      _logEvent('❌ Cannot set route: Required blocks occupied');
      return;
    }

    route.requiredPointPositions.forEach((pointId, position) {
      final point = points[pointId];
      if (point != null) {
        if (!_arePointsMovable() && point.position != position) {
          _logEvent(
              '❌ Cannot set route: Points deadlocked by train in critical block');
          return;
        }

        if (point.locked || selfNormalizingPoints) {
          point.position = position;
          point.locked = true;
          _logEvent('🔧 Point $pointId set to ${position.name.toUpperCase()}');
        }
      }
    });

    signal.activeRouteId = routeId;
    signal.routeState = RouteState.setting;

    _logEvent('🚦 Setting route: ${route.name}');

    final approachingTrain = _findApproachingTrainForSignal(signalId);
    if (approachingTrain != null) {
      _createRouteReservation(signalId, '${approachingTrain.id}_${route.id}',
          route.protectedBlocks);
    } else {
      _createRouteReservation(
          signalId, 'route_active_${route.id}', route.protectedBlocks);
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      signal.routeState = RouteState.set;
      _updateSignalAspects();
      _logEvent('✅ Route set: ${route.name}');
      notifyListeners();
    });

    notifyListeners();
  }

  bool _checkRouteConflicts(String signalId, SignalRoute route) {
    // Check for conflicting routes
    for (var conflictId in route.conflictingRoutes) {
      for (var sig in signals.values) {
        if (sig.activeRouteId == conflictId &&
            sig.routeState == RouteState.set) {
          _logEvent(
              '❌ Cannot set route: Conflicts with active route ${sig.id}');
          return false;
        }
      }
    }

    // Enhanced conflict: C31 Route 2 vs C30 routes
    if (signalId == 'C31' && route.id == 'C31_R2') {
      final c30 = signals['C30'];
      if (c30?.routeState == RouteState.set) {
        _logEvent('❌ Cannot set C31 Route 2: C30 has active route');
        return false;
      }
    }

    // Check point position conflicts
    for (var pointEntry in route.requiredPointPositions.entries) {
      final pointId = pointEntry.key;
      final requiredPosition = pointEntry.value;
      final point = points[pointId];

      if (point != null && point.position != requiredPosition) {
        // Check if point is deadlocked by AB occupation
        if (_isPointDeadlockedByAB(pointId)) {
          final ab106Occupied = ace.isABOccupied('AB106');
          final specificAB = pointId == '78A'
              ? (ab106Occupied ? 'AB106' : 'AB104')
              : (ab106Occupied ? 'AB106' : 'AB109');

          _logEvent(
              '❌ Cannot set route: Point $pointId deadlocked by $specificAB occupation');
          return false;
        }

        // Check if point is locked in a different position by another route
        if (point.locked) {
          _logEvent(
              '❌ Cannot set route: Point $pointId locked in different position');
          return false;
        }
      }
    }

    return true;
  }

  // Find approaching train for signal
  Train? _findApproachingTrainForSignal(String signalId) {
    final signal = signals[signalId];
    if (signal == null) return null;

    // Find trains that could approach this signal
    for (var train in trains) {
      if (_isTrainInApproachBlock(train, signalId)) {
        return train;
      }
    }
    return null;
  }

  // Check if train is in approach block for signal
  bool _isTrainInApproachBlock(Train train, String signalId) {
    switch (signalId) {
      case 'C30':
        return (train.currentBlockId == '109' ||
                train.currentBlockId == '111') &&
            train.direction > 0;
      case 'C31':
        return train.currentBlockId == '104' && train.direction > 0;
      case 'C33':
        return train.currentBlockId == '112' && train.direction > 0;
      case 'C28':
        return (train.currentBlockId == '105' ||
                train.currentBlockId == '107' ||
                train.currentBlockId == '109' ||
                train.currentBlockId == '111') &&
            train.direction < 0;
      default:
        return false;
    }
  }

  // Enhanced route cancellation with proper release button
  void cancelRoute(String signalId) {
    final signal = signals[signalId];
    if (signal == null || signal.activeRouteId == null) return;

    // Special case: C31 Route 1 cannot be cancelled if train is on block 106
    if (signalId == 'C31' && signal.activeRouteId == 'C31_R1') {
      if (blocks['106']?.occupied == true) {
        _logEvent('❌ Cannot cancel C31 Route 1: Train is on block 106');
        return;
      }
    }

    // Don't allow new cancellations during release countdown
    if (releaseState == ReleaseState.counting) {
      _logEvent('🚫 Cannot cancel route: Release countdown in progress');
      return;
    }

    final route = signal.routes.firstWhere((r) => r.id == signal.activeRouteId);

    // Mark as pending cancellation with timestamp
    _pendingRouteCancellations[signalId] = true;
    _pendingCancellationTimers[signalId] = DateTime.now();

    _logEvent(
        '🟡 Route cancellation pending: ${signal.id} - waiting for train to clear protected blocks');

    // Start cancellation process
    _startRouteCancellation(signalId, route);
    notifyListeners();
  }

  // New method to start route cancellation
  void _startRouteCancellation(String signalId, SignalRoute route) {
    releaseState = ReleaseState.counting;
    releaseCountdown = 5; // 5 second countdown

    _logEvent('⏱️ Route release countdown started: ${releaseCountdown}s');

    // Start countdown timer
    _cancellationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      releaseCountdown--;

      if (releaseCountdown <= 0) {
        // Countdown finished, execute cancellation
        timer.cancel();
        _executeRouteCancellation(signalId);
        releaseState = ReleaseState.inactive;
        releaseCountdown = 0;
      }

      notifyListeners();
    });
  }

  // Enhanced route release method
  void releaseRoute(String signalId) {
    final signal = signals[signalId];
    if (signal == null || signal.activeRouteId == null) return;

    if (releaseState == ReleaseState.counting) {
      // Cancel the countdown and release immediately
      _cancellationTimer?.cancel();
      _executeRouteCancellation(signalId);
      releaseState = ReleaseState.inactive;
      releaseCountdown = 0;
      _logEvent('✅ Route ${signal.id} released immediately');
    } else {
      // Start normal cancellation process
      cancelRoute(signalId);
    }
  }

  // Enhanced route cancellation - ONLY clear reservations when route is fully cancelled
  void _executeRouteCancellation(String signalId) {
    final signal = signals[signalId];
    if (signal == null || signal.activeRouteId == null) return;

    // Clear pending cancellation flag
    _pendingRouteCancellations.remove(signalId);
    _pendingCancellationTimers.remove(signalId);

    signal.routeState = RouteState.releasing;
    _logEvent('🚦 Releasing route: ${signal.id}');

    Future.delayed(const Duration(milliseconds: 300), () {
      // FIXED: ONLY clear route reservations when route is fully cancelled
      routeReservations
          .removeWhere((id, reservation) => reservation.signalId == signalId);

      // Self-normalizing points reset when routes cancel
      if (selfNormalizingPoints) {
        points.forEach((id, point) {
          if (point.locked) {
            point.position = PointPosition.normal;
            point.locked = false;
            point.lockedByAB = false;
            _logEvent('🔓 Point $id unlocked and normalized');
          }
        });
      } else {
        // Just unlock points without changing position
        points.forEach((id, point) {
          if (point.locked) {
            point.locked = false;
            point.lockedByAB = false;
            _logEvent('🔓 Point $id unlocked');
          }
        });
      }

      signal.activeRouteId = null;
      signal.routeState = RouteState.unset;
      signal.aspect = SignalAspect.red;
      _logEvent('✅ Route released: ${signal.id}');
      notifyListeners();
    });

    notifyListeners();
  }

  // ============================================================================
  // ENHANCED SIGNAL ASPECT CALCULATION WITH BLOCK 104/109 OCCUPATION CHECKS
  // ============================================================================

  void _updateSignalAspects() {
    // In CBTC mode, all signals remain blue (moving block signaling)
    // Skip traditional fixed-block signal aspect updates
    if (cbtcModeActive) {
      return;
    }

    for (var signal in signals.values) {
      if (signal.routeState != RouteState.set) {
        signal.aspect = SignalAspect.red;
        continue;
      }

      final route =
          signal.routes.firstWhere((r) => r.id == signal.activeRouteId);

      // Check if required blocks are clear - INCLUDING BLOCK 104 FOR C31 AND 109 FOR C30
      bool allClear = true;
      for (var blockId in route.requiredBlocksClear) {
        if (blocks[blockId]?.occupied == true) {
          allClear = false;
          break;
        }
      }

      // ADDITIONAL CHECKS FOR SPECIFIC SIGNALS
      if (signal.id == 'C31') {
        // C31 cannot show green if block 104 has a train
        if (blocks['104']?.occupied == true) {
          allClear = false;
          _logEvent('🛑 C31: Block 104 occupied - forcing RED aspect');
        }
      }

      if (signal.id == 'C30') {
        // C30 cannot show green if block 109 has a train
        if (blocks['109']?.occupied == true) {
          allClear = false;
          _logEvent('🛑 C30: Block 109 occupied - forcing RED aspect');
        }
      }

      // Special approach control logic for C28
      if (signal.id == 'C28') {
        // C28 only shows green when train is on block 105 approaching the signal
        bool trainApproaching = false;
        for (var train in trains) {
          if (train.currentBlockId == '105' && train.direction < 0) {
            trainApproaching = true;
            break;
          }
        }

        if (!trainApproaching) {
          signal.aspect = SignalAspect.red;
          continue;
        }
      }

      // Special approach control logic for C33
      if (signal.id == 'C33') {
        // C33 only shows green when train occupies block 110 approaching the signal
        bool trainApproaching = false;
        for (var train in trains) {
          if (train.currentBlockId == '110' && train.direction > 0) {
            trainApproaching = true;
            break;
          }
        }

        if (!trainApproaching) {
          signal.aspect = SignalAspect.red;
          continue;
        }
      }

      signal.aspect = allClear ? SignalAspect.green : SignalAspect.red;
    }

    // Update train stop states based on signal aspects
    _updateTrainStops();
  }

  // ========== TRAIN MANAGEMENT ==========

  void addTrain() {
    // FIXED: Now properly uses safe block selection instead of always using block 100
    final safeBlocks = getSafeBlocksForTrainAdd();

    if (safeBlocks.isEmpty) {
      _logEvent('❌ Cannot add train: No safe blocks available');
      return;
    }

    // Use the first available safe block with priority order
    // Priority: 100, 102, 108, 110, 112, 114, 111, 105, 107, 109
    final preferredOrder = [
      '100',
      '102',
      '108',
      '110',
      '112',
      '114',
      '111',
      '105',
      '107',
      '109'
    ];
    String? selectedBlock;

    for (var blockId in preferredOrder) {
      if (safeBlocks.contains(blockId)) {
        selectedBlock = blockId;
        break;
      }
    }

    // Fallback to first safe block if none of the preferred blocks are available
    selectedBlock ??= safeBlocks.first;

    addTrainToBlock(selectedBlock);
  }

  void reverseTrain(String id) {
    final train = trains.firstWhere((t) => t.id == id);

    // Auto trains in block 111 should stop and wait for depart
    if (train.controlMode == TrainControlMode.automatic &&
        train.currentBlockId == '111' &&
        train.direction > 0) {
      train.manualStop = true;
      train.targetSpeed = 0;
      train.speed = 0;
      train.direction = -1;
      train.hasCommittedToMove = false;
      train.lastPassedSignalId = null;
      _logEvent(
          '🔄 ${train.name} direction reversed to WESTBOUND ⬅️ (awaiting AUTO DEPART)');
    } else {
      train.direction *= -1;
      train.hasCommittedToMove = false;
      train.lastPassedSignalId = null;
      _logEvent(
          '🔄 ${train.name} direction reversed → ${train.direction == 1 ? "Eastbound ➡️" : "Westbound ⬅️"}');
    }

    notifyListeners();
  }

  void departTrain(String id) {
    final train = trains.firstWhere((t) => t.id == id);

    // FIXED: Ensure manual trains can depart properly
    if (train.controlMode == TrainControlMode.manual) {
      train.manualStop = false;
      train.emergencyBrake = false;
      train.targetSpeed = 2.0;
      train.speed =
          0.5; // Give initial speed boost for manual mode to ensure immediate movement
      _logEvent('🚦 ${train.name} MANUAL DEPART - go');
    } else {
      // Auto mode - just release the manual stop if it was engaged
      train.manualStop = false;
      train.emergencyBrake = false;
      train.targetSpeed = 2.0;
      _logEvent('🚦 ${train.name} AUTO DEPART - released');
    }
    notifyListeners();
  }

  void stopTrain(String id) {
    final train = trains.firstWhere((t) => t.id == id);
    train.manualStop = true;
    train.targetSpeed = 0;
    _logEvent('🛑 ${train.name} manual STOP - engaged');
    notifyListeners();
  }

  void toggleTrainMode(String id) {
    final train = trains.firstWhere((t) => t.id == id);
    train.controlMode = train.controlMode == TrainControlMode.automatic
        ? TrainControlMode.manual
        : TrainControlMode.automatic;

    if (train.controlMode == TrainControlMode.manual) {
      // FIXED: When switching to manual, engage manual stop and zero target speed
      train.manualStop = true;
      train.targetSpeed = 0;
      _logEvent('🎮 ${train.name} → MANUAL mode (use Depart/Stop buttons)');
    } else {
      // FIXED: When switching to auto, release manual stop and let signals control
      train.manualStop = false;
      train.emergencyBrake = false;
      // Don't set targetSpeed here - let the signal logic control it
      _logEvent('🤖 ${train.name} → AUTO mode (signals control movement)');
    }
    notifyListeners();
  }

  void removeTrain(String id) {
    // Clear any route reservations for this train
    routeReservations
        .removeWhere((reservationId, reservation) => reservation.trainId == id);

    trains.removeWhere((t) => t.id == id);
    _updateBlockOccupation();
    notifyListeners();
  }

  // New enhanced train control methods
  void updateTrainType(String id, TrainType newType) {
    final train = trains.firstWhere((t) => t.id == id);
    // Create a new train with updated type by copying all properties
    final updatedTrain = Train(
      id: train.id,
      name: train.name,
      vin: train.vin,
      trainType: newType,
      x: train.x,
      y: train.y,
      speed: train.speed,
      targetSpeed: train.targetSpeed,
      direction: train.direction,
      color: train.color,
      controlMode: train.controlMode,
      manualStop: train.manualStop,
      emergencyBrake: train.emergencyBrake,
      currentBlockId: train.currentBlockId,
      hasCommittedToMove: train.hasCommittedToMove,
      lastPassedSignalId: train.lastPassedSignalId,
      rotation: train.rotation,
      doorsOpen: train.doorsOpen,
      doorsOpenedAt: train.doorsOpenedAt,
      isCbtcEquipped: newType == TrainType.cbtcM1 || newType == TrainType.cbtcM2,
      cbtcMode: (newType == TrainType.cbtcM1 || newType == TrainType.cbtcM2)
          ? CbtcMode.auto
          : CbtcMode.off,
      smcDestination: train.smcDestination,
      movementAuthority: train.movementAuthority,
      isNCT: train.isNCT, // Preserve NCT state
      transpondersPassed: train.transpondersPassed,
      lastTransponderId: train.lastTransponderId,
      terReceived: train.terReceived,
      directionConfirmed: train.directionConfirmed,
    );

    final index = trains.indexWhere((t) => t.id == id);
    trains[index] = updatedTrain;

    _logEvent('🔧 ${train.name} type changed to ${_getTrainTypeName(newType)}');
    notifyListeners();
  }

  String _getTrainTypeName(TrainType type) {
    switch (type) {
      case TrainType.m1:
        return 'M1 (Single)';
      case TrainType.m2:
        return 'M2 (Double)';
      case TrainType.cbtcM1:
        return 'CBTC M1';
      case TrainType.cbtcM2:
        return 'CBTC M2';
    }
  }

  void updateTrainCbtcMode(String id, CbtcMode newMode) {
    final train = trains.firstWhere((t) => t.id == id);

    // Prevent switching to AUTO or PM mode when in NCT state
    if (train.isNCT && (newMode == CbtcMode.auto || newMode == CbtcMode.pm)) {
      _logEvent('❌ ${train.name} is in NCT state (flashing red) - cannot enter ${_getCbtcModeName(newMode)} mode');
      _logEvent('ℹ️  Put train in RM mode and pass over 2 transponders first');
      return;
    }

    final oldMode = train.cbtcMode;
    train.cbtcMode = newMode;

    // If switching FROM off mode TO any other mode, trigger NCT
    if (oldMode == CbtcMode.off && newMode != CbtcMode.off && newMode != CbtcMode.storage) {
      train.isNCT = true;
      train.transpondersPassed = 0;
      train.terReceived = false;
      train.directionConfirmed = false;
      train.lastTransponderId = null;
      train.tractionLostAt = null; // Clear traction tracking
      train.tractionLossWarned = false;
      _logEvent('🚨 NCT ALERT: ${train.name} is now a Non-Communication Train (was in OFF mode)');
      _logEvent('ℹ️  Switch to RM mode and pass over 2 transponders to activate');
    }

    _logEvent('🔧 ${train.name} CBTC mode changed to ${_getCbtcModeName(newMode)}');
    notifyListeners();
  }

  String _getCbtcModeName(CbtcMode mode) {
    switch (mode) {
      case CbtcMode.auto:
        return 'Auto';
      case CbtcMode.pm:
        return 'PM (Protective Manual)';
      case CbtcMode.rm:
        return 'RM (Restrictive Manual)';
      case CbtcMode.off:
        return 'Off';
      case CbtcMode.storage:
        return 'Storage';
    }
  }

  void setTrainDestination(String id, String? destination) {
    final train = trains.firstWhere((t) => t.id == id);
    train.smcDestination = destination;

    if (destination == null) {
      _logEvent('📍 ${train.name} destination cleared');
    } else {
      _logEvent('📍 ${train.name} destination set to $destination');
    }
    notifyListeners();
  }

  void startSimulation() {
    isRunning = true;
    _startSimulationTimer();

    // FIXED: When simulation starts, ensure auto mode trains are ready to move
    for (var train in trains) {
      if (train.controlMode == TrainControlMode.automatic &&
          !train.manualStop &&
          !train.emergencyBrake &&
          train.speed == 0 &&
          train.targetSpeed == 0) {
        // Auto mode train that hasn't been explicitly stopped - allow it to move
        train.targetSpeed = 2.0;
        _logEvent(
            '🚦 ${train.name} AUTO mode ready - will move when signals permit');
      }
    }

    _logEvent('▶️ Simulation started');
    notifyListeners();
  }

  void pauseSimulation() {
    isRunning = false;
    _stopSimulationTimer();
    _logEvent('⏸️ Simulation paused');
    notifyListeners();
  }

  void resetSimulation() {
    trains.clear();
    blocks.forEach((_, block) {
      block.occupied = false;
      block.occupyingTrainId = null;
    });
    points.forEach((_, point) {
      point.position = PointPosition.normal;
      point.locked = false;
      point.lockedByAB = false;
    });
    signals.forEach((_, signal) {
      signal.aspect = SignalAspect.red;
      signal.activeRouteId = null;
      signal.routeState = RouteState.unset;
    });
    routeReservations.clear();
    _pendingRouteCancellations.clear();
    _pendingCancellationTimers.clear();
    _cancellationTimer?.cancel();
    releaseState = ReleaseState.inactive;
    releaseCountdown = 0;
    isRunning = false;
    tickCount = 0;
    nextTrainNumber = 1;
    eventLog.clear();

    // Reset axle counters and ACE
    resetACE();

    // Reset simulation timer
    _resetSimulationTimer();

    // Reset train stops
    trainStops.forEach((_, trainStop) {
      trainStop.active = false;
      trainStop.enabled = true;
    });
    trainStopsEnabled = true;

    // Reset signal visibility
    signalsVisible = true;

    _logEvent('🔄 Simulation reset');
    notifyListeners();
  }

  void setSimulationSpeed(double speed) {
    simulationSpeed = speed;
    notifyListeners();
  }

  // ========== SIMULATION UPDATE ==========

  /// Check if CBTC trains in NCT mode pass over transponders for activation
  void _checkTransponders() {
    for (var train in trains) {
      if (!train.isCbtcTrain || !train.isNCT) continue;
      if (train.cbtcMode != CbtcMode.rm) continue; // Must be in RM mode

      // Check all transponders
      for (var transponder in transponders.values) {
        // Check if train is within 5 units of transponder (passing over it)
        final distance = (train.x - transponder.x).abs();
        if (distance < 5 && (train.y - transponder.y).abs() < 20) {
          // Check if this is a different transponder from last one
          if (train.lastTransponderId != transponder.id) {
            train.lastTransponderId = transponder.id;
            train.transpondersPassed++;

            if (train.transpondersPassed == 1) {
              // First transponder: TER (Train Entry Request)
              train.terReceived = true;
              _logEvent('📡 ${train.name} TER: Train Entry Request received by VCC (Transponder ${transponder.id})');
            } else if (train.transpondersPassed == 2) {
              // Second transponder: Direction confirmed, NCT cleared
              train.directionConfirmed = true;
              train.isNCT = false; // Clear NCT state
              train.tractionLostAt = null; // Clear traction tracking
              train.tractionLossWarned = false;
              _logEvent('✅ ${train.name} ACTIVE: Direction confirmed, NCT state cleared (Transponder ${transponder.id})');
              _logEvent('🚄 ${train.name} can now enter AUTO or PM mode');
            } else if (train.transpondersPassed > 2) {
              // Log subsequent transponder passes for positioning
              _logEvent('📍 ${train.name} passed transponder ${transponder.id} (${transponder.description})');
            }

            notifyListeners();
            break; // Only process one transponder per tick
          }
        }
      }
    }
  }

  void updateSimulation() {
    if (!isRunning) return;

    tickCount++;
    _clearExpiredReservations();
    _checkAutoTrainDoorsAtPlatforms(); // Auto-open doors for trains at platforms
    _checkDoorAutoClose(); // Auto-close doors after 20 seconds

    // Check AB-based point deadlocks every simulation tick
    _arePointsDeadlocked();

    _checkTrainStops();
    _checkAutoSignals();
    _updateAxleCounters();
    _updateMovementAuthorities();
    _checkTransponders(); // Check for CBTC NCT transponder activation

    for (var train in trains) {
      // ========== EARLY EXIT CONDITIONS ==========

      // 1. Door override - train cannot move with open doors
      if (train.doorsOpen) {
        train.targetSpeed = 0;
        train.speed = 0;
        continue;
      }

      // 1.5. CLOSED BLOCK CHECK - Auto trains emergency brake in/approaching closed blocks
      if (train.controlMode == TrainControlMode.automatic) {
        // Check if current block is closed
        if (train.currentBlockId != null && isBlockClosed(train.currentBlockId!)) {
          if (!train.emergencyBrake) {
            train.emergencyBrake = true;
            train.targetSpeed = 0;
            train.speed = 0;
            _logEvent('🚫 ${train.name} EMERGENCY BRAKE: In closed block ${train.currentBlockId}');
          }
          continue;
        }

        // Check if approaching a closed block within 20 units
        bool approachingClosedBlock = false;
        for (var block in blocks.values) {
          if (!isBlockClosed(block.id)) continue;

          // Calculate distance to block based on train direction
          double distanceToBlock = 0;
          bool isAhead = false;

          if (train.direction > 0) {
            // Eastbound - check blocks ahead (to the right)
            if (block.startX > train.x && block.y == train.y) {
              isAhead = true;
              distanceToBlock = block.startX - train.x;
            }
          } else {
            // Westbound - check blocks ahead (to the left)
            if (block.endX < train.x && block.y == train.y) {
              isAhead = true;
              distanceToBlock = train.x - block.endX;
            }
          }

          if (isAhead && distanceToBlock <= 20) {
            approachingClosedBlock = true;
            if (!train.emergencyBrake) {
              train.emergencyBrake = true;
              train.targetSpeed = 0;
              _logEvent('🚫 ${train.name} EMERGENCY BRAKE: Approaching closed block ${block.id} (${distanceToBlock.toStringAsFixed(1)}m away)');
            }
            break;
          }
        }

        if (approachingClosedBlock) {
          continue;
        }
      }

      // 2. COLLISION RECOVERY - Modified to not block movement completely
      if (_isTrainInCollisionRecovery(train.id)) {
        final recoveryPlan = _getRecoveryPlanForTrain(train.id);
        if (recoveryPlan != null) {
          _handleCollisionRecovery(train, recoveryPlan);
          // Continue with normal movement instead of skipping
          // This allows trains to move while in recovery
        }
      }

      // 3. SPAD RECOVERY - Block movement until emergency brake reset
      if (_isTrainInSPADRecovery(train.id) && train.emergencyBrake) {
        train.targetSpeed = 0;
        train.speed = math.max(train.speed - 0.2, 0);
        continue;
      }

      // 4. EMERGENCY BRAKE - Block all movement
      if (train.emergencyBrake) {
        train.targetSpeed = 0;
        train.speed = math.max(train.speed - 0.2, 0);
        continue;
      }

      // 5. CBTC TRACTION LOSS - Check for traction current in train's area
      if (train.isCbtcTrain && train.cbtcMode != CbtcMode.off && train.cbtcMode != CbtcMode.storage) {
        final hasTraction = isTractionOnAt(train.x);

        if (!hasTraction) {
          // Traction current lost - emergency brake immediately
          if (!train.emergencyBrake) {
            train.emergencyBrake = true;
            train.targetSpeed = 0;
            _logEvent('🚨 ${train.name} EMERGENCY BRAKE: Traction current lost');
          }

          // Start or continue 30-second countdown to NCT
          if (train.tractionLostAt == null) {
            train.tractionLostAt = DateTime.now();
            train.tractionLossWarned = false;
            _logEvent('⚠️  ${train.name} traction lost - 30 seconds until NCT state');
          } else {
            // Check if 30 seconds have elapsed
            final elapsed = DateTime.now().difference(train.tractionLostAt!);
            if (elapsed.inSeconds >= 30 && !train.isNCT) {
              // Enter NCT state
              train.isNCT = true;
              train.transpondersPassed = 0;
              train.terReceived = false;
              train.directionConfirmed = false;
              _logEvent('🚨 NCT ALERT: ${train.name} traction not restored - now in NCT state');
              _logEvent('ℹ️  ${train.name} must use RM mode and pass 2 transponders to re-activate');
            } else if (elapsed.inSeconds >= 15 && !train.tractionLossWarned) {
              // Warn at 15 seconds remaining
              train.tractionLossWarned = true;
              _logEvent('⚠️  ${train.name} traction still off - ${30 - elapsed.inSeconds} seconds until NCT');
            }
          }
        } else {
          // Traction current restored
          if (train.tractionLostAt != null && !train.isNCT) {
            _logEvent('✅ ${train.name} traction current restored');
            train.tractionLostAt = null;
            train.tractionLossWarned = false;
            // Keep emergency brake - driver must manually reset
          }
        }
      }

      // ========== NORMAL MOVEMENT LOGIC ==========

      // ========== CBTC TRAIN BEHAVIOR ==========
      // When CBTC mode is globally active, ALL trains use CBTC behavior
      if (train.isCbtcTrain || cbtcModeActive) {
        if (train.cbtcMode == CbtcMode.auto || cbtcModeActive) {
          // CBTC Auto mode: Ignore signals and train stops, but check obstacles
          if (train.manualStop) {
            train.targetSpeed = 0;
          } else {
            // Check for trains ahead (stop 20 units before)
            final trainAhead = _getTrainAhead(train, 50.0);
            if (trainAhead != null) {
              final distance = (trainAhead.x - train.x).abs();
              if (distance < 20.0) {
                train.targetSpeed = 0;
                _logEvent('🛑 CBTC ${train.name} stopped: Train ahead within 20 units');
              } else {
                train.targetSpeed = 2.0;
              }
            } else {
              // Check for occupied AB ahead (stop 20 units before)
              final occupiedAB = _getOccupiedABAhead(train, 50.0);
              if (occupiedAB != null) {
                final abPosition = _getABPosition(occupiedAB);
                if (abPosition != null) {
                  final distance = (abPosition - train.x) * train.direction;
                  if (distance < 20.0 && distance > 0) {
                    train.targetSpeed = 0;
                    _logEvent('🛑 CBTC ${train.name} stopped: Occupied AB ahead within 20 units');
                  } else {
                    train.targetSpeed = 2.0;
                  }
                } else {
                  train.targetSpeed = 2.0;
                }
              } else {
                train.targetSpeed = 2.0;
              }
            }

            // CBTC Auto routing: Automatically throw points as train approaches
            if (cbtcModeActive && train.smcDestination != null) {
              _autoRouteTrainInCbtc(train);
            }
          }
        } else if (train.cbtcMode == CbtcMode.pm) {
          // CBTC PM (Protective Manual) mode: Manual control with auto emergency brake
          if (train.manualStop) {
            train.targetSpeed = 0;
          } else {
            // Check for obstacles within 20 units and auto emergency brake
            final trainAhead = _getTrainAhead(train, 30.0);
            if (trainAhead != null) {
              final distance = (trainAhead.x - train.x).abs();
              if (distance < 20.0) {
                train.emergencyBrake = true;
                _logEvent('⚠️ CBTC PM ${train.name}: Emergency brake - Train ahead within 20 units');
              }
            }

            final occupiedAB = _getOccupiedABAhead(train, 30.0);
            if (occupiedAB != null) {
              final abPosition = _getABPosition(occupiedAB);
              if (abPosition != null) {
                final distance = (abPosition - train.x) * train.direction;
                if (distance < 20.0 && distance > 0) {
                  train.emergencyBrake = true;
                  _logEvent('⚠️ CBTC PM ${train.name}: Emergency brake - Occupied AB ahead within 20 units');
                }
              }
            }
          }
        } else if (train.cbtcMode == CbtcMode.rm) {
          // CBTC RM (Restrictive Manual) mode: Full manual control - NO restrictions
          // RM mode ignores signals, ignores train stops - used for NCT re-entry
          // User has full manual control to move train in any direction
          if (train.manualStop) {
            train.targetSpeed = 0;
          } else {
            // Allow free movement - maintain targetSpeed set by departTrain()
            // No signal checks, no train stop checks, no speed restrictions
            // User controls movement via Go/Stop buttons
            if (train.targetSpeed == 0) {
              train.targetSpeed = 2.0; // Ensure train can move when Go is pressed
            }
          }
        } else if (train.cbtcMode == CbtcMode.storage || train.cbtcMode == CbtcMode.off) {
          // Storage or Off mode - train should not move
          train.targetSpeed = 0;
          train.speed = 0;
        } else {
          // Fallback for any other modes
          if (train.manualStop) {
            train.targetSpeed = 0;
          }
        }
      } else {
        // ========== NON-CBTC TRAIN BEHAVIOR (Standard) ==========

        // Manual stop override
        if (train.manualStop) {
          train.targetSpeed = 0;
        } else if (train.controlMode == TrainControlMode.manual) {
          // Manual mode without stop - allow movement at current target speed
          // targetSpeed already set by departTrain() or user control
        } else {
          // Automatic mode - check signals and route reservations
          Signal? signalAhead = _getSignalAhead(train);

        // Enhanced permissive movement logic with direction protection
        bool hasPassedSignalThreshold = false;
        if (signalAhead != null && train.lastPassedSignalId == signalAhead.id) {
          final distancePastSignal =
              (train.x - signalAhead.x) * train.direction;
          hasPassedSignalThreshold = distancePastSignal > 4;
        }

        // Enhanced direction-based signal protection
        signalAhead = _filterSignalByDirection(train, signalAhead);

        // Check if train has route reservation for the block ahead
        bool hasRouteReservation = false;
        final nextBlock = _getNextBlockForTrain(train);
        if (nextBlock != null) {
          hasRouteReservation = routeReservations.values.any((reservation) =>
              reservation.trainId == train.id &&
              reservation.reservedBlocks.contains(nextBlock));
        }

        if (signalAhead == null) {
          train.targetSpeed = 2.0;
        } else if (signalAhead.aspect == SignalAspect.red &&
            !hasPassedSignalThreshold &&
            !hasRouteReservation) {
          final distanceToSignal = (signalAhead.x - train.x).abs();
          if (distanceToSignal < 100 && distanceToSignal > 0) {
            if (train.targetSpeed > 0) {
              _logStopReason(train, signalAhead, 'approaching red signal');
            }
            train.targetSpeed = 0;
            train.hasCommittedToMove = false;
          }
        } else {
          train.targetSpeed = 2.0;

          if ((signalAhead.aspect == SignalAspect.green ||
                  hasRouteReservation) &&
              !train.hasCommittedToMove) {
            final hasPassed = train.direction > 0
                ? train.x >= signalAhead.x
                : train.x <= signalAhead.x;

            if (hasPassed) {
              train.lastPassedSignalId = signalAhead.id;
              train.hasCommittedToMove = true;
              _logEvent(
                  '🚂 ${train.name} passed signal ${signalAhead.id} - committed to route');
            }
          }
        }
        }
      }

      // Check for point collision (running through points from converging side)
      if (_checkPointCollision(train)) {
        continue; // Skip movement this tick
      }

      // Auto mode directional restrictions
      if (train.controlMode == TrainControlMode.automatic) {
        // Prevent auto trains from traveling from block 114 to 108
        if (train.currentBlockId == '114' && train.direction < 0) {
          train.targetSpeed = 0;
          train.speed = 0;
          _logEvent(
              '🛑 ${train.name} stopped: Auto mode cannot travel westbound from block 114');
          continue;
        }

        // Prevent auto trains from block 103 to 105 and 105 to 107
        if ((train.currentBlockId == '103' &&
                train.direction > 0 &&
                _getNextBlockForTrain(train) == '105') ||
            (train.currentBlockId == '105' &&
                train.direction > 0 &&
                _getNextBlockForTrain(train) == '107')) {
          train.targetSpeed = 0;
          train.speed = 0;
          _logEvent(
              '🛑 ${train.name} stopped: Auto mode cannot travel from ${train.currentBlockId} to ${_getNextBlockForTrain(train)}');
          continue;
        }
      }

      // Accelerate/brake
      if (train.speed < train.targetSpeed) {
        train.speed = math.min(train.speed + 0.05, train.targetSpeed);
      } else if (train.speed > train.targetSpeed) {
        train.speed = math.max(train.speed - 0.1, train.targetSpeed);
      }

      // Move train
      if (train.speed > 0) {
        final oldBlockId = train.currentBlockId;
        final nextX =
            train.x + (train.speed * simulationSpeed * train.direction);

        // Check if this would move to a different block
        BlockSection? nextBlock;
        for (var block in blocks.values) {
          if (block.containsPosition(nextX, train.y)) {
            nextBlock = block;
            break;
          }
        }

        // Validate track connection before moving
        if (nextBlock != null &&
            oldBlockId != null &&
            nextBlock.id != oldBlockId) {
          final currentBlock = blocks[oldBlockId];
          if (currentBlock != null &&
              !_canTrainMoveBetweenBlocks(train, currentBlock, nextBlock)) {
            train.targetSpeed = 0;
            train.speed = 0;
            _logEvent(
                '🛑 ${train.name} stopped: Points not set for ${oldBlockId}→${nextBlock.id}');
            continue;
          }
        }

        // Move is valid - proceed
        train.x = nextX;

        // Update Y position based on track
        _updateTrainYPosition(train);

        // Check if entered new block - update commitment and reservations
        _updateBlockOccupation();
        if (train.currentBlockId != oldBlockId &&
            train.currentBlockId != null) {
          train.hasCommittedToMove = false;
          train.lastPassedSignalId = null;
        }

        // Block 111 auto-stop (AUTO mode)
        if (train.controlMode == TrainControlMode.automatic) {
          if (train.currentBlockId == '111' && train.direction > 0) {
            final blockCenter = 1100;
            if (train.x >= blockCenter) {
              train.x = blockCenter.toDouble();
              train.speed = 0;
              train.targetSpeed = 0;
              train.manualStop = true;
              _logEvent(
                  '🛑 ${train.name} AUTO-STOP in block 111 (awaiting depart command)');

              _collisionSystem.trackEvent(
                trainId: train.id,
                description: 'Auto-stopped in block 111',
                location: 'Block 111',
                trainSpeed: 0,
                systemState: {'autoMode': true, 'bufferProtection': true},
              );
            }
          }
        }

        // Buffer stop check
        if (train.direction > 0 && train.y > 250 && train.x >= 1190) {
          if (train.controlMode == TrainControlMode.manual) {
            _handleBufferCollision(train.id);
          } else {
            train.x = 1190;
            train.speed = 0;
            train.targetSpeed = 0;
            train.emergencyBrake = true;
            _logEvent('🛑 ${train.name} reached buffer stop (safety)');
          }
        }

        // Check for west end limit (westbound trains)
        if (train.direction < 0 && train.x <= 0) {
          train.x = 0;
          train.speed = 0;
          train.targetSpeed = 0;
          _logEvent('🛑 ${train.name} reached west end');
        }
      }

      // Wrap around at track end (eastbound)
      if (train.direction > 0 && train.x > 1600) {
        train.x = 50;
        train.y = 100;
        train.hasCommittedToMove = false;
        train.lastPassedSignalId = null;
      }

      // Wrap around at track start (westbound)
      if (train.direction < 0 && train.x < 0) {
        train.x = 1550;
        train.y = 100;
        train.hasCommittedToMove = false;
        train.lastPassedSignalId = null;
      }
    }

    // Re-enable train stops when trains clear the blocks
    _reEnableTrainStops();

    _updateBlockOccupation();
    _updateSignalAspects();
    _checkCollisions();

    // Auto-follow train if following mode is active
    if (followingTrainId != null) {
      final train = trains.where((t) => t.id == followingTrainId).firstOrNull;
      if (train != null) {
        cameraOffsetX = -train.x;
        cameraOffsetY = -train.y;
      } else {
        // Train no longer exists, stop following
        followingTrainId = null;
      }
    }

    notifyListeners();
  }

  // Enhanced signal filtering by direction
  Signal? _filterSignalByDirection(Train train, Signal? signal) {
    if (signal == null) return null;

    // Apply direction-based filtering
    switch (signal.id) {
      case 'C33':
      case 'C31':
        return train.direction > 0 ? signal : null;
      case 'C28':
        return train.direction < 0 ? signal : null;
      case 'C30':
        return signal;
      default:
        return signal;
    }
  }

  String? _getNextBlockForTrain(Train train) {
    if (train.currentBlockId == null) return null;

    final currentBlock = blocks[train.currentBlockId!];
    if (currentBlock == null) return null;

    // MIRRORED TERMINAL STATION ROUTING - Continuous loop through 3 sections
    // Upper track ALWAYS eastbound →, Lower track ALWAYS westbound ←

    if (train.direction > 0) {
      // ========== EASTBOUND (Upper Track) ==========

      // LEFT SECTION (200-214)
      switch (currentBlock.id) {
        case '200': return '202';
        case '202': return '204';
        case '204': return '206';
        case '206': return '208';
        case '208': return '210';
        case '210': return '212';
        case '212': return '214';
        case '214': return '100'; // Continue to MIDDLE section
      }

      // MIDDLE SECTION (100-114)
      switch (currentBlock.id) {
        case '100':
          return '102';
        case '102':
          return '104';
        case '104':
          return '106';
        case '106':
          return '108';
        case '108':
          return '110';
        case '110':
          return '112';
        case '112':
          return '114';
        case '114':
          return '116';
        case '116':
          return '118';
        case '118':
          return '120';
        case '120':
          return '122';
        case '122':
          return '124';
        case '124':
          return '126';
        case '126':
          return '128';
        case '128':
          return '130';
        case '130':
          return '132';
        case '101':
          return '103';
        case '103':
          return '105';
        case '105':
          return '107';
        case '107':
          return '109';
        case '109':
          return '111';
        case 'crossover106':
          return 'crossover109';
        case 'crossover109':
          return '109';
      }

      // RIGHT SECTION (300-314)
      switch (currentBlock.id) {
        case '300': return '302';
        case '302': return '304';
        case '304': return '306';
        case '306': return '308';
        case '308': return '310';
        case '310': return '312';
        case '312': return '314';
        case '314': return 'crossover_right'; // Use right crossover to switch to lower track
      }

      // Crossovers
      if (currentBlock.id == 'crossover_right') return '315'; // Switch to lower track
      if (currentBlock.id == 'crossover106') return 'crossover109';
      if (currentBlock.id == 'crossover109') return '109';
      if (currentBlock.id == 'crossover_left') return '201'; // Switch to lower track

    } else {
      // ========== WESTBOUND (Lower Track) ==========

      // RIGHT SECTION (301-315) - going west
      switch (currentBlock.id) {
        case '132':
          return '130';
        case '130':
          return '128';
        case '128':
          return '126';
        case '126':
          return '124';
        case '124':
          return '122';
        case '122':
          return '120';
        case '120':
          return '118';
        case '118':
          return '116';
        case '116':
          return '114';
        case '114':
          return '112';
        case '112':
          return '110';
        case '110':
          return '108';
        case '108':
          return '106';
        case '106':
          return '104';
        case '104':
          return '102';
        case '102':
          return '100';
        case '111':
          return '109';
        case '109':
          return '107';
        case '107':
          return '105';
        case '105':
          return '103';
        case '103':
          return '101';
        case 'crossover109':
          return 'crossover106';
        case 'crossover106':
          return '104';
      }

      // MIDDLE SECTION (101-115) - going west
      switch (currentBlock.id) {
        case '115': return '113';
        case '113': return '111';
        case '111': return '109';
        case '109': return '107';
        case '107': return '105';
        case '105': return '103';
        case '103': return '101';
        case '101': return '215'; // Continue to LEFT section
      }

      // LEFT SECTION (201-215) - going west
      switch (currentBlock.id) {
        case '215': return '213';
        case '213': return '211';
        case '211': return '209';
        case '209': return '207';
        case '207': return '205';
        case '205': return '203';
        case '203': return '201';
        case '201': return 'crossover_left'; // Use left crossover to switch to upper track
      }

      // Crossovers
      if (currentBlock.id == 'crossover_left') return '200'; // Complete loop - switch to upper track
      if (currentBlock.id == 'crossover109') return 'crossover106';
      if (currentBlock.id == 'crossover106') return '104';
      if (currentBlock.id == 'crossover_right') return '314'; // Back to upper track
    }

    return null;
  }

  /// Automatically route CBTC train by throwing points and setting routes
  void _autoRouteTrainInCbtc(Train train) {
    if (train.smcDestination == null) return;

    // Parse destination (format: "B:blockId" or just "blockId")
    final destinationBlock = train.smcDestination!.startsWith('B:')
        ? train.smcDestination!.substring(2)
        : train.smcDestination!;

    // Find points ahead of the train within 100 units
    for (var point in points.values) {
      if (point.locked) continue; // Skip locked points

      final distanceToPoint = (point.x - train.x) * train.direction;

      // Only consider points ahead within 100 units
      if (distanceToPoint > 0 && distanceToPoint < 100) {
        // Determine required point position based on destination
        final requiredPosition = _calculateRequiredPointPosition(
          train, point, destinationBlock);

        if (requiredPosition != null && point.position != requiredPosition) {
          // Check if point can be swung (not deadlocked)
          if (!_isPointDeadlockedByAB(point.id) && _arePointsMovable()) {
            // Automatically throw the point
            point.position = requiredPosition;
            _logEvent('🔀 CBTC Auto: Point ${point.id} swung to ${requiredPosition.name.toUpperCase()} for ${train.name}');
            notifyListeners();
          }
        }
      }
    }

    // Find signals ahead and automatically set routes if needed
    final signalAhead = _getSignalAhead(train);
    if (signalAhead != null && signalAhead.routeState != RouteState.set) {
      final distanceToSignal = (signalAhead.x - train.x).abs();

      // Only auto-set route if signal is within 150 units
      if (distanceToSignal < 150) {
        // Find appropriate route based on destination
        for (var route in signalAhead.routes) {
          if (_isRouteTowardDestination(train, route, destinationBlock)) {
            // Attempt to set the route
            if (!_checkRouteConflicts(signalAhead.id, route)) {
              continue;
            }

            bool blocksClear = true;
            for (var blockId in route.requiredBlocksClear) {
              if (blocks[blockId]?.occupied == true &&
                  blocks[blockId]?.occupyingTrainId != train.id) {
                blocksClear = false;
                break;
              }
            }

            if (blocksClear) {
              // Set the route
              signalAhead.routeState = RouteState.set;
              signalAhead.activeRouteId = route.id;
              signalAhead.aspect = SignalAspect.blue; // Keep blue in CBTC mode

              _logEvent('🔀 CBTC Auto: Route ${route.id} set for ${train.name} to reach $destinationBlock');
              notifyListeners();
              break;
            }
          }
        }
      }
    }
  }

  /// Calculate required point position to reach destination
  PointPosition? _calculateRequiredPointPosition(
      Train train, Point point, String destinationBlock) {
    // Simple routing logic based on point location and destination
    // This is a simplified version - can be enhanced with more sophisticated routing

    final trainY = train.y;
    final destinationY = blocks[destinationBlock]?.y ?? trainY;

    // For points 76A/76B (left crossover)
    if (point.id == '76A' || point.id == '77A') {
      if (destinationY > 200) {
        return PointPosition.reverse; // Route to upper track
      } else {
        return PointPosition.normal; // Route to lower track
      }
    }

    // For points 76B/77B (left crossover upper)
    if (point.id == '76B' || point.id == '77B') {
      if (destinationY > 200) {
        return PointPosition.reverse; // Route to upper track
      } else {
        return PointPosition.normal; // Route to lower track
      }
    }

    // For points 78A/78B (middle crossover)
    if (point.id == '78A' || point.id == '78B') {
      if (destinationY > 200) {
        return PointPosition.reverse; // Route to upper track
      } else {
        return PointPosition.normal; // Route to lower track
      }
    }

    // For points 79A/79B/80A/80B (right crossover)
    if (point.id == '79A' || point.id == '79B' ||
        point.id == '80A' || point.id == '80B') {
      if (destinationY > 200) {
        return PointPosition.reverse; // Route to upper track
      } else {
        return PointPosition.normal; // Route to lower track
      }
    }

    return null; // No specific requirement
  }

  /// Check if route leads toward destination
  bool _isRouteTowardDestination(Train train, SignalRoute route, String destinationBlock) {
    // Check if any of the route's required blocks or protected blocks
    // are on the path to the destination
    final allBlocks = [...route.requiredBlocksClear, ...route.protectedBlocks];

    for (var blockId in allBlocks) {
      if (blockId == destinationBlock) {
        return true; // Route directly leads to destination
      }

      // Check if block is on the path to destination
      if (_isBlockOnPathToDestination(blockId, destinationBlock, train.direction)) {
        return true;
      }
    }

    return allBlocks.isNotEmpty; // If no specific match, allow if route has blocks
  }

  /// Check if block is on path to destination
  bool _isBlockOnPathToDestination(String blockId, String destinationBlock, int direction) {
    // Simple heuristic: check if block number is between current and destination
    final blockNum = int.tryParse(blockId);
    final destNum = int.tryParse(destinationBlock);

    if (blockNum == null || destNum == null) return true;

    if (direction > 0) {
      return blockNum <= destNum; // Going east
    } else {
      return blockNum >= destNum; // Going west
    }
  }

  void _reEnableTrainStops() {
    for (var trainStop in trainStops.values) {
      if (!trainStop.enabled && _spadTrainStopId == trainStop.id) {
        // Check if any train is still in the protected block
        bool trainInProtectedArea = false;
        final signal = signals[trainStop.signalId];
        if (signal != null && signal.activeRouteId != null) {
          final route = signal.routes.firstWhere(
            (r) => r.id == signal.activeRouteId,
            orElse: () => signal.routes.first,
          );

          for (var blockId in route.protectedBlocks) {
            if (blocks[blockId]?.occupied == true) {
              trainInProtectedArea = true;
              break;
            }
          }
        }

        if (!trainInProtectedArea) {
          trainStop.enabled = true;
          _logEvent('🟢 TrainStop ${trainStop.id} re-enabled');
          _spadTrainStopId = null;
        }
      }
    }
  }

  // Update getStats method to include ACE info
  Map<String, dynamic> getStats() {
    return {
      'trains': trains.length,
      'occupied_blocks': blocks.values.where((b) => b.occupied).length,
      'active_routes':
          signals.values.where((s) => s.routeState == RouteState.set).length,
      'route_reservations': routeReservations.length,
      'self_normalizing_points': selfNormalizingPoints,
      'pending_cancellations': _pendingRouteCancellations.length,
      'release_state': releaseState.name,
      'release_countdown': releaseCountdown,
      'setting_routes': signals.values
          .where((s) => s.routeState == RouteState.setting)
          .length,
      'releasing_routes': signals.values
          .where((s) => s.routeState == RouteState.releasing)
          .length,
      'train_stops_enabled': trainStopsEnabled,
      'active_train_stops':
          trainStops.values.where((s) => s.active && s.enabled).length,
      'spad_alarm_active': _spadAlarmActive,
      'collision_alarm_active': collisionAlarmActive,
      'active_collision_recoveries': _activeCollisionRecoveries.length,
      'recovery_trains_involved': _activeCollisionRecoveries.values
          .fold<int>(0, (sum, plan) => sum + plan.trainsInvolved.length),
      'axle_counters': axleCounters.length,
      'occupied_ab_sections': ace.abResults.values.where((v) => v > 0).length,
      'signals_visible': signalsVisible,
      'point_78a_deadlocked': _isPointDeadlockedByAB('78A'),
      'point_78b_deadlocked': _isPointDeadlockedByAB('78B'),
      'ab104_occupied': ace.isABOccupied('AB104'),
      'ab106_occupied': ace.isABOccupied('AB106'),
      'ab109_occupied': ace.isABOccupied('AB109'),
    };
  }

  // ========== EXISTING METHODS ==========

  void _updateTrainYPosition(Train train) {
    final point76A = points['76A'];
    final point76B = points['76B'];
    final point78A = points['78A'];
    final point78B = points['78B'];
    final point80A = points['80A'];
    final point80B = points['80B'];

    // LEFT SECTION DOUBLE DIAMOND CROSSOVER (x=-550 to -450, points 76A, 76B)
    if (train.x >= -550 && train.x < -450) {
      if (point76A?.position == PointPosition.reverse &&
          point76B?.position == PointPosition.reverse) {
        // 135-degree crossover - train transitioning between upper and lower tracks
        double progress = (train.x + 550) / 100;  // 0 to 1 over the crossover
        if (train.direction > 0) {
          // Moving right: upper track (y=100) to lower track (y=300)
          train.y = 100 + (200 * progress);
          train.rotation = 2.356; // 135 degrees in radians
        } else {
          // Moving left: lower track (y=300) to upper track (y=100)
          train.y = 300 - (200 * progress);
          train.rotation = -2.356; // -135 degrees in radians
        }
      } else {
        // Points in normal position - stay on current track
        if (train.y < 200) {
          train.y = 100;
        } else {
          train.y = 300;
        }
        train.rotation = 0.0;
      }
    }
    // CENTER SECTION DOUBLE CROSSOVER (x=600 to 800, points 78A, 78B) - EXISTING CODE
    else if (train.x >= 600 && train.x < 800) {
      if (point78A?.position == PointPosition.reverse &&
          point78B?.position == PointPosition.reverse) {
        if (train.x < 700) {
          double progress = (train.x - 600) / 100;
          train.y = 100 + (100 * progress);
          train.rotation = 0.785398;  // 45 degrees
        } else {
          double progress = (train.x - 700) / 100;
          train.y = 200 + (100 * progress);
          train.rotation = 0.785398;  // 45 degrees
        }
      } else {
        if (train.y < 200) {
          train.y = 100;
        } else {
          train.y = 300;
        }
        train.rotation = 0.0;
      }
    }
    // RIGHT SECTION DOUBLE DIAMOND CROSSOVER (x=1900 to 2000, points 80A, 80B)
    else if (train.x >= 1900 && train.x < 2000) {
      if (point80A?.position == PointPosition.reverse &&
          point80B?.position == PointPosition.reverse) {
        // 135-degree crossover - train transitioning between upper and lower tracks
        double progress = (train.x - 1900) / 100;  // 0 to 1 over the crossover
        if (train.direction > 0) {
          // Moving right: upper track (y=100) to lower track (y=300)
          train.y = 100 + (200 * progress);
          train.rotation = 2.356; // 135 degrees in radians
        } else {
          // Moving left: lower track (y=300) to upper track (y=100)
          train.y = 300 - (200 * progress);
          train.rotation = -2.356; // -135 degrees in radians
        }
      } else {
        // Points in normal position - stay on current track
        if (train.y < 200) {
          train.y = 100;
        } else {
          train.y = 300;
        }
        train.rotation = 0.0;
      }
    }
    // ALL OTHER SECTIONS - maintain straight tracks
    else {
      if (train.y > 200) {
        train.y = 300;
      } else {
        train.y = 100;
      }
      train.rotation = 0.0;
    }
  }

  void _updateBlockOccupation() {
    blocks.forEach((_, block) {
      block.occupied = false;
      block.occupyingTrainId = null;
    });

    for (var train in trains) {
      for (var block in blocks.values) {
        if (block.containsPosition(train.x, train.y)) {
          block.occupied = true;
          block.occupyingTrainId = train.id;
          train.currentBlockId = block.id;
        }
      }
    }
  }

  bool _canTrainMoveBetweenBlocks(
      Train train, BlockSection fromBlock, BlockSection nextBlock) {
    if ((fromBlock.y - nextBlock.y).abs() < 50) {
      return true;
    }

    final needsCrossover = (fromBlock.y - nextBlock.y).abs() > 50;
    if (!needsCrossover) {
      return true;
    }

    return _isValidJunctionMove(train, fromBlock.id, nextBlock.id);
  }

  bool _isValidJunctionMove(Train train, String fromBlockId, String toBlockId) {
    final point76A = points['76A'];
    final point76B = points['76B'];
    final point78A = points['78A'];
    final point78B = points['78B'];
    final point80A = points['80A'];
    final point80B = points['80B'];

    // LEFT SECTION DOUBLE DIAMOND CROSSOVER (blocks 211, 212, crossover_211_212)
    if (train.direction > 0) {
      // Eastbound through left crossover
      if (fromBlockId == '210' && toBlockId == 'crossover_211_212') {
        return point76A?.position == PointPosition.reverse;
      }
      if (fromBlockId == 'crossover_211_212' && toBlockId == '212') {
        return point76B?.position == PointPosition.reverse;
      }
      if (fromBlockId == '211' && toBlockId == 'crossover_211_212') {
        return point76B?.position == PointPosition.reverse;
      }
      if (fromBlockId == 'crossover_211_212' && toBlockId == '213') {
        return point76A?.position == PointPosition.reverse;
      }
    }

    if (train.direction < 0) {
      // Westbound through left crossover
      if (fromBlockId == '212' && toBlockId == 'crossover_211_212') {
        return point76B?.position == PointPosition.reverse;
      }
      if (fromBlockId == 'crossover_211_212' && toBlockId == '210') {
        return point76A?.position == PointPosition.reverse;
      }
      if (fromBlockId == '213' && toBlockId == 'crossover_211_212') {
        return point76A?.position == PointPosition.reverse;
      }
      if (fromBlockId == 'crossover_211_212' && toBlockId == '211') {
        return point76B?.position == PointPosition.reverse;
      }
    }

    // CENTER SECTION DOUBLE CROSSOVER (blocks 106, 108, 107, 109, crossover106, crossover109)
    if (train.direction > 0) {
      if (fromBlockId == '106' && toBlockId == 'crossover106') {
        return point78A?.position == PointPosition.reverse;
      }
      if (fromBlockId == 'crossover106' && toBlockId == 'crossover109') {
        return true;
      }
      if (fromBlockId == 'crossover109' && toBlockId == '109') {
        return point78B?.position == PointPosition.reverse;
      }
      if (fromBlockId == '109' && toBlockId == 'crossover109') {
        return point78B?.position == PointPosition.reverse;
      }
      if (fromBlockId == 'crossover109' && toBlockId == 'crossover106') {
        return true;
      }
      if (fromBlockId == 'crossover106' && toBlockId == '108') {
        return point78A?.position == PointPosition.reverse;
      }
    }

    if (train.direction < 0) {
      if (fromBlockId == '109' && toBlockId == 'crossover109') {
        return point78B?.position == PointPosition.reverse;
      }
      if (fromBlockId == 'crossover109' && toBlockId == 'crossover106') {
        return true;
      }
      if (fromBlockId == 'crossover106' && toBlockId == '106') {
        return point78A?.position == PointPosition.reverse;
      }
      if (fromBlockId == '106' && toBlockId == 'crossover106') {
        return point78A?.position == PointPosition.reverse;
      }
      if (fromBlockId == 'crossover106' && toBlockId == 'crossover109') {
        return true;
      }
      if (fromBlockId == 'crossover109' && toBlockId == '107') {
        return point78B?.position == PointPosition.reverse;
      }
    }

    // RIGHT SECTION DOUBLE DIAMOND CROSSOVER (blocks 302, 304, 303, 305, crossover_303_304)
    if (train.direction > 0) {
      // Eastbound through right crossover
      if (fromBlockId == '302' && toBlockId == 'crossover_303_304') {
        return point80A?.position == PointPosition.reverse;
      }
      if (fromBlockId == 'crossover_303_304' && toBlockId == '304') {
        return point80B?.position == PointPosition.reverse;
      }
      if (fromBlockId == '303' && toBlockId == 'crossover_303_304') {
        return point80B?.position == PointPosition.reverse;
      }
      if (fromBlockId == 'crossover_303_304' && toBlockId == '305') {
        return point80A?.position == PointPosition.reverse;
      }
    }

    if (train.direction < 0) {
      // Westbound through right crossover
      if (fromBlockId == '304' && toBlockId == 'crossover_303_304') {
        return point80B?.position == PointPosition.reverse;
      }
      if (fromBlockId == 'crossover_303_304' && toBlockId == '302') {
        return point80A?.position == PointPosition.reverse;
      }
      if (fromBlockId == '305' && toBlockId == 'crossover_303_304') {
        return point80A?.position == PointPosition.reverse;
      }
      if (fromBlockId == 'crossover_303_304' && toBlockId == '303') {
        return point80B?.position == PointPosition.reverse;
      }
    }

    _logEvent(
        '🚨 DERAILMENT PREVENTED: ${train.name} tried to move $fromBlockId→$toBlockId (no track connection)');
    return false;
  }

  // Check if train is approaching points from converging side with points reversed
  // This should trigger emergency brake (collision scenario)
  bool _checkPointCollision(Train train) {
    final currentBlockId = train.currentBlockId;
    if (currentBlockId == null) return false;

    // LEFT CROSSOVER - Check points 76A, 76B, 77A, 77B
    // Eastbound approaching from converging side (lower track to upper via points in reverse)
    if (train.direction > 0 && currentBlockId == '211') {
      final point76B = points['76B'];
      final point77B = points['77B'];
      if (point76B?.position == PointPosition.reverse &&
          point77B?.position == PointPosition.reverse) {
        _logEvent('💥 COLLISION: ${train.name} running through reversed points 76B/77B from converging side!');
        train.emergencyBrake = true;
        train.speed = 0;
        train.targetSpeed = 0;
        return true;
      }
    }

    // Westbound approaching from converging side (upper track to lower via points in reverse)
    if (train.direction < 0 && currentBlockId == '212') {
      final point76A = points['76A'];
      final point77A = points['77A'];
      if (point76A?.position == PointPosition.reverse &&
          point77A?.position == PointPosition.reverse) {
        _logEvent('💥 COLLISION: ${train.name} running through reversed points 76A/77A from converging side!');
        train.emergencyBrake = true;
        train.speed = 0;
        train.targetSpeed = 0;
        return true;
      }
    }

    // CENTRAL CROSSOVER - Check points 78A, 78B
    // Eastbound approaching from converging side
    if (train.direction > 0 && currentBlockId == '109') {
      final point78B = points['78B'];
      if (point78B?.position == PointPosition.reverse) {
        _logEvent('💥 COLLISION: ${train.name} running through reversed point 78B from converging side!');
        train.emergencyBrake = true;
        train.speed = 0;
        train.targetSpeed = 0;
        return true;
      }
    }

    // Westbound approaching from converging side
    if (train.direction < 0 && currentBlockId == '108') {
      final point78A = points['78A'];
      if (point78A?.position == PointPosition.reverse) {
        _logEvent('💥 COLLISION: ${train.name} running through reversed point 78A from converging side!');
        train.emergencyBrake = true;
        train.speed = 0;
        train.targetSpeed = 0;
        return true;
      }
    }

    // RIGHT CROSSOVER - Check points 79A, 79B, 80A, 80B
    // Eastbound approaching from converging side
    if (train.direction > 0 && currentBlockId == '303') {
      final point79B = points['79B'];
      final point80B = points['80B'];
      if (point79B?.position == PointPosition.reverse &&
          point80B?.position == PointPosition.reverse) {
        _logEvent('💥 COLLISION: ${train.name} running through reversed points 79B/80B from converging side!');
        train.emergencyBrake = true;
        train.speed = 0;
        train.targetSpeed = 0;
        return true;
      }
    }

    // Westbound approaching from converging side
    if (train.direction < 0 && currentBlockId == '304') {
      final point79A = points['79A'];
      final point80A = points['80A'];
      if (point79A?.position == PointPosition.reverse &&
          point80A?.position == PointPosition.reverse) {
        _logEvent('💥 COLLISION: ${train.name} running through reversed points 79A/80A from converging side!');
        train.emergencyBrake = true;
        train.speed = 0;
        train.targetSpeed = 0;
        return true;
      }
    }

    return false;
  }

  void _checkAutoSignals() {
    final c28 = signals['C28'];
    if (c28 != null && c28.routeState == RouteState.unset) {
      bool trainReadyToExit = false;
      for (var train in trains) {
        if ((train.currentBlockId == '105' ||
                train.currentBlockId == '107' ||
                train.currentBlockId == '109' ||
                train.currentBlockId == '111') &&
            train.direction < 0) {
          trainReadyToExit = true;
          break;
        }
      }

      if (trainReadyToExit) {
        final block103 = blocks['103'];
        final block101 = blocks['101'];
        if (block103?.occupied == false && block101?.occupied == false) {
          setRoute('C28', 'C28_R1');
          _logEvent(
              '🤖 C28 auto-set: Exit blocks clear for westbound departure');
        }
      }
    }
  }

  Signal? _getSignalAhead(Train train) {
    Signal? nearest;
    double minDistance = double.infinity;

    final currentBlock = blocks[train.currentBlockId];
    if (currentBlock == null) return null;

    for (var signal in signals.values) {
      // Only consider signals in the same direction
      final isSameDirection = (train.direction > 0 && signal.y < 200) ||
          (train.direction < 0 && signal.y > 200);
      if (!isSameDirection) continue;

      if ((signal.y - train.y).abs() > 50) continue;

      final isAhead =
          train.direction > 0 ? signal.x > train.x : signal.x < train.x;

      if (isAhead) {
        final distance = (signal.x - train.x).abs();
        if (distance < minDistance) {
          minDistance = distance;
          nearest = signal;
        }
      }
    }

    return nearest;
  }

  void _logEvent(String message) {
    eventLog.insert(0,
        '${DateTime.now().toIso8601String().split('T')[1].substring(0, 8)} - $message');
    if (eventLog.length > 50) {
      eventLog.removeLast();
    }
  }

  // ========== CBTC HELPER METHODS ==========

  /// Check if there's a train ahead within the specified distance
  Train? _getTrainAhead(Train train, double maxDistance) {
    Train? nearestTrain;
    double minDistance = maxDistance;

    for (var otherTrain in trains) {
      if (otherTrain.id == train.id) continue;

      // Check if other train is in same direction lane
      final isSameLane = (train.y - otherTrain.y).abs() < 50;
      if (!isSameLane) continue;

      // Check if other train is ahead
      final distance = (otherTrain.x - train.x) * train.direction;
      if (distance > 0 && distance < minDistance) {
        minDistance = distance;
        nearestTrain = otherTrain;
      }
    }

    return nearestTrain;
  }

  /// Check if there's an occupied AB ahead within the specified distance
  String? _getOccupiedABAhead(Train train, double maxDistance) {
    final absToCheck = ['AB100', 'AB105', 'AB106', 'AB108', 'AB111'];
    String? nearestAB;
    double minDistance = maxDistance;

    for (var abId in absToCheck) {
      if (!ace.isABOccupied(abId)) continue;

      // Get AB position - approximate from block positions
      final abPosition = _getABPosition(abId);
      if (abPosition == null) continue;

      // Check if AB is ahead
      final distance = (abPosition - train.x) * train.direction;
      if (distance > 0 && distance < minDistance) {
        minDistance = distance;
        nearestAB = abId;
      }
    }

    return nearestAB;
  }

  /// Get approximate X position for an AB section
  double? _getABPosition(String abId) {
    switch (abId) {
      case 'AB100':
        return 300.0;
      case 'AB105':
        return 500.0;
      case 'AB106':
        return 675.0;
      case 'AB108':
        return 900.0;
      case 'AB111':
        return 1000.0;
      default:
        return null;
    }
  }

  void _logStopReason(Train train, Signal? signal, String reason) {
    if (train.manualStop) {
      _logEvent('🛑 ${train.name} stopped: Manual stop engaged');
    } else if (train.emergencyBrake) {
      _logEvent('🛑 ${train.name} stopped: Emergency brake engaged');
    } else if (signal == null) {
      _logEvent('✅ ${train.name}: No signal ahead, ${reason}');
    } else if (signal.aspect == SignalAspect.red) {
      if (signal.routeState == RouteState.unset) {
        _logEvent(
            '🛑 ${train.name} stopped: Signal ${signal.id} RED - NO ROUTE SET (use route buttons)');
      } else {
        final route = signal.routes.firstWhere(
          (r) => r.id == signal.activeRouteId,
          orElse: () => signal.routes.first,
        );
        final occupiedBlocks = route.requiredBlocksClear
            .where((bid) => blocks[bid]?.occupied == true)
            .map((bid) => '$bid(${blocks[bid]?.occupyingTrainId})')
            .toList();

        if (occupiedBlocks.isNotEmpty) {
          _logEvent(
              '🛑 ${train.name} stopped: Signal ${signal.id} RED - blocks occupied: ${occupiedBlocks.join(", ")}');
        } else {
          _logEvent(
              '🛑 ${train.name} stopped: Signal ${signal.id} RED - checking route conditions...');
        }
      }
    } else {
      _logEvent('ℹ️ ${train.name}: ${reason}');
    }
  }

  // ========== XML EXPORT ==========

  String exportLayoutAsXML() {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<RailwayLayout name="Terminal Station" version="2.6">');
    buffer.writeln('  <Metadata>');
    buffer.writeln(
        '    <Description>Terminal station with crossover and bay platform - Enhanced with ac107 crossover counter for train location tracking</Description>');
    buffer.writeln(
        '    <ExportDate>${DateTime.now().toIso8601String()}</ExportDate>');
    buffer.writeln('    <TrainCount>${trains.length}</TrainCount>');
    buffer.writeln('    <SignalCount>${signals.length}</SignalCount>');
    buffer.writeln('    <PointCount>${points.length}</PointCount>');
    buffer.writeln('    <TrainStopCount>${trainStops.length}</TrainStopCount>');
    buffer.writeln(
        '    <AxleCounterCount>${axleCounters.length}</AxleCounterCount>');
    buffer.writeln(
        '    <SelfNormalizingPoints>$selfNormalizingPoints</SelfNormalizingPoints>');
    buffer.writeln(
        '    <TrainStopsEnabled>$trainStopsEnabled</TrainStopsEnabled>');
    buffer.writeln(
        '    <AxleCountersVisible>$axleCountersVisible</AxleCountersVisible>');
    buffer.writeln('    <SignalsVisible>$signalsVisible</SignalsVisible>');
    buffer.writeln('  </Metadata>');

    // Export Blocks
    buffer.writeln('  <Blocks>');
    blocks.forEach((id, block) {
      buffer.writeln(
          '    <Block id="$id" startX="${block.startX}" endX="${block.endX}" y="${block.y}" occupied="${block.occupied}" occupyingTrain="${block.occupyingTrainId ?? 'none'}" />');
    });
    buffer.writeln('  </Blocks>');

    // Export Points
    buffer.writeln('  <Points>');
    points.forEach((id, point) {
      buffer.writeln(
          '    <Point id="$id" x="${point.x}" y="${point.y}" position="${point.position.name}" locked="${point.locked}" lockedByAB="${point.lockedByAB}" />');
    });
    buffer.writeln('  </Points>');

    // Export Signals
    buffer.writeln('  <Signals>');
    signals.forEach((id, signal) {
      buffer.writeln(
          '    <Signal id="$id" x="${signal.x}" y="${signal.y}" aspect="${signal.aspect.name}" state="${signal.routeState.name}">');
      for (var route in signal.routes) {
        buffer.writeln('      <Route id="${route.id}" name="${route.name}">');
        buffer.writeln(
            '        <RequiredBlocks>${route.requiredBlocksClear.join(', ')}</RequiredBlocks>');
        buffer.writeln(
            '        <PathBlocks>${route.pathBlocks.join(', ')}</PathBlocks>');
        buffer.writeln(
            '        <ProtectedBlocks>${route.protectedBlocks.join(', ')}</ProtectedBlocks>');
        buffer.writeln(
            '        <ConflictingRoutes>${route.conflictingRoutes.join(', ')}</ConflictingRoutes>');
        buffer.writeln('      </Route>');
      }
      buffer.writeln('    </Signal>');
    });
    buffer.writeln('  </Signals>');

    // Export Platforms
    buffer.writeln('  <Platforms>');
    for (var platform in platforms) {
      buffer.writeln(
          '    <Platform id="${platform.id}" name="${platform.name}" startX="${platform.startX}" endX="${platform.endX}" y="${platform.y}" occupied="${platform.occupied}" />');
    }
    ;
    buffer.writeln('  </Platforms>');

    // Export Trains
    buffer.writeln('  <Trains>');
    for (var train in trains) {
      buffer.writeln(
          '    <Train id="${train.id}" name="${train.name}" x="${train.x}" y="${train.y}" speed="${train.speed}" direction="${train.direction == 1 ? 'eastbound' : 'westbound'}" currentBlock="${train.currentBlockId ?? 'none'}" controlMode="${train.controlMode.name}" rotation="${train.rotation}" emergencyBrake="${train.emergencyBrake}" doorsOpen="${train.doorsOpen}" />');
    }
    ;
    buffer.writeln('  </Trains>');

    // Export Route Reservations
    buffer.writeln('  <RouteReservations>');
    routeReservations.forEach((id, reservation) {
      buffer.writeln(
          '    <Reservation id="$id" signal="${reservation.signalId}" train="${reservation.trainId}" blocks="${reservation.reservedBlocks.join(', ')}" />');
    });
    buffer.writeln('  </RouteReservations>');

    // Export Train Stops
    buffer.writeln('  <TrainStops>');
    trainStops.forEach((id, trainStop) {
      buffer.writeln(
          '    <TrainStop id="$id" signal="${trainStop.signalId}" x="${trainStop.x}" y="${trainStop.y}" enabled="${trainStop.enabled}" active="${trainStop.active}" />');
    });
    buffer.writeln('  </TrainStops>');

    // Export Axle Counters
    buffer.writeln('  <AxleCounters>');
    axleCounters.forEach((id, counter) {
      buffer.writeln(
          '    <AxleCounter id="$id" block="${counter.blockId}" x="${counter.x}" y="${counter.y}" count="${counter.count}" isTwin="${counter.isTwin}" twinLabel="${counter.twinLabel ?? ''}" />');
    });
    buffer.writeln('  </AxleCounters>');

    // Export ACE Results
    buffer.writeln('  <ACEResults>');
    ace.abResults.forEach((abId, count) {
      buffer.writeln(
          '    <ABResult id="$abId" count="$count" occupied="${ace.isABOccupied(abId)}" />');
    });
    buffer.writeln('  </ACEResults>');

    // Export Double Diamond Crossovers
    buffer.writeln('');
    buffer.writeln('  <!-- DOUBLE DIAMOND CROSSOVER CONFIGURATIONS -->');
    _exportDoubleDiamondCrossovers(buffer);

    buffer.writeln('</RailwayLayout>');

    _logEvent('📄 Layout exported to XML (${buffer.length} bytes)');
    return buffer.toString();
  }

  /// Exports enhanced double diamond crossover configurations
  void _exportDoubleDiamondCrossovers(StringBuffer buffer) {
    // LEFT SECTION - Double Diamond Crossover (x=-550 to -450)
    buffer.writeln('  <DoubleDiamondCrossover id="ddc_77" centerX="-500" centerY="200">');
    buffer.writeln('    <!-- Points: 76A, 76B, 77A, 77B -->');
    buffer.writeln('    <Points>');
    buffer.writeln('      <Point id="77c" type="left_hand" x="-575.7" y="173.8" state="normal">');
    buffer.writeln('        <Geometry>');
    buffer.writeln('          <MainRoute angle="0" length="21.2"/>');
    buffer.writeln('          <DivergingRoute angle="-6.7" length="21.2"/>');
    buffer.writeln('          <ThrowTime>2000</ThrowTime>');
    buffer.writeln('        </Geometry>');
    buffer.writeln('        <Control>');
    buffer.writeln('          <Relay id="WKR_77c" status="normal"/>');
    buffer.writeln('          <Detection circuit="DP_77c"/>');
    buffer.writeln('        </Control>');
    buffer.writeln('      </Point>');
    buffer.writeln('      <Point id="77d" type="right_hand" x="-424.3" y="173.8" state="normal">');
    buffer.writeln('        <Geometry>');
    buffer.writeln('          <MainRoute angle="180" length="21.2"/>');
    buffer.writeln('          <DivergingRoute angle="186.7" length="21.2"/>');
    buffer.writeln('          <ThrowTime>2000</ThrowTime>');
    buffer.writeln('        </Geometry>');
    buffer.writeln('        <Control>');
    buffer.writeln('          <Relay id="WKR_77d" status="normal"/>');
    buffer.writeln('          <Detection circuit="DP_77d"/>');
    buffer.writeln('        </Control>');
    buffer.writeln('      </Point>');
    buffer.writeln('      <Point id="77e" type="left_hand" x="-523.2" y="273.7" state="normal">');
    buffer.writeln('        <Geometry>');
    buffer.writeln('          <MainRoute angle="90" length="21.2"/>');
    buffer.writeln('          <DivergingRoute angle="83.3" length="21.2"/>');
    buffer.writeln('          <ThrowTime>2000</ThrowTime>');
    buffer.writeln('        </Geometry>');
    buffer.writeln('        <Control>');
    buffer.writeln('          <Relay id="WKR_77e" status="normal"/>');
    buffer.writeln('          <Detection circuit="DP_77e"/>');
    buffer.writeln('        </Control>');
    buffer.writeln('      </Point>');
    buffer.writeln('      <Point id="77f" type="right_hand" x="-476.8" y="226.3" state="normal">');
    buffer.writeln('        <Geometry>');
    buffer.writeln('          <MainRoute angle="270" length="21.2"/>');
    buffer.writeln('          <DivergingRoute angle="276.7" length="21.2"/>');
    buffer.writeln('          <ThrowTime>2000</ThrowTime>');
    buffer.writeln('        </Geometry>');
    buffer.writeln('        <Control>');
    buffer.writeln('          <Relay id="WKR_77f" status="normal"/>');
    buffer.writeln('          <Detection circuit="DP_77f"/>');
    buffer.writeln('        </Control>');
    buffer.writeln('      </Point>');
    buffer.writeln('    </Points>');
    buffer.writeln('');
    buffer.writeln('    <!-- Diamond Crossings -->');
    buffer.writeln('    <Diamonds>');
    buffer.writeln('      <Diamond id="diamond_45" angle="45" x="-500" y="200">');
    buffer.writeln('        <Geometry>');
    buffer.writeln('          <Leg1 direction="22.5" length="28.4"/>');
    buffer.writeln('          <Leg2 direction="112.5" length="28.4"/>');
    buffer.writeln('          <Leg3 direction="202.5" length="28.4"/>');
    buffer.writeln('          <Leg4 direction="292.5" length="28.4"/>');
    buffer.writeln('          <CrossingNose gap="42"/>');
    buffer.writeln('          <CheckRail clearance="48"/>');
    buffer.writeln('        </Geometry>');
    buffer.writeln('        <Performance>');
    buffer.writeln('          <SpeedLimit>25</SpeedLimit>');
    buffer.writeln('          <MaintenanceFactor>3.0</MaintenanceFactor>');
    buffer.writeln('        </Performance>');
    buffer.writeln('      </Diamond>');
    buffer.writeln('      <Diamond id="diamond_135" angle="135" x="-500" y="200">');
    buffer.writeln('        <Geometry>');
    buffer.writeln('          <Leg1 direction="67.5" length="28.4"/>');
    buffer.writeln('          <Leg2 direction="157.5" length="28.4"/>');
    buffer.writeln('          <Leg3 direction="247.5" length="28.4"/>');
    buffer.writeln('          <Leg4 direction="337.5" length="28.4"/>');
    buffer.writeln('          <CrossingNose gap="42"/>');
    buffer.writeln('          <CheckRail clearance="48"/>');
    buffer.writeln('        </Geometry>');
    buffer.writeln('        <Performance>');
    buffer.writeln('          <SpeedLimit>60</SpeedLimit>');
    buffer.writeln('          <MaintenanceFactor>1.5</MaintenanceFactor>');
    buffer.writeln('        </Performance>');
    buffer.writeln('      </Diamond>');
    buffer.writeln('    </Diamonds>');
    buffer.writeln('');
    buffer.writeln('    <!-- Track Circuits -->');
    buffer.writeln('    <TrackCircuits>');
    buffer.writeln('      <Circuit id="TR_77A" points="77c" occupied="false"/>');
    buffer.writeln('      <Circuit id="TR_77B" points="77d" occupied="false"/>');
    buffer.writeln('      <Circuit id="TR_77C" points="77e" occupied="false"/>');
    buffer.writeln('      <Circuit id="TR_77D" points="77f" occupied="false"/>');
    buffer.writeln('      <Circuit id="TR_77_D45" points="diamond_45" occupied="false"/>');
    buffer.writeln('      <Circuit id="TR_77_D135" points="diamond_135" occupied="false"/>');
    buffer.writeln('    </TrackCircuits>');
    buffer.writeln('');
    buffer.writeln('    <!-- Route Possibilities -->');
    buffer.writeln('    <Routes>');
    buffer.writeln('      <Route id="R77_EW_Straight" points="77c:normal,77d:normal" diamonds="diamond_45" speed="80"/>');
    buffer.writeln('      <Route id="R77_EW_Cross" points="77c:reverse,77d:reverse" diamonds="diamond_135" speed="60"/>');
    buffer.writeln('      <Route id="R77_NS_Straight" points="77e:normal,77f:normal" diamonds="diamond_45" speed="80"/>');
    buffer.writeln('      <Route id="R77_NS_Cross" points="77e:reverse,77f:reverse" diamonds="diamond_135" speed="60"/>');
    buffer.writeln('      <Route id="R77_Turn_NW" points="77c:reverse,77e:normal" speed="40"/>');
    buffer.writeln('      <Route id="R77_Turn_NE" points="77d:reverse,77f:normal" speed="40"/>');
    buffer.writeln('      <Route id="R77_Turn_SW" points="77e:reverse,77c:normal" speed="40"/>');
    buffer.writeln('      <Route id="R77_Turn_SE" points="77f:reverse,77d:normal" speed="40"/>');
    buffer.writeln('    </Routes>');
    buffer.writeln('  </DoubleDiamondCrossover>');
    buffer.writeln('');

    // RIGHT SECTION - Double Diamond Crossover (x=1900 to 2000)
    buffer.writeln('  <DoubleDiamondCrossover id="ddc_79" centerX="1950" centerY="200">');
    buffer.writeln('    <!-- Points: 79A, 79B, 80A, 80B -->');
    buffer.writeln('    <Points>');
    buffer.writeln('      <Point id="79c" type="left_hand" x="1874.3" y="173.8" state="normal"/>');
    buffer.writeln('      <Point id="79d" type="right_hand" x="2025.7" y="173.8" state="normal"/>');
    buffer.writeln('      <Point id="79e" type="left_hand" x="1926.8" y="273.7" state="normal"/>');
    buffer.writeln('      <Point id="79f" type="right_hand" x="1973.2" y="226.3" state="normal"/>');
    buffer.writeln('    </Points>');
    buffer.writeln('    <!-- Similar diamond and route configuration as ddc_77 -->');
    buffer.writeln('  </DoubleDiamondCrossover>');
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _cancellationTimer?.cancel();
    _simulationTimer?.cancel();
    _timetableTimer?.cancel();
    super.dispose();
  }
}
