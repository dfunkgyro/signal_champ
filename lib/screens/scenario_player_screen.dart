import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/scenario_models.dart';
import '../controllers/terminal_station_controller.dart';
import 'terminal_station_screen.dart';

/// Screen for playing railway scenarios
/// Wraps TerminalStationScreen with scenario-specific UI and objective tracking
class ScenarioPlayerScreen extends StatefulWidget {
  final RailwayScenario scenario;
  final bool isTestMode;

  const ScenarioPlayerScreen({
    Key? key,
    required this.scenario,
    this.isTestMode = false,
  }) : super(key: key);

  @override
  State<ScenarioPlayerScreen> createState() => _ScenarioPlayerScreenState();
}

class _ScenarioPlayerScreenState extends State<ScenarioPlayerScreen> {
  bool _isLoading = true;
  String? _loadError;
  Timer? _timeTimer;
  Timer? _trainSpawnTimer;
  Duration _elapsedTime = Duration.zero;

  // Objective tracking
  final Map<String, bool> _objectiveCompletion = {};
  final Map<String, int> _objectiveProgress = {};
  int _totalScore = 0;
  bool _scenarioCompleted = false;
  bool _scenarioFailed = false;
  String? _completionMessage;

  // Train spawning tracking
  final Set<String> _spawnedTrains = {};

  @override
  void initState() {
    super.initState();
    _loadScenario();
    _initializeObjectives();
    _startTimeTracking();
    _setupTrainSpawning();
  }

  @override
  void dispose() {
    _timeTimer?.cancel();
    _trainSpawnTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadScenario() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final controller = context.read<TerminalStationController>();
      await controller.loadScenario(widget.scenario);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = e.toString();
        });
      }
    }
  }

  void _initializeObjectives() {
    for (var objective in widget.scenario.objectives) {
      _objectiveCompletion[objective.id] = false;
      _objectiveProgress[objective.id] = 0;
    }
  }

  void _startTimeTracking() {
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedTime += const Duration(seconds: 1);

          // Check time limit
          if (widget.scenario.timeLimit != null) {
            if (_elapsedTime.inSeconds >= widget.scenario.timeLimit!) {
              _failScenario('Time limit exceeded!');
            }
          }
        });
        _checkObjectives();
      }
    });
  }

  void _setupTrainSpawning() {
    if (widget.scenario.trainSpawns.isEmpty) return;

    // Check for train spawns every second
    _trainSpawnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      final controller = context.read<TerminalStationController>();

      for (var spawn in widget.scenario.trainSpawns) {
        // Check if already spawned
        if (_spawnedTrains.contains(spawn.id)) continue;

        // Check if spawn delay has elapsed
        if (_elapsedTime.inSeconds >= spawn.spawnDelaySeconds) {
          _spawnTrain(spawn, controller);
          _spawnedTrains.add(spawn.id);
        }
      }
    });
  }

  void _spawnTrain(ScenarioTrainSpawn spawn, TerminalStationController controller) {
    // Map scenario train type to TrainType enum
    TrainType trainType;
    switch (spawn.trainType.toLowerCase()) {
      case 'm1':
        trainType = TrainType.m1;
        break;
      case 'm2':
        trainType = TrainType.m2;
        break;
      case 'm7':
        trainType = TrainType.m7;
        break;
      case 'm9':
        trainType = TrainType.m9;
        break;
      case 'freight':
        trainType = TrainType.freight;
        break;
      default:
        trainType = TrainType.m1;
    }

    // Find closest block to spawn position
    // This is a simplified approach - in production, you'd want more sophisticated block selection
    String? spawnBlock;
    double closestDistance = double.infinity;

    for (var block in controller.blocks.values) {
      final blockCenterX = (block.startX + block.endX) / 2;
      final distance = (blockCenterX - spawn.x).abs();

      if (distance < closestDistance && !block.isOccupied) {
        closestDistance = distance;
        spawnBlock = block.id;
      }
    }

    if (spawnBlock != null) {
      controller.addTrain(spawnBlock, trainType, destination: spawn.destination);
      debugPrint('🚂 Spawned ${spawn.trainType} train at $spawnBlock');
    }
  }

  void _checkObjectives() {
    if (_scenarioCompleted || _scenarioFailed) return;

    final controller = context.read<TerminalStationController>();
    bool allObjectivesComplete = true;
    int newScore = 0;

    for (var objective in widget.scenario.objectives) {
      bool isComplete = false;

      switch (objective.type) {
        case 'avoid_collision':
          // Check if any collisions occurred
          isComplete = !controller.collisionAlarmActive &&
                       controller.currentCollisionIncident == null;
          break;

        case 'deliver':
          // Check if specific trains reached destination
          final targetTrainCount = objective.parameters['train_count'] as int? ?? 1;
          final deliveredTrains = controller.trains
              .where((t) => t.hasReachedDestination)
              .length;
          _objectiveProgress[objective.id] = deliveredTrains;
          isComplete = deliveredTrains >= targetTrainCount;
          break;

        case 'time_limit':
          // Complete if within time limit
          final maxTime = objective.parameters['max_seconds'] as int? ?? 300;
          isComplete = _elapsedTime.inSeconds <= maxTime;
          break;

        case 'efficiency':
          // Check average delay or other efficiency metrics
          // This is a placeholder - actual implementation depends on metrics
          final maxDelay = objective.parameters['max_delay_seconds'] as int? ?? 60;
          isComplete = true; // Placeholder logic
          break;

        default:
          isComplete = false;
      }

      if (isComplete && !_objectiveCompletion[objective.id]!) {
        setState(() {
          _objectiveCompletion[objective.id] = true;
          _totalScore += objective.points;
        });
        debugPrint('✅ Objective completed: ${objective.description}');
      }

      if (!isComplete) {
        allObjectivesComplete = false;
      } else {
        newScore += objective.points;
      }
    }

    // Check if all objectives are complete
    if (allObjectivesComplete && widget.scenario.objectives.isNotEmpty) {
      _completeScenario();
    }
  }

  void _completeScenario() {
    if (_scenarioCompleted) return;

    setState(() {
      _scenarioCompleted = true;
      _completionMessage = 'Scenario Complete!';
    });

    _timeTimer?.cancel();
    _trainSpawnTimer?.cancel();

    // Show completion dialog
    _showCompletionDialog();
  }

  void _failScenario(String reason) {
    if (_scenarioFailed || _scenarioCompleted) return;

    setState(() {
      _scenarioFailed = true;
      _completionMessage = reason;
    });

    _timeTimer?.cancel();
    _trainSpawnTimer?.cancel();

    final controller = context.read<TerminalStationController>();
    if (controller.isRunning) {
      controller.toggleSimulation();
    }

    _showFailureDialog();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 32),
            SizedBox(width: 12),
            Text('Scenario Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Congratulations! You completed "${widget.scenario.name}"'),
            const SizedBox(height: 16),
            Text('Total Score: $_totalScore points',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Time: ${_formatDuration(_elapsedTime)}'),
            const SizedBox(height: 16),
            const Text('Objectives Completed:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...widget.scenario.objectives.map((obj) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Row(
                    children: [
                      Icon(
                        _objectiveCompletion[obj.id]!
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: _objectiveCompletion[obj.id]!
                            ? Colors.green
                            : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(obj.description)),
                    ],
                  ),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to marketplace/builder
            },
            child: Text(widget.isTestMode ? 'Return to Editor' : 'Return to Marketplace'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _loadScenario(); // Restart scenario
              _initializeObjectives();
              setState(() {
                _elapsedTime = Duration.zero;
                _totalScore = 0;
                _scenarioCompleted = false;
                _spawnedTrains.clear();
              });
              _startTimeTracking();
              _setupTrainSpawning();
            },
            child: Text(widget.isTestMode ? 'Test Again' : 'Play Again'),
          ),
        ],
      ),
    );
  }

  void _showFailureDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Scenario Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_completionMessage ?? 'Unknown failure reason'),
            const SizedBox(height: 16),
            Text('Score: $_totalScore points'),
            Text('Time: ${_formatDuration(_elapsedTime)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to marketplace/builder
            },
            child: Text(widget.isTestMode ? 'Return to Editor' : 'Return to Marketplace'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _loadScenario(); // Restart scenario
              _initializeObjectives();
              setState(() {
                _elapsedTime = Duration.zero;
                _totalScore = 0;
                _scenarioFailed = false;
                _spawnedTrains.clear();
              });
              _startTimeTracking();
              _setupTrainSpawning();
            },
            child: Text(widget.isTestMode ? 'Test Again' : 'Try Again'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Loading: ${widget.scenario.name}'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading scenario...'),
            ],
          ),
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to load scenario:'),
              Text(_loadError!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Return to Marketplace'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // The actual railway simulation
          const TerminalStationScreen(),

          // Scenario HUD overlay
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildScenarioHUD(),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioHUD() {
    return Card(
      color: Colors.black.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Scenario title and info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.scenario.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.isTestMode)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'TEST MODE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Time display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getTimeColor(),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDuration(_elapsedTime),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Score display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Score: $_totalScore',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Time limit warning
            if (widget.scenario.timeLimit != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Time Limit: ${_formatDuration(Duration(seconds: widget.scenario.timeLimit!))}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ),

            // Objectives list
            if (widget.scenario.objectives.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Objectives:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...widget.scenario.objectives.map((obj) {
                final isComplete = _objectiveCompletion[obj.id] ?? false;
                final progress = _objectiveProgress[obj.id] ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isComplete ? Colors.green : Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          obj.description,
                          style: TextStyle(
                            color: isComplete ? Colors.green : Colors.white,
                            fontSize: 13,
                            decoration: isComplete
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                      if (obj.type == 'deliver' && progress > 0)
                        Text(
                          '($progress)',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        '+${obj.points}',
                        style: TextStyle(
                          color: Colors.amber[700],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Color _getTimeColor() {
    if (widget.scenario.timeLimit == null) {
      return Colors.blue;
    }

    final remaining = widget.scenario.timeLimit! - _elapsedTime.inSeconds;
    final percentRemaining = remaining / widget.scenario.timeLimit!;

    if (percentRemaining > 0.5) {
      return Colors.green;
    } else if (percentRemaining > 0.25) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
