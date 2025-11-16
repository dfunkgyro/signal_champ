import 'package:flutter_test/flutter_test.dart';
import 'package:rail_champ/screens/terminal_station_models.dart';

void main() {
  group('Station Model Tests', () {
    test('Station should be created with correct properties', () {
      final station = Station(
        id: 'MA1',
        name: 'Mainline Station 1',
        platformId: 'P1',
        x: 1110,
        y: 100,
      );

      expect(station.id, 'MA1');
      expect(station.name, 'Mainline Station 1');
      expect(station.platformId, 'P1');
      expect(station.x, 1110);
      expect(station.y, 100);
    });

    test('Station should have default occupied status as false', () {
      final station = Station(
        id: 'MA1',
        name: 'Mainline Station 1',
        platformId: 'P1',
        x: 1110,
        y: 100,
      );

      expect(station.occupied, false);
    });

    test('Station occupied status can be updated', () {
      final station = Station(
        id: 'MA1',
        name: 'Mainline Station 1',
        platformId: 'P1',
        x: 1110,
        y: 100,
        occupied: true,
      );

      expect(station.occupied, true);
    });
  });

  group('TimetableEntry Model Tests', () {
    test('TimetableEntry should be created with sequential stops', () {
      final entry = TimetableEntry(
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
            departureTime: null, // Terminus
            dwellTime: const Duration(seconds: 0),
            platformId: 'P1',
          ),
        ],
      );

      expect(entry.id, 'TT001');
      expect(entry.trainServiceNumber, '101');
      expect(entry.stops.length, 3);
      expect(entry.stops[0].stationId, 'MA1');
      expect(entry.stops[1].stationId, 'MA2');
      expect(entry.stops[2].stationId, 'MA3');
    });

    test('TimetableEntry should identify origin station correctly', () {
      final entry = TimetableEntry(
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

      expect(entry.originStation, 'MA1');
    });

    test('TimetableEntry should identify terminus station correctly', () {
      final entry = TimetableEntry(
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

      expect(entry.terminusStation, 'MA3');
    });

    test('TimetableEntry should get next stop correctly', () {
      final entry = TimetableEntry(
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

      expect(entry.getNextStop('MA1')?.stationId, 'MA2');
      expect(entry.getNextStop('MA2')?.stationId, 'MA3');
      expect(entry.getNextStop('MA3'), null); // No next stop at terminus
    });

    test('TimetableEntry should return null for invalid current station', () {
      final entry = TimetableEntry(
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
        ],
      );

      expect(entry.getNextStop('INVALID'), null);
    });
  });

  group('TimetableStop Model Tests', () {
    test('TimetableStop should be created for origin station', () {
      final stop = TimetableStop(
        stationId: 'MA1',
        arrivalTime: null, // Origin has no arrival time
        departureTime: const Duration(minutes: 0),
        dwellTime: const Duration(seconds: 30),
        platformId: 'P1',
      );

      expect(stop.stationId, 'MA1');
      expect(stop.arrivalTime, null);
      expect(stop.departureTime, const Duration(minutes: 0));
      expect(stop.dwellTime, const Duration(seconds: 30));
      expect(stop.platformId, 'P1');
    });

    test('TimetableStop should be created for intermediate station', () {
      final stop = TimetableStop(
        stationId: 'MA2',
        arrivalTime: const Duration(minutes: 2),
        departureTime: const Duration(minutes: 3),
        dwellTime: const Duration(seconds: 60),
        platformId: 'P2',
      );

      expect(stop.stationId, 'MA2');
      expect(stop.arrivalTime, const Duration(minutes: 2));
      expect(stop.departureTime, const Duration(minutes: 3));
      expect(stop.dwellTime, const Duration(seconds: 60));
    });

    test('TimetableStop should be created for terminus station', () {
      final stop = TimetableStop(
        stationId: 'MA3',
        arrivalTime: const Duration(minutes: 5),
        departureTime: null, // Terminus has no departure
        dwellTime: const Duration(seconds: 0),
        platformId: 'P1',
      );

      expect(stop.stationId, 'MA3');
      expect(stop.arrivalTime, const Duration(minutes: 5));
      expect(stop.departureTime, null);
      expect(stop.dwellTime, const Duration(seconds: 0));
    });

    test('TimetableStop should identify if it is origin', () {
      final originStop = TimetableStop(
        stationId: 'MA1',
        arrivalTime: null,
        departureTime: const Duration(minutes: 0),
        dwellTime: const Duration(seconds: 30),
        platformId: 'P1',
      );

      final intermediateStop = TimetableStop(
        stationId: 'MA2',
        arrivalTime: const Duration(minutes: 2),
        departureTime: const Duration(minutes: 3),
        dwellTime: const Duration(seconds: 60),
        platformId: 'P2',
      );

      expect(originStop.isOrigin, true);
      expect(intermediateStop.isOrigin, false);
    });

    test('TimetableStop should identify if it is terminus', () {
      final terminusStop = TimetableStop(
        stationId: 'MA3',
        arrivalTime: const Duration(minutes: 5),
        departureTime: null,
        dwellTime: const Duration(seconds: 0),
        platformId: 'P1',
      );

      final intermediateStop = TimetableStop(
        stationId: 'MA2',
        arrivalTime: const Duration(minutes: 2),
        departureTime: const Duration(minutes: 3),
        dwellTime: const Duration(seconds: 60),
        platformId: 'P2',
      );

      expect(terminusStop.isTerminus, true);
      expect(intermediateStop.isTerminus, false);
    });
  });

  group('GhostTrain Model Tests', () {
    test('GhostTrain should be created with timetable reference', () {
      final ghostTrain = GhostTrain(
        id: 'GHOST001',
        timetableId: 'TT001',
        serviceNumber: '101',
        currentStationId: null,
        assignedToRealTrain: false,
      );

      expect(ghostTrain.id, 'GHOST001');
      expect(ghostTrain.timetableId, 'TT001');
      expect(ghostTrain.serviceNumber, '101');
      expect(ghostTrain.currentStationId, null);
      expect(ghostTrain.assignedToRealTrain, false);
      expect(ghostTrain.realTrainId, null);
    });

    test('GhostTrain should be assignable to real train', () {
      final ghostTrain = GhostTrain(
        id: 'GHOST001',
        timetableId: 'TT001',
        serviceNumber: '101',
        currentStationId: 'MA1',
        assignedToRealTrain: true,
        realTrainId: 'TRAIN_001',
      );

      expect(ghostTrain.assignedToRealTrain, true);
      expect(ghostTrain.realTrainId, 'TRAIN_001');
    });

    test('GhostTrain should track current station progress', () {
      final ghostTrain = GhostTrain(
        id: 'GHOST001',
        timetableId: 'TT001',
        serviceNumber: '101',
        currentStationId: 'MA2',
        assignedToRealTrain: false,
      );

      expect(ghostTrain.currentStationId, 'MA2');
    });
  });

  group('TimetableRoute Model Tests', () {
    test('TimetableRoute should map station sequences to signal routes', () {
      final route = TimetableRoute(
        fromStationId: 'MA1',
        toStationId: 'MA2',
        signalId: 'C31',
        routeId: 'C31_R2',
        requiredBlocks: ['104', '106', 'crossover106', 'crossover109', '109', '111'],
      );

      expect(route.fromStationId, 'MA1');
      expect(route.toStationId, 'MA2');
      expect(route.signalId, 'C31');
      expect(route.routeId, 'C31_R2');
      expect(route.requiredBlocks.length, 6);
    });

    test('TimetableRoute should support multiple routes between stations', () {
      final route1 = TimetableRoute(
        fromStationId: 'MA1',
        toStationId: 'MA2',
        signalId: 'C31',
        routeId: 'C31_R1',
        requiredBlocks: ['106', '108', '110'],
      );

      final route2 = TimetableRoute(
        fromStationId: 'MA1',
        toStationId: 'MA3',
        signalId: 'C31',
        routeId: 'C31_R2',
        requiredBlocks: ['104', '106', 'crossover106', 'crossover109', '109', '111'],
      );

      expect(route1.toStationId, 'MA2');
      expect(route2.toStationId, 'MA3');
      expect(route1.routeId != route2.routeId, true);
    });
  });

  // NOTE: TimetableManager is now integrated into TerminalStationController
  // Tests for timetable manager functionality are in controllers/terminal_station_controller_test.dart
}
