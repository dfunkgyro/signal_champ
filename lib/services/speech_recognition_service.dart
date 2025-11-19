import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

/// Service for managing speech recognition (STT)
class SpeechRecognitionService extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isAvailable = false;
  bool _isListening = false;
  String _lastWords = '';
  String _lastError = '';
  double _confidence = 0.0;

  // Wake word detection
  bool _wakeWordMode = false;
  final List<String> _wakeWords = ['ssm', 'search for', 'hey assistant'];
  Function(String)? _onWakeWordDetected;

  // Language settings
  String _currentLocale = 'en-US';
  List<stt.LocaleName> _availableLocales = [];

  // Getters
  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  String get lastError => _lastError;
  double get confidence => _confidence;
  bool get wakeWordMode => _wakeWordMode;
  String get currentLocale => _currentLocale;
  List<stt.LocaleName> get availableLocales => _availableLocales;

  /// Initialize speech recognition
  Future<bool> initialize() async {
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();

      if (!status.isGranted) {
        _lastError = 'Microphone permission denied';
        notifyListeners();
        return false;
      }

      // Initialize speech recognition
      _isAvailable = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
        debugLogging: true,
      );

      if (_isAvailable) {
        // Load available locales
        _availableLocales = await _speech.locales();
        debugPrint('Speech recognition initialized with ${_availableLocales.length} locales');
      } else {
        _lastError = 'Speech recognition not available on this device';
      }

      notifyListeners();
      return _isAvailable;
    } catch (e) {
      _lastError = 'Failed to initialize speech recognition: $e';
      _isAvailable = false;
      notifyListeners();
      return false;
    }
  }

  /// Start listening for speech
  Future<void> startListening({
    required Function(String) onResult,
    String? localeId,
  }) async {
    if (!_isAvailable) {
      _lastError = 'Speech recognition not available';
      notifyListeners();
      return;
    }

    if (_isListening) {
      await stopListening();
    }

    _lastWords = '';
    _lastError = '';

    try {
      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          _confidence = result.confidence;

          // Check for wake words if in wake word mode
          if (_wakeWordMode) {
            _checkForWakeWord(_lastWords.toLowerCase());
          }

          onResult(_lastWords);
          notifyListeners();
        },
        localeId: localeId ?? _currentLocale,
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: false,
        partialResults: true,
      );

      _isListening = true;
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to start listening: $e';
      _isListening = false;
      notifyListeners();
    }
  }

  /// Start continuous listening for wake words
  Future<void> startWakeWordListening({
    required Function(String wakeWord) onWakeWordDetected,
  }) async {
    if (!_isAvailable) {
      _lastError = 'Speech recognition not available';
      notifyListeners();
      return;
    }

    _wakeWordMode = true;
    _onWakeWordDetected = onWakeWordDetected;

    try {
      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          _checkForWakeWord(_lastWords.toLowerCase());
          notifyListeners();
        },
        localeId: _currentLocale,
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: false,
        partialResults: true,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );

      _isListening = true;
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to start wake word listening: $e';
      _wakeWordMode = false;
      _isListening = false;
      notifyListeners();
    }
  }

  /// Check if recognized text contains wake words
  void _checkForWakeWord(String text) {
    for (final wakeWord in _wakeWords) {
      if (text.contains(wakeWord)) {
        debugPrint('Wake word detected: $wakeWord');
        _onWakeWordDetected?.call(wakeWord);

        // Stop wake word mode and restart listening for the actual command
        _wakeWordMode = false;
        break;
      }
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speech.stop();
      _isListening = false;
      _wakeWordMode = false;
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to stop listening: $e';
      notifyListeners();
    }
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    if (!_isListening) return;

    try {
      await _speech.cancel();
      _isListening = false;
      _wakeWordMode = false;
      _lastWords = '';
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to cancel listening: $e';
      notifyListeners();
    }
  }

  /// Set locale for speech recognition
  void setLocale(String localeId) {
    _currentLocale = localeId;
    notifyListeners();
  }

  /// Handle speech status changes
  void _onSpeechStatus(String status) {
    debugPrint('Speech status: $status');

    if (status == 'done' || status == 'notListening') {
      _isListening = false;

      // If in wake word mode, restart listening
      if (_wakeWordMode && _onWakeWordDetected != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_wakeWordMode) {
            startWakeWordListening(onWakeWordDetected: _onWakeWordDetected!);
          }
        });
      }

      notifyListeners();
    }
  }

  /// Handle speech errors
  void _onSpeechError(dynamic error) {
    debugPrint('Speech error: $error');
    _lastError = error.toString();
    _isListening = false;
    notifyListeners();
  }

  /// Check microphone permission status
  Future<bool> checkPermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Request microphone permission
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Get error message for user display
  String getUserFriendlyError() {
    if (_lastError.isEmpty) return '';

    if (_lastError.contains('permission')) {
      return 'Microphone permission required. Please enable in settings.';
    } else if (_lastError.contains('not available')) {
      return 'Speech recognition is not available on this device.';
    } else {
      return 'Speech recognition error. Please try again.';
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}
