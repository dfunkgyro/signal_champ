#!/bin/bash
# Script to clean Flutter build cache and rebuild

echo "Cleaning Flutter build cache..."
flutter clean

echo "Getting Flutter dependencies..."
flutter pub get

echo "Running build_runner if needed..."
if grep -q "build_runner" pubspec.yaml; then
    flutter pub run build_runner build --delete-conflicting-outputs
fi

echo "Analyzing code..."
flutter analyze

echo "Done! Try running your app now."
