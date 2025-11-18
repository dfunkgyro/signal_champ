import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for integrating with OpenAI API
/// Provides natural language processing for railway control commands
class OpenAIService {
  final String _apiKey;
  final String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  final String _model;

  OpenAIService({
    required String apiKey,
    String model = 'gpt-3.5-turbo',
  })  : _apiKey = apiKey,
        _model = model;

  /// Send a command to the AI agent and get a structured response
  Future<AIResponse> processCommand(String userInput, String systemContext) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': systemContext,
            },
            {
              'role': 'user',
              'content': userInput,
            }
          ],
          'temperature': 0.7,
          'max_tokens': 300,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final content = jsonResponse['choices'][0]['message']['content'] as String;

        return AIResponse(
          success: true,
          content: content,
          rawResponse: jsonResponse,
        );
      } else {
        return AIResponse(
          success: false,
          content: 'API Error: ${response.statusCode} - ${response.body}',
          error: 'HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      return AIResponse(
        success: false,
        content: 'Failed to communicate with OpenAI: $e',
        error: e.toString(),
      );
    }
  }

  /// Parse command and extract railway control actions
  Future<RailwayCommand?> parseRailwayCommand(String userInput) async {
    const systemPrompt = '''
You are a railway signaling assistant. Parse user commands into structured JSON.

Available commands:
- Set signal route: {"action": "set_route", "signal_id": "L01", "route_id": "L01_R1"}
- Cancel route: {"action": "cancel_route", "signal_id": "L01"}
- Swing point: {"action": "swing_point", "point_id": "76A"}
- Add train: {"action": "add_train", "block_id": "100", "train_type": "m1"}
- Remove train: {"action": "remove_train", "train_id": "1"}
- Set CBTC mode: {"action": "set_cbtc", "enabled": true}

Respond ONLY with valid JSON matching one of these patterns.
''';

    final response = await processCommand(userInput, systemPrompt);

    if (response.success) {
      try {
        final json = jsonDecode(response.content);
        return RailwayCommand.fromJson(json);
      } catch (e) {
        // If parsing fails, return null
        return null;
      }
    }

    return null;
  }
}

/// Response from the AI agent
class AIResponse {
  final bool success;
  final String content;
  final String? error;
  final Map<String, dynamic>? rawResponse;

  AIResponse({
    required this.success,
    required this.content,
    this.error,
    this.rawResponse,
  });
}

/// Structured railway command parsed from natural language
class RailwayCommand {
  final String action;
  final Map<String, dynamic> parameters;

  RailwayCommand({
    required this.action,
    required this.parameters,
  });

  factory RailwayCommand.fromJson(Map<String, dynamic> json) {
    return RailwayCommand(
      action: json['action'] as String,
      parameters: Map<String, dynamic>.from(json)..remove('action'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      ...parameters,
    };
  }
}
