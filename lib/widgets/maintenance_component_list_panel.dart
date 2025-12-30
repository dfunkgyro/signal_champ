import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/terminal_station_controller.dart';
import '../controllers/maintenance_edit_controller.dart';
import '../screens/terminal_station_models.dart';

/// Maintenance mode left panel - lists all components with coordinates
class MaintenanceComponentListPanel extends StatefulWidget {
  final String title;

  const MaintenanceComponentListPanel({
    Key? key,
    this.title = 'Components',
  }) : super(key: key);

  @override
  State<MaintenanceComponentListPanel> createState() =>
      _MaintenanceComponentListPanelState();
}

class _MaintenanceComponentListPanelState
    extends State<MaintenanceComponentListPanel> {
  String _expandedSection = 'signals'; // Which section is expanded

  MaintenanceEditController get editController =>
      Provider.of<MaintenanceEditController>(context, listen: false);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TerminalStationController>(context);

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          right: BorderSide(color: Colors.grey[700]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              border: Border(
                bottom: BorderSide(color: Colors.grey[700]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.build_circle, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Component List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                _buildComponentSection(
                  title: 'Signals',
                  icon: Icons.traffic,
                  color: Colors.green,
                  count: controller.signals.length,
                  sectionKey: 'signals',
                  builder: () => _buildSignalsList(controller),
                ),
                const SizedBox(height: 8),
                _buildComponentSection(
                  title: 'Points',
                  icon: Icons.call_split,
                  color: Colors.blue,
                  count: controller.points.length,
                  sectionKey: 'points',
                  builder: () => _buildPointsList(controller),
                ),
                const SizedBox(height: 8),
                _buildComponentSection(
                  title: 'Blocks',
                  icon: Icons.view_module,
                  color: Colors.purple,
                  count: controller.blockSections.length,
                  sectionKey: 'blocks',
                  builder: () => _buildBlocksList(controller),
                ),
                const SizedBox(height: 8),
                _buildComponentSection(
                  title: 'Axle Counters',
                  icon: Icons.sensors,
                  color: Colors.cyan,
                  count: controller.axleCounters.length,
                  sectionKey: 'axleCounters',
                  builder: () => _buildAxleCountersList(controller),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentSection({
    required String title,
    required IconData icon,
    required Color color,
    required int count,
    required String sectionKey,
    required Widget Function() builder,
  }) {
    final isExpanded = _expandedSection == sectionKey;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedSection = isExpanded ? '' : sectionKey;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[700]!),
                ),
              ),
              child: builder(),
            ),
        ],
      ),
    );
  }

  Widget _buildSignalsList(TerminalStationController controller) {
    final signals = controller.signals.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: signals.length,
      itemBuilder: (context, index) {
        final signal = signals[index];
        return _buildComponentItem(
          id: signal.id,
          x: signal.x,
          y: signal.y,
          subtitle: 'Direction: ${signal.direction.name}',
          color: Colors.green,
          onTap: () {
            controller.selectComponent('signal', signal.id);
            editController.selectComponent('signal', signal.id);
            controller.requestCanvasCenter(Offset(signal.x, signal.y));
          },
        );
      },
    );
  }

  Widget _buildPointsList(TerminalStationController controller) {
    final points = controller.points.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: points.length,
      itemBuilder: (context, index) {
        final point = points[index];
        return _buildComponentItem(
          id: point.id,
          x: point.x,
          y: point.y,
          subtitle: 'Position: ${point.currentPosition.name}',
          color: Colors.blue,
          onTap: () {
            controller.selectComponent('point', point.id);
            editController.selectComponent('point', point.id);
            controller.requestCanvasCenter(Offset(point.x, point.y));
          },
        );
      },
    );
  }

  Widget _buildBlocksList(TerminalStationController controller) {
    final blocks = controller.blockSections.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: blocks.length,
      itemBuilder: (context, index) {
        final block = blocks[index];
        return _buildComponentItem(
          id: block.id,
          x: block.x,
          y: block.y,
          subtitle: 'State: ${block.state.name.toUpperCase()}',
          color: Colors.purple,
          onTap: () {
            controller.selectComponent('block', block.id);
            editController.selectComponent('block', block.id);
            controller.requestCanvasCenter(Offset(block.centerX, block.y));
          },
        );
      },
    );
  }

  Widget _buildAxleCountersList(TerminalStationController controller) {
    final axleCounters = controller.axleCounters.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: axleCounters.length,
      itemBuilder: (context, index) {
        final ac = axleCounters[index];
        return _buildComponentItem(
          id: ac.id,
          x: ac.x,
          y: ac.y,
          subtitle: 'Count: ${ac.count}, Block: ${ac.blockId}',
          color: Colors.cyan,
          onTap: () {
            controller.selectComponent('axleCounter', ac.id);
            editController.selectComponent('axleCounter', ac.id);
            controller.requestCanvasCenter(Offset(ac.x, ac.y));
          },
        );
      },
    );
  }

  Widget _buildComponentItem({
    required String id,
    required double x,
    required double y,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[800]!),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    id,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'X: ${x.toStringAsFixed(1)}, Y: ${y.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
