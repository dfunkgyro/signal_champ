#!/bin/bash
#
# Build script for Xcode 14.2 / macOS Monterey 12.7.x
# This script automates the build process for the specific hardware/software constraints
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_header() {
    echo ""
    echo "======================================"
    echo "$1"
    echo "======================================"
    echo ""
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS systems only"
    exit 1
fi

# Check macOS version
MACOS_VERSION=$(sw_vers -productVersion)
print_status "Running on macOS $MACOS_VERSION"

# Check Xcode version
if command -v xcodebuild &> /dev/null; then
    XCODE_VERSION=$(xcodebuild -version | grep "Xcode" | awk '{print $2}')
    print_status "Xcode version: $XCODE_VERSION"

    if [[ "$XCODE_VERSION" != "14.2"* ]]; then
        print_warning "This build is optimized for Xcode 14.2, you have $XCODE_VERSION"
        print_warning "Continuing anyway..."
    fi
else
    print_error "Xcode is not installed or xcodebuild is not in PATH"
    exit 1
fi

# Check Flutter installation
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    print_error "Please install Flutter and add it to your PATH"
    exit 1
fi

FLUTTER_VERSION=$(flutter --version | grep "Flutter" | awk '{print $2}')
print_status "Flutter version: $FLUTTER_VERSION"

# Check CocoaPods installation
if ! command -v pod &> /dev/null; then
    print_error "CocoaPods is not installed"
    print_error "Install it with: sudo gem install cocoapods"
    exit 1
fi

POD_VERSION=$(pod --version)
print_status "CocoaPods version: $POD_VERSION"

# Parse command line arguments
PLATFORM="all"
BUILD_TYPE="debug"
CLEAN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --release)
            BUILD_TYPE="release"
            shift
            ;;
        --clean)
            CLEAN=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --platform <name>   Build for specific platform (macos, ios, android, all)"
            echo "  --release           Build in release mode (default: debug)"
            echo "  --clean             Clean before building"
            echo "  --help              Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 --platform macos --release"
            echo "  $0 --clean --platform ios"
            echo "  $0 --platform all"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

print_header "Signal Champ Build Script for Xcode 14.2"

# Clean if requested
if [ "$CLEAN" = true ]; then
    print_header "Cleaning Previous Builds"

    print_status "Running flutter clean..."
    flutter clean

    if [ -d "ios/Pods" ] || [ -f "ios/Podfile.lock" ]; then
        print_status "Cleaning iOS dependencies..."
        rm -rf ios/Pods ios/Podfile.lock
    fi

    if [ -d "macos/Pods" ] || [ -f "macos/Podfile.lock" ]; then
        print_status "Cleaning macOS dependencies..."
        rm -rf macos/Pods macos/Podfile.lock
    fi

    print_status "Clean complete"
fi

# Get Flutter dependencies
print_header "Installing Flutter Dependencies"
flutter pub get

# Function to build macOS
build_macos() {
    print_header "Building for macOS"

    cd macos
    print_status "Installing CocoaPods dependencies..."
    pod install --repo-update
    cd ..

    if [ "$BUILD_TYPE" = "release" ]; then
        print_status "Building macOS app in release mode..."
        flutter build macos --release
    else
        print_status "Building macOS app in debug mode..."
        flutter build macos --debug
    fi

    print_status "macOS build complete!"
}

# Function to build iOS
build_ios() {
    print_header "Building for iOS"

    cd ios
    print_status "Installing CocoaPods dependencies..."
    pod install --repo-update
    cd ..

    if [ "$BUILD_TYPE" = "release" ]; then
        print_status "Building iOS app in release mode..."
        print_warning "Note: Release builds require proper code signing configuration"
        flutter build ios --release
    else
        print_status "Building iOS app in debug mode for simulator..."
        flutter build ios --debug --simulator
    fi

    print_status "iOS build complete!"
}

# Function to build Android
build_android() {
    print_header "Building for Android"

    if [ "$BUILD_TYPE" = "release" ]; then
        print_status "Building Android APK in release mode..."
        print_warning "Note: Release builds require signing configuration in android/app/build.gradle"
        flutter build apk --release
    else
        print_status "Building Android APK in debug mode..."
        flutter build apk --debug
    fi

    print_status "Android build complete!"
}

# Execute builds based on platform selection
case $PLATFORM in
    macos)
        build_macos
        ;;
    ios)
        build_ios
        ;;
    android)
        build_android
        ;;
    all)
        build_macos
        build_ios
        build_android
        ;;
    *)
        print_error "Unknown platform: $PLATFORM"
        print_error "Valid platforms: macos, ios, android, all"
        exit 1
        ;;
esac

# Summary
print_header "Build Summary"
print_status "Platform: $PLATFORM"
print_status "Build Type: $BUILD_TYPE"
print_status "Clean Build: $CLEAN"
echo ""
print_status "All builds completed successfully! 🎉"
echo ""

# Show output locations
if [ "$PLATFORM" = "macos" ] || [ "$PLATFORM" = "all" ]; then
    echo "macOS app location: build/macos/Build/Products/$([[ $BUILD_TYPE == "release" ]] && echo "Release" || echo "Debug")/signal_champ.app"
fi

if [ "$PLATFORM" = "ios" ] || [ "$PLATFORM" = "all" ]; then
    echo "iOS app location: build/ios/iphoneos/"
fi

if [ "$PLATFORM" = "android" ] || [ "$PLATFORM" = "all" ]; then
    echo "Android APK location: build/app/outputs/flutter-apk/app-$BUILD_TYPE.apk"
fi

echo ""
print_status "Done! Check BUILD_INSTRUCTIONS_XCODE_14.md for detailed documentation."
