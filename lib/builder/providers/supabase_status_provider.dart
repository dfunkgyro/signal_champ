import 'package:flutter/material.dart';

import '../services/supabase_service.dart';

enum SupabaseConnectionStatus {
  idle,
  checking,
  connected,
  disconnected,
  error,
}

class SupabaseStatusProvider with ChangeNotifier {
  SupabaseConnectionStatus _status = SupabaseConnectionStatus.idle;
  String? _message;
  DateTime? _lastCheckedAt;
  List<Map<String, dynamic>> _recentLayouts = const [];

  SupabaseConnectionStatus get status => _status;
  String? get message => _message;
  DateTime? get lastCheckedAt => _lastCheckedAt;
  List<Map<String, dynamic>> get recentLayouts => _recentLayouts;

  bool get isConnected => _status == SupabaseConnectionStatus.connected;

  Future<void> checkConnection() async {
    _status = SupabaseConnectionStatus.checking;
    _message = null;
    notifyListeners();

    try {
      final service = SupabaseService.instance;
      if (!service.isEnabled) {
        _status = SupabaseConnectionStatus.disconnected;
        _message = 'Supabase not initialized.';
      } else {
        await service.checkConnection();
        _status = SupabaseConnectionStatus.connected;
        _message = 'Connected';
      }
    } catch (error) {
      _status = SupabaseConnectionStatus.error;
      _message = error.toString();
    } finally {
      _lastCheckedAt = DateTime.now();
      notifyListeners();
    }
  }

  Future<void> refreshRecentLayouts({int limit = 5}) async {
    try {
      final service = SupabaseService.instance;
      _recentLayouts = await service.fetchRecentLayouts(limit: limit);
      notifyListeners();
    } catch (_) {
      _recentLayouts = const [];
      notifyListeners();
    }
  }
}
