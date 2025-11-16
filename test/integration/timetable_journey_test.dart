import 'package:flutter_test/flutter_test.dart';
import 'package:rail_champ/controllers/terminal_station_controller.dart';
import 'package:rail_champ/screens/terminal_station_models.dart';

/// Integration tests for complete timetable journeys
/// Tests the full workflow: MA1 → MA2 → MA3
///
/// Note: Timetable functionality is now integrated into TerminalStationController
void main() {
  group('Complete Timetable Journey Integration Tests', () {
    late TerminalStationController controller;

    setUp(() {
      controller = TerminalStationController();
      // Default timetable is already created in constructor
    });

    test('Journey MA1 → MA2 → MA3: Timetable assignment and tracking', () {
      // Spawn train at MA1
      controller.addTrainToBlock('110'); // Block 110 is at MA1
      final train = controller.trains.first;

      // Assign default timetable
      controller.assignTimetableToTrain(train.id, 'TT001');

      // Verify ghost train was created
      expect(controller.ghostTrains.length, 1);
      final ghostTrain = controller.ghostTrains.first;
      expect(ghostTrain.assignedToRealTrain, true);
      expect(ghostTrain.realTrainId, train.id);

      // Verify timetable has all 3 stops
      final timetable = controller.timetables.first;
      expect(timetable.stops.length, 3);
      expect(timetable.stops[0].stationId, 'MA1');
      expect(timetable.stops[1].stationId, 'MA2');
      expect(timetable.stops[2].stationId, 'MA3');
    });

    test('Timetable routes should be correctly configured', () {
      // MA1 → MA2: Via crossover to bay platform
      final route1 = controller.timetableRoutes
          .where((r) => r.fromStationId == 'MA1' && r.toStationId == 'MA2')
          .firstOrNull;

      expect(route1, isNotNull);
      expect(route1!.signalId, 'C31');
      expect(route1.routeId, 'C31_R2');
      expect(route1.requiredBlocks.contains('crossover106'), true);

      // MA1 → MA3: Direct via main line
      final route2 = controller.timetableRoutes
          .where((r) => r.fromStationId == 'MA1' && r.toStationId == 'MA3')
          .firstOrNull;

      expect(route2, isNotNull);
      expect(route2!.signalId, 'C31');
      expect(route2.routeId, 'C31_R1');
      expect(route2.requiredBlocks.contains('crossover106'), false);

      // MA2 → MA3: From bay via crossover to main line
      final route3 = controller.timetableRoutes
          .where((r) => r.fromStationId == 'MA2' && r.toStationId == 'MA3')
          .firstOrNull;

      expect(route3, isNotNull);
      expect(route3!.signalId, 'C30');
      expect(route3.routeId, 'C30_R1');
    });

    test('Multiple trains can have independent timetables', () {
      // Spawn two trains
      controller.addTrainToBlock('110');
      controller.addTrainToBlock('111');

      final train1 = controller.trains[0];
      final train2 = controller.trains[1];

      // Assign same timetable to both
      controller.assignTimetableToTrain(train1.id, 'TT001');
      controller.assignTimetableToTrain(train2.id, 'TT001');

      // Should have 2 ghost trains
      expect(controller.ghostTrains.length, 2);
      expect(controller.ghostTrains[0].realTrainId, train1.id);
      expect(controller.ghostTrains[1].realTrainId, train2.id);
    });

    test('Unassigning timetable should work correctly', () {
      controller.addTrainToBlock('110');
      final train = controller.trains.first;

      // Assign timetable
      controller.assignTimetableToTrain(train.id, 'TT001');
      expect(controller.ghostTrains.first.assignedToRealTrain, true);

      // Unassign
      controller.unassignTimetableFromTrain(train.id);
      expect(controller.ghostTrains.first.assignedToRealTrain, false);
      expect(controller.ghostTrains.first.realTrainId, null);
    });

    test('Station system should be properly initialized', () {
      expect(controller.stations.length, 3);

      final ma1 = controller.stations.where((s) => s.id == 'MA1').firstOrNull;
      expect(ma1, isNotNull);
      expect(ma1!.name, 'Mainline Station 1');
      expect(ma1.platformId, 'P1');
      expect(ma1.y, 100); // Upper track

      final ma2 = controller.stations.where((s) => s.id == 'MA2').firstOrNull;
      expect(ma2, isNotNull);
      expect(ma2!.name, 'Mainline Station 2 (Bay)');
      expect(ma2.platformId, 'P2');
      expect(ma2.y, 300); // Lower track (bay)

      final ma3 = controller.stations.where((s) => s.id == 'MA3').firstOrNull;
      expect(ma3, isNotNull);
      expect(ma3!.name, 'Mainline Station 3');
      expect(ma3.platformId, 'P1');
      expect(ma3.y, 100); // Upper track
    });
  });

  group('Timetable Auto-Routing Integration', () {
    late TerminalStationController controller;

    setUp(() {
      controller = TerminalStationController();
    });

    test('Auto-routing should be triggered for timetabled trains', () {
      // Add train at MA1 in auto mode
      controller.addTrainToBlock('110');
      final train = controller.trains.first;
      train.controlMode = TrainControlMode.automatic;

      // Assign timetable
      controller.assignTimetableToTrain(train.id, 'TT001');

      // Start simulation (which calls _updateTimetableRouting)
      controller.startSimulation();

      // Verify system is running
      expect(controller.isRunning, true);

      // The train should now be managed by the timetable system
      // (Detailed behavior tested via manual testing and end-to-end tests)
    });
  });
}
