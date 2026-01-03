import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/railway_provider.dart';
import '../models/railway_model.dart' as railway;

class ToolboxPanel extends StatelessWidget {
  const ToolboxPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RailwayProvider>(context);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSelectionTools(provider, context),
                  const SizedBox(height: 24),
                  _buildBlockTools(provider, context),
                  const SizedBox(height: 24),
                  _buildInfrastructureTools(provider, context),
                  const SizedBox(height: 24),
                  _buildQuickAddSection(provider, context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[700],
        border: Border(bottom: BorderSide(color: Colors.blue[800]!)),
      ),
      child: const Row(
        children: [
          Icon(Icons.build, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Text(
            'Toolbox',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionTools(RailwayProvider provider, BuildContext context) {
    return _buildToolSection(
      title: 'Selection Tools',
      tools: railway.ToolThumbnails.getSelectionTools().map((tool) {
        return _buildToolButton(tool, provider, context);
      }).toList(),
    );
  }

  Widget _buildBlockTools(RailwayProvider provider, BuildContext context) {
    return _buildToolSection(
      title: 'Track Elements',
      tools: railway.ToolThumbnails.getTrackTools().map((tool) {
        return _buildDraggableToolButton(tool, provider, context);
      }).toList(),
    );
  }

  Widget _buildInfrastructureTools(
      RailwayProvider provider, BuildContext context) {
    return _buildToolSection(
      title: 'Infrastructure',
      tools: railway.ToolThumbnails.getInfrastructureTools().map((tool) {
        return _buildDraggableToolButton(tool, provider, context);
      }).toList(),
    );
  }

  Widget _buildQuickAddSection(RailwayProvider provider, BuildContext context) {
    return _buildToolSection(
      title: 'Quick Add',
      tools: [
        _buildQuickAddButton(
          'Straight Block',
          Icons.add_circle_outline,
          Colors.blue,
          () => _showQuickBlockDialog(context),
        ),
        _buildQuickAddButton(
          'Signal',
          Icons.add_circle_outline,
          Colors.red,
          () => _showQuickSignalDialog(context),
        ),
        _buildQuickAddButton(
          'Point',
          Icons.add_circle_outline,
          Colors.green,
          () => _showQuickPointDialog(context),
        ),
        _buildQuickAddButton(
          'Platform',
          Icons.add_circle_outline,
          Colors.blue,
          () => _showQuickPlatformDialog(context),
        ),
      ],
    );
  }

  Widget _buildToolSection({
    required String title,
    required List<Widget> tools,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tools,
        ),
      ],
    );
  }

  Widget _buildToolButton(
    railway.DraggableTool tool,
    RailwayProvider provider,
    BuildContext context,
  ) {
    final isActive = provider.currentTool == tool.toolMode;

    return GestureDetector(
      onTap: () {
        provider.currentTool = tool.toolMode;
      },
      child: _buildToolButtonContent(tool, isActive),
    );
  }

  Widget _buildDraggableToolButton(
    railway.DraggableTool tool,
    RailwayProvider provider,
    BuildContext context,
  ) {
    final isActive = provider.currentTool == tool.toolMode;

    return Draggable<railway.DraggableTool>(
      data: tool,
      feedback: _buildToolFeedback(tool),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildToolButtonContent(tool, isActive),
      ),
      child: GestureDetector(
        onTap: () {
          provider.currentTool = tool.toolMode;
        },
        child: _buildToolButtonContent(tool, isActive),
      ),
    );
  }

  Widget _buildToolFeedback(railway.DraggableTool tool) {
    return Material(
      child: Container(
        width: 85,
        height: 85,
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

  Widget _buildToolButtonContent(railway.DraggableTool tool, bool isActive) {
    return Container(
      width: 85,
      height: 85,
      decoration: BoxDecoration(
        color: isActive ? tool.color.withOpacity(0.2) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? tool.color : Colors.grey[300]!,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(tool.icon, color: tool.color, size: 24),
          const SizedBox(height: 4),
          Text(
            tool.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddButton(
      String text, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickBlockDialog(BuildContext context) {
    final provider = Provider.of<RailwayProvider>(context, listen: false);
    final idController = TextEditingController(
        text: 'block_${DateTime.now().millisecondsSinceEpoch}');
    final yController = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Add Block'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                decoration: const InputDecoration(
                  labelText: 'Block ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: yController,
                decoration: const InputDecoration(
                  labelText: 'Y Position',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final block = railway.Block(
                id: idController.text,
                startX: 0,
                endX: 200,
                y: double.parse(yController.text),
                occupied: false,
                occupyingTrain: 'none',
                type: railway.BlockType.straight,
              );
              provider.addBlock(block);
              Navigator.of(context).pop();
              _showSuccessSnackbar(context, 'Block added');
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showQuickSignalDialog(BuildContext context) {
    final provider = Provider.of<RailwayProvider>(context, listen: false);
    final idController = TextEditingController(
        text: 'S${DateTime.now().millisecondsSinceEpoch}');
    final xController = TextEditingController(text: '100');
    final yController = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Add Signal'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                decoration: const InputDecoration(
                  labelText: 'Signal ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: xController,
                      decoration: const InputDecoration(
                        labelText: 'X Position',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: yController,
                      decoration: const InputDecoration(
                        labelText: 'Y Position',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final signal = railway.Signal(
                id: idController.text,
                x: double.parse(xController.text),
                y: double.parse(yController.text),
                aspect: 'red',
                state: 'unset',
                routes: [],
              );
              provider.addSignal(signal);
              Navigator.of(context).pop();
              _showSuccessSnackbar(context, 'Signal added');
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showQuickPointDialog(BuildContext context) {
    final provider = Provider.of<RailwayProvider>(context, listen: false);
    final idController = TextEditingController(
        text: 'P${DateTime.now().millisecondsSinceEpoch}');
    final xController = TextEditingController(text: '100');
    final yController = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Add Point'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                decoration: const InputDecoration(
                  labelText: 'Point ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: xController,
                      decoration: const InputDecoration(
                        labelText: 'X Position',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: yController,
                      decoration: const InputDecoration(
                        labelText: 'Y Position',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final point = railway.Point(
                id: idController.text,
                x: double.parse(xController.text),
                y: double.parse(yController.text),
                position: 'normal',
                locked: false,
              );
              provider.addPoint(point);
              Navigator.of(context).pop();
              _showSuccessSnackbar(context, 'Point added');
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showQuickPlatformDialog(BuildContext context) {
    final provider = Provider.of<RailwayProvider>(context, listen: false);
    final idController = TextEditingController(
        text: 'PL${DateTime.now().millisecondsSinceEpoch}');
    final nameController = TextEditingController(text: 'Platform 1');
    final yController = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Add Platform'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                decoration: const InputDecoration(
                  labelText: 'Platform ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Platform Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: yController,
                decoration: const InputDecoration(
                  labelText: 'Y Position',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final platform = railway.Platform(
                id: idController.text,
                name: nameController.text,
                startX: 0,
                endX: 200,
                y: double.parse(yController.text),
                occupied: false,
              );
              provider.addPlatform(platform);
              Navigator.of(context).pop();
              _showSuccessSnackbar(context, 'Platform added');
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
