import 'package:flutter/material.dart';
import 'control_section_base.dart';

class SignalControlSection extends StatelessWidget {
  const SignalControlSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return buildSection(
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
        buildControlButton(
          context,
          icon: Icons.refresh,
          label: 'Reset All Signals',
          color: Colors.blue,
          onPressed: () {
            // Reset signals
          },
        ),
      ],
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
}
