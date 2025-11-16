import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/railway_model.dart';

class CbtcControlSection extends StatelessWidget {
  const CbtcControlSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final railwayModel = context.watch<RailwayModel>();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings_remote, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'CBTC System',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Toggle CBTC Devices
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: railwayModel.cbtcDevicesEnabled
                    ? Colors.blue[50]
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: railwayModel.cbtcDevicesEnabled
                      ? Colors.blue
                      : Colors.grey,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sensors,
                    size: 20,
                    color: railwayModel.cbtcDevicesEnabled
                        ? Colors.blue
                        : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'CBTC Devices',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Switch(
                    value: railwayModel.cbtcDevicesEnabled,
                    onChanged: (value) {
                      railwayModel.toggleCbtcDevices(value);
                    },
                    activeColor: Colors.blue,
                  ),
                ],
              ),
            ),

            if (railwayModel.cbtcDevicesEnabled) ...[
              const SizedBox(height: 12),

              // Device info
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                        const SizedBox(width: 6),
                        Text(
                          'Devices Active',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '• ${railwayModel.transponders.length} Transponder tags\n'
                      '• ${railwayModel.wifiAntennas.length} WiFi antennas',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green[800],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Start CBTC Mode button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    railwayModel.toggleCbtcMode(!railwayModel.cbtcModeActive);
                  },
                  icon: Icon(
                    railwayModel.cbtcModeActive
                        ? Icons.stop_circle
                        : Icons.play_circle,
                  ),
                  label: Text(
                    railwayModel.cbtcModeActive
                        ? 'Stop CBTC Mode'
                        : 'Start CBTC Mode',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: railwayModel.cbtcModeActive
                        ? Colors.orange
                        : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              if (railwayModel.cbtcModeActive) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.radio_button_checked,
                              size: 16,
                              color: Colors.blue[700]),
                          const SizedBox(width: 6),
                          Text(
                            'Moving Block System Active',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'All signals showing blue aspect.\nTrains using continuous ATP supervision.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
