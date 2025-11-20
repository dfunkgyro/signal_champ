# Edit Mode Implementation Status

## Overview
This document tracks the implementation of the Edit Mode feature for Signal Champ, which allows users to move and adjust railway layout components with snap-to-grid positioning and persistence.

## ✅ Completed Features

### Phase 1: Data Model Foundation (COMPLETED)

#### 1. Signal Direction Support
- ✅ Added `SignalDirection` enum (east, west)
- ✅ Added `direction` property to Signal model
- ✅ Updated signal rendering to use `signal.direction` instead of hardcoded IDs
- ✅ Initialized C30 signal with `SignalDirection.west`

#### 2. Mutable Coordinates
Made all component coordinates mutable for edit mode:
- ✅ Signal (x, y)
- ✅ Point (x, y)
- ✅ Platform (startX, endX, y)
- ✅ TrainStop (x, y)
- ✅ BlockSection (startX, endX, y)
- ✅ AxleCounter (x, y)

#### 3. New Data Models
- ✅ **BufferStop** class - proper data model (previously hardcoded in painter)
- ✅ **Crossover** class - tracks parent-child point relationships
- ✅ **SignalDirection** enum - for signal orientation control

#### 4. Axle Counter Flipped Orientation
- ✅ Added `flipped` boolean property to AxleCounter
- ✅ Updated detection logic to swap D1/D2 when flipped
- ✅ Updated rendering to swap D1/D2 visual positions when flipped
- ✅ Allows axle counters to match different track orientations

### Phase 2: Relative Positioning (COMPLETED)

#### 1. Point Gap Refactoring
- ✅ Replaced ALL hardcoded point gap coordinates with relative offsets
- ✅ Created `_drawStandardCrossoverGap()` for middle crossover (78A, 78B)
- ✅ Created `_drawDoubleDiamondGap()` for double diamonds (76A/B, 77A/B, 79A/B, 80A/B)
- ✅ All gaps now calculate relative to `point.x` and `point.y`
- ✅ Point gaps will correctly follow points when moved

#### 2. Platform Enhancements
- ✅ Added `length` getter to Platform class

### Bug Fixes (COMPLETED)
- ✅ Fixed ConnectionIndicator context error
- ✅ Fixed RailwaySearchBar reference (renamed to RailwaySearchBarEnhanced)

## 🚧 Pending Features (Not Yet Implemented)

### Phase 3: Controller Integration (PENDING)

#### 1. BufferStop Instances
- ❌ Add BufferStop instances to controller
- ❌ Replace hardcoded buffer stop rendering with data-driven approach
- ❌ Initialize buffer stops at current positions

#### 2. Crossover Instances
- ❌ Add Crossover instances to controller
- ❌ Define crossover-point relationships:
  - Left: crossover_211_212 → points [76A, 76B, 77A, 77B]
  - Middle: crossover106/109 → points [78A, 78B]
  - Right: crossover_303_304 → points [79A, 79B, 80A, 80B]

#### 3. Initialize Remaining Signal Directions
- ❌ Set C28 to SignalDirection.west (if exists)
- ❌ Verify all westbound signals have correct direction

### Phase 4: Edit Mode Core (PENDING)

#### 1. Edit Mode State Management
- ❌ Add `editModeEnabled` boolean to controller
- ❌ Add `gridSize` property (default: 10)
- ❌ Add `pauseSimulationForEditMode()` method
- ❌ Add `resumeSimulationAfterEditMode()` method

#### 2. Snap-to-Grid Helpers
- ❌ Add `snapToGrid(double value, double gridSize)` helper
- ❌ Add `moveComponent(componentType, id, deltaX, deltaY)` method
- ❌ Add bounds checking for movement

#### 3. Component Movement Methods
```dart
// Example methods needed:
void moveSignal(String signalId, double newX, double newY)
void movePoint(String pointId, double newX, double newY)
void movePlatform(String platformId, double newX, double newY)
void moveTrainStop(String stopId, double newX, double newY)
void moveAxleCounter(String counterId, double newX, double newY)
void moveBufferStop(String bufferId, double newX, double newY)
void moveBlock(String blockId, double deltaX, double deltaY)
```

#### 4. Platform Resize Methods
```dart
void resizePlatformLeft(String platformId, double newStartX)
void resizePlatformRight(String platformId, double newEndX)
```

#### 5. Crossover-Point Compound Movement
```dart
void moveCrossover(String crossoverId, double deltaX, double deltaY) {
  // Move crossover block
  // Move all child points together
}
```

#### 6. Train Position Updates
```dart
void updateTrainsInBlock(String blockId, double deltaX, double deltaY) {
  // When block moves, update trains in that block
}
```

### Phase 5: Edit Mode UI (PENDING)

#### 1. Edit Mode Toggle Button
- ❌ Add global Edit Mode toggle button in main UI
- ❌ Visual indicator (lock/unlock icon)
- ❌ Pause simulation when ON
- ❌ Resume simulation when OFF

#### 2. Grid Overlay
- ❌ Optional grid visualization when edit mode is ON
- ❌ Toggle grid visibility

#### 3. Signal Direction Toggle
- ❌ Add "Switch Direction" button in signal dialog
- ❌ Only visible when Edit Mode is ON
- ❌ Toggles between SignalDirection.east and SignalDirection.west

#### 4. Platform Resize Handles
- ❌ Detect clicks on left edge, right edge, center
- ❌ Drag left edge → resize startX
- ❌ Drag right edge → resize endX
- ❌ Drag center → move whole platform

#### 5. Component Dragging
- ❌ Implement GestureDetector for all movable components
- ❌ Snap-to-grid while dragging
- ❌ Visual feedback during drag

### Phase 6: Persistence (PENDING)

#### 1. JSON Serialization
- ❌ Add `toJson()` methods for all components
- ❌ Add `fromJson()` factory constructors
- ❌ Create layout export schema

#### 2. Auto-Save to Local Storage
- ❌ Save layout on Edit Mode OFF
- ❌ Use SharedPreferences or Hive
- ❌ Debounce saves (5 seconds)
- ❌ Auto-load on app startup

#### 3. XML Export/Import
- ❌ Implement `exportLayoutToXML()` method
- ❌ Implement `importLayoutFromXML()` method
- ❌ File picker integration
- ❌ Validation on import
- ❌ Save to Downloads folder

#### 4. Reset to Default
- ❌ Store original hardcoded layout
- ❌ Implement `resetToDefaultLayout()` method
- ❌ Confirmation dialog

#### 5. Layout Menu UI
```
Layout Menu:
  📁 Export Layout (XML)
  📂 Import Layout (XML)
  💾 Auto-save: ON/OFF
  ↺ Reset to Default
  ℹ️ Layout Info
```

### Phase 7: Advanced Features (PENDING)

#### 1. Fix Hardcoded AB Positions
- ❌ Make AB display positions calculate from block positions
- ❌ OR add AB position data to models

#### 2. Movable Labels
- ❌ Station name labels
- ❌ Route name labels
- ❌ Point name labels

#### 3. Transponder and WiFi Antenna Movement
- ❌ Make transponders movable
- ❌ Make WiFi antennas movable

#### 4. Validation
- ❌ Prevent invalid positions (components off screen)
- ❌ Warn about overlapping components
- ❌ Check minimum platform sizes

#### 5. Undo/Redo
- ❌ Command pattern for movements
- ❌ Undo/Redo buttons

## 📊 Implementation Summary

### Completed: ~30% of Full Feature
- ✅ Core data models (100%)
- ✅ Relative positioning (100%)
- ✅ Signal direction system (100%)
- ✅ Axle counter flipped orientation (100%)
- ✅ Point gap refactoring (100%)

### Pending: ~70% Remaining
- ❌ Controller integration (0%)
- ❌ Edit Mode state management (0%)
- ❌ Movement logic (0%)
- ❌ UI implementation (0%)
- ❌ Persistence (0%)

## 🎯 Next Steps

To complete the Edit Mode feature, implement in this order:

1. **Add BufferStop instances** to controller (1-2 hours)
2. **Add Crossover instances** to controller (1 hour)
3. **Implement Edit Mode toggle** state management (2-3 hours)
4. **Implement snap-to-grid movement** helpers (2-3 hours)
5. **Add Edit Mode UI toggle** button (1-2 hours)
6. **Implement component dragging** (4-6 hours)
7. **Implement platform resize** (2-3 hours)
8. **Add signal direction toggle** UI (1 hour)
9. **Implement JSON persistence** (4-6 hours)
10. **Implement XML export/import** (3-4 hours)
11. **Add Reset to Default** (1 hour)
12. **Testing and refinement** (4-8 hours)

**Total estimated time remaining: 25-40 hours**

## 🔧 Technical Debt

- BufferStops currently hardcoded in painter at line 1094
- AB positions currently hardcoded in painter at line 495-502
- C28 signal may not exist (needs verification)

## 📝 Notes

The foundation has been solidly implemented with:
- All data models ready for movement
- All coordinates mutable
- All rendering using relative positions
- Signal direction system working
- Axle counter orientation system working

The remaining work is primarily:
- Controller methods for movement
- UI implementation for dragging/resizing
- Persistence layer

All the hard architectural decisions have been made and the groundwork is complete.
