import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/terminal_station_controller.dart';
import '../services/intent_service.dart';
import '../services/connection_service.dart';
import '../services/openai_service.dart';

/// AI Agent Widget - Floating draggable AI assistant for natural language control
/// Provides SSM troubleshooting guidance and allows control of all simulation elements
class AIAgentWidget extends StatefulWidget {
  const AIAgentWidget({Key? key}) : super(key: key);

  @override
  State<AIAgentWidget> createState() => _AIAgentWidgetState();
}

class _AIAgentWidgetState extends State<AIAgentWidget> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, String>> _chatHistory = [];
  bool _isExpanded = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _sendMessage(
      BuildContext context, TerminalStationController controller) async {
    final message = _textController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _chatHistory.add({'role': 'user', 'message': message});
      _isProcessing = true;
    });

    _textController.clear();

    // Process the command
    final response =
        await _processNaturalLanguageCommand(context, message, controller);

    setState(() {
      _chatHistory.add({'role': 'assistant', 'message': response});
      _isProcessing = false;
    });
  }

  Future<String> _processNaturalLanguageCommand(
    BuildContext context,
    String command,
    TerminalStationController controller,
  ) async {
    final lowerCommand = command.toLowerCase();
    final intentService = context.read<IntentService>();
    final connectionService = context.read<ConnectionService>();

    // SSM Troubleshooting commands
    if (lowerCommand.contains('start') &&
        (lowerCommand.contains('troubleshoot') ||
            lowerCommand.contains('help') ||
            lowerCommand.contains('ssm'))) {
      intentService.startSession();
      if (intentService.currentIntent != null) {
        return 'Starting SSM troubleshooting session:\n\n${intentService.currentIntent!.cleanQuestion}\n\nRespond with "yes" or "no".';
      }
      return 'Troubleshooting intents not loaded. Please try again.';
    }

    // Yes/No responses for SSM troubleshooting
    if (intentService.currentIntent != null) {
      if (lowerCommand == 'yes' || lowerCommand == 'y') {
        intentService.answerCurrentIntent(true);
        if (intentService.currentIntent != null) {
          if (intentService.currentIntent!.isTerminal) {
            return '${intentService.currentIntent!.cleanQuestion}\n\nEnd of troubleshooting path. Type "start troubleshooting" to begin a new session.';
          }
          return intentService.currentIntent!.cleanQuestion +
              '\n\nRespond with "yes" or "no".';
        }
        return 'Troubleshooting complete. Type "start troubleshooting" to begin again.';
      } else if (lowerCommand == 'no' || lowerCommand == 'n') {
        intentService.answerCurrentIntent(false);
        if (intentService.currentIntent != null) {
          if (intentService.currentIntent!.isTerminal) {
            return '${intentService.currentIntent!.cleanQuestion}\n\nEnd of troubleshooting path. Type "start troubleshooting" to begin a new session.';
          }
          return intentService.currentIntent!.cleanQuestion +
              '\n\nRespond with "yes" or "no".';
        }
        return 'Troubleshooting complete. Type "start troubleshooting" to begin again.';
      } else if (lowerCommand.contains('back')) {
        intentService.goBack();
        if (intentService.currentIntent != null) {
          return 'Going back:\n\n${intentService.currentIntent!.cleanQuestion}\n\nRespond with "yes" or "no".';
        }
        return 'Already at the beginning.';
      } else if (lowerCommand.contains('reset') ||
          lowerCommand.contains('restart')) {
        intentService.resetSession();
        return 'Troubleshooting session reset. Type "start troubleshooting" to begin.';
      }
    }

    // Use OpenAI for more complex queries if available
    if (connectionService.openAiService != null) {
      try {
        // Get context from intent service
        final aiContext = intentService.getAIContext();

        final systemPrompt = '''
You are an AI assistant for a railway signaling simulation app.
You can help with:
1. SSM (Signal & Systems Maintenance) troubleshooting using guided flowcharts
2. Controlling trains and signals in the simulation
3. Explaining railway signaling concepts

Current context:
$aiContext

Be concise and helpful. If user wants troubleshooting, guide them to type "start troubleshooting".
For yes/no questions in troubleshooting, expect "yes" or "no" responses.
''';

        final aiResponse =
            await connectionService.openAiService!.processCommand(
          command,
          systemPrompt,
          timeout: const Duration(seconds: 10),
        );

        if (aiResponse.success) {
          return aiResponse.content;
        } else {
          return 'AI Error: ${aiResponse.userFriendlyError}';
        }
      } catch (e) {
        // Fall back to basic command processing
        debugPrint('OpenAI error: $e');
      }
    }

    // Basic command processing fallback
    if (lowerCommand.contains('traction')) {
      controller.toggleTractionCurrent();
      return controller.tractionCurrentOn
          ? 'Traction current enabled. All trains can resume movement.'
          : 'Traction current disabled. All trains have emergency braked.';
    }

    // Help command
    if (lowerCommand.contains('help')) {
      return '''
AI Assistant Commands:
• "start troubleshooting" - Begin SSM troubleshooting
• "yes" or "no" - Answer troubleshooting questions
• "back" - Go to previous question
• "reset" - Restart troubleshooting
• Ask any railway-related question
• "traction" - Toggle traction current

Try: "start troubleshooting" to begin!
''';
    }

    return 'I can help with SSM troubleshooting and railway operations. Type "help" for commands or "start troubleshooting" to begin.';
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

  Widget _buildAgentContainer(TerminalStationController controller,
      {bool isDragging = false}) {
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
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
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
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 12),
                        onSubmitted: (_) => _sendMessage(context, controller),
                        enabled: !_isProcessing,
                      ),
                    ),
                    if (_isProcessing)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.send, size: 20),
                        onPressed: () => _sendMessage(context, controller),
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
