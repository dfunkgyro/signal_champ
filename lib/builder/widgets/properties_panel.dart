import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/railway_provider.dart';
import '../models/railway_model.dart' as railway;

class PropertiesPanel extends StatelessWidget {
  const PropertiesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RailwayProvider>(context);
    final selected = provider.selectedElement;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: selected == null
                ? _buildNoSelection()
                : _buildPropertiesForElement(selected, provider, context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[700],
        border: Border(bottom: BorderSide(color: Colors.green[800]!)),
      ),
      child: const Row(
        children: [
          Icon(Icons.tune, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Text(
            'Properties',
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

  Widget _buildNoSelection() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.select_all, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Select an element to edit',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Click on any track, signal, point, or platform',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesForElement(railway.Selection selected,
      RailwayProvider provider, BuildContext context) {
    switch (selected.type) {
      case 'block':
        return _buildBlockProperties(selected.element, provider, context);
      case 'point':
        return _buildPointProperties(selected.element, provider, context);
      case 'signal':
        return _buildSignalProperties(selected.element, provider, context);
      case 'platform':
        return _buildPlatformProperties(selected.element, provider, context);
      default:
        return _buildNoSelection();
    }
  }

  Widget _buildBlockProperties(
      railway.Block block, RailwayProvider provider, BuildContext context) {
    final idController = TextEditingController(text: block.id);
    final startXController =
        TextEditingController(text: block.startX.toString());
    final endXController = TextEditingController(text: block.endX.toString());
    final yController = TextEditingController(text: block.y.toString());
    final trainController = TextEditingController(text: block.occupyingTrain);
    var occupied = block.occupied;
    var type = block.type;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildElementHeader(
            icon: Icons.track_changes,
            title: 'Block ${block.id}',
            subtitle: 'Track Element',
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildPropertyCard(
            children: [
              _buildReadOnlyField('Type', _getBlockTypeName(block.type)),
              const SizedBox(height: 12),
              _buildReadOnlyField(
                  'Length', '${block.length.toStringAsFixed(1)} units'),
              const SizedBox(height: 12),
              _buildReadOnlyField('Center',
                  '(${block.centerX.toStringAsFixed(1)}, ${block.y.toStringAsFixed(1)})'),
            ],
          ),
          const SizedBox(height: 16),
          _buildPropertyCard(
            title: 'Basic Properties',
            children: [
              _buildTextField(idController, 'Block ID', Icons.tag),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _buildTextField(
                          startXController, 'Start X', Icons.arrow_left)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildTextField(
                          endXController, 'End X', Icons.arrow_right)),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(yController, 'Y Position', Icons.height),
            ],
          ),
          const SizedBox(height: 16),
          _buildPropertyCard(
            title: 'Status & Type',
            children: [
              _buildDropdownField(
                value: type,
                items: railway.BlockType.values,
                label: 'Block Type',
                onChanged: (value) => type = value!,
                displayText: (type) => _getBlockTypeName(type),
              ),
              const SizedBox(height: 12),
              _buildOccupiedSection(
                occupied: occupied,
                trainController: trainController,
                onOccupiedChanged: (value) => occupied = value,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final updatedBlock = block.copyWith(
                      id: idController.text,
                      startX: double.parse(startXController.text),
                      endX: double.parse(endXController.text),
                      y: double.parse(yController.text),
                      occupied: occupied,
                      occupyingTrain: occupied ? trainController.text : 'none',
                      type: type,
                    );
                    provider.updateBlock(block.id, updatedBlock);
                    _showSuccessSnackbar(context, 'Block updated');
                  },
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () =>
                    _showDeleteDialog(context, 'block', block.id, provider),
                icon: const Icon(Icons.delete),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                tooltip: 'Delete Block',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPointProperties(
      railway.Point point, RailwayProvider provider, BuildContext context) {
    final idController = TextEditingController(text: point.id);
    final xController = TextEditingController(text: point.x.toString());
    final yController = TextEditingController(text: point.y.toString());
    var position = point.position;
    var locked = point.locked;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildElementHeader(
            icon: Icons.change_history,
            title: 'Point ${point.id}',
            subtitle: 'Switch Point',
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          _buildPropertyCard(
            children: [
              _buildReadOnlyField('Position',
                  '(${point.x.toStringAsFixed(1)}, ${point.y.toStringAsFixed(1)})'),
              const SizedBox(height: 12),
              _buildReadOnlyField(
                  'Status', point.locked ? 'Locked' : 'Unlocked'),
            ],
          ),
          const SizedBox(height: 16),
          _buildPropertyCard(
            title: 'Properties',
            children: [
              _buildTextField(idController, 'Point ID', Icons.tag),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _buildTextField(
                          xController, 'X Position', Icons.pin_drop)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildTextField(
                          yController, 'Y Position', Icons.height)),
                ],
              ),
              const SizedBox(height: 12),
              _buildDropdownField(
                value: position,
                items: const ['normal', 'reverse'],
                label: 'Position',
                onChanged: (value) => position = value!,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: locked,
                    onChanged: (value) => locked = value ?? false,
                  ),
                  const Text('Locked'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final updatedPoint = point.copyWith(
                      id: idController.text,
                      x: double.parse(xController.text),
                      y: double.parse(yController.text),
                      position: position,
                      locked: locked,
                    );
                    provider.updatePoint(point.id, updatedPoint);
                    _showSuccessSnackbar(context, 'Point updated');
                  },
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () =>
                    _showDeleteDialog(context, 'point', point.id, provider),
                icon: const Icon(Icons.delete),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                tooltip: 'Delete Point',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignalProperties(
      railway.Signal signal, RailwayProvider provider, BuildContext context) {
    final idController = TextEditingController(text: signal.id);
    final xController = TextEditingController(text: signal.x.toString());
    final yController = TextEditingController(text: signal.y.toString());
    var aspect = signal.aspect;
    var state = signal.state;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildElementHeader(
            icon: Icons.traffic,
            title: 'Signal ${signal.id}',
            subtitle: 'Signal Mast',
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          _buildPropertyCard(
            children: [
              _buildReadOnlyField('Position',
                  '(${signal.x.toStringAsFixed(1)}, ${signal.y.toStringAsFixed(1)})'),
              const SizedBox(height: 12),
              _buildReadOnlyField(
                  'Routes', '${signal.routes.length} routes configured'),
            ],
          ),
          const SizedBox(height: 16),
          _buildPropertyCard(
            title: 'Basic Properties',
            children: [
              _buildTextField(idController, 'Signal ID', Icons.tag),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _buildTextField(
                          xController, 'X Position', Icons.pin_drop)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildTextField(
                          yController, 'Y Position', Icons.height)),
                ],
              ),
              const SizedBox(height: 12),
              _buildDropdownField(
                value: aspect,
                items: const ['red', 'yellow', 'green'],
                label: 'Aspect',
                onChanged: (value) => aspect = value!,
              ),
              const SizedBox(height: 12),
              _buildDropdownField(
                value: state,
                items: const ['unset', 'set', 'locked'],
                label: 'State',
                onChanged: (value) => state = value!,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPropertyCard(
            title: 'Routes (${signal.routes.length})',
            children: [
              if (signal.routes.isEmpty)
                const Text(
                  'No routes configured',
                  style: TextStyle(
                      color: Colors.grey, fontStyle: FontStyle.italic),
                )
              else
                ...signal.routes.map((route) =>
                    _buildRouteItem(route, signal, provider, context)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _showAddRouteDialog(context, signal, provider),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Route'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[50],
                  foregroundColor: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final updatedSignal = signal.copyWith(
                      id: idController.text,
                      x: double.parse(xController.text),
                      y: double.parse(yController.text),
                      aspect: aspect,
                      state: state,
                    );
                    provider.updateSignal(signal.id, updatedSignal);
                    _showSuccessSnackbar(context, 'Signal updated');
                  },
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () =>
                    _showDeleteDialog(context, 'signal', signal.id, provider),
                icon: const Icon(Icons.delete),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                tooltip: 'Delete Signal',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformProperties(railway.Platform platform,
      RailwayProvider provider, BuildContext context) {
    final idController = TextEditingController(text: platform.id);
    final nameController = TextEditingController(text: platform.name);
    final startXController =
        TextEditingController(text: platform.startX.toString());
    final endXController =
        TextEditingController(text: platform.endX.toString());
    final yController = TextEditingController(text: platform.y.toString());
    var occupied = platform.occupied;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildElementHeader(
            icon: Icons.train,
            title: 'Platform ${platform.id}',
            subtitle: platform.name,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildPropertyCard(
            children: [
              _buildReadOnlyField(
                  'Length', '${platform.length.toStringAsFixed(1)} units'),
              const SizedBox(height: 12),
              _buildReadOnlyField('Position',
                  '(${platform.startX.toStringAsFixed(1)}-${platform.endX.toStringAsFixed(1)}, ${platform.y.toStringAsFixed(1)})'),
            ],
          ),
          const SizedBox(height: 16),
          _buildPropertyCard(
            title: 'Properties',
            children: [
              _buildTextField(idController, 'Platform ID', Icons.tag),
              const SizedBox(height: 12),
              _buildTextField(nameController, 'Platform Name', Icons.title),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _buildTextField(
                          startXController, 'Start X', Icons.arrow_left)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildTextField(
                          endXController, 'End X', Icons.arrow_right)),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(yController, 'Y Position', Icons.height),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: occupied,
                    onChanged: (value) => occupied = value ?? false,
                  ),
                  const Text('Occupied'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final updatedPlatform = platform.copyWith(
                      id: idController.text,
                      name: nameController.text,
                      startX: double.parse(startXController.text),
                      endX: double.parse(endXController.text),
                      y: double.parse(yController.text),
                      occupied: occupied,
                    );
                    provider.updatePlatform(platform.id, updatedPlatform);
                    _showSuccessSnackbar(context, 'Platform updated');
                  },
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _showDeleteDialog(
                    context, 'platform', platform.id, provider),
                icon: const Icon(Icons.delete),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                tooltip: 'Delete Platform',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods for building UI components
  Widget _buildElementHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard({
    String? title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required T value,
    required List<T> items,
    required String label,
    required Function(T?) onChanged,
    String Function(T)? displayText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[400]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            items: items.map((T item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(
                  displayText?.call(item) ?? item.toString(),
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildOccupiedSection({
    required bool occupied,
    required TextEditingController trainController,
    required Function(bool) onOccupiedChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: occupied,
              onChanged: (value) => onOccupiedChanged(value ?? false),
            ),
            const Text('Occupied'),
          ],
        ),
        if (occupied) ...[
          const SizedBox(height: 8),
          TextField(
            controller: trainController,
            decoration: const InputDecoration(
              labelText: 'Occupying Train',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRouteItem(railway.Route route, railway.Signal signal,
      RailwayProvider provider, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${route.pathBlocks.length} blocks',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18),
            onPressed: () =>
                provider.deleteRouteFromSignal(signal.id, route.id),
            tooltip: 'Delete Route',
          ),
        ],
      ),
    );
  }

  void _showAddRouteDialog(
      BuildContext context, railway.Signal signal, RailwayProvider provider) {
    final idController = TextEditingController(
        text: '${signal.id}_R${signal.routes.length + 1}');
    final nameController = TextEditingController();
    final blocksController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Route to Signal'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                decoration: const InputDecoration(
                  labelText: 'Route ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Route Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: blocksController,
                decoration: const InputDecoration(
                  labelText: 'Path Blocks (comma separated)',
                  border: OutlineInputBorder(),
                ),
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
              if (idController.text.isNotEmpty &&
                  nameController.text.isNotEmpty) {
                final route = railway.Route(
                  id: idController.text,
                  name: nameController.text,
                  requiredBlocks: blocksController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList(),
                  pathBlocks: blocksController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList(),
                  conflictingRoutes: [],
                  startSignal: signal.id,
                  endSignal: '',
                );
                provider.addRouteToSignal(signal.id, route);
                Navigator.of(context).pop();
                _showSuccessSnackbar(context, 'Route added');
              }
            },
            child: const Text('Add Route'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, String type, String id, RailwayProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $type?'),
        content: Text(
            'Are you sure you want to delete $type $id? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              switch (type) {
                case 'block':
                  provider.deleteBlock(id);
                  break;
                case 'point':
                  provider.deletePoint(id);
                  break;
                case 'signal':
                  provider.deleteSignal(id);
                  break;
                case 'platform':
                  provider.deletePlatform(id);
                  break;
              }
              Navigator.of(context).pop();
              _showSuccessSnackbar(context, '$type deleted');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getBlockTypeName(railway.BlockType type) {
    switch (type) {
      case railway.BlockType.straight:
        return 'Straight Track';
      case railway.BlockType.crossover:
        return 'Crossover';
      case railway.BlockType.curve:
        return 'Curve';
      case railway.BlockType.switchLeft:
        return 'Left Switch';
      case railway.BlockType.switchRight:
        return 'Right Switch';
      case railway.BlockType.station:
        return 'Station';
      case railway.BlockType.end:
        return 'End Buffer';
    }
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
