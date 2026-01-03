import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/railway_provider.dart';
import '../models/railway_model.dart' as railway;

class LeftSidebar extends StatelessWidget {
  const LeftSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RailwayProvider>(context);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey[300]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context, provider),
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  Container(
                    color: Colors.grey[50],
                    child: const TabBar(
                      labelColor: Colors.blue,
                      unselectedLabelColor: Colors.grey,
                      tabs: [
                        Tab(text: 'Tools'),
                        Tab(text: 'Elements'),
                        Tab(text: 'Layers'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildToolsTab(provider, context),
                        _buildElementsTab(provider, context),
                        _buildLayersTab(provider, context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, RailwayProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[700],
        border: Border(bottom: BorderSide(color: Colors.blue[800]!)),
      ),
      child: Row(
        children: [
          const Icon(Icons.build, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          const Text(
            'Toolbox',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () => provider.leftSidebarVisible = false,
            tooltip: 'Collapse Sidebar',
          ),
        ],
      ),
    );
  }

  Widget _buildToolsTab(RailwayProvider provider, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTransformTools(provider),
          const SizedBox(height: 24),
          _buildGridSettings(provider),
          const SizedBox(height: 24),
          _buildViewControls(provider),
          const SizedBox(height: 24),
          _buildMeasurementTools(provider),
        ],
      ),
    );
  }

  Widget _buildTransformTools(RailwayProvider provider) {
    final transformTools = [
      const railway.TransformTool(
        id: 'select',
        name: 'Select',
        icon: Icons.select_all,
        mode: railway.TransformMode.select,
      ),
      const railway.TransformTool(
        id: 'move',
        name: 'Move',
        icon: Icons.open_with,
        mode: railway.TransformMode.move,
      ),
      const railway.TransformTool(
        id: 'rotate',
        name: 'Rotate',
        icon: Icons.rotate_right,
        mode: railway.TransformMode.rotate,
      ),
      const railway.TransformTool(
        id: 'scale',
        name: 'Scale',
        icon: Icons.zoom_out_map,
        mode: railway.TransformMode.scale,
      ),
      const railway.TransformTool(
        id: 'duplicate',
        name: 'Duplicate',
        icon: Icons.content_copy,
        mode: railway.TransformMode.duplicate,
      ),
      const railway.TransformTool(
        id: 'delete',
        name: 'Delete',
        icon: Icons.delete,
        mode: railway.TransformMode.delete,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transform Tools',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: transformTools.map((tool) {
            return _buildTransformToolButton(tool, provider);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTransformToolButton(
      railway.TransformTool tool, RailwayProvider provider) {
    final isActive = provider.transformMode == tool.mode;

    return Tooltip(
      message: tool.name,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isActive ? Colors.blue[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? Colors.blue : Colors.grey[300]!,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => provider.transformMode = tool.mode,
            borderRadius: BorderRadius.circular(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(tool.icon,
                    color: isActive ? Colors.blue : Colors.grey[700]),
                const SizedBox(height: 4),
                Text(
                  tool.name,
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive ? Colors.blue : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridSettings(RailwayProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Grid Settings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Checkbox(
              value: provider.gridSettings.enabled,
              onChanged: (value) {
                provider.gridSettings = provider.gridSettings.copyWith(
                  enabled: value ?? false,
                );
              },
            ),
            const Text('Show Grid'),
          ],
        ),
        Row(
          children: [
            Checkbox(
              value: provider.gridSettings.snapToGrid,
              onChanged: (value) {
                provider.gridSettings = provider.gridSettings.copyWith(
                  snapToGrid: value ?? false,
                );
              },
            ),
            const Text('Snap to Grid'),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Grid Size: ${provider.gridSettings.cellSize.toInt()}px',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Slider(
          value: provider.gridSettings.cellSize,
          min: 10,
          max: 50,
          divisions: 4,
          onChanged: (value) {
            provider.gridSettings = provider.gridSettings.copyWith(
              cellSize: value,
            );
          },
        ),
      ],
    );
  }

  Widget _buildViewControls(RailwayProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'View Controls',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildViewControlButton(
              'Zoom In',
              Icons.zoom_in,
              () {
                provider.zoomLevel += 0.1;
              },
            ),
            _buildViewControlButton(
              'Zoom Out',
              Icons.zoom_out,
              () {
                provider.zoomLevel -= 0.1;
              },
            ),
            _buildViewControlButton(
              'Fit to Screen',
              Icons.fit_screen,
              () {
                provider.zoomLevel = 1.0;
              },
            ),
            _buildViewControlButton(
              'Reset View',
              Icons.refresh,
              () {
                provider.zoomLevel = 1.0;
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMeasurementTools(RailwayProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Measurement Tools',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildViewControlButton(
              'Measure',
              Icons.straighten,
              () {
                provider.currentTool = railway.ToolMode.measure;
              },
            ),
            _buildViewControlButton(
              'Clear All',
              Icons.cleaning_services,
              () {
                provider.clearMeasurements();
              },
            ),
          ],
        ),
        if (provider.measurements.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Recent Measurements:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          ...provider.measurements.reversed.take(3).map((measurement) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${measurement.distance.toStringAsFixed(1)} units',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildViewControlButton(
      String label, IconData icon, VoidCallback onTap) {
    return Container(
      width: 70,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: Colors.grey[700]),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 10, color: Color.fromRGBO(97, 97, 97, 1)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildElementsTab(RailwayProvider provider, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildElementCategory('Track Elements',
              railway.ToolThumbnails.getTrackTools(), provider, context),
          const SizedBox(height: 16),
          _buildElementCategory(
              'Infrastructure',
              railway.ToolThumbnails.getInfrastructureTools(),
              provider,
              context),
        ],
      ),
    );
  }

  Widget _buildElementCategory(
    String title,
    List<railway.DraggableTool> tools,
    RailwayProvider provider,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tools.map((tool) {
            return _buildDraggableElement(tool, provider, context);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDraggableElement(
    railway.DraggableTool tool,
    RailwayProvider provider,
    BuildContext context,
  ) {
    return Draggable<railway.DraggableTool>(
      data: tool,
      feedback: _buildElementFeedback(tool),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildElementContent(tool),
      ),
      child: _buildElementContent(tool),
    );
  }

  Widget _buildElementFeedback(railway.DraggableTool tool) {
    return Material(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: tool.color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tool.color, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(tool.icon, color: tool.color, size: 24),
            const SizedBox(height: 4),
            Text(
              tool.label.split('\n').first,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: tool.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElementContent(railway.DraggableTool tool) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(tool.icon, color: tool.color, size: 24),
          const SizedBox(height: 4),
          Text(
            tool.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayersTab(RailwayProvider provider, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Document Layers',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildLayerList(provider),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Add new layer functionality
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Layer'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerList(RailwayProvider provider) {
    final layers = [
      {
        'name': 'Tracks',
        'visible': true,
        'locked': false,
        'count': provider.data.blocks.length
      },
      {
        'name': 'Signals',
        'visible': true,
        'locked': false,
        'count': provider.data.signals.length
      },
      {
        'name': 'Points',
        'visible': true,
        'locked': false,
        'count': provider.data.points.length
      },
      {
        'name': 'Platforms',
        'visible': true,
        'locked': false,
        'count': provider.data.platforms.length
      },
      {
        'name': 'Measurements',
        'visible': true,
        'locked': false,
        'count': provider.measurements.length
      },
      {
        'name': 'Text Annotations',
        'visible': true,
        'locked': false,
        'count': provider.textAnnotations.length
      },
    ];

    return Column(
      children: layers.map((layer) {
        return _buildLayerItem(layer);
      }).toList(),
    );
  }

  Widget _buildLayerItem(Map<String, dynamic> layer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(
            layer['visible'] ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  layer['name'],
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${layer['count']} elements',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Icon(
            layer['locked'] ? Icons.lock : Icons.lock_open,
            color: Colors.grey[600],
            size: 20,
          ),
        ],
      ),
    );
  }
}
