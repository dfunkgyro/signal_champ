import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

/// Voice Recognition Service for SSM (Signalling System Manager) AI Agent
/// Supports wake word "ssm" activation
class VoiceRecognitionService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  bool _voiceEnabled = false;
  bool _wakeWordMode = false;
  String _lastWords = '';

  Function(String)? onResult;
  Function(String)? onError;
  Function(bool)? onListeningStateChanged;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  bool get voiceEnabled => _voiceEnabled;
  bool get wakeWordMode => _wakeWordMode;
  String get lastWords => _lastWords;

  /// Initialize speech recognition
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        onError?.call('Microphone permission not granted');
        return false;
      }

      // Initialize speech recognition
      _isInitialized = await _speech.initialize(
        onError: (error) {
          onError?.call('Speech recognition error: ${error.errorMsg}');
          _isListening = false;
          onListeningStateChanged?.call(false);
        },
        onStatus: (status) {
          if (status == 'notListening') {
            _isListening = false;
            onListeningStateChanged?.call(false);

            // Auto-restart if wake word mode is active
            if (_wakeWordMode && _voiceEnabled) {
              Future.delayed(const Duration(milliseconds: 500), () {
                startListening();
              });
            }
          }
        },
      );

      return _isInitialized;
    } catch (e) {
      onError?.call('Failed to initialize voice recognition: $e');
      return false;
    }
  }

  /// Enable or disable voice recognition
  void setVoiceEnabled(bool enabled) {
    _voiceEnabled = enabled;
    if (!enabled && _isListening) {
      stopListening();
    }
  }

  /// Enable or disable wake word mode
  void setWakeWordMode(bool enabled) {
    _wakeWordMode = enabled;
    if (enabled && _voiceEnabled && !_isListening) {
      startListening();
    } else if (!enabled && _isListening) {
      stopListening();
    }
  }

  /// Start listening for voice input
  Future<void> startListening() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    if (!_voiceEnabled) return;
    if (_isListening) return;

    try {
      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords.toLowerCase();

          if (_wakeWordMode) {
            // Check for wake word "ssm"
            if (_lastWords.contains('ssm') || _lastWords.contains('s s m')) {
              // Wake word detected! Extract command after "ssm"
              final words = _lastWords.split(' ');
              final ssmIndex = words.indexOf('ssm');

              if (ssmIndex >= 0 && ssmIndex < words.length - 1) {
                // Get everything after "ssm"
                final command = words.sublist(ssmIndex + 1).join(' ');
                if (command.trim().isNotEmpty) {
                  onResult?.call(command);
                }
              } else {
                // Just "ssm" was said, activate listening for next command
                onResult?.call('listening');
              }
            }
          } else {
            // Not in wake word mode, pass through all recognized text
            if (result.finalResult && _lastWords.isNotEmpty) {
              onResult?.call(_lastWords);
            }
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );

      _isListening = true;
      onListeningStateChanged?.call(true);
    } catch (e) {
      onError?.call('Failed to start listening: $e');
      _isListening = false;
      onListeningStateChanged?.call(false);
    }
  }

  /// Stop listening for voice input
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speech.stop();
      _isListening = false;
      onListeningStateChanged?.call(false);
    } catch (e) {
      onError?.call('Failed to stop listening: $e');
    }
  }

  /// Toggle listening state
  Future<void> toggleListening() async {
    if (_isListening) {
      await stopListening();
    } else {
      await startListening();
    }
  }

  /// Dispose of resources
  void dispose() {
    if (_isListening) {
      _speech.stop();
    }
    _speech.cancel();
  }

  /// Check if speech recognition is available on this device
  Future<bool> isAvailable() async {
    return await _speech.initialize();
  }

  /// Get list of available locales
  Future<List<String>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }

    final locales = await _speech.locales();
    return locales.map((l) => l.localeId).toList();
  }

  /// Get current locale
  String? getCurrentLocale() {
    // Note: localeId is not available in speech_to_text 5.1.0
    // Return null for now - locale is set during listen() call
    return null;
  }
}
