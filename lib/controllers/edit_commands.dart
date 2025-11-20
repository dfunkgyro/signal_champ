import 'package:rail_champ/controllers/terminal_station_controller.dart';
import 'package:rail_champ/screens/terminal_station_models.dart';

/// Base interface for all edit commands (Command Pattern)
abstract class EditCommand {
  void execute();
  void undo();
  String get description;
}

/// Command to move a signal
class MoveSignalCommand implements EditCommand {
  final TerminalStationController controller;
  final String signalId;
  final double oldX, oldY;
  final double newX, newY;

  MoveSignalCommand(
    this.controller,
    this.signalId,
    this.oldX,
    this.oldY,
    this.newX,
    this.newY,
  );

  @override
  void execute() {
    final signal = controller.signals[signalId];
    if (signal != null) {
      signal.x = newX;
      signal.y = newY;
    }
  }

  @override
  void undo() {
    final signal = controller.signals[signalId];
    if (signal != null) {
      signal.x = oldX;
      signal.y = oldY;
    }
  }

  @override
  String get description => 'Move Signal $signalId';
}

/// Command to move a point
class MovePointCommand implements EditCommand {
  final TerminalStationController controller;
  final String pointId;
  final double oldX, oldY;
  final double newX, newY;

  MovePointCommand(
    this.controller,
    this.pointId,
    this.oldX,
    this.oldY,
    this.newX,
    this.newY,
  );

  @override
  void execute() {
    final point = controller.points[pointId];
    if (point != null) {
      point.x = newX;
      point.y = newY;
    }
  }

  @override
  void undo() {
    final point = controller.points[pointId];
    if (point != null) {
      point.x = oldX;
      point.y = oldY;
    }
  }

  @override
  String get description => 'Move Point $pointId';
}

/// Command to move a platform
class MovePlatformCommand implements EditCommand {
  final TerminalStationController controller;
  final String platformId;
  final double oldStartX, oldEndX, oldY;
  final double newStartX, newEndX, newY;

  MovePlatformCommand(
    this.controller,
    this.platformId,
    this.oldStartX,
    this.oldEndX,
    this.oldY,
    this.newStartX,
    this.newEndX,
    this.newY,
  );

  @override
  void execute() {
    try {
      final platform = controller.platforms.firstWhere((p) => p.id == platformId);
      platform.startX = newStartX;
      platform.endX = newEndX;
      platform.y = newY;
    } catch (e) {
      // Platform not found
    }
  }

  @override
  void undo() {
    try {
      final platform = controller.platforms.firstWhere((p) => p.id == platformId);
      platform.startX = oldStartX;
      platform.endX = oldEndX;
      platform.y = oldY;
    } catch (e) {
      // Platform not found
    }
  }

  @override
  String get description => 'Move Platform $platformId';
}

/// Command to resize a platform
class ResizePlatformCommand implements EditCommand {
  final TerminalStationController controller;
  final String platformId;
  final double oldStartX, oldEndX;
  final double newStartX, newEndX;

  ResizePlatformCommand(
    this.controller,
    this.platformId,
    this.oldStartX,
    this.oldEndX,
    this.newStartX,
    this.newEndX,
  );

  @override
  void execute() {
    try {
      final platform = controller.platforms.firstWhere((p) => p.id == platformId);
      platform.startX = newStartX;
      platform.endX = newEndX;
    } catch (e) {
      // Platform not found
    }
  }

  @override
  void undo() {
    try {
      final platform = controller.platforms.firstWhere((p) => p.id == platformId);
      platform.startX = oldStartX;
      platform.endX = oldEndX;
    } catch (e) {
      // Platform not found
    }
  }

  @override
  String get description => 'Resize Platform $platformId';
}

/// Command to move a train stop
class MoveTrainStopCommand implements EditCommand {
  final TerminalStationController controller;
  final String stopId;
  final double oldX, oldY;
  final double newX, newY;

  MoveTrainStopCommand(
    this.controller,
    this.stopId,
    this.oldX,
    this.oldY,
    this.newX,
    this.newY,
  );

  @override
  void execute() {
    final stop = controller.trainStops[stopId];
    if (stop != null) {
      stop.x = newX;
      stop.y = newY;
    }
  }

  @override
  void undo() {
    final stop = controller.trainStops[stopId];
    if (stop != null) {
      stop.x = oldX;
      stop.y = oldY;
    }
  }

  @override
  String get description => 'Move Train Stop $stopId';
}

/// Command to move an axle counter
class MoveAxleCounterCommand implements EditCommand {
  final TerminalStationController controller;
  final String counterId;
  final double oldX, oldY;
  final double newX, newY;

  MoveAxleCounterCommand(
    this.controller,
    this.counterId,
    this.oldX,
    this.oldY,
    this.newX,
    this.newY,
  );

  @override
  void execute() {
    final counter = controller.axleCounters[counterId];
    if (counter != null) {
      counter.x = newX;
      counter.y = newY;
    }
  }

  @override
  void undo() {
    final counter = controller.axleCounters[counterId];
    if (counter != null) {
      counter.x = oldX;
      counter.y = oldY;
    }
  }

  @override
  String get description => 'Move Axle Counter $counterId';
}

/// Command to change signal direction
class ChangeSignalDirectionCommand implements EditCommand {
  final TerminalStationController controller;
  final String signalId;
  final SignalDirection oldDirection;
  final SignalDirection newDirection;

  ChangeSignalDirectionCommand(
    this.controller,
    this.signalId,
    this.oldDirection,
    this.newDirection,
  );

  @override
  void execute() {
    final signal = controller.signals[signalId];
    if (signal != null) {
      signal.direction = newDirection;
    }
  }

  @override
  void undo() {
    final signal = controller.signals[signalId];
    if (signal != null) {
      signal.direction = oldDirection;
    }
  }

  @override
  String get description => 'Change Signal $signalId Direction';
}

/// Command to flip axle counter orientation
class FlipAxleCounterCommand implements EditCommand {
  final TerminalStationController controller;
  final String counterId;

  FlipAxleCounterCommand(this.controller, this.counterId);

  @override
  void execute() {
    final counter = controller.axleCounters[counterId];
    if (counter != null) {
      counter.flipped = !counter.flipped;
    }
  }

  @override
  void undo() {
    final counter = controller.axleCounters[counterId];
    if (counter != null) {
      counter.flipped = !counter.flipped;
    }
  }

  @override
  String get description => 'Flip Axle Counter $counterId';
}

/// Command to delete a component (stores full state for undo)
class DeleteComponentCommand implements EditCommand {
  final TerminalStationController controller;
  final String componentType;
  final String componentId;
  final Map<String, dynamic> componentData;

  DeleteComponentCommand(
    this.controller,
    this.componentType,
    this.componentId,
    this.componentData,
  );

  @override
  void execute() {
    controller.deleteComponent(componentType, componentId);
  }

  @override
  void undo() {
    controller.restoreComponent(componentType, componentId, componentData);
  }

  @override
  String get description => 'Delete $componentType $componentId';
}

/// Command to add a component
class AddComponentCommand implements EditCommand {
  final TerminalStationController controller;
  final String componentType;
  final String componentId;
  final Map<String, dynamic> componentData;

  AddComponentCommand(
    this.controller,
    this.componentType,
    this.componentId,
    this.componentData,
  );

  @override
  void execute() {
    controller.restoreComponent(componentType, componentId, componentData);
  }

  @override
  void undo() {
    controller.deleteComponent(componentType, componentId);
  }

  @override
  String get description => 'Add $componentType $componentId';
}

/// Command History Manager - manages undo/redo stacks
class CommandHistory {
  final List<EditCommand> _undoStack = [];
  final List<EditCommand> _redoStack = [];
  static const int maxHistorySize = 50;

  /// Execute a command and add to history
  void executeCommand(EditCommand command) {
    command.execute();
    _undoStack.add(command);
    _redoStack.clear(); // Clear redo stack when new command executed

    // Limit history size to prevent memory issues
    if (_undoStack.length > maxHistorySize) {
      _undoStack.removeAt(0);
    }
  }

  /// Check if undo is available
  bool canUndo() => _undoStack.isNotEmpty;

  /// Check if redo is available
  bool canRedo() => _redoStack.isNotEmpty;

  /// Undo last command
  void undo() {
    if (!canUndo()) return;

    final command = _undoStack.removeLast();
    command.undo();
    _redoStack.add(command);
  }

  /// Redo last undone command
  void redo() {
    if (!canRedo()) return;

    final command = _redoStack.removeLast();
    command.execute();
    _undoStack.add(command);
  }

  /// Get description of command that will be undone
  String? getUndoDescription() {
    return canUndo() ? _undoStack.last.description : null;
  }

  /// Get description of command that will be redone
  String? getRedoDescription() {
    return canRedo() ? _redoStack.last.description : null;
  }

  /// Clear all history
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }

  /// Get number of commands in undo stack
  int get undoCount => _undoStack.length;

  /// Get number of commands in redo stack
  int get redoCount => _redoStack.length;
}
