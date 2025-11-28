import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/terminal_station_controller.dart';
import '../models/layout_configuration.dart';

/// Dropdown widget to select and switch between railway layouts
class LayoutSelectorDropdown extends StatefulWidget {
  const LayoutSelectorDropdown({Key? key}) : super(key: key);

  @override
  State<LayoutSelectorDropdown> createState() => _LayoutSelectorDropdownState();
}

class _LayoutSelectorDropdownState extends State<LayoutSelectorDropdown> {
  String _selectedLayoutId = 'classic_terminal';

  @override
  Widget build(BuildContext context) {
    return Consumer<TerminalStationController>(
      builder: (context, controller, child) {
        final layouts = PredefinedLayouts.getAll();

        return Card(
          margin: const EdgeInsets.all(12),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.railway_alert, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Railway Layout',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedLayoutId,
                      icon: const Icon(Icons.arrow_drop_down),
                      style: Theme.of(context).textTheme.bodyLarge,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          _confirmLayoutChange(context, controller, newValue);
                        }
                      },
                      items: layouts.map<DropdownMenuItem<String>>(
                        (layout) {
                          return DropdownMenuItem<String>(
                            value: layout.id,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  layout.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  layout.description,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      ).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Current layout info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Layout:',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        layouts
                            .firstWhere((l) => l.id == _selectedLayoutId)
                            .name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        layouts
                            .firstWhere((l) => l.id == _selectedLayoutId)
                            .description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Quick stats
                _buildLayoutStats(context, controller),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLayoutStats(BuildContext context, TerminalStationController controller) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Layout Statistics:',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildStatChip(context, '${controller.blocks.length}', 'Blocks'),
              _buildStatChip(context, '${controller.signals.length}', 'Signals'),
              _buildStatChip(context, '${controller.points.length}', 'Points'),
              _buildStatChip(context, '${controller.crossovers.length}', 'Crossovers'),
              _buildStatChip(context, '${controller.platforms.length}', 'Platforms'),
              _buildStatChip(context, '${controller.trains.length}', 'Trains'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLayoutChange(
    BuildContext context,
    TerminalStationController controller,
    String newLayoutId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Change Railway Layout?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Switching layouts will:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Replace all tracks, signals, and points'),
            const Text('• Remove all current trains'),
            const Text('• Reset the simulation'),
            const SizedBox(height: 16),
            const Text(
              'This action cannot be undone. Are you sure?',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
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
              setState(() {
                _selectedLayoutId = newLayoutId;
              });
              _loadLayout(controller, newLayoutId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Loaded layout: ${PredefinedLayouts.getAll().firstWhere((l) => l.id == newLayoutId).name}',
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Switch Layout'),
          ),
        ],
      ),
    );
  }

  void _loadLayout(TerminalStationController controller, String layoutId) {
    final layout = PredefinedLayouts.getAll().firstWhere((l) => l.id == layoutId);
    controller.loadLayoutConfiguration(layout);
    controller.logEvent('🎨 Loaded layout: ${layout.name}');
  }
}
