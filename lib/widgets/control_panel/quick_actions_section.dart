import 'package:flutter/material.dart';
import 'control_section_base.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return buildSection(
      context,
      title: 'Quick Actions',
      icon: Icons.flash_on,
      children: [
        buildQuickAction(
          context,
          icon: Icons.emergency,
          label: 'Emergency Stop',
          onPressed: () {
            _showEmergencyStopDialog(context);
          },
        ),
        const SizedBox(height: 8),
        buildQuickAction(
          context,
          icon: Icons.restart_alt,
          label: 'Reset Simulation',
          onPressed: () {
            _showResetDialog(context);
          },
        ),
        const SizedBox(height: 8),
        buildQuickAction(
          context,
          icon: Icons.cloud_upload,
          label: 'Save to Cloud',
          onPressed: () {
            // Save to cloud
          },
        ),
      ],
    );
  }

  void _showEmergencyStopDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency Stop'),
          ],
        ),
        content: const Text(
          'This will immediately stop all trains and set all signals to red. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Emergency stop logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emergency stop activated'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Emergency Stop'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Simulation'),
        content: const Text(
          'This will reset the simulation to its initial state. All unsaved progress will be lost. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Reset logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Simulation reset')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
