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
              const PopupMenuItem(value: 'point', child: Text('🔀 Add Point')),
              const PopupMenuItem(value: 'platform', child: Text('🚉 Add Platform')),
              const PopupMenuItem(value: 'trainstop', child: Text('🛑 Add Train Stop')),
              const PopupMenuItem(value: 'bufferstop', child: Text('🛑 Add Buffer Stop')),
              const PopupMenuItem(value: 'axlecounter', child: Text('🔢 Add Axle Counter')),
              const PopupMenuItem(value: 'transponder', child: Text('📡 Add Transponder')),
              const PopupMenuItem(value: 'wifiantenna', child: Text('📶 Add WiFi Antenna')),
            ],
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
              _createComponent(controller, componentType, newId);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// Create a component using the controller's factory methods
  void _createComponent(TerminalStationController controller, String componentType, String id) {
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
              controller.deleteComponent(type, id);
              controller.clearSelection();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted $type $id')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
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
