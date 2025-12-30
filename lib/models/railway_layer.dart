import 'package:uuid/uuid.dart';

/// Represents a layer in the railway layout designer
/// Layers organize railway infrastructure components into manageable groups
class RailwayLayer {
  /// Unique identifier for this layer
  final String id;

  /// User-editable name (e.g., "Main Line Tracks", "Platform Signals")
  String name;

  /// Whether this layer is visible in the canvas
  bool isVisible;

  /// Whether this layer is locked (prevents editing components)
  bool isLocked;

  /// Opacity of this layer (0.0 = transparent, 1.0 = opaque)
  double opacity;

  /// Type/category of this layer
  LayerType type;

  /// Set of component IDs that belong to this layer
  /// Components can be blocks, signals, points, platforms, etc.
  final Set<String> componentIds;

  RailwayLayer({
    String? id,
    required this.name,
    this.isVisible = true,
    this.isLocked = false,
    this.opacity = 1.0,
    required this.type,
    Set<String>? componentIds,
  })  : id = id ?? const Uuid().v4(),
        componentIds = componentIds ?? {};

  /// Create a copy of this layer with optional modifications
  RailwayLayer copyWith({
    String? id,
    String? name,
    bool? isVisible,
    bool? isLocked,
    double? opacity,
    LayerType? type,
    Set<String>? componentIds,
  }) {
    return RailwayLayer(
      id: id ?? this.id,
      name: name ?? this.name,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
      opacity: opacity ?? this.opacity,
      type: type ?? this.type,
      componentIds: componentIds ?? Set.from(this.componentIds),
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isVisible': isVisible,
      'isLocked': isLocked,
      'opacity': opacity,
      'type': type.name,
      'componentIds': componentIds.toList(),
    };
  }

  /// Create from JSON
  factory RailwayLayer.fromJson(Map<String, dynamic> json) {
    return RailwayLayer(
      id: json['id'] as String,
      name: json['name'] as String,
      isVisible: json['isVisible'] as bool? ?? true,
      isLocked: json['isLocked'] as bool? ?? false,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      type: LayerType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => LayerType.custom,
      ),
      componentIds: Set<String>.from(json['componentIds'] as List? ?? []),
    );
  }

  /// Add a component to this layer
  void addComponent(String componentId) {
    componentIds.add(componentId);
  }

  /// Remove a component from this layer
  void removeComponent(String componentId) {
    componentIds.remove(componentId);
  }

  /// Check if this layer contains a specific component
  bool containsComponent(String componentId) {
    return componentIds.contains(componentId);
  }

  @override
  String toString() {
    return 'RailwayLayer(id: $id, name: $name, visible: $isVisible, locked: $isLocked, components: ${componentIds.length})';
  }
}

/// Types of railway infrastructure layers
enum LayerType {
  /// Track blocks and crossovers
  tracks,

  /// All signals (main, distant, shunt, etc.)
  signals,

  /// All points/switches
  points,

  /// Platforms, train stops, buffer stops
  platforms,

  /// CBTC infrastructure (transponders, WiFi, axle counters)
  cbtc,

  /// User-defined mixed layer
  custom,

  /// Background layer (grid, reference lines)
  background,
}

/// Extension to get display names and icons for layer types
extension LayerTypeExtension on LayerType {
  /// User-friendly display name
  String get displayName {
    switch (this) {
      case LayerType.tracks:
        return 'Tracks';
      case LayerType.signals:
        return 'Signals';
      case LayerType.points:
        return 'Points';
      case LayerType.platforms:
        return 'Platforms';
      case LayerType.cbtc:
        return 'CBTC';
      case LayerType.custom:
        return 'Custom';
      case LayerType.background:
        return 'Background';
    }
  }

  /// Icon name for this layer type (Material Icons)
  String get iconName {
    switch (this) {
      case LayerType.tracks:
        return 'train';
      case LayerType.signals:
        return 'traffic';
      case LayerType.points:
        return 'alt_route';
      case LayerType.platforms:
        return 'location_city';
      case LayerType.cbtc:
        return 'wifi';
      case LayerType.custom:
        return 'layers';
      case LayerType.background:
        return 'grid_on';
    }
  }
}
