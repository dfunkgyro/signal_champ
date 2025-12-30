import 'dart:convert';
import 'package:xml/xml.dart';
import 'package:rail_champ/controllers/terminal_station_controller.dart';
import 'package:rail_champ/screens/terminal_station_models.dart';

/// Service for exporting and importing railway layouts to/from XML
class LayoutXMLService {
  /// Export the current layout to XML
  static String exportToXML(TerminalStationController controller) {
    final builder = XmlBuilder();

    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('RailwayLayout', nest: () {
      // Metadata
      builder.element('Metadata', nest: () {
        builder.element('ExportDate',
            nest: DateTime.now().toIso8601String());
        builder.element('Version', nest: '1.0');
      });

      // Signals
      builder.element('Signals', nest: () {
        for (final signal in controller.signals.values) {
          builder.element('Signal', nest: () {
            builder.attribute('id', signal.id);
            builder.attribute('x', signal.x.toString());
            builder.attribute('y', signal.y.toString());
            builder.attribute('direction', signal.direction.name);
            builder.attribute('state', signal.state.name);

            if (signal.junctionId != null) {
              builder.attribute('junctionId', signal.junctionId!);
              builder.attribute('junctionPosition', signal.junctionPosition.name);
            }

            // Routes
            if (signal.routes.isNotEmpty) {
              builder.element('Routes', nest: () {
                for (final route in signal.routes) {
                  builder.element('Route', nest: () {
                    builder.attribute('id', route.id);
                    builder.attribute('name', route.name);

                    // Required blocks
                    if (route.requiredBlocks.isNotEmpty) {
                      builder.element('RequiredBlocks',
                          nest: route.requiredBlocks.join(','));
                    }

                    // Points
                    if (route.pointPositions.isNotEmpty) {
                      builder.element('PointPositions', nest: () {
                        route.pointPositions.forEach((pointId, position) {
                          builder.element('Point', nest: () {
                            builder.attribute('id', pointId);
                            builder.attribute('position', position.name);
                          });
                        });
                      });
                    }
                  });
                }
              });
            }
          });
        }
      });

      // Points
      builder.element('Points', nest: () {
        for (final point in controller.points.values) {
          builder.element('Point', nest: () {
            builder.attribute('id', point.id);
            builder.attribute('x', point.x.toString());
            builder.attribute('y', point.y.toString());
            builder.attribute('currentPosition', point.currentPosition.name);
            builder.attribute('normalPosition', point.normalPosition.name);
            builder.attribute('isLocked', point.isLocked.toString());

            if (point.junctionId != null) {
              builder.attribute('junctionId', point.junctionId!);
            }

            // Connections
            if (point.normalConnection != null) {
              builder.attribute('normalConnection', point.normalConnection!);
            }
            if (point.reverseConnection != null) {
              builder.attribute('reverseConnection', point.reverseConnection!);
            }
          });
        }
      });

      // Blocks
      builder.element('Blocks', nest: () {
        for (final block in controller.blockSections.values) {
          builder.element('Block', nest: () {
            builder.attribute('id', block.id);
            builder.attribute('x', block.x.toString());
            builder.attribute('y', block.y.toString());
            builder.attribute('length', block.length.toString());
            builder.attribute('state', block.state.name);

            if (block.primaryDirection != null) {
              builder.attribute('primaryDirection', block.primaryDirection!.name);
            }
            builder.attribute('isBidirectional', block.isBidirectional.toString());

            // Connected blocks
            if (block.connectedBlocks.isNotEmpty) {
              builder.element('ConnectedBlocks',
                  nest: block.connectedBlocks.join(','));
            }
          });
        }
      });

      // Axle Counters
      builder.element('AxleCounters', nest: () {
        for (final ac in controller.axleCounters.values) {
          builder.element('AxleCounter', nest: () {
            builder.attribute('id', ac.id);
            builder.attribute('blockId', ac.blockId);
            builder.attribute('x', ac.x.toString());
            builder.attribute('y', ac.y.toString());
            builder.attribute('isTwin', ac.isTwin.toString());
            builder.attribute('flipped', ac.flipped.toString());

            if (ac.twinLabel != null) {
              builder.attribute('twinLabel', ac.twinLabel!);
            }
          });
        }
      });
    });

    final document = builder.buildDocument();
    return document.toXmlString(pretty: true, indent: '  ');
  }

  /// Import a layout from XML
  static void importFromXML(String xmlString, TerminalStationController controller) {
    try {
      final document = XmlDocument.parse(xmlString);
      final root = document.findElements('RailwayLayout').first;

      // Import Signals
      final signalsElement = root.findElements('Signals').firstOrNull;
      if (signalsElement != null) {
        for (final signalElement in signalsElement.findElements('Signal')) {
          final id = signalElement.getAttribute('id')!;
          final x = double.parse(signalElement.getAttribute('x')!);
          final y = double.parse(signalElement.getAttribute('y')!);
          final directionStr = signalElement.getAttribute('direction')!;

          final signal = controller.signals[id];
          if (signal != null) {
            signal.x = x;
            signal.y = y;
            signal.direction = SignalDirection.values.firstWhere(
              (d) => d.name == directionStr,
              orElse: () => signal.direction,
            );

            // Import routes if present
            // (This would require more complex logic to update routes)
          }
        }
      }

      // Import Points
      final pointsElement = root.findElements('Points').firstOrNull;
      if (pointsElement != null) {
        for (final pointElement in pointsElement.findElements('Point')) {
          final id = pointElement.getAttribute('id')!;
          final x = double.parse(pointElement.getAttribute('x')!);
          final y = double.parse(pointElement.getAttribute('y')!);

          final point = controller.points[id];
          if (point != null) {
            point.x = x;
            point.y = y;
          }
        }
      }

      // Import Blocks
      final blocksElement = root.findElements('Blocks').firstOrNull;
      if (blocksElement != null) {
        for (final blockElement in blocksElement.findElements('Block')) {
          final id = blockElement.getAttribute('id')!;
          final x = double.parse(blockElement.getAttribute('x')!);
          final y = double.parse(blockElement.getAttribute('y')!);
          final lengthAttr = blockElement.getAttribute('length');

          final block = controller.blockSections[id];
          if (block != null) {
            block.startX = x;
            if (lengthAttr != null) {
              final length = double.parse(lengthAttr);
              block.endX = x + length;
            }
            block.y = y;
          }
        }
      }

      // Import Axle Counters
      final axleCountersElement = root.findElements('AxleCounters').firstOrNull;
      if (axleCountersElement != null) {
        for (final acElement in axleCountersElement.findElements('AxleCounter')) {
          final id = acElement.getAttribute('id')!;
          final x = double.parse(acElement.getAttribute('x')!);
          final y = double.parse(acElement.getAttribute('y')!);

          final ac = controller.axleCounters[id];
          if (ac != null) {
            ac.x = x;
            ac.y = y;
          }
        }
      }

      controller.notifyListeners();
    } catch (e) {
      throw Exception('Failed to import XML: $e');
    }
  }

  /// Export only modified components (for change tracking)
  static String exportChanges(
    TerminalStationController controller,
    Map<String, dynamic> originalSnapshot,
  ) {
    // This would compare the current state with the original snapshot
    // and export only the differences
    // For now, just export everything
    return exportToXML(controller);
  }

  /// Validate XML before importing
  static bool validateXML(String xmlString) {
    try {
      final document = XmlDocument.parse(xmlString);
      final root = document.findElements('RailwayLayout');
      return root.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
