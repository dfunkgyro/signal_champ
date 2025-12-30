// Sound Service for managing alarm and alert sounds
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service for managing alarm and alert sounds throughout the app
class SoundService {
  // Singleton instance
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  // Audio players
  final AudioPlayer _alarmPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isEnabled = true;

  /// Initialize the sound service
  Future<void> initialize() async {
    try {
      // Set audio player mode for looping alarms
      await _alarmPlayer.setReleaseMode(ReleaseMode.loop);
      debugPrint('SoundService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing SoundService: $e');
    }
  }

  /// Play the alarm sound for collision/SPAD alerts
  Future<void> playAlarm() async {
    if (!_isEnabled || _isPlaying) return;

    try {
      _isPlaying = true;
      await _alarmPlayer.play(AssetSource('sound/atone.wav'));
      debugPrint('Alarm sound started playing');
    } catch (e) {
      debugPrint('Error playing alarm sound: $e');
      _isPlaying = false;
    }
  }

  /// Stop the alarm sound
  Future<void> stopAlarm() async {
    if (!_isPlaying) return;

    try {
      await _alarmPlayer.stop();
      _isPlaying = false;
      debugPrint('Alarm sound stopped');
    } catch (e) {
      debugPrint('Error stopping alarm sound: $e');
    }
  }

  /// Play a single alert beep (non-looping)
  Future<void> playAlertBeep() async {
    if (!_isEnabled) return;

    try {
      final beepPlayer = AudioPlayer();
      await beepPlayer.setReleaseMode(ReleaseMode.stop);
      await beepPlayer.play(AssetSource('sound/atone.wav'));
      debugPrint('Alert beep played');

      // Auto-dispose after playing
      beepPlayer.onPlayerComplete.listen((_) {
        beepPlayer.dispose();
      });
    } catch (e) {
      debugPrint('Error playing alert beep: $e');
    }
  }

  /// Enable or disable sound globally
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled && _isPlaying) {
      stopAlarm();
    }
    debugPrint('Sound service ${enabled ? "enabled" : "disabled"}');
  }

  /// Check if alarm is currently playing
  bool get isPlaying => _isPlaying;

  /// Check if sound is enabled
  bool get isEnabled => _isEnabled;

  /// Dispose of audio players
  Future<void> dispose() async {
    await _alarmPlayer.stop();
    await _alarmPlayer.dispose();
  }
}
