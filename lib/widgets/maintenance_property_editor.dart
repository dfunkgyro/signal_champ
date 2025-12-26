import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/terminal_station_controller.dart';
import '../controllers/maintenance_edit_controller.dart';
import '../screens/terminal_station_models.dart';

/// Property editor panel for maintenance mode
class MaintenancePropertyEditor extends StatefulWidget {
  final String title;

  const MaintenancePropertyEditor({
    Key? key,
    this.title = 'Properties',
  }) : super(key: key);

  @override
  State<MaintenancePropertyEditor> createState() =>
      _MaintenancePropertyEditorState();
}

class _MaintenancePropertyEditorState extends State<MaintenancePropertyEditor> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(String key, String initialValue) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(text: initialValue);
    } else if (_controllers[key]!.text != initialValue &&
        !_controllers[key]!.selection.isValid) {
      // Update if not currently being edited
      _controllers[key]!.text = initialValue;
    }
    return _controllers[key]!;
  }

  @override
  Widget build(BuildContext context) {
    final editController = Provider.of<MaintenanceEditController>(context);
    final stationController = Provider.of<TerminalStationController>(context);

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          left: BorderSide(color: Colors.grey[700]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              border: Border(
                bottom: BorderSide(color: Colors.grey[700]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.tune, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (editController.selectionCount > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${editController.selectionCount} selected',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: editController.hasSelection
                ? _buildPropertiesContent(editController, stationController)
                : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app,
            color: Colors.grey[600],
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'No component selected',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click a component to edit',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesContent(
    MaintenanceEditController editController,
    TerminalStationController stationController,
  ) {
    if (editController.selectionCount > 1) {
      return _buildMultiSelectionProperties(editController);
    }

    final selection = editController.primarySelection!;

    switch (selection.type) {
      case 'signal':
        final signal = stationController.signals[selection.id];
        if (signal != null) {
          return _buildSignalProperties(signal, editController);
        }
        break;
      case 'point':
        final point = stationController.points[selection.id];
        if (point != null) {
          return _buildPointProperties(point, editController);
        }
        break;
      case 'block':
        final block = stationController.blockSections[selection.id];
        if (block != null) {
          return _buildBlockProperties(block, editController);
        }
        break;
      case 'axleCounter':
        final ac = stationController.axleCounters[selection.id];
        if (ac != null) {
          return _buildAxleCounterProperties(ac, editController);
        }
        break;
    }

    return _buildEmptyState();
  }

  Widget _buildSignalProperties(
    Signal signal,
    MaintenanceEditController editController,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Signal', Icons.traffic, Colors.green),
        const SizedBox(height: 16),

        _buildPropertyLabel('ID'),
        _buildReadOnlyField(signal.id),
        const SizedBox(height: 16),

        _buildPropertyLabel('Position'),
        Row(
          children: [
            Expanded(
              child: _buildNumberField(
                label: 'X',
                value: signal.x,
                onChanged: (value) {
                  if (value != null) {
                    editController.moveComponent(
                      'signal',
                      signal.id,
                      value,
                      signal.y,
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildNumberField(
                label: 'Y',
                value: signal.y,
                onChanged: (value) {
                  if (value != null) {
                    editController.moveComponent(
                      'signal',
                      signal.id,
                      signal.x,
                      value,
                    );
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _buildPropertyLabel('Direction'),
        _buildDirectionSelector(signal, editController),
        const SizedBox(height: 16),

        _buildPropertyLabel('State'),
        _buildReadOnlyField(signal.state.name.toUpperCase()),
        const SizedBox(height: 16),

        if (signal.junctionId != null) ...[
          _buildPropertyLabel('Junction'),
          _buildReadOnlyField(signal.junctionId!),
          const SizedBox(height: 8),
          _buildPropertyLabel('Junction Position'),
          _buildReadOnlyField(signal.junctionPosition.name),
          const SizedBox(height: 16),
        ],

        _buildPropertyLabel('Routes'),
        _buildReadOnlyField('${signal.routes.length} route(s)'),
        const SizedBox(height: 24),

        _buildActionButtons(editController),
      ],
    );
  }

  Widget _buildPointProperties(
    Point point,
    MaintenanceEditController editController,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Point', Icons.call_split, Colors.blue),
        const SizedBox(height: 16),

        _buildPropertyLabel('ID'),
        _buildReadOnlyField(point.id),
        const SizedBox(height: 16),

        _buildPropertyLabel('Position'),
        Row(
          children: [
            Expanded(
              child: _buildNumberField(
                label: 'X',
                value: point.x,
                onChanged: (value) {
                  if (value != null) {
                    editController.moveComponent(
                      'point',
                      point.id,
                      value,
                      point.y,
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildNumberField(
                label: 'Y',
                value: point.y,
                onChanged: (value) {
                  if (value != null) {
                    editController.moveComponent(
                      'point',
                      point.id,
                      point.x,
                      value,
                    );
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _buildPropertyLabel('Current Position'),
        _buildReadOnlyField(point.currentPosition.name.toUpperCase()),
        const SizedBox(height: 16),

        _buildPropertyLabel('Is Locked'),
        _buildReadOnlyField(point.isLocked ? 'Yes' : 'No'),
        const SizedBox(height: 24),

        _buildActionButtons(editController),
      ],
    );
  }

  Widget _buildBlockProperties(
    BlockSection block,
    MaintenanceEditController editController,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Block', Icons.view_module, Colors.purple),
        const SizedBox(height: 16),

        _buildPropertyLabel('ID'),
        _buildReadOnlyField(block.id),
        const SizedBox(height: 16),

        _buildPropertyLabel('Position'),
        Row(
          children: [
            Expanded(
              child: _buildNumberField(
                label: 'X',
                value: block.x,
                onChanged: (value) {
                  if (value != null) {
                    editController.moveComponent(
                      'block',
                      block.id,
                      value,
                      block.y,
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildNumberField(
                label: 'Y',
                value: block.y,
                onChanged: (value) {
                  if (value != null) {
                    editController.moveComponent(
                      'block',
                      block.id,
                      block.x,
                      value,
                    );
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _buildPropertyLabel('State'),
        _buildReadOnlyField(block.state.name.toUpperCase()),
        const SizedBox(height: 16),

        _buildPropertyLabel('Length'),
        _buildReadOnlyField('${block.length.toStringAsFixed(1)} units'),
        const SizedBox(height: 24),

        _buildActionButtons(editController),
      ],
    );
  }

  Widget _buildAxleCounterProperties(
    AxleCounter ac,
    MaintenanceEditController editController,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Axle Counter', Icons.sensors, Colors.cyan),
        const SizedBox(height: 16),

        _buildPropertyLabel('ID'),
        _buildReadOnlyField(ac.id),
        const SizedBox(height: 16),

        _buildPropertyLabel('Position'),
        Row(
          children: [
            Expanded(
              child: _buildNumberField(
                label: 'X',
                value: ac.x,
                onChanged: (value) {
                  if (value != null) {
                    editController.moveComponent(
                      'axleCounter',
                      ac.id,
                      value,
                      ac.y,
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildNumberField(
                label: 'Y',
                value: ac.y,
                onChanged: (value) {
                  if (value != null) {
                    editController.moveComponent(
                      'axleCounter',
                      ac.id,
                      ac.x,
                      value,
                    );
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _buildPropertyLabel('Block ID'),
        _buildReadOnlyField(ac.blockId),
        const SizedBox(height: 16),

        _buildPropertyLabel('Count'),
        _buildReadOnlyField(ac.count.toString()),
        const SizedBox(height: 24),

        _buildActionButtons(editController),
      ],
    );
  }

  Widget _buildMultiSelectionProperties(
    MaintenanceEditController editController,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(
          'Multiple Selection',
          Icons.select_all,
          Colors.orange,
        ),
        const SizedBox(height: 16),

        _buildPropertyLabel('Selected Components'),
        _buildReadOnlyField('${editController.selectionCount} components'),
        const SizedBox(height: 24),

        _buildPropertyLabel('Batch Operations'),
        const SizedBox(height: 12),

        _buildAlignmentTools(editController),
        const SizedBox(height: 24),

        _buildActionButtons(editController),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.grey[400],
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildReadOnlyField(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 13,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required double value,
    required void Function(double?) onChanged,
  }) {
    final controller = _getController(label, value.toStringAsFixed(1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.-]')),
          ],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontFamily: 'monospace',
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Colors.orange, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          onSubmitted: (text) {
            final newValue = double.tryParse(text);
            onChanged(newValue);
          },
        ),
      ],
    );
  }

  Widget _buildDirectionSelector(
    Signal signal,
    MaintenanceEditController editController,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SignalDirection.values.map((dir) {
        final isSelected = signal.direction == dir;
        return InkWell(
          onTap: () {
            editController.changeSignalDirection(signal.id, dir);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.grey[800],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? Colors.orange : Colors.grey[700]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getDirectionIcon(dir),
                  color: isSelected ? Colors.orange : Colors.grey[400],
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  dir.name.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.orange : Colors.grey[400],
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getDirectionIcon(SignalDirection dir) {
    switch (dir) {
      case SignalDirection.north:
        return Icons.arrow_upward;
      case SignalDirection.east:
        return Icons.arrow_forward;
      case SignalDirection.south:
        return Icons.arrow_downward;
      case SignalDirection.west:
        return Icons.arrow_back;
    }
  }

  Widget _buildAlignmentTools(MaintenanceEditController editController) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildToolButton(
                'Align Left',
                Icons.align_horizontal_left,
                () => editController.alignLeft(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildToolButton(
                'Align Right',
                Icons.align_horizontal_right,
                () => editController.alignRight(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildToolButton(
                'Align Top',
                Icons.align_vertical_top,
                () => editController.alignTop(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildToolButton(
                'Align Bottom',
                Icons.align_vertical_bottom,
                () => editController.alignBottom(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildToolButton(
                'Distribute H',
                Icons.horizontal_distribute,
                () => editController.distributeHorizontally(),
                enabled: editController.selectionCount >= 3,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildToolButton(
                'Distribute V',
                Icons.vertical_distribute,
                () => editController.distributeVertically(),
                enabled: editController.selectionCount >= 3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolButton(
    String label,
    IconData icon,
    VoidCallback onPressed, {
    bool enabled = true,
  }) {
    return ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[800],
        foregroundColor: enabled ? Colors.white : Colors.grey[600],
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  Widget _buildActionButtons(MaintenanceEditController editController) {
    return Column(
      children: [
        const Divider(color: Colors.grey),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: editController.hasSelection
                    ? () => editController.clearSelection()
                    : null,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[400],
                  side: BorderSide(color: Colors.grey[700]!),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
