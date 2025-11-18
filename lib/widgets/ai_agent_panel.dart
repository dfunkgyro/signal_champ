import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/terminal_station_controller.dart';
import '../screens/terminal_station_models.dart';
import '../services/openai_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Floating AI Agent panel for natural language railway control
class AIAgentPanel extends StatefulWidget {
  const AIAgentPanel({Key? key}) : super(key: key);

  @override
  State<AIAgentPanel> createState() => _AIAgentPanelState();
}

class _AIAgentPanelState extends State<AIAgentPanel> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  OpenAIService? _openAIService;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeOpenAI();
    _addMessage('AI Agent', 'Hello! I can help you control the railway. Try commands like:\n• "Set route L01 to route 1"\n• "Swing point 76A"\n• "Add M1 train to block 100"', isAI: true);
  }

  void _initializeOpenAI() {
    try {
      final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
      if (apiKey.isNotEmpty && apiKey != 'your_api_key_here') {
        _openAIService = OpenAIService(
          apiKey: apiKey,
          model: dotenv.env['OPENAI_MODEL'] ?? 'gpt-3.5-turbo',
        );
      }
    } catch (e) {
      _addMessage('System', 'API key not configured. Create assets/.env file with OPENAI_API_KEY', isAI: true);
    }
  }

  void _addMessage(String sender, String text, {bool isAI = false}) {
    setState(() {
      _messages.add(ChatMessage(sender: sender, text: text, isAI: isAI));
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _processCommand(TerminalStationController controller) async {
    final input = _inputController.text.trim();
    if (input.isEmpty) return;

    _addMessage('You', input);
    _inputController.clear();

    setState(() => _isProcessing = true);

    if (_openAIService == null) {
      // Fallback: Simple pattern matching
      _processLocalCommand(input, controller);
    } else {
      // Use OpenAI for natural language processing
      final command = await _openAIService!.parseRailwayCommand(input);

      if (command != null) {
        _executeCommand(command, controller);
      } else {
        _addMessage('AI Agent', 'I couldn\'t understand that command. Please try again.', isAI: true);
      }
    }

    setState(() => _isProcessing = false);
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
    final controller = Provider.of<TerminalStationController>(context, listen: false);

    return Positioned(
      left: controller.aiAgentPosition.dx,
      top: controller.aiAgentPosition.dy,
      child: Draggable(
        feedback: Material(child: _buildPanel(controller, isDragging: true)),
        childWhenDragging: const SizedBox.shrink(),
        onDragEnd: (details) {
          controller.updateAiAgentPosition(details.offset);
        },
        child: _buildPanel(controller),
      ),
    );
  }

  Widget _buildPanel(TerminalStationController controller, {bool isDragging = false}) {
    return Material(
      elevation: isDragging ? 8 : 4,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 350,
        height: 500,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue, width: 2),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.smart_toy, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'AI Railway Assistant',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => controller.toggleAiAgent(),
                    iconSize: 20,
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
                    child: TextField(
                      controller: _inputController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter command...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
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

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
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
