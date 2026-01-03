import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../builder/screens/terminal_editor_screen.dart';
import '../controllers/terminal_station_controller.dart';

class BuilderModeScreen extends StatelessWidget {
  final VoidCallback onSwitchToSimulation;

  const BuilderModeScreen({
    Key? key,
    required this.onSwitchToSimulation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TerminalEditorScreen(
      onApplyLayout: (layout) {
        final controller = context.read<TerminalStationController>();
        controller.importLayoutFromJson(layout);
        controller.resetSimulation();
        onSwitchToSimulation();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Builder layout loaded into simulation'),
          ),
        );
      },
    );
  }
}
