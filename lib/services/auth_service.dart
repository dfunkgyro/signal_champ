import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Authentication service for handling user login, Google Sign-In, and guest mode
class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase;

  User? _currentUser;
  bool _isGuest = false;
  bool _isInitialized = false;
  String _connectionStatus = 'Initializing...';
  bool _isConnected = false;

  AuthService(this._supabase) {
    _initialize();
  }

  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null || _isGuest;
  bool get isGuest => _isGuest;
  bool get isInitialized => _isInitialized;
  String get connectionStatus => _connectionStatus;
  bool get isConnected => _isConnected;
  String? get userId => _isGuest ? 'guest_${_getGuestId()}' : _currentUser?.id;
  String? get userEmail => _isGuest ? 'guest@local' : _currentUser?.email;
  String get displayName {
    if (_isGuest) return 'Guest User';
    return _currentUser?.userMetadata?['full_name'] ??
        _currentUser?.email?.split('@')[0] ??
        'User';
  }

  Future<void> _initialize() async {
    try {
      _updateConnectionStatus('Connecting to Supabase...', false);

      // Listen to auth state changes
      _supabase.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;

        if (event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.tokenRefreshed) {
          _currentUser = session?.user;
          _isGuest = false;
          _updateConnectionStatus('Connected to Supabase', true);
        } else if (event == AuthChangeEvent.signedOut) {
          _currentUser = null;
          _updateConnectionStatus('Disconnected', false);
        }
        notifyListeners();
      });

      // Check for existing session
      final session = _supabase.auth.currentSession;
      if (session != null) {
        _currentUser = session.user;
        _updateConnectionStatus('Connected to Supabase', true);
      } else {
        // Check if user was in guest mode
        final prefs = await SharedPreferences.getInstance();
        _isGuest = prefs.getBool('is_guest') ?? false;
        if (_isGuest) {
          _updateConnectionStatus('Guest mode (offline)', false);
        } else {
          _updateConnectionStatus('Not authenticated', false);
        }
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      _updateConnectionStatus('Connection failed: $e', false);
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  void _updateConnectionStatus(String status, bool connected) {
    _connectionStatus = status;
    _isConnected = connected;
    notifyListeners();
  }

  /// Sign up with email and password
  Future<AuthResult> signUpWithEmail(String email, String password,
      {String? fullName}) async {
    try {
      _updateConnectionStatus('Creating account...', false);

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );

      if (response.user != null) {
        _currentUser = response.user;
        _isGuest = false;
        await _setGuestMode(false);
        _updateConnectionStatus('Connected to Supabase', true);
        return AuthResult(
            success: true, message: 'Account created successfully');
      } else {
        _updateConnectionStatus('Sign up failed', false);
        return AuthResult(success: false, message: 'Sign up failed');
      }
    } catch (e) {
      _updateConnectionStatus('Sign up error', false);
      return AuthResult(success: false, message: 'Error: ${e.toString()}');
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      _updateConnectionStatus('Signing in...', false);

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _currentUser = response.user;
        _isGuest = false;
        await _setGuestMode(false);
        _updateConnectionStatus('Connected to Supabase', true);
        return AuthResult(success: true, message: 'Signed in successfully');
      } else {
        _updateConnectionStatus('Sign in failed', false);
        return AuthResult(success: false, message: 'Sign in failed');
      }
    } catch (e) {
      _updateConnectionStatus('Sign in error', false);
      return AuthResult(success: false, message: 'Error: ${e.toString()}');
    }
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      _updateConnectionStatus('Signing in with Google...', false);

      // Sign in with Google via Supabase
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.railchamp://login-callback/',
      );

      _updateConnectionStatus('Google sign in initiated', false);
      return AuthResult(success: true, message: 'Google sign in initiated');
    } catch (e) {
      debugPrint('Google sign in error: $e');
      _updateConnectionStatus('Google sign in error', false);
      return AuthResult(success: false, message: 'Error: ${e.toString()}');
    }
  }

  /// Continue as guest (no authentication required)
  Future<AuthResult> continueAsGuest() async {
    try {
      _isGuest = true;
      _currentUser = null;
      await _setGuestMode(true);
      _updateConnectionStatus('Guest mode (offline)', false);
      return AuthResult(success: true, message: 'Continuing as guest');
    } catch (e) {
      return AuthResult(success: false, message: 'Error: ${e.toString()}');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      if (!_isGuest) {
        await _supabase.auth.signOut();
      }
      _currentUser = null;
      _isGuest = false;
      await _setGuestMode(false);
      _updateConnectionStatus('Signed out', false);
    } catch (e) {
      debugPrint('Sign out error: $e');
      _updateConnectionStatus('Sign out error', false);
    }
  }

  /// Reset password
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return AuthResult(success: true, message: 'Password reset email sent');
    } catch (e) {
      return AuthResult(success: false, message: 'Error: ${e.toString()}');
    }
  }

  /// Save user settings to Supabase
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    if (_isGuest) {
      // Save locally for guest users
      final prefs = await SharedPreferences.getInstance();
      settings.forEach((key, value) {
        if (value is String) {
          prefs.setString('setting_$key', value);
        } else if (value is int) {
          prefs.setInt('setting_$key', value);
        } else if (value is double) {
          prefs.setDouble('setting_$key', value);
        } else if (value is bool) {
          prefs.setBool('setting_$key', value);
        }
      });
      return;
    }

    try {
      await _supabase.from('user_settings').upsert({
        'user_id': userId,
        'settings': settings,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving settings: $e');
      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      settings.forEach((key, value) {
        if (value is String) {
          prefs.setString('setting_$key', value);
        } else if (value is int) {
          prefs.setInt('setting_$key', value);
        } else if (value is double) {
          prefs.setDouble('setting_$key', value);
        } else if (value is bool) {
          prefs.setBool('setting_$key', value);
        }
      });
    }
  }

  /// Load user settings from Supabase
  Future<Map<String, dynamic>> loadSettings() async {
    if (_isGuest) {
      // Load from local storage for guest users
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('setting_'));
      final settings = <String, dynamic>{};
      for (final key in keys) {
        final settingKey = key.replaceFirst('setting_', '');
        settings[settingKey] = prefs.get(key);
      }
      return settings;
    }

    try {
      final response = await _supabase
          .from('user_settings')
          .select('settings')
          .eq('user_id', userId!)
          .maybeSingle();

      if (response != null && response['settings'] != null) {
        return Map<String, dynamic>.from(response['settings']);
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }

    // Fallback to local storage
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('setting_'));
    final settings = <String, dynamic>{};
    for (final key in keys) {
      final settingKey = key.replaceFirst('setting_', '');
      settings[settingKey] = prefs.get(key);
    }
    return settings;
  }

  Future<void> _setGuestMode(bool isGuest) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest', isGuest);
  }

  String _getGuestId() {
    // Generate a consistent guest ID
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

/// Result of an authentication operation
class AuthResult {
  final bool success;
  final String message;

  AuthResult({required this.success, required this.message});
}
