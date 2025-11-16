# Terminal Station Layout Styles

This document describes the three professional layout styles available in the Terminal Station simulator.

## Overview

The Terminal Station now supports **3 different layout styles** to provide users with maximum flexibility and professional interfaces for interacting with the simulation. Each layout is optimized for specific use cases while ensuring full access to all features and functions.

## Layout Styles

### 1. Compact Layout 🔹
**Purpose**: Minimal UI, maximum canvas space

**Best for**:
- Focusing on the simulation visualization
- Presentations and demos
- Users who prefer minimal UI clutter
- Training scenarios where attention should be on the tracks

**Characteristics**:
- Panel Width: 240px (left & right)
- Top Panel Height: 60px
- Font Size: 11px (controls), 10px (labels)
- Default Zoom: 0.7x
- Compact zoom controls (36px)
- Essential information only
- Streamlined interface

**Features**:
✅ All simulation controls accessible
✅ All train management features
✅ Signal and route controls
✅ Collision detection and recovery
✅ CBTC functionality
✅ Axle counter management

---

### 2. Standard Layout 🔷 (Default)
**Purpose**: Balanced layout with professional appearance

**Best for**:
- General operation and training
- Day-to-day simulation work
- New users learning the system
- Professional demonstrations

**Characteristics**:
- Panel Width: 320px (left & right)
- Top Panel Height: 80px
- Font Size: 13px (controls), 12px (labels)
- Default Zoom: 0.8x
- Standard zoom controls (48px)
- Full information display
- All advanced controls visible

**Features**:
✅ All Compact layout features PLUS:
✅ Detailed status information
✅ Advanced control options
✅ Enhanced visibility of system state
✅ Comprehensive event logging
✅ Full diagnostic information

---

### 3. Expanded Layout 🔶
**Purpose**: Maximum information display for power users

**Best for**:
- Advanced users and operators
- Detailed analysis and debugging
- Training instructors
- System monitoring and oversight
- Complex multi-train scenarios

**Characteristics**:
- Panel Width: 380px (left & right)
- Top Panel Height: 100px
- Font Size: 14px (controls), 13px (labels)
- Default Zoom: 0.9x
- Large zoom controls (56px)
- Maximum information density
- All features prominently displayed

**Features**:
✅ All Standard layout features PLUS:
✅ Expanded control panels
✅ Enhanced readability
✅ More detailed train information
✅ Comprehensive system diagnostics
✅ Advanced analysis tools
✅ Full collision forensics display

---

## How to Change Layouts

### Method 1: Dropdown Selector (Recommended)
1. Click the **Layout Dropdown** in the top-right of the app bar
2. Select your preferred layout:
   - 🔹 **Compact** - Minimal interface
   - 🔷 **Standard** - Balanced view (default)
   - 🔶 **Expanded** - Maximum information

### Method 2: Programmatic (for developers)
```dart
// Get the controller
final controller = context.read<TerminalStationController>();

// Set a specific layout
controller.setLayoutStyle(LayoutStyle.compact);
controller.setLayoutStyle(LayoutStyle.standard);
controller.setLayoutStyle(LayoutStyle.expanded);

// Cycle through layouts
controller.cycleLayoutStyle();
```

---

## Visual Indicators

### Layout Info Banner
A colored banner appears below the app bar showing:
- Current layout name
- Layout description
- Color-coded indicator:
  - **Purple** = Compact
  - **Blue** = Standard
  - **Green** = Expanded

### Zoom Controls
The floating zoom controls automatically adapt to the current layout:
- Size adjusts based on layout
- Compact mode has smaller, tighter controls
- Expanded mode has larger, more accessible controls

---

## Feature Comparison Matrix

| Feature | Compact | Standard | Expanded |
|---------|---------|----------|----------|
| **Panel Width** | 240px | 320px | 380px |
| **Top Panel** | 60px | 80px | 100px |
| **Font Size** | 11/10px | 13/12px | 14/13px |
| **Default Zoom** | 0.7x | 0.8x | 0.9x |
| **Zoom Controls** | 36px | 48px | 56px |
| Train Management | ✅ | ✅ | ✅ |
| Signal Controls | ✅ | ✅ | ✅ |
| Route Management | ✅ | ✅ | ✅ |
| Collision Detection | ✅ | ✅ | ✅ |
| CBTC Features | ✅ | ✅ | ✅ |
| Axle Counters | ✅ | ✅ | ✅ |
| Detailed Info | ❌ | ✅ | ✅ |
| Advanced Controls | ❌ | ✅ | ✅ |
| Enhanced Diagnostics | ❌ | ✅ | ✅ |
| Maximum Readability | ❌ | ❌ | ✅ |

---

## Layout-Responsive Features

### Automatic Adjustments
When you change layouts, the following automatically adapt:

1. **Panel Widths**
   - Left and right panels resize
   - Canvas area adjusts accordingly

2. **Font Sizes**
   - All labels scale appropriately
   - Control text adjusts for readability

3. **Zoom Level**
   - Default zoom optimized for layout
   - Zoom controls resize

4. **Control Density**
   - Compact mode: streamlined controls
   - Standard/Expanded: full controls visible

5. **Visual Elements**
   - Block labels
   - Signal labels
   - Train names
   - Platform labels
   - Axle counter indicators

---

## Professional Use Cases

### Compact Layout Scenarios
1. **Presentation Mode**: When showing the simulation to a group
2. **Focus Mode**: When you need to concentrate on train movements
3. **Limited Screen Space**: On smaller displays or split screens
4. **Quick Glance**: Monitoring multiple simulations

### Standard Layout Scenarios
1. **Training**: Teaching new operators
2. **Daily Operations**: Regular simulation tasks
3. **General Use**: Default professional experience
4. **Balanced Workflow**: Mix of monitoring and control

### Expanded Layout Scenarios
1. **Advanced Training**: Teaching complex scenarios
2. **Debugging**: Analyzing system behavior
3. **Multi-Train Operations**: Managing complex traffic
4. **System Analysis**: Deep dive into collision scenarios
5. **Professional Development**: Creating training materials

---

## Technical Implementation

### Files Modified
1. **terminal_station_models.dart**
   - Added `LayoutStyle` enum
   - Added `LayoutConfiguration` class
   - Three predefined configurations

2. **terminal_station_controller.dart**
   - Layout state management
   - Layout switching logic
   - Helper methods for layout info

3. **terminal_station_painter.dart**
   - Dynamic font sizing
   - Layout-aware rendering
   - Responsive visual elements

4. **terminal_station_screen.dart**
   - Layout selector dropdown
   - Responsive panel sizing
   - Layout info banner
   - Adaptive zoom controls

### Configuration Class
```dart
class LayoutConfiguration {
  final LayoutStyle style;
  final double leftPanelWidth;
  final double rightPanelWidth;
  final double topPanelHeight;
  final double controlFontSize;
  final double labelFontSize;
  final bool showDetailedInfo;
  final bool showAdvancedControls;
  final bool compactControls;
  final double zoomControlSize;
  final double defaultZoom;
}
```

---

## Accessibility Features

All layouts maintain:
- ✅ Full keyboard accessibility
- ✅ Screen reader compatibility
- ✅ High contrast text
- ✅ Clear visual hierarchy
- ✅ Touch-friendly controls
- ✅ Consistent interaction patterns

---

## Tips for Best Experience

1. **Start with Standard**: Get familiar with all features
2. **Use Compact for Demos**: Clean, professional appearance
3. **Switch to Expanded for Analysis**: When debugging or training
4. **Adjust Zoom**: Use zoom controls to fine-tune visibility
5. **Toggle Panels**: Hide panels when you need more canvas space
6. **Combine Features**: Use layout + panel toggles for maximum flexibility

---

## Future Enhancements

Potential additions:
- [ ] Custom layout configurations
- [ ] Save layout preferences
- [ ] Per-theme layout settings
- [ ] Layout keyboard shortcuts
- [ ] Layout presets for different scenarios
- [ ] Auto-switch based on screen size

---

## Support

For questions or issues with layouts:
1. Check this documentation
2. Review the code comments
3. Test each layout to understand differences
4. Report bugs with layout name and description

---

**Version**: 1.0
**Last Updated**: 2025-11-16
**Author**: Signal Champ Development Team
