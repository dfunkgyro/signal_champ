import 'package:flutter/material.dart';
import 'control_section_base.dart';

class TrainControlSection extends StatelessWidget {
  const TrainControlSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return buildSection(
      context,
      title: 'Trains',
      icon: Icons.train,
      children: [
        buildControlButton(
          context,
          icon: Icons.add,
          label: 'Add Train',
          color: Theme.of(context).colorScheme.primary,
          onPressed: () {
            _showAddTrainDialog(context);
          },
        ),
        const SizedBox(height: 8),
        buildControlButton(
          context,
          icon: Icons.delete,
          label: 'Remove Selected',
          color: Colors.red,
          onPressed: () {
            // Remove train
          },
        ),
        const SizedBox(height: 16),
        buildInfoCard(
          context,
          label: 'Active Trains',
          value: '3',
          icon: Icons.train,
        ),
      ],
    );
  }

  void _showAddTrainDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Train'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: 'Train Name',
                hintText: 'Enter train name',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Starting Block',
              ),
              items: const [
                DropdownMenuItem(value: 'B1', child: Text('Block B1')),
                DropdownMenuItem(value: 'B2', child: Text('Block B2')),
                DropdownMenuItem(value: 'B3', child: Text('Block B3')),
              ],
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Add train logic
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
