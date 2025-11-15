import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIController extends ChangeNotifier {
  String? _apiKey;
  bool _isConnected = false;
  String _connectionStatus = 'Not configured';
  
  bool get isConnected => _isConnected;
  String get connectionStatus => _connectionStatus;
  
  AIController() {
    _initialize();
  }
  
  void _initialize() {
    try {
      _apiKey = dotenv.env['OPENAI_API_KEY'];
      if (_apiKey != null && _apiKey!.isNotEmpty) {
        _isConnected = true;
        _connectionStatus = 'Connected to OpenAI';
      } else {
        _isConnected = false;
        _connectionStatus = 'API key not configured';
      }
    } catch (e) {
      _isConnected = false;
      _connectionStatus = 'Configuration error: $e';
    }
    notifyListeners();
  }
  
  Future<String> analyzeRailwayOperation(String prompt) async {
    if (!_isConnected || _apiKey == null) {
      return 'AI features not available. Please configure OPENAI_API_KEY in assets/.env';
    }
    
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a railway operations expert and simulation analyst. '
                  'Provide detailed, technical analysis and recommendations for railway operations.'
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        return content;
      } else {
        debugPrint('OpenAI API error: ${response.statusCode} - ${response.body}');
        return 'Error: ${response.statusCode} - Unable to get AI analysis';
      }
    } catch (e) {
      debugPrint('AI analysis error: $e');
      return 'Error connecting to AI service: $e';
    }
  }
  
  Future<String> suggestOptimalRoute(Map<String, dynamic> railwayState) async {
    final prompt = '''
Analyze this railway state and suggest the optimal route:

Current State:
${jsonEncode(railwayState)}

Provide:
1. Recommended route
2. Expected travel time
3. Potential conflicts
4. Alternative routes
''';
    
    return await analyzeRailwayOperation(prompt);
  }
  
  Future<String> predictCongestion(Map<String, dynamic> railwayState) async {
    final prompt = '''
Predict potential congestion points in the next 10 minutes:

Current State:
- Active trains: ${railwayState['train_count']}
- Occupied blocks: ${railwayState['occupied_blocks']}
- Signal states: ${railwayState['signal_states']}

Provide:
1. High-risk congestion points
2. Estimated time of congestion
3. Preventive actions
4. Severity (1-10)
''';
    
    return await analyzeRailwayOperation(prompt);
  }
  
  Future<String> diagnoseIssue(String issueDescription) async {
    final prompt = '''
Diagnose this railway simulation issue:

Issue: $issueDescription

Provide:
1. Root cause analysis
2. Step-by-step fix instructions
3. Prevention measures
4. Related issues to check
''';
    
    return await analyzeRailwayOperation(prompt);
  }
  
  Future<List<String>> generateSuggestions(Map<String, dynamic> context) async {
    final prompt = '''
Based on this simulation state, provide 3-5 actionable suggestions:

Context:
${jsonEncode(context)}

Format as a numbered list.
''';
    
    final response = await analyzeRailwayOperation(prompt);
    
    // Parse response into list
    return response
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .take(5)
        .toList();
  }
  
  Future<Map<String, dynamic>> analyzePerformance(
    Map<String, dynamic> metrics,
  ) async {
    final prompt = '''
Analyze these simulation performance metrics:

Metrics:
${jsonEncode(metrics)}

Provide analysis in JSON format:
{
  "overall_score": 0-100,
  "strengths": ["list", "of", "strengths"],
  "weaknesses": ["list", "of", "issues"],
  "recommendations": ["list", "of", "improvements"]
}
''';
    
    final response = await analyzeRailwayOperation(prompt);
    
    try {
      // Try to extract JSON from response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        final jsonStr = response.substring(jsonStart, jsonEnd);
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error parsing AI response: $e');
    }
    
    // Return default structure if parsing fails
    return {
      'overall_score': 75,
      'strengths': ['System operational'],
      'weaknesses': ['Unable to parse detailed analysis'],
      'recommendations': ['Review AI response format'],
    };
  }
  
  Future<String> explainConcept(String concept) async {
    final prompt = '''
Explain this railway concept in simple terms:

Concept: $concept

Provide:
1. Clear definition
2. How it works in railway operations
3. Common examples
4. Related concepts
''';
    
    return await analyzeRailwayOperation(prompt);
  }
  
  Future<String> generateScenario(String theme, String difficulty) async {
    final prompt = '''
Create a railway simulation scenario:

Theme: $theme
Difficulty: $difficulty

Include:
1. Initial setup (train positions, signal states)
2. 3-5 objectives to achieve
3. Challenges and obstacles
4. Success criteria
5. Estimated completion time
''';
    
    return await analyzeRailwayOperation(prompt);
  }
  
  Future<bool> checkConfiguration() async {
    return _isConnected;
  }
  
  void reconnect() {
    _initialize();
  }
}
