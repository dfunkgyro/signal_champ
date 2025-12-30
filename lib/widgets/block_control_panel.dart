import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/terminal_station_controller.dart';
import '../screens/terminal_station_models.dart';

/// Block Control Panel - Manages opening/closing of railway blocks
/// Replaces the previous popup dialog with a dedicated sidebar section
class BlockControlPanel extends StatefulWidget {
  const BlockControlPanel({Key? key}) : super(key: key);

  @override
  State<BlockControlPanel> createState() => _BlockControlPanelState();
}

class _BlockControlPanelState extends State<BlockControlPanel> {
  String _searchQuery = '';
  bool _showOnlyOccupied = false;
  bool _showOnlyClosed = false;
  String? _selectedBlockId;

  @override
  Widget build(BuildContext context) {
    return Consumer<TerminalStationController>(
      builder: (context, controller, _) {
        final allBlocks = controller.blocks.values.toList()
          ..sort((a, b) => a.id.compareTo(b.id));

        // Filter blocks based on search and toggles
        final filteredBlocks = allBlocks.where((block) {
          final matchesSearch = _searchQuery.isEmpty ||
              block.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (block.name?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                  false);

          final matchesOccupied = !_showOnlyOccupied || block.occupied;
          final matchesClosed =
              !_showOnlyClosed || controller.isBlockClosed(block.id);

          return matchesSearch && matchesOccupied && matchesClosed;
        }).toList();

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.grid_view,
                      size: 20,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Block Control',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${filteredBlocks.length}/${allBlocks.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer
                            .withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Search and filters
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    // Search field
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search blocks...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      style: const TextStyle(fontSize: 12),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),

                    // Filter toggles
                    Row(
                      children: [
                        Expanded(
                          child: _buildFilterChip(
                            label: 'Occupied',
                            selected: _showOnlyOccupied,
                            onSelected: (selected) {
                              setState(() {
                                _showOnlyOccupied = selected;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildFilterChip(
                            label: 'Closed',
                            selected: _showOnlyClosed,
                            onSelected: (selected) {
                              setState(() {
                                _showOnlyClosed = selected;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Quick actions
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _closeAllBlocks(controller);
                        },
                        icon: const Icon(Icons.block, size: 16),
                        label: const Text('Close All', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade100,
                          foregroundColor: Colors.red.shade900,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _openAllBlocks(controller);
                        },
                        icon: const Icon(Icons.lock_open, size: 16),
                        label: const Text('Open All', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade100,
                          foregroundColor: Colors.green.shade900,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Block list
              Expanded(
                child: filteredBlocks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No blocks match the current filters',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filteredBlocks.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final block = filteredBlocks[index];
                          return _buildBlockItem(controller, block);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 11),
      ),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: true,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildBlockItem(
      TerminalStationController controller, BlockSection block) {
    final isClosed = controller.isBlockClosed(block.id);
    final isSelected = _selectedBlockId == block.id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedBlockId = isSelected ? null : block.id;
        });
      },
      child: Container(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Block ID
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getBlockColor(block, isClosed),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    block.id,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Block name
                if (block.name != null)
                  Expanded(
                    child: Text(
                      block.name!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  const Spacer(),

                // Toggle button
                IconButton(
                  onPressed: () {
                    controller.toggleBlockClosed(block.id);
                  },
                  icon: Icon(
                    isClosed ? Icons.lock : Icons.lock_open,
                    size: 18,
                  ),
                  color: isClosed ? Colors.red : Colors.green,
                  tooltip: isClosed ? 'Open Block' : 'Close Block',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            // Additional info when selected
            if (isSelected) ...[
              const SizedBox(height: 8),
              _buildBlockDetails(block, isClosed),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBlockDetails(BlockSection block, bool isClosed) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Status', isClosed ? '🚫 CLOSED' : '✅ OPEN',
              isClosed ? Colors.red : Colors.green),
          _buildDetailRow(
              'Occupied', block.occupied ? 'YES' : 'NO',
              block.occupied ? Colors.orange : Colors.grey),
          if (block.occupied && block.occupyingTrainId != null)
            _buildDetailRow('Train', block.occupyingTrainId!, Colors.blue),
          _buildDetailRow(
            'Position',
            'X: ${block.startX.toInt()}-${block.endX.toInt()}, Y: ${block.y.toInt()}',
            Colors.grey,
          ),
          if (isClosed) ...[
            const SizedBox(height: 4),
            Text(
              '⚠️ Auto trains will emergency brake if in or approaching this block',
              style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBlockColor(BlockSection block, bool isClosed) {
    if (isClosed) return Colors.red.shade700;
    if (block.occupied) return Colors.orange.shade700;
    return Colors.green.shade700;
  }

  void _closeAllBlocks(TerminalStationController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close All Blocks'),
        content: const Text(
          'Are you sure you want to close all blocks? This will cause all auto trains to emergency brake.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              for (var block in controller.blocks.values) {
                if (!controller.isBlockClosed(block.id)) {
                  controller.closeBlock(block.id);
                }
              }
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All blocks closed')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Close All'),
          ),
        ],
      ),
    );
  }

  void _openAllBlocks(TerminalStationController controller) {
    for (var block in controller.blocks.values) {
      if (controller.isBlockClosed(block.id)) {
        controller.openBlock(block.id);
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All blocks opened')),
    );
  }
}
