import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:logging/logging.dart';
import 'package:intl/intl.dart';

/// Comprehensive crash reporting service with local file generation,
/// Sentry integration, and syslog support for debugging
class CrashReportService {
  static final CrashReportService _instance = CrashReportService._internal();
  factory CrashReportService() => _instance;
  CrashReportService._internal();

  final Logger _logger = Logger('CrashReportService');
  bool _isInitialized = false;
  String? _crashReportsDir;
  Map<String, dynamic> _deviceInfo = {};
  PackageInfo? _packageInfo;

  // Configuration
  final int maxStoredReports = 10;
  final bool enableSentry = true;
  final bool enableLocalReports = true;
  final bool enableSyslog = true;

  bool get isInitialized => _isInitialized;
  String? get crashReportsDirectory => _crashReportsDir;

  /// Initialize crash reporting with optional Sentry DSN
  Future<void> initialize({String? sentryDsn}) async {
    if (_isInitialized) {
      _logger.info('Crash reporting already initialized');
      return;
    }

    try {
      _logger.info('Initializing crash reporting service...');

      // Set up logging
      if (enableSyslog) {
        _setupLogging();
      }

      // Get device info
      await _getDeviceInfo();

      // Get package info
      _packageInfo = await PackageInfo.fromPlatform();

      // Set up crash reports directory
      if (enableLocalReports) {
        await _setupCrashReportsDirectory();
        _logger.info('Crash reports directory: $_crashReportsDir');
      }

      // Initialize Sentry if DSN provided
      if (enableSentry && sentryDsn != null && sentryDsn.isNotEmpty) {
        await _initializeSentry(sentryDsn);
      } else if (enableSentry) {
        _logger.warning('Sentry enabled but no DSN provided. Set SENTRY_DSN in .env file');
      }

      _isInitialized = true;
      _logger.info('Crash reporting initialized successfully');
    } catch (e, stackTrace) {
      _logger.severe('Failed to initialize crash reporting', e, stackTrace);
      debugPrint('Crash reporting initialization error: $e');
    }
  }

  /// Set up structured logging with syslog-like format
  void _setupLogging() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(record.time);
      final level = record.level.name.padRight(7);
      final loggerName = record.loggerName.padRight(20);
      final message = record.message;

      // Syslog-like format
      final logLine = '$timestamp [$level] $loggerName - $message';

      // Print to console
      debugPrint(logLine);

      // Write to file for crash reports context
      if (record.level >= Level.WARNING) {
        _appendToLogFile(logLine, record.error, record.stackTrace);
      }
    });
  }

  /// Initialize Sentry crash reporting
  Future<void> _initializeSentry(String dsn) async {
    try {
      await SentryFlutter.init(
        (options) {
          options.dsn = dsn;
          options.tracesSampleRate = 1.0;
          options.profilesSampleRate = 1.0;
          options.enableAutoSessionTracking = true;
          options.attachScreenshot = true;
          options.attachViewHierarchy = true;
          options.beforeSend = (event, hint) {
            // Add custom context
            event = event.copyWith(
              contexts: event.contexts.copyWith(
                device: SentryDevice(
                  name: _deviceInfo['model'] as String?,
                  manufacturer: _deviceInfo['manufacturer'] as String?,
                  model: _deviceInfo['model'] as String?,
                  modelId: _deviceInfo['device'] as String?,
                ),
                app: SentryApp(
                  name: _packageInfo?.appName,
                  version: _packageInfo?.version,
                  build: _packageInfo?.buildNumber,
                ),
              ),
            );
            return event;
          };
        },
      );
      _logger.info('Sentry initialized successfully');
    } catch (e, stackTrace) {
      _logger.severe('Failed to initialize Sentry', e, stackTrace);
      debugPrint('Sentry initialization error: $e');
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
          'brand': androidInfo.brand,
          'hardware': androidInfo.hardware,
          'isPhysicalDevice': androidInfo.isPhysicalDevice,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        _deviceInfo = {
          'platform': 'iOS',
          'model': iosInfo.model,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'device': iosInfo.name,
          'localizedModel': iosInfo.localizedModel,
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
        };
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfoPlugin.macOsInfo;
        _deviceInfo = {
          'platform': 'macOS',
          'model': macInfo.model,
          'hostName': macInfo.hostName,
          'osRelease': macInfo.osRelease,
        };
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfoPlugin.windowsInfo;
        _deviceInfo = {
          'platform': 'Windows',
          'computerName': windowsInfo.computerName,
          'numberOfCores': windowsInfo.numberOfCores,
          'systemMemoryInMegabytes': windowsInfo.systemMemoryInMegabytes,
        };
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfoPlugin.linuxInfo;
        _deviceInfo = {
          'platform': 'Linux',
          'name': linuxInfo.name,
          'version': linuxInfo.version,
          'id': linuxInfo.id,
          'prettyName': linuxInfo.prettyName,
        };
      }
    } catch (e, stackTrace) {
      _logger.warning('Error getting device info', e, stackTrace);
      debugPrint('Error getting device info: $e');
    }
  }

  /// Set up crash reports directory in Downloads folder
  Future<void> _setupCrashReportsDirectory() async {
    try {
      Directory? baseDir;

      if (Platform.isAndroid || Platform.isIOS) {
        // For mobile, use downloads directory
        baseDir = await getApplicationDocumentsDirectory();
      } else {
        // For desktop, use downloads directory
        baseDir = await getDownloadsDirectory();
      }

      if (baseDir == null) {
        throw Exception('Could not access storage directory');
      }

      final crashDir = Directory('${baseDir.path}/SignalChamp/crash_reports');
      if (!await crashDir.exists()) {
        await crashDir.create(recursive: true);
      }

      _crashReportsDir = crashDir.path;

      // Clean up old reports
      await _cleanupOldReports();
    } catch (e, stackTrace) {
      _logger.severe('Error setting up crash reports directory', e, stackTrace);
      debugPrint('Error setting up crash reports directory: $e');
    }
  }

  /// Generate and save a crash report
  Future<String?> generateCrashReport({
    required dynamic error,
    required StackTrace stackTrace,
    String? errorContext,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final timestamp = DateTime.now();
      final dateFormat = DateFormat('yyyyMMdd_HHmmss');
      final fileName = 'crash_${dateFormat.format(timestamp)}.txt';

      // Build crash report content
      final reportContent = _buildCrashReport(
        error: error,
        stackTrace: stackTrace,
        timestamp: timestamp,
        errorContext: errorContext,
        additionalData: additionalData,
      );

      // Save to local file
      String? filePath;
      if (enableLocalReports && _crashReportsDir != null) {
        filePath = '$_crashReportsDir/$fileName';
        final file = File(filePath);
        await file.writeAsString(reportContent);
        _logger.info('Crash report saved: $filePath');
      }

      // Send to Sentry
      if (enableSentry) {
        await _sendToSentry(error, stackTrace, errorContext, additionalData);
      }

      return filePath;
    } catch (e, stackTrace) {
      _logger.severe('Error generating crash report', e, stackTrace);
      debugPrint('Error generating crash report: $e');
      return null;
    }
  }

  /// Build crash report content
  String _buildCrashReport({
    required dynamic error,
    required StackTrace stackTrace,
    required DateTime timestamp,
    String? errorContext,
    Map<String, dynamic>? additionalData,
  }) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

    // Header
    buffer.writeln('=' * 80);
    buffer.writeln('SIGNAL CHAMP CRASH REPORT');
    buffer.writeln('=' * 80);
    buffer.writeln();

    // Timestamp
    buffer.writeln('Crash Time: ${dateFormat.format(timestamp)}');
    buffer.writeln('Timezone: ${timestamp.timeZoneName}');
    buffer.writeln();

    // App Info
    buffer.writeln('--- Application Information ---');
    if (_packageInfo != null) {
      buffer.writeln('App Name: ${_packageInfo!.appName}');
      buffer.writeln('Package Name: ${_packageInfo!.packageName}');
      buffer.writeln('Version: ${_packageInfo!.version}');
      buffer.writeln('Build Number: ${_packageInfo!.buildNumber}');
    }
    buffer.writeln();

    // Device Info
    buffer.writeln('--- Device Information ---');
    _deviceInfo.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    buffer.writeln();

    // Memory Info
    buffer.writeln('--- Memory Information ---');
    if (Platform.isAndroid || Platform.isIOS) {
      buffer.writeln('Current RSS: ${ProcessInfo.currentRss ~/ (1024 * 1024)} MB');
      buffer.writeln('Max RSS: ${ProcessInfo.maxRss ~/ (1024 * 1024)} MB');
    }
    buffer.writeln();

    // Error Context
    if (errorContext != null) {
      buffer.writeln('--- Error Context ---');
      buffer.writeln(errorContext);
      buffer.writeln();
    }

    // Error Details
    buffer.writeln('--- Error Details ---');
    buffer.writeln('Error Type: ${error.runtimeType}');
    buffer.writeln('Error Message:');
    buffer.writeln(error.toString());
    buffer.writeln();

    // Stack Trace
    buffer.writeln('--- Stack Trace ---');
    buffer.writeln(stackTrace.toString());
    buffer.writeln();

    // Additional Data
    if (additionalData != null && additionalData.isNotEmpty) {
      buffer.writeln('--- Additional Data ---');
      additionalData.forEach((key, value) {
        buffer.writeln('$key: $value');
      });
      buffer.writeln();
    }

    // Footer
    buffer.writeln('=' * 80);
    buffer.writeln('END OF CRASH REPORT');
    buffer.writeln('=' * 80);

    return buffer.toString();
  }

  /// Send error to Sentry
  Future<void> _sendToSentry(
    dynamic error,
    StackTrace stackTrace,
    String? errorContext,
    Map<String, dynamic>? additionalData,
  ) async {
    try {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: (scope) {
          if (errorContext != null) {
            scope.setContexts('error_context', errorContext);
          }
          if (additionalData != null) {
            additionalData.forEach((key, value) {
              scope.setExtra(key, value);
            });
          }
        },
      );
      _logger.info('Error sent to Sentry');
    } catch (e, stackTrace) {
      _logger.warning('Failed to send error to Sentry', e, stackTrace);
      debugPrint('Sentry error: $e');
    }
  }

  /// Append log entry to crash log file
  Future<void> _appendToLogFile(String logLine, Object? error, StackTrace? stackTrace) async {
    if (_crashReportsDir == null) return;

    try {
      final dateFormat = DateFormat('yyyyMMdd');
      final fileName = 'app_log_${dateFormat.format(DateTime.now())}.txt';
      final filePath = '$_crashReportsDir/$fileName';
      final file = File(filePath);

      final buffer = StringBuffer(logLine);
      buffer.writeln();
      if (error != null) {
        buffer.writeln('Error: $error');
      }
      if (stackTrace != null) {
        buffer.writeln('Stack Trace: $stackTrace');
      }
      buffer.writeln();

      await file.writeAsString(
        buffer.toString(),
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      debugPrint('Error writing to log file: $e');
    }
  }

  /// Clean up old crash reports, keeping only the most recent ones
  Future<void> _cleanupOldReports() async {
    if (_crashReportsDir == null) return;

    try {
      final dir = Directory(_crashReportsDir!);
      final files = await dir.list().where((entity) => entity is File).toList();

      // Sort by modification time, newest first
      files.sort((a, b) =>
        File(b.path).lastModifiedSync().compareTo(
          File(a.path).lastModifiedSync()
        )
      );

      // Delete old crash reports (keep only maxStoredReports)
      final crashFiles = files.where((f) => f.path.contains('crash_')).toList();
      if (crashFiles.length > maxStoredReports) {
        for (var i = maxStoredReports; i < crashFiles.length; i++) {
          await File(crashFiles[i].path).delete();
          _logger.info('Deleted old crash report: ${crashFiles[i].path}');
        }
      }

      // Keep log files for last 7 days
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final logFiles = files.where((f) => f.path.contains('app_log_')).toList();
      for (var file in logFiles) {
        final lastModified = File(file.path).lastModifiedSync();
        if (lastModified.isBefore(sevenDaysAgo)) {
          await File(file.path).delete();
          _logger.info('Deleted old log file: ${file.path}');
        }
      }
    } catch (e, stackTrace) {
      _logger.warning('Error cleaning up old reports', e, stackTrace);
      debugPrint('Error cleaning up old reports: $e');
    }
  }

  /// Get all crash report files
  Future<List<File>> getCrashReportFiles() async {
    if (_crashReportsDir == null) return [];

    try {
      final dir = Directory(_crashReportsDir!);
      final files = await dir
          .list()
          .where((entity) => entity is File && entity.path.contains('crash_'))
          .cast<File>()
          .toList();

      // Sort by modification time, newest first
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      return files;
    } catch (e, stackTrace) {
      _logger.warning('Error getting crash report files', e, stackTrace);
      debugPrint('Error getting crash report files: $e');
      return [];
    }
  }

  /// Delete a specific crash report file
  Future<bool> deleteCrashReport(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        _logger.info('Deleted crash report: $filePath');
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      _logger.warning('Error deleting crash report', e, stackTrace);
      debugPrint('Error deleting crash report: $e');
      return false;
    }
  }

  /// Delete all crash reports
  Future<void> deleteAllCrashReports() async {
    try {
      final files = await getCrashReportFiles();
      for (var file in files) {
        await file.delete();
      }
      _logger.info('Deleted all crash reports');
    } catch (e, stackTrace) {
      _logger.warning('Error deleting all crash reports', e, stackTrace);
      debugPrint('Error deleting all crash reports: $e');
    }
  }

  /// Log a breadcrumb for debugging context (Sentry only)
  Future<void> addBreadcrumb({
    required String message,
    String? category,
    SentryLevel? level,
    Map<String, dynamic>? data,
  }) async {
    if (!enableSentry) return;

    try {
      await Sentry.addBreadcrumb(
        Breadcrumb(
          message: message,
          category: category,
          level: level ?? SentryLevel.info,
          data: data,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('Error adding breadcrumb: $e');
    }
  }

  /// Set user context for crash reports
  Future<void> setUser({
    String? id,
    String? email,
    String? username,
    Map<String, dynamic>? extras,
  }) async {
    if (!enableSentry) return;

    try {
      await Sentry.configureScope((scope) {
        scope.setUser(SentryUser(
          id: id,
          email: email,
          username: username,
          data: extras,
        ));
      });
    } catch (e) {
      debugPrint('Error setting user: $e');
    }
  }
}
