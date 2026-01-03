import 'dart:convert';

import 'package:http/http.dart' as http;

import 'openai_agent_service.dart';

class TerminalAgentResponse {
  final String? xmlLayout;
  final String? recommendedXml;
  final String summary;
  final List<String> advice;
  final String rawText;

  const TerminalAgentResponse({
    required this.xmlLayout,
    required this.recommendedXml,
    required this.summary,
    required this.advice,
    required this.rawText,
  });
}

class OpenAiTerminalAgentService {
  final OpenAiConfig config;
  final http.Client _client;

  OpenAiTerminalAgentService({
    required this.config,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<TerminalAgentResponse> generateLayout({
    required String description,
    required String currentXml,
  }) async {
    final response = await _sendChatRequest(
      systemPrompt: _systemPromptForGeneration(),
      userPrompt: _userPrompt(description, currentXml),
    );
    return _parseResponse(response);
  }

  Future<TerminalAgentResponse> validateLayout({
    required String description,
    required String currentXml,
  }) async {
    final response = await _sendChatRequest(
      systemPrompt: _systemPromptForValidation(),
      userPrompt: _userPrompt(description, currentXml),
    );
    return _parseResponse(response);
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

  TerminalAgentResponse _parseResponse(String content) {
    final jsonMap = _decodeJsonFromContent(content);
    final xmlLayout = _asString(jsonMap['xml']);
    final recommendedXml = _asString(jsonMap['recommended_xml']);
    final summary = _asString(jsonMap['summary']) ?? '';
    final adviceList = _parseAdvice(jsonMap['advice']);

    return TerminalAgentResponse(
      xmlLayout: xmlLayout,
      recommendedXml: recommendedXml,
      summary: summary,
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

  List<String> _parseAdvice(dynamic payload) {
    if (payload is List) {
      return payload.map((value) => value.toString()).toList();
    }
    if (payload is String && payload.trim().isNotEmpty) {
      return [payload.trim()];
    }
    return [];
  }

  String? _asString(dynamic value) {
    final text = value?.toString();
    if (text == null || text.trim().isEmpty) return null;
    return text;
  }

  String _systemPromptForGeneration() {
    return '''
You are an expert railway terminal layout designer embedded in an SVG/XML editor.
Return JSON only. Do not include markdown, comments, or extra text.

Goal: Create a complete terminal station layout based on the user request.
You must return XML that matches the editor's schema so it can be imported.
If you cannot improve upon the current XML, still return a full XML layout.

Output JSON schema:
{
  "xml": "<terminalStation>...</terminalStation>",
  "summary": "Short description of the layout",
  "advice": ["Optional tips or assumptions"]
}
''';
  }

  String _systemPromptForValidation() {
    return '''
You are an expert railway terminal layout validator embedded in an SVG/XML editor.
Return JSON only. Do not include markdown, comments, or extra text.

Goal: Validate the provided XML layout for operational safety and capacity.
If improvements are needed, return a recommended_xml with fixes.

Output JSON schema:
{
  "summary": "Short validation summary",
  "advice": ["Issues or improvements"],
  "recommended_xml": "<terminalStation>...</terminalStation>"
}
''';
  }

  String _userPrompt(String description, String currentXml) {
    return '''
User request:
$description

Current layout XML:
$currentXml
''';
  }
}
