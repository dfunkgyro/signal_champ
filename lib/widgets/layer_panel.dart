import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rail_champ/controllers/terminal_station_controller.dart';
import 'package:rail_champ/models/railway_layer.dart';

/// Layer management panel for organizing railway infrastructure components
/// Provides Photoshop-style layer controls: visibility, lock, opacity, reorder
class LayerPanel extends StatefulWidget {
  const LayerPanel({Key? key}) : super(key: key);

  @override
  State<LayerPanel> createState() => _LayerPanelState();
}

class _LayerPanelState extends State<LayerPanel> {
  String? _editingLayerId; // Layer currently being renamed

  @override
  Widget build(BuildContext context) {
    return Consumer<TerminalStationController>(
      builder: (context, controller, child) {
        return Container(
          width: 280,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            border: Border(
              left: BorderSide(color: Colors.grey[700]!, width: 1),
            ),
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(context),
              
              // Layer list
              Expanded(
                child: _buildLayerList(controller),
              ),
              
              // Footer with action buttons
              _buildFooter(controller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        border: Border(
          bottom: BorderSide(color: Colors.grey[700]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.layers, size: 20, color: Colors.blue[300]),
          const SizedBox(width: 8),
          const Text(
            'Layers',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Consumer<TerminalStationController>(
            builder: (context, controller, child) {
              return Text(
                '${controller.layers.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLayerList(TerminalStationController controller) {
    if (controller.layers.isEmpty) {
      return Center(
        child: Text(
          'No layers',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    // Reverse list to show top layer first (Photoshop convention)
    final reversedLayers = controller.layers.reversed.toList();

    return ReorderableListView.builder(
      itemCount: reversedLayers.length,
      onReorder: (oldIndex, newIndex) {
        // Convert reversed indices back to original indices
        final actualOldIndex = controller.layers.length - 1 - oldIndex;
        final actualNewIndex = controller.layers.length - 1 - newIndex;
        controller.reorderLayers(actualOldIndex, actualNewIndex);
      },
      itemBuilder: (context, index) {
        final layer = reversedLayers[index];
        final isActive = controller.activeLayer == layer;

        return _buildLayerItem(
          key: ValueKey(layer.id),
          layer: layer,
          isActive: isActive,
          controller: controller,
        );
      },
    );
  }

  Widget _buildLayerItem({
    required Key key,
    required RailwayLayer layer,
    required bool isActive,
    required TerminalStationController controller,
  }) {
    final isEditing = _editingLayerId == layer.id;

    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue[900]!.withOpacity(0.3) : Colors.grey[850],
        border: Border.all(
          color: isActive ? Colors.blue[600]! : Colors.grey[700]!,
          width: isActive ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        onTap: () => controller.setActiveLayer(layer.id),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: visibility, lock, name, component count
              Row(
                children: [
                  // Visibility toggle
                  IconButton(
                    icon: Icon(
                      layer.isVisible ? Icons.visibility : Icons.visibility_off,
                      size: 18,
                    ),
                    color: layer.isVisible ? Colors.white : Colors.grey[600],
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => controller.toggleLayerVisibility(layer.id),
                  ),
                  const SizedBox(width: 8),
                  
                  // Lock toggle
                  IconButton(
                    icon: Icon(
                      layer.isLocked ? Icons.lock : Icons.lock_open,
                      size: 18,
                    ),
                    color: layer.isLocked ? Colors.red[300] : Colors.grey[600],
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => controller.toggleLayerLock(layer.id),
                  ),
                  const SizedBox(width: 8),
                  
                  // Layer type icon
                  Icon(
                    _getLayerIcon(layer.type),
                    size: 16,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(width: 8),
                  
                  // Layer name (editable)
                  Expanded(
                    child: isEditing
                        ? TextField(
                            autofocus: true,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 4),
                              border: OutlineInputBorder(),
                            ),
                            controller: TextEditingController(text: layer.name),
                            onSubmitted: (value) {
                              if (value.isNotEmpty) {
                                controller.renameLayer(layer.id, value);
                              }
                              setState(() => _editingLayerId = null);
                            },
                            onEditingComplete: () {
                              setState(() => _editingLayerId = null);
                            },
                          )
                        : GestureDetector(
                            onDoubleTap: () {
                              setState(() => _editingLayerId = layer.id);
                            },
                            child: Text(
                              layer.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Component count badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${layer.componentIds.length}',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Opacity slider
              if (layer.opacity < 1.0 || isActive)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.opacity, size: 14, color: Colors.grey[500]),
                      Expanded(
                        child: Slider(
                          value: layer.opacity,
                          min: 0.0,
                          max: 1.0,
                          divisions: 20,
                          label: '${(layer.opacity * 100).round()}%',
                          onChanged: (value) {
                            controller.setLayerOpacity(layer.id, value);
                          },
                        ),
                      ),
                      Text(
                        '${(layer.opacity * 100).round()}%',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(TerminalStationController controller) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        border: Border(
          top: BorderSide(color: Colors.grey[700]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Add layer button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showAddLayerDialog(context, controller),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Layer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // More actions menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) => _handleMenuAction(value, controller),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.content_copy, size: 18),
                    SizedBox(width: 8),
                    Text('Duplicate Layer'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'merge_down',
                child: Row(
                  children: [
                    Icon(Icons.merge, size: 18),
                    SizedBox(width: 8),
                    Text('Merge Down'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, size: 18),
                    SizedBox(width: 8),
                    Text('Clear Layer'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Layer', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddLayerDialog(BuildContext context, TerminalStationController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Layer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Layer Name',
                hintText: 'e.g., Platform Signals',
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  controller.addLayer(name: value);
                  Navigator.pop(context);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<LayerType>(
              decoration: const InputDecoration(labelText: 'Layer Type'),
              value: LayerType.custom,
              items: LayerType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(_getLayerIcon(type), size: 18),
                      const SizedBox(width: 8),
                      Text(type.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {},
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
              controller.addLayer();
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, TerminalStationController controller) {
    final activeLayer = controller.activeLayer;
    if (activeLayer == null) return;

    switch (action) {
      case 'duplicate':
        controller.duplicateLayer(activeLayer.id);
        break;
      case 'merge_down':
        controller.mergeLayerDown(activeLayer.id);
        break;
      case 'clear':
        _confirmClearLayer(context, controller, activeLayer);
        break;
      case 'delete':
        _confirmDeleteLayer(context, controller, activeLayer);
        break;
    }
  }

  void _confirmClearLayer(BuildContext context, TerminalStationController controller, RailwayLayer layer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Layer'),
        content: Text('Remove all ${layer.componentIds.length} components from "${layer.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.clearLayer(layer.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteLayer(BuildContext context, TerminalStationController controller, RailwayLayer layer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Layer'),
        content: Text('Delete "${layer.name}" and move its ${layer.componentIds.length} components to another layer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.removeLayer(layer.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _getLayerIcon(LayerType type) {
    switch (type) {
      case LayerType.tracks:
        return Icons.train;
      case LayerType.signals:
        return Icons.traffic;
      case LayerType.points:
        return Icons.alt_route;
      case LayerType.platforms:
        return Icons.location_city;
      case LayerType.cbtc:
        return Icons.wifi;
      case LayerType.custom:
        return Icons.layers;
      case LayerType.background:
        return Icons.grid_on;
    }
  }
}
