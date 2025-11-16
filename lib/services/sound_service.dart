import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum SoundType {
  // Basic FX
  click,
  success,
  error,
  notification,

  // Train Sounds
  trainDepart,
  trainArrive,
  trainBrake,
  doorOpen,
  doorClose,

  // Signal Sounds
  signalChange,
  pointSwitch,
  routeSet,
  routeRelease,

  // Alarms
  collision,
  emergency,
  warning,

  // Alerts
  trainStop,
  blockOccupied,
  systemAlert,
}

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;

  SoundService._internal();

  final AudioPlayer _fxPlayer = AudioPlayer();
  final AudioPlayer _alarmPlayer = AudioPlayer();
  final AudioPlayer _alertPlayer = AudioPlayer();
  final AudioPlayer _ambientPlayer = AudioPlayer();

  bool _soundEnabled = true;
  bool _alarmEnabled = true;
  bool _alertEnabled = true;
  double _volume = 0.7;

  // Sound mapping (using synthesized beeps for now)
  final Map<SoundType, String> _soundPaths = {
    // Basic FX - short beeps
    SoundType.click: 'sounds/click.mp3',
    SoundType.success: 'sounds/success.mp3',
    SoundType.error: 'sounds/error.mp3',
    SoundType.notification: 'sounds/notification.mp3',

    // Train sounds
    SoundType.trainDepart: 'sounds/train_depart.mp3',
    SoundType.trainArrive: 'sounds/train_arrive.mp3',
    SoundType.trainBrake: 'sounds/train_brake.mp3',
    SoundType.doorOpen: 'sounds/door_open.mp3',
    SoundType.doorClose: 'sounds/door_close.mp3',

    // Signal sounds
    SoundType.signalChange: 'sounds/signal_change.mp3',
    SoundType.pointSwitch: 'sounds/point_switch.mp3',
    SoundType.routeSet: 'sounds/route_set.mp3',
    SoundType.routeRelease: 'sounds/route_release.mp3',

    // Alarms
    SoundType.collision: 'sounds/alarm_collision.mp3',
    SoundType.emergency: 'sounds/alarm_emergency.mp3',
    SoundType.warning: 'sounds/alarm_warning.mp3',

    // Alerts
    SoundType.trainStop: 'sounds/alert_train_stop.mp3',
    SoundType.blockOccupied: 'sounds/alert_block.mp3',
    SoundType.systemAlert: 'sounds/alert_system.mp3',
  };

  // Initialize the sound service
  Future<void> initialize() async {
    try {
      await _fxPlayer.setVolume(_volume);
      await _alarmPlayer.setVolume(_volume);
      await _alertPlayer.setVolume(_volume);
      await _ambientPlayer.setVolume(_volume * 0.5);

      if (kDebugMode) {
        print('SoundService initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing SoundService: $e');
      }
    }
  }

  // Play a sound effect
  Future<void> play(SoundType soundType, {double? volumeOverride}) async {
    if (!_soundEnabled) return;

    // Check specific sound type enablement
    if (_isAlarm(soundType) && !_alarmEnabled) return;
    if (_isAlert(soundType) && !_alertEnabled) return;

    try {
      final player = _getPlayerForSound(soundType);
      final path = _soundPaths[soundType];

      if (path == null) {
        if (kDebugMode) {
          print('No sound path for $soundType - using beep tone');
        }
        // Fallback to synthesized beep
        await _playSynthesizedBeep(soundType);
        return;
      }

      // Set volume
      final volume = volumeOverride ?? _volume;
      await player.setVolume(volume);

      // Try to play from assets
      try {
        await player.play(AssetSource(path));
      } catch (e) {
        // Asset not found, use synthesized sound
        if (kDebugMode) {
          print('Sound file not found: $path - using beep tone');
        }
        await _playSynthesizedBeep(soundType);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing sound $soundType: $e');
      }
    }
  }

  // Play a looping alarm
  Future<void> playAlarmLoop(SoundType soundType) async {
    if (!_soundEnabled || !_alarmEnabled) return;
    if (!_isAlarm(soundType)) return;

    try {
      await _alarmPlayer.setVolume(_volume);
      await _alarmPlayer.setReleaseMode(ReleaseMode.loop);

      final path = _soundPaths[soundType];
      if (path != null) {
        await _alarmPlayer.play(AssetSource(path));
      } else {
        // Use synthesized alarm tone
        await _playSynthesizedAlarmLoop(soundType);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing alarm loop: $e');
      }
    }
  }

  // Stop alarm loop
  Future<void> stopAlarm() async {
    try {
      await _alarmPlayer.stop();
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping alarm: $e');
      }
    }
  }

  // Synthesized beep for missing sound files
  Future<void> _playSynthesizedBeep(SoundType soundType) async {
    // This is a placeholder - in production, you would use actual sound files
    // or implement tone generation
    if (kDebugMode) {
      print('BEEP: $soundType');
    }
  }

  // Synthesized alarm loop
  Future<void> _playSynthesizedAlarmLoop(SoundType soundType) async {
    // Placeholder for alarm loop
    if (kDebugMode) {
      print('ALARM LOOP: $soundType');
    }
  }

  // Get appropriate player for sound type
  AudioPlayer _getPlayerForSound(SoundType soundType) {
    if (_isAlarm(soundType)) {
      return _alarmPlayer;
    } else if (_isAlert(soundType)) {
      return _alertPlayer;
    } else {
      return _fxPlayer;
    }
  }

  // Check if sound is an alarm
  bool _isAlarm(SoundType soundType) {
    return soundType == SoundType.collision ||
        soundType == SoundType.emergency ||
        soundType == SoundType.warning;
  }

  // Check if sound is an alert
  bool _isAlert(SoundType soundType) {
    return soundType == SoundType.trainStop ||
        soundType == SoundType.blockOccupied ||
        soundType == SoundType.systemAlert;
  }

  // Settings
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    if (!enabled) {
      stopAll();
    }
  }

  void setAlarmEnabled(bool enabled) {
    _alarmEnabled = enabled;
    if (!enabled) {
      stopAlarm();
    }
  }

  void setAlertEnabled(bool enabled) {
    _alertEnabled = enabled;
  }

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    _fxPlayer.setVolume(_volume);
    _alarmPlayer.setVolume(_volume);
    _alertPlayer.setVolume(_volume);
    _ambientPlayer.setVolume(_volume * 0.5);
  }

  // Stop all sounds
  Future<void> stopAll() async {
    await _fxPlayer.stop();
    await _alarmPlayer.stop();
    await _alertPlayer.stop();
    await _ambientPlayer.stop();
  }

  // Dispose
  Future<void> dispose() async {
    await stopAll();
    await _fxPlayer.dispose();
    await _alarmPlayer.dispose();
    await _alertPlayer.dispose();
    await _ambientPlayer.dispose();
  }

  // Getters
  bool get soundEnabled => _soundEnabled;
  bool get alarmEnabled => _alarmEnabled;
  bool get alertEnabled => _alertEnabled;
  double get volume => _volume;
}
