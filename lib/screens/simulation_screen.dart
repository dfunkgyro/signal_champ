import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

// ============================================================================
// DATA MODELS
// ============================================================================

class Train {
  final String id;
  final String name;
  double x;
  double y;
  double speed;
  double maxSpeed;
  Color color;
  bool isMoving;
  String? currentBlockId;
  String? targetPlatformId;
  bool atPlatform;
  int platformStopTime; // seconds
  bool hasStoppedAtSignal;
  
  Train({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    this.speed = 0,
    this.maxSpeed = 2.0,
    this.color = Colors.blue,
    this.isMoving = false,
    this.currentBlockId,
    this.targetPlatformId,
    this.atPlatform = false,
    this.platformStopTime = 0,
    this.hasStoppedAtSignal = false,
  });
}

class BlockSection {
  final String id;
  final double startX;
  final double endX;
  final double y;
  bool occupied;
  String? occupyingTrainId;
  bool isOverlapBlock; // For safety overlap protection
  
  BlockSection({
    required this.id,
    required this.startX,
    required this.endX,
    required this.y,
    this.occupied = false,
    this.occupyingTrainId,
    this.isOverlapBlock = false,
  });
  
  bool containsPosition(double x) {
    return x >= startX && x <= endX;
  }
}

class Signal {
  final String id;
  final double x;
  final double y;
  SignalAspect aspect;
  String protectsBlockId; // The block this signal protects
  String? overlapBlockId; // Overlap block for safety
  
  Signal({
    required this.id,
    required this.x,
    required this.y,
    this.aspect = SignalAspect.red,
    required this.protectsBlockId,
    this.overlapBlockId,
  });
}

enum SignalAspect {
  red,   // Stop - block ahead occupied
  green, // Proceed - block ahead clear
}

class Platform {
  final String id;
  final String name;
  final double startX;
  final double endX;
  final double y;
  bool occupied;
  String? occupyingTrainId;
  
  Platform({
    required this.id,
    required this.name,
    required this.startX,
    required this.endX,
    required this.y,
    this.occupied = false,
    this.occupyingTrainId,
  });
  
  double get centerX => (startX + endX) / 2;
  
  bool containsPosition(double x) {
    return x >= startX && x <= endX;
  }
}

// ============================================================================
// SIMULATION CONTROLLER WITH PROPER SIGNALLING
// ============================================================================

class RailwaySimulationController extends ChangeNotifier {
  final List<Train> trains = [];
  final List<BlockSection> blocks = [];
  final List<Signal> signals = [];
  final List<Platform> platforms = [];
  
  bool isRunning = false;
  double simulationSpeed = 1.0;
  int simulationTime = 0; // in ticks
  
  // Track layout constants
  static const double trackY = 300;
  static const double blockLength = 200;
  static const double overlapLength = 50;
  static const double platformLength = 150;
  static const double signalDistance = 30; // Distance before block
  
  RailwaySimulationController() {
    _initializeRailwayLayout();
  }
  
  void _initializeRailwayLayout() {
    // Create a longer track with 12 main blocks + overlap blocks
    // Layout: Platform1 - Blocks - Station - Blocks - Platform2
    
    double currentX = 100;
    
    // ===== PLATFORM 1 (WESTBOUND TERMINUS) =====
    platforms.add(Platform(
      id: 'P1',
      name: 'Platform 1 (Westbound)',
      startX: currentX,
      endX: currentX + platformLength,
      y: trackY,
    ));
    currentX += platformLength + 20;
    
    // ===== MAIN LINE BLOCKS (1-5) =====
    for (int i = 1; i <= 5; i++) {
      // Main block
      blocks.add(BlockSection(
        id: 'B$i',
        startX: currentX,
        endX: currentX + blockLength,
        y: trackY,
      ));
      
      // Signal protecting this block
      signals.add(Signal(
        id: 'S$i',
        x: currentX - signalDistance,
        y: trackY - 10,
        protectsBlockId: 'B$i',
        overlapBlockId: 'OL$i',
      ));
      
      currentX += blockLength;
      
      // Overlap block after main block
      blocks.add(BlockSection(
        id: 'OL$i',
        startX: currentX,
        endX: currentX + overlapLength,
        y: trackY,
        isOverlapBlock: true,
      ));
      
      currentX += overlapLength + 10;
    }
    
    // ===== STATION (PLATFORM 2 - CENTRAL STATION) =====
    platforms.add(Platform(
      id: 'P2',
      name: 'Central Station',
      startX: currentX,
      endX: currentX + platformLength,
      y: trackY,
    ));
    
    // Signal before station
    signals.add(Signal(
      id: 'S_STATION',
      x: currentX - signalDistance,
      y: trackY - 10,
      protectsBlockId: 'B_STATION',
    ));
    
    // Station block
    blocks.add(BlockSection(
      id: 'B_STATION',
      startX: currentX,
      endX: currentX + platformLength,
      y: trackY,
    ));
    
    currentX += platformLength + 20;
    
    // ===== MAIN LINE BLOCKS (6-10) =====
    for (int i = 6; i <= 10; i++) {
      // Main block
      blocks.add(BlockSection(
        id: 'B$i',
        startX: currentX,
        endX: currentX + blockLength,
        y: trackY,
      ));
      
      // Signal protecting this block
      signals.add(Signal(
        id: 'S$i',
        x: currentX - signalDistance,
        y: trackY - 10,
        protectsBlockId: 'B$i',
        overlapBlockId: 'OL$i',
      ));
      
      currentX += blockLength;
      
      // Overlap block
      blocks.add(BlockSection(
        id: 'OL$i',
        startX: currentX,
        endX: currentX + overlapLength,
        y: trackY,
        isOverlapBlock: true,
      ));
      
      currentX += overlapLength + 10;
    }
    
    // ===== PLATFORM 3 (EASTBOUND TERMINUS) =====
    platforms.add(Platform(
      id: 'P3',
      name: 'Platform 3 (Eastbound)',
      startX: currentX,
      endX: currentX + platformLength,
      y: trackY,
    ));
    
    // Signal before terminus
    signals.add(Signal(
      id: 'S_TERMINUS',
      x: currentX - signalDistance,
      y: trackY - 10,
      protectsBlockId: 'B_TERMINUS',
    ));
    
    // Terminus block
    blocks.add(BlockSection(
      id: 'B_TERMINUS',
      startX: currentX,
      endX: currentX + platformLength,
      y: trackY,
    ));
    
    // Initialize all signals to red (safe state)
    for (var signal in signals) {
      signal.aspect = SignalAspect.red;
    }
  }
  
  void addTrain({String? startPlatformId}) {
    startPlatformId ??= 'P1'; // Default to Platform 1
    
    final platform = platforms.firstWhere((p) => p.id == startPlatformId);
    
    trains.add(Train(
      id: 'T${trains.length + 1}',
      name: 'Train ${trains.length + 1}',
      x: platform.centerX,
      y: trackY,
      speed: 0,
      maxSpeed: 2.0 + (trains.length * 0.2), // Vary speeds slightly
      color: Colors.primaries[trains.length % Colors.primaries.length],
      targetPlatformId: startPlatformId == 'P1' ? 'P3' : 'P1', // Go to opposite end
      atPlatform: true,
    ));
    
    platform.occupied = true;
    platform.occupyingTrainId = 'T${trains.length}';
    
    // Update block occupation
    _updateBlockOccupation();
    notifyListeners();
  }
  
  void removeTrain(String id) {
    final train = trains.firstWhere((t) => t.id == id);
    
    // Clear platform if train is on one
    for (var platform in platforms) {
      if (platform.occupyingTrainId == train.id) {
        platform.occupied = false;
        platform.occupyingTrainId = null;
      }
    }
    
    trains.removeWhere((t) => t.id == id);
    _updateBlockOccupation();
    _updateSignalAspects();
    notifyListeners();
  }
  
  void startSimulation() {
    isRunning = true;
    
    // Depart all trains from platforms
    for (var train in trains) {
      if (train.atPlatform) {
        train.atPlatform = false;
        train.isMoving = true;
        train.platformStopTime = 0;
        
        // Clear platform
        for (var platform in platforms) {
          if (platform.occupyingTrainId == train.id) {
            platform.occupied = false;
            platform.occupyingTrainId = null;
          }
        }
      }
    }
    
    notifyListeners();
  }
  
  void pauseSimulation() {
    isRunning = false;
    notifyListeners();
  }
  
  void resetSimulation() {
    trains.clear();
    isRunning = false;
    simulationTime = 0;
    
    // Reset all blocks
    for (var block in blocks) {
      block.occupied = false;
      block.occupyingTrainId = null;
    }
    
    // Reset all platforms
    for (var platform in platforms) {
      platform.occupied = false;
      platform.occupyingTrainId = null;
    }
    
    // Reset all signals to red
    for (var signal in signals) {
      signal.aspect = SignalAspect.red;
    }
    
    notifyListeners();
  }
  
  void setSimulationSpeed(double speed) {
    simulationSpeed = speed;
    notifyListeners();
  }
  
  void updateSimulation() {
    if (!isRunning) return;
    
    simulationTime++;
    
    for (var train in trains) {
      if (!train.isMoving && !train.atPlatform) continue;
      
      // Check signal ahead
      final signalAhead = _getSignalAhead(train);
      final canProceed = _canTrainProceed(train, signalAhead);
      
      if (canProceed) {
        // Accelerate or maintain speed
        if (train.speed < train.maxSpeed) {
          train.speed = math.min(train.speed + 0.05, train.maxSpeed);
        }
        
        // Move train
        train.x += train.speed * simulationSpeed;
        train.hasStoppedAtSignal = false;
      } else {
        // Decelerate to stop at red signal
        if (train.speed > 0) {
          train.speed = math.max(train.speed - 0.1, 0);
          train.x += train.speed * simulationSpeed;
        } else {
          train.hasStoppedAtSignal = true;
        }
      }
      
      // Check if train reached target platform
      if (train.targetPlatformId != null) {
        final platform = platforms.firstWhere((p) => p.id == train.targetPlatformId);
        
        if (platform.containsPosition(train.x) && !train.atPlatform) {
          // Arrive at platform
          train.atPlatform = true;
          train.isMoving = false;
          train.speed = 0;
          train.x = platform.centerX; // Snap to center
          train.platformStopTime = 180; // Stop for 3 seconds (at 60 ticks/sec)
          
          platform.occupied = true;
          platform.occupyingTrainId = train.id;
          
          // Switch target to opposite platform
          if (train.targetPlatformId == 'P1') {
            train.targetPlatformId = 'P3';
          } else if (train.targetPlatformId == 'P3') {
            train.targetPlatformId = 'P1';
          } else {
            // At central station, continue in same direction
            train.targetPlatformId = train.targetPlatformId == 'P2' ? 'P3' : 'P2';
          }
        }
      }
      
      // Handle platform stop time
      if (train.atPlatform) {
        train.platformStopTime--;
        if (train.platformStopTime <= 0) {
          // Depart from platform
          train.atPlatform = false;
          train.isMoving = true;
          
          // Clear platform
          for (var platform in platforms) {
            if (platform.occupyingTrainId == train.id) {
              platform.occupied = false;
              platform.occupyingTrainId = null;
            }
          }
        }
      }
      
      // Wrap around at track ends (for testing)
      if (train.x > 3500) {
        train.x = 100;
        train.targetPlatformId = 'P3';
      }
    }
    
    // Update track circuits (block occupation detection)
    _updateBlockOccupation();
    
    // Update signal aspects based on block occupation
    _updateSignalAspects();
    
    notifyListeners();
  }
  
  void _updateBlockOccupation() {
    // Clear all blocks first
    for (var block in blocks) {
      block.occupied = false;
      block.occupyingTrainId = null;
    }
    
    // Detect train presence in each block (track circuit simulation)
    for (var train in trains) {
      for (var block in blocks) {
        if (block.containsPosition(train.x)) {
          block.occupied = true;
          block.occupyingTrainId = train.id;
          train.currentBlockId = block.id;
        }
      }
    }
  }
  
  void _updateSignalAspects() {
    // Implement two-aspect fixed block signalling logic
    for (var signal in signals) {
      final protectedBlock = blocks.firstWhere(
        (b) => b.id == signal.protectsBlockId,
        orElse: () => blocks.first,
      );
      
      // Check overlap block if it exists
      BlockSection? overlapBlock;
      if (signal.overlapBlockId != null) {
        overlapBlock = blocks.firstWhere(
          (b) => b.id == signal.overlapBlockId,
          orElse: () => blocks.first,
        );
      }
      
      // Signal logic: Show green only if protected block AND overlap are clear
      if (!protectedBlock.occupied && (overlapBlock == null || !overlapBlock.occupied)) {
        signal.aspect = SignalAspect.green;
      } else {
        signal.aspect = SignalAspect.red;
      }
    }
  }
  
  Signal? _getSignalAhead(Train train) {
    // Find the next signal in front of the train
    Signal? nearestSignal;
    double minDistance = double.infinity;
    
    for (var signal in signals) {
      if (signal.x > train.x) {
        final distance = signal.x - train.x;
        if (distance < minDistance) {
          minDistance = distance;
          nearestSignal = signal;
        }
      }
    }
    
    return nearestSignal;
  }
  
  bool _canTrainProceed(Train train, Signal? signalAhead) {
    if (signalAhead == null) return true; // No signal ahead, can proceed
    
    // Calculate stopping distance
    const double stoppingDistance = 80.0; // Safety margin
    final distanceToSignal = signalAhead.x - train.x;
    
    // If signal is red and train is approaching
    if (signalAhead.aspect == SignalAspect.red) {
      // Must stop if within stopping distance
      if (distanceToSignal <= stoppingDistance) {
        return false;
      }
      // Can continue if far enough to stop
      return distanceToSignal > stoppingDistance;
    }
    
    // Green signal - can proceed
    return true;
  }
  
  Map<String, dynamic> getSimulationStats() {
    return {
      'total_trains': trains.length,
      'moving_trains': trains.where((t) => t.isMoving).length,
      'trains_at_platforms': trains.where((t) => t.atPlatform).length,
      'occupied_blocks': blocks.where((b) => b.occupied && !b.isOverlapBlock).length,
      'total_blocks': blocks.where((b) => !b.isOverlapBlock).length,
      'green_signals': signals.where((s) => s.aspect == SignalAspect.green).length,
      'total_signals': signals.length,
      'simulation_time': simulationTime,
    };
  }
}

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
  double _cameraOffsetY = 0;
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
                    _cameraOffsetY = 0;
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
                _cameraOffsetY += details.delta.dy / _zoom;
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
                cameraOffsetY: _cameraOffsetY,
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

// ============================================================================
// RAILWAY PAINTER - RENDERS THE TRACK LAYOUT
// ============================================================================

class RailwayPainter extends CustomPainter {
  final List<Train> trains;
  final List<BlockSection> blocks;
  final List<Signal> signals;
  final List<Platform> platforms;
  final double cameraOffsetX;
  final double cameraOffsetY;
  final double zoom;

  RailwayPainter({
    required this.trains,
    required this.blocks,
    required this.signals,
    required this.platforms,
    required this.cameraOffsetX,
    required this.cameraOffsetY,
    required this.zoom,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    
    // Apply camera transform
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(zoom);
    canvas.translate(cameraOffsetX, cameraOffsetY);
    
    // Draw platforms first (yellow base layer)
    _drawPlatforms(canvas);
    
    // Draw blocks (track sections)
    _drawBlocks(canvas);
    
    // Draw signals
    _drawSignals(canvas);
    
    // Draw trains
    _drawTrains(canvas);
    
    // Draw labels
    _drawLabels(canvas);
    
    canvas.restore();
  }
  
  void _drawPlatforms(Canvas canvas) {
    for (var platform in platforms) {
      // Platform base (yellow)
      final platformPaint = Paint()
        ..color = Colors.yellow[700]!
        ..style = PaintingStyle.fill;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            platform.startX,
            platform.y - 25,
            platform.endX - platform.startX,
            50,
          ),
          const Radius.circular(8),
        ),
        platformPaint,
      );
      
      // Platform edge
      final edgePaint = Paint()
        ..color = Colors.amber[900]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            platform.startX,
            platform.y - 25,
            platform.endX - platform.startX,
            50,
          ),
          const Radius.circular(8),
        ),
        edgePaint,
      );
      
      // Platform tactile strips (safety markings)
      final stripPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 2;
      
      for (double x = platform.startX + 10; x < platform.endX; x += 20) {
        canvas.drawLine(
          Offset(x, platform.y - 20),
          Offset(x, platform.y - 25),
          stripPaint,
        );
        canvas.drawLine(
          Offset(x, platform.y + 20),
          Offset(x, platform.y + 25),
          stripPaint,
        );
      }
    }
  }
  
  void _drawBlocks(Canvas canvas) {
    for (var block in blocks) {
      // Block base
      final blockPaint = Paint()
        ..color = block.occupied
            ? (block.isOverlapBlock ? Colors.orange.withOpacity(0.3) : Colors.red.withOpacity(0.3))
            : Colors.grey[300]!
        ..style = PaintingStyle.fill;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            block.startX,
            block.y - 15,
            block.endX - block.startX,
            30,
          ),
          const Radius.circular(4),
        ),
        blockPaint,
      );
      
      // Block outline
      final outlinePaint = Paint()
        ..color = block.isOverlapBlock ? Colors.orange : Colors.grey[600]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = block.isOverlapBlock ? 2 : 1;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            block.startX,
            block.y - 15,
            block.endX - block.startX,
            30,
          ),
          const Radius.circular(4),
        ),
        outlinePaint,
      );
      
      // Rails
      final railPaint = Paint()
        ..color = Colors.grey[700]!
        ..strokeWidth = 3;
      
      canvas.drawLine(
        Offset(block.startX, block.y - 8),
        Offset(block.endX, block.y - 8),
        railPaint,
      );
      
      canvas.drawLine(
        Offset(block.startX, block.y + 8),
        Offset(block.endX, block.y + 8),
        railPaint,
      );
      
      // Sleepers (ties)
      final sleeperPaint = Paint()
        ..color = Colors.brown[700]!
        ..strokeWidth = 6;
      
      for (double x = block.startX; x < block.endX; x += 15) {
        canvas.drawLine(
          Offset(x, block.y - 12),
          Offset(x, block.y + 12),
          sleeperPaint,
        );
      }
    }
  }
  
  void _drawSignals(Canvas canvas) {
    for (var signal in signals) {
      // Signal pole
      final polePaint = Paint()
        ..color = Colors.grey[800]!
        ..strokeWidth = 5;
      
      canvas.drawLine(
        Offset(signal.x, signal.y),
        Offset(signal.x, signal.y - 50),
        polePaint,
      );
      
      // Signal head (casing)
      final headPaint = Paint()
        ..color = Colors.grey[900]!
        ..style = PaintingStyle.fill;
      
      canvas.drawRect(
        Rect.fromLTWH(signal.x - 12, signal.y - 65, 24, 30),
        headPaint,
      );
      
      // Signal light
      final lightColor = signal.aspect == SignalAspect.green
          ? Colors.green
          : Colors.red;
      
      final lightPaint = Paint()
        ..color = lightColor
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(signal.x, signal.y - 50),
        10,
        lightPaint,
      );
      
      // Glow effect
      if (signal.aspect == SignalAspect.green) {
        final glowPaint = Paint()
          ..color = Colors.green.withOpacity(0.4)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        
        canvas.drawCircle(
          Offset(signal.x, signal.y - 50),
          15,
          glowPaint,
        );
      }
      
      // Light outline
      final outlinePaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawCircle(
        Offset(signal.x, signal.y - 50),
        10,
        outlinePaint,
      );
    }
  }
  
  void _drawTrains(Canvas canvas) {
    for (var train in trains) {
      // Train body
      final bodyPaint = Paint()
        ..color = train.color
        ..style = PaintingStyle.fill;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(train.x - 25, train.y - 14, 50, 28),
          const Radius.circular(6),
        ),
        bodyPaint,
      );
      
      // Train outline
      final outlinePaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(train.x - 25, train.y - 14, 50, 28),
          const Radius.circular(6),
        ),
        outlinePaint,
      );
      
      // Windows
      final windowPaint = Paint()
        ..color = Colors.lightBlue[100]!
        ..style = PaintingStyle.fill;
      
      canvas.drawRect(Rect.fromLTWH(train.x - 20, train.y - 10, 10, 8), windowPaint);
      canvas.drawRect(Rect.fromLTWH(train.x - 5, train.y - 10, 10, 8), windowPaint);
      canvas.drawRect(Rect.fromLTWH(train.x + 10, train.y - 10, 10, 8), windowPaint);
      
      // Wheels
      final wheelPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(train.x - 15, train.y + 14), 6, wheelPaint);
      canvas.drawCircle(Offset(train.x + 15, train.y + 14), 6, wheelPaint);
      
      // Direction indicator (if moving)
      if (train.isMoving && train.speed > 0) {
        final arrowPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        
        final path = Path()
          ..moveTo(train.x + 20, train.y)
          ..lineTo(train.x + 28, train.y)
          ..moveTo(train.x + 28, train.y)
          ..lineTo(train.x + 24, train.y - 4)
          ..moveTo(train.x + 28, train.y)
          ..lineTo(train.x + 24, train.y + 4);
        
        canvas.drawPath(path, arrowPaint);
      }
      
      // Status indicator
      if (train.atPlatform) {
        final stopPaint = Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(Offset(train.x - 20, train.y - 20), 4, stopPaint);
      } else if (train.hasStoppedAtSignal) {
        final waitPaint = Paint()
          ..color = Colors.orange
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(Offset(train.x - 20, train.y - 20), 4, waitPaint);
      }
    }
  }
  
  void _drawLabels(Canvas canvas) {
    // Draw platform labels
    for (var platform in platforms) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: platform.name,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          platform.centerX - textPainter.width / 2,
          platform.y + 35,
        ),
      );
    }
    
    // Draw block labels
    for (var block in blocks) {
      if (!block.isOverlapBlock) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: block.id,
            style: TextStyle(
              color: block.occupied ? Colors.red[700] : Colors.grey[700],
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            (block.startX + block.endX) / 2 - textPainter.width / 2,
            block.y - 35,
          ),
        );
      }
    }
    
    // Draw signal labels
    for (var signal in signals) {
      final aspectText = signal.aspect == SignalAspect.green ? 'G' : 'R';
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${signal.id}\n$aspectText',
          style: TextStyle(
            color: signal.aspect == SignalAspect.green
                ? Colors.green[700]
                : Colors.red[700],
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          signal.x - textPainter.width / 2,
          signal.y - 85,
        ),
      );
    }
    
    // Draw train labels
    for (var train in trains) {
      final statusText = train.atPlatform
          ? 'PLATFORM'
          : train.hasStoppedAtSignal
              ? 'SIGNAL'
              : '${train.speed.toStringAsFixed(1)} km/h';
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${train.name}\n$statusText',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          train.x - textPainter.width / 2,
          train.y - 35,
        ),
      );
    }
  }
  
  @override
  bool shouldRepaint(RailwayPainter oldDelegate) => true;
}
