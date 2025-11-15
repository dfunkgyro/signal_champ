import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rail_champ/models/railway_model.dart';
import 'package:rail_champ/widgets/smc_overview_panel.dart';

class ControlPanel extends StatelessWidget {
  const ControlPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.control_camera,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Control Panel',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Simulation Controls
                _buildSection(
                  context,
                  title: 'Simulation',
                  icon: Icons.play_circle,
                  children: [
                    _buildControlButton(
                      context,
                      icon: Icons.play_arrow,
                      label: 'Start',
                      color: Colors.green,
                      onPressed: () {
                        // Start simulation
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildControlButton(
                      context,
                      icon: Icons.pause,
                      label: 'Pause',
                      color: Colors.orange,
                      onPressed: () {
                        // Pause simulation
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildControlButton(
                      context,
                      icon: Icons.stop,
                      label: 'Stop',
                      color: Colors.red,
                      onPressed: () {
                        // Stop simulation
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildSlider(
                      context,
                      label: 'Speed',
                      value: 1.0,
                      min: 0.1,
                      max: 5.0,
                      onChanged: (value) {
                        // Update speed
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Train Management
                _buildSection(
                  context,
                  title: 'Trains',
                  icon: Icons.train,
                  children: [
                    _buildControlButton(
                      context,
                      icon: Icons.add,
                      label: 'Add Train',
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: () {
                        _showAddTrainDialog(context);
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildControlButton(
                      context,
                      icon: Icons.delete,
                      label: 'Remove Selected',
                      color: Colors.red,
                      onPressed: () {
                        // Remove train
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      context,
                      label: 'Active Trains',
                      value: '3',
                      icon: Icons.train,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Signal Control
                _buildSection(
                  context,
                  title: 'Signals',
                  icon: Icons.traffic,
                  children: [
                    _buildSignalControl(context, 'Signal C31'),
                    const SizedBox(height: 8),
                    _buildSignalControl(context, 'Signal C32'),
                    const SizedBox(height: 8),
                    _buildSignalControl(context, 'Signal C33'),
                    const SizedBox(height: 16),
                    _buildControlButton(
                      context,
                      icon: Icons.refresh,
                      label: 'Reset All Signals',
                      color: Colors.blue,
                      onPressed: () {
                        // Reset signals
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // CBTC System
                _buildCbtcSection(context),

                const SizedBox(height: 16),

                // SMC Overview Panel
                const SmcOverviewPanel(),

                const SizedBox(height: 16),

                // Quick Actions
                _buildSection(
                  context,
                  title: 'Quick Actions',
                  icon: Icons.flash_on,
                  children: [
                    _buildQuickAction(
                      context,
                      icon: Icons.emergency,
                      label: 'Emergency Stop',
                      onPressed: () {
                        _showEmergencyStopDialog(context);
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildQuickAction(
                      context,
                      icon: Icons.restart_alt,
                      label: 'Reset Simulation',
                      onPressed: () {
                        _showResetDialog(context);
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildQuickAction(
                      context,
                      icon: Icons.cloud_upload,
                      label: 'Save to Cloud',
                      onPressed: () {
                        // Save to cloud
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildSlider(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              '${value.toStringAsFixed(1)}x',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) * 10).toInt(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalControl(BuildContext context, String signalId) {
    return Row(
      children: [
        Expanded(
          child: Text(signalId),
        ),
        IconButton(
          icon: const Icon(Icons.circle, color: Colors.green),
          onPressed: () {
            // Set signal to green
          },
          tooltip: 'Green',
        ),
        IconButton(
          icon: const Icon(Icons.circle, color: Colors.red),
          onPressed: () {
            // Set signal to red
          },
          tooltip: 'Red',
        ),
      ],
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(label)),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
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

  Widget _buildCbtcSection(BuildContext context) {
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
