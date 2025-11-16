import 'package:flutter/material.dart';
import '../../controllers/simulation_controller.dart';

class EventLogSection extends StatelessWidget {
  final SimulationController controller;

  const EventLogSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final events = controller.eventLog;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.list_alt, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Event Log',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${events.length} events',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 150,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[50],
              ),
              child: events.isEmpty
                  ? const Center(
                      child: Text(
                        'No events yet\nStart simulation to see events',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        return _buildEventLogItem(events[index]);
                      },
                    ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: events.isEmpty
                        ? null
                        : () {
                            controller.clearEventLog();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Event log cleared'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Clear Log'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: events.isEmpty
                        ? null
                        : () {
                            // Export functionality
                            final exportData = events.join('\n');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Exported ${events.length} events'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Export'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventLogItem(String event) {
    // Parse event to determine type and color
    Color dotColor = Colors.green;
    if (event.contains('stopped') ||
        event.contains('RED') ||
        event.contains('OCCUPIED')) {
      dotColor = Colors.red;
    } else if (event.contains('waiting') || event.contains('warning')) {
      dotColor = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              event,
              style: const TextStyle(fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
