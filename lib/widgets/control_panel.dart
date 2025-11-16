import 'package:flutter/material.dart';
import 'smc_overview_panel.dart';
import 'control_panel/simulation_control_section.dart';
import 'control_panel/train_control_section.dart';
import 'control_panel/signal_control_section.dart';
import 'control_panel/cbtc_control_section.dart';
import 'control_panel/quick_actions_section.dart';

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
              children: const [
                // Simulation Controls
                SimulationControlSection(),
                SizedBox(height: 16),

                // Train Management
                TrainControlSection(),
                SizedBox(height: 16),

                // Signal Control
                SignalControlSection(),
                SizedBox(height: 16),

                // CBTC System
                CbtcControlSection(),
                SizedBox(height: 16),

                // SMC Overview Panel
                SmcOverviewPanel(),
                SizedBox(height: 16),

                // Quick Actions
                QuickActionsSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
