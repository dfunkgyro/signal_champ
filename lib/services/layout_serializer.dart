import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:rail_champ/screens/terminal_station_models.dart';
import 'package:rail_champ/models/railway_model.dart' show Transponder, WifiAntenna, TransponderType;

/// Service for serializing and deserializing railway layouts to/from JSON
class LayoutSerializer {
  /// Export complete layout to JSON
  static Map<String, dynamic> exportLayoutToJson({
    required Map<String, BlockSection> blocks,
    required Map<String, Point> points,
    required Map<String, Signal> signals,
    required List<Platform> platforms,
    required Map<String, dynamic> crossovers,
    required Map<String, dynamic> axleCounters,
    required Map<String, Transponder> transponders,
    required Map<String, WifiAntenna> wifiAntennas,
    required Map<String, dynamic> bufferStops,
  }) {
    return {
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'layout': {
        'blocks': blocks.map((key, value) => MapEntry(key, {
          'id': value.id,
          'name': value.name,
          'startX': value.startX,
          'endX': value.endX,
          'y': value.y,
        })),
        'points': points.map((key, value) => MapEntry(key, {
          'id': value.id,
          'name': value.name,
          'x': value.x,
          'y': value.y,
          'position': value.position.name,
          'gapAngle': value.gapAngle,
          'crossoverId': value.crossoverId,
        })),
        'signals': signals.map((key, value) => MapEntry(key, {
          'id': value.id,
          'x': value.x,
          'y': value.y,
          'direction': value.direction.name,
          'routes': value.routes.map((route) => {
            'id': route.id,
            'name': route.name,
            'requiredBlocksClear': route.requiredBlocksClear,
            'requiredPointPositions': route.requiredPointPositions
                .map((k, v) => MapEntry(k, v.name)),
            'conflictingRoutes': route.conflictingRoutes,
            'pathBlocks': route.pathBlocks,
            'protectedBlocks': route.protectedBlocks,
          }).toList(),
        })),
        'platforms': platforms.map((platform) => {
          'id': platform.id,
          'name': platform.name,
          'startX': platform.startX,
          'endX': platform.endX,
          'y': platform.y,
          'width': platform.width,
          'height': platform.height,
        }).toList(),
        'crossovers': crossovers,
        'axleCounters': axleCounters,
        'transponders': transponders.map((key, value) => MapEntry(key, {
          'id': value.id,
          'type': value.type.name,
          'x': value.x,
          'y': value.y,
          'description': value.description,
        })),
        'wifiAntennas': wifiAntennas.map((key, value) => MapEntry(key, {
          'id': value.id,
          'x': value.x,
          'y': value.y,
          'isActive': value.isActive,
        })),
        'bufferStops': bufferStops,
      },
    };
  }

  /// Save layout to JSON file
  static Future<String> saveLayoutToFile(Map<String, dynamic> layoutJson, String filename) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      final jsonString = JsonEncoder.withIndent('  ').convert(layoutJson);
      await file.writeAsString(jsonString);
      return file.path;
    } catch (e) {
      throw Exception('Failed to save layout: $e');
    }
  }

  /// Load layout from JSON file
  static Future<Map<String, dynamic>> loadLayoutFromFile(String filepath) async {
    try {
      final file = File(filepath);
      if (!await file.exists()) {
        throw Exception('File not found: $filepath');
      }
      final jsonString = await file.readAsString();
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load layout: $e');
    }
  }

  /// Import layout from JSON and reconstruct objects
  static Map<String, dynamic> importLayoutFromJson(Map<String, dynamic> layoutJson) {
    try {
      final layout = layoutJson['layout'] as Map<String, dynamic>;

      // Reconstruct blocks
      final blocks = <String, BlockSection>{};
      (layout['blocks'] as Map<String, dynamic>).forEach((key, value) {
        final blockData = value as Map<String, dynamic>;
        blocks[key] = BlockSection(
          id: blockData['id'] as String,
          name: blockData['name'] as String?,
          startX: (blockData['startX'] as num).toDouble(),
          endX: (blockData['endX'] as num).toDouble(),
          y: (blockData['y'] as num).toDouble(),
        );
      });

      // Reconstruct points
      final points = <String, Point>{};
      (layout['points'] as Map<String, dynamic>).forEach((key, value) {
        final pointData = value as Map<String, dynamic>;
        points[key] = Point(
          id: pointData['id'] as String,
          name: pointData['name'] as String?,
          x: (pointData['x'] as num).toDouble(),
          y: (pointData['y'] as num).toDouble(),
          position: PointPosition.values.firstWhere(
            (e) => e.name == pointData['position'],
            orElse: () => PointPosition.normal,
          ),
          gapAngle: (pointData['gapAngle'] as num?)?.toDouble() ?? 15.0,
          crossoverId: pointData['crossoverId'] as String?,
        );
      });

      // Reconstruct signals
      final signals = <String, Signal>{};
      (layout['signals'] as Map<String, dynamic>).forEach((key, value) {
        final signalData = value as Map<String, dynamic>;
        final routes = (signalData['routes'] as List).map((routeData) {
          final rd = routeData as Map<String, dynamic>;
          return SignalRoute(
            id: rd['id'] as String,
            name: rd['name'] as String,
            requiredBlocksClear: List<String>.from(rd['requiredBlocksClear']),
            requiredPointPositions: (rd['requiredPointPositions'] as Map<String, dynamic>)
                .map((k, v) => MapEntry(
                  k,
                  PointPosition.values.firstWhere(
                    (e) => e.name == v,
                    orElse: () => PointPosition.normal,
                  ),
                )),
            conflictingRoutes: List<String>.from(rd['conflictingRoutes'] ?? []),
            pathBlocks: List<String>.from(rd['pathBlocks']),
            protectedBlocks: List<String>.from(rd['protectedBlocks']),
          );
        }).toList();

        signals[key] = Signal(
          id: signalData['id'] as String,
          x: (signalData['x'] as num).toDouble(),
          y: (signalData['y'] as num).toDouble(),
          direction: SignalDirection.values.firstWhere(
            (e) => e.name == signalData['direction'],
            orElse: () => SignalDirection.east,
          ),
          routes: routes,
        );
      });

      // Reconstruct platforms
      final platforms = (layout['platforms'] as List).map((platformData) {
        final pd = platformData as Map<String, dynamic>;
        return Platform(
          id: pd['id'] as String,
          name: pd['name'] as String,
          startX: (pd['startX'] as num).toDouble(),
          endX: (pd['endX'] as num).toDouble(),
          y: (pd['y'] as num).toDouble(),
          width: (pd['width'] as num?)?.toDouble() ?? 200.0,
          height: (pd['height'] as num?)?.toDouble() ?? 40.0,
        );
      }).toList();

      return {
        'blocks': blocks,
        'points': points,
        'signals': signals,
        'platforms': platforms,
        'crossovers': layout['crossovers'],
        'axleCounters': layout['axleCounters'],
        'transponders': layout['transponders'],
        'wifiAntennas': layout['wifiAntennas'],
        'bufferStops': layout['bufferStops'],
      };
    } catch (e) {
      throw Exception('Failed to import layout: $e');
    }
  }

  /// Export scenario to JSON (includes layout + trains + states)
  static Map<String, dynamic> exportScenarioToJson({
    required Map<String, dynamic> layout,
    required List<dynamic> trains,
    required Map<String, dynamic> systemState,
  }) {
    return {
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'type': 'scenario',
      'layout': layout,
      'trains': trains,
      'systemState': systemState,
    };
  }
}
