# Three Railway System (MA2-MA1-MA3) Specification

## Overview
This document specifies the expansion from a single railway (MA1) to a seamless 3-railway system with VCC communication and SRS (Schedule Regulator Subsystem).

## Railway Layout

### MA2 (Left Railway - Mirrored)
**Position**: X: -1600 to 0
**VCC**: VCC2

#### Blocks
**Upper Track (y=100)**: 98, 96, 94, 92, 90, 88, 86, 84 (even, descending)
- Block 98: x=-1600 to -1400
- Block 96: x=-1400 to -1200
- Block 94: x=-1200 to -1000
- Block 92: x=-1000 to -800
- Block 90: x=-800 to -600
- Block 88: x=-600 to -400
- Block 86: x=-400 to -200
- Block 84: x=-200 to 0

**Lower Track (y=300)**: 99, 97, 95, 93, 91, 89, 87 (odd, descending)
- Block 99: x=-1200 to -1000
- Block 97: x=-1000 to -800
- Block 95: x=-800 to -600
- Block 93: x=-600 to -400
- Block 91: x=-400 to -200
- Block 89: x=-200 to 0

#### Signals (b-series, descending)
- **b6**: x=-210, y=80 (Upper track, westbound entry)
- **b4**: x=-590, y=320 (Lower track, eastbound entry)
- **b3**: x=-1010, y=320 (Lower track, platform exit)
- **b1**: x=-1210, y=80 (Upper track, platform exit)

#### Points
- **38a**: x=-200, y=100 (Upper track crossover)
- **38b**: x=-800, y=300 (Lower track crossover)

#### Crossovers
- **crossover90**: x=-600 to -700, y=150
- **crossover93**: x=-700 to -800, y=250

#### Platforms
- **P5 (Platform 5)**: x=-1240 to -980, y=100
- **P6 (Platform 6 Bay)**: x=-1240 to -980, y=300

---

### MA1 (Center Railway - Original)
**Position**: X: 0 to 1600
**VCC**: VCC1

#### Blocks (Renamed for consistency)
**Upper Track (y=100)**: 100, 102, 104, 106, 108, 110, 112, 114 (even, ascending)
**Lower Track (y=300)**: 101, 103, 105, 107, 109, 111 (odd, ascending)

#### Signals (Renamed from C-series to b-series)
- **b8**: x=400, y=320 (was C28) - Lower track westbound
- **b10**: x=980, y=320 (was C30) - Lower track platform
- **b11**: x=390, y=80 (was C31) - Upper track eastbound
- **b13**: x=1200, y=80 (was C33) - Upper track platform

#### Points (Renamed)
- **48a**: x=600, y=100 (was 78A)
- **48b**: x=800, y=300 (was 78B)

#### Crossovers
- **crossover106**: x=600 to 700, y=150
- **crossover109**: x=700 to 800, y=250

#### Platforms
- **P1 (Platform 1)**: x=980 to 1240, y=100
- **P2 (Platform 2 Bay)**: x=980 to 1240, y=300

---

### MA3 (Right Railway - Mirrored)
**Position**: X: 1600 to 3200
**VCC**: VCC3

#### Blocks
**Upper Track (y=100)**: 116, 118, 120, 122, 124, 126, 128, 130 (even, ascending)
- Block 116: x=1600 to 1800
- Block 118: x=1800 to 2000
- Block 120: x=2000 to 2200
- Block 122: x=2200 to 2400
- Block 124: x=2400 to 2600
- Block 126: x=2600 to 2800
- Block 128: x=2800 to 3000
- Block 130: x=3000 to 3200

**Lower Track (y=300)**: 113, 115, 117, 119, 121, 123 (odd, ascending)
- Block 113: x=1600 to 1800
- Block 115: x=1800 to 2000
- Block 117: x=2000 to 2200
- Block 119: x=2200 to 2400
- Block 121: x=2400 to 2600
- Block 123: x=2600 to 2800

#### Signals (d-series)
- **d48**: x=1610, y=320 (Lower track, westbound entry)
- **d50**: x=2010, y=320 (Lower track, platform)
- **d51**: x=2010, y=80 (Upper track, platform)
- **d53**: x=2810, y=80 (Upper track, eastbound exit)

#### Points
- **108a**: x=2000, y=100 (Upper track crossover)
- **108b**: x=2400, y=300 (Lower track crossover)

#### Crossovers
- **crossover120**: x=2000 to 2100, y=150
- **crossover119**: x=2100 to 2200, y=250

#### Platforms
- **P3 (Platform 3)**: x=2380 to 2640, y=100
- **P4 (Platform 4 Bay)**: x=2380 to 2640, y=300

---

## Axle Counter Naming System

### MA2 (Descending)
**Upper Track**: ac98, ac96, ac94, ac92, ac90, ac88, ac86, ac84
**Lower Track**: ac99, ac97, ac95, ac93, ac91, ac89, ac87

### MA1 (Existing)
**Upper Track**: ac100, ac104, ac108, ac112
**Lower Track**: ac101, ac105, ac109, ac111

### MA3 (Ascending)
**Upper Track**: ac116, ac120, ac124, ac128
**Lower Track**: ac113, ac117, ac121, ac123

---

## VCC (Vital Computer Controller) System

### VCC1 (MA1 - Center)
**Responsibilities**:
- Manages blocks 100-114, 101-111
- Controls signals b8, b10, b11, b13
- Controls points 48a, 48b
- Coordinates with VCC2 and VCC3

### VCC2 (MA2 - Left)
**Responsibilities**:
- Manages blocks 84-98, 87-99
- Controls signals b1, b3, b4, b6
- Controls points 38a, 38b
- Coordinates with VCC1

### VCC3 (MA3 - Right)
**Responsibilities**:
- Manages blocks 116-130, 113-123
- Controls signals d48, d50, d51, d53
- Controls points 108a, 108b
- Coordinates with VCC1

### VCC Communication Protocol
1. **Handshaking**: Every 1 second
2. **Data Shared**:
   - Train positions and IDs
   - Train destinations
   - Predicted arrival times
   - Signal states
   - Route reservations

3. **Handoff Procedure**:
   - Train approaching boundary
   - Source VCC sends train data to destination VCC
   - Destination VCC acknowledges
   - Train crosses boundary
   - Destination VCC takes control

---

## SRS (Schedule Regulator Subsystem)

### Overview
Part of the SMC (Signaling and Movement Controller), SRS creates and manages timetables with ghost trains.

### Ghost Trains
- **Invisible**: Not rendered on canvas
- **Purpose**: Follow ideal timetable routes
- **Indication**: Green "Timetable OK" when all ghost trains on schedule
- Use **ghost signals** and **ghost points** (invisible infrastructure)

### Timetable Cycle
**Route**: MA2 → MA1 → MA3 → MA2 → MA1 (continuous loop)

#### Example Route MA2→MA1→MA3:
1. Start at Platform 6 (MA2)
2. Depart P6 → Block 91 → Crossover 93 → Block 94
3. Enter MA1 at Block 104 → Platform 1
4. Depart P1 → Block 110 → Crossover 109
5. Enter MA3 at Block 116 → Platform 3
6. Depart P3 → Continue to next cycle

### Real Train Assignment
1. User adds a train
2. User selects "Run to Timetable"
3. System finds nearest ghost train
4. Real train replaces ghost train
5. Real train follows ghost train's schedule
6. Shows delay/early status relative to ghost train timing

### Timetable Display
- **On Time**: Green indicator (±30 seconds)
- **Early**: Blue indicator with -XX seconds
- **Late**: Red indicator with +XX seconds
- **Not Scheduled**: Gray indicator

---

## Seamless Train Movement

### Boundary Transitions

#### MA2 → MA1 (at X=0)
- MA2 Block 84/89 → MA1 Block 100/101
- VCC2 hands off to VCC1
- Axle counters update ownership
- Signals coordinate

#### MA1 → MA3 (at X=1600)
- MA1 Block 114/111 → MA3 Block 116/113
- VCC1 hands off to VCC3
- Axle counters update ownership
- Signals coordinate

#### MA3 → MA1 (at X=1600)
- MA3 Block 116/113 → MA1 Block 114/111
- VCC3 hands off to VCC1

#### MA1 → MA2 (at X=0)
- MA1 Block 100/101 → MA2 Block 84/89
- VCC1 hands off to VCC2

### Route Protection
- Routes can span multiple areas
- All affected VCCs must approve
- Example: MA1→MA3 route reserves blocks in both areas

---

## Implementation Phases

### Phase 1: Models ✅ COMPLETE
- Add RailwayArea enum
- Add VccController class
- Add Ghost train classes
- Add SRS classes
- Add Timetable classes
- Update existing models with area tracking

### Phase 2: Controller (IN PROGRESS)
- Initialize 3 VCC controllers
- Create MA2 and MA3 layouts
- Rename MA1 signals/points
- Implement VCC handshaking
- Implement SRS ghost train system
- Implement timetable management
- Handle boundary transitions

### Phase 3: Painter
- Extend canvas to support -1600 to 3200
- Render MA2, MA1, MA3 railways
- Visual distinction between areas
- Ghost train indicators (invisible but show status)
- Timetable status indicators

### Phase 4: Screen UI
- Timetable panel showing all schedules
- VCC status indicators
- SRS enable/disable controls
- Train-to-timetable assignment
- Delay/early indicators
- Ghost train count display
- Area selection controls

---

## Testing Checklist

- [ ] Train travels MA2→MA1 seamlessly
- [ ] Train travels MA1→MA3 seamlessly
- [ ] Train travels MA3→MA1 seamlessly
- [ ] VCC1 ↔ VCC2 handshaking works
- [ ] VCC1 ↔ VCC3 handshaking works
- [ ] Ghost trains run invisibly
- [ ] Timetable shows correct status
- [ ] Real train can replace ghost train
- [ ] Delay calculation accurate
- [ ] All signals work in all areas
- [ ] All points work in all areas
- [ ] Axle counters track across boundaries
- [ ] Collision detection across areas
- [ ] CBTC works across boundaries

---

## File Changes Required

### terminal_station_models.dart ✅
- Added RailwayArea enum
- Added VccController class
- Added GhostTrain, TimetableEntry classes
- Added SrsData class
- Added area field to all infrastructure models

### terminal_station_controller.dart (IN PROGRESS)
- Add VCC controller initialization
- Add SRS initialization
- Create MA2 and MA3 layouts
- Rename MA1 infrastructure
- Implement VCC communication
- Implement SRS logic
- Handle area transitions

### terminal_station_painter.dart (TODO)
- Extend rendering for 3 areas
- Add visual area distinctions
- Add timetable status indicators

### terminal_station_screen.dart (TODO)
- Add timetable UI panel
- Add VCC status display
- Add SRS controls
- Add train assignment controls

---

**Version**: 1.0
**Status**: Phase 1 Complete, Phase 2 In Progress
**Last Updated**: 2025-11-16
