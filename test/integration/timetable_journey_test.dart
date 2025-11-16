import 'package:flutter_test/flutter_test.dart';
import 'package:rail_champ/controllers/timetable_controller.dart';
import 'package:rail_champ/controllers/terminal_station_controller.dart';
import 'package:rail_champ/models/timetable_model.dart';
import 'package:rail_champ/screens/terminal_station_models.dart';

/// Integration tests for complete timetable journeys
/// Tests the full workflow: MA1 → MA2 → MA3
void main() {
  group('Complete Timetable Journey Integration Tests', () {
    late TimetableController timetableController;
    late TerminalStationController stationController;

    setUp(() {
      timetableController = TimetableController();
      stationController = TerminalStationController();
      timetableController.createDefaultTimetable();
    });

    test('Journey MA1 → MA2 → MA3: Full sequence with route setting', () async {
      // PHASE 1: Setup - Train spawns at MA1
      final train = Train(
        id: 'TRAIN_001',
        name: 'Train 1',
        vin: 'VIN001',
        x: 1110, // Center of MA1 (Platform 1)
        y: 100,
        speed: 0,
        targetSpeed: 0,
        direction: 1,
        color: const Color(0xFF00FF00),
        controlMode: TrainControlMode.automatic,
        cbtcMode: CbtcMode.auto,
        currentBlockId: '110',
      );

      // Assign timetable to train
      final timetable = timetableController.timetableManager.timetables.first;
      final ghostTrain = timetableController.timetableManager.createGhostTrain(timetable.id);
      timetableController.timetableManager.assignGhostTrainToReal(ghostTrain!.id, train.id);

      expect(ghostTrain.assignedToRealTrain, true);
      expect(ghostTrain.realTrainId, train.id);

      // PHASE 2: At MA1 - Doors open, dwell, prepare for departure
      stationController.trains.add(train);

      // Check current station
      final currentStation = timetableController.getTrainCurrentStation(train);
      expect(currentStation, 'MA1');

      // Get next stop
      final nextStop = timetableController.getNextStop(train);
      expect(nextStop, isNotNull);
      expect(nextStop!.stationId, 'MA2');
      expect(nextStop.platformId, 'P2'); // Bay platform

      // Get route from MA1 to MA2
      final route1 = timetableController.getRouteForJourney('MA1', 'MA2');
      expect(route1, isNotNull);
      expect(route1!.fromStationId, 'MA1');
      expect(route1.toStationId, 'MA2');
      expect(route1.signalId, 'C31');
      expect(route1.routeId, 'C31_R2'); // Route to bay platform via crossover

      // Simulate doors opening at MA1
      train.doorsOpen = true;
      train.doorsOpenedAt = DateTime.now();

      // Wait for dwell time (simulated)
      await Future.delayed(const Duration(milliseconds: 100));

      // Dwell time should be tracked
      final currentStop = timetable.stops[0];
      expect(currentStop.stationId, 'MA1');
      expect(currentStop.dwellTime, greaterThan(Duration.zero));

      // PHASE 3: Departure from MA1 to MA2
      // In real system, this would trigger route setting
      // Signal C31 should be set to route R2 (to bay platform)
      train.doorsOpen = false;
      train.doorsOpenedAt = null;

      // Simulate train movement toward MA2
      // Train should travel via crossover to bay platform
      train.x = 900; // In transit
      train.y = 200; // Moving toward lower track
      train.speed = 5;

      // Train not at any station during transit
      final transitStation = timetableController.getTrainCurrentStation(train);
      expect(transitStation, null);

      // PHASE 4: Arrival at MA2 (Bay Platform)
      train.x = 1110; // Center of MA2
      train.y = 300; // Bay platform (lower track)
      train.speed = 0;
      train.currentBlockId = '111';

      // Update ghost train progress
      timetableController.updateGhostTrainProgress(train);

      // Verify arrival at MA2
      final arrivedStation = timetableController.getTrainCurrentStation(train);
      expect(arrivedStation, 'MA2');

      // Get updated ghost train state
      final ghostAfterMA2 = timetableController.timetableManager.getGhostTrainByRealTrain(train.id);
      expect(ghostAfterMA2?.currentStationId, 'MA2');

      // Get next stop from MA2
      final nextFromMA2 = timetableController.getNextStop(train);
      expect(nextFromMA2, isNotNull);
      expect(nextFromMA2!.stationId, 'MA3');

      // Get route from MA2 to MA3
      final route2 = timetableController.getRouteForJourney('MA2', 'MA3');
      expect(route2, isNotNull);
      expect(route2!.fromStationId, 'MA2');
      expect(route2.toStationId, 'MA3');
      expect(route2.signalId, 'C30'); // Departure signal from bay

      // Simulate doors opening at MA2
      train.doorsOpen = true;
      train.doorsOpenedAt = DateTime.now();

      await Future.delayed(const Duration(milliseconds: 100));

      // PHASE 5: Departure from MA2 to MA3
      train.doorsOpen = false;
      train.doorsOpenedAt = null;

      // Simulate train movement toward MA3
      // Train should travel via crossover back to upper track
      train.x = 1200;
      train.y = 200; // Moving toward upper track
      train.speed = 5;

      // PHASE 6: Arrival at MA3 (Terminus)
      train.x = 1490; // MA3 position (eastern end of platform 1)
      train.y = 100; // Upper track
      train.speed = 0;
      train.currentBlockId = '114';

      // Update ghost train progress
      timetableController.updateGhostTrainProgress(train);

      // Verify arrival at MA3
      final finalStation = timetableController.getTrainCurrentStation(train);
      expect(finalStation, 'MA3');

      // Get updated ghost train state
      final ghostAtMA3 = timetableController.timetableManager.getGhostTrainByRealTrain(train.id);
      expect(ghostAtMA3?.currentStationId, 'MA3');

      // At terminus - no next stop
      final nextFromMA3 = timetableController.getNextStop(train);
      expect(nextFromMA3, null); // Terminus reached

      // Journey complete
      expect(train.x, 1490);
      expect(train.y, 100);
      expect(train.speed, 0);
    });

    test('Journey MA1 → MA3 (Direct): Skip intermediate station', () {
      // Create timetable with only MA1 → MA3
      final directTimetable = TimetableEntry(
        id: 'TT_DIRECT',
        trainServiceNumber: '102',
        stops: [
          TimetableStop(
            stationId: 'MA1',
            arrivalTime: null,
            departureTime: const Duration(minutes: 0),
            dwellTime: const Duration(seconds: 30),
            platformId: 'P1',
          ),
          TimetableStop(
            stationId: 'MA3',
            arrivalTime: const Duration(minutes: 3),
            departureTime: null,
            dwellTime: const Duration(seconds: 0),
            platformId: 'P1',
          ),
        ],
      );

      timetableController.timetableManager.addTimetable(directTimetable);

      final train = Train(
        id: 'TRAIN_002',
        name: 'Train 2',
        vin: 'VIN002',
        x: 1110,
        y: 100,
        speed: 0,
        targetSpeed: 0,
        direction: 1,
        color: const Color(0xFFFF0000),
        controlMode: TrainControlMode.automatic,
        cbtcMode: CbtcMode.auto,
        currentBlockId: '110',
      );

      // Assign direct timetable
      final ghostTrain = timetableController.timetableManager.createGhostTrain('TT_DIRECT');
      timetableController.timetableManager.assignGhostTrainToReal(ghostTrain!.id, train.id);

      // At MA1, next should be MA3 (skip MA2)
      final nextStop = timetableController.getNextStop(train);
      expect(nextStop, isNotNull);
      expect(nextStop!.stationId, 'MA3');

      // Route should be direct via main line
      final route = timetableController.getRouteForJourney('MA1', 'MA3');
      expect(route, isNotNull);
      expect(route!.fromStationId, 'MA1');
      expect(route.toStationId, 'MA3');
      expect(route.signalId, 'C31');
      expect(route.routeId, 'C31_R1'); // Direct route (not via crossover)

      // Simulate arrival at MA3
      train.x = 1490;
      train.y = 100;
      train.currentBlockId = '114';

      timetableController.updateGhostTrainProgress(train);

      // Verify at MA3
      final station = timetableController.getTrainCurrentStation(train);
      expect(station, 'MA3');

      // No next stop - terminus
      final nextFromMA3 = timetableController.getNextStop(train);
      expect(nextFromMA3, null);
    });

    test('Multiple trains following different timetables simultaneously', () {
      // Train 1: MA1 → MA2 → MA3
      final train1 = Train(
        id: 'TRAIN_001',
        name: 'Train 1',
        vin: 'VIN001',
        x: 1110,
        y: 100,
        speed: 0,
        targetSpeed: 0,
        direction: 1,
        color: const Color(0xFF00FF00),
        controlMode: TrainControlMode.automatic,
        cbtcMode: CbtcMode.auto,
        currentBlockId: '110',
      );

      // Train 2: MA1 → MA3 (direct)
      final train2 = Train(
        id: 'TRAIN_002',
        name: 'Train 2',
        vin: 'VIN002',
        x: 1110,
        y: 100,
        speed: 0,
        targetSpeed: 0,
        direction: 1,
        color: const Color(0xFFFF0000),
        controlMode: TrainControlMode.automatic,
        cbtcMode: CbtcMode.auto,
        currentBlockId: '110',
      );

      // Create second timetable
      final directTimetable = TimetableEntry(
        id: 'TT_DIRECT',
        trainServiceNumber: '102',
        stops: [
          TimetableStop(
            stationId: 'MA1',
            arrivalTime: null,
            departureTime: const Duration(minutes: 0),
            dwellTime: const Duration(seconds: 30),
            platformId: 'P1',
          ),
          TimetableStop(
            stationId: 'MA3',
            arrivalTime: const Duration(minutes: 3),
            departureTime: null,
            dwellTime: const Duration(seconds: 0),
            platformId: 'P1',
          ),
        ],
      );
      timetableController.timetableManager.addTimetable(directTimetable);

      // Assign timetables
      final timetable1 = timetableController.timetableManager.timetables.first;
      final ghost1 = timetableController.timetableManager.createGhostTrain(timetable1.id);
      final ghost2 = timetableController.timetableManager.createGhostTrain('TT_DIRECT');

      timetableController.timetableManager.assignGhostTrainToReal(ghost1!.id, train1.id);
      timetableController.timetableManager.assignGhostTrainToReal(ghost2!.id, train2.id);

      // Train 1 next stop should be MA2
      final next1 = timetableController.getNextStop(train1);
      expect(next1?.stationId, 'MA2');

      // Train 2 next stop should be MA3
      final next2 = timetableController.getNextStop(train2);
      expect(next2?.stationId, 'MA3');

      // Different routes
      final route1 = timetableController.getRouteForJourney('MA1', 'MA2');
      final route2 = timetableController.getRouteForJourney('MA1', 'MA3');

      expect(route1?.routeId, 'C31_R2'); // Via crossover to bay
      expect(route2?.routeId, 'C31_R1'); // Direct main line

      // Both trains should have independent ghost train tracking
      expect(ghost1.id != ghost2.id, true);
      expect(ghost1.timetableId != ghost2.timetableId, true);
    });

    test('Timetable should handle dwell time correctly at each station', () async {
      final timetable = TimetableEntry(
        id: 'TT_DWELL',
        trainServiceNumber: '103',
        stops: [
          TimetableStop(
            stationId: 'MA1',
            arrivalTime: null,
            departureTime: const Duration(minutes: 0),
            dwellTime: const Duration(seconds: 30),
            platformId: 'P1',
          ),
          TimetableStop(
            stationId: 'MA2',
            arrivalTime: const Duration(minutes: 2),
            departureTime: const Duration(minutes: 3),
            dwellTime: const Duration(minutes: 1), // 60 seconds
            platformId: 'P2',
          ),
          TimetableStop(
            stationId: 'MA3',
            arrivalTime: const Duration(minutes: 5),
            departureTime: null,
            dwellTime: const Duration(seconds: 0), // Terminus
            platformId: 'P1',
          ),
        ],
      );

      timetableController.timetableManager.addTimetable(timetable);

      final train = Train(
        id: 'TRAIN_003',
        name: 'Train 3',
        vin: 'VIN003',
        x: 1110,
        y: 100,
        speed: 0,
        targetSpeed: 0,
        direction: 1,
        color: const Color(0xFF0000FF),
        controlMode: TrainControlMode.automatic,
        cbtcMode: CbtcMode.auto,
      );

      final ghost = timetableController.timetableManager.createGhostTrain('TT_DWELL');
      timetableController.timetableManager.assignGhostTrainToReal(ghost!.id, train.id);

      // Test dwell time at MA1 (30 seconds)
      train.doorsOpen = true;
      train.doorsOpenedAt = DateTime.now().subtract(const Duration(seconds: 20));

      var isDwellComplete = timetableController.isDwellTimeComplete(train, timetable.stops[0]);
      expect(isDwellComplete, false); // Only 20 seconds elapsed

      train.doorsOpenedAt = DateTime.now().subtract(const Duration(seconds: 35));
      isDwellComplete = timetableController.isDwellTimeComplete(train, timetable.stops[0]);
      expect(isDwellComplete, true); // 35 seconds elapsed

      // Test dwell time at MA2 (60 seconds)
      train.x = 1110;
      train.y = 300;
      train.doorsOpenedAt = DateTime.now().subtract(const Duration(seconds: 45));

      isDwellComplete = timetableController.isDwellTimeComplete(train, timetable.stops[1]);
      expect(isDwellComplete, false); // Only 45 seconds elapsed

      train.doorsOpenedAt = DateTime.now().subtract(const Duration(seconds: 65));
      isDwellComplete = timetableController.isDwellTimeComplete(train, timetable.stops[1]);
      expect(isDwellComplete, true); // 65 seconds elapsed
    });

    test('System should handle train not following timetable (wrong platform)', () {
      final train = Train(
        id: 'TRAIN_004',
        name: 'Train 4',
        vin: 'VIN004',
        x: 1110,
        y: 300, // At P2, but timetable says P1
        speed: 0,
        targetSpeed: 0,
        direction: 1,
        color: const Color(0xFFFFFF00),
        controlMode: TrainControlMode.automatic,
        cbtcMode: CbtcMode.auto,
      );

      final timetable = timetableController.timetableManager.timetables.first;
      final ghost = timetableController.timetableManager.createGhostTrain(timetable.id);
      timetableController.timetableManager.assignGhostTrainToReal(ghost!.id, train.id);

      // Train is at MA2 (P2), but timetable first stop is MA1 (P1)
      final currentStation = timetableController.getTrainCurrentStation(train);
      expect(currentStation, 'MA2'); // Train physically at MA2

      // Timetable expects MA1
      expect(timetable.stops[0].stationId, 'MA1');
      expect(timetable.stops[0].platformId, 'P1');

      // System should detect mismatch
      expect(currentStation != timetable.stops[0].stationId, true);
    });
  });

  group('Timetable Auto-Routing Logic Tests', () {
    late TimetableController timetableController;

    setUp(() {
      timetableController = TimetableController();
      timetableController.createDefaultTimetable();
    });

    test('Auto-routing should set correct signal routes for MA1→MA2 journey', () {
      final route = timetableController.getRouteForJourney('MA1', 'MA2');

      expect(route, isNotNull);
      expect(route!.signalId, 'C31');
      expect(route.routeId, 'C31_R2');

      // Route should include crossover blocks
      expect(route.requiredBlocks.contains('crossover106'), true);
      expect(route.requiredBlocks.contains('crossover109'), true);
      expect(route.requiredBlocks.contains('109'), true);
      expect(route.requiredBlocks.contains('111'), true);
    });

    test('Auto-routing should set correct signal routes for MA2→MA3 journey', () {
      final route = timetableController.getRouteForJourney('MA2', 'MA3');

      expect(route, isNotNull);
      expect(route!.signalId, 'C30');
      expect(route.routeId, 'C30_R1');
    });

    test('Auto-routing should set correct signal routes for MA1→MA3 direct', () {
      final route = timetableController.getRouteForJourney('MA1', 'MA3');

      expect(route, isNotNull);
      expect(route!.signalId, 'C31');
      expect(route.routeId, 'C31_R1');

      // Direct route should NOT include crossover
      expect(route.requiredBlocks.contains('crossover106'), false);
      expect(route.requiredBlocks.contains('108'), true);
      expect(route.requiredBlocks.contains('110'), true);
      expect(route.requiredBlocks.contains('112'), true);
    });

    test('Auto-routing should return null for invalid station pairs', () {
      final route = timetableController.getRouteForJourney('INVALID', 'MA2');
      expect(route, null);

      final route2 = timetableController.getRouteForJourney('MA1', 'INVALID');
      expect(route2, null);
    });
  });
}
