# Remaining Features & Fixes

## ✅ COMPLETED (Just Pushed)

1. **Voice Recognition Service Fixes** ✓
   - Fixed localeId getter error
   - Updated for speech_to_text 5.1.0 compatibility

2. **Android Build Fix** ✓
   - Removed problematic text_to_speech package
   - Namespace configuration error resolved

3. **AB Self-Occupancy Logic** ✓ **CRITICAL FIX**
   - Trains no longer block themselves on partial AB occupation
   - Added `_getTrainCurrentAB()` helper method
   - Modified `_getOccupiedABAhead()` to skip current AB
   - Implements direction-aware tail confirmation

---

## 🚧 PENDING IMPLEMENTATION

### 1. **Edit Mode Selection Tools** (HIGH PRIORITY)
**Problem**: Users cannot select components to delete, move, or resize

**Required Changes**:
- Add selection state to TerminalStationController
- Implement tap/click handlers for component selection
- Add visual selection indicators (highlight selected item)
- Create delete button that works on selected component
- Add drag handlers for moving selected items
- Add resize handles for platforms

**Files to Modify**:
- `lib/controllers/terminal_station_controller.dart` - Add selection state
- `lib/screens/terminal_station_screen.dart` - Add tap handlers
- `lib/widgets/edit_mode_toolbar.dart` - Add delete/move UI buttons

### 2. **Voice Recognition UI Integration**

#### A. Search Bar Voice Recognition
**Required**:
- Add microphone icon button to search bar
- Add "search for" activation word toggle
- Integrate VoiceRecognitionService with search widget
- Display voice input status (listening/processing)

**Files to Modify**:
- `lib/widgets/railway_search.dart` (or equivalent)
- Add microphone IconButton
- Connect to VoiceRecognitionService
- Process voice input as search query

#### B. AI Agent Voice Recognition
**Required**:
- Add microphone icon to AI Agent panel header
- Add "ssm" activation word toggle
- Integrate VoiceRecognitionService
- Show listening status indicator

**Files to Modify**:
- `lib/widgets/ai_agent_panel.dart`
- Add microphone button next to settings
- Add listening indicator (pulsing mic icon)
- Process voice as AI commands

### 3. **Train Orientation Over Crossovers** (HIGH PRIORITY)
**Problem**: Trains upside down on diamond crossovers (76A/B, 77A/B, 79A/B, 80A/B)

**Analysis**:
- Points 78A/78B work correctly as reference
- Other crossovers have incorrect Y-axis or rotation calculations

**Required Changes**:
- Find train rendering/rotation logic
- Check crossover block definitions
- Ensure train angle updates correctly based on track curve
- Fix Y-coordinate calculations for crossover blocks

**Files to Investigate**:
- Train painting logic (terminal_station_screen.dart or custom painter)
- Crossover block definitions
- Train rotation calculation methods

### 4. **Point Gaps Positioning** (MEDIUM PRIORITY)
**Problem**: Point gaps for 76A/B, 77A/B, 79A/B, 80A/B incorrectly positioned

**Reference**: Points 78A/78B have correct positioning

**Required**:
- Measure 78A/78B gap positions relative to track
- Calculate relative offsets for other point pairs
- Update point gap rendering coordinates

**Files to Modify**:
- Point gap rendering code
- Point definitions with gap coordinates

### 5. **Multi-Carriage Individual Alignment** (HIGH PRIORITY)
**Problem**: Multi-carriage trains (M2, M4, M6, M8) don't align carriages individually

**Required**:
- Modify train rendering to draw each carriage separately
- Calculate angle for each carriage based on its position
- Implement carriage chain physics (follow path)

**Technical Approach**:
```dart
// Each carriage should:
1. Track its own position on the curve
2. Calculate its own rotation based on local track angle
3. Maintain fixed distance from previous carriage
4. Update angle independently during curves
```

**Files to Modify**:
- Train rendering CustomPainter
- Train model to include carriage positions
- Movement update logic

### 6. **Responsive UI for All Screen Sizes** (MEDIUM PRIORITY)
**Required**:
- Phone layout (< 600px width)
- Tablet layout (600-1200px width)
- Desktop layout (> 1200px width)
- Split screen support
- Multi-window support

**Approach**:
- Use `LayoutBuilder` to detect screen size
- Create responsive breakpoints
- Adjust panel sizes/positions based on available space
- Stack vs Row/Column layouts

**Files to Modify**:
- `lib/screens/terminal_station_screen.dart` - Main layout
- All panel widgets (mini map, AI agent, etc.)

---

## 📝 IMPLEMENTATION PRIORITY

### Must Fix Immediately:
1. ✅ AB Self-Occupancy (DONE)
2. Edit Mode Selection Tools
3. Train Orientation on Crossovers
4. Multi-Carriage Alignment

### Should Fix Soon:
5. Voice UI Integration (Search Bar)
6. Voice UI Integration (AI Agent)
7. Point Gaps Positioning

### Nice to Have:
8. Responsive UI Optimization

---

## 🔧 QUICK FIX SNIPPETS

### Edit Mode Selection (Skeleton)
```dart
// In TerminalStationController
String? selectedComponentType;
String? selectedComponentId;

void selectComponent(String type, String id) {
  selectedComponentType = type;
  selectedComponentId = id;
  notifyListeners();
}

void deleteSelectedComponent() {
  if (selectedComponentType != null && selectedComponentId != null) {
    final command = DeleteComponentCommand(
      this,
      selectedComponentType!,
      selectedComponentId!,
      getComponentData(selectedComponentType!, selectedComponentId!),
    );
    commandHistory.executeCommand(command);
    selectedComponentType = null;
    selectedComponentId = null;
  }
}
```

### Voice Recognition Integration (Skeleton)
```dart
// In search bar widget
final voiceService = VoiceRecognitionService();

IconButton(
  icon: Icon(voiceService.isListening ? Icons.mic : Icons.mic_none),
  onPressed: () async {
    if (voiceService.isListening) {
      await voiceService.stopListening();
    } else {
      voiceService.onResult = (text) {
        searchController.text = text;
        performSearch(text);
      };
      await voiceService.startListening();
    }
  },
)
```

---

## ✅ All Critical Fixes Committed and Pushed

Branch: `claude/fix-simulation-time-getter-01S5dJN3geevGkh6UPypjh6j`

**Next Steps**: Implement remaining features from this document.
