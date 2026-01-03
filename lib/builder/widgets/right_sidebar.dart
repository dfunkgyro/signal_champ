import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/railway_provider.dart';
import '../models/railway_model.dart' as railway;
import 'ai_agent_panel.dart';

class RightSidebar extends StatelessWidget {
  const RightSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RailwayProvider>(context);

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey[300]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context, provider),
          Expanded(
            child: DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  Container(
                    color: Colors.grey[50],
                    child: const TabBar(
                      labelColor: Colors.blue,
                      unselectedLabelColor: Colors.grey,
                      tabs: [
                        Tab(text: 'Properties'),
                        Tab(text: 'Document'),
                        Tab(text: 'Routes'),
                        Tab(text: 'AI Agent'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildPropertiesTab(provider, context),
                        _buildDocumentTab(provider, context),
                        _buildRoutesTab(provider, context),
                        AIAgentPanel(provider: provider),
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
        color: Colors.green[700],
        border: Border(bottom: BorderSide(color: Colors.green[800]!)),
      ),
      child: Row(
        children: [
          const Icon(Icons.tune, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          const Text(
            'Properties',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: () => provider.rightSidebarVisible = false,
            tooltip: 'Collapse Sidebar',
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesTab(RailwayProvider provider, BuildContext context) {
    final selected = provider.selectedElement;

    if (selected == null) {
      return _buildNoSelection();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildElementHeader(selected),
          const SizedBox(height: 16),
          _buildTransformControls(provider, context),
          const SizedBox(height: 16),
          _buildElementProperties(selected, provider, context),
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
            'No Element Selected',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Select an element to edit its properties',
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

  Widget _buildElementHeader(railway.Selection selected) {
    late IconData icon;
    late Color color;
    late String title;
    late String subtitle;

    switch (selected.type) {
      case 'block':
        final block = selected.element as railway.Block;
        icon = Icons.track_changes;
        color = Colors.blue;
        title = 'Block ${block.id}';
        subtitle = _getBlockTypeName(block.type);
        break;
      case 'point':
        final point = selected.element as railway.Point;
        icon = Icons.change_history;
        color = Colors.green;
        title = 'Point ${point.id}';
        subtitle = 'Switch Point';
        break;
      case 'signal':
        final signal = selected.element as railway.Signal;
        icon = Icons.traffic;
        color = Colors.red;
        title = 'Signal ${signal.id}';
        subtitle = 'Signal Mast';
        break;
      case 'platform':
        final platform = selected.element as railway.Platform;
        icon = Icons.train;
        color = Colors.blue;
        title = 'Platform ${platform.id}';
        subtitle = platform.name;
        break;
    }

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

  Widget _buildTransformControls(
      RailwayProvider provider, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transform',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => provider.duplicateSelectedElement(),
                  icon: const Icon(Icons.content_copy, size: 16),
                  label: const Text('Duplicate'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (provider.selectedElement != null) {
                      _showDeleteDialog(context, provider);
                    }
                  },
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildElementProperties(
    railway.Selection selected,
    RailwayProvider provider,
    BuildContext context,
  ) {
    switch (selected.type) {
      case 'block':
        return _buildBlockProperties(
            selected.element as railway.Block, provider, context);
      case 'point':
        return _buildPointProperties(
            selected.element as railway.Point, provider, context);
      case 'signal':
        return _buildSignalProperties(
            selected.element as railway.Signal, provider, context);
      case 'platform':
        return _buildPlatformProperties(
            selected.element as railway.Platform, provider, context);
      default:
        return const SizedBox();
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

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Block Properties',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              _buildReadOnlyField('Type', _getBlockTypeName(block.type)),
              const SizedBox(height: 8),
              _buildReadOnlyField(
                  'Length', '${block.length.toStringAsFixed(1)} units'),
              const SizedBox(height: 8),
              _buildReadOnlyField('Center',
                  '(${block.centerX.toStringAsFixed(1)}, ${block.y.toStringAsFixed(1)})'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Properties',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              _buildTextField(idController, 'Block ID', Icons.tag),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                        startXController, 'Start X', Icons.arrow_left),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                        endXController, 'End X', Icons.arrow_right),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(yController, 'Y Position', Icons.height),
              const SizedBox(height: 12),
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
              const SizedBox(height: 16),
              ElevatedButton(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPointProperties(
      railway.Point point, RailwayProvider provider, BuildContext context) {
    final idController = TextEditingController(text: point.id);
    final xController = TextEditingController(text: point.x.toString());
    final yController = TextEditingController(text: point.y.toString());
    var position = point.position;
    var locked = point.locked;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Point Properties',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              _buildReadOnlyField('Position',
                  '(${point.x.toStringAsFixed(1)}, ${point.y.toStringAsFixed(1)})'),
              const SizedBox(height: 8),
              _buildReadOnlyField(
                  'Status', point.locked ? 'Locked' : 'Unlocked'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Properties',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              _buildTextField(idController, 'Point ID', Icons.tag),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                        xController, 'X Position', Icons.pin_drop),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                        yController, 'Y Position', Icons.height),
                  ),
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
              const SizedBox(height: 16),
              ElevatedButton(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignalProperties(
      railway.Signal signal, RailwayProvider provider, BuildContext context) {
    final idController = TextEditingController(text: signal.id);
    final xController = TextEditingController(text: signal.x.toString());
    final yController = TextEditingController(text: signal.y.toString());
    var aspect = signal.aspect;
    var state = signal.state;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Signal Properties',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              _buildReadOnlyField('Position',
                  '(${signal.x.toStringAsFixed(1)}, ${signal.y.toStringAsFixed(1)})'),
              const SizedBox(height: 8),
              _buildReadOnlyField(
                  'Routes', '${signal.routes.length} routes configured'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Properties',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              _buildTextField(idController, 'Signal ID', Icons.tag),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                        xController, 'X Position', Icons.pin_drop),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                        yController, 'Y Position', Icons.height),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDropdownField(
                value: aspect,
                items: const ['red', 'yellow', 'green', 'double_yellow'],
                label: 'Aspect',
                onChanged: (value) => aspect = value!,
              ),
              const SizedBox(height: 12),
              _buildDropdownField(
                value: state,
                items: const ['unset', 'set', 'locked', 'proved'],
                label: 'State',
                onChanged: (value) => state = value!,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ],
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

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Platform Properties',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              _buildReadOnlyField(
                  'Length', '${platform.length.toStringAsFixed(1)} units'),
              const SizedBox(height: 8),
              _buildReadOnlyField('Position',
                  '(${platform.startX.toStringAsFixed(1)}-${platform.endX.toStringAsFixed(1)}, ${platform.y.toStringAsFixed(1)})'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Properties',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              _buildTextField(idController, 'Platform ID', Icons.tag),
              const SizedBox(height: 12),
              _buildTextField(nameController, 'Platform Name', Icons.title),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                        startXController, 'Start X', Icons.arrow_left),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                        endXController, 'End X', Icons.arrow_right),
                  ),
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
              const SizedBox(height: 16),
              ElevatedButton(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentTab(RailwayProvider provider, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Document Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDocumentStats(provider),
          const SizedBox(height: 16),
          _buildSaveExportButtons(provider, context),
          const SizedBox(height: 16),
          _buildDocumentSettings(provider),
        ],
      ),
    );
  }

  Widget _buildRoutesTab(RailwayProvider provider, BuildContext context) {
    final allRoutes = <railway.Route>[];
    for (final signal in provider.data.signals) {
      allRoutes.addAll(signal.routes);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Route Management',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (allRoutes.isEmpty)
            const Center(
              child: Column(
                children: [
                  Icon(Icons.alt_route, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No Routes Defined',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add routes to signals to manage train paths',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            )
          else
            ...allRoutes
                .map((route) => _buildRouteCard(route, provider, context)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddRouteDialog(context, provider),
            icon: const Icon(Icons.add),
            label: const Text('Add New Route'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(
      railway.Route route, RailwayProvider provider, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alt_route, color: Colors.purple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  route.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () =>
                    _showDeleteRouteDialog(context, route, provider),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('ID: ${route.id}'),
          const SizedBox(height: 8),
          Text('Path Blocks: ${route.pathBlocks.length}'),
          const SizedBox(height: 8),
          Text('Conflicting Routes: ${route.conflictingRoutes.length}'),
        ],
      ),
    );
  }

  Widget _buildDocumentStats(RailwayProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistics',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatItem('Blocks', provider.data.blocks.length.toString()),
          _buildStatItem('Signals', provider.data.signals.length.toString()),
          _buildStatItem('Points', provider.data.points.length.toString()),
          _buildStatItem(
              'Platforms', provider.data.platforms.length.toString()),
          _buildStatItem('Routes', _countTotalRoutes(provider).toString()),
          _buildStatItem(
              'Measurements', provider.measurements.length.toString()),
          _buildStatItem(
              'Text Annotations', provider.textAnnotations.length.toString()),
          _buildStatItem(
              'Unsaved Changes', provider.hasUnsavedChanges ? 'Yes' : 'No'),
        ],
      ),
    );
  }

  int _countTotalRoutes(RailwayProvider provider) {
    int count = 0;
    for (final signal in provider.data.signals) {
      count += signal.routes.length;
    }
    return count;
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveExportButtons(
      RailwayProvider provider, BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () {
            provider.markTabSaved();
            _showSuccessSnackbar(context, 'Document saved');
          },
          icon: const Icon(Icons.save),
          label: const Text('Save Document'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            final xmlContent = provider.exportCurrentToXml();
            _showExportDialog(context, xmlContent, 'XML');
          },
          icon: const Icon(Icons.download),
          label: const Text('Export as XML'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            final svgContent = provider.exportCurrentToSvg();
            _showExportDialog(context, svgContent, 'SVG');
          },
          icon: const Icon(Icons.download),
          label: const Text('Export as SVG'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            final jsonContent = provider.exportCurrentToJson();
            _showExportDialog(context, jsonContent, 'JSON');
          },
          icon: const Icon(Icons.download),
          label: const Text('Export as JSON'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentSettings(RailwayProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Document Settings',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Auto-save'),
            subtitle: const Text('Automatically save changes'),
            value: false,
            onChanged: (value) {},
          ),
          SwitchListTile(
            title: const Text('Show connection points'),
            subtitle: const Text('Display element connection points'),
            value: true,
            onChanged: (value) {},
          ),
          SwitchListTile(
            title: const Text('Smart guides'),
            subtitle: const Text('Show alignment guides'),
            value: true,
            onChanged: (value) {},
          ),
          SwitchListTile(
            title: const Text('Show measurements'),
            subtitle: const Text('Display measurement overlays'),
            value: true,
            onChanged: (value) {},
          ),
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

  void _showDeleteDialog(BuildContext context, RailwayProvider provider) {
    final selected = provider.selectedElement;
    if (selected == null) return;

    String type = selected.type;
    String id = '';
    String name = '';

    switch (selected.type) {
      case 'block':
        final block = selected.element as railway.Block;
        id = block.id;
        name = 'Block ${block.id}';
        break;
      case 'point':
        final point = selected.element as railway.Point;
        id = point.id;
        name = 'Point ${point.id}';
        break;
      case 'signal':
        final signal = selected.element as railway.Signal;
        id = signal.id;
        name = 'Signal ${signal.id}';
        break;
      case 'platform':
        final platform = selected.element as railway.Platform;
        id = platform.id;
        name = 'Platform ${platform.id}';
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $type?'),
        content: Text(
            'Are you sure you want to delete $name? This action cannot be undone.'),
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

  void _showDeleteRouteDialog(
      BuildContext context, railway.Route route, RailwayProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route?'),
        content: Text('Are you sure you want to delete route "${route.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Find and delete the route from its parent signal
              for (final signal in provider.data.signals) {
                final routeIndex =
                    signal.routes.indexWhere((r) => r.id == route.id);
                if (routeIndex != -1) {
                  provider.deleteRouteFromSignal(signal.id, route.id);
                  break;
                }
              }
              Navigator.of(context).pop();
              _showSuccessSnackbar(context, 'Route deleted');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddRouteDialog(BuildContext context, RailwayProvider provider) {
    final idController = TextEditingController(
        text: 'route_${DateTime.now().millisecondsSinceEpoch}');
    final nameController = TextEditingController();
    final startSignalController = TextEditingController();
    final endSignalController = TextEditingController();
    final blocksController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Route'),
        content: SizedBox(
          width: 500,
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
                controller: startSignalController,
                decoration: const InputDecoration(
                  labelText: 'Start Signal ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: endSignalController,
                decoration: const InputDecoration(
                  labelText: 'End Signal ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: blocksController,
                maxLines: 3,
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
                  startSignal: startSignalController.text,
                  endSignal: endSignalController.text,
                );

                if (provider.data.signals.isNotEmpty) {
                  provider.addRouteToSignal(
                      provider.data.signals.first.id, route);
                  Navigator.of(context).pop();
                  _showSuccessSnackbar(context, 'Route added');
                } else {
                  _showErrorSnackbar(
                      context, 'No signals available to add route to');
                }
              }
            },
            child: const Text('Add Route'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context, String content, String format) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exported $format'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      content,
                      style: const TextStyle(
                          fontFamily: 'Monospace', fontSize: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy to Clipboard',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: content));
                      _showSuccessSnackbar(
                          context, '$format copied to clipboard');
                    },
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
