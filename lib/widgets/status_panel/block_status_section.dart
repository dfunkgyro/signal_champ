import 'package:flutter/material.dart';
import '../../models/railway_model.dart';

class BlockStatusSection extends StatelessWidget {
  final RailwayModel railwayModel;

  const BlockStatusSection({super.key, required this.railwayModel});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.view_week, size: 16),
                SizedBox(width: 8),
                Text(
                  'Block Sections Status',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: railwayModel.blocks.map((block) {
                final isOccupied = block.occupied;
                final isCrossover = block.id.startsWith('crossover');
                return Tooltip(
                  message:
                      '${block.id}: ${isOccupied ? "OCCUPIED" : "CLEAR"}${isCrossover ? " (Crossover)" : ""}',
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOccupied
                          ? Colors.red.withOpacity(0.2)
                          : Colors.green.withOpacity(0.2),
                      border: Border.all(
                        color: isOccupied ? Colors.red : Colors.green,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      block.id,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isOccupied ? Colors.red[900] : Colors.green[900],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
