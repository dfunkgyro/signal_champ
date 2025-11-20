# Remaining Features - Implementation Guide

**Date:** 2025-11-20
**Session:** Component Dragging & UI Improvements
**Branch:** claude/debug-macos-crash-01LeSJx8PLdzqyane2KXJvJN

---

## ✅ COMPLETED THIS SESSION

### 1. **Component Selection and Dragging** (CRITICAL - DONE)
**Status:** ✅ Fully Implemented

**What Was Fixed:**
- Components can now be selected by clicking them in edit mode
- Drag-and-drop functionality works for all 8 component types
- Automatic snap-to-grid when grid is visible
- Smooth drag with proper coordinate transformation
- Camera panning disabled during component drag

**Files Modified:**
- `lib/screens/terminal_station_screen.dart` (+330 lines)
  - Added dragging state tracking
  - Implemented `_handleEditModeClick()` for component selection
  - Implemented `_isClickingOnComponent()` for hit detection
  - Implemented `_moveComponent()` for position updates with snap-to-grid

**How to Use:**
1. Enable Edit Mode from the toolbar
2. Click any component to select it (log message will confirm)
3. Click and drag the selected component to move it
4. Enable grid to snap components to grid automatically
5. Click empty space to deselect

---

### 2. **Dot Matrix Display Relocation** (DONE)
**Status:** ✅ Fully Implemented

**What Was Changed:**
- Moved from bottom-left floating overlay to right sidebar
- Positioned directly under the minimap
- Resized to 280x140 to match minimap dimensions
- Better UI organization and no canvas obstruction

**Files Modified:**
- `lib/screens/terminal_station_screen.dart`
  - Line 4240-4246: Added to right sidebar column
  - Line 463: Removed old floating position

---

## 🔴 HIGH PRIORITY - Needs Implementation

### 3. **Fix Undo/Redo in Edit Mode**
**Current Status:** ❌ Not Working
**Priority:** HIGH

**Problem:**
- Command history exists but undo/redo buttons don't work
- Commands not being properly recorded during component operations

**Implementation Steps:**

```dart
// In terminal_station_controller.dart

// Add command for component movement
class MoveComponentCommand extends EditCommand {
  final String componentType;
  final String componentId;
  final double oldX, oldY, newX, newY;

  MoveComponentCommand(this.componentType, this.componentId,
                       this.oldX, this.oldY, this.newX, this.newY);

  @override
  void execute(TerminalStationController controller) {
    // Move to new position
    _setComponentPosition(controller, componentType, componentId, newX, newY);
  }

  @override
  void undo(TerminalStationController controller) {
    // Move back to old position
    _setComponentPosition(controller, componentType, componentId, oldX, oldY);
  }
}
```

**In terminal_station_screen.dart:**
```dart
// In _moveComponent(), wrap in command
void _moveComponent(...) {
  // Get current position before moving
  final oldX = _getComponentX(controller, type, id);
  final oldY = _getComponentY(controller, type, id);

  // Move component
  // ... existing code ...

  // Record command on drag end (in onPanEnd)
  if (_dragStartPosition != null) {
    final newX = _getComponentX(controller, type, id);
    final newY = _getComponentY(controller, type, id);
    controller.executeCommand(
      MoveComponentCommand(type, id, oldX, oldY, newX, newY)
    );
  }
}
```

**Files to Modify:**
- `lib/controllers/terminal_station_controller.dart` - Add MoveComponentCommand
- `lib/screens/terminal_station_screen.dart` - Record commands during drag
- `lib/widgets/edit_mode_toolbar.dart` - Ensure undo/redo buttons call controller methods

**Estimated Time:** 2-3 hours

---

### 4. **Update AI Agent Size/Color to Match Minimap**
**Current Status:** Default is blue, should be orange like minimap
**Priority:** MEDIUM

**Implementation:**

```dart
// In lib/services/widget_preferences_service.dart
// Change AI Agent defaults

double _aiAgentWidth = 280.0;  // Match minimap
double _aiAgentHeight = 140.0; // Match minimap
Color _aiAgentColor = Colors.orange; // Match minimap default
```

**Files to Modify:**
- `lib/services/widget_preferences_service.dart` - Update defaults

**Estimated Time:** 5 minutes

---

### 5. **Add Search Capability to OpenAI AI Agent**
**Current Status:** AI agent can execute commands but can't search for components
**Priority:** MEDIUM

**Implementation:**

```dart
// In lib/widgets/ai_agent_panel.dart

// Add to local command processing (around line 200)
if (lower.contains('find') || lower.contains('search') || lower.contains('locate')) {
  _handleSearchCommand(controller, message);
  return;
}

void _handleSearchCommand(TerminalStationController controller, String query) {
  // Extract search term
  final searchTerms = ['signal', 'point', 'platform', 'train', 'block'];

  for (var term in searchTerms) {
    if (query.toLowerCase().contains(term)) {
      // Search for component
      switch (term) {
        case 'signal':
          final signals = controller.signals.keys.toList();
          _addMessage('Search Results',
            '🔍 Found ${signals.length} signals: ${signals.join(", ")}');
          break;
        case 'point':
          final points = controller.points.keys.toList();
          _addMessage('Search Results',
            '🔍 Found ${points.length} points: ${points.join(", ")}');
          break;
        // ... etc for other types
      }
      return;
    }
  }

  _addMessage('Search', '❌ No matches found for: $query');
}
```

**Files to Modify:**
- `lib/widgets/ai_agent_panel.dart` - Add search command handling

**Estimated Time:** 1-2 hours

---

## 🟡 MEDIUM PRIORITY - Feature Enhancements

### 6. **Replace Points with Crossover System**
**Current Status:** Points can be added individually
**Requirement:** Add crossovers (left/right/double diamond) with automatic point gaps

**Implementation:**

```dart
// In lib/controllers/terminal_station_controller.dart

void createCrossover(String id, CrossoverType type, double x, double y) {
  switch (type) {
    case CrossoverType.leftHand:
      // Create two points with correct spacing
      createPoint('${id}_A', x, y);
      createPoint('${id}_B', x + 100, y);

      // Create point gaps between them
      // ... logic to ensure proper connection
      break;

    case CrossoverType.rightHand:
      // Mirror of left-hand
      break;

    case CrossoverType.doubleDiamond:
      // Create 4 points in diamond configuration
      // Add connecting track sections
      break;
  }

  _logEvent('✅ Created $type crossover $id');
  notifyListeners();
}
```

**In edit_mode_toolbar.dart:**
```dart
// Replace "Add Point" button with crossover selector
DropdownButton<CrossoverType>(
  items: [
    DropdownMenuItem(value: CrossoverType.leftHand, child: Text('Left Crossover')),
    DropdownMenuItem(value: CrossoverType.rightHand, child: Text('Right Crossover')),
    DropdownMenuItem(value: CrossoverType.doubleDiamond, child: Text('Double Diamond')),
  ],
  onChanged: (type) => _createCrossover(controller, type),
)
```

**Files to Modify:**
- `lib/controllers/terminal_station_controller.dart` - Add crossover creation methods
- `lib/widgets/edit_mode_toolbar.dart` - Replace point button with crossover selector
- `lib/screens/terminal_station_models.dart` - Add CrossoverType enum

**Estimated Time:** 4-6 hours

---

### 7. **Add Block Creation/Movement in Edit Mode**
**Current Status:** Blocks cannot be added or moved
**Priority:** MEDIUM

**Implementation:**

```dart
// In terminal_station_controller.dart
void createBlock(String id, double startX, double endX, double y) {
  if (blocks.containsKey(id)) {
    _logEvent('❌ Block $id already exists');
    return;
  }

  blocks[id] = BlockSection(
    id: id,
    startX: startX,
    endX: endX,
    y: y,
    occupied: false,
  );

  _logEvent('✅ Created block $id');
  _logEvent('⚠️ WARNING: New block may affect simulation. Test thoroughly!');
  notifyListeners();
}
```

**Block Movement:**
```dart
// In terminal_station_screen.dart _moveComponent()
case 'block':
  final block = controller.blocks[id];
  if (block != null) {
    final length = block.endX - block.startX;
    block.startX += dx;
    block.endX = block.startX + length;
    block.y += dy;

    // Warn user
    controller.logEvent('⚠️ Block moved - verify train routing still works!');
    controller.notifyListeners();
  }
  break;
```

**Files to Modify:**
- `lib/controllers/terminal_station_controller.dart` - Add createBlock method
- `lib/screens/terminal_station_screen.dart` - Add block to _moveComponent
- `lib/widgets/edit_mode_toolbar.dart` - Add "Add Block" button

**Estimated Time:** 3-4 hours

---

### 8. **Make Platform Length Adjustable in Edit Mode**
**Current Status:** Platform length fixed at creation
**Priority:** MEDIUM

**Implementation:**

```dart
// Add resize handles to platforms in edit mode
// In terminal_station_screen.dart

// When platform is selected, show resize handles at both ends
void _renderPlatformHandles(Canvas canvas, Platform platform) {
  if (controller.selectedComponentId == platform.id &&
      controller.editModeEnabled) {
    // Left handle
    final leftHandle = Rect.fromCenter(
      center: Offset(platform.startX, platform.y),
      width: 20,
      height: 20,
    );
    canvas.drawRect(leftHandle, Paint()..color = Colors.blue);

    // Right handle
    final rightHandle = Rect.fromCenter(
      center: Offset(platform.endX, platform.y),
      width: 20,
      height: 20,
    );
    canvas.drawRect(rightHandle, Paint()..color = Colors.blue);
  }
}

// Add handle detection in gesture handlers
bool _isClickingOnHandle(Platform platform, double canvasX, double canvasY) {
  // Check if clicking near startX or endX
  return (canvasX - platform.startX).abs() < 10 ||
         (canvasX - platform.endX).abs() < 10;
}

// Resize platform during drag
void _resizePlatform(Platform platform, String handle, double dx) {
  if (handle == 'left') {
    platform.startX += dx;
  } else {
    platform.endX += dx;
  }
  controller.logEvent('Platform ${platform.id} resized to ${platform.length.toStringAsFixed(0)}m');
}
```

**Files to Modify:**
- `lib/screens/terminal_station_screen.dart` - Add resize handle detection and drag
- `lib/painters/terminal_station_painter.dart` - Draw resize handles in edit mode

**Estimated Time:** 3-4 hours

---

## 🔵 LOW PRIORITY - Advanced Features

### 9. **Voice Recognition with SSM Activation Word**
**Current Status:** Speech recognition disabled on macOS, not integrated with AI agent
**Priority:** LOW (Complex, platform-specific issues)

**Implementation Overview:**

```dart
// In lib/services/speech_service.dart

bool _listeningForActivation = false;
String activationWord = 'ssm';

void startListeningForActivation() async {
  _listeningForActivation = true;

  speechToText.listen(
    onResult: (result) {
      final words = result.recognizedWords.toLowerCase();

      if (words.contains(activationWord)) {
        _logEvent('🎤 SSM activated!');
        _startCommandListening();
      }
    },
    listenMode: ListenMode.continuously,
  );
}

void _startCommandListening() {
  // Listen for actual command
  speechToText.listen(
    onResult: (result) {
      final command = result.recognizedWords;
      _sendToAIAgent(command);
    },
    listenFor: Duration(seconds: 5),
  );
}
```

**Permission Handling:**

```yaml
# android/app/src/main/AndroidManifest.xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>

# ios/Runner/Info.plist
<key>NSMicrophoneUsageDescription</key>
<string>Signal Champ needs microphone access for voice commands</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Signal Champ uses speech recognition for SSM voice control</string>

# macos/Runner/DebugProfile.entitlements
<key>com.apple.security.device.audio-input</key>
<true/>
```

**Request Permissions at Runtime:**

```dart
// In lib/main.dart
Future<void> _requestPermissions() async {
  if (Platform.isAndroid || Platform.isIOS) {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      _initializeSpeechRecognition();
    } else {
      _showPermissionDeniedDialog();
    }
  } else if (Platform.isMacOS) {
    // macOS permissions handled via Info.plist
    // User will see system dialog on first use
    _initializeSpeechRecognition();
  }
}
```

**Toggle in AI Agent:**

```dart
// In lib/widgets/ai_agent_panel.dart
bool _voiceEnabled = false;

IconButton(
  icon: Icon(_voiceEnabled ? Icons.mic : Icons.mic_off),
  onPressed: () {
    setState(() => _voiceEnabled = !_voiceEnabled);
    if (_voiceEnabled) {
      SpeechService().startListeningForActivation();
    } else {
      SpeechService().stop();
    }
  },
)
```

**Files to Modify:**
- `lib/services/speech_service.dart` - Add SSM activation logic
- `lib/widgets/ai_agent_panel.dart` - Add voice toggle
- `lib/main.dart` - Request permissions at startup
- Platform-specific permission files

**Challenges:**
- macOS speech recognition currently disabled due to crashes
- Need to update `speech_to_text` package or find alternative
- Platform-specific permission flows differ
- Continuous listening drains battery

**Estimated Time:** 2-3 days (due to platform complexities)

---

## 📋 IMPLEMENTATION PRIORITY ORDER

### Week 1 - Critical Fixes
1. ✅ Component selection and dragging (DONE)
2. ✅ Dot matrix relocation (DONE)
3. 🔲 Fix undo/redo functionality (2-3 hours)
4. 🔲 Update AI agent appearance (5 minutes)
5. 🔲 Add AI agent search capability (1-2 hours)

### Week 2 - Feature Enhancements
6. 🔲 Block creation and movement (3-4 hours)
7. 🔲 Platform length adjustment (3-4 hours)
8. 🔲 Crossover system (4-6 hours)

### Week 3 - Advanced Features
9. 🔲 Voice recognition with SSM (2-3 days)
10. 🔲 Microphone permissions for all platforms (included in #9)

---

## 🛠️ QUICK REFERENCE - Key Files

| Feature | Primary File | Secondary Files |
|---------|-------------|-----------------|
| Component Dragging | terminal_station_screen.dart | - |
| Undo/Redo | terminal_station_controller.dart | edit_mode_toolbar.dart, edit_commands.dart |
| AI Agent Size/Color | widget_preferences_service.dart | - |
| AI Agent Search | ai_agent_panel.dart | - |
| Crossovers | terminal_station_controller.dart | edit_mode_toolbar.dart, terminal_station_models.dart |
| Block Editing | terminal_station_controller.dart | terminal_station_screen.dart, edit_mode_toolbar.dart |
| Platform Resize | terminal_station_screen.dart | terminal_station_painter.dart |
| Voice Recognition | speech_service.dart | ai_agent_panel.dart, main.dart, platform configs |

---

## 📝 TESTING CHECKLIST

After implementing each feature:

- [ ] Feature works in edit mode
- [ ] Feature doesn't break normal mode
- [ ] Snap-to-grid works correctly
- [ ] Undo/redo works (after fix)
- [ ] No console errors
- [ ] Performance acceptable
- [ ] Works on all platforms (where applicable)
- [ ] User feedback messages clear

---

## ⚠️ KNOWN ISSUES & WARNINGS

1. **macOS Voice Recognition:** Currently disabled due to crashes. Needs package update or alternative solution.

2. **Block Movement:** Moving blocks can break train routing logic. Always warn users and recommend testing.

3. **Platform Resizing:** Need to ensure minimum length (e.g., 50m) to prevent visual glitches.

4. **Crossover Complexity:** Auto-connecting points and gaps requires careful coordinate calculation.

5. **Undo/Redo Memory:** Large command histories can consume significant memory. Consider limiting to last 50 commands.

---

**End of Implementation Guide**

For questions or clarification on any feature, refer to the specific file and line number references above.
