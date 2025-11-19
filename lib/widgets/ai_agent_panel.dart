import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/terminal_station_controller.dart';
import '../screens/terminal_station_models.dart';
import '../services/openai_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Floating Signalling System Manager panel for natural language railway control
/// (formerly known as AI Agent)
class AIAgentPanel extends StatefulWidget {
  const AIAgentPanel({Key? key}) : super(key: key);

  @override
  State<AIAgentPanel> createState() => _AIAgentPanelState();
}

class _AIAgentPanelState extends State<AIAgentPanel> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final List<String> _commandHistory = [];
  int _historyIndex = -1;
  OpenAIService? _openAIService;
  bool _isProcessing = false;
  Map<String, dynamic>? _pendingCommand; // Store incomplete command for confirmation
  final FocusNode _inputFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeOpenAI();
    _addMessage('Signalling Manager', 'Hello! I am the Signalling System Manager. I can help you control the railway. Try commands like:\n• "Set route L01 to route 1"\n• "Swing point 76A"\n• "Add M1 train to block 100"', isAI: true);
  }

  void _initializeOpenAI() {
    try {
      final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        _addMessage('System', 'ℹ️ OpenAI API key not found. Using local command processing only.\n\nTo enable AI features, create assets/.env file with:\nOPENAI_API_KEY=your_key_here', isAI: true);
        return;
      }

      if (apiKey == 'your_api_key_here' || apiKey == 'sk-') {
        _addMessage('System', '⚠️ Invalid API key format. Please update assets/.env file with a valid OpenAI API key.', isAI: true);
        return;
      }

      _openAIService = OpenAIService(
        apiKey: apiKey,
        model: dotenv.env['OPENAI_MODEL'] ?? 'gpt-3.5-turbo',
      );

      debugPrint('✅ OpenAI service initialized with model: ${dotenv.env['OPENAI_MODEL'] ?? 'gpt-3.5-turbo'}');
    } catch (e) {
      _addMessage('System', '❌ Error initializing OpenAI: ${e.toString()}\n\nFalling back to local command processing.', isAI: true);
      debugPrint('OpenAI initialization error: $e');
    }
  }

  void _addMessage(String sender, String text, {bool isAI = false}) {
    setState(() {
      _messages.add(ChatMessage(sender: sender, text: text, isAI: isAI));
    });

    // Only auto-scroll if the setting is enabled
    final controller = Provider.of<TerminalStationController>(context, listen: false);
    if (controller.signallingSystemManagerAutoScroll) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients && mounted) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  /// Navigate command history with up/down arrows
  void _navigateHistory(bool up) {
    if (_commandHistory.isEmpty) return;

    setState(() {
      if (up) {
        if (_historyIndex < _commandHistory.length - 1) {
          _historyIndex++;
          _inputController.text = _commandHistory[_commandHistory.length - 1 - _historyIndex];
          _inputController.selection = TextSelection.fromPosition(
            TextPosition(offset: _inputController.text.length),
          );
        }
      } else {
        if (_historyIndex > 0) {
          _historyIndex--;
          _inputController.text = _commandHistory[_commandHistory.length - 1 - _historyIndex];
          _inputController.selection = TextSelection.fromPosition(
            TextPosition(offset: _inputController.text.length),
          );
        } else if (_historyIndex == 0) {
          _historyIndex = -1;
          _inputController.clear();
        }
      }
    });
  }

  /// Clear chat history
  void _clearChat() {
    setState(() {
      _messages.clear();
      _addMessage('System', '🗑️ Chat history cleared.', isAI: true);
    });
  }

  Future<void> _processCommand(TerminalStationController controller) async {
    final input = _inputController.text.trim();
    if (input.isEmpty) return;

    // Add to command history
    if (input != _commandHistory.lastOrNull) {
      _commandHistory.add(input);
      if (_commandHistory.length > 50) {
        _commandHistory.removeAt(0); // Keep max 50 commands
      }
    }
    _historyIndex = -1;

    _addMessage('You', input);
    _inputController.clear();

    setState(() => _isProcessing = true);

    // Check if we're waiting for confirmation on a pending command
    if (_pendingCommand != null) {
      if (input.toLowerCase() == 'yes' || input.toLowerCase() == 'y') {
        // Execute the pending command
        _executePendingCommand(controller);
        _pendingCommand = null;
      } else {
        // Cancel the pending command
        _addMessage('AI Agent', '❌ Command cancelled.', isAI: true);
        _pendingCommand = null;
      }
      setState(() => _isProcessing = false);
      return;
    }

    if (_openAIService == null) {
      // Fallback: Simple pattern matching with extrapolation
      _processLocalCommand(input, controller);
    } else {
      // Use OpenAI for natural language processing with timeout
      try {
        final command = await _openAIService!.parseRailwayCommand(input).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            _addMessage('AI Agent', '⏱️ Request timed out. Falling back to local processing...', isAI: true);
            _processLocalCommand(input, controller);
            return null;
          },
        );

        if (command != null) {
          _executeCommand(command, controller);
        } else {
          // Fallback to local command processing if OpenAI couldn't parse
          _processLocalCommand(input, controller);
        }
      } catch (e) {
        _addMessage('AI Agent', '❌ API Error: ${e.toString()}\n\nFalling back to local processing...', isAI: true);
        _processLocalCommand(input, controller);
      }
    }

    setState(() => _isProcessing = false);
  }

  void _executePendingCommand(TerminalStationController controller) {
    if (_pendingCommand == null) return;

    final action = _pendingCommand!['action'] as String;
    switch (action) {
      case 'set_route':
        final signalId = _pendingCommand!['signal_id'] as String;
        final routeId = _pendingCommand!['route_id'] as String;
        controller.setRoute(signalId, routeId);
        _addMessage('AI Agent', '✅ Route $routeId set for signal $signalId', isAI: true);
        break;

      case 'swing_point':
        final pointId = _pendingCommand!['point_id'] as String;
        controller.swingPoint(pointId);
        _addMessage('AI Agent', '✅ Point $pointId swung', isAI: true);
        break;

      case 'add_train':
        final blockId = _pendingCommand!['block_id'] as String;
        final trainType = _pendingCommand!['train_type'] as TrainType;
        controller.addTrainToBlock(blockId, trainType: trainType);
        _addMessage('AI Agent', '✅ ${trainType.name.toUpperCase()} train added to block $blockId', isAI: true);
        break;

      case 'set_destination':
        final trainId = _pendingCommand!['train_id'] as String;
        final blockId = _pendingCommand!['block_id'] as String;
        controller.setTrainDestination(trainId, 'B:$blockId');
        _addMessage('AI Agent', '✅ Train $trainId destination set to block $blockId', isAI: true);
        break;
    }
  }

  void _processLocalCommand(String input, TerminalStationController controller) {
    final lower = input.toLowerCase();

    // Cancel route pattern
    if (lower.contains('cancel') && lower.contains('route')) {
      final signalMatch = RegExp(r'([lcr]\d+)', caseSensitive: false).firstMatch(input);
      if (signalMatch != null) {
        final signalId = signalMatch.group(1)!.toUpperCase();
        controller.cancelRoute(signalId);
        _addMessage('AI Agent', '✅ Route cancelled for signal $signalId', isAI: true);
      } else {
        _addMessage('AI Agent', '⚠️ Please specify signal ID (e.g., "cancel route L01")', isAI: true);
      }
      return;
    }

    // Set route pattern - enhanced to handle various formats
    if (lower.contains('set') && lower.contains('route') ||
        lower.contains('route') && lower.contains('to') ||
        lower.contains('set signal')) {
      final signalMatch = RegExp(r'([lcr]\d+)', caseSensitive: false).firstMatch(input);
      if (signalMatch != null) {
        final signalId = signalMatch.group(1)!.toUpperCase();
        final signal = controller.signals[signalId];

        if (signal != null && signal.routes.isNotEmpty) {
          // Try to parse specific route number
          final routeNumMatch = RegExp(r'route\s*(\d+)', caseSensitive: false).firstMatch(input);
          String routeId;

          if (routeNumMatch != null) {
            final routeNum = routeNumMatch.group(1);
            routeId = '${signalId}_R$routeNum';
          } else {
            routeId = signal.routes.first.id;
          }

          controller.setRoute(signalId, routeId);
          _addMessage('AI Agent', '✅ Route $routeId set for signal $signalId', isAI: true);
        } else {
          _addMessage('AI Agent', '⚠️ Signal $signalId not found', isAI: true);
        }
      } else {
        _addMessage('AI Agent', '⚠️ Please specify signal ID (e.g., "set route L01")', isAI: true);
      }
      return;
    }

    // Swing/throw point pattern - enhanced
    if (lower.contains('swing') || lower.contains('throw') ||
        (lower.contains('point') && (lower.contains('normal') || lower.contains('reverse')))) {
      final pointMatch = RegExp(r'(\d+[ab])', caseSensitive: false).firstMatch(input);
      if (pointMatch != null) {
        final pointId = pointMatch.group(1)!.toUpperCase();
        if (controller.points.containsKey(pointId)) {
          controller.swingPoint(pointId);
          _addMessage('AI Agent', '✅ Point $pointId swung', isAI: true);
        } else {
          _addMessage('AI Agent', '⚠️ Point $pointId not found', isAI: true);
        }
      } else {
        _addMessage('AI Agent', '⚠️ Please specify point ID (e.g., "swing point 76A")', isAI: true);
      }
      return;
    }

    // Add train pattern - enhanced with train type support
    if (lower.contains('add') && lower.contains('train')) {
      final blockMatch = RegExp(r'block\s*(\d+)', caseSensitive: false).firstMatch(input);
      TrainType trainType = TrainType.m1; // Default

      // Parse train type
      if (lower.contains('m2') || lower.contains('double')) {
        trainType = TrainType.m2;
      } else if (lower.contains('cbtc m1') || lower.contains('cbtc-m1')) {
        trainType = TrainType.cbtcM1;
      } else if (lower.contains('cbtc m2') || lower.contains('cbtc-m2')) {
        trainType = TrainType.cbtcM2;
      }

      if (blockMatch != null) {
        final blockId = blockMatch.group(1)!;
        controller.addTrainToBlock(blockId, trainType: trainType);
        _addMessage('AI Agent', '✅ ${trainType.name.toUpperCase()} train added to block $blockId', isAI: true);
      } else {
        controller.addTrain();
        _addMessage('AI Agent', '✅ Train added to default safe block', isAI: true);
      }
      return;
    }

    // Remove train pattern
    if (lower.contains('remove') && lower.contains('train')) {
      final trainMatch = RegExp(r'train\s*(\d+)', caseSensitive: false).firstMatch(input);
      if (trainMatch != null) {
        final trainId = trainMatch.group(1)!;
        controller.removeTrain(trainId);
        _addMessage('AI Agent', '✅ Train $trainId removed', isAI: true);
      } else {
        _addMessage('AI Agent', '⚠️ Please specify train ID (e.g., "remove train 1")', isAI: true);
      }
      return;
    }

    // Set train destination
    if (lower.contains('set') && lower.contains('destination') ||
        lower.contains('destination') && lower.contains('to')) {
      final trainMatch = RegExp(r'train\s*(\d+)', caseSensitive: false).firstMatch(input);
      final blockMatch = RegExp(r'block\s*(\d+)', caseSensitive: false).firstMatch(input);

      if (trainMatch != null && blockMatch != null) {
        final trainId = trainMatch.group(1)!;
        final blockId = blockMatch.group(1)!;
        controller.setTrainDestination(trainId, 'B:$blockId');
        _addMessage('AI Agent', '✅ Train $trainId destination set to block $blockId', isAI: true);
      } else {
        _addMessage('AI Agent', '⚠️ Please specify train ID and destination block (e.g., "set train 1 destination to block 110")', isAI: true);
      }
      return;
    }

    // CBTC mode - enhanced
    if (lower.contains('cbtc')) {
      final enable = lower.contains('enable') || lower.contains('on') ||
                     lower.contains('activate') || lower.contains('start');

      // First enable CBTC devices if not already enabled
      if (enable && !controller.cbtcDevicesEnabled) {
        controller.toggleCbtcDevices(true);
      }

      controller.toggleCbtcMode(enable);
      _addMessage('AI Agent', '✅ CBTC mode ${enable ? "enabled" : "disabled"}', isAI: true);
      return;
    }

    // Depart train
    if (lower.contains('depart') && lower.contains('train')) {
      final trainMatch = RegExp(r'train\s*(\d+)', caseSensitive: false).firstMatch(input);
      if (trainMatch != null) {
        final trainId = trainMatch.group(1)!;
        controller.departTrain(trainId);
        _addMessage('AI Agent', '✅ Train $trainId departing', isAI: true);
      } else {
        _addMessage('AI Agent', '⚠️ Please specify train ID (e.g., "depart train 1")', isAI: true);
      }
      return;
    }

    // Emergency brake
    if (lower.contains('emergency') || lower.contains('stop all')) {
      controller.emergencyBrakeAll();
      _addMessage('AI Agent', '🚨 Emergency brake applied to all trains', isAI: true);
      return;
    }

    // Help command
    if (lower.contains('help') || lower.contains('what can you do')) {
      _addMessage('AI Agent', '''🤖 Available Commands:

📍 Routes & Signals:
• "set route [signal]" or "set signal L01 to route 1"
• "cancel route [signal]"

🔀 Points:
• "swing point [id]" or "throw point 76A"

🚂 Trains:
• "add train to block [id]" or "add M2 train to block 100"
• "add CBTC M1 train to block 100"
• "remove train [id]"
• "set train [id] destination to block [id]"
• "depart train [id]"

🚄 CBTC:
• "enable CBTC" or "activate CBTC mode"
• "disable CBTC" or "turn off CBTC"

🚨 Safety:
• "emergency brake" or "stop all trains"

Examples:
• "Set route L01"
• "Swing point 76A"
• "Add CBTC M1 train to block 100"
• "Set train 1 destination to block 110"
• "Enable CBTC mode"
''', isAI: true);
      return;
    }

    // Search and pan commands
    if (lower.contains('find') || lower.contains('search') || lower.contains('locate')) {
      final trainMatch = RegExp(r'train\s*(\d+)', caseSensitive: false).firstMatch(input);
      final signalMatch = RegExp(r'signal\s*([lcr]\d+)', caseSensitive: false).firstMatch(input);
      final blockMatch = RegExp(r'block\s*(\d+)', caseSensitive: false).firstMatch(input);
      final pointMatch = RegExp(r'point\s*(\d+[ab])', caseSensitive: false).firstMatch(input);

      if (trainMatch != null) {
        final trainId = trainMatch.group(1)!;
        final train = controller.trains.where((t) => t.id == trainId).firstOrNull;
        if (train != null) {
          controller.panToPosition(train.x, train.y, zoom: 1.2);
          controller.highlightItem(trainId, 'train');
          _addMessage('AI Agent', '🔍 Found Train $trainId at position (${train.x.toInt()}, ${train.y.toInt()})', isAI: true);
        } else {
          _addMessage('AI Agent', '❌ Train $trainId not found', isAI: true);
        }
      } else if (signalMatch != null) {
        final signalId = signalMatch.group(1)!.toUpperCase();
        final signal = controller.signals[signalId];
        if (signal != null) {
          controller.panToPosition(signal.x, signal.y, zoom: 1.5);
          controller.highlightItem(signalId, 'signal');
          _addMessage('AI Agent', '🔍 Found Signal $signalId (${signal.aspect.name})', isAI: true);
        } else {
          _addMessage('AI Agent', '❌ Signal $signalId not found', isAI: true);
        }
      } else if (blockMatch != null) {
        final blockId = blockMatch.group(1)!;
        final block = controller.blocks[blockId];
        if (block != null) {
          final centerX = (block.startX + block.endX) / 2;
          controller.panToPosition(centerX, block.y, zoom: 1.2);
          controller.highlightItem(blockId, 'block');
          _addMessage('AI Agent', '🔍 Found Block $blockId (${block.occupied ? "Occupied" : "Clear"})', isAI: true);
        } else {
          _addMessage('AI Agent', '❌ Block $blockId not found', isAI: true);
        }
      } else if (pointMatch != null) {
        final pointId = pointMatch.group(1)!.toUpperCase();
        final point = controller.points[pointId];
        if (point != null) {
          controller.panToPosition(point.x, point.y, zoom: 1.5);
          controller.highlightItem(pointId, 'point');
          _addMessage('AI Agent', '🔍 Found Point $pointId (${point.position == PointPosition.normal ? "Normal" : "Reverse"})', isAI: true);
        } else {
          _addMessage('AI Agent', '❌ Point $pointId not found', isAI: true);
        }
      } else {
        _addMessage('AI Agent', '⚠️ Please specify what to search for (e.g., "find train 1", "search signal L01")', isAI: true);
      }
      return;
    }

    // Follow train command
    if (lower.contains('follow') && lower.contains('train')) {
      final trainMatch = RegExp(r'train\s*(\d+)', caseSensitive: false).firstMatch(input);
      if (trainMatch != null) {
        final trainId = trainMatch.group(1)!;
        final train = controller.trains.where((t) => t.id == trainId).firstOrNull;
        if (train != null) {
          controller.followTrain(trainId);
          _addMessage('AI Agent', '📹 Following Train $trainId', isAI: true);
        } else {
          _addMessage('AI Agent', '❌ Train $trainId not found', isAI: true);
        }
      } else {
        _addMessage('AI Agent', '⚠️ Please specify train ID (e.g., "follow train 1")', isAI: true);
      }
      return;
    }

    // Stop following command
    if (lower.contains('stop following') || lower.contains('unfollow')) {
      controller.stopFollowingTrain();
      _addMessage('AI Agent', '✅ Stopped following train', isAI: true);
      return;
    }

    // Status queries
    if (lower.contains('status') || lower.contains('how many')) {
      final trainCount = controller.trains.length;
      final cbtcStatus = controller.cbtcModeActive ? 'ENABLED' : 'DISABLED';
      _addMessage('AI Agent', '''📊 Railway Status:
• Trains: $trainCount
• CBTC Mode: $cbtcStatus
• Signals: ${controller.signals.length}
• Points: ${controller.points.length}
• Blocks: ${controller.blocks.length}
''', isAI: true);
      return;
    }

    // Default - command not recognized
    _addMessage('AI Agent', '''⚠️ Command not recognized.

Try saying:
• "help" - See all available commands
• "set route L01"
• "swing point 76A"
• "add train to block 100"
• "enable CBTC mode"
• "status" - See railway status
''', isAI: true);
  }

  void _executeCommand(RailwayCommand command, TerminalStationController controller) {
    try {
      switch (command.action) {
        case 'set_route':
          final signalId = command.parameters['signal_id'] as String;
          final routeId = command.parameters['route_id'] as String;
          controller.setRoute(signalId, routeId);
          _addMessage('AI Agent', 'Route $routeId set for signal $signalId', isAI: true);
          break;

        case 'cancel_route':
          final signalId = command.parameters['signal_id'] as String;
          controller.cancelRoute(signalId);
          _addMessage('AI Agent', 'Route cancelled for signal $signalId', isAI: true);
          break;

        case 'swing_point':
          final pointId = command.parameters['point_id'] as String;
          controller.swingPoint(pointId);
          _addMessage('AI Agent', 'Point $pointId swung', isAI: true);
          break;

        case 'add_train':
          final blockId = command.parameters['block_id'] as String;
          final trainType = _parseTrainType(command.parameters['train_type'] as String?);
          controller.addTrainToBlock(blockId, trainType: trainType);
          _addMessage('AI Agent', 'Train added to block $blockId', isAI: true);
          break;

        case 'set_cbtc':
          final enabled = command.parameters['enabled'] as bool;
          controller.toggleCbtcMode(enabled);
          _addMessage('AI Agent', 'CBTC mode ${enabled ? "enabled" : "disabled"}', isAI: true);
          break;

        default:
          _addMessage('AI Agent', 'Unknown action: ${command.action}', isAI: true);
      }
    } catch (e) {
      _addMessage('AI Agent', 'Error executing command: $e', isAI: true);
    }
  }

  TrainType _parseTrainType(String? type) {
    switch (type?.toLowerCase()) {
      case 'm2':
        return TrainType.m2;
      case 'cbtc_m1':
        return TrainType.cbtcM1;
      case 'cbtc_m2':
        return TrainType.cbtcM2;
      default:
        return TrainType.m1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TerminalStationController>(
      builder: (context, controller, child) {
        return Positioned(
          left: controller.aiAgentPosition.dx,
          top: controller.aiAgentPosition.dy,
          child: Draggable(
            feedback: Opacity(
              opacity: 0.7,
              child: Material(child: _buildPanel(controller, isDragging: true)),
            ),
            childWhenDragging: const SizedBox.shrink(),
            onDragEnd: (details) {
              controller.updateAiAgentPosition(details.offset);
            },
            child: _buildPanel(controller),
          ),
        );
      },
    );
  }

  Widget _buildPanel(TerminalStationController controller, {bool isDragging = false}) {
    final designType = controller.signallingSystemManagerDesignType;
    final themeColor = controller.signallingSystemManagerColor;
    final compactMode = controller.signallingSystemManagerCompactMode;

    return Opacity(
      opacity: isDragging ? 0.7 : controller.signallingSystemManagerOpacity,
      child: Material(
        elevation: isDragging ? 8 : 4,
        borderRadius: BorderRadius.circular(designType == 3 ? 0 : 12),
        child: Stack(
          children: [
            Container(
              width: controller.signallingSystemManagerWidth,
              height: controller.signallingSystemManagerHeight,
              decoration: _getDesignDecoration(designType, themeColor),
              child: Column(
                children: [
                  // Header with drag handle and controls
                  Container(
                    padding: EdgeInsets.all(compactMode ? 4 : 8),
                    decoration: _getHeaderDecoration(designType, themeColor),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.drag_indicator, color: Colors.white, size: compactMode ? 16 : 20),
                            SizedBox(width: compactMode ? 2 : 4),
                            Icon(_getDesignIcon(designType), color: Colors.white, size: compactMode ? 16 : 20),
                            SizedBox(width: compactMode ? 4 : 8),
                            Expanded(
                              child: Text(
                                compactMode ? 'SSM' : 'Signalling System Manager',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: compactMode ? 12 : 14,
                                ),
                              ),
                            ),
                            // Clear chat button
                            if (!compactMode) IconButton(
                              icon: const Icon(Icons.delete_sweep, color: Colors.white70),
                              onPressed: _clearChat,
                              iconSize: 16,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Clear chat',
                            ),
                            if (!compactMode) const SizedBox(width: 4),
                            // Settings button
                            IconButton(
                              icon: const Icon(Icons.settings, color: Colors.white70),
                              onPressed: () => _showSettingsDialog(context, controller),
                              iconSize: compactMode ? 14 : 16,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Settings',
                            ),
                            SizedBox(width: compactMode ? 2 : 4),
                            // Opacity control
                            if (!compactMode) SizedBox(
                              width: 80,
                              child: Row(
                                children: [
                                  const Icon(Icons.opacity, color: Colors.white70, size: 14),
                                  Expanded(
                                    child: Slider(
                                      value: controller.signallingSystemManagerOpacity,
                                      min: 0.1,
                                      max: 1.0,
                                      activeColor: Colors.white,
                                      inactiveColor: Colors.white30,
                                      onChanged: (value) => controller.updateSignallingSystemManagerOpacity(value),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => controller.toggleSignallingSystemManager(),
                              iconSize: compactMode ? 14 : 18,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),
            // Input
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                border: Border(top: BorderSide(color: Colors.grey[700]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: RawKeyboardListener(
                      focusNode: _inputFocusNode,
                      onKey: (event) {
                        if (event is RawKeyDownEvent) {
                          if (event.logicalKey.keyLabel == 'Arrow Up') {
                            _navigateHistory(true);
                          } else if (event.logicalKey.keyLabel == 'Arrow Down') {
                            _navigateHistory(false);
                          }
                        }
                      },
                      child: TextField(
                        controller: _inputController,
                        style: const TextStyle(color: Colors.white),
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Enter command... (↑↓ for history)',
                          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[800],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _processCommand(controller),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send, color: Colors.blue),
                    onPressed: _isProcessing ? null : () => _processCommand(controller),
                  ),
                ],
              ),
            ),
                ],
              ),
            ),
            // Resize handle
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onPanUpdate: (details) {
                  // Add bounds checking to prevent panel from becoming unusable
                  const minWidth = 150.0;
                  const maxWidth = 600.0;
                  const minHeight = 200.0;
                  const maxHeight = 800.0;

                  final newWidth = (controller.aiAgentWidth + details.delta.dx).clamp(minWidth, maxWidth);
                  final newHeight = (controller.aiAgentHeight + details.delta.dy).clamp(minHeight, maxHeight);

                  controller.updateAiAgentSize(newWidth, newHeight);
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.8),
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(10),
                      topLeft: Radius.circular(4),
                    ),
                  ),
                  child: const Icon(
                    Icons.zoom_out_map,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: message.isAI ? Colors.grey[800] : Colors.blue[700],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.sender,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // Design helper methods
  IconData _getDesignIcon(int designType) {
    switch (designType) {
      case 0: return Icons.traffic; // Modern
      case 1: return Icons.train; // Railway
      case 2: return Icons.commute; // Professional
      case 3: return Icons.directions_railway; // Classic
      default: return Icons.traffic;
    }
  }

  BoxDecoration _getDesignDecoration(int designType, Color themeColor) {
    switch (designType) {
      case 0: // Modern - Dark with colored border
        return BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: themeColor, width: 2),
        );
      case 1: // Railway - Industrial look
        return BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: themeColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: themeColor.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        );
      case 2: // Professional - Clean gradient
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey[900]!, Colors.grey[800]!],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: themeColor, width: 1),
        );
      case 3: // Classic - Sharp edges, bold borders
        return BoxDecoration(
          color: Colors.black87,
          border: Border.all(color: themeColor, width: 4),
        );
      default:
        return BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: themeColor, width: 2),
        );
    }
  }

  BoxDecoration _getHeaderDecoration(int designType, Color themeColor) {
    switch (designType) {
      case 0: // Modern
        return BoxDecoration(
          color: themeColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        );
      case 1: // Railway - Metallic look
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              themeColor,
              themeColor.withOpacity(0.7),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        );
      case 2: // Professional - Subtle gradient
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [themeColor, themeColor.withOpacity(0.8)],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
          ),
        );
      case 3: // Classic - Solid color, no rounding
        return BoxDecoration(
          color: themeColor,
        );
      default:
        return BoxDecoration(
          color: themeColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        );
    }
  }

  void _showSettingsDialog(BuildContext context, TerminalStationController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signalling System Manager Settings'),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Color Picker
              const Text('Theme Color', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _colorOption(controller, Colors.blue, 'Blue'),
                  _colorOption(controller, Colors.green, 'Green'),
                  _colorOption(controller, Colors.orange, 'Orange'),
                  _colorOption(controller, Colors.red, 'Red'),
                  _colorOption(controller, Colors.purple, 'Purple'),
                  _colorOption(controller, Colors.teal, 'Teal'),
                  _colorOption(controller, Colors.amber, 'Amber'),
                  _colorOption(controller, Colors.indigo, 'Indigo'),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              // Design Type
              const Text('Design Style', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _designTypeOption(controller, 0, 'Modern', Icons.traffic),
              _designTypeOption(controller, 1, 'Railway', Icons.train),
              _designTypeOption(controller, 2, 'Professional', Icons.commute),
              _designTypeOption(controller, 3, 'Classic', Icons.directions_railway),
              const SizedBox(height: 16),
              const Divider(),
              // Additional Options
              const Text('Options', style: TextStyle(fontWeight: FontWeight.bold)),
              SwitchListTile(
                title: const Text('Compact Mode'),
                value: controller.signallingSystemManagerCompactMode,
                onChanged: (value) {
                  controller.toggleSignallingSystemManagerCompactMode();
                  Navigator.of(context).pop();
                  _showSettingsDialog(context, controller);
                },
              ),
              SwitchListTile(
                title: const Text('Auto-scroll'),
                value: controller.signallingSystemManagerAutoScroll,
                onChanged: (value) {
                  controller.toggleSignallingSystemManagerAutoScroll();
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

  Widget _colorOption(TerminalStationController controller, Color color, String label) {
    final isSelected = controller.signallingSystemManagerColor == color;
    return InkWell(
      onTap: () => controller.updateSignallingSystemManagerColor(color),
      child: Container(
        width: 70,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _designTypeOption(TerminalStationController controller, int type, String label, IconData icon) {
    final isSelected = controller.signallingSystemManagerDesignType == type;
    return Card(
      color: isSelected ? controller.signallingSystemManagerColor.withOpacity(0.2) : null,
      child: ListTile(
        leading: Icon(icon, color: isSelected ? controller.signallingSystemManagerColor : null),
        title: Text(label),
        trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
        onTap: () => controller.updateSignallingSystemManagerDesignType(type),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String sender;
  final String text;
  final bool isAI;

  ChatMessage({
    required this.sender,
    required this.text,
    required this.isAI,
  });
}
