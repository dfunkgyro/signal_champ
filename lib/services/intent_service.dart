import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service for loading and processing SSM (Signal & Systems Maintenance) intents
/// Provides troubleshooting guidance through a flowchart-based system
class IntentService extends ChangeNotifier {
  List<Intent> _intents = [];
  Intent? _currentIntent;
  List<Intent> _intentHistory = [];
  bool _isLoaded = false;
  String? _error;

  // Getters
  List<Intent> get intents => _intents;
  Intent? get currentIntent => _currentIntent;
  List<Intent> get intentHistory => _intentHistory;
  bool get isLoaded => _isLoaded;
  String? get error => _error;

  /// Load intents from assets/json/ssm.json
  Future<void> loadIntents() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/json/ssm.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      final List<dynamic> intentsJson = jsonData['intents'] as List<dynamic>;
      _intents = intentsJson.map((json) => Intent.fromJson(json)).toList();

      _isLoaded = true;
      _error = null;
      notifyListeners();

      debugPrint('Loaded ${_intents.length} SSM intents');
    } catch (e) {
      _error = 'Failed to load intents: $e';
      _isLoaded = false;
      debugPrint(_error);
      notifyListeners();
    }
  }

  /// Start a new troubleshooting session
  void startSession() {
    if (_intents.isEmpty) {
      debugPrint('No intents loaded. Call loadIntents() first.');
      return;
    }

    // Find the initial question
    _currentIntent = _intents.firstWhere(
      (intent) => intent.id == 'pointscbtcfail1_initial_question',
      orElse: () => _intents.first,
    );

    _intentHistory.clear();
    _intentHistory.add(_currentIntent!);
    notifyListeners();
  }

  /// Navigate to the next intent based on user's yes/no answer
  void answerCurrentIntent(bool isYes) {
    if (_currentIntent == null) {
      debugPrint('No current intent. Start a session first.');
      return;
    }

    final nextIntentId = isYes ? _currentIntent!.onYes : _currentIntent!.onNo;

    if (nextIntentId == null) {
      debugPrint('Reached end of troubleshooting flow');
      notifyListeners();
      return;
    }

    final nextIntent = _intents.firstWhere(
      (intent) => intent.id == nextIntentId,
      orElse: () {
        debugPrint('Intent not found: $nextIntentId');
        return _currentIntent!;
      },
    );

    _currentIntent = nextIntent;
    _intentHistory.add(nextIntent);
    notifyListeners();
  }

  /// Go back to the previous intent
  void goBack() {
    if (_intentHistory.length <= 1) {
      debugPrint('Already at the first intent');
      return;
    }

    _intentHistory.removeLast();
    _currentIntent = _intentHistory.last;
    notifyListeners();
  }

  /// Reset the troubleshooting session
  void resetSession() {
    _currentIntent = null;
    _intentHistory.clear();
    notifyListeners();
  }

  /// Find an intent by ID
  Intent? findIntentById(String id) {
    try {
      return _intents.firstWhere((intent) => intent.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get all intents that match a search query
  List<Intent> searchIntents(String query) {
    final lowerQuery = query.toLowerCase();
    return _intents.where((intent) {
      return intent.name.toLowerCase().contains(lowerQuery) ||
             intent.question.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get context for AI assistant to help answer questions
  String getAIContext() {
    if (_currentIntent == null) {
      return 'User has not started a troubleshooting session. Available topics: Points CBTC Failure troubleshooting.';
    }

    final context = StringBuffer();
    context.writeln('Current Troubleshooting Session:');
    context.writeln('Current Question: ${_currentIntent!.question}');
    context.writeln('Intent: ${_currentIntent!.name}');

    if (_intentHistory.length > 1) {
      context.writeln('\nPrevious Steps:');
      for (int i = _intentHistory.length - 2; i >= 0 && i >= _intentHistory.length - 4; i--) {
        context.writeln('- ${_intentHistory[i].name}');
      }
    }

    context.writeln('\nAvailable Responses: Yes or No');

    return context.toString();
  }

  /// Generate a summary of the current troubleshooting path
  String getSessionSummary() {
    if (_intentHistory.isEmpty) {
      return 'No active troubleshooting session';
    }

    final summary = StringBuffer();
    summary.writeln('Troubleshooting Path:');
    for (int i = 0; i < _intentHistory.length; i++) {
      summary.writeln('${i + 1}. ${_intentHistory[i].name}');
    }

    return summary.toString();
  }
}

/// Model class for SSM Intent
class Intent {
  final String id;
  final String name;
  final String question;
  final String? onYes;
  final String? onNo;

  Intent({
    required this.id,
    required this.name,
    required this.question,
    this.onYes,
    this.onNo,
  });

  factory Intent.fromJson(Map<String, dynamic> json) {
    return Intent(
      id: json['id'] as String,
      name: json['name'] as String,
      question: json['question'] as String,
      onYes: json['on_yes'] as String?,
      onNo: json['on_no'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'question': question,
      'on_yes': onYes,
      'on_no': onNo,
    };
  }

  /// Check if this is a terminal node (no next steps)
  bool get isTerminal => onYes == null && onNo == null;

  /// Clean up the question text (remove extra whitespace)
  String get cleanQuestion => question.trim().replaceAll(RegExp(r'\s+'), ' ');
}
