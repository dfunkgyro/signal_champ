import 'package:flutter/material.dart';

/// Scenario difficulty levels
enum ScenarioDifficulty {
  beginner,
  intermediate,
  advanced,
  expert;

  String get displayName {
    switch (this) {
      case ScenarioDifficulty.beginner:
        return 'Beginner';
      case ScenarioDifficulty.intermediate:
        return 'Intermediate';
      case ScenarioDifficulty.advanced:
        return 'Advanced';
      case ScenarioDifficulty.expert:
        return 'Expert';
    }
  }

  Color get color {
    switch (this) {
      case ScenarioDifficulty.beginner:
        return Colors.green;
      case ScenarioDifficulty.intermediate:
        return Colors.blue;
      case ScenarioDifficulty.advanced:
        return Colors.orange;
      case ScenarioDifficulty.expert:
        return Colors.red;
    }
  }
}

/// Scenario categories/types
enum ScenarioCategory {
  rushHour,
  emergency,
  trackMaintenance,
  custom,
  tutorial,
  challenge;

  String get displayName {
    switch (this) {
      case ScenarioCategory.rushHour:
        return 'Rush Hour';
      case ScenarioCategory.emergency:
        return 'Emergency';
      case ScenarioCategory.trackMaintenance:
        return 'Track Maintenance';
      case ScenarioCategory.custom:
        return 'Custom';
      case ScenarioCategory.tutorial:
        return 'Tutorial';
      case ScenarioCategory.challenge:
        return 'Challenge';
    }
  }

  IconData get icon {
    switch (this) {
      case ScenarioCategory.rushHour:
        return Icons.access_time;
      case ScenarioCategory.emergency:
        return Icons.warning_amber;
      case ScenarioCategory.trackMaintenance:
        return Icons.construction;
      case ScenarioCategory.custom:
        return Icons.edit;
      case ScenarioCategory.tutorial:
        return Icons.school;
      case ScenarioCategory.challenge:
        return Icons.emoji_events;
    }
  }
}

/// Railway element type for drag-and-drop
enum RailwayElementType {
  track,
  signal,
  point,
  blockSection,
  transponder,
  wifiAntenna,
  station,
  buffer;

  String get displayName {
    switch (this) {
      case RailwayElementType.track:
        return 'Track';
      case RailwayElementType.signal:
        return 'Signal';
      case RailwayElementType.point:
        return 'Point';
      case RailwayElementType.blockSection:
        return 'Block Section';
      case RailwayElementType.transponder:
        return 'Transponder';
      case RailwayElementType.wifiAntenna:
        return 'WiFi Antenna';
      case RailwayElementType.station:
        return 'Station';
      case RailwayElementType.buffer:
        return 'Buffer';
    }
  }

  IconData get icon {
    switch (this) {
      case RailwayElementType.track:
        return Icons.linear_scale;
      case RailwayElementType.signal:
        return Icons.traffic;
      case RailwayElementType.point:
        return Icons.call_split;
      case RailwayElementType.blockSection:
        return Icons.crop_square;
      case RailwayElementType.transponder:
        return Icons.sensors;
      case RailwayElementType.wifiAntenna:
        return Icons.wifi;
      case RailwayElementType.station:
        return Icons.home;
      case RailwayElementType.buffer:
        return Icons.stop;
    }
  }
}

/// Track configuration for scenario
class ScenarioTrack {
  final String id;
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final bool isCurved;
  final double? curveRadius;

  ScenarioTrack({
    required this.id,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    this.isCurved = false,
    this.curveRadius,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'startX': startX,
        'startY': startY,
        'endX': endX,
        'endY': endY,
        'isCurved': isCurved,
        'curveRadius': curveRadius,
      };

  factory ScenarioTrack.fromJson(Map<String, dynamic> json) => ScenarioTrack(
        id: json['id'] as String,
        startX: (json['startX'] as num).toDouble(),
        startY: (json['startY'] as num).toDouble(),
        endX: (json['endX'] as num).toDouble(),
        endY: (json['endY'] as num).toDouble(),
        isCurved: json['isCurved'] as bool? ?? false,
        curveRadius: (json['curveRadius'] as num?)?.toDouble(),
      );
}

/// Signal configuration for scenario
class ScenarioSignal {
  final String id;
  final double x;
  final double y;
  final List<String> controlledBlocks;
  final List<String> requiredPointPositions;

  ScenarioSignal({
    required this.id,
    required this.x,
    required this.y,
    required this.controlledBlocks,
    required this.requiredPointPositions,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'x': x,
        'y': y,
        'controlledBlocks': controlledBlocks,
        'requiredPointPositions': requiredPointPositions,
      };

  factory ScenarioSignal.fromJson(Map<String, dynamic> json) => ScenarioSignal(
        id: json['id'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        controlledBlocks: List<String>.from(json['controlledBlocks'] as List),
        requiredPointPositions:
            List<String>.from(json['requiredPointPositions'] as List),
      );
}

/// Point/switch configuration for scenario
class ScenarioPoint {
  final String id;
  final double x;
  final double y;
  final String normalRoute;
  final String reverseRoute;

  ScenarioPoint({
    required this.id,
    required this.x,
    required this.y,
    required this.normalRoute,
    required this.reverseRoute,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'x': x,
        'y': y,
        'normalRoute': normalRoute,
        'reverseRoute': reverseRoute,
      };

  factory ScenarioPoint.fromJson(Map<String, dynamic> json) => ScenarioPoint(
        id: json['id'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        normalRoute: json['normalRoute'] as String,
        reverseRoute: json['reverseRoute'] as String,
      );
}

/// Block section configuration for scenario
class ScenarioBlockSection {
  final String id;
  final double startX;
  final double endX;
  final double y;
  final String? nextBlock;
  final String? prevBlock;
  final bool isCrossover;
  final bool isReversingArea;

  ScenarioBlockSection({
    required this.id,
    required this.startX,
    required this.endX,
    required this.y,
    this.nextBlock,
    this.prevBlock,
    this.isCrossover = false,
    this.isReversingArea = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'startX': startX,
        'endX': endX,
        'y': y,
        'nextBlock': nextBlock,
        'prevBlock': prevBlock,
        'isCrossover': isCrossover,
        'isReversingArea': isReversingArea,
      };

  factory ScenarioBlockSection.fromJson(Map<String, dynamic> json) =>
      ScenarioBlockSection(
        id: json['id'] as String,
        startX: (json['startX'] as num).toDouble(),
        endX: (json['endX'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        nextBlock: json['nextBlock'] as String?,
        prevBlock: json['prevBlock'] as String?,
        isCrossover: json['isCrossover'] as bool? ?? false,
        isReversingArea: json['isReversingArea'] as bool? ?? false,
      );
}

/// Train spawn configuration for scenario
class ScenarioTrainSpawn {
  final String id;
  final String trainType;
  final double x;
  final double y;
  final String direction;
  final int spawnDelaySeconds;
  final String? destination;

  ScenarioTrainSpawn({
    required this.id,
    required this.trainType,
    required this.x,
    required this.y,
    required this.direction,
    this.spawnDelaySeconds = 0,
    this.destination,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'trainType': trainType,
        'x': x,
        'y': y,
        'direction': direction,
        'spawnDelaySeconds': spawnDelaySeconds,
        'destination': destination,
      };

  factory ScenarioTrainSpawn.fromJson(Map<String, dynamic> json) =>
      ScenarioTrainSpawn(
        id: json['id'] as String,
        trainType: json['trainType'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        direction: json['direction'] as String,
        spawnDelaySeconds: json['spawnDelaySeconds'] as int? ?? 0,
        destination: json['destination'] as String?,
      );
}

/// Scenario objective/goal
class ScenarioObjective {
  final String id;
  final String description;
  final String type; // 'deliver', 'avoid_collision', 'time_limit', 'efficiency'
  final Map<String, dynamic> parameters;
  final int points;

  ScenarioObjective({
    required this.id,
    required this.description,
    required this.type,
    required this.parameters,
    this.points = 100,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'type': type,
        'parameters': parameters,
        'points': points,
      };

  factory ScenarioObjective.fromJson(Map<String, dynamic> json) =>
      ScenarioObjective(
        id: json['id'] as String,
        description: json['description'] as String,
        type: json['type'] as String,
        parameters: Map<String, dynamic>.from(json['parameters'] as Map),
        points: json['points'] as int? ?? 100,
      );
}

/// Complete railway scenario
class RailwayScenario {
  final String id;
  final String name;
  final String description;
  final String authorId;
  final String? authorName;
  final ScenarioCategory category;
  final ScenarioDifficulty difficulty;
  final bool isPublic;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int downloads;
  final double rating;
  final int ratingCount;

  // Layout data
  final double canvasWidth;
  final double canvasHeight;
  final List<ScenarioTrack> tracks;
  final List<ScenarioSignal> signals;
  final List<ScenarioPoint> points;
  final List<ScenarioBlockSection> blockSections;
  final List<ScenarioTrainSpawn> trainSpawns;

  // Objectives and constraints
  final List<ScenarioObjective> objectives;
  final int? timeLimit; // seconds
  final int? maxTrains;

  // Metadata
  final List<String> tags;
  final String? thumbnailUrl;
  final Map<String, dynamic>? metadata;

  RailwayScenario({
    required this.id,
    required this.name,
    required this.description,
    required this.authorId,
    this.authorName,
    required this.category,
    required this.difficulty,
    this.isPublic = false,
    this.isFeatured = false,
    required this.createdAt,
    required this.updatedAt,
    this.downloads = 0,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.canvasWidth = 7000,
    this.canvasHeight = 1200,
    this.tracks = const [],
    this.signals = const [],
    this.points = const [],
    this.blockSections = const [],
    this.trainSpawns = const [],
    this.objectives = const [],
    this.timeLimit,
    this.maxTrains,
    this.tags = const [],
    this.thumbnailUrl,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'author_id': authorId,
        'author_name': authorName,
        'category': category.name,
        'difficulty': difficulty.name,
        'is_public': isPublic,
        'is_featured': isFeatured,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'downloads': downloads,
        'rating': rating,
        'rating_count': ratingCount,
        'canvas_width': canvasWidth,
        'canvas_height': canvasHeight,
        'tracks': tracks.map((t) => t.toJson()).toList(),
        'signals': signals.map((s) => s.toJson()).toList(),
        'points': points.map((p) => p.toJson()).toList(),
        'block_sections': blockSections.map((b) => b.toJson()).toList(),
        'train_spawns': trainSpawns.map((t) => t.toJson()).toList(),
        'objectives': objectives.map((o) => o.toJson()).toList(),
        'time_limit': timeLimit,
        'max_trains': maxTrains,
        'tags': tags,
        'thumbnail_url': thumbnailUrl,
        'metadata': metadata,
      };

  factory RailwayScenario.fromJson(Map<String, dynamic> json) =>
      RailwayScenario(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        authorId: json['author_id'] as String,
        authorName: json['author_name'] as String?,
        category: ScenarioCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => ScenarioCategory.custom,
        ),
        difficulty: ScenarioDifficulty.values.firstWhere(
          (e) => e.name == json['difficulty'],
          orElse: () => ScenarioDifficulty.beginner,
        ),
        isPublic: json['is_public'] as bool? ?? false,
        isFeatured: json['is_featured'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        downloads: json['downloads'] as int? ?? 0,
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        ratingCount: json['rating_count'] as int? ?? 0,
        canvasWidth: (json['canvas_width'] as num?)?.toDouble() ?? 7000,
        canvasHeight: (json['canvas_height'] as num?)?.toDouble() ?? 1200,
        tracks: (json['tracks'] as List?)
                ?.map((t) => ScenarioTrack.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
        signals: (json['signals'] as List?)
                ?.map(
                    (s) => ScenarioSignal.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        points: (json['points'] as List?)
                ?.map((p) => ScenarioPoint.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
        blockSections: (json['block_sections'] as List?)
                ?.map((b) =>
                    ScenarioBlockSection.fromJson(b as Map<String, dynamic>))
                .toList() ??
            [],
        trainSpawns: (json['train_spawns'] as List?)
                ?.map((t) =>
                    ScenarioTrainSpawn.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
        objectives: (json['objectives'] as List?)
                ?.map((o) =>
                    ScenarioObjective.fromJson(o as Map<String, dynamic>))
                .toList() ??
            [],
        timeLimit: json['time_limit'] as int?,
        maxTrains: json['max_trains'] as int?,
        tags: (json['tags'] as List?)?.cast<String>() ?? [],
        thumbnailUrl: json['thumbnail_url'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );

  RailwayScenario copyWith({
    String? id,
    String? name,
    String? description,
    String? authorId,
    String? authorName,
    ScenarioCategory? category,
    ScenarioDifficulty? difficulty,
    bool? isPublic,
    bool? isFeatured,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? downloads,
    double? rating,
    int? ratingCount,
    double? canvasWidth,
    double? canvasHeight,
    List<ScenarioTrack>? tracks,
    List<ScenarioSignal>? signals,
    List<ScenarioPoint>? points,
    List<ScenarioBlockSection>? blockSections,
    List<ScenarioTrainSpawn>? trainSpawns,
    List<ScenarioObjective>? objectives,
    int? timeLimit,
    int? maxTrains,
    List<String>? tags,
    String? thumbnailUrl,
    Map<String, dynamic>? metadata,
  }) {
    return RailwayScenario(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      isPublic: isPublic ?? this.isPublic,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      downloads: downloads ?? this.downloads,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      canvasWidth: canvasWidth ?? this.canvasWidth,
      canvasHeight: canvasHeight ?? this.canvasHeight,
      tracks: tracks ?? this.tracks,
      signals: signals ?? this.signals,
      points: points ?? this.points,
      blockSections: blockSections ?? this.blockSections,
      trainSpawns: trainSpawns ?? this.trainSpawns,
      objectives: objectives ?? this.objectives,
      timeLimit: timeLimit ?? this.timeLimit,
      maxTrains: maxTrains ?? this.maxTrains,
      tags: tags ?? this.tags,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      metadata: metadata ?? this.metadata,
    );
  }
}
