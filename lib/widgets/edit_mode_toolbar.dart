import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rail_champ/controllers/terminal_station_controller.dart';

/// Toolbar for Edit Mode with undo/redo and component actions
class EditModeToolbar extends StatelessWidget {
  const EditModeToolbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TerminalStationController>(
      builder: (context, controller, child) {
        if (!controller.editModeEnabled) {
          // Show compact edit mode toggle when disabled
          return _buildCompactToggle(context, controller);
        }

        // Show full toolbar when edit mode is enabled
        return _buildFullToolbar(context, controller);
      },
    );
  }

  /// Compact toggle button when edit mode is off
  Widget _buildCompactToggle(BuildContext context, TerminalStationController controller) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: ElevatedButton.icon(
        onPressed: () => controller.toggleEditMode(),
        icon: const Icon(Icons.edit, size: 18),
        label: const Text('Edit Mode'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  /// Full toolbar when edit mode is enabled
  Widget _buildFullToolbar(BuildContext context, TerminalStationController controller) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Edit Mode indicator
          const Icon(Icons.edit, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Text(
            'EDIT MODE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 16),

          // Divider
          Container(
            width: 1,
            height: 24,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(width: 16),

          // Undo button
          Tooltip(
            message: controller.commandHistory.getUndoDescription() ?? 'Nothing to undo',
            child: IconButton(
              icon: const Icon(Icons.undo, color: Colors.white),
              onPressed: controller.commandHistory.canUndo()
                  ? () => controller.undo()
                  : null,
              splashRadius: 20,
            ),
          ),

          // Redo button
          Tooltip(
            message: controller.commandHistory.getRedoDescription() ?? 'Nothing to redo',
            child: IconButton(
              icon: const Icon(Icons.redo, color: Colors.white),
              onPressed: controller.commandHistory.canRedo()
                  ? () => controller.redo()
                  : null,
              splashRadius: 20,
            ),
          ),

          const SizedBox(width: 8),

          // Divider
          Container(
            width: 1,
            height: 24,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(width: 8),

          // Add component button
          PopupMenuButton<String>(
            icon: const Icon(Icons.add_circle, color: Colors.white),
            tooltip: 'Add Component',
            onSelected: (type) => _showAddComponentDialog(context, controller, type),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'signal', child: Text('📍 Add Signal')),
              const PopupMenuItem(value: 'point', child: Text('🔀 Add Points & Crossings')),
              const PopupMenuItem(value: 'platform', child: Text('🚉 Add Platform')),
              const PopupMenuItem(value: 'trainstop', child: Text('🛑 Add Train Stop')),
              const PopupMenuItem(value: 'bufferstop', child: Text('🛑 Add Buffer Stop')),
              const PopupMenuItem(value: 'axlecounter', child: Text('🔢 Add Axle Counter')),
              const PopupMenuItem(value: 'transponder', child: Text('📡 Add Transponder')),
              const PopupMenuItem(value: 'wifiantenna', child: Text('📶 Add WiFi Antenna')),
            ],
          ),

          // Rename component button
          Tooltip(
            message: 'Rename Selected Component',
            child: IconButton(
              icon: const Icon(Icons.edit_note, color: Colors.white),
              onPressed: controller.selectedComponentId != null
                  ? () => _showRenameDialog(context, controller)
                  : null,
              splashRadius: 20,
            ),
          ),

          // Delete component button
          Tooltip(
            message: 'Delete Selected Component',
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: controller.selectedComponentId != null
                  ? () => _confirmDelete(context, controller)
                  : null,
              splashRadius: 20,
            ),
          ),

          const SizedBox(width: 8),

          // Divider
          Container(
            width: 1,
            height: 24,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(width: 8),

          // Grid toggle
          Tooltip(
            message: 'Toggle Grid',
            child: IconButton(
              icon: Icon(
                Icons.grid_on,
                color: controller.gridVisible ? Colors.greenAccent : Colors.white,
              ),
              onPressed: () {
                controller.gridVisible = !controller.gridVisible;
                controller.notifyListeners();
              },
              splashRadius: 20,
            ),
          ),

          const SizedBox(width: 8),

          // Undo history size control
          Tooltip(
            message: 'Adjust Undo History (${controller.commandHistory.maxHistorySize} steps)',
            child: PopupMenuButton<int>(
              icon: const Icon(Icons.history, color: Colors.white),
              tooltip: 'Undo History Settings',
              onSelected: (size) {
                controller.commandHistory.maxHistorySize = size;
                controller.notifyListeners();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 10,
                  child: Text('10 steps (Minimum)'),
                ),
                PopupMenuItem(
                  value: 20,
                  child: Row(
                    children: [
                      Text('20 steps (Default)'),
                      if (controller.commandHistory.maxHistorySize == 20)
                        const Icon(Icons.check, size: 16, color: Colors.green),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 30,
                  child: Row(
                    children: [
                      Text('30 steps'),
                      if (controller.commandHistory.maxHistorySize == 30)
                        const Icon(Icons.check, size: 16, color: Colors.green),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 40,
                  child: Row(
                    children: [
                      Text('40 steps'),
                      if (controller.commandHistory.maxHistorySize == 40)
                        const Icon(Icons.check, size: 16, color: Colors.green),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 50,
                  child: Row(
                    children: [
                      Text('50 steps (Maximum)'),
                      if (controller.commandHistory.maxHistorySize == 50)
                        const Icon(Icons.check, size: 16, color: Colors.green),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Divider
          Container(
            width: 1,
            height: 24,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(width: 8),

          // Selection Tool Buttons
          Tooltip(
            message: 'Pointer Tool (Click to select)\nShortcut: V',
            child: IconButton(
              icon: Icon(
                Icons.near_me,
                color: controller.selectionMode == SelectionMode.pointer
                    ? Colors.cyanAccent
                    : Colors.white,
              ),
              onPressed: () => controller.setSelectionMode(SelectionMode.pointer),
              splashRadius: 20,
            ),
          ),

          Tooltip(
            message: 'Quick Selection Tool (Auto-detect)\nShortcut: W',
            child: IconButton(
              icon: Icon(
                Icons.auto_fix_high,
                color: controller.selectionMode == SelectionMode.quickSelect
                    ? Colors.cyanAccent
                    : Colors.white,
              ),
              onPressed: () => controller.setSelectionMode(SelectionMode.quickSelect),
              splashRadius: 20,
            ),
          ),

          Tooltip(
            message: 'Marquee Tool (Rectangular selection)\nShortcut: M',
            child: IconButton(
              icon: Icon(
                Icons.crop_square,
                color: controller.selectionMode == SelectionMode.marquee
                    ? Colors.cyanAccent
                    : Colors.white,
              ),
              onPressed: () => controller.setSelectionMode(SelectionMode.marquee),
              splashRadius: 20,
            ),
          ),

          Tooltip(
            message: 'Lasso Tool (Freehand selection)\nShortcut: L',
            child: IconButton(
              icon: Icon(
                Icons.gesture,
                color: controller.selectionMode == SelectionMode.lasso
                    ? Colors.cyanAccent
                    : Colors.white,
              ),
              onPressed: () => controller.setSelectionMode(SelectionMode.lasso),
              splashRadius: 20,
            ),
          ),

          const SizedBox(width: 8),

          // Divider
          Container(
            width: 1,
            height: 24,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(width: 8),

          // Selection tool indicator (shows current selection)
          Tooltip(
            message: 'Selection Tool (ACTIVE)\n\nClick any component to select it\nDrag selected component to move\nPress Delete key to remove',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.cyan.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.cyan, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.touch_app, color: Colors.cyan, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    controller.selectedComponentId != null
                        ? 'Selected: ${controller.selectedComponentType} ${controller.selectedComponentId}'
                        : 'Click to Select',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Clear selection button (visible only when something is selected)
          if (controller.selectedComponentId != null)
            Tooltip(
              message: 'Clear Selection',
              child: IconButton(
                icon: const Icon(Icons.clear, color: Colors.white),
                onPressed: () => controller.clearSelection(),
                splashRadius: 20,
              ),
            ),

          const SizedBox(width: 8),

          // Reset to default layout button
          Tooltip(
            message: 'Reset Layout to Default',
            child: IconButton(
              icon: const Icon(Icons.restore, color: Colors.white),
              onPressed: () => _confirmResetLayout(context, controller),
              splashRadius: 20,
            ),
          ),

          const SizedBox(width: 8),

          // Close edit mode button
          ElevatedButton.icon(
            onPressed: () => controller.toggleEditMode(),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Done'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  /// Show dialog to add a component
  void _showAddComponentDialog(
    BuildContext context,
    TerminalStationController controller,
    String componentType,
  ) {
    final newId = controller.generateUniqueId(componentType);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $componentType'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ID: $newId'),
            const SizedBox(height: 16),
            const Text('Component will be added at grid position (0, 0).'),
            const Text('You can then drag it to the desired location.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Create the component at origin (0, 0) - user can drag to position
              _createComponent(context, controller, componentType, newId);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// Create a component using the controller's factory methods
  void _createComponent(
    BuildContext context,
    TerminalStationController controller,
    String componentType,
    String id,
  ) {
    // Default position at (0, 0) - user will drag to desired location
    const double x = 0.0;
    const double y = 0.0;

    try {
      switch (componentType.toLowerCase()) {
        case 'signal':
          controller.createSignal(id, x, y);
          // Auto-select the new signal so user can immediately drag it
          controller.selectComponent(id, 'signal');
          break;

        case 'point':
          controller.createPoint(id, x, y);
          controller.selectComponent(id, 'point');
          break;

        case 'platform':
          // Use ID as name for now - user can rename later
          controller.createPlatform(id, id.toUpperCase(), x, y);
          controller.selectComponent(id, 'platform');
          break;

        case 'trainstop':
          controller.createTrainStop(id, x, y);
          controller.selectComponent(id, 'trainstop');
          break;

        case 'bufferstop':
          controller.createBufferStop(id, x, y);
          controller.selectComponent(id, 'bufferstop');
          break;

        case 'axlecounter':
          // Find a default block - use first available or '100'
          String blockId = controller.blocks.keys.isNotEmpty
              ? controller.blocks.keys.first
              : '100';
          controller.createAxleCounter(id, x, y, blockId);
          controller.selectComponent(id, 'axlecounter');
          break;

        case 'transponder':
          controller.createTransponder(id, x, y);
          controller.selectComponent(id, 'transponder');
          break;

        case 'wifiantenna':
          controller.createWifiAntenna(id, x, y);
          controller.selectComponent(id, 'wifiantenna');
          break;

        default:
          controller.logEvent('❌ Unknown component type: $componentType');
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Created $componentType $id - Drag to position it!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      controller.logEvent('❌ Error creating $componentType: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to create $componentType: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show dialog to rename a component (points, crossovers, platforms)
  void _showRenameDialog(BuildContext context, TerminalStationController controller) {
    if (controller.selectedComponentId == null ||
        controller.selectedComponentType == null) {
      return;
    }

    final type = controller.selectedComponentType!;
    final id = controller.selectedComponentId!;

    // Get current name based on type
    String currentName = id;
    if (type == 'point') {
      final point = controller.points[id];
      currentName = point?.name ?? id;
    } else if (type == 'crossover') {
      final crossover = controller.crossovers[id];
      currentName = crossover?.name ?? id;
    } else if (type == 'platform') {
      final platform = controller.platforms.firstWhere(
        (p) => p.id == id,
        orElse: () => null as dynamic,
      );
      currentName = platform?.name ?? id;
    } else {
      // Show message for unsupported types
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Renaming not supported for $type'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final nameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rename $type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ID: $id', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'New Name',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _performRename(context, controller, type, id, value.trim());
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                _performRename(context, controller, type, id, newName);
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  /// Perform the rename operation
  void _performRename(
    BuildContext context,
    TerminalStationController controller,
    String type,
    String id,
    String newName,
  ) {
    try {
      if (type == 'point') {
        final point = controller.points[id];
        if (point != null) {
          point.name = newName;
          controller.notifyListeners();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Renamed point $id to "$newName"'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (type == 'crossover') {
        final crossover = controller.crossovers[id];
        if (crossover != null) {
          crossover.name = newName;
          controller.notifyListeners();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Renamed crossover $id to "$newName"'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (type == 'platform') {
        // Platform renaming would need a method in the controller
        // For now, we'll log it
        controller.logEvent('Platform rename requested: $id -> $newName');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Platform renaming not yet implemented'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      controller.logEvent('❌ Error renaming $type: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to rename: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Confirm before deleting a component
  void _confirmDelete(BuildContext context, TerminalStationController controller) {
    if (controller.selectedComponentId == null ||
        controller.selectedComponentType == null) {
      return;
    }

    final type = controller.selectedComponentType!;
    final id = controller.selectedComponentId!;

    // Check if deletion is safe
    if (!controller.canDeleteComponent(type, id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete component - check event log for details'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Component?'),
        content: Text('Delete $type $id? This action can be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteSelectedComponent(); // Uses command pattern with undo
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted $type $id (undo with Ctrl+Z)')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Confirm reset to default layout
  void _confirmResetLayout(BuildContext context, TerminalStationController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Layout to Default?'),
        content: const Text(
          'This will reset all signals, points, platforms, and blocks to their default positions. '
          'This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.resetLayoutToDefault();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Layout reset to default'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

/// Keyboard shortcuts handler for edit mode
class EditModeKeyboardHandler extends StatelessWidget {
  final Widget child;

  const EditModeKeyboardHandler({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TerminalStationController>(
      builder: (context, controller, _) {
        return KeyboardListener(
          focusNode: FocusNode()..requestFocus(),
          autofocus: true,
          onKeyEvent: (event) {
            if (event is KeyDownEvent && controller.editModeEnabled) {
              // Ctrl+Z = Undo
              if (event.logicalKey == LogicalKeyboardKey.keyZ &&
                  HardwareKeyboard.instance.isControlPressed &&
                  !HardwareKeyboard.instance.isShiftPressed) {
                controller.undo();
              }
              // Ctrl+Y or Ctrl+Shift+Z = Redo
              else if ((event.logicalKey == LogicalKeyboardKey.keyY &&
                      HardwareKeyboard.instance.isControlPressed) ||
                  (event.logicalKey == LogicalKeyboardKey.keyZ &&
                      HardwareKeyboard.instance.isControlPressed &&
                      HardwareKeyboard.instance.isShiftPressed)) {
                controller.redo();
              }
              // Delete or Backspace = Delete selected component
              else if ((event.logicalKey == LogicalKeyboardKey.delete ||
                      event.logicalKey == LogicalKeyboardKey.backspace) &&
                  controller.selectedComponentId != null) {
                if (controller.canDeleteComponent(
                  controller.selectedComponentType!,
                  controller.selectedComponentId!,
                )) {
                  controller.deleteComponent(
                    controller.selectedComponentType!,
                    controller.selectedComponentId!,
                  );
                  controller.clearSelection();
                }
              }
              // Escape = Clear selection
              else if (event.logicalKey == LogicalKeyboardKey.escape) {
                controller.clearSelection();
              }
            }
          },
          child: child,
        );
      },
    );
  }
}
