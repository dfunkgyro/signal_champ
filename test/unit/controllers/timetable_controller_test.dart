import 'package:flutter_test/flutter_test.dart';
import 'package:rail_champ/controllers/timetable_controller.dart';
import 'package:rail_champ/models/timetable_model.dart';
import 'package:rail_champ/screens/terminal_station_models.dart';

void main() {
  group('TimetableController Tests', () {
    late TimetableController controller;

    setUp(() {
      controller = TimetableController();
    });

    test('TimetableController should initialize with default stations', () {
      final stations = controller.stations;

      expect(stations.length, 3);
      expect(stations.any((s) => s.id == 'MA1'), true);
      expect(stations.any((s) => s.id == 'MA2'), true);
      expect(stations.any((s) => s.id == 'MA3'), true);
    });

    test('TimetableController should map MA1 to Platform 1', () {
      final station = controller.getStationById('MA1');

      expect(station, isNotNull);
      expect(station!.name, 'Mainline Station 1');
      expect(station.platformId, 'P1');
      expect(station.y, 100); // Upper track
    });

    test('TimetableController should map MA2 to Bay Platform 2', () {
      final station = controller.getStationById('MA2');

      expect(station, isNotNull);
      expect(station!.name, 'Mainline Station 2 (Bay)');
      expect(station.platformId, 'P2');
      expect(station.y, 300); // Lower track
    });

    test('TimetableController should map MA3 to extended Platform 1', () {
      final station = controller.getStationById('MA3');

      expect(station, isNotNull);
      expect(station!.name, 'Mainline Station 3');
      expect(station.platformId, 'P1');
      expect(station.y, 100); // Upper track, further east
    });

    test('TimetableController should detect train at station', () {
      final train = Train(
        id: 'TRAIN_001',
        name: 'Train 1',
        vin: 'VIN001',
        x: 1110, // Center of MA1 platform
        y: 100,
        speed: 0,
        targetSpeed: 0,
        direction: 1,
        color: const Color(0xFF00FF00),
        controlMode: TrainControlMode.automatic,
      );

      final stationId = controller.getTrainCurrentStation(train);
      expect(stationId, 'MA1');
    });

    test('TimetableController should return null when train not at station', () {
      final train = Train(
        id: 'TRAIN_001',
        name: 'Train 1',
        vin: 'VIN001',
        x: 500, // Not at any station
        y: 100,
        speed: 0,
        targetSpeed: 0,
        direction: 1,
        color: const Color(0xFF00FF00),
        controlMode: TrainControlMode.automatic,
      );

      final stationId = controller.getTrainCurrentStation(train);
      expect(stationId, null);
    });

    test('TimetableController should get next timetable stop for train', () {
      final timetable = TimetableEntry(
        id: 'TT001',
        trainServiceNumber: '101',
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
            dwellTime: const Duration(seconds: 60),
            platformId: 'P2',
          ),
          TimetableStop(
            stationId: 'MA3',
            arrivalTime: const Duration(minutes: 5),
            departureTime: null,
            dwellTime: const Duration(seconds: 0),
            platformId: 'P1',
          ),
        ],
      );

      controller.timetableManager.addTimetable(timetable);

      final train = Train(
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
      );

      final ghostTrain = controller.timetableManager.createGhostTrain('TT001');
      controller.timetableManager.assignGhostTrainToReal(ghostTrain!.id, 'TRAIN_001');

      final nextStop = controller.getNextStop(train);
      expect(nextStop, isNotNull);
      expect(nextStop!.stationId, 'MA2');
    });

    test('TimetableController should return null at terminus', () {
      final timetable = TimetableEntry(
        id: 'TT001',
        trainServiceNumber: '101',
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
            arrivalTime: const Duration(minutes: 5),
            departureTime: null,
            dwellTime: const Duration(seconds: 0),
            platformId: 'P1',
          ),
        ],
      );

      controller.timetableManager.addTimetable(timetable);

      final train = Train(
        id: 'TRAIN_001',
        name: 'Train 1',
        vin: 'VIN001',
        x: 1490, // At MA3
        y: 100,
        speed: 0,
        targetSpeed: 0,
        direction: 1,
        color: const Color(0xFF00FF00),
        controlMode: TrainControlMode.automatic,
      );

      final ghostTrain = controller.timetableManager.createGhostTrain('TT001');
      controller.timetableManager.assignGhostTrainToReal(ghostTrain!.id, 'TRAIN_001');

      // Update ghost train to MA3
      final updatedGhost = GhostTrain(
        id: ghostTrain.id,
        timetableId: ghostTrain.timetableId,
        serviceNumber: ghostTrain.serviceNumber,
        currentStationId: 'MA3',
        assignedToRealTrain: true,
        realTrainId: 'TRAIN_001',
      );
      controller.timetableManager.ghostTrains[0] = updatedGhost;

      final nextStop = controller.getNextStop(train);
      expect(nextStop, null); // At terminus
    });

    test('TimetableController should get route for MA1 to MA2 journey', () {
      final route = controller.getRouteForJourney('MA1', 'MA2');

      expect(route, isNotNull);
      expect(route!.fromStationId, 'MA1');
      expect(route.toStationId, 'MA2');
      expect(route.signalId, 'C31');
      expect(route.routeId, 'C31_R2'); // Route to bay platform
    });

    test('TimetableController should get route for MA2 to MA3 journey', () {
      final route = controller.getRouteForJourney('MA2', 'MA3');

      expect(route, isNotNull);
      expect(route!.fromStationId, 'MA2');
      expect(route.toStationId, 'MA3');
      expect(route.signalId, 'C30');
      expect(route.routeId, 'C30_R1'); // Departure from bay
    });

    test('TimetableController should get route for MA1 to MA3 direct journey', () {
      final route = controller.getRouteForJourney('MA1', 'MA3');

      expect(route, isNotNull);
      expect(route!.fromStationId, 'MA1');
      expect(route.toStationId, 'MA3');
      expect(route.signalId, 'C31');
      expect(route.routeId, 'C31_R1'); // Direct route via main line
    });

    test('TimetableController should determine if dwell time is complete', () {
      final train = Train(
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
        doorsOpen: true,
        doorsOpenedAt: DateTime.now().subtract(const Duration(seconds: 40)),
      );

      final stop = TimetableStop(
        stationId: 'MA1',
        arrivalTime: null,
        departureTime: const Duration(minutes: 0),
        dwellTime: const Duration(seconds: 30),
        platformId: 'P1',
      );

      final isComplete = controller.isDwellTimeComplete(train, stop);
      expect(isComplete, true); // 40 seconds > 30 seconds
    });

    test('TimetableController should determine dwell time is not complete', () {
      final train = Train(
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
        doorsOpen: true,
        doorsOpenedAt: DateTime.now().subtract(const Duration(seconds: 20)),
      );

      final stop = TimetableStop(
        stationId: 'MA1',
        arrivalTime: null,
        departureTime: const Duration(minutes: 0),
        dwellTime: const Duration(seconds: 30),
        platformId: 'P1',
      );

      final isComplete = controller.isDwellTimeComplete(train, stop);
      expect(isComplete, false); // 20 seconds < 30 seconds
    });

    test('TimetableController should handle train not at timetabled platform', () {
      final train = Train(
        id: 'TRAIN_001',
        name: 'Train 1',
        vin: 'VIN001',
        x: 1110,
        y: 300, // At P2, but timetable says P1
        speed: 0,
        targetSpeed: 0,
        direction: 1,
        color: const Color(0xFF00FF00),
        controlMode: TrainControlMode.automatic,
        doorsOpen: true,
        doorsOpenedAt: DateTime.now().subtract(const Duration(seconds: 40)),
      );

      final stop = TimetableStop(
        stationId: 'MA1',
        arrivalTime: null,
        departureTime: const Duration(minutes: 0),
        dwellTime: const Duration(seconds: 30),
        platformId: 'P1', // Should be at P1, but train is at P2
      );

      final isComplete = controller.isDwellTimeComplete(train, stop);
      expect(isComplete, false); // Wrong platform
    });

    test('TimetableController should update ghost train current station', () {
      final timetable = TimetableEntry(
        id: 'TT001',
        trainServiceNumber: '101',
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
            dwellTime: const Duration(seconds: 60),
            platformId: 'P2',
          ),
        ],
      );

      controller.timetableManager.addTimetable(timetable);
      final ghostTrain = controller.timetableManager.createGhostTrain('TT001');
      controller.timetableManager.assignGhostTrainToReal(ghostTrain!.id, 'TRAIN_001');

      final train = Train(
        id: 'TRAIN_001',
        name: 'Train 1',
        vin: 'VIN001',
        x: 1110,
        y: 300, // At MA2
        speed: 0,
        targetSpeed: 0,
        direction: 1,
        color: const Color(0xFF00FF00),
        controlMode: TrainControlMode.automatic,
      );

      controller.updateGhostTrainProgress(train);

      final updated = controller.timetableManager.getGhostTrainByRealTrain('TRAIN_001');
      expect(updated?.currentStationId, 'MA2');
    });

    test('TimetableController should create default sample timetable', () {
      controller.createDefaultTimetable();

      final timetables = controller.timetableManager.timetables;
      expect(timetables.length, greaterThan(0));

      final firstTimetable = timetables.first;
      expect(firstTimetable.stops.length, 3); // MA1 → MA2 → MA3
      expect(firstTimetable.stops[0].stationId, 'MA1');
      expect(firstTimetable.stops[1].stationId, 'MA2');
      expect(firstTimetable.stops[2].stationId, 'MA3');
    });
  });

  group('TimetableController Integration with Auto Mode', () {
    late TimetableController controller;

    setUp(() {
      controller = TimetableController();
      controller.createDefaultTimetable();
    });

    test('Auto mode train should follow timetable sequence', () {
      // Create a train at MA1
      final train = Train(
        id: 'TRAIN_001',
        name: 'Train 1',
        vin: 'VIN001',
        x: 1110, // At MA1
        y: 100,
        speed: 0,
        targetSpeed: 0,
        direction: 1,
        color: const Color(0xFF00FF00),
        controlMode: TrainControlMode.automatic,
        cbtcMode: CbtcMode.auto,
      );

      // Assign ghost train
      final timetable = controller.timetableManager.timetables.first;
      final ghostTrain = controller.timetableManager.createGhostTrain(timetable.id);
      controller.timetableManager.assignGhostTrainToReal(ghostTrain!.id, train.id);

      // Get next stop - should be MA2
      final nextStop = controller.getNextStop(train);
      expect(nextStop, isNotNull);
      expect(nextStop!.stationId, 'MA2');

      // Get route to next stop
      final route = controller.getRouteForJourney('MA1', 'MA2');
      expect(route, isNotNull);
      expect(route!.signalId, 'C31');
    });

    test('Auto mode train should progress through all stations', () {
      final train = Train(
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
      );

      final timetable = controller.timetableManager.timetables.first;
      final ghostTrain = controller.timetableManager.createGhostTrain(timetable.id);
      controller.timetableManager.assignGhostTrainToReal(ghostTrain!.id, train.id);

      // At MA1, next should be MA2
      var nextStop = controller.getNextStop(train);
      expect(nextStop?.stationId, 'MA2');

      // Simulate arrival at MA2
      controller.updateGhostTrainProgress(train);
      final updated1 = controller.timetableManager.getGhostTrainByRealTrain(train.id);
      // Current station should still be MA1 until we manually update position

      // Move train to MA2
      train.x = 1110;
      train.y = 300;
      controller.updateGhostTrainProgress(train);

      // At MA2, next should be MA3
      nextStop = controller.getNextStop(train);
      expect(nextStop?.stationId, 'MA3');

      // Move train to MA3
      train.x = 1490;
      train.y = 100;
      controller.updateGhostTrainProgress(train);

      // At MA3 (terminus), next should be null
      nextStop = controller.getNextStop(train);
      expect(nextStop, null);
    });

    test('Should handle multiple trains with different timetables', () {
      // Create second timetable
      final timetable2 = TimetableEntry(
        id: 'TT002',
        trainServiceNumber: '102',
        stops: [
          TimetableStop(
            stationId: 'MA1',
            arrivalTime: null,
            departureTime: const Duration(minutes: 5),
            dwellTime: const Duration(seconds: 30),
            platformId: 'P1',
          ),
          TimetableStop(
            stationId: 'MA3',
            arrivalTime: const Duration(minutes: 10),
            departureTime: null,
            dwellTime: const Duration(seconds: 0),
            platformId: 'P1',
          ),
        ],
      );
      controller.timetableManager.addTimetable(timetable2);

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
      );

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
      );

      // Assign different timetables
      final ghost1 = controller.timetableManager.createGhostTrain('TT001');
      final ghost2 = controller.timetableManager.createGhostTrain('TT002');

      controller.timetableManager.assignGhostTrainToReal(ghost1!.id, train1.id);
      controller.timetableManager.assignGhostTrainToReal(ghost2!.id, train2.id);

      // Train 1 should go MA1 → MA2 → MA3
      final next1 = controller.getNextStop(train1);
      expect(next1?.stationId, 'MA2');

      // Train 2 should go MA1 → MA3 (direct)
      final next2 = controller.getNextStop(train2);
      expect(next2?.stationId, 'MA3');
    });
  });
}
