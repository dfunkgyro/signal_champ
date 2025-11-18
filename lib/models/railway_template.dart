import 'package:flutter/material.dart';
import 'terminal_station_models.dart';

/// Template categories for railway layout elements
enum TemplateCategory {
  signals,
  points,
  tracks,
  platforms,
  crossovers,
  stations,
}

/// Railway layout template item
class RailwayTemplate {
  final String id;
  final String name;
  final String description;
  final TemplateCategory category;
  final IconData icon;
  final Map<String, dynamic> properties;

  const RailwayTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.properties,
  });

  /// Create a template from a signal
  factory RailwayTemplate.fromSignal(Signal signal) {
    return RailwayTemplate(
      id: 'signal_${signal.id}',
      name: 'Signal ${signal.id}',
      description: '${signal.routes.length} route signal',
      category: TemplateCategory.signals,
      icon: Icons.traffic,
      properties: {
        'type': 'signal',
        'id': signal.id,
        'x': signal.x,
        'y': signal.y,
        'routes': signal.routes.length,
      },
    );
  }

  /// Create a template from a point
  factory RailwayTemplate.fromPoint(Point point) {
    return RailwayTemplate(
      id: 'point_${point.id}',
      name: 'Point ${point.id}',
      description: 'Track point switch',
      category: TemplateCategory.points,
      icon: Icons.call_split,
      properties: {
        'type': 'point',
        'id': point.id,
        'x': point.x,
        'y': point.y,
      },
    );
  }

  /// Create a template from a platform
  factory RailwayTemplate.fromPlatform(Platform platform) {
    return RailwayTemplate(
      id: 'platform_${platform.id}',
      name: platform.name,
      description: 'Station platform',
      category: TemplateCategory.platforms,
      icon: Icons.train_outlined,
      properties: {
        'type': 'platform',
        'id': platform.id,
        'startX': platform.startX,
        'endX': platform.endX,
        'y': platform.y,
      },
    );
  }

  /// Create a template from a crossover
  factory RailwayTemplate.fromCrossover(BlockSection crossover) {
    return RailwayTemplate(
      id: 'crossover_${crossover.id}',
      name: crossover.name ?? 'Crossover ${crossover.id}',
      description: 'Track crossover',
      category: TemplateCategory.crossovers,
      icon: Icons.alt_route,
      properties: {
        'type': 'crossover',
        'id': crossover.id,
        'startX': crossover.startX,
        'endX': crossover.endX,
        'y': crossover.y,
      },
    );
  }
}

/// Predefined railway templates library
class RailwayTemplateLibrary {
  static List<RailwayTemplate> getStandardTemplates() {
    return [
      // Standard signals
      const RailwayTemplate(
        id: 'signal_2aspect',
        name: '2-Aspect Signal',
        description: 'Standard red/green signal',
        category: TemplateCategory.signals,
        icon: Icons.traffic,
        properties: {
          'type': 'signal',
          'aspects': 2,
          'routes': 1,
        },
      ),
      const RailwayTemplate(
        id: 'signal_dual_route',
        name: 'Dual Route Signal',
        description: 'Signal with 2 routes',
        category: TemplateCategory.signals,
        icon: Icons.traffic,
        properties: {
          'type': 'signal',
          'aspects': 2,
          'routes': 2,
        },
      ),

      // Track points
      const RailwayTemplate(
        id: 'point_left',
        name: 'Left-Hand Point',
        description: 'Point diverging left',
        category: TemplateCategory.points,
        icon: Icons.call_split,
        properties: {
          'type': 'point',
          'direction': 'left',
        },
      ),
      const RailwayTemplate(
        id: 'point_right',
        name: 'Right-Hand Point',
        description: 'Point diverging right',
        category: TemplateCategory.points,
        icon: Icons.call_split,
        properties: {
          'type': 'point',
          'direction': 'right',
        },
      ),

      // Track sections
      const RailwayTemplate(
        id: 'track_straight_100',
        name: 'Straight Track (100m)',
        description: '100 meter straight section',
        category: TemplateCategory.tracks,
        icon: Icons.straighten,
        properties: {
          'type': 'track',
          'length': 100,
          'shape': 'straight',
        },
      ),
      const RailwayTemplate(
        id: 'track_straight_200',
        name: 'Straight Track (200m)',
        description: '200 meter straight section',
        category: TemplateCategory.tracks,
        icon: Icons.straighten,
        properties: {
          'type': 'track',
          'length': 200,
          'shape': 'straight',
        },
      ),

      // Platforms
      const RailwayTemplate(
        id: 'platform_200',
        name: 'Platform (200m)',
        description: 'Standard platform 200m',
        category: TemplateCategory.platforms,
        icon: Icons.train_outlined,
        properties: {
          'type': 'platform',
          'length': 200,
        },
      ),
      const RailwayTemplate(
        id: 'platform_400',
        name: 'Platform (400m)',
        description: 'Extended platform 400m',
        category: TemplateCategory.platforms,
        icon: Icons.train_outlined,
        properties: {
          'type': 'platform',
          'length': 400,
        },
      ),

      // Crossovers
      const RailwayTemplate(
        id: 'crossover_single',
        name: 'Single Crossover',
        description: '45° single crossover',
        category: TemplateCategory.crossovers,
        icon: Icons.alt_route,
        properties: {
          'type': 'crossover',
          'style': 'single',
          'angle': 45,
        },
      ),
      const RailwayTemplate(
        id: 'crossover_double_diamond',
        name: 'Double Diamond',
        description: '45°/135° double crossover',
        category: TemplateCategory.crossovers,
        icon: Icons.alt_route,
        properties: {
          'type': 'crossover',
          'style': 'double_diamond',
          'angles': [45, 135],
        },
      ),

      // Station templates
      const RailwayTemplate(
        id: 'station_terminus',
        name: 'Terminus Station',
        description: 'End-of-line terminus',
        category: TemplateCategory.stations,
        icon: Icons.apartment,
        properties: {
          'type': 'station',
          'style': 'terminus',
          'platforms': 2,
        },
      ),
      const RailwayTemplate(
        id: 'station_through',
        name: 'Through Station',
        description: 'Standard through station',
        category: TemplateCategory.stations,
        icon: Icons.apartment,
        properties: {
          'type': 'station',
          'style': 'through',
          'platforms': 2,
        },
      ),
    ];
  }

  static List<RailwayTemplate> filterByCategory(TemplateCategory category) {
    return getStandardTemplates()
        .where((template) => template.category == category)
        .toList();
  }

  static RailwayTemplate? getTemplateById(String id) {
    try {
      return getStandardTemplates().firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }
}

/// Snap-to-grid utility for positioning elements
class SnapToGrid {
  final double gridSize;

  const SnapToGrid({this.gridSize = 50.0});

  /// Snap a point to the nearest grid intersection
  Offset snap(Offset point) {
    final x = (point.dx / gridSize).round() * gridSize;
    final y = (point.dy / gridSize).round() * gridSize;
    return Offset(x, y);
  }

  /// Snap X coordinate only
  double snapX(double x) {
    return (x / gridSize).round() * gridSize;
  }

  /// Snap Y coordinate only
  double snapY(double y) {
    return (y / gridSize).round() * gridSize;
  }

  /// Check if two elements are close enough to connect (within 1 grid unit)
  bool canConnect(Offset point1, Offset point2) {
    final snapped1 = snap(point1);
    final snapped2 = snap(point2);
    return (snapped1 - snapped2).distance <= gridSize;
  }

  /// Get nearby connection points
  List<Offset> getNearbyConnectionPoints(Offset point, {int radius = 1}) {
    final snapped = snap(point);
    final points = <Offset>[];

    for (var dx = -radius; dx <= radius; dx++) {
      for (var dy = -radius; dy <= radius; dy++) {
        if (dx == 0 && dy == 0) continue;
        points.add(Offset(
          snapped.dx + dx * gridSize,
          snapped.dy + dy * gridSize,
        ));
      }
    }

    return points;
  }
}
