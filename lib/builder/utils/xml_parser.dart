import 'package:xml/xml.dart';
import '../models/railway_model.dart';

class XmlParser {
  static RailwayData parseRailwayData(String xmlString) {
    try {
      final document = XmlDocument.parse(xmlString);

      final blocks = _parseBlocks(document);
      final points = _parsePoints(document);
      final signals = _parseSignals(document);
      final platforms = _parsePlatforms(document);

      return RailwayData(
        blocks: blocks,
        points: points,
        signals: signals,
        platforms: platforms,
      );
    } catch (e) {
      throw Exception('Failed to parse XML: $e');
    }
  }

  static List<Block> _parseBlocks(XmlDocument document) {
    final blockElements = document.findAllElements('Block');
    return blockElements.map((element) {
      final id = element.getAttribute('id') ?? '';
      final type = _determineBlockType(id, element);

      return Block(
        id: id,
        startX: double.parse(element.getAttribute('startX') ?? '0'),
        endX: double.parse(element.getAttribute('endX') ?? '0'),
        y: double.parse(element.getAttribute('y') ?? '0'),
        occupied: (element.getAttribute('occupied') ?? 'false') == 'true',
        occupyingTrain: element.getAttribute('occupyingTrain') ?? 'none',
        type: type,
      );
    }).toList();
  }

  static BlockType _determineBlockType(String id, XmlElement element) {
    if (id.contains('crossover')) {
      return BlockType.crossover;
    } else if (id.contains('switch')) {
      return BlockType.switchLeft; // Default to left switch
    } else if (id.contains('curve')) {
      return BlockType.curve;
    } else if (id.contains('station')) {
      return BlockType.station;
    }
    return BlockType.straight;
  }

  static List<Point> _parsePoints(XmlDocument document) {
    final pointElements = document.findAllElements('Point');
    return pointElements.map((element) {
      return Point(
        id: element.getAttribute('id') ?? '',
        x: double.parse(element.getAttribute('x') ?? '0'),
        y: double.parse(element.getAttribute('y') ?? '0'),
        position: element.getAttribute('position') ?? 'normal',
        locked: (element.getAttribute('locked') ?? 'false') == 'true',
      );
    }).toList();
  }

  static List<Signal> _parseSignals(XmlDocument document) {
    final signalElements = document.findAllElements('Signal');
    return signalElements.map((signalElement) {
      final routes = signalElement.findElements('Route').map((routeElement) {
        return Route(
          id: routeElement.getAttribute('id') ?? '',
          name: routeElement.getElement('name')?.innerText ?? '',
          requiredBlocks:
              _parseBlockList(routeElement.getElement('RequiredBlocks')),
          pathBlocks: _parseBlockList(routeElement.getElement('PathBlocks')),
          conflictingRoutes:
              _parseBlockList(routeElement.getElement('ConflictingRoutes')),
          startSignal: signalElement.getAttribute('id') ?? '',
          endSignal: '',
        );
      }).toList();

      return Signal(
        id: signalElement.getAttribute('id') ?? '',
        x: double.parse(signalElement.getAttribute('x') ?? '0'),
        y: double.parse(signalElement.getAttribute('y') ?? '0'),
        aspect: signalElement.getAttribute('aspect') ?? 'red',
        state: signalElement.getAttribute('state') ?? 'unset',
        routes: routes,
      );
    }).toList();
  }

  static List<String> _parseBlockList(XmlElement? element) {
    if (element == null) return [];
    final text = element.innerText;
    return text
        .split(',')
        .map((block) => block.trim())
        .where((block) => block.isNotEmpty)
        .toList();
  }

  static List<Platform> _parsePlatforms(XmlDocument document) {
    final platformElements = document.findAllElements('Platform');
    return platformElements.map((element) {
      return Platform(
        id: element.getAttribute('id') ?? '',
        name: element.getAttribute('name') ?? '',
        startX: double.parse(element.getAttribute('startX') ?? '0'),
        endX: double.parse(element.getAttribute('endX') ?? '0'),
        y: double.parse(element.getAttribute('y') ?? '0'),
        occupied: (element.getAttribute('occupied') ?? 'false') == 'true',
      );
    }).toList();
  }
}
