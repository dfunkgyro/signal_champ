import 'package:flutter/material.dart';

class Block {
  String id;
  double startX;
  double endX;
  double y;
  bool occupied;
  String occupyingTrain;
  BlockType type;

  Block({
    required this.id,
    required this.startX,
    required this.endX,
    required this.y,
    required this.occupied,
    required this.occupyingTrain,
    this.type = BlockType.straight,
  });

  double get length => (endX - startX).abs();
  double get centerX => (startX + endX) / 2;

  Block copyWith({
    String? id,
    double? startX,
    double? endX,
    double? y,
    bool? occupied,
    String? occupyingTrain,
    BlockType? type,
  }) {
    return Block(
      id: id ?? this.id,
      startX: startX ?? this.startX,
      endX: endX ?? this.endX,
      y: y ?? this.y,
      occupied: occupied ?? this.occupied,
      occupyingTrain: occupyingTrain ?? this.occupyingTrain,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startX': startX,
      'endX': endX,
      'y': y,
      'occupied': occupied,
      'occupyingTrain': occupyingTrain,
      'type': type.toString().split('.').last,
    };
  }

  factory Block.fromJson(Map<String, dynamic> json) {
    return Block(
      id: json['id'],
      startX: (json['startX'] as num).toDouble(),
      endX: (json['endX'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      occupied: json['occupied'],
      occupyingTrain: json['occupyingTrain'],
      type: BlockType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => BlockType.straight,
      ),
    );
  }
}

class Point {
  String id;
  double x;
  double y;
  String position;
  bool locked;
  List<String> connectedBlocks;

  Point({
    required this.id,
    required this.x,
    required this.y,
    required this.position,
    required this.locked,
    this.connectedBlocks = const [],
  });

  Point copyWith({
    String? id,
    double? x,
    double? y,
    String? position,
    bool? locked,
    List<String>? connectedBlocks,
  }) {
    return Point(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      position: position ?? this.position,
      locked: locked ?? this.locked,
      connectedBlocks: connectedBlocks ?? this.connectedBlocks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': x,
      'y': y,
      'position': position,
      'locked': locked,
      'connectedBlocks': connectedBlocks,
    };
  }

  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      id: json['id'],
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      position: json['position'],
      locked: json['locked'],
      connectedBlocks: List<String>.from(json['connectedBlocks'] ?? []),
    );
  }
}

class Route {
  String id;
  String name;
  List<String> requiredBlocks;
  List<String> pathBlocks;
  List<String> conflictingRoutes;
  String startSignal;
  String endSignal;

  Route({
    required this.id,
    required this.name,
    required this.requiredBlocks,
    required this.pathBlocks,
    required this.conflictingRoutes,
    required this.startSignal,
    required this.endSignal,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'requiredBlocks': requiredBlocks,
      'pathBlocks': pathBlocks,
      'conflictingRoutes': conflictingRoutes,
      'startSignal': startSignal,
      'endSignal': endSignal,
    };
  }

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
      id: json['id'],
      name: json['name'],
      requiredBlocks: List<String>.from(json['requiredBlocks'] ?? []),
      pathBlocks: List<String>.from(json['pathBlocks'] ?? []),
      conflictingRoutes: List<String>.from(json['conflictingRoutes'] ?? []),
      startSignal: json['startSignal'] ?? '',
      endSignal: json['endSignal'] ?? '',
    );
  }
}

class Signal {
  String id;
  double x;
  double y;
  String aspect;
  String state;
  List<Route> routes;
  String direction;
  String type;

  Signal({
    required this.id,
    required this.x,
    required this.y,
    required this.aspect,
    required this.state,
    required this.routes,
    this.direction = 'left',
    this.type = 'main',
  });

  Signal copyWith({
    String? id,
    double? x,
    double? y,
    String? aspect,
    String? state,
    List<Route>? routes,
    String? direction,
    String? type,
  }) {
    return Signal(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      aspect: aspect ?? this.aspect,
      state: state ?? this.state,
      routes: routes ?? this.routes,
      direction: direction ?? this.direction,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': x,
      'y': y,
      'aspect': aspect,
      'state': state,
      'routes': routes.map((route) => route.toJson()).toList(),
      'direction': direction,
      'type': type,
    };
  }

  factory Signal.fromJson(Map<String, dynamic> json) {
    return Signal(
      id: json['id'],
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      aspect: json['aspect'],
      state: json['state'],
      routes: (json['routes'] as List)
          .map((route) => Route.fromJson(route))
          .toList(),
      direction: json['direction'] ?? 'left',
      type: json['type'] ?? 'main',
    );
  }
}

class Platform {
  String id;
  String name;
  double startX;
  double endX;
  double y;
  bool occupied;
  String side;
  int capacity;

  Platform({
    required this.id,
    required this.name,
    required this.startX,
    required this.endX,
    required this.y,
    required this.occupied,
    this.side = 'left',
    this.capacity = 500,
  });

  double get length => (endX - startX).abs();

  Platform copyWith({
    String? id,
    String? name,
    double? startX,
    double? endX,
    double? y,
    bool? occupied,
    String? side,
    int? capacity,
  }) {
    return Platform(
      id: id ?? this.id,
      name: name ?? this.name,
      startX: startX ?? this.startX,
      endX: endX ?? this.endX,
      y: y ?? this.y,
      occupied: occupied ?? this.occupied,
      side: side ?? this.side,
      capacity: capacity ?? this.capacity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startX': startX,
      'endX': endX,
      'y': y,
      'occupied': occupied,
      'side': side,
      'capacity': capacity,
    };
  }

  factory Platform.fromJson(Map<String, dynamic> json) {
    return Platform(
      id: json['id'],
      name: json['name'],
      startX: (json['startX'] as num).toDouble(),
      endX: (json['endX'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      occupied: json['occupied'],
      side: json['side'] ?? 'left',
      capacity: json['capacity'] ?? 500,
    );
  }
}

class RailwayData {
  List<Block> blocks;
  List<Point> points;
  List<Signal> signals;
  List<Platform> platforms;

  RailwayData({
    required this.blocks,
    required this.points,
    required this.signals,
    required this.platforms,
  });

  Map<String, dynamic> toJson() {
    return {
      'blocks': blocks.map((block) => block.toJson()).toList(),
      'points': points.map((point) => point.toJson()).toList(),
      'signals': signals.map((signal) => signal.toJson()).toList(),
      'platforms': platforms.map((platform) => platform.toJson()).toList(),
    };
  }

  factory RailwayData.fromJson(Map<String, dynamic> json) {
    return RailwayData(
      blocks: (json['blocks'] as List)
          .map((block) => Block.fromJson(block))
          .toList(),
      points: (json['points'] as List)
          .map((point) => Point.fromJson(point))
          .toList(),
      signals: (json['signals'] as List)
          .map((signal) => Signal.fromJson(signal))
          .toList(),
      platforms: (json['platforms'] as List)
          .map((platform) => Platform.fromJson(platform))
          .toList(),
    );
  }

  RailwayData copyWith({
    List<Block>? blocks,
    List<Point>? points,
    List<Signal>? signals,
    List<Platform>? platforms,
  }) {
    return RailwayData(
      blocks: blocks ?? this.blocks,
      points: points ?? this.points,
      signals: signals ?? this.signals,
      platforms: platforms ?? this.platforms,
    );
  }
}

enum BlockType {
  straight,
  crossover,
  curve,
  switchLeft,
  switchRight,
  station,
  end,
}

enum ToolMode {
  select,
  block,
  point,
  signal,
  platform,
  route,
  delete,
  text,
  measure,
}

class Selection {
  dynamic element;
  String type;

  Selection({required this.element, required this.type});
}

class DraggableTool {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final ToolMode toolMode;
  final BlockType? blockType;

  const DraggableTool({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.toolMode,
    this.blockType,
  });
}

class ToolThumbnails {
  static final List<DraggableTool> tools = [
    const DraggableTool(
      id: 'select',
      label: 'Select',
      icon: Icons.select_all,
      color: Colors.blue,
      toolMode: ToolMode.select,
    ),
    const DraggableTool(
      id: 'delete',
      label: 'Delete',
      icon: Icons.delete_outline,
      color: Colors.red,
      toolMode: ToolMode.delete,
    ),
    const DraggableTool(
      id: 'measure',
      label: 'Measure',
      icon: Icons.straighten,
      color: Colors.orange,
      toolMode: ToolMode.measure,
    ),
    const DraggableTool(
      id: 'text',
      label: 'Text',
      icon: Icons.text_fields,
      color: Colors.purple,
      toolMode: ToolMode.text,
    ),
    const DraggableTool(
      id: 'straight',
      label: 'Straight\nTrack',
      icon: Icons.straight,
      color: Colors.green,
      toolMode: ToolMode.block,
      blockType: BlockType.straight,
    ),
    const DraggableTool(
      id: 'crossover',
      label: 'Crossover',
      icon: Icons.change_circle,
      color: Colors.orange,
      toolMode: ToolMode.block,
      blockType: BlockType.crossover,
    ),
    const DraggableTool(
      id: 'curve',
      label: 'Curve',
      icon: Icons.arrow_circle_up_outlined,
      color: Colors.teal,
      toolMode: ToolMode.block,
      blockType: BlockType.curve,
    ),
    const DraggableTool(
      id: 'switch_left',
      label: 'Switch\nLeft',
      icon: Icons.switch_left,
      color: Colors.purple,
      toolMode: ToolMode.block,
      blockType: BlockType.switchLeft,
    ),
    const DraggableTool(
      id: 'switch_right',
      label: 'Switch\nRight',
      icon: Icons.switch_right,
      color: Colors.deepPurple,
      toolMode: ToolMode.block,
      blockType: BlockType.switchRight,
    ),
    const DraggableTool(
      id: 'station',
      label: 'Station',
      icon: Icons.directions_railway,
      color: Colors.brown,
      toolMode: ToolMode.block,
      blockType: BlockType.station,
    ),
    const DraggableTool(
      id: 'end',
      label: 'End\nBuffer',
      icon: Icons.block,
      color: Colors.grey,
      toolMode: ToolMode.block,
      blockType: BlockType.end,
    ),
    const DraggableTool(
      id: 'signal',
      label: 'Signal',
      icon: Icons.traffic,
      color: Colors.red,
      toolMode: ToolMode.signal,
    ),
    const DraggableTool(
      id: 'point',
      label: 'Point',
      icon: Icons.change_history,
      color: Colors.green,
      toolMode: ToolMode.point,
    ),
    const DraggableTool(
      id: 'platform',
      label: 'Platform',
      icon: Icons.train,
      color: Colors.blue,
      toolMode: ToolMode.platform,
    ),
    const DraggableTool(
      id: 'route',
      label: 'Route',
      icon: Icons.alt_route,
      color: Colors.purple,
      toolMode: ToolMode.route,
    ),
  ];

  static List<DraggableTool> getTrackTools() {
    return tools.where((tool) => tool.toolMode == ToolMode.block).toList();
  }

  static List<DraggableTool> getInfrastructureTools() {
    return tools
        .where((tool) =>
            tool.toolMode == ToolMode.signal ||
            tool.toolMode == ToolMode.point ||
            tool.toolMode == ToolMode.platform ||
            tool.toolMode == ToolMode.route)
        .toList();
  }

  static List<DraggableTool> getSelectionTools() {
    return tools
        .where((tool) =>
            tool.toolMode == ToolMode.select ||
            tool.toolMode == ToolMode.delete ||
            tool.toolMode == ToolMode.measure ||
            tool.toolMode == ToolMode.text)
        .toList();
  }
}

class TransformTool {
  final String id;
  final String name;
  final IconData icon;
  final TransformMode mode;

  const TransformTool({
    required this.id,
    required this.name,
    required this.icon,
    required this.mode,
  });
}

enum TransformMode {
  select,
  move,
  rotate,
  scale,
  duplicate,
  delete,
}

class GridSettings {
  final double cellSize;
  final bool enabled;
  final bool snapToGrid;
  final bool showCoordinates;
  final Color gridColor;

  const GridSettings({
    this.cellSize = 20.0,
    this.enabled = true,
    this.snapToGrid = true,
    this.showCoordinates = false,
    this.gridColor = const Color(0xFFE0E0E0),
  });

  GridSettings copyWith({
    double? cellSize,
    bool? enabled,
    bool? snapToGrid,
    bool? showCoordinates,
    Color? gridColor,
  }) {
    return GridSettings(
      cellSize: cellSize ?? this.cellSize,
      enabled: enabled ?? this.enabled,
      snapToGrid: snapToGrid ?? this.snapToGrid,
      showCoordinates: showCoordinates ?? this.showCoordinates,
      gridColor: gridColor ?? this.gridColor,
    );
  }
}

class WorkspaceTab {
  final String id;
  final String title;
  final RailwayData data;
  final bool hasUnsavedChanges;
  final String? filePath;
  final FileType fileType;
  final DateTime createdAt;
  final DateTime modifiedAt;

  WorkspaceTab({
    required this.id,
    required this.title,
    required this.data,
    this.hasUnsavedChanges = false,
    this.filePath,
    this.fileType = FileType.newFile,
    DateTime? createdAt,
    DateTime? modifiedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now();

  WorkspaceTab copyWith({
    String? title,
    RailwayData? data,
    bool? hasUnsavedChanges,
    String? filePath,
    FileType? fileType,
    DateTime? modifiedAt,
  }) {
    return WorkspaceTab(
      id: id,
      title: title ?? this.title,
      data: data ?? this.data,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? DateTime.now(),
    );
  }
}

enum FileType {
  newFile,
  xml,
  svg,
  json,
}

class ConnectionPoint {
  final String elementId;
  final String elementType;
  final double x;
  final double y;
  final ConnectionType type;

  ConnectionPoint({
    required this.elementId,
    required this.elementType,
    required this.x,
    required this.y,
    required this.type,
  });
}

enum ConnectionType {
  start,
  end,
  center,
  signal,
  point,
  platformStart,
  platformEnd,
  crossover,
}

class Measurement {
  final String id;
  final Offset start;
  final Offset end;
  final double distance;
  final DateTime timestamp;

  Measurement({
    required this.id,
    required this.start,
    required this.end,
    required this.distance,
    required this.timestamp,
  });
}

class TextAnnotation {
  final String id;
  final String text;
  final Offset position;
  final double fontSize;
  final Color color;
  final DateTime createdAt;

  TextAnnotation({
    required this.id,
    required this.text,
    required this.position,
    this.fontSize = 12,
    this.color = Colors.black,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
