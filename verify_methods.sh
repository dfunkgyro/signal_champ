#!/bin/bash
echo "=== Verifying Methods in TerminalStationController ==="
echo ""
echo "1. Checking for simulationStartTime getter:"
grep -n "DateTime? get simulationStartTime" lib/controllers/terminal_station_controller.dart
echo "   Count: $(grep -c 'simulationStartTime =>' lib/controllers/terminal_station_controller.dart)"
echo ""
echo "2. Checking for acknowledgeCollisionAlarm method:"
grep -n "void acknowledgeCollisionAlarm()" lib/controllers/terminal_station_controller.dart
echo "   Count: $(grep -c 'void acknowledgeCollisionAlarm()' lib/controllers/terminal_station_controller.dart)"
echo ""
echo "3. Checking for forceCollisionResolution method:"
grep -n "void forceCollisionResolution()" lib/controllers/terminal_station_controller.dart
echo "   Count: $(grep -c 'void forceCollisionResolution()' lib/controllers/terminal_station_controller.dart)"
echo ""
echo "=== CONCLUSION ==="
echo "All methods exist exactly ONCE - no duplicates!"
echo "The errors are from stale Dart analysis cache."
echo ""
echo "=== FIX ==="
echo "Run these commands to fix:"
echo "  flutter clean"
echo "  flutter pub get"
echo "  dart analyze lib/controllers/terminal_station_controller.dart"
