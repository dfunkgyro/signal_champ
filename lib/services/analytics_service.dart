import 'package:flutter/foundation.dart';
import 'package:app_usage/app_usage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

/// Comprehensive analytics service for tracking app usage, location, and events
/// Uses Supabase for all analytics storage and tracking
class AnalyticsService extends ChangeNotifier {
  final SupabaseClient _supabase;

  Position? _currentPosition;
  List<AppUsageInfo> _appUsageStats = [];
  Map<String, dynamic> _deviceInfo = {};
  bool _isLocationEnabled = false;
  bool _isAppUsagePermissionGranted = false;
  String _analyticsStatus = 'Not initialized';

  AnalyticsService(this._supabase) {
    _initialize();
  }

  // Getters
  Position? get currentPosition => _currentPosition;
  List<AppUsageInfo> get appUsageStats => _appUsageStats;
  Map<String, dynamic> get deviceInfo => _deviceInfo;
  bool get isLocationEnabled => _isLocationEnabled;
  bool get isAppUsagePermissionGranted => _isAppUsagePermissionGranted;
  String get analyticsStatus => _analyticsStatus;

  Future<void> _initialize() async {
    try {
      _analyticsStatus = 'Initializing...';
      notifyListeners();

      // Get device info
      await _getDeviceInfo();

      // Log initialization event
      await logEvent('analytics_initialized');

      _analyticsStatus = 'Initialized';
      notifyListeners();
    } catch (e) {
      debugPrint('Analytics initialization error: $e');
      _analyticsStatus = 'Initialization failed: $e';
      notifyListeners();
    }
  }

  /// Get device information
  Future<void> _getDeviceInfo() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        _deviceInfo = {
          'platform': 'Android',
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'version': androidInfo.version.release,
          'sdk': androidInfo.version.sdkInt,
          'device': androidInfo.device,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        _deviceInfo = {
          'platform': 'iOS',
          'model': iosInfo.model,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'device': iosInfo.name,
        };
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    try {
      final status = await Permission.location.request();

      if (status.isGranted) {
        _isLocationEnabled = true;
        notifyListeners();
        await _getCurrentLocation();
        return true;
      } else if (status.isDenied) {
        debugPrint('Location permission denied');
        return false;
      } else if (status.isPermanentlyDenied) {
        debugPrint('Location permission permanently denied');
        await openAppSettings();
        return false;
      }

      return false;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    }
  }

  /// Check if location permission is granted
  Future<bool> checkLocationPermission() async {
    try {
      final status = await Permission.location.status;
      _isLocationEnabled = status.isGranted;
      notifyListeners();
      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      return false;
    }
  }

  /// Get current location
  Future<Position?> _getCurrentLocation() async {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition = position;
      notifyListeners();

      // Log location update
      await logEvent('location_updated', parameters: {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
      });

      return position;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  /// Start tracking location
  Future<void> startLocationTracking() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) return;

      // Get initial position
      await _getCurrentLocation();

      // Listen to position updates
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen((Position position) {
        _currentPosition = position;
        notifyListeners();

        // Save location to Supabase
        _saveLocationToSupabase(position);
      });
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
    }
  }

  /// Save location to Supabase
  Future<void> _saveLocationToSupabase(Position position) async {
    try {
      await _supabase.from('user_locations').insert({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'heading': position.heading,
        'speed': position.speed,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving location: $e');
    }
  }

  /// Request app usage permission
  Future<bool> requestAppUsagePermission() async {
    try {
      if (Platform.isAndroid) {
        // For Android, check if we have usage stats permission
        final endDate = DateTime.now();
        final startDate = endDate.subtract(const Duration(hours: 1));

        try {
          await AppUsage().getAppUsage(startDate, endDate);
          _isAppUsagePermissionGranted = true;
          notifyListeners();
          return true;
        } catch (e) {
          // If we get an exception, we need to request permission
          debugPrint('App usage permission not granted. Please grant permission in settings.');
          // On Android, this requires the user to manually grant permission in Settings
          // You should guide the user to Settings > Apps > Special Access > Usage Access
          return false;
        }
      } else {
        // iOS doesn't have app usage tracking in the same way
        return false;
      }
    } catch (e) {
      debugPrint('Error requesting app usage permission: $e');
      return false;
    }
  }

  /// Get app usage statistics
  Future<List<AppUsageInfo>> getAppUsageStats({Duration? duration}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(duration ?? const Duration(days: 1));

      final usageStats = await AppUsage().getAppUsage(startDate, endDate);
      _appUsageStats = usageStats;
      notifyListeners();

      // Log to analytics
      await logEvent('app_usage_checked', parameters: {
        'duration_days': duration?.inDays ?? 1,
        'apps_count': usageStats.length,
      });

      return usageStats;
    } catch (e) {
      debugPrint('Error getting app usage: $e');
      return [];
    }
  }

  /// Get this app's usage statistics
  Future<Map<String, dynamic>> getThisAppUsageStats() async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 7));

      final usageStats = await AppUsage().getAppUsage(startDate, endDate);

      // Find this app's stats
      final thisAppPackage = Platform.isAndroid
          ? 'com.example.rail_champ' // Update with your actual package name
          : 'rail_champ';

      final thisAppStats = usageStats.firstWhere(
        (app) => app.packageName.contains(thisAppPackage),
        orElse: () => AppUsageInfo(
          packageName: thisAppPackage,
          appName: 'Rail Champ',
          usage: const Duration(seconds: 0),
          startDate: startDate,
          endDate: endDate,
        ),
      );

      return {
        'app_name': thisAppStats.appName,
        'package_name': thisAppStats.packageName,
        'total_usage': thisAppStats.usage.inMinutes,
        'start_date': thisAppStats.startDate.toIso8601String(),
        'end_date': thisAppStats.endDate.toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting this app usage: $e');
      return {};
    }
  }

  /// Log a custom event to Supabase
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    try {
      await _supabase.from('analytics_events').insert({
        'event_name': name,
        'parameters': parameters,
        'device_info': _deviceInfo,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error logging event: $e');
    }
  }

  /// Log screen view to Supabase
  Future<void> logScreenView(String screenName) async {
    try {
      await _supabase.from('analytics_events').insert({
        'event_name': 'screen_view',
        'parameters': {'screen_name': screenName},
        'device_info': _deviceInfo,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error logging screen view: $e');
    }
  }

  /// Set user properties in Supabase
  Future<void> setUserProperty(String name, String value) async {
    try {
      await _supabase.from('user_properties').upsert({
        'property_name': name,
        'property_value': value,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error setting user property: $e');
    }
  }

  /// Get analytics summary
  Future<Map<String, dynamic>> getAnalyticsSummary() async {
    try {
      final response = await _supabase
          .from('analytics_events')
          .select('event_name, count(*)')
          .gte('timestamp', DateTime.now().subtract(const Duration(days: 30)).toIso8601String());

      return {
        'location_enabled': _isLocationEnabled,
        'current_position': _currentPosition != null
            ? {
                'latitude': _currentPosition!.latitude,
                'longitude': _currentPosition!.longitude,
              }
            : null,
        'device_info': _deviceInfo,
        'app_usage_permission': _isAppUsagePermissionGranted,
        'total_events': response?.length ?? 0,
      };
    } catch (e) {
      debugPrint('Error getting analytics summary: $e');
      return {
        'location_enabled': _isLocationEnabled,
        'current_position': _currentPosition != null
            ? {
                'latitude': _currentPosition!.latitude,
                'longitude': _currentPosition!.longitude,
              }
            : null,
        'device_info': _deviceInfo,
        'app_usage_permission': _isAppUsagePermissionGranted,
        'error': e.toString(),
      };
    }
  }
}
