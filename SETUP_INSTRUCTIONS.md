# Rail Champ - Setup Instructions

This document provides comprehensive setup instructions for the Rail Champ app with authentication, analytics, and cloud features.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Supabase Setup](#supabase-setup)
3. [Firebase Setup](#firebase-setup)
4. [Google Sign-In Setup](#google-sign-in-setup)
5. [Android Configuration](#android-configuration)
6. [iOS Configuration](#ios-configuration)
7. [Environment Variables](#environment-variables)
8. [Running the App](#running-the-app)
9. [Features Overview](#features-overview)

---

## Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Supabase account (free tier available)
- Firebase account (free tier available)
- Google Cloud Console account (for Google Sign-In)

---

## Supabase Setup

### 1. Create a Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Sign up / Sign in
3. Click "New Project"
4. Fill in project details:
   - Project name: `rail-champ` (or your choice)
   - Database password: (save this securely)
   - Region: (choose closest to your users)
5. Wait for project to be created

### 2. Get Supabase Credentials

1. Go to Project Settings > API
2. Copy:
   - **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - **anon/public key** (starts with `eyJ...`)

### 3. Run Database SQL Script

1. Go to SQL Editor in your Supabase dashboard
2. Open the file `supabase_setup.sql` from this project
3. Copy and paste the entire SQL script
4. Click "Run" to execute
5. Verify tables were created: Check the Table Editor

### 4. Configure Authentication Providers

#### Email/Password (Already enabled by default)
No additional setup needed.

#### Google OAuth

1. Go to Authentication > Providers in Supabase
2. Enable "Google" provider
3. Add your Google OAuth credentials (see Google Sign-In Setup below)

---

## Firebase Setup

### 1. Create Firebase Project

1. Go to [https://console.firebase.google.com](https://console.firebase.google.com)
2. Click "Add Project"
3. Enter project name: `rail-champ` (or your choice)
4. Enable Google Analytics (recommended)
5. Select your Google Analytics account or create new one
6. Click "Create Project"

### 2. Add Android App

1. In Firebase Console, click "Add App" > Android icon
2. Enter package name: `com.example.rail_champ` (or your actual package name)
3. Download `google-services.json`
4. Place it in `android/app/google-services.json`

### 3. Add iOS App

1. In Firebase Console, click "Add App" > iOS icon
2. Enter bundle ID: `com.example.railChamp` (or your actual bundle ID)
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/GoogleService-Info.plist`

### 4. Enable Analytics

1. Go to Analytics in Firebase Console
2. Analytics should be automatically enabled
3. No additional configuration needed

---

## Google Sign-In Setup

### 1. Google Cloud Console

1. Go to [https://console.cloud.google.com](https://console.cloud.google.com)
2. Select or create a project
3. Enable Google+ API:
   - Go to "APIs & Services" > "Library"
   - Search for "Google+ API"
   - Click "Enable"

### 2. Create OAuth 2.0 Credentials

#### For Android:

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth client ID"
3. Select "Android"
4. Enter package name: `com.example.rail_champ`
5. Get SHA-1 fingerprint:
   ```bash
   # For debug build
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

   # For release build
   keytool -list -v -keystore /path/to/your/keystore -alias your-alias
   ```
6. Enter SHA-1 fingerprint
7. Click "Create"
8. Copy the Client ID

#### For iOS:

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth client ID"
3. Select "iOS"
4. Enter bundle ID: `com.example.railChamp`
5. Click "Create"
6. Copy the Client ID
7. Download the plist file

### 3. Configure Supabase

1. Go to Supabase > Authentication > Providers > Google
2. Enable Google provider
3. Enter your Google Client ID (from Google Cloud Console)
4. Enter your Google Client Secret (from Google Cloud Console)
5. Save

---

## Android Configuration

### 1. Update AndroidManifest.xml

Add the following permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.rail_champ">

    <!-- Internet permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

    <!-- Location permissions -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>

    <!-- App usage stats permission (Android 5.0+) -->
    <uses-permission android:name="android.permission.PACKAGE_USAGE_STATS"
        tools:ignore="ProtectedPermissions"/>

    <application
        android:label="Rail Champ"
        android:name="${applicationName}"
        android:icon="@mipmap/launcher_icon">

        <!-- Your existing activity configuration -->

    </application>
</manifest>
```

### 2. Update build.gradle

Add Google Services plugin to `android/build.gradle`:

```gradle
buildscript {
    dependencies {
        // ...
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

And in `android/app/build.gradle`:

```gradle
apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
apply plugin: 'com.google.gms.google-services'  // Add this line

android {
    compileSdkVersion 34  // or higher

    defaultConfig {
        minSdkVersion 21  // Minimum required
        targetSdkVersion 34
    }
}
```

---

## iOS Configuration

### 1. Update Info.plist

Add the following to `ios/Runner/Info.plist`:

```xml
<dict>
    <!-- Your existing keys -->

    <!-- Location permissions -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>This app needs access to your location to provide location-based analytics.</string>

    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>This app needs access to your location to track usage patterns.</string>

    <key>NSLocationAlwaysUsageDescription</key>
    <string>This app needs access to your location in the background.</string>

    <!-- Google Sign-In -->
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <!-- Replace with your REVERSED_CLIENT_ID from GoogleService-Info.plist -->
                <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
            </array>
        </dict>
    </array>
</dict>
```

### 2. Update Podfile

Update `ios/Podfile`:

```ruby
platform :ios, '12.0'

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
```

---

## Environment Variables

### 1. Create .env file

Create a file `assets/.env` with the following content:

```env
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here

# OpenAI Configuration (optional - for AI features)
OPENAI_API_KEY=your-openai-api-key-here
```

### 2. Update pubspec.yaml

Ensure the .env file is included in assets:

```yaml
flutter:
  assets:
    - assets/
    - assets/.env
    - assets/icon/
```

---

## Running the App

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Run on Android

```bash
flutter run
```

### 3. Run on iOS

```bash
cd ios
pod install
cd ..
flutter run
```

---

## Features Overview

### 🔐 Authentication

- **Email/Password Login**: Traditional authentication
- **Google Sign-In**: One-tap authentication with Google
- **Guest Mode**: Use the app without signing in (local storage only)

### 📊 Analytics

- **Firebase Analytics**: Track user events and behavior
- **App Usage Statistics**: Monitor app usage time (Android only)
- **Location Tracking**: Track user location (with permission)
- **Password Protected**: Analytics tab requires password: `password`

### 🔄 Force Update

- **Automatic Version Checking**: Checks for updates on app start
- **Configurable**: Set minimum version in Supabase `app_version` table
- **User-Friendly**: Prompts users to update with custom message

### 🌐 Connection Indicators

- **Supabase Status**: Shows real-time connection to Supabase
- **AI Service Status**: Shows connection to OpenAI API
- **Fallback Mode**: App works offline when connections fail

### 💾 Data Persistence

- **Cloud Sync**: Settings synced via Supabase for logged-in users
- **Local Storage**: Guest users store data locally
- **Automatic Backup**: Data automatically backed up to cloud

---

## Troubleshooting

### Supabase Connection Issues

1. Verify `.env` file has correct credentials
2. Check Supabase project is active
3. Ensure RLS policies are set up correctly (run SQL script)

### Google Sign-In Not Working

1. Verify SHA-1 fingerprint is correct
2. Check Google Cloud Console credentials
3. Ensure `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is in correct location

### Firebase Analytics Not Working

1. Verify Firebase configuration files are in place
2. Check Firebase Console for data (can take 24 hours for first data)
3. Ensure Firebase Core is initialized

### Location Permission Issues

1. Check manifest/plist has required permissions
2. Request permission at runtime
3. For Android 10+, background location requires special permission

### App Usage Stats Not Working (Android)

1. This requires manual permission grant
2. Guide users to: Settings > Apps > Special Access > Usage Access
3. Enable permission for Rail Champ

---

## Support

For issues or questions:
- Check the Flutter documentation: https://flutter.dev/docs
- Supabase docs: https://supabase.com/docs
- Firebase docs: https://firebase.google.com/docs

---

## Security Notes

1. **Never commit** `.env` files to version control
2. **Never commit** `google-services.json` or `GoogleService-Info.plist` to public repos
3. Use **Row Level Security** (RLS) in Supabase for data protection
4. Rotate API keys regularly
5. Use secure password policies for user accounts

---

## Version Management

To update the minimum required version:

1. Go to Supabase SQL Editor
2. Run:
   ```sql
   UPDATE app_version
   SET minimum_version = '2.2.0',
       latest_version = '2.2.0',
       force_update = true,
       update_message = 'Critical update available. Please update now.'
   WHERE platform = 'android';  -- or 'ios'
   ```

---

**Congratulations!** 🎉 Your Rail Champ app is now fully configured with authentication, analytics, and cloud features!
