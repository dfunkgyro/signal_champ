import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rail_champ/controllers/terminal_station_controller.dart';
import 'package:rail_champ/models/railway_layer.dart';

/// Component types available in the palette
enum ComponentType {
  block,
  signal,
  point,
  crossover,
  platform,
  trainStop,
  bufferStop,
  axleCounter,
  transponder,
  wifiAntenna,
}

/// Extension for component type metadata
extension ComponentTypeExtension on ComponentType {
  String get displayName {
    switch (this) {
      case ComponentType.block:
        return 'Track Block';
      case ComponentType.signal:
        return 'Signal';
      case ComponentType.point:
        return 'Point/Switch';
      case ComponentType.crossover:
        return 'Crossover';
      case ComponentType.platform:
        return 'Platform';
      case ComponentType.trainStop:
        return 'Train Stop';
      case ComponentType.bufferStop:
        return 'Buffer Stop';
      case ComponentType.axleCounter:
        return 'Axle Counter';
      case ComponentType.transponder:
        return 'Transponder';
      case ComponentType.wifiAntenna:
        return 'WiFi Antenna';
    }
  }

  IconData get icon {
    switch (this) {
      case ComponentType.block:
        return Icons.line_axis;
      case ComponentType.signal:
        return Icons.traffic;
      case ComponentType.point:
        return Icons.call_split;
      case ComponentType.crossover:
        return Icons.compare_arrows;
      case ComponentType.platform:
        return Icons.location_city;
      case ComponentType.trainStop:
        return Icons.pan_tool;
      case ComponentType.bufferStop:
        return Icons.stop_circle;
      case ComponentType.axleCounter:
        return Icons.calculate;
      case ComponentType.transponder:
        return Icons.sensors;
      case ComponentType.wifiAntenna:
        return Icons.wifi;
    }
  }

  Color get color {
    switch (this) {
      case ComponentType.block:
        return Colors.blue;
      case ComponentType.signal:
        return Colors.red;
      case ComponentType.point:
        return Colors.orange;
      case ComponentType.crossover:
        return Colors.purple;
      case ComponentType.platform:
        return Colors.green;
      case ComponentType.trainStop:
        return Colors.yellow;
      case ComponentType.bufferStop:
        return Colors.red;
      case ComponentType.axleCounter:
        return Colors.cyan;
      case ComponentType.transponder:
        return Colors.teal;
      case ComponentType.wifiAntenna:
        return Colors.indigo;
    }
  }

  /// Get the appropriate layer type for this component
  LayerType get suggestedLayerType {
    switch (this) {
      case ComponentType.block:
        return LayerType.tracks;
      case ComponentType.signal:
        return LayerType.signals;
      case ComponentType.point:
      case ComponentType.crossover:
        return LayerType.points;
      case ComponentType.platform:
      case ComponentType.trainStop:
      case ComponentType.bufferStop:
        return LayerType.platforms;
      case ComponentType.axleCounter:
      case ComponentType.transponder:
      case ComponentType.wifiAntenna:
        return LayerType.cbtc;
    }
  }
}

/// Component Palette Widget - Photoshop-style draggable component library
class ComponentPalette extends StatefulWidget {
  const ComponentPalette({Key? key}) : super(key: key);

  @override
  State<ComponentPalette> createState() => _ComponentPaletteState();
}

class _ComponentPaletteState extends State<ComponentPalette> {
  bool _isExpanded = true;
  String _searchQuery = '';
  ComponentCategory _selectedCategory = ComponentCategory.all;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          right: BorderSide(color: Colors.grey[700]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),

          // Search bar
          if (_isExpanded) _buildSearchBar(),

          // Category filter
          if (_isExpanded) _buildCategoryFilter(),

          // Component grid
          if (_isExpanded)
            Expanded(
              child: _buildComponentGrid(),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
          Icon(Icons.widgets, size: 20, color: Colors.blue[300]),
          const SizedBox(width: 8),
          const Text(
            'Component Palette',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search components...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 18),
          filled: true,
          fillColor: Colors.grey[850],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: ComponentCategory.values.map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                category.displayName,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCategory = category);
              },
              selectedColor: Colors.blue[700],
              backgroundColor: Colors.grey[800],
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildComponentGrid() {
    final filteredComponents = _getFilteredComponents();

    if (filteredComponents.isEmpty) {
      return Center(
        child: Text(
          'No components found',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemCount: filteredComponents.length,
      itemBuilder: (context, index) {
        return _buildComponentItem(filteredComponents[index]);
      },
    );
  }

  Widget _buildComponentItem(ComponentType component) {
    return Consumer<TerminalStationController>(
      builder: (context, controller, child) {
        return Draggable<ComponentType>(
          data: component,
          feedback: Material(
            color: Colors.transparent,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: component.color.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(component.icon, color: Colors.white, size: 36),
                  const SizedBox(height: 4),
                  Text(
                    component.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: child!,
          ),
          child: _buildComponentCard(component, controller),
        );
      },
    );
  }

  Widget _buildComponentCard(ComponentType component, TerminalStationController controller) {
    // Check if active layer is appropriate for this component
    final activeLayer = controller.activeLayer;
    final isAppropriateLayer = activeLayer != null &&
        (activeLayer.type == component.suggestedLayerType ||
         activeLayer.type == LayerType.custom);

    return Tooltip(
      message: '${component.displayName}\nDrag to canvas to add\nSuggested layer: ${component.suggestedLayerType.displayName}',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAppropriateLayer ? component.color : Colors.grey[700]!,
            width: isAppropriateLayer ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              component.icon,
              color: component.color,
              size: 32,
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                component.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isAppropriateLayer && activeLayer != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.warning_amber,
                  size: 12,
                  color: Colors.orange[300],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<ComponentType> _getFilteredComponents() {
    var components = ComponentType.values.toList();

    // Filter by category
    if (_selectedCategory != ComponentCategory.all) {
      components = components.where((c) {
        return _selectedCategory.componentTypes.contains(c);
      }).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      components = components.where((c) {
        return c.displayName.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    return components;
  }
}

/// Component categories for filtering
enum ComponentCategory {
  all,
  tracks,
  signaling,
  platforms,
  cbtc,
}

extension ComponentCategoryExtension on ComponentCategory {
  String get displayName {
    switch (this) {
      case ComponentCategory.all:
        return 'All';
      case ComponentCategory.tracks:
        return 'Tracks';
      case ComponentCategory.signaling:
        return 'Signaling';
      case ComponentCategory.platforms:
        return 'Platforms';
      case ComponentCategory.cbtc:
        return 'CBTC';
    }
  }

  List<ComponentType> get componentTypes {
    switch (this) {
      case ComponentCategory.all:
        return ComponentType.values;
      case ComponentCategory.tracks:
        return [ComponentType.block, ComponentType.point, ComponentType.crossover];
      case ComponentCategory.signaling:
        return [ComponentType.signal];
      case ComponentCategory.platforms:
        return [
          ComponentType.platform,
          ComponentType.trainStop,
          ComponentType.bufferStop,
        ];
      case ComponentCategory.cbtc:
        return [
          ComponentType.axleCounter,
          ComponentType.transponder,
          ComponentType.wifiAntenna,
        ];
    }
  }
}
