import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/railway_model.dart';

class SimulationController extends ChangeNotifier {
  Timer? _simulationTimer;
  Timer? _movementTimer;
  bool _isRunning = false;
  double _simulationSpeed = 1.0;
  int _updateCount = 0;
  RailwayModel? _model;

  bool get isRunning => _isRunning;
  double get simulationSpeed => _simulationSpeed;
  int get updateCount => _updateCount;
  List<String> get eventLog => _model?.eventLog ?? [];

  void setModel(RailwayModel model) {
    _model = model;
    if (kDebugMode) {
      print('[SimulationController] Model initialized');
    }
  }

  void startSimulation() {
    if (_isRunning || _model == null) return;

    _isRunning = true;
    _updateCount = 0;

    if (kDebugMode) {
      print('[SimulationController] Simulation STARTED at speed ${_simulationSpeed}x');
    }

    // Main simulation timer for signal logic updates
    _simulationTimer = Timer.periodic(
      Duration(milliseconds: (1000 / _simulationSpeed).round()),
      (timer) {
        _updateCount++;
        _checkSignalLogic();
        notifyListeners();
      },
    );

    // Movement timer for smooth train animations
    _movementTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_isRunning && _model != null) {
        _model!.updateAllTrainPositions();
      }
    });

    notifyListeners();
  }

  void pauseSimulation() {
    _isRunning = false;
    _simulationTimer?.cancel();
    _movementTimer?.cancel();
    
    if (kDebugMode) {
      print('[SimulationController] Simulation PAUSED at update $_updateCount');
    }
    
    notifyListeners();
  }

  void resetSimulation() {
    pauseSimulation();
    _updateCount = 0;
    _model?.resetAll();
    
    if (kDebugMode) {
      print('[SimulationController] Simulation RESET');
    }
    
    notifyListeners();
  }

  void setSimulationSpeed(double speed) {
    _simulationSpeed = speed.clamp(0.1, 5.0);

    if (kDebugMode) {
      print('[SimulationController] Speed changed to ${_simulationSpeed.toStringAsFixed(1)}x');
    }

    if (_isRunning) {
      _simulationTimer?.cancel();
      _simulationTimer = Timer.periodic(
        Duration(milliseconds: (1000 / _simulationSpeed).round()),
        (timer) {
          _updateCount++;
          _checkSignalLogic();
          notifyListeners();
        },
      );
    }
    notifyListeners();
  }

  void stepForward() {
    if (_model != null) {
      _model!.updateAllTrainPositions();
      _updateCount++;
      _checkSignalLogic();
      
      if (kDebugMode) {
        print('[SimulationController] Stepped forward - update $_updateCount');
      }
      
      notifyListeners();
    }
  }

  void _checkSignalLogic() {
    if (_model == null) return;

    // Update signals based on block occupancy, point positions, and route conflicts
    for (final signal in _model!.signals) {
      final previousState = signal.state;
      bool shouldBeGreen = true;
      List<String> redReasons = [];

      // Check block occupancy
      List<String> occupiedBlocks = [];
      for (final blockId in signal.controlledBlocks) {
        if (_model!.isBlockOccupied(blockId)) {
          shouldBeGreen = false;
          occupiedBlocks.add(blockId);
        }
      }
      if (occupiedBlocks.isNotEmpty) {
        redReasons.add('Blocks occupied: ${occupiedBlocks.join(", ")}');
      }

      // Check point positions for signals that require specific point settings
      List<String> pointIssues = [];
      for (final pointReq in signal.requiredPointPositions) {
        final parts = pointReq.split(':');
        final pointId = parts[0];
        final requiredPosition =
            parts[1] == 'normal' ? PointPosition.normal : PointPosition.reverse;

        final point = _model!.points.firstWhere((p) => p.id == pointId);
        if (point.position != requiredPosition) {
          shouldBeGreen = false;
          pointIssues.add('$pointId is ${point.position.name}, needs ${requiredPosition.name}');
        }
      }
      if (pointIssues.isNotEmpty) {
        redReasons.add('Points incorrect: ${pointIssues.join(", ")}');
      }

      // Special logic for C31 route 2 - requires both 78A and 78B reverse
      if (signal.id == 'C31' && signal.route == 2) {
        final signalC30 = _model!.signals.firstWhere((s) => s.id == 'C30');
        if (signalC30.state == SignalState.green) {
          shouldBeGreen = false;
          redReasons.add('C30 is green (route conflict)');
        }

        // Check both points are reverse
        final point78A = _model!.points.firstWhere((p) => p.id == '78A');
        final point78B = _model!.points.firstWhere((p) => p.id == '78B');
        
        if (point78A.position != PointPosition.reverse) {
          shouldBeGreen = false;
          redReasons.add('78A must be REVERSE for route 2');
        }
        if (point78B.position != PointPosition.reverse) {
          shouldBeGreen = false;
          redReasons.add('78B must be REVERSE for route 2');
        }

        // Check crossover blocks are clear
        if (_model!.isBlockOccupied('crossover106')) {
          shouldBeGreen = false;
          redReasons.add('crossover106 occupied');
        }
        if (_model!.isBlockOccupied('crossover109')) {
          shouldBeGreen = false;
          redReasons.add('crossover109 occupied');
        }
      }

      // Special logic for C30 - cannot be green if C31 route 2 is green
      if (signal.id == 'C30') {
        final signalC31 = _model!.signals.firstWhere((s) => s.id == 'C31');
        if (signalC31.route == 2 && signalC31.state == SignalState.green) {
          shouldBeGreen = false;
          redReasons.add('C31 route 2 is green (route conflict)');
        }
      }

      // Update signal state
      final newState = shouldBeGreen ? SignalState.green : SignalState.red;
      if (signal.state != newState) {
        signal.state = newState;
        if (newState == SignalState.red && redReasons.isNotEmpty) {
          signal.lastStateChangeReason = redReasons.join('; ');
          if (kDebugMode) {
            print('[SignalLogic] ${signal.id} turned RED: ${signal.lastStateChangeReason}');
          }
        } else if (newState == SignalState.green) {
          signal.lastStateChangeReason = 'All conditions met';
          if (kDebugMode) {
            print('[SignalLogic] ${signal.id} turned GREEN: All conditions met');
          }
        }
      }

      // Log state changes
      if (previousState != signal.state) {
        // Event is already logged in railway_model, no need to duplicate here
      }
    }

    // Check for trains waiting at signals and log their status
    for (final train in _model!.trains) {
      if (train.status == TrainStatus.waiting && train.stopReason.isNotEmpty) {
        // Trains waiting are already logged when they stop
      }
    }
  }

  void clearEventLog() {
    _model?.clearEventLog();
    notifyListeners();
  }

  Map<String, dynamic> getSimulationStats() {
    if (_model == null) {
      return {
        'running': false,
        'updates': 0,
        'trains': 0,
        'speed': 1.0,
      };
    }

    return {
      'running': _isRunning,
      'updates': _updateCount,
      'trains': _model!.trains.length,
      'speed': _simulationSpeed,
      'occupiedBlocks': _model!.blocks.where((b) => b.occupied).length,
      'greenSignals':
          _model!.signals.where((s) => s.state == SignalState.green).length,
      'movingTrains':
          _model!.trains.where((t) => t.status == TrainStatus.moving).length,
      'waitingTrains':
          _model!.trains.where((t) => t.status == TrainStatus.waiting).length,
    };
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _movementTimer?.cancel();
    super.dispose();
  }
}
