import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/graph_model.dart';
import '../providers/graph_provider.dart';

class GraphToolboxPanel extends StatelessWidget {
  const GraphToolboxPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GraphProvider>(context, listen: false);

    return Container(
      width: 220,
      color: const Color(0xFFF2F2F2),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Nodes',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                const Text(
                  'Track',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _ToolButton(
                  label: 'Block',
                  icon: Icons.straighten,
                  color: const Color(0xFF2E86AB),
                  onTap: () => provider.addNode(
                    GraphNodeType.block,
                    const Offset(300, 200),
                  ),
                ),
                _ToolButton(
                  label: 'Crossover',
                  icon: Icons.close,
                  color: const Color(0xFF4C566A),
                  onTap: () => provider.addNode(
                    GraphNodeType.crossover,
                    const Offset(320, 200),
                  ),
                ),
                _ToolButton(
                  label: 'Point',
                  icon: Icons.change_history,
                  color: const Color(0xFF2A9D8F),
                  onTap: () => provider.addNode(
                    GraphNodeType.point,
                    const Offset(300, 260),
                  ),
                ),
                _ToolButton(
                  label: 'Platform',
                  icon: Icons.train,
                  color: const Color(0xFF6D597A),
                  onTap: () => provider.addNode(
                    GraphNodeType.platform,
                    const Offset(300, 380),
                  ),
                ),
                _ToolButton(
                  label: 'Buffer Stop',
                  icon: Icons.block,
                  color: const Color(0xFFB00020),
                  onTap: () => provider.addNode(
                    GraphNodeType.bufferStop,
                    const Offset(260, 200),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Signals & Control',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _ToolButton(
                  label: 'Signal',
                  icon: Icons.traffic,
                  color: const Color(0xFFE63946),
                  onTap: () => provider.addNode(
                    GraphNodeType.signal,
                    const Offset(300, 320),
                  ),
                ),
                _ToolButton(
                  label: 'Train Stop',
                  icon: Icons.stop_circle,
                  color: const Color(0xFFF4A261),
                  onTap: () => provider.addNode(
                    GraphNodeType.trainStop,
                    const Offset(340, 320),
                  ),
                ),
                _ToolButton(
                  label: 'Route Reservation',
                  icon: Icons.layers,
                  color: const Color(0xFFF1C40F),
                  onTap: () => provider.addNode(
                    GraphNodeType.routeReservation,
                    const Offset(380, 220),
                  ),
                ),
                _ToolButton(
                  label: 'Movement Auth',
                  icon: Icons.arrow_forward,
                  color: const Color(0xFF2ECC71),
                  onTap: () => provider.addNode(
                    GraphNodeType.movementAuthority,
                    const Offset(380, 260),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'CBTC & Sensors',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _ToolButton(
                  label: 'Axle Counter',
                  icon: Icons.adjust,
                  color: const Color(0xFF457B9D),
                  onTap: () => provider.addNode(
                    GraphNodeType.axleCounter,
                    const Offset(420, 200),
                  ),
                ),
                _ToolButton(
                  label: 'Transponder',
                  icon: Icons.hexagon,
                  color: const Color(0xFF118AB2),
                  onTap: () => provider.addNode(
                    GraphNodeType.transponder,
                    const Offset(420, 240),
                  ),
                ),
                _ToolButton(
                  label: 'WiFi Antenna',
                  icon: Icons.wifi,
                  color: const Color(0xFF06D6A0),
                  onTap: () => provider.addNode(
                    GraphNodeType.wifiAntenna,
                    const Offset(420, 280),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Rolling Stock',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _ToolButton(
                  label: 'Train',
                  icon: Icons.train,
                  color: const Color(0xFF1D3557),
                  onTap: () => provider.addNode(
                    GraphNodeType.train,
                    const Offset(260, 120),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Notes',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _ToolButton(
                  label: 'Text',
                  icon: Icons.text_fields,
                  color: const Color(0xFF8D6E63),
                  onTap: () => provider.addNode(
                    GraphNodeType.text,
                    const Offset(300, 440),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tip: Toggle Connect, then click two nodes to link them.',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class GraphPropertiesPanel extends StatefulWidget {
  const GraphPropertiesPanel({super.key});

  @override
  State<GraphPropertiesPanel> createState() => _GraphPropertiesPanelState();
}

class _GraphPropertiesPanelState extends State<GraphPropertiesPanel> {
  final TextEditingController _labelController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GraphProvider>(context);
    final node = provider.selectedNode;

    if (node == null) {
      return Container(
        width: 260,
        color: const Color(0xFFF7F7F7),
        padding: const EdgeInsets.all(16),
        child: const Text(
          'Select a node to edit properties.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    _labelController.value = TextEditingValue(
      text: node.label,
      selection: TextSelection.collapsed(offset: node.label.length),
    );

    return Container(
      width: 260,
      color: const Color(0xFFF7F7F7),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            node.type.name.toUpperCase(),
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Label',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) {
              provider.updateNodeLabel(node.id, value);
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Position: ${node.position.dx.toStringAsFixed(0)}, '
            '${node.position.dy.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 12),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: provider.deleteSelectedNode,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete Node'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE63946),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ToolButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: color,
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
