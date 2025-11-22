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

/// Command to move a block section
class MoveBlockCommand implements EditCommand {
  final TerminalStationController controller;
  final String blockId;
  final double oldStartX, oldEndX, oldY;
  final double newStartX, newEndX, newY;

  MoveBlockCommand(
    this.controller,
    this.blockId,
    this.oldStartX,
    this.oldEndX,
    this.oldY,
    this.newStartX,
    this.newEndX,
    this.newY,
  );

  @override
  void execute() {
    final block = controller.blocks[blockId];
    if (block != null) {
      block.startX = newStartX;
      block.endX = newEndX;
      block.y = newY;
    }
  }

  @override
  void undo() {
    final block = controller.blocks[blockId];
    if (block != null) {
      block.startX = oldStartX;
      block.endX = oldEndX;
      block.y = oldY;
    }
  }

  @override
  String get description => 'Move Block $blockId';
}

/// Command to resize a block section
class ResizeBlockCommand implements EditCommand {
  final TerminalStationController controller;
  final String blockId;
  final double oldStartX, oldEndX;
  final double newStartX, newEndX;

  ResizeBlockCommand(
    this.controller,
    this.blockId,
    this.oldStartX,
    this.oldEndX,
    this.newStartX,
    this.newEndX,
  );

  @override
  void execute() {
    final block = controller.blocks[blockId];
    if (block != null) {
      block.startX = newStartX;
      block.endX = newEndX;
    }
  }

  @override
  void undo() {
    final block = controller.blocks[blockId];
    if (block != null) {
      block.startX = oldStartX;
      block.endX = oldEndX;
    }
  }

  @override
  String get description => 'Resize Block $blockId';
}

/// Command to create a new block section
class CreateBlockCommand implements EditCommand {
  final TerminalStationController controller;
  final String blockId;
  final double startX, endX, y;
  final String? name;

  CreateBlockCommand(
    this.controller,
    this.blockId,
    this.startX,
    this.endX,
    this.y, {
    this.name,
  });

  @override
  void execute() {
    final block = BlockSection(
      id: blockId,
      name: name,
      startX: startX,
      endX: endX,
      y: y,
      occupied: false,
    );
    controller.blocks[blockId] = block;
  }

  @override
  void undo() {
    controller.blocks.remove(blockId);
  }

  @override
  String get description => 'Create Block $blockId';
}

/// Command to delete a block section (with train check)
class DeleteBlockCommand implements EditCommand {
  final TerminalStationController controller;
  final String blockId;
  final BlockSection? _savedBlock;

  DeleteBlockCommand(
    this.controller,
    this.blockId,
  ) : _savedBlock = controller.blocks[blockId];

  @override
  void execute() {
    // Check if block has a train on it
    final block = controller.blocks[blockId];
    if (block != null && block.occupied) {
      throw Exception('Cannot delete block $blockId - train ${block.occupyingTrainId} is on it');
    }
    controller.blocks.remove(blockId);
  }

  @override
  void undo() {
    if (_savedBlock != null) {
      controller.blocks[blockId] = _savedBlock!;
    }
  }

  @override
  String get description => 'Delete Block $blockId';
}

// ============================================================================
// CROSSOVER EDIT COMMANDS
// ============================================================================

/// Command to create a new crossover with points and gaps
class CreateCrossoverCommand implements EditCommand {
  final TerminalStationController controller;
  final String crossoverId;
  final double x;
  final double y;
  final List<String> pointIds;
  final String blockId;

  CreateCrossoverCommand(
    this.controller,
    this.crossoverId,
    this.x,
    this.y,
    this.pointIds,
    this.blockId,
  );

  @override
  void execute() {
    // Create crossover block
    controller.blocks[blockId] = BlockSection(
      id: blockId,
      name: 'Crossover $crossoverId',
      startX: x - 100,
      endX: x + 100,
      y: y,
      occupied: false,
    );

    // Create points for crossover (4 points for double diamond)
    final pointOffsets = [
      {'id': '${crossoverId}A', 'x': x - 50, 'y': y - 100},
      {'id': '${crossoverId}B', 'x': x - 50, 'y': y + 100},
      {'id': '${crossoverId}C', 'x': x + 50, 'y': y - 100},
      {'id': '${crossoverId}D', 'x': x + 50, 'y': y + 100},
    ];

    for (var offset in pointOffsets) {
      final pointId = offset['id'] as String;
      controller.points[pointId] = Point(
        id: pointId,
        x: offset['x'] as double,
        y: offset['y'] as double,
        position: PointPosition.normal,
        locked: false,
      );
    }

    controller.logEvent('✅ Created crossover $crossoverId with 4 points');
  }

  @override
  void undo() {
    // Remove crossover block
    controller.blocks.remove(blockId);

    // Remove all points
    for (var pointId in pointIds) {
      controller.points.remove(pointId);
    }

    controller.logEvent('↩️ Deleted crossover $crossoverId');
  }

  @override
  String get description => 'Create Crossover $crossoverId';
}

/// Command to move a crossover and all associated points
class MoveCrossoverCommand implements EditCommand {
  final TerminalStationController controller;
  final String crossoverId;
  final String blockId;
  final List<String> pointIds;
  final double oldX, oldY;
  final double newX, newY;
  final Map<String, Offset> oldPointPositions = {};

  MoveCrossoverCommand(
    this.controller,
    this.crossoverId,
    this.blockId,
    this.pointIds,
    this.oldX,
    this.oldY,
    this.newX,
    this.newY,
  ) {
    // Save old point positions
    for (var pointId in pointIds) {
      final point = controller.points[pointId];
      if (point != null) {
        oldPointPositions[pointId] = Offset(point.x, point.y);
      }
    }
  }

  @override
  void execute() {
    final deltaX = newX - oldX;
    final deltaY = newY - oldY;

    // Move crossover block
    final block = controller.blocks[blockId];
    if (block != null) {
      block.startX += deltaX;
      block.endX += deltaX;
      block.y += deltaY;
    }

    // Move all associated points
    for (var pointId in pointIds) {
      final point = controller.points[pointId];
      if (point != null) {
        point.x += deltaX;
        point.y += deltaY;
      }
    }

    controller.logEvent('📍 Moved crossover $crossoverId');
  }

  @override
  void undo() {
    final deltaX = oldX - newX;
    final deltaY = oldY - newY;

    // Move crossover block back
    final block = controller.blocks[blockId];
    if (block != null) {
      block.startX += deltaX;
      block.endX += deltaX;
      block.y += deltaY;
    }

    // Restore old point positions
    oldPointPositions.forEach((pointId, offset) {
      final point = controller.points[pointId];
      if (point != null) {
        point.x = offset.dx;
        point.y = offset.dy;
      }
    });

    controller.logEvent('↩️ Moved crossover $crossoverId back');
  }

  @override
  String get description => 'Move Crossover $crossoverId';
}

/// Command to delete a crossover and all associated points
class DeleteCrossoverCommand implements EditCommand {
  final TerminalStationController controller;
  final String crossoverId;
  final String blockId;
  final List<String> pointIds;
  BlockSection? _savedBlock;
  final Map<String, Point> _savedPoints = {};

  DeleteCrossoverCommand(
    this.controller,
    this.crossoverId,
    this.blockId,
    this.pointIds,
  );

  @override
  void execute() {
    // Check if any trains are on the crossover
    final block = controller.blocks[blockId];
    if (block != null && block.occupied) {
      throw Exception('Cannot delete crossover $crossoverId - train is on it');
    }

    // Save block and points for undo
    _savedBlock = block;
    for (var pointId in pointIds) {
      final point = controller.points[pointId];
      if (point != null) {
        _savedPoints[pointId] = point;
      }
    }

    // Delete crossover block
    controller.blocks.remove(blockId);

    // Delete all associated points
    for (var pointId in pointIds) {
      controller.points.remove(pointId);
    }

    controller.logEvent('🗑️ Deleted crossover $crossoverId with all points');
  }

  @override
  void undo() {
    // Restore crossover block
    if (_savedBlock != null) {
      controller.blocks[blockId] = _savedBlock!;
    }

    // Restore all points
    _savedPoints.forEach((pointId, point) {
      controller.points[pointId] = point;
    });

    controller.logEvent('↩️ Restored crossover $crossoverId');
  }

  @override
  String get description => 'Delete Crossover $crossoverId';
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
