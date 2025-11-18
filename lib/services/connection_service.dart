import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

/// Service for monitoring connection status to AI and Supabase with fallback logic
class ConnectionService extends ChangeNotifier {
  final SupabaseClient _supabase;
  final String? _openAiApiKey;

  bool _isSupabaseConnected = false;
  bool _isAiConnected = false;
  String _supabaseStatus = 'Not checked';
  String _aiStatus = 'Not checked';
  DateTime? _lastSupabaseCheck;
  DateTime? _lastAiCheck;
  Timer? _connectionTimer;

  // Fallback mode - app can work without connections
  bool _fallbackMode = false;

  ConnectionService(this._supabase, {String? openAiApiKey})
      : _openAiApiKey = openAiApiKey {
    _startPeriodicChecks();
  }

  // Getters
  bool get isSupabaseConnected => _isSupabaseConnected;
  bool get isAiConnected => _isAiConnected;
  String get supabaseStatus => _supabaseStatus;
  String get aiStatus => _aiStatus;
  DateTime? get lastSupabaseCheck => _lastSupabaseCheck;
  DateTime? get lastAiCheck => _lastAiCheck;
  bool get fallbackMode => _fallbackMode;
  bool get isFullyConnected => _isSupabaseConnected && _isAiConnected;
  bool get isPartiallyConnected => _isSupabaseConnected || _isAiConnected;

  /// Start periodic connection checks
  void _startPeriodicChecks() {
    // Check immediately
    checkAllConnections();

    // Then check every 30 seconds
    _connectionTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      checkAllConnections();
    });
  }

  /// Check all connections
  Future<void> checkAllConnections() async {
    await Future.wait([
      checkSupabaseConnection(),
      checkAiConnection(),
    ]);
  }

  /// Check Supabase connection
  Future<bool> checkSupabaseConnection() async {
    try {
      _supabaseStatus = 'Checking...';
      notifyListeners();

      // Try to perform a simple query
      final response = await _supabase
          .from('connection_test')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 5));

      _isSupabaseConnected = true;
      _supabaseStatus = 'Connected ✓';
      _lastSupabaseCheck = DateTime.now();
      _fallbackMode = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Try auth status as fallback
      try {
        final session = _supabase.auth.currentSession;
        if (session != null) {
          _isSupabaseConnected = true;
          _supabaseStatus = 'Connected (limited) ✓';
          _lastSupabaseCheck = DateTime.now();
          notifyListeners();
          return true;
        }
      } catch (_) {}

      debugPrint('Supabase connection error: $e');
      _isSupabaseConnected = false;
      _supabaseStatus = 'Disconnected (using fallback)';
      _lastSupabaseCheck = DateTime.now();
      _fallbackMode = true;
      notifyListeners();
      return false;
    }
  }

  /// Check AI (OpenAI) connection
  Future<bool> checkAiConnection() async {
    if (_openAiApiKey == null || _openAiApiKey!.isEmpty) {
      _isAiConnected = false;
      _aiStatus = 'No API key configured';
      _lastAiCheck = DateTime.now();
      notifyListeners();
      return false;
    }

    try {
      _aiStatus = 'Checking...';
      notifyListeners();

      // Try to make a simple API call to check connection
      final response = await http
          .get(
            Uri.parse('https://api.openai.com/v1/models'),
            headers: {
              'Authorization': 'Bearer $_openAiApiKey',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        _isAiConnected = true;
        _aiStatus = 'Connected ✓';
        _lastAiCheck = DateTime.now();
        notifyListeners();
        return true;
      } else {
        _isAiConnected = false;
        _aiStatus = 'Error: ${response.statusCode}';
        _lastAiCheck = DateTime.now();
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('AI connection error: $e');
      _isAiConnected = false;
      _aiStatus = 'Disconnected (AI features disabled)';
      _lastAiCheck = DateTime.now();
      notifyListeners();
      return false;
    }
  }

  /// Enable fallback mode
  void enableFallbackMode() {
    _fallbackMode = true;
    notifyListeners();
  }

  /// Disable fallback mode
  void disableFallbackMode() {
    _fallbackMode = false;
    notifyListeners();
  }

  /// Get connection summary
  Map<String, dynamic> getConnectionSummary() {
    return {
      'supabase': {
        'connected': _isSupabaseConnected,
        'status': _supabaseStatus,
        'last_check': _lastSupabaseCheck?.toIso8601String(),
      },
      'ai': {
        'connected': _isAiConnected,
        'status': _aiStatus,
        'last_check': _lastAiCheck?.toIso8601String(),
      },
      'fallback_mode': _fallbackMode,
      'fully_connected': isFullyConnected,
      'partially_connected': isPartiallyConnected,
    };
  }

  @override
  void dispose() {
    _connectionTimer?.cancel();
    super.dispose();
  }
}
