import 'package:flutter/material.dart';

import '../models/railway_model.dart' as railway;

class SvgGenerator {
  static String generateSvg(
    railway.RailwayData data, {
    bool showGrid = true,
    List<railway.Measurement> measurements = const [],
    List<railway.TextAnnotation> textAnnotations = const [],
    bool isMeasuring = false,
    Offset? measureStart,
    Offset? measureEnd,
  }) {
    try {
      final buffer = StringBuffer();

      const double width = 1600;
      const double height = 800;

      buffer.write(
          '<svg width="$width" height="$height" viewBox="0 0 $width $height" '
          'xmlns="http://www.w3.org/2000/svg">');

      buffer.write('<rect width="100%" height="100%" fill="white"/>');

      if (showGrid) {
        buffer.write(_generateGrid());
      }

      buffer.write(_generateBlocks(data.blocks));
      buffer.write(_generatePoints(data.points));
      buffer.write(_generateSignals(data.signals));
      buffer.write(_generatePlatforms(data.platforms));

      for (final measurement in measurements) {
        buffer.write(_generateMeasurement(measurement));
      }

      if (isMeasuring && measureStart != null && measureEnd != null) {
        buffer.write(_generateTemporaryMeasurement(measureStart, measureEnd));
      }

      for (final textAnnotation in textAnnotations) {
        buffer.write(_generateTextAnnotation(textAnnotation));
      }

      buffer.write('</svg>');

      return buffer.toString();
    } catch (e) {
      return _generateErrorSvg('SVG Generation Error: $e');
    }
  }

  static String _generateGrid() {
    final buffer = StringBuffer();
    buffer.write('<g stroke="#e0e0e0" stroke-width="1" opacity="0.5">');

    for (int x = 0; x <= 1600; x += 100) {
      buffer.write('<line x1="$x" y1="0" x2="$x" y2="800"/>');
    }
    for (int y = 0; y <= 800; y += 100) {
      buffer.write('<line x1="0" y1="$y" x2="1600" y2="$y"/>');
    }

    buffer.write('</g>');
    return buffer.toString();
  }

  static String _generateBlocks(List<railway.Block> blocks) {
    if (blocks.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.write('<g class="blocks">');

    for (final block in blocks) {
      final color = block.occupied ? '#ff4444' : '#0066cc';
      final strokeWidth = block.type == railway.BlockType.station ? '10' : '6';

      String pathData = '';
      switch (block.type) {
        case railway.BlockType.straight:
          pathData = 'M ${block.startX} ${block.y} L ${block.endX} ${block.y}';
          break;
        case railway.BlockType.curve:
          final controlX = (block.startX + block.endX) / 2;
          final controlY = block.y - 50;
          pathData =
              'M ${block.startX} ${block.y} Q $controlX $controlY ${block.endX} ${block.y}';
          break;
        case railway.BlockType.crossover:
          pathData = 'M ${block.startX} ${block.y} L ${block.endX} ${block.y}';
          break;
        case railway.BlockType.switchLeft:
          pathData = 'M ${block.startX} ${block.y} L ${block.endX} ${block.y}';
          break;
        case railway.BlockType.switchRight:
          pathData = 'M ${block.startX} ${block.y} L ${block.endX} ${block.y}';
          break;
        case railway.BlockType.station:
          pathData = 'M ${block.startX} ${block.y} L ${block.endX} ${block.y}';
          break;
        case railway.BlockType.end:
          pathData = 'M ${block.startX} ${block.y} L ${block.endX} ${block.y}';
          break;
      }

      buffer.write(
          '<path d="$pathData" stroke="$color" stroke-width="$strokeWidth" '
          'stroke-linecap="round" fill="none"/>');

      if (block.type == railway.BlockType.station) {
        buffer.write('<rect x="${block.centerX - 20}" y="${block.y - 15}" '
            'width="40" height="30" fill="#ffcc00" opacity="0.3" '
            'stroke="#cc9900" stroke-width="2"/>');
      }

      if (block.type == railway.BlockType.end) {
        buffer.write('<rect x="${block.endX - 10}" y="${block.y - 15}" '
            'width="10" height="30" fill="#666666" stroke="#333333" stroke-width="2"/>');
      }

      buffer.write('<text x="${block.centerX}" y="${block.y - 20}" '
          'text-anchor="middle" font-family="Arial" font-size="12" fill="#333" '
          'font-weight="bold">${block.id}</text>');
    }

    buffer.write('</g>');
    return buffer.toString();
  }

  static String _generatePoints(List<railway.Point> points) {
    if (points.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.write('<g class="points">');

    for (final point in points) {
      final color = point.locked ? '#ff6600' : '#00aa00';
      buffer.write('<circle cx="${point.x}" cy="${point.y}" r="8" '
          'fill="$color" stroke="#333" stroke-width="2"/>');

      buffer.write('<text x="${point.x}" y="${point.y + 20}" '
          'text-anchor="middle" font-family="Arial" font-size="10" fill="#333">'
          '${point.id}</text>');
    }

    buffer.write('</g>');
    return buffer.toString();
  }

  static String _generateSignals(List<railway.Signal> signals) {
    if (signals.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.write('<g class="signals">');

    for (final signal in signals) {
      String aspectColor = '#ff0000';
      switch (signal.aspect) {
        case 'green':
          aspectColor = '#00ff00';
          break;
        case 'yellow':
          aspectColor = '#ffff00';
          break;
        case 'double_yellow':
          aspectColor = '#ffff00';
          break;
        case 'red':
        default:
          aspectColor = '#ff0000';
      }

      buffer.write('<line x1="${signal.x}" y1="${signal.y}" '
          'x2="${signal.x}" y2="${signal.y - 40}" '
          'stroke="#333" stroke-width="3"/>');

      buffer.write('<circle cx="${signal.x}" cy="${signal.y - 30}" r="6" '
          'fill="$aspectColor" stroke="#333" stroke-width="2"/>');

      if (signal.aspect == 'double_yellow') {
        buffer.write('<circle cx="${signal.x}" cy="${signal.y - 45}" r="4" '
            'fill="#ffff00" stroke="#333" stroke-width="1"/>');
      }

      buffer.write('<text x="${signal.x}" y="${signal.y + 15}" '
          'text-anchor="middle" font-family="Arial" font-size="10" fill="#333">'
          '${signal.id}</text>');
    }

    buffer.write('</g>');
    return buffer.toString();
  }

  static String _generatePlatforms(List<railway.Platform> platforms) {
    if (platforms.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.write('<g class="platforms">');

    for (final platform in platforms) {
      final color = platform.occupied ? '#ff6666' : '#66aaff';
      buffer.write('<rect x="${platform.startX}" y="${platform.y - 12}" '
          'width="${platform.endX - platform.startX}" height="24" '
          'fill="$color" opacity="0.3" stroke="#3366cc" stroke-width="2"/>');

      buffer.write(
          '<text x="${(platform.startX + platform.endX) / 2}" y="${platform.y}" '
          'text-anchor="middle" font-family="Arial" font-size="11" fill="#333" '
          'font-weight="bold">${platform.name}</text>');
    }

    buffer.write('</g>');
    return buffer.toString();
  }

  static String _generateMeasurement(railway.Measurement measurement) {
    final distance = measurement.distance.toStringAsFixed(1);
    return '''
<g class="measurement">
  <line x1="${measurement.start.dx}" y1="${measurement.start.dy}" 
        x2="${measurement.end.dx}" y2="${measurement.end.dy}" 
        stroke="green" stroke-width="2" stroke-dasharray="5,5"/>
  <circle cx="${measurement.start.dx}" cy="${measurement.start.dy}" r="3" fill="green"/>
  <circle cx="${measurement.end.dx}" cy="${measurement.end.dy}" r="3" fill="green"/>
  <rect x="${(measurement.start.dx + measurement.end.dx) / 2 - 30}" 
        y="${(measurement.start.dy + measurement.end.dy) / 2 - 10}" 
        width="60" height="20" fill="white" opacity="0.8" stroke="green" stroke-width="1"/>
  <text x="${(measurement.start.dx + measurement.end.dx) / 2}" 
        y="${(measurement.start.dy + measurement.end.dy) / 2 + 5}" 
        text-anchor="middle" font-family="Arial" font-size="12" 
        fill="green" font-weight="bold">${distance}u</text>
</g>
''';
  }

  static String _generateTemporaryMeasurement(Offset start, Offset end) {
    final distance = (start - end).distance.toStringAsFixed(1);
    return '''
<g class="temporary-measurement">
  <line x1="${start.dx}" y1="${start.dy}" 
        x2="${end.dx}" y2="${end.dy}" 
        stroke="blue" stroke-width="2" stroke-dasharray="5,5"/>
  <circle cx="${start.dx}" cy="${start.dy}" r="3" fill="blue"/>
  <circle cx="${end.dx}" cy="${end.dy}" r="3" fill="blue"/>
  <rect x="${(start.dx + end.dx) / 2 - 30}" 
        y="${(start.dy + end.dy) / 2 - 10}" 
        width="60" height="20" fill="white" opacity="0.8" stroke="blue" stroke-width="1"/>
  <text x="${(start.dx + end.dx) / 2}" 
        y="${(start.dy + end.dy) / 2 + 5}" 
        text-anchor="middle" font-family="Arial" font-size="12" 
        fill="blue" font-weight="bold">${distance}u</text>
</g>
''';
  }

  static String _generateTextAnnotation(railway.TextAnnotation annotation) {
    return '''
<g class="text-annotation">
  <rect x="${annotation.position.dx - 50}" y="${annotation.position.dy - 15}" 
        width="100" height="30" fill="white" opacity="0.9" 
        stroke="purple" stroke-width="1" rx="4"/>
  <text x="${annotation.position.dx}" y="${annotation.position.dy + 5}" 
        text-anchor="middle" font-family="Arial" font-size="${annotation.fontSize}" 
        fill="${_colorToHex(annotation.color)}" font-weight="normal">
        ${annotation.text}
  </text>
</g>
''';
  }

  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  static String _generateErrorSvg(String error) {
    return '''
<svg width="400" height="200" viewBox="0 0 400 200" xmlns="http://www.w3.org/2000/svg">
  <rect width="400" height="200" fill="#ffebee" rx="8"/>
  <text x="200" y="80" text-anchor="middle" font-family="Arial" font-size="16" fill="#d32f2f" font-weight="bold">
    SVG Generation Error
  </text>
  <text x="200" y="110" text-anchor="middle" font-family="Arial" font-size="12" fill="#d32f2f">
    $error
  </text>
  <text x="200" y="140" text-anchor="middle" font-family="Arial" font-size="12" fill="#666">
    Check console for details
  </text>
</svg>
''';
  }
}
