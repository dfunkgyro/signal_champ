import 'package:flutter/material.dart';
import 'control_section_base.dart';

class SimulationControlSection extends StatelessWidget {
  const SimulationControlSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return buildSection(
      context,
      title: 'Simulation',
      icon: Icons.play_circle,
      children: [
        buildControlButton(
          context,
          icon: Icons.play_arrow,
          label: 'Start',
          color: Colors.green,
          onPressed: () {
            // Start simulation
          },
        ),
        const SizedBox(height: 8),
        buildControlButton(
          context,
          icon: Icons.pause,
          label: 'Pause',
          color: Colors.orange,
          onPressed: () {
            // Pause simulation
          },
        ),
        const SizedBox(height: 8),
        buildControlButton(
          context,
          icon: Icons.stop,
          label: 'Stop',
          color: Colors.red,
          onPressed: () {
            // Stop simulation
          },
        ),
        const SizedBox(height: 16),
        buildSlider(
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
    );
  }
}
