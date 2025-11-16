import 'package:flutter/material.dart';
import 'package:rail_champ/controllers/terminal_station_controller.dart';
import 'package:rail_champ/screens/terminal_station_models.dart';

/// AI-powered natural language controller for the railway system
/// This service interprets natural language commands and executes them
/// using the TerminalStationController
class AIRailwayController {
  final TerminalStationController controller;

  AIRailwayController(this.controller);

  /// Process a natural language command
  Future<AICommandResult> processCommand(String command) async {
    final lowerCommand = command.toLowerCase().trim();

    // Train commands
    if (_matchesIntent(lowerCommand, ['spawn', 'add', 'create'], ['train'])) {
      return await _spawnTrain(lowerCommand);
    }

    if (_matchesIntent(lowerCommand, ['remove', 'delete'], ['train'])) {
      return _removeTrain(lowerCommand);
    }

    if (_matchesIntent(lowerCommand, ['move', 'send'], ['train'])) {
      return _moveTrain(lowerCommand);
    }

    if (_matchesIntent(lowerCommand, ['speed', 'faster', 'slower'], ['train'])) {
      return _changeTrainSpeed(lowerCommand);
    }

    if (_matchesIntent(lowerCommand, ['stop', 'brake'], ['train'])) {
      return _stopTrain(lowerCommand);
    }

    if (_matchesIntent(lowerCommand, ['open', 'close'], ['door'])) {
      return _controlDoors(lowerCommand);
    }

    if (_matchesIntent(lowerCommand, ['auto', 'manual', 'cbtc', 'mode'], ['train'])) {
      return _changeTrainMode(lowerCommand);
    }

    if (_matchesIntent(lowerCommand, ['depart', 'go'], ['train'])) {
      return _departTrain(lowerCommand);
    }

    // Signal commands
    if (_matchesIntent(lowerCommand, ['clear', 'set', 'green'], ['signal', 'route'])) {
      return _clearSignal(lowerCommand);
    }

    if (_matchesIntent(lowerCommand, ['return', 'red', 'cancel'], ['signal', 'route'])) {
      return _returnSignal(lowerCommand);
    }

    // Point commands
    if (_matchesIntent(lowerCommand, ['switch', 'set', 'change'], ['point'])) {
      return _switchPoint(lowerCommand);
    }

    if (_matchesIntent(lowerCommand, ['lock', 'unlock'], ['point'])) {
      return _lockPoint(lowerCommand);
    }

    // Query commands
    if (_matchesIntent(lowerCommand, ['where', 'location', 'status'], ['train'])) {
      return _queryTrainStatus(lowerCommand);
    }

    if (_matchesIntent(lowerCommand, ['status', 'occupied'], ['block'])) {
      return _queryBlockStatus(lowerCommand);
    }

    if (_matchesIntent(lowerCommand, ['show', 'list'], ['train', 'signal', 'route'])) {
      return _listStatus(lowerCommand);
    }

    // System commands
    if (_matchesIntent(lowerCommand, ['explain', 'how', 'what'], ['layout', 'station'])) {
      return _explainLayout();
    }

    if (_matchesIntent(lowerCommand, ['help'], [])) {
      return _showHelp();
    }

    return AICommandResult(
      success: false,
      message: 'I don\'t understand that command. Try "help" for available commands.',
    );
  }

  /// Helper to match command intent
  bool _matchesIntent(String command, List<String> verbs, List<String> nouns) {
    final hasVerb = verbs.isEmpty || verbs.any((v) => command.contains(v));
    final hasNoun = nouns.isEmpty || nouns.any((n) => command.contains(n));
    return hasVerb && hasNoun;
  }

  /// Extract train ID from command (e.g., "T1", "train 1", "T2")
  String? _extractTrainId(String command) {
    // Try to match T1, T2, etc.
    final match = RegExp(r't\s*(\d+)', caseSensitive: false).firstMatch(command);
    if (match != null) {
      return 'T${match.group(1)}';
    }

    // If command mentions "all", return null to indicate all trains
    if (command.contains('all')) {
      return 'all';
    }

    // Otherwise, try to find first train in list
    if (controller.trains.isNotEmpty) {
      return controller.trains.first.id;
    }

    return null;
  }

  /// Extract signal ID from command
  String? _extractSignalId(String command) {
    final match = RegExp(r'c\s*(\d+)', caseSensitive: false).firstMatch(command);
    if (match != null) {
      return 'C${match.group(1)}';
    }
    return null;
  }

  /// Extract point ID from command
  String? _extractPointId(String command) {
    final match = RegExp(r'78[ab]', caseSensitive: false).firstMatch(command);
    return match?.group(0)?.toUpperCase();
  }

  /// Extract block ID from command
  String? _extractBlockId(String command) {
    final match = RegExp(r'block\s*(\d+)', caseSensitive: false).firstMatch(command);
    if (match != null) {
      return match.group(1);
    }
    return null;
  }

  // ============================================================================
  // TRAIN COMMANDS
  // ============================================================================

  Future<AICommandResult> _spawnTrain(String command) async {
    try {
      // Extract parameters
      final trainId = _extractTrainId(command) ?? 'T${controller.trains.length + 1}';
      final blockId = _extractBlockId(command) ?? '100'; // Default to block 100

      // Determine color based on command
      Color trainColor = Colors.blue;
      if (command.contains('red')) trainColor = Colors.red;
      if (command.contains('green')) trainColor = Colors.green;
      if (command.contains('yellow')) trainColor = Colors.yellow;
      if (command.contains('orange')) trainColor = Colors.orange;

      // Create train using controller's createTrain method
      final train = Train(
        id: trainId,
        name: trainId,
        vin: 'VIN-$trainId',
        x: controller.blocks[blockId]?.centerX ?? 200,
        y: blockId.startsWith('1') && int.parse(blockId) % 2 == 0 ? 100 : 300,
        speed: 0,
        targetSpeed: 0,
        direction: 1, // Eastbound by default
        color: trainColor,
        controlMode: TrainControlMode.automatic,
        isCbtcEquipped: true,
        cbtcMode: CbtcMode.auto,
      );

      controller.trains.add(train);
      controller.notifyListeners();

      return AICommandResult(
        success: true,
        message: '✅ Created train $trainId in block $blockId',
        data: {'trainId': trainId, 'blockId': blockId},
      );
    } catch (e) {
      return AICommandResult(
        success: false,
        message: '❌ Failed to spawn train: $e',
      );
    }
  }

  AICommandResult _removeTrain(String command) {
    try {
      final trainId = _extractTrainId(command);
      if (trainId == null) {
        return AICommandResult(
          success: false,
          message: '❌ Please specify which train to remove (e.g., "remove train T1")',
        );
      }

      final train = controller.trains.where((t) => t.id == trainId).firstOrNull;
      if (train == null) {
        return AICommandResult(
          success: false,
          message: '❌ Train $trainId not found',
        );
      }

      controller.trains.remove(train);
      controller.notifyListeners();

      return AICommandResult(
        success: true,
        message: '✅ Removed train $trainId',
      );
    } catch (e) {
      return AICommandResult(
        success: false,
        message: '❌ Failed to remove train: $e',
      );
    }
  }

  AICommandResult _moveTrain(String command) {
    try {
      final trainId = _extractTrainId(command);
      if (trainId == null) {
        return AICommandResult(
          success: false,
          message: '❌ Please specify which train to move',
        );
      }

      final train = controller.trains.where((t) => t.id == trainId).firstOrNull;
      if (train == null) {
        return AICommandResult(
          success: false,
          message: '❌ Train $trainId not found',
        );
      }

      // Set destination or direction
      if (command.contains('platform 1') || command.contains('eastbound')) {
        train.smcDestination = 'Platform 1';
        train.direction = 1;
      } else if (command.contains('platform 2') || command.contains('westbound')) {
        train.smcDestination = 'Platform 2';
        train.direction = -1;
      }

      controller.notifyListeners();

      return AICommandResult(
        success: true,
        message: '✅ Set destination for $trainId: ${train.smcDestination ?? "unknown"}',
      );
    } catch (e) {
      return AICommandResult(
        success: false,
        message: '❌ Failed to move train: $e',
      );
    }
  }

  AICommandResult _changeTrainSpeed(String command) {
    try {
      final trainId = _extractTrainId(command);
      if (trainId == null) {
        return AICommandResult(
          success: false,
          message: '❌ Please specify which train',
        );
      }

      final train = controller.trains.where((t) => t.id == trainId).firstOrNull;
      if (train == null) {
        return AICommandResult(
          success: false,
          message: '❌ Train $trainId not found',
        );
      }

      if (command.contains('faster') || command.contains('speed up')) {
        train.targetSpeed = (train.targetSpeed + 1.0).clamp(0, 5.0);
      } else if (command.contains('slower') || command.contains('slow down')) {
        train.targetSpeed = (train.targetSpeed - 1.0).clamp(0, 5.0);
      } else {
        // Try to extract number
        final match = RegExp(r'(\d+)').firstMatch(command);
        if (match != null) {
          train.targetSpeed = double.parse(match.group(1)!).clamp(0, 5.0);
        }
      }

      controller.notifyListeners();

      return AICommandResult(
        success: true,
        message: '✅ Set $trainId target speed to ${train.targetSpeed}',
      );
    } catch (e) {
      return AICommandResult(
        success: false,
        message: '❌ Failed to change speed: $e',
      );
    }
  }

  AICommandResult _stopTrain(String command) {
    try {
      final trainId = _extractTrainId(command);
      if (trainId == null) {
        return AICommandResult(
          success: false,
          message: '❌ Please specify which train to stop',
        );
      }

      if (trainId == 'all') {
        for (var train in controller.trains) {
          controller.stopTrain(train.id);
        }
        return AICommandResult(
          success: true,
          message: '✅ Stopped all trains',
        );
      }

      controller.stopTrain(trainId);
      return AICommandResult(
        success: true,
        message: '✅ Stopped train $trainId',
      );
    } catch (e) {
      return AICommandResult(
        success: false,
        message: '❌ Failed to stop train: $e',
      );
    }
  }

  AICommandResult _departTrain(String command) {
    try {
      final trainId = _extractTrainId(command);
      if (trainId == null) {
        return AICommandResult(
          success: false,
          message: '❌ Please specify which train to depart',
        );
      }

      controller.departTrain(trainId);
      return AICommandResult(
        success: true,
        message: '✅ Train $trainId departing',
      );
    } catch (e) {
      return AICommandResult(
        success: false,
        message: '❌ Failed to depart train: $e',
      );
    }
  }

  AICommandResult _controlDoors(String command) {
    try {
      final trainId = _extractTrainId(command);
      if (trainId == null) {
        return AICommandResult(
          success: false,
          message: '❌ Please specify which train',
        );
      }

      if (command.contains('open')) {
        controller.openTrainDoors(trainId);
        return AICommandResult(
          success: true,
          message: '✅ Opened doors on train $trainId',
        );
      } else {
        controller.closeTrainDoors(trainId);
        return AICommandResult(
          success: true,
          message: '✅ Closed doors on train $trainId',
        );
      }
    } catch (e) {
      return AICommandResult(
        success: false,
        message: '❌ Failed to control doors: $e',
      );
    }
  }

  AICommandResult _changeTrainMode(String command) {
    try {
      final trainId = _extractTrainId(command);
      if (trainId == null) {
        return AICommandResult(
          success: false,
          message: '❌ Please specify which train',
        );
      }

      final train = controller.trains.where((t) => t.id == trainId).firstOrNull;
      if (train == null) {
        return AICommandResult(
          success: false,
          message: '❌ Train $trainId not found',
        );
      }

      // Control mode
      if (command.contains('manual')) {
        train.controlMode = TrainControlMode.manual;
      } else if (command.contains('auto')) {
        train.controlMode = TrainControlMode.automatic;
      }

      // CBTC mode
      if (command.contains('cbtc')) {
        if (command.contains('auto')) {
          train.cbtcMode = CbtcMode.auto;
        } else if (command.contains('pm') || command.contains('protective')) {
          train.cbtcMode = CbtcMode.pm;
        } else if (command.contains('rm') || command.contains('restrictive')) {
          train.cbtcMode = CbtcMode.rm;
        } else if (command.contains('off')) {
          train.cbtcMode = CbtcMode.off;
        } else if (command.contains('storage')) {
          train.cbtcMode = CbtcMode.storage;
        }
      }

      controller.notifyListeners();

      return AICommandResult(
        success: true,
        message: '✅ Changed $trainId to ${train.controlMode.name} mode, CBTC: ${train.cbtcMode.name}',
      );
    } catch (e) {
      return AICommandResult(
        success: false,
        message: '❌ Failed to change mode: $e',
      );
    }
  }

  // ============================================================================
  // SIGNAL COMMANDS
  // ============================================================================

  AICommandResult _clearSignal(String command) {
    try {
      final signalId = _extractSignalId(command);
      if (signalId == null) {
        return AICommandResult(
          success: false,
          message: '❌ Please specify which signal (e.g., "clear signal C28")',
        );
      }

      final signal = controller.signals[signalId];
      if (signal == null) {
        return AICommandResult(
          success: false,
          message: '❌ Signal $signalId not found',
        );
      }

      // Extract route number if specified
      String? routeId;
      if (command.contains('route 1') || command.contains('r1')) {
        routeId = '${signalId}_R1';
      } else if (command.contains('route 2') || command.contains('r2')) {
        routeId = '${signalId}_R2';
      } else if (signal.routes.isNotEmpty) {
        routeId = signal.routes.first.id;
      }

      if (routeId != null) {
        controller.setRoute(signalId, routeId);
        return AICommandResult(
          success: true,
          message: '✅ Clearing signal $signalId, route $routeId',
        );
      } else {
        return AICommandResult(
          success: false,
          message: '❌ No route specified for signal $signalId',
        );
      }
    } catch (e) {
      return AICommandResult(
        success: false,
        message: '❌ Failed to clear signal: $e',
      );
    }
  }

  AICommandResult _returnSignal(String command) {
    try {
      final signalId = _extractSignalId(command);
      if (signalId == null) {
        return AICommandResult(
          success: false,
          message: '❌ Please specify which signal',
        );
      }

      controller.cancelRoute(signalId);
      return AICommandResult(
        success: true,
        message: '✅ Returning signal $signalId to danger',
      );
    } catch (e) {
      return AICommandResult(
        success: false,
        message: '❌ Failed to return signal: $e',
      );
    }
  }

  // ============================================================================
  // POINT COMMANDS
  // ============================================================================

  AICommandResult _switchPoint(String command) {
    try {
      final pointId = _extractPointId(command);
      if (pointId == null) {
        return AICommandResult(
          success: false,
          message: '❌ Please specify which point (78A or 78B)',
        );
      }

      final point = controller.points[pointId];
      if (point == null) {
        return AICommandResult(
          success: false,
          message: '❌ Point $pointId not found',
        );
      }

      // Determine target position
      PointPosition targetPosition;
      if (command.contains('normal') || command.contains('straight')) {
        targetPosition = PointPosition.normal;
      } else if (command.contains('reverse') || command.contains('crossover')) {
        targetPosition = PointPosition.reverse;
      } else {
        // Toggle
        targetPosition = point.position == PointPosition.normal
            ? PointPosition.reverse
            : PointPosition.normal;
      }

      if (point.locked && !point.lockedByAB) {
        return AICommandResult(
          success: false,
          message: '❌ Point $pointId is locked',
        );
      }

      point.position = targetPosition;
      controller.notifyListeners();

      return AICommandResult(
        success: true,
        message: '✅ Switched point $pointId to ${targetPosition.name}',
      );
    } catch (e) {
      return AICommandResult(
        success: false,
        message: '❌ Failed to switch point: $e',
      );
    }
  }

  AICommandResult _lockPoint(String command) {
    try {
      final pointId = _extractPointId(command);
      if (pointId == null) {
        return AICommandResult(
          success: false,
          message: '❌ Please specify which point',
        );
      }

      controller.togglePointLock(pointId);
      final point = controller.points[pointId];

      return AICommandResult(
        success: true,
        message: '✅ Point $pointId is now ${point?.locked == true ? "locked" : "unlocked"}',
      );
    } catch (e) {
      return AICommandResult(
        success: false,
        message: '❌ Failed to lock/unlock point: $e',
      );
    }
  }

  // ============================================================================
  // QUERY COMMANDS
  // ============================================================================

  AICommandResult _queryTrainStatus(String command) {
    final trainId = _extractTrainId(command);
    if (trainId == null || trainId == 'all') {
      final status = controller.trains
          .map((t) =>
              '${t.name}: Block ${t.currentBlockId ?? "?"}, Speed ${t.speed.toStringAsFixed(1)}, ${t.direction > 0 ? "Eastbound" : "Westbound"}')
          .join('\n');
      return AICommandResult(
        success: true,
        message: 'Train Status:\n$status',
      );
    }

    final train = controller.trains.where((t) => t.id == trainId).firstOrNull;
    if (train == null) {
      return AICommandResult(
        success: false,
        message: '❌ Train $trainId not found',
      );
    }

    return AICommandResult(
      success: true,
      message: '''
$trainId Status:
- Block: ${train.currentBlockId ?? "Unknown"}
- Position: (${train.x.toInt()}, ${train.y.toInt()})
- Speed: ${train.speed.toStringAsFixed(1)} / ${train.targetSpeed.toStringAsFixed(1)}
- Direction: ${train.direction > 0 ? "Eastbound" : "Westbound"}
- Mode: ${train.controlMode.name}
- CBTC: ${train.cbtcMode.name}
- Doors: ${train.doorsOpen ? "Open" : "Closed"}
''',
    );
  }

  AICommandResult _queryBlockStatus(String command) {
    final blockId = _extractBlockId(command);
    if (blockId == null) {
      final occupied = controller.blocks.values.where((b) => b.occupied);
      final status = occupied
          .map((b) => 'Block ${b.id}: ${b.occupyingTrainId ?? "occupied"}')
          .join('\n');
      return AICommandResult(
        success: true,
        message: 'Occupied Blocks:\n$status',
      );
    }

    final block = controller.blocks[blockId];
    if (block == null) {
      return AICommandResult(
        success: false,
        message: '❌ Block $blockId not found',
      );
    }

    return AICommandResult(
      success: true,
      message:
          'Block $blockId: ${block.occupied ? "Occupied by ${block.occupyingTrainId}" : "Clear"}',
    );
  }

  AICommandResult _listStatus(String command) {
    if (command.contains('train')) {
      return _queryTrainStatus('all');
    } else if (command.contains('route')) {
      final routes = controller.routeReservations.values
          .map((r) => '${r.signalId}: ${r.trainId}')
          .join('\n');
      return AICommandResult(
        success: true,
        message: 'Active Routes:\n$routes',
      );
    } else if (command.contains('signal')) {
      final signals = controller.signals.values
          .map((s) => '${s.id}: ${s.aspect.name} ${s.activeRouteId ?? ""}')
          .join('\n');
      return AICommandResult(
        success: true,
        message: 'Signal Status:\n$signals',
      );
    }

    return AICommandResult(
      success: false,
      message: '❌ Please specify what to list (trains, signals, or routes)',
    );
  }

  // ============================================================================
  // SYSTEM COMMANDS
  // ============================================================================

  AICommandResult _explainLayout() {
    return AICommandResult(
      success: true,
      message: '''
Railway Layout Overview:

This is a terminal station with two main tracks:
- Eastbound (top): Blocks 100, 102, 104, 106, 108, 110, 112, 114
- Westbound (bottom): Blocks 101, 103, 105, 107, 109, 111

Crossovers at blocks 106/109 allow trains to switch between tracks.

Signals:
- C28: Eastbound entry
- C31: Eastbound exit (2 routes)
- C33: Westbound entry
- C30: Westbound exit (2 routes)

Points:
- 78A: Eastbound crossover control
- 78B: Westbound crossover control

The system uses CBTC with Movement Authority (MA1) visualization showing green arrows ahead of trains.
''',
    );
  }

  AICommandResult _showHelp() {
    return AICommandResult(
      success: true,
      message: '''
AI Railway Controller - Available Commands:

Trains:
- "spawn train" / "add train T5 in block 100"
- "remove train T1"
- "move train T1 to platform 2"
- "speed up train T1" / "set train T1 speed to 3"
- "stop train T1"
- "depart train T1"
- "open doors on T1" / "close doors on T1"
- "set train T1 to manual mode"

Signals:
- "clear signal C28" / "set signal C31 route 1"
- "return signal C28 to red"

Points:
- "switch point 78A" / "set point 78B to reverse"
- "lock point 78A"

Queries:
- "where is train T1?"
- "is block 105 occupied?"
- "show all trains" / "list routes"

System:
- "explain layout"
- "help"
''',
    );
  }
}

/// Result of an AI command execution
class AICommandResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  AICommandResult({
    required this.success,
    required this.message,
    this.data,
  });
}
