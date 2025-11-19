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
