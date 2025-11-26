# Quick Start Guide - Xcode 14.2 / Monterey 12.7.x

## For MacBook 2015 with macOS Monterey 12.7.x and Xcode 14.2

### Prerequisites

1. **Xcode 14.2** installed from App Store or Apple Developer
2. **Xcode Command Line Tools**:
   ```bash
   xcode-select --install
   ```

3. **CocoaPods** installed:
   ```bash
   sudo gem install cocoapods
   ```

4. **Flutter** installed and in PATH

### Quick Build Commands

#### Option 1: Using the Automated Script (Recommended)

```bash
# Build for macOS in debug mode
./build_xcode14.sh --platform macos

# Build for macOS in release mode
./build_xcode14.sh --platform macos --release

# Build for iOS (simulator)
./build_xcode14.sh --platform ios

# Build for all platforms
./build_xcode14.sh --platform all --release

# Clean build (recommended for first build)
./build_xcode14.sh --clean --platform macos
```

#### Option 2: Manual Build Commands

```bash
# 1. Clean everything (first time only)
flutter clean
rm -rf ios/Pods ios/Podfile.lock macos/Pods macos/Podfile.lock

# 2. Get dependencies
flutter pub get

# 3. Install pods for macOS
cd macos && pod install && cd ..

# 4. Build macOS app
flutter build macos --release

# 5. Install pods for iOS (if building iOS)
cd ios && pod install && cd ..

# 6. Build iOS app
flutter build ios --release
```

### First Time Setup

If this is your first time building after cloning the repository:

```bash
# 1. Make the build script executable
chmod +x build_xcode14.sh

# 2. Run a clean build for your target platform
./build_xcode14.sh --clean --platform macos

# 3. Wait for the build to complete (this may take several minutes)
```

### Common Issues and Quick Fixes

#### Issue: "pod install" fails
```bash
cd macos  # or ios
pod repo update
pod deintegrate
pod install
cd ..
```

#### Issue: Build fails with signing errors
- For debug builds: This shouldn't happen with the current configuration
- For release builds: Configure code signing in Xcode

#### Issue: Module not found errors
```bash
flutter clean
flutter pub get
cd macos && pod install && cd ..
```

#### Issue: Xcode shows deprecated API warnings
- These are suppressed in the build settings
- If you still see them, they won't prevent the build from succeeding

### Testing Your Build

#### macOS
```bash
# Run the app directly
flutter run -d macos

# Or open the built app
open build/macos/Build/Products/Release/signal_champ.app
```

#### iOS Simulator
```bash
# List available simulators
xcrun simctl list devices

# Run on a specific simulator
flutter run -d <simulator-id>
```

### Platform-Specific Notes

#### macOS
- ✅ Deployment target: 11.0 (compatible with Monterey 12.7.x)
- ✅ Works with speech_to_text plugin
- ✅ Optimized for Xcode 14.2

#### iOS
- ✅ Deployment target: 13.0
- ✅ Compatible with Xcode 14.2 (supports up to iOS 16.2)
- ⚠️ Physical device testing requires Apple Developer account

#### Android
- ✅ Minimum SDK: 21 (Android 5.0+)
- ✅ Builds independently of Xcode version
- ✅ No special configuration needed

### Performance Tips

1. **Use the automated script** - It handles pod installation and build configuration automatically
2. **Clean builds** - Use `--clean` flag if you encounter unexplained errors
3. **Debug vs Release** - Use debug mode for testing, release mode for distribution
4. **Simulator vs Device** - iOS simulator builds are faster for testing

### Need More Help?

- Check `BUILD_INSTRUCTIONS_XCODE_14.md` for detailed documentation
- Review Flutter and Xcode logs for specific errors
- Ensure all deployment targets match the documented versions

### Build Time Estimates

| Platform | Clean Build | Incremental Build |
|----------|-------------|-------------------|
| macOS    | 3-5 min     | 30-60 sec        |
| iOS      | 3-5 min     | 30-60 sec        |
| Android  | 2-4 min     | 20-40 sec        |

*Times may vary based on your MacBook 2015 specifications*

---

**Last Updated**: 2025-11-19
**Optimized For**: MacBook 2015, macOS Monterey 12.7.x, Xcode 14.2
