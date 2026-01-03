import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/graph_provider.dart';

class GraphToolbar extends StatelessWidget {
  const GraphToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GraphProvider>(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1D3557),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            'Node Rail Editor',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          _ToolbarButton(
            label: provider.connectMode ? 'Connecting' : 'Connect',
            icon: provider.connectMode ? Icons.link : Icons.link_outlined,
            isActive: provider.connectMode,
            onPressed: provider.toggleConnectMode,
          ),
          const SizedBox(width: 8),
          _ToolbarButton(
            label: 'Delete',
            icon: Icons.delete_outline,
            onPressed: provider.selectedNode == null
                ? null
                : provider.deleteSelectedNode,
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isActive;

  const _ToolbarButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
      style: TextButton.styleFrom(
        backgroundColor:
            isActive ? const Color(0xFF457B9D) : const Color(0xFF2E4A6F),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
