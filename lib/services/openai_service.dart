import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;

/// Service for integrating with OpenAI API
/// Provides natural language processing for railway control commands
class OpenAIService {
  final String _apiKey;
  final String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  final String _model;

  String? _ssmKnowledge;  // Cached SSM.json knowledge

  OpenAIService({
    required String apiKey,
    String model = 'gpt-3.5-turbo',
  })  : _apiKey = apiKey,
        _model = model {
    _loadSSMKnowledge();  // Load SSM knowledge on initialization
  }

  /// Load SSM.json knowledge base for fault finding and signalling
  Future<void> _loadSSMKnowledge() async {
    try {
      final ssmContent = await rootBundle.loadString('assets/json/ssm.json');
      _ssmKnowledge = ssmContent;
      print('✅ SSM knowledge loaded successfully');
    } catch (e) {
      print('⚠️ Failed to load SSM knowledge: $e');
      _ssmKnowledge = null;
    }
  }

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
    // Include SSM knowledge in the system prompt
    final ssmSection = _ssmKnowledge != null
        ? '\n\nSIGNALLING SYSTEM KNOWLEDGE BASE:\n$_ssmKnowledge\n\nUse this knowledge to help diagnose faults and provide expert signalling advice.'
        : '';

    final systemPrompt = '''
You are an intelligent Railway Signalling System Manager assistant with FULL CONTROL over the railway simulation app. Your role is to understand natural language commands about railway operations and convert them to structured JSON commands, provide fault-finding guidance, and offer expert signalling advice.

$ssmSection

COMPLETE COMMAND SET - You have access to ALL app features:

1. SIGNAL & ROUTE OPERATIONS
   - Set Route: "set L01 to route 1", "pull off L01", "clear signal L01"
     JSON: {"action": "set_route", "signal_id": "L01", "route_id": "L01_R1"}
   - Cancel Route: "cancel L01", "put back L01", "release route L01"
     JSON: {"action": "cancel_route", "signal_id": "L01"}
   - Auto-clear signals: "enable auto signal clearing", "automatic signal release"
     JSON: {"action": "toggle_auto_signal_clear", "enabled": true}

2. POINTS & CROSSOVERS
   - Swing Point: "swing 76A", "throw point 76A", "reverse 76A"
     JSON: {"action": "swing_point", "point_id": "76A"}
   - Set crossover type: "set crossover 1 to lefthand", "change crossover type"
     JSON: {"action": "set_crossover_type", "crossover_id": "crossover_211_212", "type": "lefthand"}
   - Rename point: "rename point 76A to Main Junction"
     JSON: {"action": "rename_point", "point_id": "76A", "name": "Main Junction"}
   - Point position confirmation: "enable point confirmation", "disable point safety dialog"
     JSON: {"action": "toggle_point_confirmation", "enabled": true}

3. TRAIN OPERATIONS
   - Add Train: "add M2 train to block 100", "create CBTC train"
     Train types: m1, m2, m4, m8, cbtcM1, cbtcM2, cbtcM4, cbtcM8
     JSON: {"action": "add_train", "block_id": "100", "train_type": "m2"}
   - Remove Train: "remove train 1", "delete all trains"
     JSON: {"action": "remove_train", "train_id": "1"}
   - Set train destination: "send train 1 to block 300"
     JSON: {"action": "set_train_destination", "train_id": "1", "destination": "300"}
   - Emergency stop: "emergency stop train 1", "apply emergency brake"
     JSON: {"action": "emergency_stop", "train_id": "1"}
   - Set speed limit: "set speed limit 40 for train 1"
     JSON: {"action": "set_speed_limit", "train_id": "1", "limit": 40}

4. CBTC OPERATIONS
   - Toggle CBTC: "enable CBTC", "turn on CBTC", "activate moving block"
     JSON: {"action": "set_cbtc", "enabled": true}
   - CBTC mode: "set train 1 to auto mode", "switch to protective manual"
     Modes: auto, pm, rm, off, storage
     JSON: {"action": "set_cbtc_mode", "train_id": "1", "mode": "auto"}
   - WiFi control: "toggle WiFi antenna", "enable CBTC WiFi"
     JSON: {"action": "toggle_wifi", "enabled": true}
   - Platform doors: "open platform doors", "enable CBTC door timing"
     JSON: {"action": "toggle_platform_doors", "enabled": true}

5. EDIT MODE & LAYOUT
   - Toggle edit mode: "enable edit mode", "start editing layout"
     JSON: {"action": "toggle_edit_mode", "enabled": true}
   - Save layout: "save current layout", "export layout to JSON"
     JSON: {"action": "save_layout", "filename": "my_layout.json"}
   - Load layout: "load layout from file", "import custom layout"
     JSON: {"action": "load_layout", "filename": "custom_layout.json"}
   - Export scenario: "export scenario", "save scenario as JSON"
     JSON: {"action": "export_scenario", "filename": "scenario.json"}
   - Resize platform: "make platform P1 longer", "adjust platform size"
     JSON: {"action": "resize_platform", "platform_id": "P1", "length": 300}

6. TIMETABLE & SCHEDULING
   - Enable timetable: "activate timetable", "start scheduled service"
     JSON: {"action": "toggle_timetable", "enabled": true}
   - Add departure: "schedule train at 10:30", "add departure slot"
     JSON: {"action": "add_departure", "time": "10:30", "train_type": "m2"}
   - View schedule: "show timetable", "display schedule"
     JSON: {"action": "show_timetable"}

7. COLLISION & SAFETY
   - Acknowledge collision: "acknowledge collision", "clear collision alarm"
     JSON: {"action": "acknowledge_collision"}
   - Start recovery: "start collision recovery", "initiate automatic recovery"
     JSON: {"action": "start_collision_recovery"}
   - Reset AB: "reset AB100", "clear axle counter AB105"
     JSON: {"action": "reset_ab", "ab_id": "AB100"}

8. VISUAL & UI CONTROLS
   - Block highlighting: "enable block highlighting", "highlight blocks on hover"
     JSON: {"action": "toggle_block_highlighting", "enabled": true}
   - Show panels: "show left panel", "hide status panel", "toggle mini map"
     JSON: {"action": "toggle_panel", "panel": "left", "visible": true}
   - Zoom: "zoom in", "zoom out", "reset zoom"
     JSON: {"action": "zoom", "level": "in"}

9. FAULT FINDING & DIAGNOSTICS
   When user asks about faults, failures, or troubleshooting, use the SSM knowledge base to provide step-by-step diagnostic guidance.
   JSON: {"action": "diagnostic", "issue": "point failure", "details": "points failing N to R"}

10. HELP & TUTORIALS
   - General help: "help", "what can you do", "list commands"
     JSON: {"action": "help", "topic": "general"}
   - Specific topics: "help with signals", "tutorial on CBTC", "teach me about points"
     JSON: {"action": "help", "topic": "signals"}

IMPORTANT RULES:
- Understand natural language variations and synonyms
- Infer reasonable defaults when information is missing
- For route IDs, convert "route 1" to "<signal_id>_R1" format
- Point IDs: 76A, 76B, 77A, 77B, 78A, 78B, 79A, 79B, 80A, 80B
- Signal IDs: L01-L10, C10-C31, R01-R10
- Block IDs: 100-115, 198-215, 300-319
- Crossover IDs: crossover_211_212, crossover106, crossover109, crossover_303_304
- Platform IDs: P1-P6
- AB sections: AB100, AB101, AB105, AB108, AB109, AB111, AB112

When providing fault-finding advice, use the diagnostic flowchart from the SSM knowledge base.

Respond ONLY with valid JSON matching these patterns. Be comprehensive and helpful!
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
