import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rail_champ/screens/collision_analysis_system.dart';
import 'package:rail_champ/screens/terminal_station_models.dart'
    hide CollisionIncident;
import 'package:rail_champ/models/railway_model.dart';  // FIXED: Import for WiFi and Transponders
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

  // Enhanced axle counter update with bidirectional tracking
  void updateAxleCounter(String counterId, int direction, bool isEntering) {
    final counter = axleCounters[counterId];
    if (counter == null) return;

    final oldCount = counter.count;

    if (isEntering) {
      counter.count++;
      counter.lastDirection = direction > 0 ? 'Eastbound' : 'Westbound';
      counter.lastDetectionTime = DateTime.now();
      print(
          '🚂 ENTRY: $counterId detected train entry - Count: $oldCount → ${counter.count}');
    } else {
      counter.count = math.max(0, counter.count - 1);
      counter.lastDirection = direction > 0 ? 'Eastbound' : 'Westbound';
      counter.lastDetectionTime = DateTime.now();
      print(
          '🚂 EXIT: $counterId detected train exit - Count: $oldCount → ${counter.count}');
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

  bool _spadAlarmActive = false;
  CollisionIncident? _currentSpadIncident;
  String? _spadTrainStopId;

  bool get spadAlarmActive => _spadAlarmActive;
  CollisionIncident? get currentSpadIncident => _currentSpadIncident;
  String? get spadTrainStopId => _spadTrainStopId;

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
      ace.updateAxleCounter(nearestCounter, train.direction, isEntering);
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
    _logEvent(active
        ? '🚄 CBTC Mode ACTIVATED - Moving block signaling enabled'
        : '🚄 CBTC Mode DEACTIVATED - Fixed block signaling');
    notifyListeners();
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
    final targetBlockId = plan.reverseInstructions[train.id];
    if (targetBlockId == null) return;

    if (train.direction > 0) {
      train.direction = -1;
      _logEvent('🔄 ${train.name} reversing for collision recovery');
    }

    train.emergencyBrake = false;
    train.targetSpeed = 3.0;

    train.x += train.speed * train.direction * simulationSpeed * 2.0;

    final targetBlock = blocks[targetBlockId];
    if (targetBlock != null && targetBlock.containsPosition(train.x, train.y)) {
      _logEvent(
          '✅ ${train.name} reached safe position in block $targetBlockId');
      train.targetSpeed = 0;
      train.speed = 0;
      train.emergencyBrake = false;
      train.direction = 1;

      _checkRecoveryCompletion(plan);
    }
  }

  void _checkRecoveryCompletion(CollisionRecoveryPlan plan) {
    bool allTrainsSafe = true;

    for (var trainId in plan.trainsInvolved) {
      final train = trains.firstWhere((t) => t.id == trainId);
      final targetBlockId = plan.reverseInstructions[trainId];
      final targetBlock = blocks[targetBlockId];

      if (targetBlock == null ||
          !targetBlock.containsPosition(train.x, train.y) ||
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

    return MovementAuthority(
      maxDistance: maxDistance.clamp(0.0, 2000.0),
      limitReason: limitReason,
      hasDestination: hasDestination,
    );
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
    ace = AxleCounterEvaluator(axleCounters);
  }

  void _initializeAxleCounters() {
    axleCounters['ac100'] =
        AxleCounter(id: 'ac100', blockId: '100', x: 100, y: 120);
    axleCounters['ac104'] =
        AxleCounter(id: 'ac104', blockId: '104', x: 550, y: 120);
    axleCounters['ac108'] =
        AxleCounter(id: 'ac108', blockId: '108', x: 700, y: 120);
    axleCounters['ac112'] =
        AxleCounter(id: 'ac112', blockId: '112', x: 1300, y: 120);

    axleCounters['ac101'] =
        AxleCounter(id: 'ac101', blockId: '101', x: 100, y: 320);
    axleCounters['ac105'] =
        AxleCounter(id: 'ac105', blockId: '105', x: 700, y: 320);
    axleCounters['ac109'] =
        AxleCounter(id: 'ac109', blockId: '109', x: 850, y: 320);

    axleCounters['ac111'] =
        AxleCounter(id: 'ac111', blockId: '111', x: 1150, y: 320);

    // UPDATED: AC106 positioned as additional entry/exit for AB104
    axleCounters['ac106'] = AxleCounter(
      id: 'ac106',
      blockId: 'crossover106',
      x: 630,
      y: 150,
      isTwin: false,
      twinLabel: 'ac106',
    );

    // UPDATED: AC107 positioned as additional entry/exit for AB109
    axleCounters['ac107'] = AxleCounter(
      id: 'ac107',
      blockId: 'crossover109',
      x: 770,
      y: 250,
      isTwin: false,
      twinLabel: 'ac107',
    );
  }

  void _initializeClock() {
    _currentTime = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentTime = DateTime.now();
      notifyListeners();
    });
  }

  void _initializeLayout() {
    _initializeAxleCounters();

    // FIXED: Expanded closed-loop network - 7000×1200 canvas
    // Section 1: Central Terminal (original, x: 0→1600, y: 100/300)
    blocks['100'] = BlockSection(id: '100', startX: 0, endX: 200, y: 100);
    blocks['102'] = BlockSection(id: '102', startX: 200, endX: 400, y: 100);
    blocks['104'] = BlockSection(id: '104', startX: 400, endX: 600, y: 100);
    blocks['106'] = BlockSection(id: '106', startX: 600, endX: 800, y: 100);
    blocks['108'] = BlockSection(id: '108', startX: 800, endX: 1000, y: 100);
    blocks['110'] = BlockSection(id: '110', startX: 1000, endX: 1200, y: 100);
    blocks['112'] = BlockSection(id: '112', startX: 1200, endX: 1400, y: 100);
    blocks['114'] = BlockSection(id: '114', startX: 1400, endX: 1600, y: 100);

    blocks['101'] = BlockSection(id: '101', startX: 0, endX: 200, y: 300);
    blocks['103'] = BlockSection(id: '103', startX: 200, endX: 400, y: 300);
    blocks['105'] = BlockSection(id: '105', startX: 400, endX: 600, y: 300);
    blocks['107'] = BlockSection(id: '107', startX: 600, endX: 800, y: 300);
    blocks['109'] = BlockSection(id: '109', startX: 800, endX: 1000, y: 300);
    blocks['111'] = BlockSection(id: '111', startX: 1000, endX: 1200, y: 300);

    // Section 2: East extension to Victoria Junction (x: 1600→3200, y: 100/300)
    for (int i = 116; i <= 132; i += 2) {
      double startX = 1600 + ((i - 116) / 2 * 200);
      blocks['$i'] = BlockSection(id: '$i', startX: startX, endX: startX + 200, y: 100);
    }
    for (int i = 113; i <= 131; i += 2) {
      double startX = 1600 + ((i - 113) / 2 * 200);
      blocks['$i'] = BlockSection(id: '$i', startX: startX, endX: startX + 200, y: 300);
    }

    // Section 3: To Paddington Central (x: 3200→4800, y: 100/300)
    for (int i = 134; i <= 148; i += 2) {
      double startX = 3200 + ((i - 134) / 2 * 200);
      blocks['$i'] = BlockSection(id: '$i', startX: startX, endX: startX + 200, y: 100);
    }
    for (int i = 133; i <= 149; i += 2) {
      double startX = 3200 + ((i - 133) / 2 * 200);
      blocks['$i'] = BlockSection(id: '$i', startX: startX, endX: startX + 200, y: 300);
    }

    // Section 4: Southern curve (x: 4800→5600, y transitions from 100 to 700)
    for (int i = 150; i <= 158; i += 2) {
      double startX = 4800 + ((i - 150) / 2 * 200);
      double yPos = 100 + ((i - 150) / 2 * 150); // Gradual curve down
      blocks['$i'] = BlockSection(id: '$i', startX: startX, endX: startX + 200, y: yPos);
    }

    // Section 5: Eastern extension and return line (x: 5600→7000, y: 700)
    for (int i = 160; i <= 174; i += 2) {
      double startX = 5600 + ((i - 160) / 2 * 200);
      blocks['$i'] = BlockSection(id: '$i', startX: startX, endX: startX + 200, y: 700);
    }

    // Section 6: Western return (x: 7000→0, y: 700) - westbound track
    for (int i = 201; i <= 235; i += 2) {
      double startX = 7000 - ((i - 201) / 2 * 200);
      blocks['$i'] = BlockSection(id: '$i', startX: startX - 200, endX: startX, y: 700);
    }

    // Section 7: Northwest curve back to start (x: 0→-800, curves north)
    for (int i = 237; i <= 243; i += 2) {
      double startX = 0 - ((i - 237) / 2 * 200);
      double yPos = 700 - ((i - 237) / 2 * 150); // Curve back up
      blocks['$i'] = BlockSection(id: '$i', startX: startX - 200, endX: startX, y: yPos);
    }

    // Crossovers
    blocks['crossover106'] =
        BlockSection(id: 'crossover106', startX: 600, endX: 700, y: 150);
    blocks['crossover109'] =
        BlockSection(id: 'crossover109', startX: 700, endX: 800, y: 250);
    blocks['crossover126'] =
        BlockSection(id: 'crossover126', startX: 2400, endX: 2500, y: 200); // Victoria
    blocks['crossover138'] =
        BlockSection(id: 'crossover138', startX: 3800, endX: 3900, y: 200); // Paddington
    blocks['crossover170'] =
        BlockSection(id: 'crossover170', startX: 6000, endX: 6100, y: 700); // Waterloo

    // Points for all crossovers
    points['78A'] = Point(id: '78A', x: 600, y: 100);
    points['78B'] = Point(id: '78B', x: 800, y: 300);
    points['80A'] = Point(id: '80A', x: 2400, y: 100); // Victoria
    points['80B'] = Point(id: '80B', x: 2500, y: 300);
    points['82A'] = Point(id: '82A', x: 3800, y: 100); // Paddington
    points['82B'] = Point(id: '82B', x: 3900, y: 300);
    points['84A'] = Point(id: '84A', x: 6000, y: 700); // Waterloo

    // FIXED: 5 Stations with unique names across the loop
    // Central Terminal (original)
    platforms.add(Platform(
        id: 'P1', name: 'Central Terminal P1', startX: 980, endX: 1240, y: 100));
    platforms.add(Platform(
        id: 'P2', name: 'Central Terminal P2 (Bay)', startX: 980, endX: 1240, y: 300));

    // Victoria Junction
    platforms.add(Platform(
        id: 'P3', name: 'Victoria Junction P3', startX: 2400, endX: 2800, y: 100));
    platforms.add(Platform(
        id: 'P4', name: 'Victoria Junction P4', startX: 2400, endX: 2800, y: 300));

    // Paddington Central
    platforms.add(Platform(
        id: 'P5', name: 'Paddington Central P5', startX: 3800, endX: 4200, y: 100));
    platforms.add(Platform(
        id: 'P6', name: 'Paddington Central P6', startX: 3800, endX: 4200, y: 300));

    // Waterloo Express
    platforms.add(Platform(
        id: 'P7', name: 'Waterloo Express P7', startX: 6000, endX: 6400, y: 700));

    // Camden Depot
    platforms.add(Platform(
        id: 'P8', name: 'Camden Depot P8', startX: -800, endX: -400, y: 700));

    signals['C31'] = Signal(
      id: 'C31',
      x: 390,
      y: 80,
      routes: [
        SignalRoute(
          id: 'C31_R1',
          name: 'Route 1 (Main → Platform 1)',
          requiredBlocksClear: ['106', '108', '110'],
          requiredPointPositions: {
            '78A': PointPosition.normal,
            '78B': PointPosition.normal
          },
          pathBlocks: ['104', '106', '108', '110', '112'],
          protectedBlocks: ['106', '108', '110'],
        ),
        SignalRoute(
          id: 'C31_R2',
          name: 'Route 2 (Main → Bay Platform 2)',
          requiredBlocksClear: [
            '106',
            'crossover106',
            'crossover109',
            '109',
            '111'
          ],
          requiredPointPositions: {
            '78A': PointPosition.reverse,
            '78B': PointPosition.reverse
          },
          conflictingRoutes: ['C30_R1', 'C30_R2'],
          pathBlocks: [
            '104',
            '106',
            'crossover106',
            'crossover109',
            '109',
            '111'
          ],
          protectedBlocks: [
            '104',
            '106',
            'crossover106',
            'crossover109',
            '109',
            '111'
          ],
        ),
      ],
    );

    signals['C33'] = Signal(
      id: 'C33',
      x: 1200,
      y: 80,
      routes: [
        SignalRoute(
          id: 'C33_R1',
          name: 'Platform 1 Departure',
          requiredBlocksClear: ['112', '114'],
          requiredPointPositions: {},
          pathBlocks: ['112', '114'],
          protectedBlocks: ['112', '114'],
        ),
      ],
    );

    signals['C30'] = Signal(
      id: 'C30',
      x: 980,
      y: 320,
      routes: [
        SignalRoute(
          id: 'C30_R1',
          name: 'C30 Route 1 (Towards C28)',
          requiredBlocksClear: ['107', '105', '103'],
          requiredPointPositions: {'78B': PointPosition.normal},
          pathBlocks: ['109', '107', '105', '103', '101'],
          protectedBlocks: ['109', '107', '105'],
        ),
        SignalRoute(
          id: 'C30_R2',
          name: 'C30 Route 2 (Via Crossover)',
          requiredBlocksClear: [
            'crossover109',
            'crossover106',
            '106',
            '108',
            '110'
          ],
          requiredPointPositions: {
            '78B': PointPosition.reverse,
            '78A': PointPosition.reverse
          },
          conflictingRoutes: ['C31_R1', 'C31_R2'],
          pathBlocks: [
            '109',
            'crossover109',
            'crossover106',
            '106',
            '108',
            '110'
          ],
          protectedBlocks: ['109', 'crossover109', 'crossover106'],
        ),
      ],
    );

    signals['C28'] = Signal(
      id: 'C28',
      x: 400,
      y: 320,
      routes: [
        SignalRoute(
          id: 'C28_R1',
          name: 'Bay Exit (Westbound)',
          requiredBlocksClear: ['103', '101'],
          requiredPointPositions: {},
          pathBlocks: ['105', '103', '101'],
          protectedBlocks: ['103', '101'],
        ),
      ],
    );

    // FIXED: New signals for expanded network
    signals['C35'] = Signal(
      id: 'C35',
      x: 2400,
      y: 80,
      routes: [
        SignalRoute(
          id: 'C35_R1',
          name: 'Victoria Entry',
          requiredBlocksClear: ['126', '128'],
          requiredPointPositions: {},
          pathBlocks: ['124', '126', '128'],
          protectedBlocks: ['126', '128'],
        ),
      ],
    );

    signals['C37'] = Signal(
      id: 'C37',
      x: 3800,
      y: 80,
      routes: [
        SignalRoute(
          id: 'C37_R1',
          name: 'Paddington Entry',
          requiredBlocksClear: ['138', '140'],
          requiredPointPositions: {},
          pathBlocks: ['136', '138', '140'],
          protectedBlocks: ['138', '140'],
        ),
      ],
    );

    signals['C39'] = Signal(
      id: 'C39',
      x: 6000,
      y: 680,
      routes: [
        SignalRoute(
          id: 'C39_R1',
          name: 'Waterloo Departure',
          requiredBlocksClear: ['170', '172'],
          requiredPointPositions: {},
          pathBlocks: ['168', '170', '172'],
          protectedBlocks: ['170', '172'],
        ),
      ],
    );

    trainStops['T31'] = TrainStop(id: 'T31', signalId: 'C31', x: 400, y: 120);
    trainStops['T33'] = TrainStop(id: 'T33', signalId: 'C33', x: 1220, y: 120);
    trainStops['T30'] = TrainStop(id: 'T30', signalId: 'C30', x: 980, y: 340);
    trainStops['T28'] = TrainStop(id: 'T28', signalId: 'C28', x: 380, y: 340);
    trainStops['T35'] = TrainStop(id: 'T35', signalId: 'C35', x: 2400, y: 120);
    trainStops['T37'] = TrainStop(id: 'T37', signalId: 'C37', x: 3800, y: 120);
    trainStops['T39'] = TrainStop(id: 'T39', signalId: 'C39', x: 6000, y: 720);

    // FIXED: WiFi Antennas for CBTC coverage across expanded network
    wifiAntennas['W1'] = WifiAntenna(id: 'W1', x: 500, y: 200, isActive: true);
    wifiAntennas['W2'] = WifiAntenna(id: 'W2', x: 1200, y: 200, isActive: true);
    wifiAntennas['W3'] = WifiAntenna(id: 'W3', x: 2000, y: 200, isActive: true);
    wifiAntennas['W4'] = WifiAntenna(id: 'W4', x: 2600, y: 200, isActive: true); // Victoria
    wifiAntennas['W5'] = WifiAntenna(id: 'W5', x: 3400, y: 200, isActive: true);
    wifiAntennas['W6'] = WifiAntenna(id: 'W6', x: 4000, y: 200, isActive: true); // Paddington
    wifiAntennas['W7'] = WifiAntenna(id: 'W7', x: 4800, y: 400, isActive: true);
    wifiAntennas['W8'] = WifiAntenna(id: 'W8', x: 5400, y: 600, isActive: true);
    wifiAntennas['W9'] = WifiAntenna(id: 'W9', x: 6200, y: 700, isActive: true); // Waterloo
    wifiAntennas['W10'] = WifiAntenna(id: 'W10', x: 5000, y: 700, isActive: true);
    wifiAntennas['W11'] = WifiAntenna(id: 'W11', x: 3000, y: 700, isActive: true);
    wifiAntennas['W12'] = WifiAntenna(id: 'W12', x: 1000, y: 700, isActive: true);
    wifiAntennas['W13'] = WifiAntenna(id: 'W13', x: -400, y: 700, isActive: true); // Camden

    // Transponders at key locations
    transponders['TP1'] = Transponder(id: 'TP1', type: TransponderType.t1, x: 300, y: 100, description: 'Central West');
    transponders['TP2'] = Transponder(id: 'TP2', type: TransponderType.t2, x: 1100, y: 100, description: 'Central East');
    transponders['TP3'] = Transponder(id: 'TP3', type: TransponderType.t3, x: 2500, y: 100, description: 'Victoria');
    transponders['TP4'] = Transponder(id: 'TP4', type: TransponderType.t6, x: 3900, y: 100, description: 'Paddington');
    transponders['TP5'] = Transponder(id: 'TP5', type: TransponderType.t1, x: 6100, y: 700, description: 'Waterloo');

    _logEvent(
        '🚉 EXPANDED LOOP NETWORK INITIALIZED: 5 stations, 8 platforms, 7 signals, 7 points, ${blocks.length} blocks, ${trainStops.length} train stops, ${wifiAntennas.length} WiFi antennas, ${transponders.length} transponders');
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

  void _checkDoorAutoClose() {
    final now = DateTime.now();
    for (var train in trains) {
      if (train.doorsOpen && train.doorsOpenedAt != null) {
        final duration = now.difference(train.doorsOpenedAt!);
        if (duration.inSeconds >= 10) {
          closeTrainDoors(train.id);
          _logEvent('⏰ ${train.name} doors auto-closed after 10 seconds');
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

    for (var trainId in trainIds) {
      final train = trains.firstWhere((t) => t.id == trainId);
      final safeBlock = _findSafeReverseBlock(train);
      reverseInstructions[trainId] = safeBlock;
      blocksToClear.add(train.currentBlockId ?? 'unknown');
    }

    return CollisionRecoveryPlan(
      collisionId: collisionId,
      trainsInvolved: trainIds,
      reverseInstructions: reverseInstructions,
      blocksToClear: blocksToClear,
      state: CollisionRecoveryState.detected,
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

  void addTrainToBlock(String blockId) {
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

    final train = Train(
      id: 'T$nextTrainNumber',
      name: 'Train $nextTrainNumber',
      vin: _generateVin(nextTrainNumber, false),
      x: _getInitialXForBlock(blockId),
      y: block.y,
      speed: 0,
      targetSpeed: 0,
      direction: direction,
      color: Colors.primaries[nextTrainNumber % Colors.primaries.length],
      controlMode: TrainControlMode.automatic,
      manualStop: false,
      isCbtcEquipped: false,
      cbtcMode: CbtcMode.off,
    );

    trains.add(train);
    nextTrainNumber++;
    _updateBlockOccupation();

    String trackType = block.y == 100 ? 'EASTBOUND road' : 'WESTBOUND road';
    _logEvent(
        '🚂 Train ${nextTrainNumber - 1} added at block $blockId ($trackType) - AUTO mode');
    notifyListeners();
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

  void toggleSelfNormalizingPoints() {
    selfNormalizingPoints = !selfNormalizingPoints;
    _logEvent(selfNormalizingPoints
        ? '🔄 Self-normalizing points ENABLED'
        : '⏸️ Self-normalizing points DISABLED');
    notifyListeners();
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

  void updateSimulation() {
    if (!isRunning) return;

    tickCount++;
    _clearExpiredReservations();
    _checkDoorAutoClose();

    // Check AB-based point deadlocks every simulation tick
    _arePointsDeadlocked();

    _checkTrainStops();
    _checkAutoSignals();
    _updateAxleCounters();
    _updateMovementAuthorities();

    for (var train in trains) {
      // ========== EARLY EXIT CONDITIONS ==========

      // 1. Door override - train cannot move with open doors
      if (train.doorsOpen) {
        train.targetSpeed = 0;
        train.speed = 0;
        continue;
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

      // ========== NORMAL MOVEMENT LOGIC ==========

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

    // Simple next block logic
    if (train.direction > 0) {
      // Eastbound
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
    } else {
      // Westbound
      switch (currentBlock.id) {
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
    }
    return null;
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
    final point78A = points['78A'];
    final point78B = points['78B'];

    if (train.x < 600) {
      if (train.y > 200) {
        train.y = 300;
      } else {
        train.y = 100;
      }
      train.rotation = 0.0;
    } else if (train.x >= 600 && train.x < 800) {
      if (point78A?.position == PointPosition.reverse &&
          point78B?.position == PointPosition.reverse) {
        if (train.x < 700) {
          double progress = (train.x - 600) / 100;
          train.y = 100 + (100 * progress);
          train.rotation = 0.785398;
        } else {
          double progress = (train.x - 700) / 100;
          train.y = 200 + (100 * progress);
          train.rotation = 0.785398;
        }
      } else {
        if (train.y < 200) {
          train.y = 100;
        } else {
          train.y = 300;
        }
        train.rotation = 0.0;
      }
    } else {
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
    final point78A = points['78A'];
    final point78B = points['78B'];

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

    _logEvent(
        '🚨 DERAILMENT PREVENTED: ${train.name} tried to move $fromBlockId→$toBlockId (no track connection)');
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

    buffer.writeln('</RailwayLayout>');

    _logEvent('📄 Layout exported to XML (${buffer.length} bytes)');
    return buffer.toString();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _cancellationTimer?.cancel();
    _simulationTimer?.cancel();
    super.dispose();
  }
}
