import '../models/railway_model.dart';

class XmlGenerator {
  static String generateXml(RailwayData data) {
    final buffer = StringBuffer();

    buffer.write('<?xml version="1.0" encoding="UTF-8"?>\n');
    buffer.write('<RailwayData>\n');

    // Write Blocks
    buffer.write('  <Blocks>\n');
    for (final block in data.blocks) {
      buffer.write('    <Block id="${block.id}" '
          'startX="${block.startX}" '
          'endX="${block.endX}" '
          'y="${block.y}" '
          'occupied="${block.occupied}" '
          'occupyingTrain="${block.occupyingTrain}" />\n');
    }
    buffer.write('  </Blocks>\n');

    // Write Points
    buffer.write('  <Points>\n');
    for (final point in data.points) {
      buffer.write('    <Point id="${point.id}" '
          'x="${point.x}" '
          'y="${point.y}" '
          'position="${point.position}" '
          'locked="${point.locked}" />\n');
    }
    buffer.write('  </Points>\n');

    // Write Signals
    buffer.write('  <Signals>\n');
    for (final signal in data.signals) {
      buffer.write('    <Signal id="${signal.id}" '
          'x="${signal.x}" '
          'y="${signal.y}" '
          'aspect="${signal.aspect}" '
          'state="${signal.state}">\n');

      for (final route in signal.routes) {
        buffer.write('      <Route id="${route.id}" name="${route.name}">\n');
        buffer.write(
            '        <RequiredBlocks>${route.requiredBlocks.join(", ")}</RequiredBlocks>\n');
        buffer.write(
            '        <PathBlocks>${route.pathBlocks.join(", ")}</PathBlocks>\n');
        buffer.write(
            '        <ConflictingRoutes>${route.conflictingRoutes.join(", ")}</ConflictingRoutes>\n');
        buffer.write('      </Route>\n');
      }

      buffer.write('    </Signal>\n');
    }
    buffer.write('  </Signals>\n');

    // Write Platforms
    buffer.write('  <Platforms>\n');
    for (final platform in data.platforms) {
      buffer.write('    <Platform id="${platform.id}" '
          'name="${platform.name}" '
          'startX="${platform.startX}" '
          'endX="${platform.endX}" '
          'y="${platform.y}" '
          'occupied="${platform.occupied}" />\n');
    }
    buffer.write('  </Platforms>\n');

    buffer.write('</RailwayData>');
    return buffer.toString();
  }
}
