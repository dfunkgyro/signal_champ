import 'dart:math' as math;
import '../models/terminal_station/axle_counter.dart';

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

  // Instance variables
  int? _lastAC109Count;
  int _ab111EntryCount = 0;

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
