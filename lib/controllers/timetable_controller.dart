import 'package:flutter/foundation.dart';
import 'package:rail_champ/models/timetable_model.dart';
import 'package:rail_champ/screens/terminal_station_models.dart';

/// Controller for managing timetables and automatic train routing
/// Handles the logic for trains following timetables in auto mode
class TimetableController extends ChangeNotifier {
  final TimetableManager timetableManager = TimetableManager();
  final List<Station> stations = [];
  final List<TimetableRoute> routes = [];

  TimetableController() {
    _initializeStations();
    _initializeRoutes();
  }

  /// Initialize the three stations: MA1, MA2, MA3
  void _initializeStations() {
    // MA1: Mainline Station 1 (Platform 1, upper track, center section)
    stations.add(Station(
      id: 'MA1',
      name: 'Mainline Station 1',
      platformId: 'P1',
      x: 1110, // Center of platform 1 (980-1240)
      y: 100, // Upper track
    ));

    // MA2: Mainline Station 2 - Bay Platform (Platform 2, lower track)
    stations.add(Station(
      id: 'MA2',
      name: 'Mainline Station 2 (Bay)',
      platformId: 'P2',
      x: 1110, // Center of platform 2 (980-1240)
      y: 300, // Lower track (bay platform)
    ));

    // MA3: Mainline Station 3 (Platform 1, upper track, eastern end)
    stations.add(Station(
      id: 'MA3',
      name: 'Mainline Station 3',
      platformId: 'P1',
      x: 1490, // Eastern end of platform 1 (around block 114)
      y: 100, // Upper track
    ));
  }

  /// Initialize the routes between stations
  /// Maps station-to-station journeys to signal routes
  void _initializeRoutes() {
    // MA1 → MA2: Route via crossover to bay platform
    routes.add(TimetableRoute(
      fromStationId: 'MA1',
      toStationId: 'MA2',
      signalId: 'C31',
      routeId: 'C31_R2',
      requiredBlocks: ['104', '106', 'crossover106', 'crossover109', '109', '111'],
    ));

    // MA1 → MA3: Direct route via main line
    routes.add(TimetableRoute(
      fromStationId: 'MA1',
      toStationId: 'MA3',
      signalId: 'C31',
      routeId: 'C31_R1',
      requiredBlocks: ['106', '108', '110', '112', '114'],
    ));

    // MA2 → MA3: Route from bay platform via crossover to main line
    routes.add(TimetableRoute(
      fromStationId: 'MA2',
      toStationId: 'MA3',
      signalId: 'C30',
      routeId: 'C30_R1',
      requiredBlocks: ['109', 'crossover109', 'crossover106', '106', '108', '110', '112', '114'],
    ));

    // Could add reverse routes here if needed (MA3 → MA2, MA3 → MA1, etc.)
  }

  /// Gets a station by ID
  Station? getStationById(String stationId) {
    try {
      return stations.firstWhere((s) => s.id == stationId);
    } catch (e) {
      return null;
    }
  }

  /// Gets the station that a train is currently at
  /// Returns null if train is not at any station
  String? getTrainCurrentStation(Train train) {
    for (final station in stations) {
      // Check if train is within station bounds
      // Platform 1 (MA1/MA3): x=980-1240, y=100 (±20)
      // Platform 2 (MA2): x=980-1240, y=300 (±20)

      final double tolerance = 20.0;
      final double platformStartX = 980.0;
      final double platformEndX = 1240.0;

      // For MA3, extend the range to cover eastern end
      final double extendedEndX = station.id == 'MA3' ? 1600.0 : platformEndX;
      final double extendedStartX = station.id == 'MA3' ? 1200.0 : platformStartX;

      bool withinX = false;
      if (station.id == 'MA3') {
        withinX = train.x >= extendedStartX && train.x <= extendedEndX;
      } else {
        withinX = train.x >= platformStartX && train.x <= platformEndX;
      }

      final bool withinY = (train.y - station.y).abs() <= tolerance;

      if (withinX && withinY) {
        return station.id;
      }
    }

    return null;
  }

  /// Gets the next stop for a train based on its assigned timetable
  /// Returns null if train has no assigned timetable or is at terminus
  TimetableStop? getNextStop(Train train) {
    // Get the ghost train assigned to this real train
    final ghostTrain = timetableManager.getGhostTrainByRealTrain(train.id);
    if (ghostTrain == null) return null;

    // Get the timetable
    final timetable = timetableManager.getTimetable(ghostTrain.timetableId);
    if (timetable == null) return null;

    // Get current station
    final currentStationId = ghostTrain.currentStationId ?? getTrainCurrentStation(train);
    if (currentStationId == null) {
      // Train not at any station - use origin as current
      return timetable.stops.first;
    }

    // Get next stop from timetable
    return timetable.getNextStop(currentStationId);
  }

  /// Gets the route for a journey between two stations
  /// Returns null if no route found
  TimetableRoute? getRouteForJourney(String fromStationId, String toStationId) {
    try {
      return routes.firstWhere(
        (r) => r.fromStationId == fromStationId && r.toStationId == toStationId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Checks if a train has completed its dwell time at a station
  /// Returns false if train is not at the correct platform
  bool isDwellTimeComplete(Train train, TimetableStop stop) {
    // Check if train is at a station
    final currentStation = getTrainCurrentStation(train);
    if (currentStation == null) return false;

    // Check if train is at the correct station
    if (currentStation != stop.stationId) return false;

    // Check if train is at the correct platform
    final station = getStationById(currentStation);
    if (station == null) return false;
    if (station.platformId != stop.platformId) return false;

    // Check if doors are open
    if (!train.doorsOpen || train.doorsOpenedAt == null) return false;

    // Check if dwell time has elapsed
    final elapsed = DateTime.now().difference(train.doorsOpenedAt!);
    return elapsed >= stop.dwellTime;
  }

  /// Updates the ghost train's current station based on train position
  void updateGhostTrainProgress(Train train) {
    final ghostTrain = timetableManager.getGhostTrainByRealTrain(train.id);
    if (ghostTrain == null) return;

    final currentStation = getTrainCurrentStation(train);
    if (currentStation != null && currentStation != ghostTrain.currentStationId) {
      timetableManager.updateGhostTrainStation(ghostTrain.id, currentStation);
    }
  }

  /// Creates a default timetable for testing
  /// Creates a MA1 → MA2 → MA3 service
  void createDefaultTimetable() {
    final timetable = TimetableEntry(
      id: 'TT001',
      trainServiceNumber: '101',
      stops: [
        TimetableStop(
          stationId: 'MA1',
          arrivalTime: null, // Origin
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

    timetableManager.addTimetable(timetable);
  }

  /// Determines if a train should depart from current station
  /// Based on timetable, dwell time, and next route availability
  bool shouldDepartStation(Train train) {
    final ghostTrain = timetableManager.getGhostTrainByRealTrain(train.id);
    if (ghostTrain == null) return false;

    final timetable = timetableManager.getTimetable(ghostTrain.timetableId);
    if (timetable == null) return false;

    final currentStation = ghostTrain.currentStationId;
    if (currentStation == null) return false;

    final currentStop = timetable.getStop(currentStation);
    if (currentStop == null) return false;

    // Check if at terminus
    if (currentStop.isTerminus) return false;

    // Check if dwell time complete
    if (!isDwellTimeComplete(train, currentStop)) return false;

    return true;
  }

  /// Gets the destination station for the next movement
  /// Returns null if at terminus or no timetable
  String? getNextDestination(Train train) {
    final nextStop = getNextStop(train);
    return nextStop?.stationId;
  }
}
