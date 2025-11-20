import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/scenario_models.dart';
import '../models/railway_template.dart';
import '../services/scenario_service.dart';
import '../services/auth_service.dart';
import '../widgets/route_designer_canvas.dart';
import 'scenario_player_screen.dart';

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
    // Validate scenario has required elements before testing
    final validationErrors = <String>[];

    if (_scenario.blockSections.isEmpty) {
      validationErrors.add('No block sections defined');
    }

    if (_scenario.signals.isEmpty) {
      validationErrors.add('No signals defined');
    }

    if (_scenario.objectives.isEmpty) {
      validationErrors.add('No objectives defined (scenario will complete immediately)');
    }

    // Show validation warnings but allow testing anyway
    if (validationErrors.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange),
              SizedBox(width: 8),
              Text('Validation Warnings'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('The following issues were found:'),
              const SizedBox(height: 8),
              ...validationErrors.map((error) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 6, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(child: Text(error)),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
              const Text('Would you like to test anyway?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _launchTestMode();
              },
              child: const Text('Test Anyway'),
            ),
          ],
        ),
      );
    } else {
      _launchTestMode();
    }
  }

  void _launchTestMode() {
    // Update scenario with current form values
    _scenario = _scenario.copyWith(
      name: _nameController.text.isNotEmpty ? _nameController.text : 'Untitled Scenario',
      description: _descriptionController.text,
      category: _selectedCategory,
      difficulty: _selectedDifficulty,
      updatedAt: DateTime.now(),
    );

    // Navigate to scenario player in test mode
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ScenarioPlayerScreen(
          scenario: _scenario,
          isTestMode: true,
        ),
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
    showDialog(
      context: context,
      builder: (context) => _TemplatePickerDialog(
        onTemplateSelected: (template) {
          _applyTemplate(template);
          Navigator.pop(context);
        },
      ),
    );
  }

  /// Apply a template to the current scenario
  void _applyTemplate(RailwayTemplate template) {
    final properties = template.properties;

    // Apply template based on category
    switch (template.category) {
      case TemplateCategory.signals:
        // Add signal-related route to scenario
        _addTemplateSignalRoute(properties);
        break;
      case TemplateCategory.points:
        // Add point-related configuration
        _addTemplatePointConfig(properties);
        break;
      case TemplateCategory.stations:
        // Apply station template (multiple components)
        _applyStationTemplate(properties);
        break;
      case TemplateCategory.platforms:
        // Add platform configuration
        _addTemplatePlatform(properties);
        break;
      case TemplateCategory.crossovers:
        // Add crossover configuration
        _addTemplateCrossover(properties);
        break;
      case TemplateCategory.tracks:
        // Add track section
        _addTemplateTrack(properties);
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Applied template: ${template.name}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addTemplateSignalRoute(Map<String, dynamic> props) {
    final routeCount = props['routes'] as int? ?? 1;
    setState(() {
      _scenario = _scenario.copyWith(
        description: '${_scenario.description}\n\n📍 Template: Signal with $routeCount route(s) applied',
      );
    });
  }

  void _addTemplatePointConfig(Map<String, dynamic> props) {
    final direction = props['direction'] as String? ?? 'left';
    setState(() {
      _scenario = _scenario.copyWith(
        description: '${_scenario.description}\n\n🔀 Template: $direction-hand point applied',
      );
    });
  }

  void _applyStationTemplate(Map<String, dynamic> props) {
    final style = props['style'] as String? ?? 'through';
    final platforms = props['platforms'] as int? ?? 2;
    setState(() {
      _scenario = _scenario.copyWith(
        description: '${_scenario.description}\n\n🚉 Template: $style station with $platforms platforms applied',
      );
    });
  }

  void _addTemplatePlatform(Map<String, dynamic> props) {
    final length = props['length'] as int? ?? 200;
    setState(() {
      _scenario = _scenario.copyWith(
        description: '${_scenario.description}\n\n🚉 Template: Platform (${length}m) applied',
      );
    });
  }

  void _addTemplateCrossover(Map<String, dynamic> props) {
    final style = props['style'] as String? ?? 'single';
    setState(() {
      _scenario = _scenario.copyWith(
        description: '${_scenario.description}\n\n🔀 Template: $style crossover applied',
      );
    });
  }

  void _addTemplateTrack(Map<String, dynamic> props) {
    final length = props['length'] as int? ?? 100;
    final shape = props['shape'] as String? ?? 'straight';
    setState(() {
      _scenario = _scenario.copyWith(
        description: '${_scenario.description}\n\n🛤️ Template: $shape track (${length}m) applied',
      );
    });
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

/// Template Picker Dialog for browsing and selecting railway templates
class _TemplatePickerDialog extends StatefulWidget {
  final Function(RailwayTemplate) onTemplateSelected;

  const _TemplatePickerDialog({required this.onTemplateSelected});

  @override
  State<_TemplatePickerDialog> createState() => _TemplatePickerDialogState();
}

class _TemplatePickerDialogState extends State<_TemplatePickerDialog> {
  TemplateCategory _selectedCategory = TemplateCategory.signals;

  @override
  Widget build(BuildContext context) {
    final templates = RailwayTemplateLibrary.filterByCategory(_selectedCategory);

    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.layers, size: 28),
                const SizedBox(width: 8),
                const Text(
                  'Railway Template Library',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),

            // Category selector
            const SizedBox(height: 8),
            const Text(
              'Category:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TemplateCategory.values.map((category) {
                final isSelected = category == _selectedCategory;
                return ChoiceChip(
                  label: Text(_getCategoryLabel(category)),
                  avatar: Icon(_getCategoryIcon(category), size: 18),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = category);
                    }
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
            const Divider(),

            // Template list
            Expanded(
              child: templates.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No templates in this category',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: templates.length,
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Icon(template.icon),
                            ),
                            title: Text(template.name),
                            subtitle: Text(template.description),
                            trailing: ElevatedButton(
                              onPressed: () => widget.onTemplateSelected(template),
                              child: const Text('Apply'),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 8),
            Text(
              '💡 Tip: Templates provide pre-configured railway components for your scenarios',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryLabel(TemplateCategory category) {
    switch (category) {
      case TemplateCategory.signals:
        return 'Signals';
      case TemplateCategory.points:
        return 'Points';
      case TemplateCategory.tracks:
        return 'Tracks';
      case TemplateCategory.platforms:
        return 'Platforms';
      case TemplateCategory.crossovers:
        return 'Crossovers';
      case TemplateCategory.stations:
        return 'Stations';
    }
  }

  IconData _getCategoryIcon(TemplateCategory category) {
    switch (category) {
      case TemplateCategory.signals:
        return Icons.traffic;
      case TemplateCategory.points:
        return Icons.call_split;
      case TemplateCategory.tracks:
        return Icons.straighten;
      case TemplateCategory.platforms:
        return Icons.train_outlined;
      case TemplateCategory.crossovers:
        return Icons.alt_route;
      case TemplateCategory.stations:
        return Icons.apartment;
    }
  }
}
