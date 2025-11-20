import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing widget appearance customization preferences
class WidgetPreferencesService extends ChangeNotifier {
  static const String _minimapWidthKey = 'minimap_width';
  static const String _minimapHeightKey = 'minimap_height';
  static const String _minimapBorderColorKey = 'minimap_border_color';
  static const String _minimapHeaderColorKey = 'minimap_header_color';
  static const String _minimapBackgroundColorKey = 'minimap_background_color';
  static const String _minimapBorderWidthKey = 'minimap_border_width';

  static const String _searchBarHeightKey = 'search_bar_height';
  static const String _searchBarColorKey = 'search_bar_color';
  static const String _searchBarTextSizeKey = 'search_bar_text_size';

  static const String _aiAgentWidthKey = 'ai_agent_width';
  static const String _aiAgentHeightKey = 'ai_agent_height';
  static const String _aiAgentColorKey = 'ai_agent_color';
  static const String _aiAgentExpandedWidthKey = 'ai_agent_expanded_width';
  static const String _aiAgentExpandedHeightKey = 'ai_agent_expanded_height';

  static const String _voiceEnabledKey = 'voice_enabled';
  static const String _ttsEnabledKey = 'tts_enabled';
  static const String _wakeWordEnabledKey = 'wake_word_enabled';
  static const String _voiceLanguageKey = 'voice_language';
  static const String _speechRateKey = 'speech_rate';
  static const String _voicePitchKey = 'voice_pitch';

  SharedPreferences? _prefs;

  // Minimap settings
  double _minimapWidth = 280.0;
  double _minimapHeight = 140.0;
  Color _minimapBorderColor = Colors.orange;
  Color _minimapHeaderColor = Colors.orange;
  Color _minimapBackgroundColor = const Color(0xFF212121);
  double _minimapBorderWidth = 2.0;

  // Search bar settings
  double _searchBarHeight = 56.0;
  Color _searchBarColor = Colors.orange;
  double _searchBarTextSize = 14.0;

  // AI Agent settings (match minimap dimensions)
  double _aiAgentWidth = 280.0;
  double _aiAgentHeight = 140.0; // Matches minimap height
  Color _aiAgentColor = Colors.orange; // Default orange like other widgets
  double _aiAgentExpandedWidth = 400.0;
  double _aiAgentExpandedHeight = 500.0;

  // Voice settings
  bool _voiceEnabled = true;
  bool _ttsEnabled = true;
  bool _wakeWordEnabled = false;
  String _voiceLanguage = 'en-US';
  double _speechRate = 1.0;
  double _voicePitch = 1.0;

  // Getters - Minimap
  double get minimapWidth => _minimapWidth;
  double get minimapHeight => _minimapHeight;
  Color get minimapBorderColor => _minimapBorderColor;
  Color get minimapHeaderColor => _minimapHeaderColor;
  Color get minimapBackgroundColor => _minimapBackgroundColor;
  double get minimapBorderWidth => _minimapBorderWidth;

  // Getters - Search Bar
  double get searchBarHeight => _searchBarHeight;
  Color get searchBarColor => _searchBarColor;
  double get searchBarTextSize => _searchBarTextSize;

  // Getters - AI Agent
  double get aiAgentWidth => _aiAgentWidth;
  double get aiAgentHeight => _aiAgentHeight;
  Color get aiAgentColor => _aiAgentColor;
  double get aiAgentExpandedWidth => _aiAgentExpandedWidth;
  double get aiAgentExpandedHeight => _aiAgentExpandedHeight;

  // Getters - Voice
  bool get voiceEnabled => _voiceEnabled;
  bool get ttsEnabled => _ttsEnabled;
  bool get wakeWordEnabled => _wakeWordEnabled;
  String get voiceLanguage => _voiceLanguage;
  double get speechRate => _speechRate;
  double get voicePitch => _voicePitch;

  /// Initialize preferences
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPreferences();
  }

  /// Load all preferences
  Future<void> _loadPreferences() async {
    if (_prefs == null) return;

    // Minimap
    _minimapWidth = _prefs!.getDouble(_minimapWidthKey) ?? 280.0;
    _minimapHeight = _prefs!.getDouble(_minimapHeightKey) ?? 140.0;
    _minimapBorderColor = Color(_prefs!.getInt(_minimapBorderColorKey) ?? Colors.orange.value);
    _minimapHeaderColor = Color(_prefs!.getInt(_minimapHeaderColorKey) ?? Colors.orange.value);
    _minimapBackgroundColor = Color(_prefs!.getInt(_minimapBackgroundColorKey) ?? 0xFF212121);
    _minimapBorderWidth = _prefs!.getDouble(_minimapBorderWidthKey) ?? 2.0;

    // Search Bar
    _searchBarHeight = _prefs!.getDouble(_searchBarHeightKey) ?? 56.0;
    _searchBarColor = Color(_prefs!.getInt(_searchBarColorKey) ?? Colors.orange.value);
    _searchBarTextSize = _prefs!.getDouble(_searchBarTextSizeKey) ?? 14.0;

    // AI Agent (defaults match minimap dimensions)
    _aiAgentWidth = _prefs!.getDouble(_aiAgentWidthKey) ?? 280.0;
    _aiAgentHeight = _prefs!.getDouble(_aiAgentHeightKey) ?? 140.0; // Match minimap height
    _aiAgentColor = Color(_prefs!.getInt(_aiAgentColorKey) ?? Colors.orange.value);
    _aiAgentExpandedWidth = _prefs!.getDouble(_aiAgentExpandedWidthKey) ?? 400.0;
    _aiAgentExpandedHeight = _prefs!.getDouble(_aiAgentExpandedHeightKey) ?? 500.0;

    // Voice
    _voiceEnabled = _prefs!.getBool(_voiceEnabledKey) ?? true;
    _ttsEnabled = _prefs!.getBool(_ttsEnabledKey) ?? true;
    _wakeWordEnabled = _prefs!.getBool(_wakeWordEnabledKey) ?? false;
    _voiceLanguage = _prefs!.getString(_voiceLanguageKey) ?? 'en-US';
    _speechRate = _prefs!.getDouble(_speechRateKey) ?? 1.0;
    _voicePitch = _prefs!.getDouble(_voicePitchKey) ?? 1.0;

    notifyListeners();
  }

  // Setters - Minimap
  Future<void> setMinimapWidth(double value) async {
    _minimapWidth = value;
    await _prefs?.setDouble(_minimapWidthKey, value);
    notifyListeners();
  }

  Future<void> setMinimapHeight(double value) async {
    _minimapHeight = value;
    await _prefs?.setDouble(_minimapHeightKey, value);
    notifyListeners();
  }

  Future<void> setMinimapBorderColor(Color value) async {
    _minimapBorderColor = value;
    await _prefs?.setInt(_minimapBorderColorKey, value.value);
    notifyListeners();
  }

  Future<void> setMinimapHeaderColor(Color value) async {
    _minimapHeaderColor = value;
    await _prefs?.setInt(_minimapHeaderColorKey, value.value);
    notifyListeners();
  }

  Future<void> setMinimapBackgroundColor(Color value) async {
    _minimapBackgroundColor = value;
    await _prefs?.setInt(_minimapBackgroundColorKey, value.value);
    notifyListeners();
  }

  Future<void> setMinimapBorderWidth(double value) async {
    _minimapBorderWidth = value;
    await _prefs?.setDouble(_minimapBorderWidthKey, value);
    notifyListeners();
  }

  // Setters - Search Bar
  Future<void> setSearchBarHeight(double value) async {
    _searchBarHeight = value;
    await _prefs?.setDouble(_searchBarHeightKey, value);
    notifyListeners();
  }

  Future<void> setSearchBarColor(Color value) async {
    _searchBarColor = value;
    await _prefs?.setInt(_searchBarColorKey, value.value);
    notifyListeners();
  }

  Future<void> setSearchBarTextSize(double value) async {
    _searchBarTextSize = value;
    await _prefs?.setDouble(_searchBarTextSizeKey, value);
    notifyListeners();
  }

  // Setters - AI Agent
  Future<void> setAiAgentWidth(double value) async {
    _aiAgentWidth = value;
    await _prefs?.setDouble(_aiAgentWidthKey, value);
    notifyListeners();
  }

  Future<void> setAiAgentHeight(double value) async {
    _aiAgentHeight = value;
    await _prefs?.setDouble(_aiAgentHeightKey, value);
    notifyListeners();
  }

  Future<void> setAiAgentColor(Color value) async {
    _aiAgentColor = value;
    await _prefs?.setInt(_aiAgentColorKey, value.value);
    notifyListeners();
  }

  Future<void> setAiAgentExpandedWidth(double value) async {
    _aiAgentExpandedWidth = value;
    await _prefs?.setDouble(_aiAgentExpandedWidthKey, value);
    notifyListeners();
  }

  Future<void> setAiAgentExpandedHeight(double value) async {
    _aiAgentExpandedHeight = value;
    await _prefs?.setDouble(_aiAgentExpandedHeightKey, value);
    notifyListeners();
  }

  // Setters - Voice
  Future<void> setVoiceEnabled(bool value) async {
    _voiceEnabled = value;
    await _prefs?.setBool(_voiceEnabledKey, value);
    notifyListeners();
  }

  Future<void> setTtsEnabled(bool value) async {
    _ttsEnabled = value;
    await _prefs?.setBool(_ttsEnabledKey, value);
    notifyListeners();
  }

  Future<void> setWakeWordEnabled(bool value) async {
    _wakeWordEnabled = value;
    await _prefs?.setBool(_wakeWordEnabledKey, value);
    notifyListeners();
  }

  Future<void> setVoiceLanguage(String value) async {
    _voiceLanguage = value;
    await _prefs?.setString(_voiceLanguageKey, value);
    notifyListeners();
  }

  Future<void> setSpeechRate(double value) async {
    _speechRate = value;
    await _prefs?.setDouble(_speechRateKey, value);
    notifyListeners();
  }

  Future<void> setVoicePitch(double value) async {
    _voicePitch = value;
    await _prefs?.setDouble(_voicePitchKey, value);
    notifyListeners();
  }

  /// Reset all preferences to defaults
  Future<void> resetToDefaults() async {
    // Minimap defaults - Orange theme
    _minimapWidth = 280.0;
    _minimapHeight = 140.0;
    _minimapBorderColor = Colors.orange;
    _minimapHeaderColor = Colors.orange;
    _minimapBackgroundColor = const Color(0xFF212121);
    _minimapBorderWidth = 2.0;

    // Search bar defaults - Orange theme
    _searchBarHeight = 56.0;
    _searchBarColor = Colors.orange;
    _searchBarTextSize = 14.0;

    // AI Agent defaults - Orange theme with better readability
    _aiAgentWidth = 280.0;
    _aiAgentHeight = 80.0;
    _aiAgentColor = Colors.orange;
    _aiAgentExpandedWidth = 400.0;
    _aiAgentExpandedHeight = 500.0;

    // Voice defaults
    _voiceEnabled = true;
    _ttsEnabled = true;
    _wakeWordEnabled = false;
    _voiceLanguage = 'en-US';
    _speechRate = 1.0;
    _voicePitch = 1.0;

    // Save all defaults
    await _prefs?.clear();
    await _loadPreferences();
    notifyListeners();
  }

  /// Get preset color schemes
  static List<Map<String, dynamic>> getColorPresets() {
    return [
      {
        'name': 'Orange (Default)',
        'color': Colors.orange,
      },
      {
        'name': 'Blue',
        'color': Colors.blue,
      },
      {
        'name': 'Green',
        'color': Colors.green,
      },
      {
        'name': 'Purple',
        'color': Colors.purple,
      },
      {
        'name': 'Red',
        'color': Colors.red,
      },
      {
        'name': 'Teal',
        'color': Colors.teal,
      },
      {
        'name': 'Amber',
        'color': Colors.amber,
      },
      {
        'name': 'Cyan',
        'color': Colors.cyan,
      },
    ];
  }
}
