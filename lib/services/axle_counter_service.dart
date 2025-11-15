import 'dart:math' as math;
import 'package:flutter/foundation.dart';

// ============================================================================
// AXLE COUNTER SERVICE
// Advanced axle counter management with bidirectional tracking,
// imbalance detection, and automatic reset capabilities
// ============================================================================

/// Represents a physical axle counter device in the railway system
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

  // Additional tracking fields
  int totalDetections;
  List<AxleCounterEvent> eventHistory;
  bool isCalibrated;
  DateTime? lastMaintenanceDate;
  double accuracyPercentage;

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
    this.totalDetections = 0,
    List<AxleCounterEvent>? eventHistory,
    this.isCalibrated = true,
    this.lastMaintenanceDate,
    this.accuracyPercentage = 100.0,
  }) : eventHistory = eventHistory ?? [];

  /// Record a detection event
  void recordEvent(AxleCounterEvent event) {
    eventHistory.add(event);
    // Keep only last 100 events
    if (eventHistory.length > 100) {
      eventHistory.removeAt(0);
    }
  }

  /// Check if counter needs maintenance
  bool needsMaintenance() {
    if (lastMaintenanceDate == null) return true;
    final daysSinceMaintenance = DateTime.now().difference(lastMaintenanceDate!).inDays;
    return daysSinceMaintenance > 90 || accuracyPercentage < 95.0;
  }

  /// Get counter status summary
  Map<String, dynamic> getStatus() {
    return {
      'id': id,
      'count': count,
      'isCalibrated': isCalibrated,
      'accuracy': accuracyPercentage,
      'needsMaintenance': needsMaintenance(),
      'totalDetections': totalDetections,
      'lastDetection': lastDetectionTime?.toIso8601String(),
    };
  }
}

/// Event record for axle counter detections
class AxleCounterEvent {
  final DateTime timestamp;
  final String direction;
  final int previousCount;
  final int newCount;
  final String? trainId;
  final bool isAnomaly;

  AxleCounterEvent({
    required this.timestamp,
    required this.direction,
    required this.previousCount,
    required this.newCount,
    this.trainId,
    this.isAnomaly = false,
  });
}

/// Calculation methods for axle counter sections
enum ABCalculationMethod {
  simple,
  flowBalance,
  exitTracking,
  fullJunction,
  conservative,
  bidirectional,
}

/// Axle counter section occupancy result
class ABOccupancyResult {
  final String sectionId;
  final int occupancyValue;
  final int entryCount;
  final int exitCount;
  final int difference;
  final bool isOccupied;
  final bool needsReset;
  final double imbalancePercentage;
  final ABCalculationMethod method;
  final DateTime timestamp;

  ABOccupancyResult({
    required this.sectionId,
    required this.occupancyValue,
    required this.entryCount,
    required this.exitCount,
    required this.difference,
    required this.isOccupied,
    required this.needsReset,
    required this.imbalancePercentage,
    required this.method,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'sectionId': sectionId,
      'occupancyValue': occupancyValue,
      'entryCount': entryCount,
      'exitCount': exitCount,
      'difference': difference,
      'isOccupied': isOccupied,
      'needsReset': needsReset,
      'imbalancePercentage': imbalancePercentage,
      'method': method.toString(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Advanced Axle Counter Evaluator with comprehensive tracking
class AxleCounterService extends ChangeNotifier {
  final Map<String, AxleCounter> axleCounters;
  final Map<String, int> abResults = {};
  final Map<String, ABOccupancyResult> detailedResults = {};

  // Track bidirectional movement states
  final Map<String, int> _lastCounterValues = {};
  final Map<String, bool> _sectionOccupancyStates = {};
  final Map<String, ABCalculationMethod> _sectionMethods = {};

  // Anomaly detection
  final Map<String, List<int>> _counterHistory = {};
  final Map<String, int> _anomalyCount = {};

  // Maximum allowed imbalance before reset
  static const int MAX_IMBALANCE = 511;
  static const int WARNING_THRESHOLD = 400;

  // Performance metrics
  int totalResets = 0;
  int totalAnomalies = 0;
  DateTime? lastResetTime;

  // AB111 specific tracking
  int? _lastAC109Count;
  int _ab111EntryCount = 0;

  AxleCounterService(this.axleCounters) {
    _initializeSectionMethods();
  }

  /// Initialize calculation methods for each section
  void _initializeSectionMethods() {
    _sectionMethods['AB100'] = ABCalculationMethod.bidirectional;
    _sectionMethods['AB105'] = ABCalculationMethod.bidirectional;
    _sectionMethods['AB106'] = ABCalculationMethod.bidirectional;
    _sectionMethods['AB108'] = ABCalculationMethod.bidirectional;
    _sectionMethods['AB111'] = ABCalculationMethod.simple;
  }

  /// Main update method - recalculates all AB section occupations
  void updateABOccupations() {
    abResults.clear();
    detailedResults.clear();

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
    _updateSection('AB100', ac100, ac104);
    _updateSection('AB105', ac105, ac101);
    _updateSection('AB106', ac106, ac107);
    _updateSection('AB108', ac108, ac112);

    // AB111 uses simple logic
    abResults['AB111'] = _calculateAB111Simple(ac109);

    if (kDebugMode) {
      print('🔢 ACE Results: ${abResults.entries.map((e) => '${e.key}=${e.value}').join(', ')}');
    }

    notifyListeners();
  }

  /// Update a bidirectional section
  void _updateSection(String sectionId, int entryCounter, int exitCounter) {
    final occupancy = _calculateBidirectionalSection(sectionId, entryCounter, exitCounter);
    abResults[sectionId] = occupancy;

    final difference = (entryCounter - exitCounter).abs();
    final imbalancePercentage = (difference / MAX_IMBALANCE) * 100;

    detailedResults[sectionId] = ABOccupancyResult(
      sectionId: sectionId,
      occupancyValue: occupancy,
      entryCount: entryCounter,
      exitCount: exitCounter,
      difference: difference,
      isOccupied: occupancy > 0,
      needsReset: difference > MAX_IMBALANCE,
      imbalancePercentage: imbalancePercentage,
      method: _sectionMethods[sectionId] ?? ABCalculationMethod.bidirectional,
    );
  }

  /// Simple calculation for AB111
  int _calculateAB111Simple(int ac109) {
    final result = ac109 % 2 == 1 ? 1 : 0;

    if (kDebugMode) {
      if (result == 1) {
        print('🚂 AB111: OCCUPIED (ac109:$ac109 is ODD)');
      } else {
        print('🚂 AB111: CLEAR (ac109:$ac109 is EVEN)');
      }
    }

    final difference = (ac109 - (_lastAC109Count ?? 0)).abs();
    detailedResults['AB111'] = ABOccupancyResult(
      sectionId: 'AB111',
      occupancyValue: result,
      entryCount: ac109,
      exitCount: 0,
      difference: difference,
      isOccupied: result > 0,
      needsReset: false,
      imbalancePercentage: 0.0,
      method: ABCalculationMethod.simple,
    );

    _lastAC109Count = ac109;
    return result;
  }

  /// Calculate bidirectional section occupancy
  int _calculateBidirectionalSection(String sectionId, int entryCounter, int exitCounter) {
    final difference = (entryCounter - exitCounter).abs();

    // Check if we need to reset due to exceeding maximum imbalance
    if (difference > MAX_IMBALANCE) {
      _resetCountersForSection(sectionId);
      if (kDebugMode) {
        print('🔄 $sectionId COUNTERS RESET: Exceeded maximum imbalance of $MAX_IMBALANCE');
      }
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

    // Detect bidirectional movement via exit counter
    if (exitCounter > entryCounter) {
      if (kDebugMode) {
        print('🔄 $sectionId: Bidirectional movement detected via exit counter');
      }
      _sectionOccupancyStates[sectionId] = true;
      _lastCounterValues['${sectionId}_entry'] = entryCounter;
      _lastCounterValues['${sectionId}_exit'] = exitCounter;
      return 1;
    }

    // Normal case: section occupied if entry counter ahead of exit counter
    final result = entryCounter > exitCounter ? 1 : 0;

    // Debug output
    if (kDebugMode) {
      if (result == 1) {
        print('📊 $sectionId: OCCUPIED (entry:$entryCounter > exit:$exitCounter)');
      } else {
        print('📊 $sectionId: CLEAR (entry:$entryCounter == exit:$exitCounter)');
      }
    }

    // State machine for bidirectional movement
    if (currentOccupancy) {
      // Section is currently occupied
      if (exitIncreased) {
        currentOccupancy = false;
        if (kDebugMode) print('🚂 $sectionId: Train EXITED via exit counter');
      } else if (entryDecreased && entryCounter == exitCounter) {
        currentOccupancy = false;
        if (kDebugMode) print('🚂 $sectionId: Train EXITED via entry counter (bidirectional)');
      }
    } else {
      // Section is currently unoccupied
      if (entryIncreased) {
        currentOccupancy = true;
        if (kDebugMode) print('🚂 $sectionId: Train ENTERED via entry counter');
      } else if (exitDecreased && exitCounter < entryCounter) {
        currentOccupancy = true;
        if (kDebugMode) print('🚂 $sectionId: Train ENTERED via exit counter (bidirectional)');
      }
    }

    // Update state
    _sectionOccupancyStates[sectionId] = currentOccupancy;
    _lastCounterValues['${sectionId}_entry'] = entryCounter;
    _lastCounterValues['${sectionId}_exit'] = exitCounter;

    return currentOccupancy ? 1 : 0;
  }

  /// Find nearest axle counter to a train position
  String? findNearestAxleCounter(double trainX, double trainY, {double maxDistance = 50.0}) {
    String? nearestCounter;
    double minDistance = maxDistance;

    for (final counter in axleCounters.values) {
      final distance = math.sqrt(
        math.pow(trainX - counter.x, 2) + math.pow(trainY - counter.y, 2)
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearestCounter = counter.id;
      }
    }

    // Debug output
    if (nearestCounter != null && kDebugMode) {
      final counter = axleCounters[nearestCounter]!;
      final actualDistance = math.sqrt(
        math.pow(trainX - counter.x, 2) + math.pow(trainY - counter.y, 2)
      );
      print('🔍 Train at ($trainX, $trainY) detected by $nearestCounter (distance: ${actualDistance.toStringAsFixed(1)})');
    }

    return nearestCounter;
  }

  /// Reset counters for a specific section
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

    totalResets++;
    lastResetTime = DateTime.now();
    notifyListeners();
  }

  /// Reset all counters to zero
  void resetAllCounters() {
    for (var counter in axleCounters.values) {
      counter.count = 0;
      counter.totalDetections = 0;
    }
    _lastCounterValues.clear();
    _sectionOccupancyStates.clear();
    abResults.clear();
    detailedResults.clear();

    totalResets++;
    lastResetTime = DateTime.now();

    if (kDebugMode) {
      print('🔄 ALL AXLE COUNTERS RESET TO ZERO');
    }

    notifyListeners();
  }

  /// Get comprehensive imbalance status for all sections
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
      'AB100': _getSectionImbalance('AB100', ac100, ac104),
      'AB105': _getSectionImbalance('AB105', ac101, ac105),
      'AB106': _getSectionImbalance('AB106', ac106, ac107),
      'AB108': _getSectionImbalance('AB108', ac108, ac112),
      'AB111': _getSectionImbalance('AB111', ac109, ac111),
    };
  }

  /// Get imbalance info for a specific section
  Map<String, dynamic> _getSectionImbalance(String sectionId, int counter1, int counter2) {
    final difference = (counter1 - counter2).abs();
    final percentage = (difference / MAX_IMBALANCE) * 100;

    return {
      'counters': [counter1, counter2],
      'difference': difference,
      'max_imbalance': MAX_IMBALANCE,
      'remaining': MAX_IMBALANCE - difference,
      'percentage': '${percentage.toStringAsFixed(1)}%',
      'needs_reset': difference > MAX_IMBALANCE,
      'warning': difference > WARNING_THRESHOLD,
    };
  }

  /// Update an axle counter with new detection
  void updateAxleCounter(String counterId, int direction, bool isEntering, {String? trainId}) {
    final counter = axleCounters[counterId];
    if (counter == null) return;

    final oldCount = counter.count;
    final directionStr = direction > 0 ? 'Eastbound' : 'Westbound';

    if (isEntering) {
      counter.count++;
      counter.totalDetections++;
      counter.lastDirection = directionStr;
      counter.lastDetectionTime = DateTime.now();
      counter.lastTrainDetected = trainId;
      counter.lastTrainDetectionTime = DateTime.now();

      counter.recordEvent(AxleCounterEvent(
        timestamp: DateTime.now(),
        direction: directionStr,
        previousCount: oldCount,
        newCount: counter.count,
        trainId: trainId,
      ));

      if (kDebugMode) {
        print('🚂 ENTRY: $counterId detected train entry - Count: $oldCount → ${counter.count}');
      }
    } else {
      counter.count = math.max(0, counter.count - 1);
      counter.lastDirection = directionStr;
      counter.lastDetectionTime = DateTime.now();

      counter.recordEvent(AxleCounterEvent(
        timestamp: DateTime.now(),
        direction: directionStr,
        previousCount: oldCount,
        newCount: counter.count,
        trainId: trainId,
      ));

      if (kDebugMode) {
        print('🚂 EXIT: $counterId detected train exit - Count: $oldCount → ${counter.count}');
      }
    }

    // Update AB occupations
    updateABOccupations();

    // Check and report imbalance status
    _checkImbalanceWarnings();

    notifyListeners();
  }

  /// Check and warn about approaching imbalances
  void _checkImbalanceWarnings() {
    final imbalanceStatus = getImbalanceStatus();

    for (var abId in ['AB100', 'AB105', 'AB106', 'AB108', 'AB111']) {
      final status = imbalanceStatus[abId]!;
      final occupancy = abResults[abId] ?? 0;

      if (kDebugMode) {
        print('📊 $abId: $occupancy (Diff: ${status['difference']}/${MAX_IMBALANCE}) ${occupancy > 0 ? '🔴 OCCUPIED' : '🟢 CLEAR'}');
      }

      if (status['warning'] == true && kDebugMode) {
        print('⚠️  $abId approaching maximum imbalance: ${status['difference']}/$MAX_IMBALANCE');
      }
    }
  }

  /// Check if an AB section is occupied
  bool isABOccupied(String abId) {
    updateABOccupations();
    return abResults[abId] != null && abResults[abId]! > 0;
  }

  /// Reset a specific AB section
  void resetAB(String abId) {
    _resetCountersForSection(abId);
    _sectionOccupancyStates[abId] = false;
    abResults[abId] = 0;
    updateABOccupations();

    if (kDebugMode) {
      print('🔄 $abId counters manually reset');
    }

    notifyListeners();
  }

  /// Get detailed result for a section
  ABOccupancyResult? getDetailedResult(String sectionId) {
    return detailedResults[sectionId];
  }

  /// Get all counters needing maintenance
  List<AxleCounter> getCountersNeedingMaintenance() {
    return axleCounters.values
        .where((counter) => counter.needsMaintenance())
        .toList();
  }

  /// Export system diagnostics
  Map<String, dynamic> getDiagnostics() {
    return {
      'totalCounters': axleCounters.length,
      'totalResets': totalResets,
      'totalAnomalies': totalAnomalies,
      'lastResetTime': lastResetTime?.toIso8601String(),
      'abResults': abResults,
      'imbalanceStatus': getImbalanceStatus(),
      'countersNeedingMaintenance': getCountersNeedingMaintenance().length,
      'detailedResults': detailedResults.map((k, v) => MapEntry(k, v.toMap())),
    };
  }
}
