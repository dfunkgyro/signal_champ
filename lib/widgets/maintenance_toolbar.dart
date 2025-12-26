import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/maintenance_edit_controller.dart';
import '../controllers/terminal_station_controller.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

/// Toolbar for maintenance mode with editing tools
class MaintenanceToolbar extends StatelessWidget {
  final VoidCallback? onSave;
  final VoidCallback? onExport;
  final VoidCallback? onImport;
  final VoidCallback? onValidate;

  const MaintenanceToolbar({
    Key? key,
    this.onSave,
    this.onExport,
    this.onImport,
    this.onValidate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final editController = Provider.of<MaintenanceEditController>(context);
    final stationController = Provider.of<TerminalStationController>(context);

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          bottom: BorderSide(color: Colors.grey[700]!, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),

          // Maintenance Mode Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.build_circle,
              color: Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          const Text(
            'Maintenance Mode',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(width: 24),
          _buildDivider(),
          const SizedBox(width: 16),

          // Undo/Redo
          _buildToolbarButton(
            icon: Icons.undo,
            tooltip: 'Undo (Ctrl+Z)',
            enabled: editController.canUndo,
            onPressed: () => editController.undo(),
          ),
          const SizedBox(width: 8),
          _buildToolbarButton(
            icon: Icons.redo,
            tooltip: 'Redo (Ctrl+Y)',
            enabled: editController.canRedo,
            onPressed: () => editController.redo(),
          ),

          const SizedBox(width: 16),
          _buildDivider(),
          const SizedBox(width: 16),

          // Selection Tools
          _buildToolbarButton(
            icon: Icons.select_all,
            tooltip: 'Select All (Ctrl+A)',
            onPressed: () => editController.selectAll(),
          ),
          const SizedBox(width: 8),
          _buildToolbarButton(
            icon: Icons.clear,
            tooltip: 'Clear Selection (Esc)',
            enabled: editController.hasSelection,
            onPressed: () => editController.clearSelection(),
          ),

          const SizedBox(width: 16),
          _buildDivider(),
          const SizedBox(width: 16),

          // Grid Tools
          _buildToggleButton(
            icon: Icons.grid_on,
            tooltip: 'Toggle Grid (G)',
            isActive: editController.gridVisible,
            onPressed: () => editController.toggleGrid(),
          ),
          const SizedBox(width: 8),
          _buildToggleButton(
            icon: Icons.grid_4x4,
            tooltip: 'Snap to Grid (Shift+G)',
            isActive: editController.snapToGrid,
            onPressed: () => editController.toggleSnapToGrid(),
          ),

          const SizedBox(width: 16),
          _buildDivider(),
          const SizedBox(width: 16),

          // Validation
          _buildToolbarButton(
            icon: Icons.verified,
            tooltip: 'Validate Layout',
            onPressed: () {
              editController.validateLayout();
              if (onValidate != null) onValidate!();
            },
            badgeCount: editController.validationIssues.length,
          ),

          const SizedBox(width: 16),
          _buildDivider(),
          const SizedBox(width: 16),

          // Quick Test (toggle trains)
          _buildToggleButton(
            icon: Icons.directions_railway,
            tooltip: 'Quick Test (Show Trains)',
            isActive: !stationController.maintenanceModeEnabled,
            onPressed: () {
              // This would toggle trains visibility without leaving maintenance mode
              // For now, just a placeholder
            },
          ),

          const Spacer(),

          // Dirty indicator
          if (editController.isDirty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.circle,
                    color: Colors.orange,
                    size: 8,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Unsaved Changes',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          if (editController.isDirty) const SizedBox(width: 16),

          // Save/Export/Reset
          _buildTextButton(
            label: 'Reset',
            icon: Icons.restore,
            color: Colors.red,
            onPressed: () => _showResetDialog(context, editController),
          ),
          const SizedBox(width: 8),
          _buildTextButton(
            label: 'Export XML',
            icon: Icons.download,
            onPressed: () {
              if (onExport != null) onExport!();
            },
          ),
          const SizedBox(width: 8),
          _buildTextButton(
            label: 'Save',
            icon: Icons.save,
            color: Colors.green,
            onPressed: () {
              if (onSave != null) onSave!();
            },
          ),

          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onPressed,
    bool enabled = true,
    int? badgeCount,
  }) {
    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: Icon(icon),
            onPressed: enabled ? onPressed : null,
            color: enabled ? Colors.white : Colors.grey[700],
            iconSize: 20,
            splashRadius: 20,
          ),
          if (badgeCount != null && badgeCount > 0)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String tooltip,
    required bool isActive,
    VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: isActive ? Colors.orange : Colors.grey[600],
        iconSize: 20,
        splashRadius: 20,
        style: IconButton.styleFrom(
          backgroundColor:
              isActive ? Colors.orange.withOpacity(0.2) : Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildTextButton({
    required String label,
    required IconData icon,
    VoidCallback? onPressed,
    Color? color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color?.withOpacity(0.2) ?? Colors.grey[800],
        foregroundColor: color ?? Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.grey[700],
    );
  }

  void _showResetDialog(
    BuildContext context,
    MaintenanceEditController editController,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Text(
              'Reset to Defaults',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          'This will discard all changes and reset the layout to the original state. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              editController.resetToDefaults();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Layout reset to defaults'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

/// History panel for viewing and navigating undo/redo history
class MaintenanceHistoryPanel extends StatelessWidget {
  const MaintenanceHistoryPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final editController = Provider.of<MaintenanceEditController>(context);

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border.all(color: Colors.grey[700]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              border: Border(
                bottom: BorderSide(color: Colors.grey[700]!),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.history, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Edit History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (editController.history.isNotEmpty)
                  Text(
                    '${editController.history.length} change(s)',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: editController.history.isEmpty
                ? Center(
                    child: Text(
                      'No changes yet',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: editController.history.length,
                    reverse: true,
                    itemBuilder: (context, index) {
                      final command =
                          editController.history[editController.history.length -
                              1 -
                              index];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.circle,
                          size: 8,
                          color: Colors.orange,
                        ),
                        title: Text(
                          command.shortDescription,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        subtitle: Text(
                          _formatTimestamp(command.timestamp),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ago';
    }
  }
}
