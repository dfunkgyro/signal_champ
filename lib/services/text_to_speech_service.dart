import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Service for managing text-to-speech (TTS)
class TextToSpeechService extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();

  bool _isAvailable = false;
  bool _isSpeaking = false;
  String _lastError = '';

  // TTS settings
  String _language = 'en-US';
  double _speechRate = 1.0;
  double _volume = 1.0;
  double _pitch = 1.0;

  // Available voices
  List<Map<String, String>> _voices = [];
  Map<String, String>? _currentVoice;

  // Getters
  bool get isAvailable => _isAvailable;
  bool get isSpeaking => _isSpeaking;
  String get lastError => _lastError;
  String get language => _language;
  double get speechRate => _speechRate;
  double get volume => _volume;
  double get pitch => _pitch;
  List<Map<String, String>> get voices => _voices;
  Map<String, String>? get currentVoice => _currentVoice;

  /// Initialize TTS
  Future<bool> initialize() async {
    try {
      // Set up TTS callbacks
      _tts.setStartHandler(() {
        _isSpeaking = true;
        notifyListeners();
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        notifyListeners();
      });

      _tts.setErrorHandler((message) {
        _lastError = message;
        _isSpeaking = false;
        notifyListeners();
      });

      _tts.setCancelHandler(() {
        _isSpeaking = false;
        notifyListeners();
      });

      _tts.setPauseHandler(() {
        notifyListeners();
      });

      _tts.setContinueHandler(() {
        notifyListeners();
      });

      // Set initial settings
      await _tts.setLanguage(_language);
      await _tts.setSpeechRate(_speechRate);
      await _tts.setVolume(_volume);
      await _tts.setPitch(_pitch);

      // Load available voices
      await _loadVoices();

      _isAvailable = true;
      notifyListeners();

      debugPrint('TTS initialized successfully');
      return true;
    } catch (e) {
      _lastError = 'Failed to initialize TTS: $e';
      _isAvailable = false;
      notifyListeners();
      debugPrint('TTS initialization error: $e');
      return false;
    }
  }

  /// Load available voices
  Future<void> _loadVoices() async {
    try {
      final voicesList = await _tts.getVoices;
      if (voicesList is List) {
        _voices = voicesList.map((voice) {
          if (voice is Map) {
            return Map<String, String>.from(
              voice.map((key, value) => MapEntry(key.toString(), value.toString())),
            );
          }
          return <String, String>{};
        }).toList();

        debugPrint('Loaded ${_voices.length} voices');
      }
    } catch (e) {
      debugPrint('Error loading voices: $e');
      _voices = [];
    }
  }

  /// Speak text
  Future<void> speak(String text) async {
    if (!_isAvailable) {
      _lastError = 'TTS not available';
      notifyListeners();
      return;
    }

    if (text.isEmpty) return;

    try {
      // Stop any current speech
      if (_isSpeaking) {
        await stop();
      }

      await _tts.speak(text);
    } catch (e) {
      _lastError = 'Failed to speak: $e';
      notifyListeners();
      debugPrint('TTS speak error: $e');
    }
  }

  /// Stop speaking
  Future<void> stop() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to stop speaking: $e';
      notifyListeners();
    }
  }

  /// Pause speaking
  Future<void> pause() async {
    try {
      await _tts.pause();
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to pause speaking: $e';
      notifyListeners();
    }
  }

  /// Set language
  Future<void> setLanguage(String language) async {
    try {
      await _tts.setLanguage(language);
      _language = language;
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to set language: $e';
      notifyListeners();
    }
  }

  /// Set speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    try {
      final clampedRate = rate.clamp(0.0, 1.0);
      await _tts.setSpeechRate(clampedRate);
      _speechRate = clampedRate;
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to set speech rate: $e';
      notifyListeners();
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      final clampedVolume = volume.clamp(0.0, 1.0);
      await _tts.setVolume(clampedVolume);
      _volume = clampedVolume;
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to set volume: $e';
      notifyListeners();
    }
  }

  /// Set pitch (0.5 to 2.0)
  Future<void> setPitch(double pitch) async {
    try {
      final clampedPitch = pitch.clamp(0.5, 2.0);
      await _tts.setPitch(clampedPitch);
      _pitch = clampedPitch;
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to set pitch: $e';
      notifyListeners();
    }
  }

  /// Set voice
  Future<void> setVoice(Map<String, String> voice) async {
    try {
      await _tts.setVoice(voice);
      _currentVoice = voice;
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to set voice: $e';
      notifyListeners();
    }
  }

  /// Get available languages
  Future<List<String>> getLanguages() async {
    try {
      final languages = await _tts.getLanguages;
      if (languages is List) {
        return languages.map((lang) => lang.toString()).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting languages: $e');
      return [];
    }
  }

  /// Test TTS with sample text
  Future<void> testSpeak() async {
    await speak('Text to speech is working correctly.');
  }

  /// Get user-friendly error message
  String getUserFriendlyError() {
    if (_lastError.isEmpty) return '';

    if (_lastError.contains('not available')) {
      return 'Text-to-speech is not available on this device.';
    } else if (_lastError.contains('language')) {
      return 'Selected language is not supported.';
    } else {
      return 'Text-to-speech error. Please try again.';
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}
