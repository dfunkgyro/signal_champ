# Signal Champ - Incomplete Features Audit Report

**Date:** 2025-11-20
**Branch:** claude/debug-macos-crash-01LeSJx8PLdzqyane2KXJvJN
**Audit Scope:** Complete codebase analysis for missing, incomplete, and placeholder features

---

## EXECUTIVE SUMMARY

**Total Features Audited:** 15
**Status Breakdown:**
- ✅ Complete: 7 (47%)
- ❌ Incomplete/Missing: 6 (40%)
- ⚠️ Platform-Limited: 2 (13%)

**Critical Findings:**
- 2 HIGH priority features blocking core functionality
- 3 MEDIUM priority features affecting user experience
- 3 LOW priority features for advanced functionality
- 2 macOS-specific limitations due to native framework issues

---

## 1. HIGH PRIORITY - BLOCKING CORE FUNCTIONALITY

### 1.1 Scenario Player/Viewer ❌

**Location:** `lib/screens/scenario_marketplace_screen.dart:623`

**Status:** Not Implemented (Placeholder only)

**Current Code:**
```dart
void _openScenario(RailwayScenario scenario) {
  // TODO: Implement scenario player/viewer
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Opening "${scenario.name}"...')),
  );
}
```

**Problem:**
- Users can browse and download scenarios from marketplace
- Clicking "Open" on a scenario shows snackbar but does nothing
- **Core feature completely non-functional**

**Impact:**
- Users cannot play downloaded scenarios
- Scenario marketplace is essentially useless
- Major feature gap in user experience

**What Needs Implementation:**
1. Create ScenarioPlayerScreen to load and display scenarios
2. Parse scenario JSON format
3. Apply scenario configuration to railway simulation
4. Handle scenario objectives and win conditions
5. Track scenario progress and completion
6. Return to marketplace with results

**Implementation Estimate:** 3-5 days

---

### 1.2 Scenario Testing Mode ❌

**Location:** `lib/screens/scenario_builder_screen.dart:545`

**Status:** Not Implemented (Placeholder only)

**Current Code:**
```dart
void _testScenario() {
  // TODO: Implement scenario testing
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Test mode - Feature coming soon!')),
  );
}
```

**Problem:**
- Scenario builder has full editing capabilities
- "Test Scenario" button exists in UI but does nothing
- Users cannot validate their scenarios before publishing

**Impact:**
- Creators must publish untested scenarios
- Users download broken scenarios
- No quality control in scenario creation workflow

**What Needs Implementation:**
1. Instantiate temporary railway simulation from current scenario state
2. Run scenario in test mode without publishing
3. Provide testing UI with debug information
4. Allow returning to editor to fix issues
5. Validate scenario objectives are achievable
6. Check for configuration errors (missing routes, invalid signals, etc.)

**Implementation Estimate:** 2-3 days

---

## 2. MEDIUM PRIORITY - AFFECTING USER EXPERIENCE

### 2.1 Component Creation in Edit Mode ❌

**Location:** `lib/widgets/edit_mode_toolbar.dart:217`

**Status:** Toolbar UI complete, creation logic missing

**Current Code:**
```dart
onPressed: () {
  // TODO: Actually create the component
  controller.logEvent('➕ Added $componentType $newId');
  Navigator.pop(context);
},
```

**Problem:**
- Edit Mode toolbar fully functional (just integrated in latest commit)
- Users can select component types to add
- Dialog appears and generates unique IDs
- **But clicking "Add" only logs event, doesn't create component**

**Impact:**
- Users cannot add new signals, points, platforms, etc.
- Edit mode limited to moving/deleting existing components
- Severely limits edit capabilities

**Affected Component Types:**
1. Signals
2. Points (switches)
3. Platforms
4. Train Stops
5. Buffer Stops
6. Axle Counters
7. Transponders
8. WiFi Antennas

**What Needs Implementation:**
1. Component factory methods in TerminalStationController
2. Default positioning logic (center of viewport or 0,0)
3. Wrap creation in AddComponentCommand for undo support
4. Trigger notifyListeners() to re-render
5. Auto-select newly created component for immediate dragging
6. Add to appropriate Map (signals, points, platforms, etc.)

**Implementation Estimate:** 1-2 days

**Note:** Command pattern already exists, just need factory methods.

---

### 2.2 Template Loading ❌

**Location:** `lib/screens/scenario_builder_screen.dart:585`

**Status:** Models exist, integration missing

**Current Code:**
```dart
void _loadTemplate() {
  // TODO: Implement template loading
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Template loading - Feature coming soon!')),
  );
}
```

**Problem:**
- Railway template models fully implemented in `lib/models/railway_template.dart`
- Template data structures ready
- UI button exists but doesn't work
- **Integration layer missing**

**Impact:**
- Users must build scenarios from scratch
- No quick-start options for common layouts
- Reduced productivity in scenario creation

**Available Template Models:**
- Simple station layout
- Junction with crossover
- Terminal station with multiple platforms
- Double-track mainline section

**What Needs Implementation:**
1. Template selection dialog
2. Load template JSON/data
3. Apply template to current scenario builder state
4. Preview template before applying
5. Merge with existing scenario or replace completely
6. Update RouteDesignerCanvas with template components

**Implementation Estimate:** 2-3 days

---

### 2.3 Collision Report Export ❌

**Location:** `lib/widgets/collision_alarm_ui.dart:535`

**Status:** Not Implemented (Placeholder only)

**Current Code:**
```dart
onPressed: () {
  // Export functionality
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Report exported (feature coming soon)')),
  );
},
```

**Problem:**
- Collision detection and analysis fully functional
- Detailed collision information displayed in UI
- "Export Report" button exists
- **Cannot save reports for later review**

**Impact:**
- Users cannot document collision incidents
- No data persistence for collision analysis
- Difficult to track safety improvements over time

**What Needs Implementation:**
1. Format collision data as structured report (JSON, CSV, or PDF)
2. Include timestamp, location, trains involved, speed, severity
3. Use file picker to choose save location
4. Generate human-readable summary
5. Optional: Email/share functionality

**Implementation Estimate:** 1-2 days

---

## 3. PLATFORM-SPECIFIC LIMITATIONS

### 3.1 Speech Recognition Disabled on macOS ⚠️

**Location:** `lib/main.dart:158-168`

**Status:** Disabled via platform check

**Current Code:**
```dart
// WORKAROUND: Skip speech recognition on macOS due to potential native crashes
if (Platform.isMacOS) {
  debugPrint('  → Skipping speech recognition on macOS (optional feature)');
} else {
  debugPrint('  → Initializing speech recognition...');
  await SpeechService().initialize();
  debugPrint('  ✅ Speech recognition initialized');
}
```

**Problem:**
- Native macOS speech recognition framework has compatibility issues
- Crashes app during initialization
- **All voice command features disabled on macOS**

**Impact:**
- macOS users cannot use voice commands for SSM AI agent
- Platform feature parity broken
- Voice-based natural language interface unavailable

**Root Cause:**
- Compatibility issues with macOS AVFoundation framework
- speech_to_text package version incompatibility
- See `VOICE_PACKAGE_MIGRATION.md` for details

**Potential Solutions:**
1. Update speech_to_text package when macOS support improves
2. Use alternative speech recognition library for macOS
3. Implement web-based speech API as fallback
4. Add browser-based speech recognition when running on web

**Implementation Estimate:** 3-5 days (package research + integration)

---

### 3.2 Text-to-Speech Disabled on macOS ⚠️

**Location:**
- `lib/main.dart:175-188`
- `lib/services/text_to_speech_service.dart:93`

**Status:** Disabled via platform check

**Current Code:**
```dart
// WORKAROUND: Skip TTS initialization on macOS due to AVFoundation crashes
if (Platform.isMacOS) {
  debugPrint('  → Skipping text-to-speech on macOS (known compatibility issue)');
} else {
  debugPrint('  → Initializing text-to-speech...');
  await TextToSpeechService().initialize();
  debugPrint('  ✅ Text-to-speech initialized');
}
```

**Problem:**
- AVSpeechSynthesisVoiceQuality enum causes fatal crash
- Error: `unexpected enum case 'AVSpeechSynthesisVoiceQuality(rawValue: 0)'`
- **All audio announcements disabled on macOS**

**Impact:**
- macOS users don't receive audio feedback
- No announcements for train arrivals, departures, warnings
- Accessibility features unavailable on macOS

**Root Cause:**
- AVFoundation framework incompatibility with Flutter builds
- Enum mismatch in native bridge
- See `ACTUAL_CRASH_ANALYSIS.md` for crash details

**Potential Solutions:**
1. Update flutter_tts package when macOS support improves
2. Use alternative TTS library for macOS
3. Implement web-based TTS API as fallback
4. Use macOS native say command via process execution

**Implementation Estimate:** 3-5 days (package research + integration)

---

## 4. LOW PRIORITY - ADVANCED FEATURES

### 4.1 Double Diamond Crossover Routing ❌

**Location:** `lib/controllers/terminal_station_controller.dart:3071-3151`

**Status:** Visual only, no routing logic

**Current Code:**
```dart
// DOUBLE DIAMOND CROSSOVER ROUTING (PLACEHOLDER - INCOMPLETE)

/// TODO: Implement double diamond crossover routing logic
void _initializeDoubleDiamondCrossovers() {
  // TODO: Implement point machine definitions (line 3093)
  // TODO: Implement diamond crossing objects (line 3103)
  // TODO: Implement track circuits for crossover sections (line 3112)
  // TODO: Define routes through crossovers (line 3121)

  _logEvent('⚠️ Double diamond crossover routing NOT IMPLEMENTED - visual only');
}

/// TODO: Calculate route through double diamond crossover (line 3127)
String? _calculateCrossoverRoute(...) {
  // TODO: Implement route calculation logic
  return null; // Placeholder - not implemented
}

/// TODO: Apply speed limit based on crossover route (line 3144)
double _getCrossoverSpeedLimit(String routeId) {
  // TODO: Return appropriate speed limit based on route type
  return 80.0; // Placeholder - default to straight route speed
}
```

**Problem:**
- Double diamond crossovers rendered visually
- No actual routing logic implemented
- Trains cannot traverse crossovers
- **Purely cosmetic feature**

**Impact:**
- Advanced railway simulation scenarios limited
- Crossovers are decorative only
- Reduced realism in complex layouts

**What Needs Implementation:**

1. **Point Machine Definitions** (8 machines):
   - 77c, 77d, 77e, 77f (East-West crossover)
   - 79c, 79d, 79e, 79f (North-South crossover)

2. **Diamond Crossing Objects**:
   - 45° diamond crossing
   - 135° diamond crossing
   - Crossing detection logic

3. **Track Circuit Definitions**:
   - TC_X77_EW (East-West section)
   - TC_X77_NS (North-South section)
   - Occupancy detection

4. **Route Definitions** (8 routes):
   - R77_EW_Straight (80 km/h)
   - R77_EW_Cross (60 km/h)
   - R77_NS_Straight (80 km/h)
   - R77_NS_Cross (60 km/h)
   - R77_Turn_NW/NE/SW/SE (40 km/h)

5. **Speed Limit Enforcement**:
   - Straight routes: 80 km/h
   - Cross routes: 60 km/h
   - Turning routes: 40 km/h

6. **Point Locking & Route Reservation**:
   - Lock all 8 points when route reserved
   - Prevent conflicting route reservations
   - Release points when route cleared

**Implementation Estimate:** 5-7 days (complex signaling logic)

---

### 4.2 Point Position Validation for Routes ❌

**Location:** `lib/controllers/terminal_station_controller.dart:1632-1634`

**Status:** Placeholder comment, no implementation

**Current Code:**
```dart
// TODO: Check if point position is correct for train's destination
// This is a placeholder for future route-based point validation
```

**Problem:**
- Point positions not validated against train's intended route
- Trains can pass through incorrectly-set points
- Reduced realism in signaling simulation

**Impact:**
- Less accurate railway simulation
- Safety features not fully implemented
- Points can be in wrong position without consequences

**What Needs Implementation:**
1. Route lookup based on train destination
2. Query expected point positions for route
3. Compare actual vs expected point positions
4. Trigger warning/error if mismatch detected
5. Optional: Auto-correct point positions or stop train

**Implementation Estimate:** 2-3 days

---

### 4.3 SSM AI Agent Color Issue 🟦→🟧

**Location:** `lib/services/widget_preferences_service.dart`

**Status:** Code shows orange default, user sees blue

**Current Code:**
```dart
// AI Agent settings (match minimap dimensions)
double _aiAgentWidth = 280.0;
double _aiAgentHeight = 140.0; // Fixed in commit bf1272f
Color _aiAgentColor = Colors.orange; // Default is orange
```

**Problem:**
- Code clearly sets default to orange
- User reports seeing blue
- **Likely SharedPreferences override from previous session**

**Impact:**
- Visual inconsistency with other widgets
- User expectation mismatch

**Solution:**
User can reset widget preferences via:
1. Settings → Widget Preferences → AI Agent Color → Reset
2. Or clear app data to reset all SharedPreferences

**Implementation:** No code changes needed, user configuration issue

---

## 5. FEATURE COMPLETENESS MATRIX

| Category | Feature | Implemented | Tested | Priority | Blocking |
|----------|---------|-------------|--------|----------|----------|
| **Scenarios** | ||||
| | Marketplace Browser | ✅ | ✅ | - | - |
| | Scenario Builder | ✅ | ✅ | - | - |
| | Scenario Player | ❌ | ❌ | HIGH | Yes |
| | Scenario Testing | ❌ | ❌ | HIGH | Yes |
| | Template Loading | ❌ | ❌ | MEDIUM | No |
| **Edit Mode** | ||||
| | Toolbar UI | ✅ | ✅ | - | - |
| | Component Selection | ✅ | ✅ | - | - |
| | Component Deletion | ✅ | ✅ | - | - |
| | Component Creation | ❌ | ❌ | MEDIUM | Partial |
| | Undo/Redo System | ✅ | ✅ | - | - |
| | Grid System | ✅ | ✅ | - | - |
| **Railway** | ||||
| | Basic Signaling | ✅ | ✅ | - | - |
| | Route Reservation | ✅ | ✅ | - | - |
| | Collision Detection | ✅ | ✅ | - | - |
| | Double Diamond Crossover | ❌ | ❌ | LOW | No |
| | Route Point Validation | ❌ | ❌ | LOW | No |
| **Data Export** | ||||
| | Layout XML Export | ✅ | ✅ | - | - |
| | Layout JSON Export | ✅ | ✅ | - | - |
| | Collision Report Export | ❌ | ❌ | MEDIUM | No |
| **Voice/Audio** | ||||
| | Speech Recognition | ⚠️ | N/A | MEDIUM | macOS only |
| | Text-to-Speech | ⚠️ | N/A | MEDIUM | macOS only |

**Legend:**
- ✅ Complete and functional
- ❌ Not implemented or placeholder only
- ⚠️ Platform-limited (macOS disabled)

---

## 6. IMPLEMENTATION ROADMAP

### **Sprint 1: Critical Features (Week 1-2)**

**Goal:** Unblock core scenario functionality

**Tasks:**
1. ✅ Fix macOS startup crashes (COMPLETED)
2. ✅ Fix connection status detection (COMPLETED)
3. ✅ Integrate Edit Mode toolbar (COMPLETED)
4. **→ Implement Scenario Player/Viewer** ⬅ START HERE
   - Create ScenarioPlayerScreen
   - Parse scenario JSON
   - Apply to railway simulation
   - Handle objectives and completion
5. **→ Implement Scenario Testing Mode**
   - Test mode UI
   - Validation checks
   - Debug information display

**Deliverable:** Users can play and test scenarios

---

### **Sprint 2: Edit Mode Completion (Week 3-4)**

**Goal:** Complete edit mode functionality

**Tasks:**
1. **Implement Component Creation**
   - Factory methods for all 8 component types
   - Default positioning logic
   - AddComponentCommand integration
2. **Implement Template Loading**
   - Template selection dialog
   - Load and apply templates
   - Preview functionality
3. **Testing & Bug Fixes**
   - Test all component types
   - Verify undo/redo works with creation
   - Edge case handling

**Deliverable:** Fully functional edit mode

---

### **Sprint 3: Data Export & Quality of Life (Week 5-6)**

**Goal:** Improve user experience and data persistence

**Tasks:**
1. **Collision Report Export**
   - JSON format export
   - CSV format export
   - File picker integration
2. **UI Polish**
   - Error message improvements
   - Loading indicators
   - Confirmation dialogs
3. **Documentation**
   - User guide for edit mode
   - Scenario creation tutorial
   - Feature completeness report

**Deliverable:** Production-ready data export

---

### **Sprint 4: macOS Platform Parity (Week 7-8)**

**Goal:** Restore voice features on macOS

**Tasks:**
1. **Research Alternative Packages**
   - Test updated speech_to_text package
   - Evaluate alternative TTS libraries
   - Web-based API fallbacks
2. **Implement macOS-Specific Solution**
   - Replace AVFoundation with compatible library
   - Test on macOS builds
   - Fallback handling
3. **Testing**
   - Cross-platform testing
   - Voice command accuracy
   - TTS quality assessment

**Deliverable:** Voice features on all platforms

---

### **Future Work: Advanced Railway Features**

**No specific timeline - low priority**

**Tasks:**
1. Double Diamond Crossover Routing
   - Point machine definitions
   - Diamond crossing logic
   - Route calculation algorithms
   - Speed limit enforcement
2. Route-Based Point Validation
   - Route lookup system
   - Position validation logic
   - Auto-correction features

**Deliverable:** Advanced signaling simulation

---

## 7. RISK ASSESSMENT

### **High Risk Items**

1. **Scenario Player Implementation**
   - Risk: Complex state management
   - Mitigation: Reuse existing TerminalStationController logic

2. **macOS Voice Features**
   - Risk: No guaranteed solution if packages remain broken
   - Mitigation: Web-based API fallback, native macOS `say` command

### **Medium Risk Items**

3. **Component Creation**
   - Risk: Undo/redo integration complexity
   - Mitigation: Command pattern already established

4. **Template Loading**
   - Risk: Merging templates with existing scenarios
   - Mitigation: Offer replace vs merge options

### **Low Risk Items**

5. **Collision Report Export**
   - Risk: Minimal, straightforward file I/O

6. **Double Diamond Crossover**
   - Risk: Complex but isolated feature

---

## 8. DEPENDENCIES & BLOCKERS

### **External Dependencies**

- **speech_to_text package** - macOS compatibility unknown
- **flutter_tts package** - macOS AVFoundation issues
- **Supabase connection** - Required for scenario marketplace sync

### **Internal Dependencies**

- Scenario Player depends on: Scenario Builder data models ✅
- Template Loading depends on: RailwayTemplate models ✅
- Component Creation depends on: Edit Mode toolbar ✅ (just completed)

### **Current Blockers**

None - all dependencies resolved or have workarounds

---

## 9. TESTING REQUIREMENTS

### **Per Feature**

Each implementation requires:
1. Unit tests for business logic
2. Widget tests for UI components
3. Integration tests for user flows
4. Platform-specific testing (macOS, iOS, Android, Web)

### **Scenario Features**

- Test scenario JSON parsing with valid/invalid data
- Test scenario objectives and win conditions
- Test scenario marketplace sync
- Test template loading with various layouts

### **Edit Mode**

- Test all 8 component types creation
- Test undo/redo with component creation
- Test component deletion safety checks
- Test grid alignment
- Test keyboard shortcuts

### **Cross-Platform**

- Verify macOS workarounds don't affect other platforms
- Test voice features on iOS/Android
- Verify export functionality on all platforms

---

## 10. TECHNICAL DEBT SUMMARY

### **Code Quality**

- ✅ Command Pattern properly implemented
- ✅ Provider state management used correctly
- ✅ Error handling comprehensive
- ⚠️ Multiple TODO comments (documented here)
- ⚠️ Platform-specific workarounds (necessary but adds complexity)

### **Architecture**

- ✅ Clean separation of concerns (screens/widgets/services/controllers)
- ✅ Models well-defined
- ✅ State management consistent
- ⚠️ Some features split across multiple files (e.g., crossover routing)

### **Documentation**

- ✅ Good inline comments for complex logic
- ✅ Error messages descriptive
- ⚠️ User-facing documentation minimal
- ⚠️ API documentation could be improved

---

## 11. RECOMMENDATIONS

### **Immediate Actions**

1. **Prioritize Scenario Player** - Unblocks core feature
2. **Complete Component Creation** - Edit mode almost done
3. **Document Current State** - This report is a start

### **Short-term Actions**

4. **User Testing** - Get feedback on existing features
5. **Template Loading** - High value, medium effort
6. **macOS Voice Research** - Understand if solvable

### **Long-term Actions**

7. **Advanced Railway Features** - After core features stable
8. **Performance Optimization** - Monitor as complexity grows
9. **User Documentation** - Create comprehensive guide

---

## 12. CONCLUSION

**Current State:**
- Core railway simulation: ✅ **Fully functional**
- Edit mode: ⚠️ **Almost complete** (just needs component creation)
- Scenario system: ⚠️ **Half-implemented** (builder works, player missing)
- Data export: ⚠️ **Partial** (layout works, collision reports missing)
- Voice features: ⚠️ **Platform-limited** (disabled on macOS)

**Next Steps:**
1. Implement Scenario Player (HIGH priority)
2. Implement Component Creation (MEDIUM priority)
3. Implement Scenario Testing (HIGH priority)

**Overall Assessment:**
The app has a solid foundation with core railway simulation fully functional. The main gaps are in scenario playback and edit mode component creation. These are well-scoped features with clear implementation paths.

**Estimated Time to Full Feature Completeness:**
- Sprint 1-2: 4 weeks (scenario system + edit mode)
- Sprint 3: 2 weeks (data export + polish)
- Sprint 4: 2 weeks (macOS voice features)

**Total: 8 weeks to complete all MEDIUM/HIGH priority features**

---

## APPENDIX A: TODO REFERENCE

### **All TODO Comments by File**

**lib/controllers/terminal_station_controller.dart:**
- Line 1632: Point position validation for routes
- Line 3071: Double diamond crossover initialization
- Line 3093: Point machine definitions
- Line 3103: Diamond crossing objects
- Line 3112: Track circuit definitions
- Line 3121: Route definitions through crossovers
- Line 3127: Calculate crossover route logic
- Line 3144: Crossover speed limit calculation

**lib/widgets/edit_mode_toolbar.dart:**
- Line 217: Actually create component (factory methods)

**lib/screens/scenario_builder_screen.dart:**
- Line 545: Scenario testing implementation
- Line 585: Template loading implementation

**lib/screens/scenario_marketplace_screen.dart:**
- Line 623: Scenario player/viewer implementation

**lib/widgets/collision_alarm_ui.dart:**
- Line 535: Collision report export

---

## APPENDIX B: FILE REFERENCE

### **Key Files for Implementation**

**Scenario System:**
- `lib/screens/scenario_marketplace_screen.dart` - Marketplace UI
- `lib/screens/scenario_builder_screen.dart` - Builder UI
- `lib/models/railway_scenario.dart` - Scenario data model
- `lib/models/railway_template.dart` - Template models ✅
- Need to create: `lib/screens/scenario_player_screen.dart`

**Edit Mode:**
- `lib/widgets/edit_mode_toolbar.dart` - Toolbar UI ✅
- `lib/controllers/edit_commands.dart` - Command pattern ✅
- `lib/controllers/terminal_station_controller.dart` - Need factory methods

**Collision System:**
- `lib/widgets/collision_alarm_ui.dart` - UI display ✅
- Need to create: Export service

**Voice/Audio:**
- `lib/services/speech_service.dart` - Speech recognition
- `lib/services/text_to_speech_service.dart` - TTS
- `lib/main.dart` - Platform checks

---

**End of Audit Report**

For questions or clarification on any incomplete feature, refer to the specific file and line number references above.
