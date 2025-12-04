import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/terminal_station_controller.dart';
import '../models/control_table_models.dart';
import '../screens/terminal_station_models.dart';

/// Control Table Panel - displays editable control table for signal configuration
/// This panel allows users to view and modify the conditions under which signals
/// show different aspects (green, yellow, red)
class ControlTablePanel extends StatefulWidget {
  final String title;
  final bool isLeftSidebar;

  const ControlTablePanel({
    Key? key,
    this.title = 'Control Table',
    this.isLeftSidebar = true,
  }) : super(key: key);

  @override
  State<ControlTablePanel> createState() => _ControlTablePanelState();
}

class _ControlTablePanelState extends State<ControlTablePanel> {
  String? _selectedSignalId;
  String? _expandedEntryId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TerminalStationController>(
      builder: (context, controller, child) {
        final allSignals = controller.signals.values.toList()
          ..sort((a, b) => a.id.compareTo(b.id));

        // Filter signals based on search query
        final filteredSignals = _searchQuery.isEmpty
            ? allSignals
            : allSignals.where((signal) {
                return signal.id.toLowerCase().contains(_searchQuery.toLowerCase());
              }).toList();

        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            border: Border.all(color: Colors.grey[700]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[900],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.table_chart, color: Colors.white, size: 20),
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
                        if (controller.controlTableConfig.hasUnsavedChanges)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'UNSAVED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Search bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search signals...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Action buttons
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[700]!),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: controller.controlTableConfig.hasUnsavedChanges
                            ? () {
                                controller.applyControlTableChanges();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Control table changes applied'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.save, size: 16),
                        label: const Text('Apply'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          controller.controlTableConfig.initializeFromSignals(
                            controller.signals,
                          );
                          setState(() {
                            _selectedSignalId = null;
                            _expandedEntryId = null;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Control table reset to current configuration'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Reset'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Signal list
              Expanded(
                child: filteredSignals.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No signals available'
                              : 'No signals match search',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredSignals.length,
                        itemBuilder: (context, index) {
                          final signal = filteredSignals[index];
                          return _buildSignalSection(context, controller, signal);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSignalSection(
    BuildContext context,
    TerminalStationController controller,
    Signal signal,
  ) {
    final isExpanded = _selectedSignalId == signal.id;
    final entries = controller.controlTableConfig.getEntriesForSignal(signal.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isExpanded ? Colors.blue : Colors.grey[700]!,
          width: isExpanded ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Signal header
          InkWell(
            onTap: () {
              setState(() {
                _selectedSignalId = isExpanded ? null : signal.id;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Signal aspect indicator
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _getSignalAspectColor(signal.aspect),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          signal.id,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${signal.direction.name.toUpperCase()} | ${entries.length} route(s)',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),

          // Route entries (when expanded)
          if (isExpanded) ...[
            const Divider(height: 1, color: Colors.grey),
            ...entries.map((entry) => _buildControlTableEntry(context, controller, entry)),
          ],
        ],
      ),
    );
  }

  Widget _buildControlTableEntry(
    BuildContext context,
    TerminalStationController controller,
    ControlTableEntry entry,
  ) {
    final isExpanded = _expandedEntryId == entry.id;

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        children: [
          // Entry header
          InkWell(
            onTap: () {
              setState(() {
                _expandedEntryId = isExpanded ? null : entry.id;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  // Target aspect indicator
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _getSignalAspectColor(entry.targetAspect),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white70, width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.routeName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (!entry.enabled)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red[900],
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'DISABLED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Entry details (when expanded)
          if (isExpanded) ...[
            const Divider(height: 1, color: Colors.grey),
            _buildEntryDetails(context, controller, entry),
          ],
        ],
      ),
    );
  }

  Widget _buildEntryDetails(
    BuildContext context,
    TerminalStationController controller,
    ControlTableEntry entry,
  ) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Target Aspect
          _buildDetailRow(
            'Target Aspect',
            DropdownButton<SignalAspect>(
              value: entry.targetAspect,
              dropdownColor: Colors.grey[800],
              style: const TextStyle(color: Colors.white, fontSize: 12),
              items: [SignalAspect.green, SignalAspect.yellow, SignalAspect.blue]
                  .map((aspect) => DropdownMenuItem(
                        value: aspect,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getSignalAspectColor(aspect),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(aspect.name.toUpperCase()),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  controller.controlTableConfig.updateEntry(
                    entry.copyWith(targetAspect: value),
                  );
                  setState(() {});
                }
              },
            ),
          ),

          const SizedBox(height: 8),

          // Required Blocks Clear
          _buildDetailSection(
            'Required Blocks Clear',
            entry.requiredBlocksClear,
            Icons.check_box,
            Colors.green,
            onEdit: () => _showBlockSelectionDialog(context, controller, entry, 'clear'),
          ),

          const SizedBox(height: 8),

          // Approach Blocks (AB)
          _buildDetailSection(
            'Approach Blocks (AB)',
            entry.approachBlocks,
            Icons.train,
            Colors.orange,
            onEdit: () => _showBlockSelectionDialog(context, controller, entry, 'approach'),
          ),

          const SizedBox(height: 8),

          // Protected Blocks
          _buildDetailSection(
            'Protected Blocks',
            entry.protectedBlocks,
            Icons.shield,
            Colors.blue,
            onEdit: () => _showBlockSelectionDialog(context, controller, entry, 'protected'),
          ),

          const SizedBox(height: 8),

          // Required Point Positions
          _buildPointPositionsSection(context, controller, entry),

          const SizedBox(height: 8),

          // Enabled toggle
          _buildDetailRow(
            'Enabled',
            Switch(
              value: entry.enabled,
              onChanged: (value) {
                controller.controlTableConfig.updateEntry(
                  entry.copyWith(enabled: value),
                );
                setState(() {});
              },
              activeColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, Widget value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        value,
      ],
    );
  }

  Widget _buildDetailSection(
    String title,
    List<String> items,
    IconData icon,
    Color color, {
    VoidCallback? onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (onEdit != null)
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue[300], size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onEdit,
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (items.isEmpty)
            Text(
              'None',
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            )
          else
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: items
                  .map((item) => Chip(
                        label: Text(
                          item,
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                        backgroundColor: color.withOpacity(0.3),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPointPositionsSection(
    BuildContext context,
    TerminalStationController controller,
    ControlTableEntry entry,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.alt_route, color: Colors.purple[300], size: 14),
              const SizedBox(width: 6),
              Text(
                'Required Point Positions',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.edit, color: Colors.blue[300], size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _showPointSelectionDialog(context, controller, entry),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (entry.requiredPointPositions.isEmpty)
            Text(
              'None',
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            )
          else
            ...entry.requiredPointPositions.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        e.key,
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: e.value == PointPosition.normal
                              ? Colors.green[900]
                              : Colors.orange[900],
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          e.value.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  void _showBlockSelectionDialog(
    BuildContext context,
    TerminalStationController controller,
    ControlTableEntry entry,
    String blockType,
  ) {
    final allBlocks = controller.blocks.keys.toList()..sort();
    List<String> selectedBlocks;
    String title;

    switch (blockType) {
      case 'clear':
        selectedBlocks = List.from(entry.requiredBlocksClear);
        title = 'Required Blocks Clear';
        break;
      case 'approach':
        selectedBlocks = List.from(entry.approachBlocks);
        title = 'Approach Blocks (AB)';
        break;
      case 'protected':
        selectedBlocks = List.from(entry.protectedBlocks);
        title = 'Protected Blocks';
        break;
      default:
        return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[850],
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: SizedBox(
            width: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allBlocks.length,
              itemBuilder: (context, index) {
                final blockId = allBlocks[index];
                final isSelected = selectedBlocks.contains(blockId);
                return CheckboxListTile(
                  title: Text(
                    blockId,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  value: isSelected,
                  activeColor: Colors.blue,
                  onChanged: (value) {
                    setDialogState(() {
                      if (value == true) {
                        selectedBlocks.add(blockId);
                      } else {
                        selectedBlocks.remove(blockId);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                ControlTableEntry updatedEntry;
                switch (blockType) {
                  case 'clear':
                    updatedEntry = entry.copyWith(requiredBlocksClear: selectedBlocks);
                    break;
                  case 'approach':
                    updatedEntry = entry.copyWith(approachBlocks: selectedBlocks);
                    break;
                  case 'protected':
                    updatedEntry = entry.copyWith(protectedBlocks: selectedBlocks);
                    break;
                  default:
                    return;
                }
                controller.controlTableConfig.updateEntry(updatedEntry);
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPointSelectionDialog(
    BuildContext context,
    TerminalStationController controller,
    ControlTableEntry entry,
  ) {
    final allPoints = controller.points.keys.toList()..sort();
    final selectedPoints = Map<String, PointPosition>.from(entry.requiredPointPositions);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[850],
          title: const Text(
            'Required Point Positions',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allPoints.length,
              itemBuilder: (context, index) {
                final pointId = allPoints[index];
                final isSelected = selectedPoints.containsKey(pointId);
                final position = selectedPoints[pointId] ?? PointPosition.normal;

                return ListTile(
                  title: Text(
                    pointId,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  trailing: isSelected
                      ? DropdownButton<PointPosition>(
                          value: position,
                          dropdownColor: Colors.grey[800],
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                          items: PointPosition.values
                              .map((pos) => DropdownMenuItem(
                                    value: pos,
                                    child: Text(pos.name.toUpperCase()),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                selectedPoints[pointId] = value;
                              });
                            }
                          },
                        )
                      : null,
                  leading: Checkbox(
                    value: isSelected,
                    activeColor: Colors.blue,
                    onChanged: (value) {
                      setDialogState(() {
                        if (value == true) {
                          selectedPoints[pointId] = PointPosition.normal;
                        } else {
                          selectedPoints.remove(pointId);
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                controller.controlTableConfig.updateEntry(
                  entry.copyWith(requiredPointPositions: selectedPoints),
                );
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSignalAspectColor(SignalAspect aspect) {
    switch (aspect) {
      case SignalAspect.red:
        return Colors.red;
      case SignalAspect.yellow:
        return Colors.yellow;
      case SignalAspect.green:
        return Colors.green;
      case SignalAspect.blue:
        return Colors.blue;
    }
  }
}
