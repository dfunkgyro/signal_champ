import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class UserPresence {
  final String userId;
  final String username;
  final DateTime lastSeen;

  UserPresence({
    required this.userId,
    required this.username,
    required this.lastSeen,
  });

  factory UserPresence.fromJson(Map<String, dynamic> json) {
    return UserPresence(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      lastSeen: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'timestamp': lastSeen.toIso8601String(),
    };
  }
}

class SupabaseService extends ChangeNotifier {
  final SupabaseClient _supabase;
  RealtimeChannel? _presenceChannel;
  final Map<String, UserPresence> _activeUsers = {};
  String? _currentUserId;
  bool _isConnected = false;
  String _connectionStatus = 'Not connected';

  SupabaseService(this._supabase) {
    _currentUserId = _supabase.auth.currentUser?.id;
    _isConnected = _currentUserId != null;
    _connectionStatus = _isConnected ? 'Connected' : 'Not authenticated';
  }

  bool get isConnected => _isConnected;
  String get connectionStatus => _connectionStatus;
  Map<String, UserPresence> get activeUsers => Map.unmodifiable(_activeUsers);

  Future<void> initializePresence() async {
    if (_currentUserId == null) {
      _currentUserId = 'anonymous_${DateTime.now().millisecondsSinceEpoch}';
    }

    try {
      _presenceChannel = _supabase.channel('railway_presence');

      _presenceChannel!.onPresenceSync((payload) {
        _handlePresenceSync();
      }).onPresenceJoin((payload) {
        debugPrint('User joined: $payload');
      }).onPresenceLeave((payload) {
        debugPrint('User left: $payload');
      }).subscribe((status, error) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          _presenceChannel!.track({
            'user_id': _currentUserId,
            'username': 'Engineer $_currentUserId',
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      });

      _isConnected = true;
      _connectionStatus = 'Connected with presence';
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing presence: $e');
      _isConnected = false;
      _connectionStatus = 'Connection error: $e';
      notifyListeners();
    }
  }

  void _handlePresenceSync() {
    // For now, just acknowledge the sync
    // The actual presence data will be tracked via track() method
    // You can enhance this later once you test the actual structure
    final state = _presenceChannel?.presenceState();

    debugPrint(
        'Presence sync received. Active presences: ${state?.length ?? 0}');

    // Clear and rebuild would go here once you know the exact structure
    // For now, just notify listeners that presence changed
    notifyListeners();
  }

  Future<void> recordMetric(String metricName, double value) async {
    if (_currentUserId == null) return;

    try {
      await _supabase.from('metrics').insert({
        'user_id': _currentUserId,
        'metric_name': metricName,
        'value': value,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error recording metric: $e');
    }
  }

  Future<Map<String, dynamic>> getMetricStats(
    String metricName,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await _supabase.rpc('calculate_metric_stats', params: {
        'metric_name': metricName,
        'start_time': start.toIso8601String(),
        'end_time': end.toIso8601String(),
      });

      return response as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting metric stats: $e');
      return {};
    }
  }

  Future<void> dispose() async {
    await _presenceChannel?.unsubscribe();
    super.dispose();
  }
}
