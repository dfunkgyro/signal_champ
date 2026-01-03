import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/railway_model.dart' as railway;

class OpenAiConfig {
  final String apiKey;
  final String model;
  final bool enabled;

  const OpenAiConfig({
    required this.apiKey,
    required this.model,
    required this.enabled,
  });

  static Future<OpenAiConfig> loadFromAssets() async {
    final content = await rootBundle.loadString('assets/.env');
    final values = _parseEnv(content);

    return OpenAiConfig(
      apiKey: values['OPENAI_API_KEY'] ?? '',
      model: values['OPENAI_MODEL'] ?? 'gpt-3.5-turbo',
      enabled: (values['USE_OPENAI'] ?? 'true').toLowerCase() == 'true',
    );
  }

  static Map<String, String> _parseEnv(String content) {
    final values = <String, String>{};
    for (final line in const LineSplitter().convert(content)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        continue;
      }
      final separatorIndex = trimmed.indexOf('=');
      if (separatorIndex == -1) {
        continue;
      }
      final key = trimmed.substring(0, separatorIndex).trim();
      final value = trimmed.substring(separatorIndex + 1).trim();
      if (key.isNotEmpty) {
        values[key] = value;
      }
    }
    return values;
  }
}

class AIAgentIssue {
  final String severity;
  final String message;
  final String? suggestion;

  const AIAgentIssue({
    required this.severity,
    required this.message,
    this.suggestion,
  });
}

class AIAgentValidation {
  final String summary;
  final bool? canSupportMultipleTrains;
  final List<AIAgentIssue> issues;

  const AIAgentValidation({
    required this.summary,
    required this.canSupportMultipleTrains,
    required this.issues,
  });
}

class AIAgentLayout {
  final railway.RailwayData data;
  final List<railway.TextAnnotation> labels;

  const AIAgentLayout({
    required this.data,
    required this.labels,
  });
}

class AIAgentResponse {
  final AIAgentLayout? layout;
  final AIAgentLayout? recommendedLayout;
  final AIAgentValidation? validation;
  final List<String> advice;
  final String rawText;

  const AIAgentResponse({
    required this.layout,
    required this.recommendedLayout,
    required this.validation,
    required this.advice,
    required this.rawText,
  });
}

class OpenAiAgentService {
  final OpenAiConfig config;
  final http.Client _client;

  OpenAiAgentService({
    required this.config,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<AIAgentResponse> generateLayout({
    required String description,
    required railway.RailwayData currentData,
  }) async {
    final response = await _sendChatRequest(
      systemPrompt: _systemPromptForLayout(),
      userPrompt: _userPromptForLayout(description, currentData),
    );

    return _parseAgentResponse(response);
  }

  Future<AIAgentResponse> validateLayout({
    required String description,
    required railway.RailwayData currentData,
  }) async {
    final response = await _sendChatRequest(
      systemPrompt: _systemPromptForValidation(),
      userPrompt: _userPromptForValidation(description, currentData),
    );

    return _parseAgentResponse(response);
  }

  Future<String> _sendChatRequest({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    if (!config.enabled) {
      throw StateError('OpenAI integration is disabled in assets/.env.');
    }
    if (config.apiKey.isEmpty) {
      throw StateError('OPENAI_API_KEY is missing in assets/.env.');
    }

    final payload = {
      'model': config.model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'temperature': 0.2,
    };

    final response = await _client.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${config.apiKey}',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
          'OpenAI request failed (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>? ?? [];
    if (choices.isEmpty) {
      throw StateError('OpenAI response did not include any choices.');
    }
    final message = choices.first['message'] as Map<String, dynamic>? ?? {};
    final content = message['content'] as String? ?? '';
    if (content.trim().isEmpty) {
      throw StateError('OpenAI response was empty.');
    }

    return content;
  }

  AIAgentResponse _parseAgentResponse(String content) {
    final jsonMap = _decodeJsonFromContent(content);
    final layout = _parseLayout(jsonMap['layout']);
    final recommendedLayout = _parseLayout(jsonMap['recommendedLayout']);
    final validation = _parseValidation(jsonMap['validation']);
    final adviceList = _parseAdvice(jsonMap['advice']);

    return AIAgentResponse(
      layout: layout,
      recommendedLayout: recommendedLayout,
      validation: validation,
      advice: adviceList,
      rawText: content,
    );
  }

  Map<String, dynamic> _decodeJsonFromContent(String content) {
    var trimmed = content.trim();
    if (trimmed.startsWith('```')) {
      trimmed = trimmed.replaceAll(RegExp(r'^```[a-zA-Z]*'), '');
      trimmed = trimmed.replaceAll(RegExp(r'```$'), '');
      trimmed = trimmed.trim();
    }
    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) {
      throw FormatException('Failed to locate JSON in response.');
    }
    final jsonText = trimmed.substring(start, end + 1);
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Expected JSON object at top-level.');
    }
    return decoded;
  }

  AIAgentLayout? _parseLayout(dynamic payload) {
    if (payload is! Map<String, dynamic>) {
      return null;
    }
    final blocks = _parseBlocks(payload['blocks']);
    final points = _parsePoints(payload['points']);
    final signals = _parseSignals(payload['signals']);
    final platforms = _parsePlatforms(payload['platforms']);
    final labels = _parseLabels(payload['textAnnotations']);

    return AIAgentLayout(
      data: railway.RailwayData(
        blocks: blocks,
        points: points,
        signals: signals,
        platforms: platforms,
      ),
      labels: labels,
    );
  }

  List<railway.Block> _parseBlocks(dynamic payload) {
    if (payload is! List) {
      return [];
    }
    return payload.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value as Map<String, dynamic>? ?? {};
      final id = data['id']?.toString() ?? 'ai_block_$index';
      final startX = _toDouble(data['startX'] ?? data['start']);
      final endX = _toDouble(data['endX'] ?? data['end'] ?? startX + 120);
      final y = _toDouble(data['y']);
      final occupied = data['occupied'] == true;
      final occupyingTrain =
          data['occupyingTrain']?.toString() ?? 'none';
      final type = _parseBlockType(data['type']?.toString());

      return railway.Block(
        id: id,
        startX: startX,
        endX: endX,
        y: y,
        occupied: occupied,
        occupyingTrain: occupyingTrain,
        type: type,
      );
    }).toList();
  }

  List<railway.Point> _parsePoints(dynamic payload) {
    if (payload is! List) {
      return [];
    }
    return payload.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value as Map<String, dynamic>? ?? {};
      final id = data['id']?.toString() ?? 'ai_point_$index';
      final x = _toDouble(data['x']);
      final y = _toDouble(data['y']);
      final position = data['position']?.toString() ?? 'normal';
      final locked = data['locked'] == true;
      final connectedBlocks =
          (data['connectedBlocks'] as List<dynamic>? ?? [])
              .map((value) => value.toString())
              .toList();

      return railway.Point(
        id: id,
        x: x,
        y: y,
        position: position,
        locked: locked,
        connectedBlocks: connectedBlocks,
      );
    }).toList();
  }

  List<railway.Signal> _parseSignals(dynamic payload) {
    if (payload is! List) {
      return [];
    }
    return payload.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value as Map<String, dynamic>? ?? {};
      final id = data['id']?.toString() ?? 'ai_signal_$index';
      final x = _toDouble(data['x']);
      final y = _toDouble(data['y']);
      final aspect = data['aspect']?.toString() ?? 'red';
      final state = data['state']?.toString() ?? 'unset';
      final direction = data['direction']?.toString() ?? 'left';
      final type = data['type']?.toString() ?? 'main';
      final routes = _parseRoutes(data['routes']);

      return railway.Signal(
        id: id,
        x: x,
        y: y,
        aspect: aspect,
        state: state,
        routes: routes,
        direction: direction,
        type: type,
      );
    }).toList();
  }

  List<railway.Route> _parseRoutes(dynamic payload) {
    if (payload is! List) {
      return [];
    }
    return payload.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value as Map<String, dynamic>? ?? {};
      return railway.Route(
        id: data['id']?.toString() ?? 'ai_route_$index',
        name: data['name']?.toString() ?? 'Route ${index + 1}',
        requiredBlocks: (data['requiredBlocks'] as List<dynamic>? ?? [])
            .map((value) => value.toString())
            .toList(),
        pathBlocks: (data['pathBlocks'] as List<dynamic>? ?? [])
            .map((value) => value.toString())
            .toList(),
        conflictingRoutes:
            (data['conflictingRoutes'] as List<dynamic>? ?? [])
                .map((value) => value.toString())
                .toList(),
        startSignal: data['startSignal']?.toString() ?? '',
        endSignal: data['endSignal']?.toString() ?? '',
      );
    }).toList();
  }

  List<railway.Platform> _parsePlatforms(dynamic payload) {
    if (payload is! List) {
      return [];
    }
    return payload.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value as Map<String, dynamic>? ?? {};
      final id = data['id']?.toString() ?? 'ai_platform_$index';
      final name = data['name']?.toString() ?? 'Platform ${index + 1}';
      final startX = _toDouble(data['startX'] ?? data['start']);
      final endX = _toDouble(data['endX'] ?? data['end'] ?? startX + 180);
      final y = _toDouble(data['y']);
      final occupied = data['occupied'] == true;
      final side = data['side']?.toString() ?? 'left';
      final capacity = _toInt(data['capacity'] ?? 500);

      return railway.Platform(
        id: id,
        name: name,
        startX: startX,
        endX: endX,
        y: y,
        occupied: occupied,
        side: side,
        capacity: capacity,
      );
    }).toList();
  }

  List<railway.TextAnnotation> _parseLabels(dynamic payload) {
    if (payload is! List) {
      return [];
    }
    return payload.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value as Map<String, dynamic>? ?? {};
      final id = data['id']?.toString() ?? 'ai_label_$index';
      final text = data['text']?.toString() ?? 'Label ${index + 1}';
      final x = _toDouble(data['x']);
      final y = _toDouble(data['y']);
      final fontSize = _toDouble(data['fontSize'] ?? 12);
      final color = _parseColor(data['color']);

      return railway.TextAnnotation(
        id: id,
        text: text,
        position: Offset(x, y),
        fontSize: fontSize,
        color: color,
      );
    }).toList();
  }

  AIAgentValidation? _parseValidation(dynamic payload) {
    if (payload is! Map<String, dynamic>) {
      return null;
    }
    final summary = payload['summary']?.toString() ?? '';
    final canSupport = payload['canSupportMultipleTrains'] as bool?;
    final issuesPayload = payload['issues'];
    final issues = <AIAgentIssue>[];
    if (issuesPayload is List) {
      for (final item in issuesPayload) {
        final issue = item as Map<String, dynamic>? ?? {};
        issues.add(AIAgentIssue(
          severity: issue['severity']?.toString() ?? 'info',
          message: issue['message']?.toString() ?? '',
          suggestion: issue['suggestion']?.toString(),
        ));
      }
    }

    return AIAgentValidation(
      summary: summary,
      canSupportMultipleTrains: canSupport,
      issues: issues,
    );
  }

  List<String> _parseAdvice(dynamic payload) {
    if (payload is List) {
      return payload.map((value) => value.toString()).toList();
    }
    if (payload is String && payload.trim().isNotEmpty) {
      return [payload.trim()];
    }
    return [];
  }

  String _systemPromptForLayout() {
    return '''
You are an expert railway layout designer embedded in a SVG rail editor.
Return JSON only. Do not include markdown, comments, or extra text.

Goal: Create a complete railway layout based on the user request.
Include tracks, signals, points, crossovers, platforms, and labels.
The editor expects coordinates in a 2D plane. Use consistent spacing.

Output JSON schema:
{
  "layout": {
    "blocks": [
      {"id":"b1","startX":100,"endX":400,"y":200,"type":"straight","occupied":false}
    ],
    "points": [
      {"id":"p1","x":250,"y":200,"position":"normal","locked":false}
    ],
    "signals": [
      {"id":"s1","x":110,"y":180,"aspect":"red","state":"unset","direction":"left","type":"main","routes":[]}
    ],
    "platforms": [
      {"id":"pl1","name":"Platform 1","startX":150,"endX":350,"y":230,"occupied":false,"side":"left","capacity":500}
    ]
  },
  "textAnnotations": [
    {"text":"Station A","x":240,"y":260,"fontSize":12,"color":"#222222"}
  ],
  "validation": {
    "summary": "Short review of operational viability.",
    "canSupportMultipleTrains": true,
    "issues": [
      {"severity":"warning","message":"Issue text","suggestion":"Fix suggestion"}
    ]
  },
  "advice": ["Extra tips or assumptions"]
}

Only include fields you can support with high confidence. Use block types:
straight, crossover, curve, switchLeft, switchRight, station, end.
''';
  }

  String _systemPromptForValidation() {
    return '''
You are an expert railway layout validator embedded in a SVG rail editor.
Return JSON only. Do not include markdown, comments, or extra text.

Goal: Validate the provided layout for operations with multiple trains.
Identify conflicts, missing signals, unsafe crossovers, or poor flow.
If improvements are needed, provide a recommendedLayout.

Output JSON schema:
{
  "validation": {
    "summary": "Short review of operational viability.",
    "canSupportMultipleTrains": true,
    "issues": [
      {"severity":"warning","message":"Issue text","suggestion":"Fix suggestion"}
    ]
  },
  "advice": ["Extra tips or assumptions"],
  "recommendedLayout": { ...same shape as layout... }
}
''';
  }

  String _userPromptForLayout(
      String description, railway.RailwayData currentData) {
    return '''
User description:
$description

Current layout data (JSON):
${jsonEncode(currentData.toJson())}
''';
  }

  String _userPromptForValidation(
      String description, railway.RailwayData currentData) {
    return '''
Validation request:
$description

Current layout data (JSON):
${jsonEncode(currentData.toJson())}
''';
  }

  railway.BlockType _parseBlockType(String? value) {
    switch (value?.toLowerCase()) {
      case 'crossover':
        return railway.BlockType.crossover;
      case 'curve':
        return railway.BlockType.curve;
      case 'switchleft':
      case 'switch_left':
      case 'leftswitch':
        return railway.BlockType.switchLeft;
      case 'switchright':
      case 'switch_right':
      case 'rightswitch':
        return railway.BlockType.switchRight;
      case 'station':
        return railway.BlockType.station;
      case 'end':
      case 'endbuffer':
      case 'buffer':
        return railway.BlockType.end;
      case 'straight':
      default:
        return railway.BlockType.straight;
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  Color _parseColor(dynamic value) {
    if (value is String) {
      final cleaned = value.replaceAll('#', '').trim();
      if (cleaned.length == 6) {
        final parsed = int.tryParse(cleaned, radix: 16);
        if (parsed != null) {
          return Color(0xFF000000 | parsed);
        }
      }
      if (cleaned.length == 8) {
        final parsed = int.tryParse(cleaned, radix: 16);
        if (parsed != null) {
          return Color(parsed);
        }
      }
    }
    return const Color(0xFF000000);
  }
}
