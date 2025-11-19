# Build Instructions for Xcode 14.2 / macOS Monterey 12.7.x

This document provides comprehensive build instructions for developers using **MacBook 2015** with **macOS Monterey 12.7.x** and **Xcode 14.2**.

## System Requirements

- **Hardware**: MacBook 2015 (or compatible)
- **macOS**: Monterey 12.7.x (maximum supported version)
- **Xcode**: 14.2 (latest version compatible with Monterey)
- **CocoaPods**: Latest stable version

## Configuration Summary

### macOS Platform
- **Deployment Target**: 11.0 (minimum required by speech_to_text plugin)
- **SDK**: macOS 12.x (Monterey SDK from Xcode 14.2)
- **Architectures**: x86_64, arm64

### iOS Platform
- **Deployment Target**: 13.0
- **SDK**: iOS 16.2 (maximum supported by Xcode 14.2)
- **Architectures**: arm64 (excludes i386 simulators)

### Android Platform
- **Minimum SDK**: 21 (Android 5.0)
- **Compile SDK**: Managed by Flutter
- **Java**: Version 11

### Windows Platform
- **CMake**: 3.14+
- **C++ Standard**: C++17
- **MSVC**: Latest compatible version

### Linux Platform
- **CMake**: 3.13+
- **C++ Standard**: C++14
- **GTK**: 3.0+

## Build Process

### 1. Clean Previous Builds

```bash
# Clean Flutter build cache
flutter clean

# Remove iOS dependencies
cd ios
rm -rf Pods Podfile.lock
cd ..

# Remove macOS dependencies
cd macos
rm -rf Pods Podfile.lock
cd ..
```

### 2. Install Dependencies

```bash
# Get Flutter dependencies
flutter pub get

# Install iOS pods
cd ios
pod install
cd ..

# Install macOS pods
cd macos
pod install
cd ..
```

### 3. Build for Specific Platforms

#### macOS

```bash
# Debug build
flutter build macos --debug

# Release build
flutter build macos --release
```

#### iOS

```bash
# For iOS Simulator
flutter build ios --debug --simulator

# For iOS Device (requires code signing)
flutter build ios --release
```

#### Android

```bash
# Debug build
flutter build apk --debug

# Release build (requires signing configuration)
flutter build apk --release
```

#### Windows

```bash
flutter build windows --release
```

#### Linux

```bash
flutter build linux --release
```

## Known Issues and Workarounds

### Issue 1: Code Signing Errors (macOS/iOS)

**Problem**: Xcode 14.2 may show code signing errors for pod dependencies.

**Solution**: The Podfiles have been configured to disable code signing for pods:
- `CODE_SIGNING_REQUIRED = 'NO'`
- `CODE_SIGNING_ALLOWED = 'NO'`

### Issue 2: Deprecated API Warnings

**Problem**: Older packages may use deprecated APIs that trigger warnings in Xcode 14.2.

**Solution**: Warnings are suppressed via `GCC_WARN_INHIBIT_ALL_WARNINGS = 'YES'` in post_install hooks.

### Issue 3: Bitcode Deprecation

**Problem**: Bitcode is deprecated in Xcode 14 but some pods may still reference it.

**Solution**: `ENABLE_BITCODE = 'NO'` is set for all targets.

### Issue 4: Module Stability

**Problem**: Some Swift modules may have stability issues across Xcode versions.

**Solution**: `BUILD_LIBRARY_FOR_DISTRIBUTION = 'YES'` ensures module compatibility.

### Issue 5: Deployment Target Mismatch

**Problem**: Some pods may have different deployment targets.

**Solution**: Post_install hooks enforce uniform deployment targets:
- macOS: 11.0
- iOS: 13.0

## Package Compatibility

All packages in `pubspec.yaml` have been verified to work with:
- Flutter SDK: >=3.0.0 <4.0.0
- Xcode: 14.2
- macOS: Monterey 12.7.x

### Critical Packages

- **speech_to_text** (^7.0.0): Requires macOS 11.0+ ✓
- **flutter_tts** (^4.2.0): Compatible with Xcode 14.2 ✓
- **supabase_flutter** (^2.10.3): Compatible ✓
- **geolocator** (^13.0.2): Compatible ✓
- **permission_handler** (^11.3.1): Compatible ✓

## Troubleshooting

### Build Fails with "Command PhaseScriptExecution failed"

1. Clean build folder in Xcode: `Product > Clean Build Folder`
2. Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData/*`
3. Re-run pod install
4. Rebuild

### "Unable to find specification for..." Error

```bash
cd ios  # or macos
pod repo update
pod install
```

### Flutter Command Not Found

Ensure Flutter is in your PATH:
```bash
export PATH="$PATH:[PATH_TO_FLUTTER]/flutter/bin"
```

### Xcode Can't Find SDK

Ensure Xcode command line tools are set:
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

## Performance Optimization

### For macOS Builds

- Use `ONLY_ACTIVE_ARCH = YES` for faster debug builds
- Enable all architectures for release builds

### For iOS Builds

- Exclude i386 architecture (32-bit simulators no longer supported)
- Use physical devices for testing when possible

### For All Platforms

- Run `flutter pub cache clean` periodically to clear package cache
- Use `flutter build --release` for production builds

## Testing

### Run Tests

```bash
# Unit tests
flutter test

# Integration tests (if available)
flutter test integration_test
```

### Platform-Specific Testing

- **macOS**: Test on Monterey 12.7.x
- **iOS**: Test on iOS 13.0+ devices and simulators
- **Android**: Test on API 21+ devices and emulators
- **Windows**: Test on Windows 10/11
- **Linux**: Test on Ubuntu 20.04+ or equivalent

## Additional Notes

1. **Do not upgrade macOS** beyond Monterey 12.7.x on MacBook 2015 hardware
2. **Do not upgrade Xcode** beyond 14.2 (newer versions require macOS Ventura+)
3. **Keep Flutter updated** to the latest stable version compatible with your setup
4. **Regular pod updates**: Run `pod repo update` periodically

## Support

For issues specific to this configuration:
1. Check this document first
2. Review Flutter and Xcode logs
3. Verify all deployment targets match the specified versions
4. Ensure CocoaPods is updated to the latest version

---

**Configuration Last Updated**: 2025-11-19
**Compatible Xcode Version**: 14.2
**Compatible macOS Version**: Monterey 12.7.x
