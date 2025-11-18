import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/scenario_models.dart';
import '../services/scenario_service.dart';
import '../services/auth_service.dart';
import '../widgets/route_designer_canvas.dart';

class ScenarioBuilderScreen extends StatefulWidget {
  final String? scenarioId;

  const ScenarioBuilderScreen({super.key, this.scenarioId});

  @override
  State<ScenarioBuilderScreen> createState() => _ScenarioBuilderScreenState();
}

class _ScenarioBuilderScreenState extends State<ScenarioBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _uuid = const Uuid();

  late RailwayScenario _scenario;
  bool _isLoading = true;
  bool _isSaving = false;
  ScenarioCategory _selectedCategory = ScenarioCategory.custom;
  ScenarioDifficulty _selectedDifficulty = ScenarioDifficulty.beginner;

  @override
  void initState() {
    super.initState();
    _initializeScenario();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _initializeScenario() async {
    setState(() => _isLoading = true);

    if (widget.scenarioId != null) {
      // Load existing scenario
      final scenarioService = context.read<ScenarioService>();
      final scenario = await scenarioService.getScenario(widget.scenarioId!);

      if (scenario != null) {
        _scenario = scenario;
        _nameController.text = scenario.name;
        _descriptionController.text = scenario.description;
        _selectedCategory = scenario.category;
        _selectedDifficulty = scenario.difficulty;
      } else {
        _createNewScenario();
      }
    } else {
      _createNewScenario();
    }

    setState(() => _isLoading = false);
  }

  void _createNewScenario() {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;

    _scenario = RailwayScenario(
      id: _uuid.v4(),
      name: 'New Scenario',
      description: '',
      authorId: user?.id ?? '',
      authorName: user?.userMetadata?['full_name'] as String? ?? 'Anonymous',
      category: ScenarioCategory.custom,
      difficulty: ScenarioDifficulty.beginner,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _nameController.text = _scenario.name;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scenario Builder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed: _showHelp,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save',
            onPressed: _isSaving ? null : _saveScenario,
          ),
          if (_scenario.isPublic)
            IconButton(
              icon: const Icon(Icons.cloud_off),
              tooltip: 'Unpublish',
              onPressed: _unpublishScenario,
            )
          else
            IconButton(
              icon: const Icon(Icons.cloud_upload),
              tooltip: 'Publish',
              onPressed: _publishScenario,
            ),
        ],
      ),
      body: Row(
        children: [
          // Left sidebar - Properties
          SizedBox(
            width: 300,
            child: _buildPropertiesPanel(theme),
          ),

          // Main canvas area
          Expanded(
            child: RouteDesignerCanvas(
              scenario: _scenario,
              onScenarioChanged: (updatedScenario) {
                setState(() {
                  _scenario = updatedScenario;
                });
              },
            ),
          ),

          // Right sidebar - Elements & Settings
          SizedBox(
            width: 300,
            child: _buildElementsPanel(theme),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _testScenario,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Test Scenario'),
      ),
    );
  }

  Widget _buildPropertiesPanel(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Scenario Properties',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _scenario = _scenario.copyWith(name: value);
                });
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _scenario = _scenario.copyWith(description: value);
                });
              },
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<ScenarioCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: ScenarioCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Icon(category.icon, size: 20),
                      const SizedBox(width: 8),
                      Text(category.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                    _scenario = _scenario.copyWith(category: value);
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Difficulty
            DropdownButtonFormField<ScenarioDifficulty>(
              value: _selectedDifficulty,
              decoration: const InputDecoration(
                labelText: 'Difficulty',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.signal_cellular_alt),
              ),
              items: ScenarioDifficulty.values.map((difficulty) {
                return DropdownMenuItem(
                  value: difficulty,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: difficulty.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(difficulty.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedDifficulty = value;
                    _scenario = _scenario.copyWith(difficulty: value);
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Canvas size
            Text(
              'Canvas Size',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Width',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: _scenario.canvasWidth.toString(),
                    onChanged: (value) {
                      final width = double.tryParse(value);
                      if (width != null) {
                        setState(() {
                          _scenario = _scenario.copyWith(canvasWidth: width);
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Height',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: _scenario.canvasHeight.toString(),
                    onChanged: (value) {
                      final height = double.tryParse(value);
                      if (height != null) {
                        setState(() {
                          _scenario = _scenario.copyWith(canvasHeight: height);
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Time limit
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Time Limit (seconds)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer),
                helperText: 'Leave empty for no time limit',
              ),
              keyboardType: TextInputType.number,
              initialValue: _scenario.timeLimit?.toString() ?? '',
              onChanged: (value) {
                final limit = int.tryParse(value);
                setState(() {
                  _scenario = _scenario.copyWith(timeLimit: limit);
                });
              },
            ),
            const SizedBox(height: 16),

            // Max trains
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Max Trains',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.train),
                helperText: 'Leave empty for unlimited',
              ),
              keyboardType: TextInputType.number,
              initialValue: _scenario.maxTrains?.toString() ?? '',
              onChanged: (value) {
                final max = int.tryParse(value);
                setState(() {
                  _scenario = _scenario.copyWith(maxTrains: max);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElementsPanel(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Layout Elements',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildElementCount('Tracks', _scenario.tracks.length, Icons.linear_scale),
          _buildElementCount('Signals', _scenario.signals.length, Icons.traffic),
          _buildElementCount('Points', _scenario.points.length, Icons.call_split),
          _buildElementCount(
              'Block Sections', _scenario.blockSections.length, Icons.crop_square),
          _buildElementCount(
              'Train Spawns', _scenario.trainSpawns.length, Icons.train),

          const SizedBox(height: 24),

          Text(
            'Quick Actions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          ElevatedButton.icon(
            onPressed: _clearAll,
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear All'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.errorContainer,
              foregroundColor: theme.colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 8),

          ElevatedButton.icon(
            onPressed: _loadTemplate,
            icon: const Icon(Icons.file_download),
            label: const Text('Load Template'),
          ),
        ],
      ),
    );
  }

  Widget _buildElementCount(String label, int count, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Chip(label: Text('$count')),
        ],
      ),
    );
  }

  Future<void> _saveScenario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final scenarioService = context.read<ScenarioService>();
    final success = widget.scenarioId != null
        ? await scenarioService.updateScenario(_scenario)
        : await scenarioService.createScenario(
            name: _scenario.name,
            description: _scenario.description,
            category: _scenario.category,
            difficulty: _scenario.difficulty,
          );

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success != null || success == true
              ? 'Scenario saved successfully'
              : 'Failed to save scenario'),
          backgroundColor:
              success != null || success == true ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _publishScenario() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publish Scenario'),
        content: const Text(
          'Publishing will make this scenario available to all users in the community marketplace. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Publish'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final scenarioService = context.read<ScenarioService>();
    final success = await scenarioService.publishScenario(_scenario.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Scenario published successfully'
              : 'Failed to publish scenario'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        setState(() {
          _scenario = _scenario.copyWith(isPublic: true);
        });
      }
    }
  }

  Future<void> _unpublishScenario() async {
    final scenarioService = context.read<ScenarioService>();
    final success = await scenarioService.unpublishScenario(_scenario.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Scenario unpublished'
              : 'Failed to unpublish scenario'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        setState(() {
          _scenario = _scenario.copyWith(isPublic: false);
        });
      }
    }
  }

  void _testScenario() {
    // TODO: Implement scenario testing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test mode - Feature coming soon!'),
      ),
    );
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Elements'),
        content: const Text('Are you sure you want to remove all elements?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _scenario = _scenario.copyWith(
                  tracks: [],
                  signals: [],
                  points: [],
                  blockSections: [],
                  trainSpawns: [],
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _loadTemplate() {
    // TODO: Implement template loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Template loading - Feature coming soon!'),
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scenario Builder Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How to use:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Select an element type from the toolbar'),
              Text('2. Click on the canvas to place elements'),
              Text('3. For tracks and blocks, click start and end points'),
              Text('4. Click elements to select and view properties'),
              Text('5. Use Delete button to remove selected element'),
              SizedBox(height: 16),
              Text(
                'Navigation:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Drag with one finger to pan'),
              Text('• Pinch with two fingers to zoom'),
              Text('• Use zoom buttons for precise control'),
              SizedBox(height: 16),
              Text(
                'Publishing:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Save your scenario first, then publish to share with the community.'),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
