import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/terminal_station_controller.dart';
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

    // Set route pattern
    if (lower.contains('set route') || lower.contains('route')) {
      final signalMatch = RegExp(r'([lcr]\d+)', caseSensitive: false).firstMatch(input);
      if (signalMatch != null) {
        final signalId = signalMatch.group(1)!.toUpperCase();
        final signal = controller.signals[signalId];

        if (signal != null && signal.routes.isNotEmpty) {
          controller.setRoute(signalId, signal.routes.first.id);
          _addMessage('AI Agent', 'Route set for signal $signalId', isAI: true);
        } else {
          _addMessage('AI Agent', 'Signal $signalId not found', isAI: true);
        }
      }
    }
    // Swing point pattern
    else if (lower.contains('swing') || lower.contains('point')) {
      final pointMatch = RegExp(r'(\d+[ab])', caseSensitive: false).firstMatch(input);
      if (pointMatch != null) {
        final pointId = pointMatch.group(1)!.toUpperCase();
        if (controller.points.containsKey(pointId)) {
          controller.swingPoint(pointId);
          _addMessage('AI Agent', 'Point $pointId swung', isAI: true);
        } else {
          _addMessage('AI Agent', 'Point $pointId not found', isAI: true);
        }
      }
    }
    // Add train pattern
    else if (lower.contains('add train')) {
      final blockMatch = RegExp(r'block (\d+)').firstMatch(lower);
      if (blockMatch != null) {
        final blockId = blockMatch.group(1)!;
        controller.addTrain(blockId, TrainType.m1);
        _addMessage('AI Agent', 'Train added to block $blockId', isAI: true);
      }
    }
    // CBTC mode
    else if (lower.contains('cbtc')) {
      final enable = lower.contains('enable') || lower.contains('on') || lower.contains('activate');
      controller.toggleCbtcMode(enable);
      _addMessage('AI Agent', 'CBTC mode ${enable ? "enabled" : "disabled"}', isAI: true);
    }
    else {
      _addMessage('AI Agent', 'Command not recognized. Available commands:\n• Set route [signal]\n• Swing point [point_id]\n• Add train to block [block_id]\n• Enable/Disable CBTC', isAI: true);
    }
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
          controller.addTrain(blockId, trainType);
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
