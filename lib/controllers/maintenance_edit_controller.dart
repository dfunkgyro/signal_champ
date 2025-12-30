import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rail_champ/screens/terminal_station_models.dart';
import 'package:rail_champ/controllers/terminal_station_controller.dart';
import 'dart:convert';

/// Command pattern for undo/redo system
abstract class EditCommand {
  final String description;
  final DateTime timestamp;

  EditCommand(this.description) : timestamp = DateTime.now();

  /// Execute the command
  void execute(TerminalStationController controller);

  /// Undo the command
  void undo(TerminalStationController controller);

  /// Get a short description for history display
  String get shortDescription => description;
}

/// Move component command
class MoveComponentCommand extends EditCommand {
  final String componentType;
  final String componentId;
  final double oldX;
  final double oldY;
  final double newX;
  final double newY;

  MoveComponentCommand({
    required this.componentType,
    required this.componentId,
    required this.oldX,
    required this.oldY,
    required this.newX,
    required this.newY,
  }) : super('Move $componentType $componentId');

  @override
  void execute(TerminalStationController controller) {
    _setPosition(controller, newX, newY);
  }

  @override
  void undo(TerminalStationController controller) {
    _setPosition(controller, oldX, oldY);
  }

  void _setPosition(TerminalStationController controller, double x, double y) {
    switch (componentType) {
      case 'signal':
        final signal = controller.signals[componentId];
        if (signal != null) {
          signal.x = x;
          signal.y = y;
        }
        break;
      case 'point':
        final point = controller.points[componentId];
        if (point != null) {
          point.x = x;
          point.y = y;
        }
        break;
      case 'block':
        final block = controller.blockSections[componentId];
        if (block != null) {
          block.x = x;
          block.y = y;
        }
        break;
      case 'axleCounter':
        final ac = controller.axleCounters[componentId];
        if (ac != null) {
          ac.x = x;
          ac.y = y;
        }
        break;
    }
    controller.notifyListeners();
  }

  @override
  String get shortDescription =>
      'Move $componentType $componentId to (${newX.toStringAsFixed(1)}, ${newY.toStringAsFixed(1)})';
}

/// Change signal direction command
class ChangeSignalDirectionCommand extends EditCommand {
  final String signalId;
  final SignalDirection oldDirection;
  final SignalDirection newDirection;

  ChangeSignalDirectionCommand({
    required this.signalId,
    required this.oldDirection,
    required this.newDirection,
  }) : super('Change signal $signalId direction');

  @override
  void execute(TerminalStationController controller) {
    final signal = controller.signals[signalId];
    if (signal != null) {
      signal.direction = newDirection;
      controller.notifyListeners();
    }
  }

  @override
  void undo(TerminalStationController controller) {
    final signal = controller.signals[signalId];
    if (signal != null) {
      signal.direction = oldDirection;
      controller.notifyListeners();
    }
  }

  @override
  String get shortDescription =>
      'Change signal $signalId direction: ${oldDirection.name} → ${newDirection.name}';
}

/// Toggle signal commission status
class ToggleSignalCommissionCommand extends EditCommand {
  final String signalId;
  final bool oldValue;
  final bool newValue;

  ToggleSignalCommissionCommand({
    required this.signalId,
    required this.oldValue,
    required this.newValue,
  }) : super('Set signal $signalId commission');

  @override
  void execute(TerminalStationController controller) {
    final signal = controller.signals[signalId];
    if (signal != null) {
      signal.commissioned = newValue;
      controller.notifyListeners();
    }
  }

  @override
  void undo(TerminalStationController controller) {
    final signal = controller.signals[signalId];
    if (signal != null) {
      signal.commissioned = oldValue;
      controller.notifyListeners();
    }
  }

  @override
  String get shortDescription =>
      '${newValue ? 'Commission' : 'Decommission'} signal $signalId';
}

/// Batch move command (for moving multiple components at once)
class BatchMoveCommand extends EditCommand {
  final List<MoveComponentCommand> moves;

  BatchMoveCommand(this.moves) : super('Move ${moves.length} components');

  @override
  void execute(TerminalStationController controller) {
    for (final move in moves) {
      move.execute(controller);
    }
  }

  @override
  void undo(TerminalStationController controller) {
    for (final move in moves.reversed) {
      move.undo(controller);
    }
  }

  @override
  String get shortDescription => 'Move ${moves.length} components';
}

/// Delete component command
class DeleteComponentCommand extends EditCommand {
  final String componentType;
  final String componentId;
  final Map<String, dynamic> componentData; // Serialized component for undo

  DeleteComponentCommand({
    required this.componentType,
    required this.componentId,
    required this.componentData,
  }) : super('Delete $componentType $componentId');

  @override
  void execute(TerminalStationController controller) {
    // TODO: Implement component deletion
    // This will require adding delete methods to the controller
  }

  @override
  void undo(TerminalStationController controller) {
    // TODO: Implement component restoration
    // This will require adding add methods to the controller
  }
}

/// Snapshot of the entire layout state
class LayoutSnapshot {
  final String name;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  LayoutSnapshot({
    required this.name,
    required this.data,
  }) : timestamp = DateTime.now();
}

/// Validation issue
class ValidationIssue {
  final String severity; // 'error', 'warning', 'info'
  final String componentType;
  final String componentId;
  final String message;
  final String? suggestion;

  ValidationIssue({
    required this.severity,
    required this.componentType,
    required this.componentId,
    required this.message,
    this.suggestion,
  });

  bool get isError => severity == 'error';
  bool get isWarning => severity == 'warning';

  Color get color {
    switch (severity) {
      case 'error':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData get icon {
    switch (severity) {
      case 'error':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }
}

/// Selected component info
class SelectedComponentInfo {
  final String type;
  final String id;
  double x;
  double y;

  SelectedComponentInfo({
    required this.type,
    required this.id,
    required this.x,
    required this.y,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectedComponentInfo &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          id == other.id;

  @override
  int get hashCode => type.hashCode ^ id.hashCode;
}

/// Controller for maintenance mode editing
class MaintenanceEditController extends ChangeNotifier {
  final TerminalStationController stationController;

  // Undo/Redo system
  final List<EditCommand> _undoStack = [];
  final List<EditCommand> _redoStack = [];
  int _maxHistorySize = 100;

  // Selection system
  final Set<SelectedComponentInfo> _selectedComponents = {};
  SelectedComponentInfo? _primarySelection;

  // Snapshots/Checkpoints
  final List<LayoutSnapshot> _snapshots = [];
  LayoutSnapshot? _originalSnapshot; // For reset to defaults

  // Visual aids
  bool gridVisible = true;
  double gridSpacing = 50.0;
  bool snapToGrid = false;
  bool showRulers = true;
  bool showBoundingBoxes = true;
  bool showMeasurements = false;

  // Editing state
  bool isDirty = false;
  bool isSelecting = false; // For drag-box selection
  Offset? selectionStart;
  Offset? selectionEnd;

  // Validation
  List<ValidationIssue> validationIssues = [];

  MaintenanceEditController(this.stationController) {
    _captureOriginalSnapshot();
  }

  // ============================================================================
  // SELECTION MANAGEMENT
  // ============================================================================

  Set<SelectedComponentInfo> get selectedComponents => _selectedComponents;
  SelectedComponentInfo? get primarySelection => _primarySelection;
  bool get hasSelection => _selectedComponents.isNotEmpty;
  int get selectionCount => _selectedComponents.length;

  void selectComponent(String type, String id, {bool addToSelection = false}) {
    final component = _getComponentInfo(type, id);
    if (component == null) return;

    if (!addToSelection) {
      _selectedComponents.clear();
    }

    _selectedComponents.add(component);
    _primarySelection = component;
    notifyListeners();
  }

  void deselectComponent(String type, String id) {
    _selectedComponents.removeWhere((c) => c.type == type && c.id == id);
    if (_primarySelection?.type == type && _primarySelection?.id == id) {
      _primarySelection = _selectedComponents.isNotEmpty
          ? _selectedComponents.first
          : null;
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedComponents.clear();
    _primarySelection = null;
    notifyListeners();
  }

  void selectAll() {
    _selectedComponents.clear();

    // Add all signals
    for (final signal in stationController.signals.values) {
      _selectedComponents.add(SelectedComponentInfo(
        type: 'signal',
        id: signal.id,
        x: signal.x,
        y: signal.y,
      ));
    }

    // Add all points
    for (final point in stationController.points.values) {
      _selectedComponents.add(SelectedComponentInfo(
        type: 'point',
        id: point.id,
        x: point.x,
        y: point.y,
      ));
    }

    // Add all blocks
    for (final block in stationController.blockSections.values) {
      _selectedComponents.add(SelectedComponentInfo(
        type: 'block',
        id: block.id,
        x: block.x,
        y: block.y,
      ));
    }

    // Add all axle counters
    for (final ac in stationController.axleCounters.values) {
      _selectedComponents.add(SelectedComponentInfo(
        type: 'axleCounter',
        id: ac.id,
        x: ac.x,
        y: ac.y,
      ));
    }

    _primarySelection = _selectedComponents.isNotEmpty
        ? _selectedComponents.first
        : null;
    notifyListeners();
  }

  void selectInRect(Rect rect) {
    _selectedComponents.clear();

    // Check all components
    for (final signal in stationController.signals.values) {
      if (rect.contains(Offset(signal.x, signal.y))) {
        _selectedComponents.add(SelectedComponentInfo(
          type: 'signal',
          id: signal.id,
          x: signal.x,
          y: signal.y,
        ));
      }
    }

    for (final point in stationController.points.values) {
      if (rect.contains(Offset(point.x, point.y))) {
        _selectedComponents.add(SelectedComponentInfo(
          type: 'point',
          id: point.id,
          x: point.x,
          y: point.y,
        ));
      }
    }

    for (final block in stationController.blockSections.values) {
      if (rect.contains(Offset(block.x, block.y))) {
        _selectedComponents.add(SelectedComponentInfo(
          type: 'block',
          id: block.id,
          x: block.x,
          y: block.y,
        ));
      }
    }

    for (final ac in stationController.axleCounters.values) {
      if (rect.contains(Offset(ac.x, ac.y))) {
        _selectedComponents.add(SelectedComponentInfo(
          type: 'axleCounter',
          id: ac.id,
          x: ac.x,
          y: ac.y,
        ));
      }
    }

    _primarySelection = _selectedComponents.isNotEmpty
        ? _selectedComponents.first
        : null;
    notifyListeners();
  }

  SelectedComponentInfo? _getComponentInfo(String type, String id) {
    switch (type) {
      case 'signal':
        final signal = stationController.signals[id];
        if (signal != null) {
          return SelectedComponentInfo(
            type: type,
            id: id,
            x: signal.x,
            y: signal.y,
          );
        }
        break;
      case 'point':
        final point = stationController.points[id];
        if (point != null) {
          return SelectedComponentInfo(
            type: type,
            id: id,
            x: point.x,
            y: point.y,
          );
        }
        break;
      case 'block':
        final block = stationController.blockSections[id];
        if (block != null) {
          return SelectedComponentInfo(
            type: type,
            id: id,
            x: block.x,
            y: block.y,
          );
        }
        break;
      case 'axleCounter':
        final ac = stationController.axleCounters[id];
        if (ac != null) {
          return SelectedComponentInfo(
            type: type,
            id: id,
            x: ac.x,
            y: ac.y,
          );
        }
        break;
    }
    return null;
  }

  // ============================================================================
  // EDITING OPERATIONS
  // ============================================================================

  void moveComponent(String type, String id, double newX, double newY,
      {bool coalesce = false}) {
    final component = _getComponentInfo(type, id);
    if (component == null) return;

    // Snap to grid if enabled
    if (snapToGrid) {
      newX = (newX / gridSpacing).round() * gridSpacing;
      newY = (newY / gridSpacing).round() * gridSpacing;
    }

    if (coalesce && _undoStack.isNotEmpty) {
      final lastCommand = _undoStack.last;
      if (lastCommand is MoveComponentCommand &&
          lastCommand.componentType == type &&
          lastCommand.componentId == id) {
        final mergedCommand = MoveComponentCommand(
          componentType: type,
          componentId: id,
          oldX: lastCommand.oldX,
          oldY: lastCommand.oldY,
          newX: newX,
          newY: newY,
        );
        _undoStack[_undoStack.length - 1] = mergedCommand;
        _redoStack.clear();
        mergedCommand.execute(stationController);
        isDirty = true;
        notifyListeners();
        return;
      }
    }

    final command = MoveComponentCommand(
      componentType: type,
      componentId: id,
      oldX: component.x,
      oldY: component.y,
      newX: newX,
      newY: newY,
    );

    executeCommand(command);
  }

  void moveSelectedComponents(double deltaX, double deltaY) {
    if (_selectedComponents.isEmpty) return;

    final moves = <MoveComponentCommand>[];

    for (final component in _selectedComponents) {
      double newX = component.x + deltaX;
      double newY = component.y + deltaY;

      if (snapToGrid) {
        newX = (newX / gridSpacing).round() * gridSpacing;
        newY = (newY / gridSpacing).round() * gridSpacing;
      }

      moves.add(MoveComponentCommand(
        componentType: component.type,
        componentId: component.id,
        oldX: component.x,
        oldY: component.y,
        newX: newX,
        newY: newY,
      ));

      // Update the cached position
      component.x = newX;
      component.y = newY;
    }

    if (moves.isNotEmpty) {
      executeCommand(BatchMoveCommand(moves));
    }
  }

  void changeSignalDirection(String signalId, SignalDirection newDirection) {
    final signal = stationController.signals[signalId];
    if (signal == null) return;

    final command = ChangeSignalDirectionCommand(
      signalId: signalId,
      oldDirection: signal.direction,
      newDirection: newDirection,
    );

    executeCommand(command);
  }

  void setSignalCommissioned(String signalId, bool commissioned) {
    final signal = stationController.signals[signalId];
    if (signal == null || signal.commissioned == commissioned) return;

    final command = ToggleSignalCommissionCommand(
      signalId: signalId,
      oldValue: signal.commissioned,
      newValue: commissioned,
    );

    executeCommand(command);

    if (!commissioned) {
      stationController.routeReservations
          .removeWhere((id, reservation) => reservation.signalId == signalId);
      signal.activeRouteId = null;
      signal.routeState = RouteState.unset;
      signal.aspect = SignalAspect.red;
      stationController.notifyListeners();
    }
  }

  // ============================================================================
  // UNDO/REDO SYSTEM
  // ============================================================================

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  List<EditCommand> get history => List.unmodifiable(_undoStack);

  void executeCommand(EditCommand command) {
    command.execute(stationController);
    _undoStack.add(command);
    _redoStack.clear(); // Clear redo stack on new command

    // Limit history size
    if (_undoStack.length > _maxHistorySize) {
      _undoStack.removeAt(0);
    }

    isDirty = true;
    notifyListeners();
  }

  void undo() {
    if (!canUndo) return;

    final command = _undoStack.removeLast();
    command.undo(stationController);
    _redoStack.add(command);

    isDirty = _undoStack.isNotEmpty;
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;

    final command = _redoStack.removeLast();
    command.execute(stationController);
    _undoStack.add(command);

    isDirty = true;
    notifyListeners();
  }

  void clearHistory() {
    _undoStack.clear();
    _redoStack.clear();
    isDirty = false;
    notifyListeners();
  }

  // ============================================================================
  // SNAPSHOTS & RESET
  // ============================================================================

  void _captureOriginalSnapshot() {
    _originalSnapshot = LayoutSnapshot(
      name: 'Original',
      data: _serializeLayout(),
    );
  }

  void createSnapshot(String name) {
    final snapshot = LayoutSnapshot(
      name: name,
      data: _serializeLayout(),
    );
    _snapshots.add(snapshot);
    notifyListeners();
  }

  void resetToDefaults() {
    if (_originalSnapshot != null) {
      _restoreSnapshot(_originalSnapshot!);
      clearHistory();
      clearSelection();
      isDirty = false;
      notifyListeners();
    }
  }

  void restoreSnapshot(LayoutSnapshot snapshot) {
    _restoreSnapshot(snapshot);
    clearHistory();
    isDirty = true;
    notifyListeners();
  }

  Map<String, dynamic> _serializeLayout() {
    return {
      'signals': stationController.signals.values
          .map((s) => {
                'id': s.id,
                'x': s.x,
                'y': s.y,
                'direction': s.direction.name,
                'commissioned': s.commissioned,
                // Add more properties as needed
              })
          .toList(),
      'points': stationController.points.values
          .map((p) => {
                'id': p.id,
                'x': p.x,
                'y': p.y,
                // Add more properties as needed
              })
          .toList(),
      'blocks': stationController.blockSections.values
          .map((b) => {
                'id': b.id,
                'x': b.x,
                'y': b.y,
                // Add more properties as needed
              })
          .toList(),
      'axleCounters': stationController.axleCounters.values
          .map((a) => {
                'id': a.id,
                'x': a.x,
                'y': a.y,
                // Add more properties as needed
              })
          .toList(),
    };
  }

  void _restoreSnapshot(LayoutSnapshot snapshot) {
    final data = snapshot.data;

    // Restore signals
    if (data['signals'] != null) {
      for (final signalData in data['signals']) {
        final signal = stationController.signals[signalData['id']];
        if (signal != null) {
          signal.x = signalData['x'];
          signal.y = signalData['y'];
          if (signalData['commissioned'] != null) {
            signal.commissioned = signalData['commissioned'] as bool;
          }
          if (signalData['direction'] != null) {
            signal.direction = SignalDirection.values.firstWhere(
              (d) => d.name == signalData['direction'],
              orElse: () => signal.direction,
            );
          }
        }
      }
    }

    // Restore points
    if (data['points'] != null) {
      for (final pointData in data['points']) {
        final point = stationController.points[pointData['id']];
        if (point != null) {
          point.x = pointData['x'];
          point.y = pointData['y'];
        }
      }
    }

    // Restore blocks
    if (data['blocks'] != null) {
      for (final blockData in data['blocks']) {
        final block = stationController.blockSections[blockData['id']];
        if (block != null) {
          block.x = blockData['x'];
          block.y = blockData['y'];
        }
      }
    }

    // Restore axle counters
    if (data['axleCounters'] != null) {
      for (final acData in data['axleCounters']) {
        final ac = stationController.axleCounters[acData['id']];
        if (ac != null) {
          ac.x = acData['x'];
          ac.y = acData['y'];
        }
      }
    }

    stationController.notifyListeners();
  }

  // ============================================================================
  // VALIDATION
  // ============================================================================

  void validateLayout() {
    validationIssues.clear();

    // Check for overlapping components
    _checkOverlaps();

    // Check for invalid signal directions
    _checkSignalDirections();

    // Add more validation rules as needed

    notifyListeners();
  }

  void _checkOverlaps() {
    final components = <String, Offset>{};

    // Collect all component positions
    for (final signal in stationController.signals.values) {
      components['signal:${signal.id}'] = Offset(signal.x, signal.y);
    }
    for (final point in stationController.points.values) {
      components['point:${point.id}'] = Offset(point.x, point.y);
    }

    // Check for overlaps (within 10 units)
    final keys = components.keys.toList();
    for (int i = 0; i < keys.length; i++) {
      for (int j = i + 1; j < keys.length; j++) {
        final pos1 = components[keys[i]]!;
        final pos2 = components[keys[j]]!;
        final distance = (pos1 - pos2).distance;

        if (distance < 10) {
          validationIssues.add(ValidationIssue(
            severity: 'warning',
            componentType: keys[i].split(':')[0],
            componentId: keys[i].split(':')[1],
            message: 'Overlapping with ${keys[j]}',
            suggestion: 'Move components further apart',
          ));
        }
      }
    }
  }

  void _checkSignalDirections() {
    // Add signal direction validation logic
    // This is a placeholder - implement specific rules as needed
  }

  // ============================================================================
  // ALIGNMENT & DISTRIBUTION TOOLS
  // ============================================================================

  void alignLeft() {
    if (_selectedComponents.length < 2) return;
    final leftmost = _selectedComponents
        .map((c) => c.x)
        .reduce((a, b) => a < b ? a : b);

    final moves = <MoveComponentCommand>[];
    for (final component in _selectedComponents) {
      if (component.x != leftmost) {
        moves.add(MoveComponentCommand(
          componentType: component.type,
          componentId: component.id,
          oldX: component.x,
          oldY: component.y,
          newX: leftmost,
          newY: component.y,
        ));
        component.x = leftmost;
      }
    }

    if (moves.isNotEmpty) {
      executeCommand(BatchMoveCommand(moves));
    }
  }

  void alignRight() {
    if (_selectedComponents.length < 2) return;
    final rightmost = _selectedComponents
        .map((c) => c.x)
        .reduce((a, b) => a > b ? a : b);

    final moves = <MoveComponentCommand>[];
    for (final component in _selectedComponents) {
      if (component.x != rightmost) {
        moves.add(MoveComponentCommand(
          componentType: component.type,
          componentId: component.id,
          oldX: component.x,
          oldY: component.y,
          newX: rightmost,
          newY: component.y,
        ));
        component.x = rightmost;
      }
    }

    if (moves.isNotEmpty) {
      executeCommand(BatchMoveCommand(moves));
    }
  }

  void alignTop() {
    if (_selectedComponents.length < 2) return;
    final topmost = _selectedComponents
        .map((c) => c.y)
        .reduce((a, b) => a < b ? a : b);

    final moves = <MoveComponentCommand>[];
    for (final component in _selectedComponents) {
      if (component.y != topmost) {
        moves.add(MoveComponentCommand(
          componentType: component.type,
          componentId: component.id,
          oldX: component.x,
          oldY: component.y,
          newX: component.x,
          newY: topmost,
        ));
        component.y = topmost;
      }
    }

    if (moves.isNotEmpty) {
      executeCommand(BatchMoveCommand(moves));
    }
  }

  void alignBottom() {
    if (_selectedComponents.length < 2) return;
    final bottommost = _selectedComponents
        .map((c) => c.y)
        .reduce((a, b) => a > b ? a : b);

    final moves = <MoveComponentCommand>[];
    for (final component in _selectedComponents) {
      if (component.y != bottommost) {
        moves.add(MoveComponentCommand(
          componentType: component.type,
          componentId: component.id,
          oldX: component.x,
          oldY: component.y,
          newX: component.x,
          newY: bottommost,
        ));
        component.y = bottommost;
      }
    }

    if (moves.isNotEmpty) {
      executeCommand(BatchMoveCommand(moves));
    }
  }

  void distributeHorizontally() {
    if (_selectedComponents.length < 3) return;

    final sorted = _selectedComponents.toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    final leftmost = sorted.first.x;
    final rightmost = sorted.last.x;
    final spacing = (rightmost - leftmost) / (sorted.length - 1);

    final moves = <MoveComponentCommand>[];
    for (int i = 1; i < sorted.length - 1; i++) {
      final targetX = leftmost + (spacing * i);
      final component = sorted[i];

      if (component.x != targetX) {
        moves.add(MoveComponentCommand(
          componentType: component.type,
          componentId: component.id,
          oldX: component.x,
          oldY: component.y,
          newX: targetX,
          newY: component.y,
        ));
        component.x = targetX;
      }
    }

    if (moves.isNotEmpty) {
      executeCommand(BatchMoveCommand(moves));
    }
  }

  void distributeVertically() {
    if (_selectedComponents.length < 3) return;

    final sorted = _selectedComponents.toList()
      ..sort((a, b) => a.y.compareTo(b.y));

    final topmost = sorted.first.y;
    final bottommost = sorted.last.y;
    final spacing = (bottommost - topmost) / (sorted.length - 1);

    final moves = <MoveComponentCommand>[];
    for (int i = 1; i < sorted.length - 1; i++) {
      final targetY = topmost + (spacing * i);
      final component = sorted[i];

      if (component.y != targetY) {
        moves.add(MoveComponentCommand(
          componentType: component.type,
          componentId: component.id,
          oldX: component.x,
          oldY: component.y,
          newX: component.x,
          newY: targetY,
        ));
        component.y = targetY;
      }
    }

    if (moves.isNotEmpty) {
      executeCommand(BatchMoveCommand(moves));
    }
  }

  // ============================================================================
  // UTILITY
  // ============================================================================

  void toggleGrid() {
    gridVisible = !gridVisible;
    notifyListeners();
  }

  void toggleSnapToGrid() {
    snapToGrid = !snapToGrid;
    notifyListeners();
  }

  void setGridSpacing(double spacing) {
    gridSpacing = spacing.clamp(10.0, 200.0);
    notifyListeners();
  }
}
