import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/terminal_station_controller.dart';

/// AI Agent Widget - Floating draggable AI assistant for natural language control
/// Provides advice and allows control of all simulation elements
class AIAgentWidget extends StatefulWidget {
  const AIAgentWidget({Key? key}) : super(key: key);

  @override
  State<AIAgentWidget> createState() => _AIAgentWidgetState();
}

class _AIAgentWidgetState extends State<AIAgentWidget> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, String>> _chatHistory = [];
  bool _isExpanded = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _sendMessage(TerminalStationController controller) {
    final message = _textController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _chatHistory.add({'role': 'user', 'message': message});
    });

    // Process the command
    final response = _processNaturalLanguageCommand(message, controller);

    setState(() {
      _chatHistory.add({'role': 'assistant', 'message': response});
      _textController.clear();
    });
  }

  String _processNaturalLanguageCommand(String command, TerminalStationController controller) {
    final lowerCommand = command.toLowerCase();

    // Route setting commands
    if (lowerCommand.contains('set route') || lowerCommand.contains('route to')) {
      return 'Route setting via AI agent will be implemented with OpenAI integration.';
    }

    // Point commands
    if (lowerCommand.contains('throw point') || lowerCommand.contains('swing point')) {
      return 'Point control will be implemented with OpenAI integration.';
    }

    // Train commands
    if (lowerCommand.contains('add train')) {
      return 'Train creation will be implemented with OpenAI integration.';
    }

    // Status queries
    if (lowerCommand.contains('why') || lowerCommand.contains('status')) {
      return 'System status analysis will be implemented with OpenAI integration.';
    }

    // Traction control
    if (lowerCommand.contains('traction')) {
      controller.toggleTractionCurrent();
      return controller.tractionCurrentOn
          ? 'Traction current enabled. All trains can resume movement.'
          : 'Traction current disabled. All trains have emergency braked.';
    }

    return 'AI agent with OpenAI integration will be added in the next phase. For now, use the control panel buttons.';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TerminalStationController>(
      builder: (context, controller, child) {
        if (!controller.aiAgentVisible) {
          return const SizedBox.shrink();
        }

        return Positioned(
          left: controller.aiAgentPosition.dx,
          top: controller.aiAgentPosition.dy,
          child: Draggable(
            feedback: _buildAgentContainer(controller, isDragging: true),
            childWhenDragging: Container(),
            onDragEnd: (details) {
              controller.updateAiAgentPosition(details.offset);
            },
            child: _buildAgentContainer(controller),
          ),
        );
      },
    );
  }

  Widget _buildAgentContainer(TerminalStationController controller, {bool isDragging = false}) {
    return Material(
      elevation: isDragging ? 8 : 4,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: _isExpanded ? 350 : 200,
        height: _isExpanded ? 400 : 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[700]!, Colors.purple[700]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Column(
          children: [
            // Header
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.smart_toy, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'AI Assistant',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),

            // Chat area (only visible when expanded)
            if (_isExpanded) ...[
              Expanded(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(8),
                  child: ListView.builder(
                    itemCount: _chatHistory.length,
                    itemBuilder: (context, index) {
                      final chat = _chatHistory[index];
                      final isUser = chat['role'] == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.blue[100] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            chat['message']!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Input field
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          hintText: 'Ask me anything...',
                          border: OutlineBorder.none,
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 12),
                        onSubmitted: (_) => _sendMessage(controller),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, size: 20),
                      onPressed: () => _sendMessage(controller),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
