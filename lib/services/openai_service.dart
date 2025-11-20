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
  /// with timeout and retry logic
  Future<AIResponse> processCommand(
    String userInput,
    String systemContext, {
    int maxRetries = 2,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    int retryCount = 0;

    while (retryCount <= maxRetries) {
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
        ).timeout(timeout);

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          final content = jsonResponse['choices'][0]['message']['content'] as String;

          return AIResponse(
            success: true,
            content: content,
            rawResponse: jsonResponse,
          );
        } else if (response.statusCode == 429) {
          // Rate limit - wait and retry
          if (retryCount < maxRetries) {
            await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
            retryCount++;
            continue;
          }
          return AIResponse(
            success: false,
            content: 'Rate limit exceeded. Please try again later.',
            error: 'RATE_LIMIT',
            errorType: ErrorType.rateLimitExceeded,
          );
        } else if (response.statusCode == 401) {
          return AIResponse(
            success: false,
            content: 'Invalid API key. Please check your configuration.',
            error: 'INVALID_API_KEY',
            errorType: ErrorType.authenticationError,
          );
        } else if (response.statusCode >= 500) {
          // Server error - retry
          if (retryCount < maxRetries) {
            await Future.delayed(Duration(seconds: 1 * (retryCount + 1)));
            retryCount++;
            continue;
          }
          return AIResponse(
            success: false,
            content: 'OpenAI service temporarily unavailable.',
            error: 'SERVER_ERROR',
            errorType: ErrorType.serverError,
          );
        } else {
          return AIResponse(
            success: false,
            content: 'API Error: ${response.statusCode}',
            error: 'HTTP_${response.statusCode}',
            errorType: ErrorType.apiError,
          );
        }
      } on http.ClientException catch (e) {
        return AIResponse(
          success: false,
          content: 'Network error: Unable to connect to OpenAI.',
          error: e.toString(),
          errorType: ErrorType.networkError,
        );
      } on FormatException catch (e) {
        return AIResponse(
          success: false,
          content: 'Invalid response format from OpenAI.',
          error: e.toString(),
          errorType: ErrorType.parseError,
        );
      } catch (e) {
        if (e.toString().contains('TimeoutException')) {
          if (retryCount < maxRetries) {
            retryCount++;
            continue;
          }
          return AIResponse(
            success: false,
            content: 'Request timed out after ${timeout.inSeconds}s.',
            error: 'TIMEOUT',
            errorType: ErrorType.timeout,
          );
        }

        return AIResponse(
          success: false,
          content: 'Unexpected error: $e',
          error: e.toString(),
          errorType: ErrorType.unknown,
        );
      }
    }

    return AIResponse(
      success: false,
      content: 'Max retries exceeded.',
      error: 'MAX_RETRIES',
      errorType: ErrorType.maxRetriesExceeded,
    );
  }

  /// Parse command and extract railway control actions with enhanced NLU
  Future<RailwayCommand?> parseRailwayCommand(String userInput) async {
    const systemPrompt = '''
You are an intelligent Railway Signalling System Manager assistant. Your role is to understand natural language commands about railway operations and convert them to structured JSON commands, OR provide helpful tutorials and guidance when asked.

COMMAND UNDERSTANDING:
You must be flexible and understand synonyms, variations, and natural speech patterns. Here are the available actions:

1. SET SIGNAL/ROUTE
   Synonyms: "set route", "change signal", "switch route", "activate signal", "clear signal", "give signal", "pull off"
   Examples: "set L01 to route 1", "change signal L01", "activate L01", "pull off L01", "give the road on L01"
   JSON: {"action": "set_route", "signal_id": "L01", "route_id": "L01_R1"}

2. CANCEL ROUTE
   Synonyms: "cancel route", "clear route", "release route", "stop route", "drop route", "put back"
   Examples: "cancel L01", "clear the route on L01", "release signal L01", "put L01 back"
   JSON: {"action": "cancel_route", "signal_id": "L01"}

3. SWING/THROW POINT
   Synonyms: "swing point", "throw point", "change point", "switch point", "reverse point", "flip point", "move point"
   Examples: "swing 76A", "throw point 76A", "change the point 76A", "flip 76A", "move point 76A"
   JSON: {"action": "swing_point", "point_id": "76A"}

4. ADD TRAIN
   Synonyms: "add train", "create train", "spawn train", "place train", "put train", "add service"
   Train types: "m1" (single car), "m2" (double car), "m7", "m9", "freight", "cbtc-m1", "cbtc-m2"
   Examples: "add train to block 100", "create M2 train in 100", "spawn a freight train", "place train"
   JSON: {"action": "add_train", "block_id": "100", "train_type": "m1"}

5. REMOVE TRAIN
   Synonyms: "remove train", "delete train", "cancel train", "clear train", "take off train"
   Examples: "remove train 1", "delete the train", "clear train 1"
   JSON: {"action": "remove_train", "train_id": "1"}

6. CBTC MODE
   Synonyms: "enable CBTC", "activate CBTC", "turn on CBTC", "disable CBTC", "turn off CBTC"
   Examples: "enable CBTC", "turn CBTC on", "activate CBTC mode"
   JSON: {"action": "set_cbtc", "enabled": true}

7. HELP/TUTORIAL REQUESTS
   When user asks for "help", "tutorial", "how to", "guide", "teach me", etc.
   JSON: {"action": "help", "topic": "<what they're asking about>"}

IMPORTANT RULES:
- Be flexible with phrasing - understand intent, not just exact words
- Infer missing information when reasonable (e.g., if block ID not specified, can use "default")
- For route IDs, if user says "route 1" convert to "<signal_id>_R1" format
- Point IDs are usually numbers with letter suffix (e.g., "76A", "79B")
- Signal IDs usually start with L, C, or R followed by numbers (e.g., "L01", "C23", "R45")
- Block IDs are usually just numbers (e.g., "100", "104")

When asked for help or tutorials, respond with:
{"action": "help", "topic": "general"} for general help
{"action": "help", "topic": "signals"} for signal-specific help
{"action": "help", "topic": "points"} for points help
{"action": "help", "topic": "trains"} for train operation help

Respond ONLY with valid JSON matching these patterns. Be smart about understanding variations and synonyms!
''';

    final response = await processCommand(userInput, systemPrompt);

    if (response.success) {
      try {
        final json = jsonDecode(response.content);
        return RailwayCommand.fromJson(json);
      } catch (e) {
        // Log parsing error for debugging
        print('Failed to parse railway command: $e');
        print('Response content: ${response.content}');
        return null;
      }
    } else {
      // Log the error for debugging
      print('OpenAI API error: ${response.error} (${response.errorType})');
    }

    return null;
  }
}

/// Error types for better error categorization
enum ErrorType {
  networkError,
  timeout,
  rateLimitExceeded,
  authenticationError,
  serverError,
  apiError,
  parseError,
  maxRetriesExceeded,
  unknown,
}

/// Response from the AI agent
class AIResponse {
  final bool success;
  final String content;
  final String? error;
  final ErrorType? errorType;
  final Map<String, dynamic>? rawResponse;

  AIResponse({
    required this.success,
    required this.content,
    this.error,
    this.errorType,
    this.rawResponse,
  });

  /// Check if error is retryable
  bool get isRetryable {
    return errorType == ErrorType.timeout ||
        errorType == ErrorType.networkError ||
        errorType == ErrorType.serverError;
  }

  /// Get user-friendly error message
  String get userFriendlyError {
    switch (errorType) {
      case ErrorType.networkError:
        return 'Unable to connect. Please check your internet connection.';
      case ErrorType.timeout:
        return 'Request took too long. Please try again.';
      case ErrorType.rateLimitExceeded:
        return 'Too many requests. Please wait a moment.';
      case ErrorType.authenticationError:
        return 'API key is invalid. Please check your configuration.';
      case ErrorType.serverError:
        return 'Service temporarily unavailable. Please try again later.';
      default:
        return content;
    }
  }
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
