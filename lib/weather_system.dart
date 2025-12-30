import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

enum WeatherCondition {
  clear,
  rain,
  heavyRain,
  fog,
  snow,
  storm,
}

class WeatherSystem extends ChangeNotifier {
  WeatherCondition _currentWeather = WeatherCondition.clear;
  double _visibility = 1.0;
  double _trackCondition = 1.0;
  Timer? _weatherTimer;
  final Random _random = Random();
  
  WeatherCondition get currentWeather => _currentWeather;
  double get visibility => _visibility;
  double get trackCondition => _trackCondition;
  
  void setWeather(WeatherCondition weather) {
    _currentWeather = weather;
    _updateEffects();
    notifyListeners();
  }
  
  void _updateEffects() {
    switch (_currentWeather) {
      case WeatherCondition.clear:
        _visibility = 1.0;
        _trackCondition = 1.0;
        break;
      case WeatherCondition.rain:
        _visibility = 0.7;
        _trackCondition = 0.85;
        break;
      case WeatherCondition.heavyRain:
        _visibility = 0.5;
        _trackCondition = 0.7;
        break;
      case WeatherCondition.fog:
        _visibility = 0.3;
        _trackCondition = 1.0;
        break;
      case WeatherCondition.snow:
        _visibility = 0.6;
        _trackCondition = 0.6;
        break;
      case WeatherCondition.storm:
        _visibility = 0.4;
        _trackCondition = 0.5;
        break;
    }
  }
  
  double getAdjustedSpeed(double baseSpeed) {
    return baseSpeed * _trackCondition;
  }
  
  double getVisibilityRange() {
    return 1000 * _visibility;
  }
  
  void startWeatherSimulation() {
    _weatherTimer?.cancel();
    _weatherTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_random.nextDouble() < 0.3) {
        _changeWeatherRandomly();
      }
    });
  }
  
  void stopWeatherSimulation() {
    _weatherTimer?.cancel();
  }
  
  void _changeWeatherRandomly() {
    final conditions = WeatherCondition.values;
    _currentWeather = conditions[_random.nextInt(conditions.length)];
    _updateEffects();
    notifyListeners();
  }
  
  String getWeatherDescription() {
    switch (_currentWeather) {
      case WeatherCondition.clear:
        return 'Clear skies';
      case WeatherCondition.rain:
        return 'Light rain';
      case WeatherCondition.heavyRain:
        return 'Heavy rain';
      case WeatherCondition.fog:
        return 'Foggy conditions';
      case WeatherCondition.snow:
        return 'Snowing';
      case WeatherCondition.storm:
        return 'Storm warning';
    }
  }
  
  @override
  void dispose() {
    _weatherTimer?.cancel();
    super.dispose();
  }
}
