import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rail_champ/models/railway_model.dart';

class SmcOverviewPanel extends StatefulWidget {
  const SmcOverviewPanel({super.key});

  @override
  State<SmcOverviewPanel> createState() => _SmcOverviewPanelState();
}

class _SmcOverviewPanelState extends State<SmcOverviewPanel> {
  final TextEditingController _trackIdController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  String? _selectedVin;

  @override
  void dispose() {
    _trackIdController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final railwayModel = context.watch<RailwayModel>();

    if (!railwayModel.cbtcModeActive) {
      return const SizedBox.shrink();
    }

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
            // Header
            Row(
              children: [
                Icon(Icons.control_point, size: 20, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'SMC Overview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'System Management Centre',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),

            // Track Control Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.track_changes, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 6),
                      Text(
                        'Track Control',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Track ID Input
                  TextField(
                    controller: _trackIdController,
                    decoration: InputDecoration(
                      labelText: 'Track/Block Number',
                      hintText: 'e.g., 100, 102, 103',
                      prefixIcon: const Icon(Icons.numbers),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),

                  // Control Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final trackId = _trackIdController.text.trim();
                            if (trackId.isNotEmpty) {
                              railwayModel.smcCloseTrack(trackId);
                              _trackIdController.clear();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a track number'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.block, size: 16),
                          label: const Text('Close Track'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final trackId = _trackIdController.text.trim();
                            if (trackId.isNotEmpty) {
                              railwayModel.smcOpenTrack(trackId);
                              _trackIdController.clear();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a track number'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.check_circle, size: 16),
                          label: const Text('Open Track'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Destination Management Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.my_location, size: 16, color: Colors.green[700]),
                      const SizedBox(width: 6),
                      Text(
                        'Destination Management',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // VIN Selector
                  DropdownButtonFormField<String>(
                    value: _selectedVin,
                    decoration: InputDecoration(
                      labelText: 'Select CBTC Train (VIN)',
                      prefixIcon: const Icon(Icons.train),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: railwayModel.trains
                        .where((t) => t.isCbtcEquipped &&
                                     (t.cbtcMode == CbtcMode.auto || t.cbtcMode == CbtcMode.pm))
                        .map((train) {
                      return DropdownMenuItem(
                        value: train.vin,
                        child: Text(
                          '${train.name} (${train.vin})',
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedVin = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Destination Input
                  TextField(
                    controller: _destinationController,
                    decoration: InputDecoration(
                      labelText: 'Destination',
                      hintText: 'e.g., Platform1, Platform2, 100, 111',
                      prefixIcon: const Icon(Icons.flag),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),

                  // Set Destination Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_selectedVin != null && _destinationController.text.trim().isNotEmpty) {
                          railwayModel.smcSetDestination(
                            _selectedVin!,
                            _destinationController.text.trim(),
                          );
                          _destinationController.clear();
                          _selectedVin = null;
                          setState(() {});
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select train and enter destination'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.send, size: 16),
                      label: const Text('Set Destination & Depart'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Active Destinations Display
                  ...railwayModel.trains
                      .where((t) => t.isCbtcEquipped && t.smcDestination != null)
                      .map((train) {
                    return Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_forward, size: 14, color: Colors.green[700]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${train.name}: ${train.currentBlock} → ${train.smcDestination}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green[900],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Closed Tracks Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, size: 16, color: Colors.red[700]),
                      const SizedBox(width: 6),
                      const Text(
                        'Closed Tracks',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (railwayModel.getClosedTracks().isEmpty)
                    Text(
                      'No tracks closed',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: railwayModel.getClosedTracks().map((trackId) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red[700]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.block, size: 12, color: Colors.red[900]),
                              const SizedBox(width: 4),
                              Text(
                                'AB $trackId',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[900],
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () {
                                  railwayModel.smcOpenTrack(trackId);
                                },
                                child: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.red[900],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Info Box
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.amber[900]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AUTO & PM mode trains will emergency stop 200 units before closed tracks',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber[900],
                      ),
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
