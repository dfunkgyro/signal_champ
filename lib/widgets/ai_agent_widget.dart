import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/terminal_station_controller.dart';
import '../services/intent_service.dart';
import '../services/connection_service.dart';
import '../services/widget_preferences_service.dart';
import '../services/speech_recognition_service.dart';
import '../services/text_to_speech_service.dart';

/// Enhanced AI Agent Widget with voice capabilities and customization
class AIAgentWidgetEnhanced extends StatefulWidget {
  const AIAgentWidgetEnhanced({Key? key}) : super(key: key);

  @override
  State<AIAgentWidgetEnhanced> createState() => _AIAgentWidgetEnhancedState();
}

class _AIAgentWidgetEnhancedState extends State<AIAgentWidgetEnhanced> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, String>> _chatHistory = [];
  bool _isExpanded = false;
  bool _isProcessing = false;
  bool _isListeningForWakeWord = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _sendMessage(
    BuildContext context,
    TerminalStationController controller,
    TextToSpeechService ttsService,
    WidgetPreferencesService prefs,
  ) async {
    final message = _textController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _chatHistory.add({'role': 'user', 'message': message});
      _isProcessing = true;
    });

    _textController.clear();

    // Process the command
    final response = await _processNaturalLanguageCommand(
      context,
      message,
      controller,
    );

    setState(() {
      _chatHistory.add({'role': 'assistant', 'message': response});
      _isProcessing = false;
    });

    // Speak response if TTS enabled
    if (prefs.ttsEnabled && ttsService.isAvailable) {
      await ttsService.speak(response);
    }
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

  /// Start voice input
  Future<void> _startVoiceInput(
    SpeechRecognitionService speechService,
    TerminalStationController controller,
    TextToSpeechService ttsService,
    WidgetPreferencesService prefs,
  ) async {
    if (!prefs.voiceEnabled) {
      _showSnackBar('Voice input is disabled in settings');
      return;
    }

    if (!speechService.isAvailable) {
      final initialized = await speechService.initialize();
      if (!initialized) {
        _showSnackBar('Speech recognition not available');
        return;
      }
    }

    await speechService.startListening(
      onResult: (text) {
        setState(() {
          _textController.text = text;
        });
      },
    );
  }

  /// Toggle wake word listening
  Future<void> _toggleWakeWordListening(
    SpeechRecognitionService speechService,
    TerminalStationController controller,
    TextToSpeechService ttsService,
    WidgetPreferencesService prefs,
  ) async {
    if (!prefs.wakeWordEnabled) {
      _showSnackBar('Wake word is disabled in settings');
      return;
    }

    if (!speechService.isAvailable) {
      final initialized = await speechService.initialize();
      if (!initialized) {
        _showSnackBar('Speech recognition not available');
        return;
      }
    }

    if (_isListeningForWakeWord) {
      await speechService.stopListening();
      setState(() {
        _isListeningForWakeWord = false;
      });
    } else {
      await speechService.startWakeWordListening(
        onWakeWordDetected: (wakeWord) async {
          if (wakeWord.contains('ssm') || wakeWord.contains('assistant')) {
            // Stop wake word listening and start command listening
            setState(() {
              _isListeningForWakeWord = false;
              _isExpanded = true; // Expand widget automatically
            });

            // Provide audio feedback
            if (prefs.ttsEnabled && ttsService.isAvailable) {
              await ttsService.speak('Yes, how can I help?');
            }

            // Start listening for command
            await _startVoiceInput(speechService, controller, ttsService, prefs);
          }
        },
      );
      setState(() {
        _isListeningForWakeWord = true;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer5<TerminalStationController, WidgetPreferencesService,
        SpeechRecognitionService, TextToSpeechService, IntentService>(
      builder: (context, controller, prefs, speechService, ttsService, intentService, child) {
        if (!controller.aiAgentVisible) {
          return const SizedBox.shrink();
        }

        final displayWidth = _isExpanded ? prefs.aiAgentExpandedWidth : prefs.aiAgentWidth;
        final displayHeight = _isExpanded ? prefs.aiAgentExpandedHeight : prefs.aiAgentHeight;

        return Positioned(
          left: controller.aiAgentPosition.dx,
          top: controller.aiAgentPosition.dy,
          child: Draggable(
            feedback: _buildAgentContainer(
              controller,
              prefs,
              speechService,
              ttsService,
              displayWidth,
              displayHeight,
              isDragging: true,
            ),
            childWhenDragging: Container(),
            onDragEnd: (details) {
              controller.updateAiAgentPosition(details.offset);
            },
            child: _buildAgentContainer(
              controller,
              prefs,
              speechService,
              ttsService,
              displayWidth,
              displayHeight,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAgentContainer(
    TerminalStationController controller,
    WidgetPreferencesService prefs,
    SpeechRecognitionService speechService,
    TextToSpeechService ttsService,
    double width,
    double height, {
    bool isDragging = false,
  }) {
    return Material(
      elevation: isDragging ? 8 : 4,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              prefs.aiAgentColor.withOpacity(0.9),
              prefs.aiAgentColor.withOpacity(0.7),
            ],
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
                    const Expanded(
                      child: Text(
                        'AI Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Wake word indicator
                    if (_isListeningForWakeWord)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.hearing, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'LISTENING',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(width: 4),
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
                  child: _chatHistory.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ask me anything!',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Try: "start troubleshooting"',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
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
                                padding: const EdgeInsets.all(10),
                                constraints: BoxConstraints(
                                  maxWidth: width * 0.75,
                                ),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? prefs.aiAgentColor.withOpacity(0.2)
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  chat['message']!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
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
                    // Wake word button
                    if (prefs.wakeWordEnabled)
                      IconButton(
                        icon: Icon(
                          _isListeningForWakeWord
                              ? Icons.hearing
                              : Icons.hearing_disabled,
                          size: 20,
                          color: _isListeningForWakeWord
                              ? Colors.green
                              : Colors.grey,
                        ),
                        onPressed: () => _toggleWakeWordListening(
                          speechService,
                          controller,
                          ttsService,
                          prefs,
                        ),
                        tooltip: 'Wake word',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    const SizedBox(width: 4),
                    // Voice input button
                    if (prefs.voiceEnabled)
                      IconButton(
                        icon: Icon(
                          speechService.isListening
                              ? Icons.mic
                              : Icons.mic_none,
                          size: 20,
                          color: speechService.isListening
                              ? Colors.red
                              : prefs.aiAgentColor,
                        ),
                        onPressed: () => _startVoiceInput(
                          speechService,
                          controller,
                          ttsService,
                          prefs,
                        ),
                        tooltip: 'Voice input',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: speechService.isListening
                              ? 'Listening...'
                              : 'Ask me anything...',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 13),
                        onSubmitted: (_) => _sendMessage(
                          context,
                          controller,
                          ttsService,
                          prefs,
                        ),
                        enabled: !_isProcessing,
                      ),
                    ),
                    if (_isProcessing)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        icon: Icon(
                          Icons.send,
                          size: 20,
                          color: prefs.aiAgentColor,
                        ),
                        onPressed: () => _sendMessage(
                          context,
                          controller,
                          ttsService,
                          prefs,
                        ),
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
