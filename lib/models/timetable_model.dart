import 'package:flutter/foundation.dart';

// ============================================================================
// STATION MODEL
// ============================================================================

/// Represents a station in the railway network
/// Stations are the named stopping points where trains call according to timetables
class Station {
  final String id; // e.g., 'MA1', 'MA2', 'MA3'
  final String name; // e.g., 'Mainline Station 1'
  final String platformId; // Platform ID (e.g., 'P1', 'P2')
  final double x; // X coordinate of station center
  final double y; // Y coordinate of station center
  bool occupied; // Whether a train is currently at this station

  Station({
    required this.id,
    required this.name,
    required this.platformId,
    required this.x,
    required this.y,
    this.occupied = false,
  });

  @override
  String toString() => 'Station($id: $name at Platform $platformId)';
}

// ============================================================================
// TIMETABLE STOP MODEL
// ============================================================================

/// Represents a single stop in a timetable
class TimetableStop {
  final String stationId; // Station where the train stops
  final Duration? arrivalTime; // Scheduled arrival time (null for origin)
  final Duration? departureTime; // Scheduled departure time (null for terminus)
  final Duration dwellTime; // How long to dwell at station (doors open)
  final String platformId; // Which platform to use at this station

  TimetableStop({
    required this.stationId,
    this.arrivalTime,
    this.departureTime,
    required this.dwellTime,
    required this.platformId,
  });

  /// Returns true if this is the origin station (no arrival time)
  bool get isOrigin => arrivalTime == null;

  /// Returns true if this is the terminus station (no departure time)
  bool get isTerminus => departureTime == null;

  @override
  String toString() {
    if (isOrigin) {
      return 'Origin: $stationId (depart: $departureTime, dwell: $dwellTime)';
    } else if (isTerminus) {
      return 'Terminus: $stationId (arrive: $arrivalTime)';
    } else {
      return 'Stop: $stationId (arrive: $arrivalTime, depart: $departureTime, dwell: $dwellTime)';
    }
  }
}

// ============================================================================
// TIMETABLE ENTRY MODEL
// ============================================================================

/// Represents a complete timetable for a train service
/// Defines the sequence of stations and timing
class TimetableEntry {
  final String id; // Unique timetable ID (e.g., 'TT001')
  final String trainServiceNumber; // Service number (e.g., '101')
  final List<TimetableStop> stops; // Sequence of stops

  TimetableEntry({
    required this.id,
    required this.trainServiceNumber,
    required this.stops,
  });

  /// Returns the origin station ID (first stop)
  String get originStation => stops.first.stationId;

  /// Returns the terminus station ID (last stop)
  String get terminusStation => stops.last.stationId;

  /// Gets the next stop after the given station
  /// Returns null if at terminus or station not found
  TimetableStop? getNextStop(String currentStationId) {
    final currentIndex = stops.indexWhere((stop) => stop.stationId == currentStationId);

    if (currentIndex == -1 || currentIndex == stops.length - 1) {
      return null; // Not found or at terminus
    }

    return stops[currentIndex + 1];
  }

  /// Gets the stop for a given station ID
  TimetableStop? getStop(String stationId) {
    try {
      return stops.firstWhere((stop) => stop.stationId == stationId);
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() => 'Timetable($id: Service $trainServiceNumber, $originStation → $terminusStation)';
}

// ============================================================================
// GHOST TRAIN MODEL
// ============================================================================

/// Represents a "ghost train" - a timetable that can be assigned to a real train
/// This allows timetables to exist independently and be assigned to physical trains
class GhostTrain {
  final String id; // Unique ghost train ID
  final String timetableId; // Reference to timetable
  final String serviceNumber; // Service number from timetable
  String? currentStationId; // Current station in the timetable sequence
  bool assignedToRealTrain; // Whether this ghost train is assigned to a real train
  String? realTrainId; // ID of the real train (if assigned)

  GhostTrain({
    required this.id,
    required this.timetableId,
    required this.serviceNumber,
    this.currentStationId,
    this.assignedToRealTrain = false,
    this.realTrainId,
  });

  @override
  String toString() {
    if (assignedToRealTrain) {
      return 'GhostTrain($id: Service $serviceNumber, assigned to $realTrainId, at $currentStationId)';
    } else {
      return 'GhostTrain($id: Service $serviceNumber, unassigned, at $currentStationId)';
    }
  }
}

// ============================================================================
// TIMETABLE ROUTE MODEL
// ============================================================================

/// Maps station-to-station journeys to signal routes
/// This bridges the gap between timetable (stations) and signaling system (routes)
class TimetableRoute {
  final String fromStationId; // Origin station
  final String toStationId; // Destination station
  final String signalId; // Signal that controls this route
  final String routeId; // Specific route ID (e.g., 'C31_R1')
  final List<String> requiredBlocks; // Blocks that must be clear

  TimetableRoute({
    required this.fromStationId,
    required this.toStationId,
    required this.signalId,
    required this.routeId,
    required this.requiredBlocks,
  });

  @override
  String toString() => 'Route($fromStationId → $toStationId via $signalId:$routeId)';
}

// ============================================================================
// TIMETABLE MANAGER
// ============================================================================

/// Manages all timetables and ghost trains in the system
class TimetableManager extends ChangeNotifier {
  final List<TimetableEntry> timetables = [];
  final List<GhostTrain> ghostTrains = [];
  int _ghostTrainCounter = 0;

  /// Adds a timetable to the system
  void addTimetable(TimetableEntry timetable) {
    timetables.add(timetable);
    notifyListeners();
  }

  /// Removes a timetable from the system
  void removeTimetable(String timetableId) {
    timetables.removeWhere((t) => t.id == timetableId);
    // Also remove associated ghost trains
    ghostTrains.removeWhere((g) => g.timetableId == timetableId);
    notifyListeners();
  }

  /// Gets a timetable by ID
  TimetableEntry? getTimetable(String timetableId) {
    try {
      return timetables.firstWhere((t) => t.id == timetableId);
    } catch (e) {
      return null;
    }
  }

  /// Creates a ghost train from a timetable
  /// Returns null if timetable not found
  GhostTrain? createGhostTrain(String timetableId) {
    final timetable = getTimetable(timetableId);
    if (timetable == null) return null;

    _ghostTrainCounter++;
    final ghostTrain = GhostTrain(
      id: 'GHOST${_ghostTrainCounter.toString().padLeft(3, '0')}',
      timetableId: timetableId,
      serviceNumber: timetable.trainServiceNumber,
      currentStationId: timetable.originStation,
      assignedToRealTrain: false,
    );

    ghostTrains.add(ghostTrain);
    notifyListeners();
    return ghostTrain;
  }

  /// Assigns a ghost train to a real train
  void assignGhostTrainToReal(String ghostTrainId, String realTrainId) {
    final ghostIndex = ghostTrains.indexWhere((g) => g.id == ghostTrainId);
    if (ghostIndex == -1) return;

    final ghost = ghostTrains[ghostIndex];
    ghostTrains[ghostIndex] = GhostTrain(
      id: ghost.id,
      timetableId: ghost.timetableId,
      serviceNumber: ghost.serviceNumber,
      currentStationId: ghost.currentStationId,
      assignedToRealTrain: true,
      realTrainId: realTrainId,
    );

    notifyListeners();
  }

  /// Unassigns a ghost train from a real train
  void unassignGhostTrain(String ghostTrainId) {
    final ghostIndex = ghostTrains.indexWhere((g) => g.id == ghostTrainId);
    if (ghostIndex == -1) return;

    final ghost = ghostTrains[ghostIndex];
    ghostTrains[ghostIndex] = GhostTrain(
      id: ghost.id,
      timetableId: ghost.timetableId,
      serviceNumber: ghost.serviceNumber,
      currentStationId: ghost.currentStationId,
      assignedToRealTrain: false,
      realTrainId: null,
    );

    notifyListeners();
  }

  /// Gets a ghost train by ID
  GhostTrain? getGhostTrain(String ghostTrainId) {
    try {
      return ghostTrains.firstWhere((g) => g.id == ghostTrainId);
    } catch (e) {
      return null;
    }
  }

  /// Gets a ghost train by real train ID
  GhostTrain? getGhostTrainByRealTrain(String realTrainId) {
    try {
      return ghostTrains.firstWhere(
        (g) => g.assignedToRealTrain && g.realTrainId == realTrainId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Updates the current station of a ghost train
  void updateGhostTrainStation(String ghostTrainId, String stationId) {
    final ghostIndex = ghostTrains.indexWhere((g) => g.id == ghostTrainId);
    if (ghostIndex == -1) return;

    final ghost = ghostTrains[ghostIndex];
    ghostTrains[ghostIndex] = GhostTrain(
      id: ghost.id,
      timetableId: ghost.timetableId,
      serviceNumber: ghost.serviceNumber,
      currentStationId: stationId,
      assignedToRealTrain: ghost.assignedToRealTrain,
      realTrainId: ghost.realTrainId,
    );

    notifyListeners();
  }

  /// Clears all timetables and ghost trains
  void clear() {
    timetables.clear();
    ghostTrains.clear();
    _ghostTrainCounter = 0;
    notifyListeners();
  }
}
