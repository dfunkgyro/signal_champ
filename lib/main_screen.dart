import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/railway_model.dart';
import 'controllers/simulation_controller.dart';
import 'controllers/ai_controller.dart';
import 'controllers/theme_controller.dart';
import 'services/supabase_service.dart';
import 'widgets/railway_canvas.dart' hide Train;
import 'widgets/control_panel.dart';
import 'widgets/status_panel.dart';
import 'history_screen.dart';
import 'analytics_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentLayout = 0;
  final List<String> _layoutOptions = [
    'Default Layout',
    'Compact View',
    'Extended Tracks',
    'Advanced Network'
  ];

  @override
  void initState() {
    super.initState();
    // Initialize simulation controller with model - DO NOT auto-start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final model = Provider.of<RailwayModel>(context, listen: false);
      final controller =
          Provider.of<SimulationController>(context, listen: false);
      controller.setModel(model);
      // Note: Simulation NOT auto-started - user must press Start button
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rail Champ - Advanced Railway Simulation'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          _buildLayoutSelector(),
          _buildConnectionStatus(),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showAIAnalysis,
            tooltip: 'AI Analysis',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            ),
            tooltip: 'History',
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () =>
                Provider.of<ThemeController>(context, listen: false)
                    .getDarkTheme(),
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SizedBox.expand(
        child: _buildCurrentLayout(),
      ),
      floatingActionButton: _buildFloatingActions(),
      drawer: _buildNavigationDrawer(),
    );
  }

  Widget _buildLayoutSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: DropdownButton<int>(
        value: _currentLayout,
        dropdownColor: Colors.blue[700],
        icon: const Icon(Icons.view_compact, color: Colors.white),
        items: _layoutOptions.asMap().entries.map((entry) {
          return DropdownMenuItem<int>(
            value: entry.key,
            child: Text(
              entry.value,
              style: const TextStyle(color: Colors.white),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _currentLayout = value!;
          });
        },
      ),
    );
  }

  Widget _buildCurrentLayout() {
    switch (_currentLayout) {
      case 0: // Default Layout
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 280,
              child: const ControlPanel(),
            ),
            const Expanded(child: RailwayCanvas()),
            Container(
              width: 320,
              child: const StatusPanel(),
            ),
          ],
        );
      case 1: // Compact View
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Expanded(flex: 2, child: RailwayCanvas()),
            SizedBox(
              height: 200,
              child: const ControlPanel(),
            ),
          ],
        );
      case 2: // Extended Tracks
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 250,
              child: const ControlPanel(),
            ),
            const Expanded(child: RailwayCanvas()),
            Container(
              width: 250,
              child: const StatusPanel(),
            ),
          ],
        );
      case 3: // Advanced Network
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 300,
              child: const ControlPanel(),
            ),
            const Expanded(child: RailwayCanvas()),
            Container(
              width: 300,
              child: const StatusPanel(),
            ),
          ],
        );
      default:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 280,
              child: const ControlPanel(),
            ),
            const Expanded(child: RailwayCanvas()),
            Container(
              width: 320,
              child: const StatusPanel(),
            ),
          ],
        );
    }
  }

  Widget _buildFloatingActions() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          onPressed: () => _showAddTrainDialog(),
          tooltip: 'Add Train',
          backgroundColor: Colors.green,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          onPressed: () {
            final model = Provider.of<RailwayModel>(context, listen: false);
            final selectedTrain = model.trains.firstWhere(
              (t) => t.isSelected,
              orElse: () => model.trains.isNotEmpty
                  ? model.trains.first
                  : Train(
                      id: '',
                      name: '',
                      vin: '',
                      x: 0,
                      y: 0,
                      speed: 0,
                      currentBlock: '',
                      color: Colors.transparent,
                    ),
            );
            if (selectedTrain.id.isNotEmpty) {
              model.reverseTrainDirection(selectedTrain.id);
            }
          },
          tooltip: 'Reverse Selected Train',
          backgroundColor: Colors.orange,
          child: const Icon(Icons.swap_horiz, color: Colors.white),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          onPressed: () {
            Provider.of<SimulationController>(context, listen: false)
                .resetSimulation();
          },
          tooltip: 'Reset Simulation',
          backgroundColor: Colors.red,
          child: const Icon(Icons.refresh, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildNavigationDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue[700],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rail Champ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Advanced Railway Simulation',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Spacer(),
                Text(
                  'Version 2.0.0',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('AI Analytics'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AnalyticsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Simulation History'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Documentation'),
            onTap: () {
              Navigator.pop(context);
              _showHelpDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Consumer2<AIController, SupabaseService>(
      builder: (context, aiController, supabaseService, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: 'AI: ${aiController.connectionStatus}',
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: aiController.isConnected ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Cloud: ${supabaseService.connectionStatus}',
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color:
                      supabaseService.isConnected ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        );
      },
    );
  }

  void _showAIAnalysis() {
    final aiController = Provider.of<AIController>(context, listen: false);
    final railwayModel = Provider.of<RailwayModel>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics, color: Colors.blue),
            SizedBox(width: 8),
            Text('AI Operations Analysis'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<String>(
            future: aiController.analyzeRailwayOperation(
                'Current railway state: ${railwayModel.trains.length} trains active, '
                '${railwayModel.blocks.where((b) => b.occupied).length} occupied blocks, '
                'Signals: ${railwayModel.signals.map((s) => '${s.id}:${s.state.name}').join(', ')}. '
                'Points: ${railwayModel.points.map((p) => '${p.id}:${p.position.name}').join(', ')}. '
                'Provide operational analysis and suggestions.'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('AI is analyzing railway operations...'),
                  ],
                );
              }
              return SingleChildScrollView(
                child: Text(snapshot.data ?? 'No analysis available'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (aiController.connectionStatus.isNotEmpty)
            TextButton(
              onPressed: () {
                // Save analysis to cloud
                final supabaseService =
                    Provider.of<SupabaseService>(context, listen: false);
                supabaseService.saveSimulationState({
                  'analysis': aiController.connectionStatus,
                  'timestamp': DateTime.now().toIso8601String(),
                  'type': 'ai_analysis',
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Analysis saved to cloud')),
                );
              },
              child: const Text('Save to Cloud'),
            ),
        ],
      ),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simulation Settings'),
        content: Consumer<SimulationController>(
          builder: (context, controller, child) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Simulation Speed:'),
              Slider(
                value: controller.simulationSpeed,
                min: 0.1,
                max: 5.0,
                divisions: 49,
                label: '${controller.simulationSpeed.toStringAsFixed(1)}x',
                onChanged: (value) => controller.setSimulationSpeed(value),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Theme:'),
                  const Spacer(),
                  Switch(
                    value: Provider.of<ThemeController>(context).themeMode ==
                        ThemeMode.dark,
                    onChanged: (value) {
                      Provider.of<ThemeController>(context, listen: false)
                          .setThemeMode(
                              value ? ThemeMode.dark : ThemeMode.light);
                    },
                  ),
                  const Text('Dark'),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Layout Options:'),
              DropdownButton<int>(
                value: _currentLayout,
                items: _layoutOptions.asMap().entries.map((entry) {
                  return DropdownMenuItem<int>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _currentLayout = value!;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Documentation'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpSection('Starting Simulation',
                  'Click the START button in the Control Panel to begin. The simulation will NOT auto-start.'),
              _buildHelpSection('Adding Trains',
                  'Click the green + button to add trains. Trains will start moving when you start the simulation.'),
              _buildHelpSection('Controlling Signals',
                  'Use the Signal Control panel to set signals to green or red. Signals automatically turn red when blocks are occupied or points are incorrectly set.'),
              _buildHelpSection('Setting Points',
                  'Use the Point Control to switch tracks. Points determine which route trains will take.'),
              _buildHelpSection('Train Management',
                  'Select a train to control its speed, direction, and status. Watch the Status Panel for train stop reasons.'),
              _buildHelpSection('AI Analysis',
                  'Get intelligent insights and optimization suggestions from the AI system (requires OpenAI API key in .env file).'),
              _buildHelpSection('Cloud Storage',
                  'Save your simulation states to the cloud for later analysis (requires Supabase credentials in .env file).'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(content),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Rail Champ'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rail Champ - Advanced Railway Simulation'),
            SizedBox(height: 8),
            Text('Version: 2.0.0'),
            SizedBox(height: 8),
            Text('A sophisticated railway simulation app featuring:'),
            SizedBox(height: 4),
            Text('• Real-time train movement with stop reasons'),
            Text('• Advanced signaling system with detailed logic'),
            Text('• Comprehensive event logging'),
            Text('• AI-powered analytics (OpenAI integration)'),
            Text('• Cloud synchronization (Supabase)'),
            Text('• Multiple layout options'),
            Text('• User-controlled simulation start'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddTrainDialog() {
    final model = Provider.of<RailwayModel>(context, listen: false);

    if (!model.canCreateNewTrain()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot add more trains - blocks occupied'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.train, color: Colors.blue),
            SizedBox(width: 8),
            Text('Add Train'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select train type:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                model.addTrain(isCbtc: false);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Regular train added'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.train),
              label: const Text('Regular Train'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                model.addTrain(isCbtc: true);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('CBTC train added'),
                    backgroundColor: Colors.cyan,
                  ),
                );
              },
              icon: const Icon(Icons.sensors),
              label: const Text('CBTC Train'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'CBTC trains support multiple operating modes with color-coded indicators',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
