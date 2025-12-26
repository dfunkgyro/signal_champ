import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../controllers/terminal_station_controller.dart';
import '../models/control_table_models.dart';
import '../screens/terminal_station_models.dart';
import '../utils/file_download_helper.dart';
import 'reservation_test_panel.dart';

/// Control Table Panel - displays editable control table for signal configuration,
/// points deadlocking/flank protection, and AB (Approach Block) management
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

class _ControlTablePanelState extends State<ControlTablePanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Signals tab
  String? _selectedSignalId;
  String? _expandedEntryId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Points tab
  String? _selectedPointId;
  final TextEditingController _pointSearchController = TextEditingController();
  String _pointSearchQuery = '';

  // ABs tab
  String? _selectedABId;
  final TextEditingController _abSearchController = TextEditingController();
  String _abSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _pointSearchController.dispose();
    _abSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TerminalStationController>(
      builder: (context, controller, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            border: Border.all(color: Colors.grey[700]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with tabs
              Container(
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
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
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
                    ),
                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      indicatorColor: Colors.white,
                      tabs: const [
                        Tab(text: 'Signals', icon: Icon(Icons.traffic, size: 18)),
                        Tab(text: 'Points', icon: Icon(Icons.alt_route, size: 18)),
                        Tab(text: 'ABs', icon: Icon(Icons.sensors, size: 18)),
                        Tab(text: 'Test', icon: Icon(Icons.verified_user, size: 18)),
                      ],
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
                child: Column(
                  children: [
                    Row(
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _exportControlTable(context, controller, 'json'),
                            icon: const Icon(Icons.download, size: 16),
                            label: const Text('Export JSON'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _exportControlTable(context, controller, 'xml'),
                            icon: const Icon(Icons.download, size: 16),
                            label: const Text('Export XML'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple[700],
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tab views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Signals Tab
                    _buildSignalsTab(controller),
                    // Points Tab
                    _buildPointsTab(controller),
                    // ABs Tab
                    _buildABsTab(controller),
                    // Reservation Test Tab
                    const ReservationTestPanel(title: 'Reservation Test'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================================
  // SIGNALS TAB
  // ============================================================================

  Widget _buildSignalsTab(TerminalStationController controller) {
    final allSignals = controller.signals.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    final filteredSignals = _searchQuery.isEmpty
        ? allSignals
        : allSignals.where((signal) {
            return signal.id.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

    return Column(
      children: [
        // Search bar for signals
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
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
        ),
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

          // Conflicting Signals
          _buildConflictingSignalsSection(context, controller, entry),

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

  Widget _buildConflictingSignalsSection(
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
              Icon(Icons.warning, color: Colors.red[300], size: 14),
              const SizedBox(width: 6),
              Text(
                'Conflicting Signals (Must be RED)',
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
                onPressed: () => _showConflictingSignalsDialog(context, controller, entry),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (entry.conflictingRoutes.isEmpty)
            Text(
              'None - No conflicting signals',
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            )
          else
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: entry.conflictingRoutes
                  .map((routeId) => Chip(
                        label: Text(
                          routeId,
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                        backgroundColor: Colors.red[900]!.withOpacity(0.3),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  void _showConflictingSignalsDialog(
    BuildContext context,
    TerminalStationController controller,
    ControlTableEntry entry,
  ) {
    // Get all signals and their routes
    final allSignalRoutes = <String>[];
    for (var signal in controller.signals.values) {
      for (var route in signal.routes) {
        allSignalRoutes.add('${signal.id}_${route.id}');
      }
    }
    allSignalRoutes.sort();

    List<String> selectedConflicts = List.from(entry.conflictingRoutes);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[850],
          title: const Text(
            'Conflicting Signals',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 300,
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select signals that must show RED for ${entry.signalId} ${entry.routeName} to show ${entry.targetAspect.name.toUpperCase()}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: allSignalRoutes.length,
                    itemBuilder: (context, index) {
                      final routeId = allSignalRoutes[index];
                      // Don't allow signal to conflict with itself
                      if (routeId == entry.id) return const SizedBox.shrink();

                      final isSelected = selectedConflicts.contains(routeId);
                      return CheckboxListTile(
                        title: Text(
                          routeId,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        value: isSelected,
                        activeColor: Colors.red,
                        onChanged: (value) {
                          setDialogState(() {
                            if (value == true) {
                              selectedConflicts.add(routeId);
                            } else {
                              selectedConflicts.remove(routeId);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
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
                  entry.copyWith(conflictingRoutes: selectedConflicts),
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

  void _exportControlTable(
    BuildContext context,
    TerminalStationController controller,
    String format,
  ) async {
    try {
      String content;
      String filename;

      if (format == 'json') {
        content = controller.exportControlTableAsJson();
        filename = 'control_table_${DateTime.now().millisecondsSinceEpoch}.json';
      } else {
        content = controller.exportControlTableAsXml();
        filename = 'control_table_${DateTime.now().millisecondsSinceEpoch}.xml';
      }

      // For web: trigger download
      // For desktop/mobile: show save dialog or copy to clipboard

      // Try to use the platform's file save functionality
      await _downloadFile(content, filename, format);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Control table exported as $format'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Copy',
              textColor: Colors.white,
              onPressed: () {
                // Copy to clipboard as fallback
                _copyToClipboard(context, content);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadFile(String content, String filename, String format) async {
    await FileDownloadHelper.downloadFile(content, filename);
  }

  void _copyToClipboard(BuildContext context, String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Control Table Export',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 600,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[900],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Copied to clipboard!',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[700]!),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      content,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // POINTS TAB
  // ============================================================================

  Widget _buildPointsTab(TerminalStationController controller) {
    final allPoints = controller.points.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    final filteredPoints = _pointSearchQuery.isEmpty
        ? allPoints
        : allPoints.where((point) {
            return point.id.toLowerCase().contains(_pointSearchQuery.toLowerCase()) ||
                point.name.toLowerCase().contains(_pointSearchQuery.toLowerCase());
          }).toList();

    return Column(
      children: [
        // Search bar for points
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: _pointSearchController,
            decoration: InputDecoration(
              hintText: 'Search points...',
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
                _pointSearchQuery = value;
              });
            },
          ),
        ),
        Expanded(
          child: filteredPoints.isEmpty
              ? Center(
                  child: Text(
                    _pointSearchQuery.isEmpty
                        ? 'No points available'
                        : 'No points match search',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                )
              : ListView.builder(
                  itemCount: filteredPoints.length,
                  itemBuilder: (context, index) {
                    final point = filteredPoints[index];
                    return _buildPointSection(context, controller, point);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPointSection(
    BuildContext context,
    TerminalStationController controller,
    Point point,
  ) {
    final isExpanded = _selectedPointId == point.id;
    final entry = controller.controlTableConfig.getPointEntry(point.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isExpanded ? Colors.purple : Colors.grey[700]!,
          width: isExpanded ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Point header
          InkWell(
            onTap: () {
              setState(() {
                _selectedPointId = isExpanded ? null : point.id;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.alt_route,
                    color: point.position == PointPosition.normal ? Colors.green : Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          point.id,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${point.name} | ${point.position.name.toUpperCase()}${point.locked ? " | LOCKED" : ""}',
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

          // Point details (when expanded)
          if (isExpanded && entry != null) ...[
            const Divider(height: 1, color: Colors.grey),
            _buildPointDetails(context, controller, entry),
          ],
        ],
      ),
    );
  }

  Widget _buildPointDetails(
    BuildContext context,
    TerminalStationController controller,
    PointControlTableEntry entry,
  ) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Deadlock Blocks
          _buildPointDetailSection(
            'Deadlock Blocks',
            entry.deadlockBlocks,
            Icons.block,
            Colors.red,
            'Blocks that prevent point movement when occupied',
            onEdit: () => _showPointBlockSelectionDialog(context, controller, entry, 'deadlock'),
          ),

          const SizedBox(height: 8),

          // Deadlock Approach Blocks
          _buildPointDetailSection(
            'Deadlock Approach Blocks (AB)',
            entry.deadlockApproachBlocks,
            Icons.train,
            Colors.orange,
            'ABs that prevent point movement when trains detected',
            onEdit: () => _showPointABSelectionDialog(context, controller, entry),
          ),

          const SizedBox(height: 8),

          // Flank Protection
          _buildFlankProtectionSection(context, controller, entry),

          const SizedBox(height: 8),

          // Manual Control
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Manual Control Enabled',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Switch(
                value: entry.manualControlEnabled,
                onChanged: (value) {
                  controller.controlTableConfig.updatePointEntry(
                    entry.copyWith(manualControlEnabled: value),
                  );
                  setState(() {});
                },
                activeColor: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPointDetailSection(
    String title,
    List<String> items,
    IconData icon,
    Color color,
    String description, {
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
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (onEdit != null)
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue[300], size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onEdit,
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: TextStyle(color: Colors.grey[500], fontSize: 9, fontStyle: FontStyle.italic),
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

  Widget _buildFlankProtectionSection(
    BuildContext context,
    TerminalStationController controller,
    PointControlTableEntry entry,
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
              Icon(Icons.shield, color: Colors.purple[300], size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Flank Protection (Point Locking Point)',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: Colors.blue[300], size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _showFlankProtectionDialog(context, controller, entry),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Points that lock this point when in specific positions',
            style: TextStyle(color: Colors.grey[500], fontSize: 9, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 4),
          if (entry.flankProtectionPoints.isEmpty)
            Text(
              'None',
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            )
          else
            ...entry.flankProtectionPoints.entries.map((e) => Padding(
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
                      const SizedBox(width: 4),
                      Text(
                        '→ Locks ${entry.pointId}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 9),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  void _showPointBlockSelectionDialog(
    BuildContext context,
    TerminalStationController controller,
    PointControlTableEntry entry,
    String blockType,
  ) {
    final allBlocks = controller.blocks.keys.toList()..sort();
    List<String> selectedBlocks = List.from(entry.deadlockBlocks);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[850],
          title: Text(
            'Deadlock Blocks for ${entry.pointId}',
            style: const TextStyle(color: Colors.white),
          ),
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
                  activeColor: Colors.red,
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
                controller.controlTableConfig.updatePointEntry(
                  entry.copyWith(deadlockBlocks: selectedBlocks),
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

  void _showPointABSelectionDialog(
    BuildContext context,
    TerminalStationController controller,
    PointControlTableEntry entry,
  ) {
    // Get all AB names from configuration
    final allABs = controller.controlTableConfig.abConfigurations.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    List<String> selectedABs = List.from(entry.deadlockApproachBlocks);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[850],
          title: Text(
            'Deadlock ABs for ${entry.pointId}',
            style: const TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 300,
            child: allABs.isEmpty
                ? const Center(
                    child: Text(
                      'No ABs configured. Add ABs in the ABs tab first.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: allABs.length,
                    itemBuilder: (context, index) {
                      final ab = allABs[index];
                      final isSelected = selectedABs.contains(ab.id);
                      return CheckboxListTile(
                        title: Text(
                          ab.name,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        subtitle: Text(
                          '${ab.axleCounter1Id} ↔ ${ab.axleCounter2Id}',
                          style: TextStyle(color: Colors.grey[400], fontSize: 10),
                        ),
                        value: isSelected,
                        activeColor: Colors.orange,
                        onChanged: (value) {
                          setDialogState(() {
                            if (value == true) {
                              selectedABs.add(ab.id);
                            } else {
                              selectedABs.remove(ab.id);
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
                controller.controlTableConfig.updatePointEntry(
                  entry.copyWith(deadlockApproachBlocks: selectedABs),
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

  void _showFlankProtectionDialog(
    BuildContext context,
    TerminalStationController controller,
    PointControlTableEntry entry,
  ) {
    final allPoints = controller.points.keys.toList()..sort();
    // Don't allow a point to lock itself
    allPoints.remove(entry.pointId);

    final selectedPoints = Map<String, PointPosition>.from(entry.flankProtectionPoints);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[850],
          title: Text(
            'Flank Protection for ${entry.pointId}',
            style: const TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select points that lock ${entry.pointId} when in specific positions',
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
                const SizedBox(height: 12),
                Expanded(
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
                          activeColor: Colors.purple,
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                controller.controlTableConfig.updatePointEntry(
                  entry.copyWith(flankProtectionPoints: selectedPoints),
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

  // ============================================================================
  // ABs TAB
  // ============================================================================

  Widget _buildABsTab(TerminalStationController controller) {
    final allABs = controller.controlTableConfig.abConfigurations.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final filteredABs = _abSearchQuery.isEmpty
        ? allABs
        : allABs.where((ab) {
            return ab.name.toLowerCase().contains(_abSearchQuery.toLowerCase()) ||
                ab.id.toLowerCase().contains(_abSearchQuery.toLowerCase());
          }).toList();

    return Column(
      children: [
        // Search bar and Add button
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _abSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search ABs...',
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
                      _abSearchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showAddABDialog(context, controller),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add AB'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[700],
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredABs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sensors_off, size: 48, color: Colors.grey[600]),
                      const SizedBox(height: 16),
                      Text(
                        _abSearchQuery.isEmpty
                            ? 'No ABs configured'
                            : 'No ABs match search',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                      if (_abSearchQuery.isEmpty) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _showAddABDialog(context, controller),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Your First AB'),
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: filteredABs.length,
                  itemBuilder: (context, index) {
                    final ab = filteredABs[index];
                    return _buildABSection(context, controller, ab);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildABSection(
    BuildContext context,
    TerminalStationController controller,
    ABConfiguration ab,
  ) {
    final isExpanded = _selectedABId == ab.id;

    // Check if AB is occupied
    final ac1 = controller.axleCounters[ab.axleCounter1Id];
    final ac2 = controller.axleCounters[ab.axleCounter2Id];
    final isOccupied = ac1 != null && ac2 != null && (ac1.count - ac2.count).abs() > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOccupied ? Colors.purple[900]!.withOpacity(0.3) : Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOccupied ? Colors.purple : (isExpanded ? Colors.blue : Colors.grey[700]!),
          width: isExpanded ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // AB header
          InkWell(
            onTap: () {
              setState(() {
                _selectedABId = isExpanded ? null : ab.id;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.sensors,
                    color: isOccupied ? Colors.purple : Colors.blue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ab.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${ab.axleCounter1Id} ↔ ${ab.axleCounter2Id}${isOccupied ? " | OCCUPIED" : ""}',
                          style: TextStyle(
                            color: isOccupied ? Colors.purple[200] : Colors.grey[400],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!ab.enabled)
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
                  ),
                ],
              ),
            ),
          ),

          // AB details (when expanded)
          if (isExpanded) ...[
            const Divider(height: 1, color: Colors.grey),
            _buildABDetails(context, controller, ab),
          ],
        ],
      ),
    );
  }

  Widget _buildABDetails(
    BuildContext context,
    TerminalStationController controller,
    ABConfiguration ab,
  ) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          TextField(
            decoration: InputDecoration(
              labelText: 'AB Name',
              labelStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 12),
            controller: TextEditingController(text: ab.name),
            onChanged: (value) {
              controller.controlTableConfig.updateABConfiguration(
                ab.copyWith(name: value),
              );
            },
          ),

          const SizedBox(height: 8),

          // Axle Counter 1
          _buildABAxleCounterDropdown(
            context,
            controller,
            ab,
            'Axle Counter 1',
            ab.axleCounter1Id,
            (value) {
              controller.controlTableConfig.updateABConfiguration(
                ab.copyWith(axleCounter1Id: value),
              );
              setState(() {});
            },
          ),

          const SizedBox(height: 8),

          // Axle Counter 2
          _buildABAxleCounterDropdown(
            context,
            controller,
            ab,
            'Axle Counter 2',
            ab.axleCounter2Id,
            (value) {
              controller.controlTableConfig.updateABConfiguration(
                ab.copyWith(axleCounter2Id: value),
              );
              setState(() {});
            },
          ),

          const SizedBox(height: 8),

          // Enabled toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Enabled',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Switch(
                value: ab.enabled,
                onChanged: (value) {
                  controller.controlTableConfig.updateABConfiguration(
                    ab.copyWith(enabled: value),
                  );
                  setState(() {});
                },
                activeColor: Colors.purple,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Delete button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.grey[850],
                    title: const Text('Delete AB?', style: TextStyle(color: Colors.white)),
                    content: Text(
                      'Are you sure you want to delete "${ab.name}"?',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          controller.controlTableConfig.removeABConfiguration(ab.id);
                          Navigator.pop(context);
                          setState(() {
                            _selectedABId = null;
                          });
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.delete, size: 16),
              label: const Text('Delete AB'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildABAxleCounterDropdown(
    BuildContext context,
    TerminalStationController controller,
    ABConfiguration ab,
    String label,
    String currentValue,
    Function(String) onChanged,
  ) {
    final allAxleCounters = controller.axleCounters.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButton<String>(
            value: allAxleCounters.contains(currentValue) ? currentValue : null,
            dropdownColor: Colors.grey[800],
            style: const TextStyle(color: Colors.white, fontSize: 12),
            isExpanded: true,
            underline: const SizedBox(),
            items: allAxleCounters
                .map((ac) => DropdownMenuItem(
                      value: ac,
                      child: Text(ac),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onChanged(value);
              }
            },
          ),
        ),
      ],
    );
  }

  void _showAddABDialog(
    BuildContext context,
    TerminalStationController controller,
  ) {
    final nameController = TextEditingController();
    final allAxleCounters = controller.axleCounters.keys.toList()..sort();
    String? ac1 = allAxleCounters.isNotEmpty ? allAxleCounters.first : null;
    String? ac2 = allAxleCounters.length > 1 ? allAxleCounters[1] : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[850],
          title: const Text(
            'Add New AB',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'AB Name *',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    hintText: 'e.g., Signal C01 Approach',
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 11),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  'Axle Counter 1 *',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButton<String>(
                    value: ac1,
                    dropdownColor: Colors.grey[800],
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: allAxleCounters
                        .map((ac) => DropdownMenuItem(
                              value: ac,
                              child: Text(ac),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        ac1 = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Axle Counter 2 *',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButton<String>(
                    value: ac2,
                    dropdownColor: Colors.grey[800],
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: allAxleCounters
                        .map((ac) => DropdownMenuItem(
                              value: ac,
                              child: Text(ac),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        ac2 = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty || ac1 == null || ac2 == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final newAB = ABConfiguration(
                  id: 'AB_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text,
                  axleCounter1Id: ac1!,
                  axleCounter2Id: ac2!,
                  enabled: true,
                );

                controller.controlTableConfig.updateABConfiguration(newAB);
                Navigator.pop(context);
                setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('AB "${newAB.name}" added'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[700]),
              child: const Text('Add AB'),
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
