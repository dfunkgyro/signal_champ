import 'package:flutter_test/flutter_test.dart';
import 'package:rail_champ/controllers/terminal_station_controller.dart';
import 'package:rail_champ/screens/terminal_station_models.dart';

/// Tests for Timetable functionality - now integrated into TerminalStationController
/// The timetable system is part of the core controller, not a separate component
///
/// Note: Most timetable methods are now private (_methodName) and integrated
/// into the controller. They are tested via integration tests and the public
/// assignTimetableToTrain method.
void main() {
  group('Terminal Station Controller - Timetable Tests', () {
    late TerminalStationController controller;

    setUp(() {
      controller = TerminalStationController();
    });

    test('Controller should initialize with default stations (MA1, MA2, MA3)', () {
      final stations = controller.stations;

      expect(stations.length, 3);
      expect(stations.any((s) => s.id == 'MA1'), true);
      expect(stations.any((s) => s.id == 'MA2'), true);
      expect(stations.any((s) => s.id == 'MA3'), true);
    });

    test('Controller should initialize with timetable routes', () {
      final routes = controller.timetableRoutes;

      expect(routes.length, greaterThan(0));

      // Check MA1 → MA2 route exists
      final ma1ToMa2 = routes.where((r) => r.fromStationId == 'MA1' && r.toStationId == 'MA2').isNotEmpty;
      expect(ma1ToMa2, true);

      // Check MA1 → MA3 route exists
      final ma1ToMa3 = routes.where((r) => r.fromStationId == 'MA1' && r.toStationId == 'MA3').isNotEmpty;
      expect(ma1ToMa3, true);
    });

    test('Controller should have default timetable initialized', () {
      final timetables = controller.timetables;

      expect(timetables.length, greaterThan(0));

      final defaultTimetable = timetables.first;
      expect(defaultTimetable.id, 'TT001');
      expect(defaultTimetable.stops.length, 3); // MA1 → MA2 → MA3
    });

    test('assignTimetableToTrain should assign timetable to a train', () {
      // Add a train first
      controller.addTrainToBlock('110'); // At MA1
      final train = controller.trains.first;

      // Assign timetable
      controller.assignTimetableToTrain(train.id, 'TT001');

      // Verify ghost train was created and assigned
      final ghostTrains = controller.ghostTrains;
      expect(ghostTrains.length, 1);
      expect(ghostTrains.first.assignedToRealTrain, true);
      expect(ghostTrains.first.realTrainId, train.id);
    });

    test('unassignTimetableFromTrain should remove timetable from train', () {
      // Add a train and assign timetable
      controller.addTrainToBlock('110');
      final train = controller.trains.first;
      controller.assignTimetableToTrain(train.id, 'TT001');

      // Verify it's assigned
      expect(controller.ghostTrains.first.assignedToRealTrain, true);

      // Unassign
      controller.unassignTimetableFromTrain(train.id);

      // Verify it's unassigned
      expect(controller.ghostTrains.first.assignedToRealTrain, false);
      expect(controller.ghostTrains.first.realTrainId, null);
    });

    test('Controller should track multiple ghost trains', () {
      // Add two trains
      controller.addTrainToBlock('110'); // Train 1 at MA1
      controller.addTrainToBlock('111'); // Train 2 at MA2

      final train1 = controller.trains[0];
      final train2 = controller.trains[1];

      // Assign same timetable to both trains
      controller.assignTimetableToTrain(train1.id, 'TT001');
      controller.assignTimetableToTrain(train2.id, 'TT001');

      // Should have 2 ghost trains
      expect(controller.ghostTrains.length, 2);
      expect(controller.ghostTrains[0].realTrainId, train1.id);
      expect(controller.ghostTrains[1].realTrainId, train2.id);
    });
  });

  // For more comprehensive timetable journey tests, see:
  // test/integration/timetable_journey_test.dart
}
