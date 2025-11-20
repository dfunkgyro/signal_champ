# Crash Reporting Setup Guide

Signal Champ includes comprehensive crash reporting with both **local file generation** and **Sentry integration** for debugging.

## Features

✅ **Automatic Local Crash Reports**
- Saves crash reports to `Downloads/SignalChamp/crash_reports/`
- Full stack traces with device info
- Works offline
- Auto-cleanup (keeps last 10 reports)
- Syslog-style structured logging

✅ **Sentry Integration (Optional)**
- Real-time crash monitoring
- Performance tracking
- Session replay
- Breadcrumb trails
- User context tracking

✅ **Built-in Crash Report Viewer**
- View all crash reports in-app
- Share crash reports via email/messaging
- Copy to clipboard
- Delete individual or all reports
- Test crash reporting with one button

---

## Setup Instructions

### 1. Basic Setup (Local Crash Reports Only)

**No configuration needed!** Local crash reporting works out of the box.

Crash reports are automatically saved to:
- **Android**: `/storage/emulated/0/Android/data/com.yourapp/files/SignalChamp/crash_reports/`
- **iOS**: `Documents/SignalChamp/crash_reports/`
- **Desktop**: `~/Downloads/SignalChamp/crash_reports/`

### 2. Sentry Setup (Optional but Recommended)

#### Step 1: Create a Sentry Account

1. Go to [sentry.io](https://sentry.io) and sign up (free tier available)
2. Create a new project:
   - Choose **Flutter** as the platform
   - Name it "Signal Champ" or similar

#### Step 2: Get Your DSN Key

1. In your Sentry project, go to: **Settings → Projects → [Your Project] → Client Keys (DSN)**
2. Copy the DSN URL (looks like: `https://[key]@[org].ingest.sentry.io/[project]`)

#### Step 3: Configure the App

1. Open `assets/.env` file
2. Add your Sentry DSN:
   ```env
   SENTRY_DSN=https://your-dsn-here@o123456.ingest.sentry.io/1234567
   ```
3. Save the file

#### Step 4: Install Dependencies

```bash
flutter pub get
```

#### Step 5: Test Crash Reporting

1. Run the app: `flutter run`
2. Navigate to: **Settings → Crash Reports**
3. Tap the **"Test Crash"** button
4. The app will crash intentionally
5. Restart the app
6. Check:
   - Local file in crash reports directory
   - Sentry dashboard for the crash event

---

## How It Works

### Automatic Crash Detection

The app automatically captures:
- ✅ Uncaught Flutter framework errors
- ✅ Uncaught Dart zone errors
- ✅ Async errors
- ✅ Native platform crashes (via Sentry)

### What's Included in Crash Reports

Each crash report contains:
- **Timestamp** - When the crash occurred
- **App Info** - Version, build number, package name
- **Device Info** - Platform, model, OS version, manufacturer
- **Memory Usage** - Current and max RSS
- **Error Details** - Exception type and message
- **Full Stack Trace** - Complete call stack
- **Error Context** - Where the error originated
- **Additional Data** - Custom context if provided

### Syslog Integration

Structured logging with automatic file persistence:
```dart
// Logs are automatically formatted as:
// 2024-01-20 14:30:45.123 [WARNING] CrashReportService - Error message
```

Logs at WARNING level and above are automatically written to daily log files in the crash reports directory.

---

## Using Crash Reports

### Viewing Crash Reports

1. Open the app
2. Go to **Settings → Crash Reports**
3. Tap any crash report to view details
4. Use the **Copy** button to copy to clipboard
5. Use the **Share** button to send via email/messaging

### Sharing Crash Reports

**Option 1: In-App Sharing**
- Settings → Crash Reports → Tap report → Share button

**Option 2: Direct File Access**
- Navigate to the crash reports directory
- Copy/share files manually

**Option 3: Sentry Dashboard**
- Log into sentry.io
- View crashes with full context and stack traces
- Download or share Sentry issue links

### Testing Crash Reporting

The app includes a built-in crash test:

1. **Settings → Crash Reports**
2. Tap the **orange "Test Crash"** floating button
3. Confirm the crash
4. App will crash immediately
5. Restart the app
6. Navigate back to Crash Reports
7. You should see a new crash report

### Deleting Crash Reports

**Delete Individual Report:**
- Settings → Crash Reports → Tap ⋮ → Delete

**Delete All Reports:**
- Settings → Crash Reports → Tap trash icon (top right)

---

## Advanced Usage

### Custom Error Reporting

```dart
import '../services/crash_report_service.dart';

try {
  // Your code
} catch (e, stackTrace) {
  await CrashReportService().generateCrashReport(
    error: e,
    stackTrace: stackTrace,
    errorContext: 'Custom operation failed',
    additionalData: {
      'user_action': 'button_tap',
      'screen': 'home_screen',
    },
  );
}
```

### Adding Breadcrumbs (Sentry)

Track user actions leading up to a crash:

```dart
import '../services/crash_report_service.dart';

// Add breadcrumb
await CrashReportService().addBreadcrumb(
  message: 'User tapped submit button',
  category: 'navigation',
  data: {'screen': 'login'},
);
```

### Setting User Context (Sentry)

Associate crashes with specific users:

```dart
import '../services/crash_report_service.dart';

// Set user context
await CrashReportService().setUser(
  id: user.id,
  email: user.email,
  username: user.username,
  extras: {'premium': user.isPremium},
);
```

---

## Configuration Options

Edit `/lib/services/crash_report_service.dart` to customize:

```dart
class CrashReportService {
  // Configuration
  final int maxStoredReports = 10;        // Max local reports to keep
  final bool enableSentry = true;         // Enable Sentry integration
  final bool enableLocalReports = true;   // Enable local file generation
  final bool enableSyslog = true;         // Enable syslog-style logging
}
```

---

## Troubleshooting

### Local Crash Reports Not Saving

**Symptom:** Crash reports directory is empty after crashes

**Solutions:**
1. Check storage permissions (Android)
2. Verify crash reports directory exists:
   ```dart
   print(CrashReportService().crashReportsDirectory);
   ```
3. Check app logs for initialization errors

### Sentry Not Receiving Crashes

**Symptom:** Crashes appear locally but not in Sentry dashboard

**Solutions:**
1. Verify DSN is correctly set in `assets/.env`
2. Check internet connection when crash occurs
3. Verify Sentry project is active
4. Check Sentry quota (free tier has limits)
5. Look for Sentry initialization errors in logs

### App Crashes on Startup

**Symptom:** App crashes immediately after adding crash reporting

**Solutions:**
1. Run `flutter clean && flutter pub get`
2. Check for syntax errors in modified files
3. Verify all imports are correct
4. Check that `.env` file is in `assets/` directory

### Crash Report Viewer Shows Error

**Symptom:** "Failed to load crash reports" error

**Solutions:**
1. Check storage permissions
2. Verify crash reports directory path
3. Restart the app
4. Check for file system errors

---

## Privacy Considerations

### Local Crash Reports
- Stored locally on device only
- No data sent to external servers (unless you manually share)
- Full control over data retention

### Sentry Integration
- Crash data sent to Sentry servers
- Includes stack traces, device info, and custom context
- **Do not send sensitive user data** (passwords, PII, etc.)
- Review Sentry's [privacy policy](https://sentry.io/privacy/)
- Configure data scrubbing in Sentry settings

### Best Practices
- Use environment-specific DSNs (dev/staging/prod)
- Scrub sensitive data before sending to Sentry
- Inform users about crash reporting in privacy policy
- Provide opt-out if required by regulations

---

## Production Checklist

Before releasing to production:

- [ ] Test crash reporting in debug mode
- [ ] Test crash reporting in release mode
- [ ] Verify Sentry DSN is for production project
- [ ] Set appropriate Sentry sample rates
- [ ] Configure Sentry data scrubbing rules
- [ ] Test local crash report generation
- [ ] Test crash report viewer UI
- [ ] Verify crash reports are auto-cleaned
- [ ] Update privacy policy with crash reporting disclosure
- [ ] Document crash report locations for support team

---

## Support

If you encounter issues with crash reporting:

1. Check this documentation
2. Review app logs for error messages
3. Test with the built-in crash test feature
4. Check Sentry status page: [status.sentry.io](https://status.sentry.io)
5. Create an issue in the project repository

---

## Technical Details

### Architecture

```
┌─────────────────┐
│   App Crashes   │
└────────┬────────┘
         │
         ├──────────────────────┬──────────────────────┐
         │                      │                      │
         ▼                      ▼                      ▼
┌─────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│ Flutter Error   │  │  Zone Error      │  │  Platform Error  │
│ Handler         │  │  Handler         │  │  (Sentry Only)   │
└────────┬────────┘  └─────────┬────────┘  └─────────┬────────┘
         │                     │                      │
         └─────────────────────┴──────────────────────┘
                               │
                      ┌────────▼────────┐
                      │ CrashReportSvc  │
                      └────────┬────────┘
                               │
                    ┌──────────┴──────────┐
                    │                     │
                    ▼                     ▼
         ┌──────────────────┐  ┌──────────────────┐
         │  Local File      │  │   Sentry API     │
         │  (Downloads)     │  │  (If Configured) │
         └──────────────────┘  └──────────────────┘
```

### Dependencies

- `sentry_flutter: ^8.11.0` - Sentry SDK for Flutter
- `logging: ^1.3.0` - Structured logging
- `device_info_plus: ^11.2.0` - Device information
- `package_info_plus: ^8.1.3` - App version info
- `path_provider: ^2.1.5` - File system paths
- `share_plus: ^12.0.1` - Sharing functionality

---

## License

Part of Signal Champ (Rail Champ) project.
