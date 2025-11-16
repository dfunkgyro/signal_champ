import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import simulation entities
import '../models/simulation/entities.dart';

// Import railway simulation controller
import '../controllers/railway_simulation_controller.dart';

// Import railway painter
import '../painters/railway_painter.dart';

// ============================================================================
// SIMULATION SCREEN UI
// ============================================================================

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({Key? key}) : super(key: key);

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double _cameraOffsetX = 0;
  double _zoom = 1.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60 FPS
    )..addListener(() {
        context.read<RailwaySimulationController>().updateSimulation();
      });
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Two-Aspect Fixed Block Signalling'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showSignallingInfo(context),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelp(context),
          ),
        ],
      ),
      body: Row(
        children: [
          _buildControlPanel(),
          Expanded(
            child: _buildRailwayCanvas(),
          ),
          _buildStatusPanel(),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
      ),
      child: Consumer<RailwaySimulationController>(
        builder: (context, controller, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Simulation Controls
              Text(
                'Simulation Controls',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.isRunning
                          ? controller.pauseSimulation
                          : controller.startSimulation,
                      icon: Icon(
                        controller.isRunning ? Icons.pause : Icons.play_arrow,
                      ),
                      label: Text(controller.isRunning ? 'Pause' : 'Start'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: controller.isRunning
                            ? Colors.orange
                            : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.stop),
                    color: Colors.red,
                    onPressed: controller.resetSimulation,
                    tooltip: 'Reset',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Speed: ${controller.simulationSpeed.toStringAsFixed(1)}x'),
              Slider(
                value: controller.simulationSpeed,
                min: 0.1,
                max: 3.0,
                divisions: 29,
                onChanged: controller.setSimulationSpeed,
              ),
              const Divider(height: 32),

              // Train Controls
              Text(
                'Train Management',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => controller.addTrain(startPlatformId: 'P1'),
                icon: const Icon(Icons.add),
                label: const Text('Add Train at P1'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => controller.addTrain(startPlatformId: 'P3'),
                icon: const Icon(Icons.add),
                label: const Text('Add Train at P3'),
              ),
              const SizedBox(height: 12),
              Text('Active Trains: ${controller.trains.length}'),
              const SizedBox(height: 8),
              ...controller.trains.map((train) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      dense: true,
                      leading: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: train.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(
                        train.name,
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        train.atPlatform
                            ? 'At platform'
                            : train.hasStoppedAtSignal
                                ? 'Stopped at signal'
                                : 'Moving ${train.speed.toStringAsFixed(1)} km/h',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        onPressed: () => controller.removeTrain(train.id),
                      ),
                    ),
                  )),
              const Divider(height: 32),

              // Camera Controls
              Text(
                'View Controls',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _cameraOffsetX += 200);
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Pan Left'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _cameraOffsetX -= 200);
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Pan Right'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _zoom = (_zoom * 1.2).clamp(0.5, 3.0));
                      },
                      icon: const Icon(Icons.zoom_in),
                      label: const Text('Zoom In'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _zoom = (_zoom / 1.2).clamp(0.5, 3.0));
                      },
                      icon: const Icon(Icons.zoom_out),
                      label: const Text('Zoom Out'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _cameraOffsetX = 0;
                    _zoom = 1.0;
                  });
                },
                icon: const Icon(Icons.center_focus_strong),
                label: const Text('Reset View'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRailwayCanvas() {
    return Container(
      color: Colors.grey[200],
      child: Consumer<RailwaySimulationController>(
        builder: (context, controller, _) {
          return GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _cameraOffsetX += details.delta.dx / _zoom;
              });
            },
            child: CustomPaint(
              size: Size.infinite,
              painter: RailwayPainter(
                trains: controller.trains,
                blocks: controller.blocks,
                signals: controller.signals,
                platforms: controller.platforms,
                cameraOffsetX: _cameraOffsetX,
                zoom: _zoom,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusPanel() {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          left: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
      ),
      child: Consumer<RailwaySimulationController>(
        builder: (context, controller, _) {
          final stats = controller.getSimulationStats();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'System Status',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              _buildStatusCard(
                'Simulation',
                controller.isRunning ? 'Running' : 'Paused',
                controller.isRunning ? Colors.green : Colors.grey,
                icon: controller.isRunning ? Icons.play_arrow : Icons.pause,
              ),

              _buildStatusCard(
                'Trains',
                '${stats['total_trains']} total',
                Colors.blue,
                icon: Icons.train,
                subtitle: '${stats['moving_trains']} moving, ${stats['trains_at_platforms']} at platforms',
              ),

              _buildStatusCard(
                'Signals',
                '${stats['green_signals']}/${stats['total_signals']} Green',
                Colors.green,
                icon: Icons.traffic,
                subtitle: '${stats['total_signals'] - stats['green_signals']} Red',
              ),

              _buildStatusCard(
                'Track Blocks',
                '${stats['occupied_blocks']}/${stats['total_blocks']} Occupied',
                stats['occupied_blocks'] > 0 ? Colors.orange : Colors.green,
                icon: Icons.grid_on,
              ),

              const Divider(height: 32),

              Text(
                'Signalling Principles',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              _buildPrincipleItem('🟢 Green: Block ahead clear'),
              _buildPrincipleItem('🔴 Red: Block ahead occupied'),
              _buildPrincipleItem('🛡️ Overlap protection active'),
              _buildPrincipleItem('📡 Track circuits monitoring'),
              _buildPrincipleItem('✅ One train per block'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(
    String label,
    String value,
    Color color, {
    IconData? icon,
    String? subtitle,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrincipleItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignallingInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Two-Aspect Fixed Block Signalling'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Key Principles:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Track divided into fixed blocks'),
              Text('• Only one train per block'),
              Text('• Two signal aspects: Red (stop) and Green (proceed)'),
              Text('• Track circuits detect train presence'),
              Text('• Overlap blocks provide safety margin'),
              Text('• Sequential clearance as trains move'),
              SizedBox(height: 12),
              Text(
                'Signal Logic:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('🟢 Green: Block ahead AND overlap clear'),
              Text('🔴 Red: Block ahead OR overlap occupied'),
              SizedBox(height: 12),
              Text(
                'Safety Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Overlap protection prevents collisions'),
              Text('• Automatic signal updates via track circuits'),
              Text('• Trains stop at red signals'),
              Text('• Platform stops for passenger service'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Use'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Adding Trains:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Click "Add Train at P1" or "Add Train at P3"'),
              Text('• Trains start at platforms'),
              SizedBox(height: 12),
              Text(
                'Running Simulation:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Click START to begin train movements'),
              Text('• Trains depart from platforms automatically'),
              Text('• Adjust speed slider to control simulation'),
              SizedBox(height: 12),
              Text(
                'Observing Signals:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Watch signals change red/green automatically'),
              Text('• Trains stop at red signals'),
              Text('• Signals turn green when blocks clear'),
              SizedBox(height: 12),
              Text(
                'Camera Controls:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Use Pan buttons to move view'),
              Text('• Use Zoom buttons to adjust scale'),
              Text('• Drag canvas to pan manually'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }
}
