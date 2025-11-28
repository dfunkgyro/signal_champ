import 'dart:convert';
import '../screens/terminal_station_models.dart';

/// Represents a complete railway layout configuration
class LayoutConfiguration {
  final String id;
  final String name;
  final String description;
  final Map<String, dynamic> data;

  LayoutConfiguration({
    required this.id,
    required this.name,
    required this.description,
    required this.data,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'data': data,
    };
  }

  /// Create from JSON
  factory LayoutConfiguration.fromJson(Map<String, dynamic> json) {
    return LayoutConfiguration(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      data: json['data'] as Map<String, dynamic>,
    );
  }

  /// Create a copy with modifications
  LayoutConfiguration copyWith({
    String? id,
    String? name,
    String? description,
    Map<String, dynamic>? data,
  }) {
    return LayoutConfiguration(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      data: data ?? this.data,
    );
  }
}

/// Pre-defined railway layout designs
class PredefinedLayouts {
  /// Layout 1: Classic Terminal Station (Default)
  static LayoutConfiguration get classicTerminal => LayoutConfiguration(
        id: 'classic_terminal',
        name: 'Classic Terminal Station',
        description: 'Traditional terminal station with 4 platforms and 3 crossover sections',
        data: _classicTerminalData(),
      );

  /// Layout 2: Express Through Station
  static LayoutConfiguration get expressThroughStation => LayoutConfiguration(
        id: 'express_through',
        name: 'Express Through Station',
        description: 'High-speed through station with bypass tracks and island platforms',
        data: _expressThroughData(),
      );

  /// Layout 3: Complex Junction
  static LayoutConfiguration get complexJunction => LayoutConfiguration(
        id: 'complex_junction',
        name: 'Complex Railway Junction',
        description: 'Multi-level junction with diamond crossings and scissor crossovers',
        data: _complexJunctionData(),
      );

  /// Layout 4: Default Full Terminal Station (matches startup layout)
  static LayoutConfiguration get defaultFullTerminal => LayoutConfiguration(
        id: 'default_full_terminal',
        name: 'Default Full Terminal',
        description: 'Complete 3-section terminal station with all features (startup default)',
        data: {}, // Empty data - handled specially by resetLayoutToDefault()
      );

  /// Layout 5: Simple Shuttle Service
  static LayoutConfiguration get simpleShuttle => LayoutConfiguration(
        id: 'simple_shuttle',
        name: 'Simple Shuttle Service',
        description: 'Basic shuttle service with 2 platforms - perfect for beginners',
        data: _simpleShuttleData(),
      );

  /// Layout 6: Metro Ring Line
  static LayoutConfiguration get metroRing => LayoutConfiguration(
        id: 'metro_ring',
        name: 'Metro Ring Line',
        description: 'Circular metro line with 6 stations and bidirectional operation',
        data: _metroRingData(),
      );

  /// Layout 7: Mainline Junction with Goods Yard
  static LayoutConfiguration get mainlineJunction => LayoutConfiguration(
        id: 'mainline_junction',
        name: 'Mainline Junction with Goods Yard',
        description: 'Complex mainline junction with passenger platforms and freight sidings',
        data: _mainlineJunctionData(),
      );

  /// Get all predefined layouts
  static List<LayoutConfiguration> getAll() {
    return [
      defaultFullTerminal, // Put default first
      classicTerminal,
      expressThroughStation,
      complexJunction,
      simpleShuttle,
      metroRing,
      mainlineJunction,
    ];
  }

  // ============================================================================
  // LAYOUT DATA GENERATORS
  // ============================================================================

  static Map<String, dynamic> _classicTerminalData() {
    return {
      'blocks': _createClassicBlocks(),
      'signals': _createClassicSignals(),
      'points': _createClassicPoints(),
      'crossovers': _createClassicCrossovers(),
      'platforms': _createClassicPlatforms(),
      'trainStops': _createClassicTrainStops(),
      'bufferStops': _createClassicBufferStops(),
      'axleCounters': _createClassicAxleCounters(),
      'transponders': _createClassicTransponders(),
    };
  }

  static Map<String, dynamic> _expressThroughData() {
    return {
      'blocks': _createExpressBlocks(),
      'signals': _createExpressSignals(),
      'points': _createExpressPoints(),
      'crossovers': _createExpressCrossovers(),
      'platforms': _createExpressPlatforms(),
      'trainStops': _createExpressTrainStops(),
      'bufferStops': _createExpressBufferStops(),
      'axleCounters': _createExpressAxleCounters(),
      'transponders': _createExpressTransponders(),
    };
  }

  static Map<String, dynamic> _complexJunctionData() {
    return {
      'blocks': _createJunctionBlocks(),
      'signals': _createJunctionSignals(),
      'points': _createJunctionPoints(),
      'crossovers': _createJunctionCrossovers(),
      'platforms': _createJunctionPlatforms(),
      'trainStops': _createJunctionTrainStops(),
      'bufferStops': _createJunctionBufferStops(),
      'axleCounters': _createJunctionAxleCounters(),
      'transponders': _createJunctionTransponders(),
    };
  }

  // ============================================================================
  // CLASSIC TERMINAL STATION DATA
  // ============================================================================

  static List<Map<String, dynamic>> _createClassicBlocks() {
    return [
      // Main line blocks
      {'id': '100', 'startX': -800.0, 'endX': -400.0, 'y': 100.0, 'name': 'Approach West', 'occupied': false},
      {'id': '101', 'startX': -400.0, 'endX': 0.0, 'y': 100.0, 'name': 'Platform 1 Approach', 'occupied': false},
      {'id': '102', 'startX': 0.0, 'endX': 400.0, 'y': 100.0, 'name': 'Platform 1', 'occupied': false},
      {'id': '103', 'startX': 400.0, 'endX': 800.0, 'y': 100.0, 'name': 'Platform 1 Departure', 'occupied': false},
      {'id': '104', 'startX': 800.0, 'endX': 1200.0, 'y': 100.0, 'name': 'Crossover West', 'occupied': false},
      {'id': '105', 'startX': 1200.0, 'endX': 1600.0, 'y': 100.0, 'name': 'Central Section', 'occupied': false},
      {'id': '106', 'startX': 1600.0, 'endX': 2000.0, 'y': 100.0, 'name': 'Crossover Central', 'occupied': false},
      {'id': '107', 'startX': 2000.0, 'endX': 2400.0, 'y': 100.0, 'name': 'Platform 3 Approach', 'occupied': false},
      {'id': '108', 'startX': 2400.0, 'endX': 2800.0, 'y': 100.0, 'name': 'Platform 3', 'occupied': false},

      // Lower track blocks
      {'id': '200', 'startX': -800.0, 'endX': -400.0, 'y': 300.0, 'name': 'Approach East', 'occupied': false},
      {'id': '201', 'startX': -400.0, 'endX': 0.0, 'y': 300.0, 'name': 'Platform 2 Approach', 'occupied': false},
      {'id': '202', 'startX': 0.0, 'endX': 400.0, 'y': 300.0, 'name': 'Platform 2', 'occupied': false},
      {'id': '203', 'startX': 400.0, 'endX': 800.0, 'y': 300.0, 'name': 'Platform 2 Departure', 'occupied': false},
      {'id': '204', 'startX': 800.0, 'endX': 1200.0, 'y': 300.0, 'name': 'Crossover West Lower', 'occupied': false},
      {'id': '205', 'startX': 1200.0, 'endX': 1600.0, 'y': 300.0, 'name': 'Central Section Lower', 'occupied': false},
      {'id': '206', 'startX': 1600.0, 'endX': 2000.0, 'y': 300.0, 'name': 'Crossover Central Lower', 'occupied': false},
      {'id': '207', 'startX': 2000.0, 'endX': 2400.0, 'y': 300.0, 'name': 'Platform 4 Approach', 'occupied': false},
      {'id': '208', 'startX': 2400.0, 'endX': 2800.0, 'y': 300.0, 'name': 'Platform 4', 'occupied': false},
    ];
  }

  static List<Map<String, dynamic>> _createClassicSignals() {
    return [
      // Upper track signals (y=100)
      {'id': '1A', 'x': -750.0, 'y': 80.0, 'aspect': 'green'},
      {'id': '1B', 'x': -350.0, 'y': 80.0, 'aspect': 'yellow'},
      {'id': '1C', 'x': 50.0, 'y': 80.0, 'aspect': 'green'},
      {'id': '1D', 'x': 450.0, 'y': 80.0, 'aspect': 'green'},
      {'id': '1E', 'x': 850.0, 'y': 80.0, 'aspect': 'green'},
      {'id': '1F', 'x': 1250.0, 'y': 80.0, 'aspect': 'green'},
      {'id': '1G', 'x': 1650.0, 'y': 80.0, 'aspect': 'green'},
      {'id': '1H', 'x': 2050.0, 'y': 80.0, 'aspect': 'green'},
      {'id': '1I', 'x': 2450.0, 'y': 80.0, 'aspect': 'green'},

      // Lower track signals (y=300)
      {'id': '2A', 'x': -750.0, 'y': 320.0, 'aspect': 'green'},
      {'id': '2B', 'x': -350.0, 'y': 320.0, 'aspect': 'yellow'},
      {'id': '2C', 'x': 50.0, 'y': 320.0, 'aspect': 'green'},
      {'id': '2D', 'x': 450.0, 'y': 320.0, 'aspect': 'green'},
      {'id': '2E', 'x': 850.0, 'y': 320.0, 'aspect': 'green'},
      {'id': '2F', 'x': 1250.0, 'y': 320.0, 'aspect': 'green'},
      {'id': '2G', 'x': 1650.0, 'y': 320.0, 'aspect': 'green'},
      {'id': '2H', 'x': 2050.0, 'y': 320.0, 'aspect': 'green'},
      {'id': '2I', 'x': 2450.0, 'y': 320.0, 'aspect': 'green'},
    ];
  }

  static List<Map<String, dynamic>> _createClassicPoints() {
    return [
      {'id': '76A', 'x': 900.0, 'y': 100.0, 'position': 'normal'},
      {'id': '76B', 'x': 1100.0, 'y': 300.0, 'position': 'normal'},
      {'id': '77A', 'x': 1700.0, 'y': 100.0, 'position': 'normal'},
      {'id': '77B', 'x': 1900.0, 'y': 300.0, 'position': 'normal'},
    ];
  }

  static List<Map<String, dynamic>> _createClassicCrossovers() {
    return [
      {
        'id': 'crossover_west',
        'name': 'West Crossover',
        'pointIds': ['76A', '76B'],
        'blockId': '104',
        'type': 'righthand',
      },
      {
        'id': 'crossover_central',
        'name': 'Central Crossover',
        'pointIds': ['77A', '77B'],
        'blockId': '106',
        'type': 'righthand',
      },
    ];
  }

  static List<Map<String, dynamic>> _createClassicPlatforms() {
    return [
      {'id': 'PF1', 'name': 'Platform 1', 'startX': 50.0, 'endX': 350.0, 'y': 100.0},
      {'id': 'PF2', 'name': 'Platform 2', 'startX': 50.0, 'endX': 350.0, 'y': 300.0},
      {'id': 'PF3', 'name': 'Platform 3', 'startX': 2450.0, 'endX': 2750.0, 'y': 100.0},
      {'id': 'PF4', 'name': 'Platform 4', 'startX': 2450.0, 'endX': 2750.0, 'y': 300.0},
    ];
  }

  static List<Map<String, dynamic>> _createClassicTrainStops() {
    return [
      {'id': 'TS1', 'x': 200.0, 'y': 100.0, 'active': true},
      {'id': 'TS2', 'x': 200.0, 'y': 300.0, 'active': true},
      {'id': 'TS3', 'x': 2600.0, 'y': 100.0, 'active': true},
      {'id': 'TS4', 'x': 2600.0, 'y': 300.0, 'active': true},
    ];
  }

  static List<Map<String, dynamic>> _createClassicBufferStops() {
    return [
      {'id': 'BS_WEST_1', 'x': -800.0, 'y': 100.0},
      {'id': 'BS_WEST_2', 'x': -800.0, 'y': 300.0},
      {'id': 'BS_EAST_1', 'x': 2800.0, 'y': 100.0},
      {'id': 'BS_EAST_2', 'x': 2800.0, 'y': 300.0},
    ];
  }

  static List<Map<String, dynamic>> _createClassicAxleCounters() {
    return [
      {'id': 'AC100', 'x': -700.0, 'y': 100.0, 'blockId': '100'},
      {'id': 'AC200', 'x': -700.0, 'y': 300.0, 'blockId': '200'},
    ];
  }

  static List<Map<String, dynamic>> _createClassicTransponders() {
    return [
      {'id': 'T100', 'x': -600.0, 'y': 100.0, 'type': 'CBTC'},
      {'id': 'T200', 'x': -600.0, 'y': 300.0, 'type': 'CBTC'},
    ];
  }

  // ============================================================================
  // EXPRESS THROUGH STATION DATA
  // ============================================================================

  static List<Map<String, dynamic>> _createExpressBlocks() {
    return [
      // Express tracks (outer)
      {'id': 'E100', 'startX': -1000.0, 'endX': -500.0, 'y': 50.0, 'name': 'Express West Approach', 'occupied': false},
      {'id': 'E101', 'startX': -500.0, 'endX': 500.0, 'y': 50.0, 'name': 'Express West Through', 'occupied': false},
      {'id': 'E102', 'startX': 500.0, 'endX': 1500.0, 'y': 50.0, 'name': 'Express Central', 'occupied': false},
      {'id': 'E103', 'startX': 1500.0, 'endX': 2500.0, 'y': 50.0, 'name': 'Express East Through', 'occupied': false},
      {'id': 'E104', 'startX': 2500.0, 'endX': 3000.0, 'y': 50.0, 'name': 'Express East Departure', 'occupied': false},

      // Local tracks (center island platforms)
      {'id': 'L100', 'startX': -1000.0, 'endX': -500.0, 'y': 150.0, 'name': 'Local West Approach', 'occupied': false},
      {'id': 'L101', 'startX': -500.0, 'endX': 500.0, 'y': 150.0, 'name': 'Local Platform 1', 'occupied': false},
      {'id': 'L102', 'startX': 500.0, 'endX': 1500.0, 'y': 150.0, 'name': 'Local Platform 2', 'occupied': false},
      {'id': 'L103', 'startX': 1500.0, 'endX': 2500.0, 'y': 150.0, 'name': 'Local Platform 3', 'occupied': false},
      {'id': 'L104', 'startX': 2500.0, 'endX': 3000.0, 'y': 150.0, 'name': 'Local East Departure', 'occupied': false},

      // Return tracks
      {'id': 'R100', 'startX': -1000.0, 'endX': -500.0, 'y': 250.0, 'name': 'Return West', 'occupied': false},
      {'id': 'R101', 'startX': -500.0, 'endX': 500.0, 'y': 250.0, 'name': 'Return Platform 4', 'occupied': false},
      {'id': 'R102', 'startX': 500.0, 'endX': 1500.0, 'y': 250.0, 'name': 'Return Central', 'occupied': false},
      {'id': 'R103', 'startX': 1500.0, 'endX': 2500.0, 'y': 250.0, 'name': 'Return East', 'occupied': false},
    ];
  }

  static List<Map<String, dynamic>> _createExpressSignals() {
    return [
      // Express track signals (y=50)
      {'id': 'ES1', 'x': -900.0, 'y': 30.0, 'aspect': 'green'},
      {'id': 'ES2', 'x': -400.0, 'y': 30.0, 'aspect': 'green'},
      {'id': 'ES3', 'x': 600.0, 'y': 30.0, 'aspect': 'green'},
      {'id': 'ES4', 'x': 1600.0, 'y': 30.0, 'aspect': 'green'},
      {'id': 'ES5', 'x': 2600.0, 'y': 30.0, 'aspect': 'green'},

      // Local track signals (y=150)
      {'id': 'LS1', 'x': -900.0, 'y': 130.0, 'aspect': 'green'},
      {'id': 'LS2', 'x': -400.0, 'y': 130.0, 'aspect': 'yellow'},
      {'id': 'LS3', 'x': 100.0, 'y': 130.0, 'aspect': 'green'},
      {'id': 'LS4', 'x': 700.0, 'y': 130.0, 'aspect': 'green'},
      {'id': 'LS5', 'x': 1100.0, 'y': 130.0, 'aspect': 'green'},
      {'id': 'LS6', 'x': 1700.0, 'y': 130.0, 'aspect': 'green'},
      {'id': 'LS7', 'x': 2100.0, 'y': 130.0, 'aspect': 'green'},
      {'id': 'LS8', 'x': 2600.0, 'y': 130.0, 'aspect': 'green'},

      // Return track signals (y=250)
      {'id': 'RS1', 'x': -900.0, 'y': 270.0, 'aspect': 'green'},
      {'id': 'RS2', 'x': -400.0, 'y': 270.0, 'aspect': 'green'},
      {'id': 'RS3', 'x': 100.0, 'y': 270.0, 'aspect': 'green'},
      {'id': 'RS4', 'x': 700.0, 'y': 270.0, 'aspect': 'green'},
      {'id': 'RS5', 'x': 1200.0, 'y': 270.0, 'aspect': 'green'},
      {'id': 'RS6', 'x': 1700.0, 'y': 270.0, 'aspect': 'green'},
    ];
  }

  static List<Map<String, dynamic>> _createExpressPoints() {
    return [
      {'id': 'P100', 'x': -600.0, 'y': 50.0, 'position': 'normal'},
      {'id': 'P101', 'x': -400.0, 'y': 150.0, 'position': 'normal'},
      {'id': 'P102', 'x': 400.0, 'y': 50.0, 'position': 'normal'},
      {'id': 'P103', 'x': 600.0, 'y': 150.0, 'position': 'normal'},
      {'id': 'P104', 'x': 1400.0, 'y': 150.0, 'position': 'normal'},
      {'id': 'P105', 'x': 1600.0, 'y': 250.0, 'position': 'normal'},
    ];
  }

  static List<Map<String, dynamic>> _createExpressCrossovers() {
    return [
      {
        'id': 'XO_WEST',
        'name': 'West Junction',
        'pointIds': ['P100', 'P101'],
        'blockId': 'E101',
        'type': 'doubleDiamond',
      },
      {
        'id': 'XO_CENTRAL',
        'name': 'Central Junction',
        'pointIds': ['P102', 'P103'],
        'blockId': 'E102',
        'type': 'doubleDiamond',
      },
      {
        'id': 'XO_EAST',
        'name': 'East Junction',
        'pointIds': ['P104', 'P105'],
        'blockId': 'L103',
        'type': 'doubleDiamond',
      },
    ];
  }

  static List<Map<String, dynamic>> _createExpressPlatforms() {
    return [
      {'id': 'EPF1', 'name': 'Express Platform 1', 'startX': -400.0, 'endX': 400.0, 'y': 150.0},
      {'id': 'EPF2', 'name': 'Express Platform 2', 'startX': 600.0, 'endX': 1400.0, 'y': 150.0},
      {'id': 'EPF3', 'name': 'Express Platform 3', 'startX': 1600.0, 'endX': 2400.0, 'y': 150.0},
      {'id': 'EPF4', 'name': 'Express Platform 4', 'startX': -400.0, 'endX': 400.0, 'y': 250.0},
    ];
  }

  static List<Map<String, dynamic>> _createExpressTrainStops() {
    return [
      {'id': 'ETS1', 'x': 0.0, 'y': 150.0, 'active': true},
      {'id': 'ETS2', 'x': 1000.0, 'y': 150.0, 'active': true},
      {'id': 'ETS3', 'x': 2000.0, 'y': 150.0, 'active': true},
      {'id': 'ETS4', 'x': 0.0, 'y': 250.0, 'active': true},
    ];
  }

  static List<Map<String, dynamic>> _createExpressBufferStops() {
    return [
      {'id': 'EBS_W1', 'x': -1000.0, 'y': 50.0},
      {'id': 'EBS_E1', 'x': 3000.0, 'y': 50.0},
    ];
  }

  static List<Map<String, dynamic>> _createExpressAxleCounters() {
    return [
      {'id': 'EAC1', 'x': -900.0, 'y': 50.0, 'blockId': 'E100'},
      {'id': 'EAC2', 'x': -900.0, 'y': 150.0, 'blockId': 'L100'},
    ];
  }

  static List<Map<String, dynamic>> _createExpressTransponders() {
    return [
      {'id': 'ET1', 'x': -800.0, 'y': 50.0, 'type': 'CBTC'},
      {'id': 'ET2', 'x': -800.0, 'y': 150.0, 'type': 'CBTC'},
    ];
  }

  // ============================================================================
  // COMPLEX JUNCTION DATA
  // ============================================================================

  static List<Map<String, dynamic>> _createJunctionBlocks() {
    return [
      // Main line north
      {'id': 'N100', 'startX': -800.0, 'endX': -200.0, 'y': 50.0, 'name': 'North Main Approach', 'occupied': false},
      {'id': 'N101', 'startX': -200.0, 'endX': 400.0, 'y': 50.0, 'name': 'North Main Junction', 'occupied': false},
      {'id': 'N102', 'startX': 400.0, 'endX': 1000.0, 'y': 50.0, 'name': 'North Main Departure', 'occupied': false},

      // Main line south
      {'id': 'S100', 'startX': -800.0, 'endX': -200.0, 'y': 350.0, 'name': 'South Main Approach', 'occupied': false},
      {'id': 'S101', 'startX': -200.0, 'endX': 400.0, 'y': 350.0, 'name': 'South Main Junction', 'occupied': false},
      {'id': 'S102', 'startX': 400.0, 'endX': 1000.0, 'y': 350.0, 'name': 'South Main Departure', 'occupied': false},

      // Branch line west
      {'id': 'W100', 'startX': -800.0, 'endX': -200.0, 'y': 200.0, 'name': 'West Branch', 'occupied': false},
      {'id': 'W101', 'startX': -200.0, 'endX': 100.0, 'y': 200.0, 'name': 'West Junction', 'occupied': false},

      // Branch line east
      {'id': 'E200', 'startX': 300.0, 'endX': 1000.0, 'y': 200.0, 'name': 'East Branch', 'occupied': false},
      {'id': 'E201', 'startX': 1000.0, 'endX': 1600.0, 'y': 200.0, 'name': 'East Departure', 'occupied': false},
    ];
  }

  static List<Map<String, dynamic>> _createJunctionSignals() {
    return [
      // North main line signals (y=50)
      {'id': 'JN1', 'x': -700.0, 'y': 30.0, 'aspect': 'green'},
      {'id': 'JN2', 'x': -100.0, 'y': 30.0, 'aspect': 'yellow'},
      {'id': 'JN3', 'x': 300.0, 'y': 30.0, 'aspect': 'green'},
      {'id': 'JN4', 'x': 600.0, 'y': 30.0, 'aspect': 'green'},

      // South main line signals (y=350)
      {'id': 'JS1', 'x': -700.0, 'y': 370.0, 'aspect': 'green'},
      {'id': 'JS2', 'x': -100.0, 'y': 370.0, 'aspect': 'yellow'},
      {'id': 'JS3', 'x': 300.0, 'y': 370.0, 'aspect': 'green'},
      {'id': 'JS4', 'x': 600.0, 'y': 370.0, 'aspect': 'green'},

      // West branch signals (y=200)
      {'id': 'JW1', 'x': -700.0, 'y': 180.0, 'aspect': 'green'},
      {'id': 'JW2', 'x': -100.0, 'y': 180.0, 'aspect': 'green'},
      {'id': 'JW3', 'x': 200.0, 'y': 180.0, 'aspect': 'green'},

      // East branch signals (y=200)
      {'id': 'JE1', 'x': 400.0, 'y': 180.0, 'aspect': 'green'},
      {'id': 'JE2', 'x': 700.0, 'y': 180.0, 'aspect': 'green'},
      {'id': 'JE3', 'x': 1200.0, 'y': 180.0, 'aspect': 'green'},
    ];
  }

  static List<Map<String, dynamic>> _createJunctionPoints() {
    return [
      // Diamond crossing points
      {'id': 'D1', 'x': 0.0, 'y': 50.0, 'position': 'normal'},
      {'id': 'D2', 'x': 200.0, 'y': 50.0, 'position': 'normal'},
      {'id': 'D3', 'x': 0.0, 'y': 200.0, 'position': 'normal'},
      {'id': 'D4', 'x': 200.0, 'y': 200.0, 'position': 'normal'},
      {'id': 'D5', 'x': 0.0, 'y': 350.0, 'position': 'normal'},
      {'id': 'D6', 'x': 200.0, 'y': 350.0, 'position': 'normal'},

      // Scissor crossover
      {'id': 'SC1', 'x': 500.0, 'y': 50.0, 'position': 'normal'},
      {'id': 'SC2', 'x': 700.0, 'y': 200.0, 'position': 'normal'},
      {'id': 'SC3', 'x': 500.0, 'y': 350.0, 'position': 'normal'},
    ];
  }

  static List<Map<String, dynamic>> _createJunctionCrossovers() {
    return [
      {
        'id': 'DIAMOND_WEST',
        'name': 'West Diamond',
        'pointIds': ['D1', 'D3', 'D5'],
        'blockId': 'N101',
        'type': 'doubleDiamond',
      },
      {
        'id': 'DIAMOND_EAST',
        'name': 'East Diamond',
        'pointIds': ['D2', 'D4', 'D6'],
        'blockId': 'N101',
        'type': 'doubleDiamond',
      },
      {
        'id': 'SCISSOR',
        'name': 'Scissor Crossover',
        'pointIds': ['SC1', 'SC2', 'SC3'],
        'blockId': 'N102',
        'type': 'doubleSlip',
      },
    ];
  }

  static List<Map<String, dynamic>> _createJunctionPlatforms() {
    return [
      {'id': 'JP1', 'name': 'Junction Platform 1', 'startX': -100.0, 'endX': 300.0, 'y': 50.0},
      {'id': 'JP2', 'name': 'Junction Platform 2', 'startX': -100.0, 'endX': 300.0, 'y': 200.0},
      {'id': 'JP3', 'name': 'Junction Platform 3', 'startX': -100.0, 'endX': 300.0, 'y': 350.0},
    ];
  }

  static List<Map<String, dynamic>> _createJunctionTrainStops() {
    return [
      {'id': 'JTS1', 'x': 100.0, 'y': 50.0, 'active': true},
      {'id': 'JTS2', 'x': 100.0, 'y': 200.0, 'active': true},
      {'id': 'JTS3', 'x': 100.0, 'y': 350.0, 'active': true},
    ];
  }

  static List<Map<String, dynamic>> _createJunctionBufferStops() {
    return [
      {'id': 'JBS_N', 'x': 1000.0, 'y': 50.0},
      {'id': 'JBS_S', 'x': 1000.0, 'y': 350.0},
      {'id': 'JBS_W', 'x': -800.0, 'y': 200.0},
      {'id': 'JBS_E', 'x': 1600.0, 'y': 200.0},
    ];
  }

  static List<Map<String, dynamic>> _createJunctionAxleCounters() {
    return [
      {'id': 'JAC1', 'x': -700.0, 'y': 50.0, 'blockId': 'N100'},
      {'id': 'JAC2', 'x': -700.0, 'y': 350.0, 'blockId': 'S100'},
      {'id': 'JAC3', 'x': -700.0, 'y': 200.0, 'blockId': 'W100'},
    ];
  }

  static List<Map<String, dynamic>> _createJunctionTransponders() {
    return [
      {'id': 'JT1', 'x': -600.0, 'y': 50.0, 'type': 'CBTC'},
      {'id': 'JT2', 'x': -600.0, 'y': 350.0, 'type': 'CBTC'},
      {'id': 'JT3', 'x': -600.0, 'y': 200.0, 'type': 'CBTC'},
    ];
  }

  // ============================================================================
  // SIMPLE SHUTTLE SERVICE DATA
  // ============================================================================

  static Map<String, dynamic> _simpleShuttleData() {
    return {
      'blocks': _createShuttleBlocks(),
      'signals': _createShuttleSignals(),
      'points': _createShuttlePoints(),
      'crossovers': _createShuttleCrossovers(),
      'platforms': _createShuttlePlatforms(),
      'trainStops': _createShuttleTrainStops(),
      'bufferStops': _createShuttleBufferStops(),
      'axleCounters': _createShuttleAxleCounters(),
      'transponders': _createShuttleTransponders(),
    };
  }

  static List<Map<String, dynamic>> _createShuttleBlocks() {
    return [
      // Main shuttle line
      {'id': 'SH100', 'startX': -800.0, 'endX': -400.0, 'y': 150.0, 'name': 'West Approach', 'occupied': false},
      {'id': 'SH101', 'startX': -400.0, 'endX': 0.0, 'y': 150.0, 'name': 'Platform 1', 'occupied': false},
      {'id': 'SH102', 'startX': 0.0, 'endX': 400.0, 'y': 150.0, 'name': 'Middle Section', 'occupied': false},
      {'id': 'SH103', 'startX': 400.0, 'endX': 800.0, 'y': 150.0, 'name': 'Platform 2', 'occupied': false},
      {'id': 'SH104', 'startX': 800.0, 'endX': 1200.0, 'y': 150.0, 'name': 'East Departure', 'occupied': false},
    ];
  }

  static List<Map<String, dynamic>> _createShuttleSignals() {
    return [
      {'id': 'SH_S1', 'x': -700.0, 'y': 130.0, 'aspect': 'green'},
      {'id': 'SH_S2', 'x': -350.0, 'y': 130.0, 'aspect': 'green'},
      {'id': 'SH_S3', 'x': 50.0, 'y': 130.0, 'aspect': 'green'},
      {'id': 'SH_S4', 'x': 450.0, 'y': 130.0, 'aspect': 'green'},
      {'id': 'SH_S5', 'x': 850.0, 'y': 130.0, 'aspect': 'green'},
    ];
  }

  static List<Map<String, dynamic>> _createShuttlePoints() {
    return [
      {'id': 'SH_P1', 'x': -600.0, 'y': 150.0, 'position': 'normal'},
      {'id': 'SH_P2', 'x': 200.0, 'y': 150.0, 'position': 'normal'},
      {'id': 'SH_P3', 'x': 600.0, 'y': 150.0, 'position': 'normal'},
    ];
  }

  static List<Map<String, dynamic>> _createShuttleCrossovers() {
    return [];
  }

  static List<Map<String, dynamic>> _createShuttlePlatforms() {
    return [
      {'id': 'SH_PF1', 'name': 'Shuttle Platform 1', 'startX': -350.0, 'endX': -50.0, 'y': 150.0},
      {'id': 'SH_PF2', 'name': 'Shuttle Platform 2', 'startX': 450.0, 'endX': 750.0, 'y': 150.0},
    ];
  }

  static List<Map<String, dynamic>> _createShuttleTrainStops() {
    return [
      {'id': 'SH_TS1', 'x': -200.0, 'y': 150.0, 'active': true},
      {'id': 'SH_TS2', 'x': 600.0, 'y': 150.0, 'active': true},
    ];
  }

  static List<Map<String, dynamic>> _createShuttleBufferStops() {
    return [
      {'id': 'SH_BS1', 'x': -800.0, 'y': 150.0},
      {'id': 'SH_BS2', 'x': 1200.0, 'y': 150.0},
    ];
  }

  static List<Map<String, dynamic>> _createShuttleAxleCounters() {
    return [
      {'id': 'SH_AC1', 'x': -700.0, 'y': 150.0, 'blockId': 'SH100'},
      {'id': 'SH_AC2', 'x': 100.0, 'y': 150.0, 'blockId': 'SH102'},
      {'id': 'SH_AC3', 'x': 900.0, 'y': 150.0, 'blockId': 'SH104'},
    ];
  }

  static List<Map<String, dynamic>> _createShuttleTransponders() {
    return [
      {'id': 'SH_T1', 'x': -600.0, 'y': 150.0, 'type': 'CBTC'},
      {'id': 'SH_T2', 'x': 200.0, 'y': 150.0, 'type': 'CBTC'},
    ];
  }

  // ============================================================================
  // METRO RING LINE DATA
  // ============================================================================

  static Map<String, dynamic> _metroRingData() {
    return {
      'blocks': _createMetroRingBlocks(),
      'signals': _createMetroRingSignals(),
      'points': _createMetroRingPoints(),
      'crossovers': _createMetroRingCrossovers(),
      'platforms': _createMetroRingPlatforms(),
      'trainStops': _createMetroRingTrainStops(),
      'bufferStops': _createMetroRingBufferStops(),
      'axleCounters': _createMetroRingAxleCounters(),
      'transponders': _createMetroRingTransponders(),
    };
  }

  static List<Map<String, dynamic>> _createMetroRingBlocks() {
    // Circular ring layout with 6 stations
    return [
      // Clockwise outer ring (y varies in circle pattern)
      {'id': 'MR100', 'startX': 0.0, 'endX': 200.0, 'y': 100.0, 'name': 'Station 1 Approach', 'occupied': false},
      {'id': 'MR101', 'startX': 200.0, 'endX': 400.0, 'y': 100.0, 'name': 'Station 1', 'occupied': false},
      {'id': 'MR102', 'startX': 400.0, 'endX': 600.0, 'y': 100.0, 'name': 'Station 2 Approach', 'occupied': false},
      {'id': 'MR103', 'startX': 600.0, 'endX': 800.0, 'y': 150.0, 'name': 'Station 2', 'occupied': false},
      {'id': 'MR104', 'startX': 800.0, 'endX': 1000.0, 'y': 200.0, 'name': 'Station 3 Approach', 'occupied': false},
      {'id': 'MR105', 'startX': 1000.0, 'endX': 1200.0, 'y': 250.0, 'name': 'Station 3', 'occupied': false},
      {'id': 'MR106', 'startX': 1200.0, 'endX': 1000.0, 'y': 300.0, 'name': 'Station 4 Approach', 'occupied': false},
      {'id': 'MR107', 'startX': 1000.0, 'endX': 800.0, 'y': 300.0, 'name': 'Station 4', 'occupied': false},
      {'id': 'MR108', 'startX': 800.0, 'endX': 600.0, 'y': 300.0, 'name': 'Station 5 Approach', 'occupied': false},
      {'id': 'MR109', 'startX': 600.0, 'endX': 400.0, 'y': 250.0, 'name': 'Station 5', 'occupied': false},
      {'id': 'MR110', 'startX': 400.0, 'endX': 200.0, 'y': 200.0, 'name': 'Station 6 Approach', 'occupied': false},
      {'id': 'MR111', 'startX': 200.0, 'endX': 0.0, 'y': 150.0, 'name': 'Station 6', 'occupied': false},
    ];
  }

  static List<Map<String, dynamic>> _createMetroRingSignals() {
    return [
      {'id': 'MR_S1', 'x': 100.0, 'y': 80.0, 'aspect': 'green'},
      {'id': 'MR_S2', 'x': 300.0, 'y': 80.0, 'aspect': 'green'},
      {'id': 'MR_S3', 'x': 500.0, 'y': 80.0, 'aspect': 'green'},
      {'id': 'MR_S4', 'x': 700.0, 'y': 130.0, 'aspect': 'green'},
      {'id': 'MR_S5', 'x': 900.0, 'y': 180.0, 'aspect': 'green'},
      {'id': 'MR_S6', 'x': 1100.0, 'y': 230.0, 'aspect': 'green'},
      {'id': 'MR_S7', 'x': 1100.0, 'y': 320.0, 'aspect': 'green'},
      {'id': 'MR_S8', 'x': 900.0, 'y': 320.0, 'aspect': 'green'},
      {'id': 'MR_S9', 'x': 700.0, 'y': 320.0, 'aspect': 'green'},
      {'id': 'MR_S10', 'x': 500.0, 'y': 270.0, 'aspect': 'green'},
      {'id': 'MR_S11', 'x': 300.0, 'y': 220.0, 'aspect': 'green'},
      {'id': 'MR_S12', 'x': 100.0, 'y': 170.0, 'aspect': 'green'},
    ];
  }

  static List<Map<String, dynamic>> _createMetroRingPoints() {
    return [
      {'id': 'MR_P1', 'x': 150.0, 'y': 100.0, 'position': 'normal'},
      {'id': 'MR_P2', 'x': 450.0, 'y': 100.0, 'position': 'normal'},
      {'id': 'MR_P3', 'x': 750.0, 'y': 175.0, 'position': 'normal'},
      {'id': 'MR_P4', 'x': 950.0, 'y': 250.0, 'position': 'normal'},
      {'id': 'MR_P5', 'x': 950.0, 'y': 300.0, 'position': 'normal'},
      {'id': 'MR_P6', 'x': 650.0, 'y': 275.0, 'position': 'normal'},
      {'id': 'MR_P7', 'x': 350.0, 'y': 225.0, 'position': 'normal'},
      {'id': 'MR_P8', 'x': 150.0, 'y': 175.0, 'position': 'normal'},
    ];
  }

  static List<Map<String, dynamic>> _createMetroRingCrossovers() {
    return [
      {
        'id': 'MR_XO1',
        'name': 'Ring Crossover 1',
        'pointIds': ['MR_P1', 'MR_P2'],
        'blockId': 'MR101',
        'type': 'righthand',
      },
      {
        'id': 'MR_XO2',
        'name': 'Ring Crossover 2',
        'pointIds': ['MR_P5', 'MR_P6'],
        'blockId': 'MR107',
        'type': 'righthand',
      },
    ];
  }

  static List<Map<String, dynamic>> _createMetroRingPlatforms() {
    return [
      {'id': 'MR_PF1', 'name': 'Metro Station 1', 'startX': 250.0, 'endX': 350.0, 'y': 100.0},
      {'id': 'MR_PF2', 'name': 'Metro Station 2', 'startX': 650.0, 'endX': 750.0, 'y': 150.0},
      {'id': 'MR_PF3', 'name': 'Metro Station 3', 'startX': 1050.0, 'endX': 1150.0, 'y': 250.0},
      {'id': 'MR_PF4', 'name': 'Metro Station 4', 'startX': 850.0, 'endX': 950.0, 'y': 300.0},
      {'id': 'MR_PF5', 'name': 'Metro Station 5', 'startX': 450.0, 'endX': 550.0, 'y': 250.0},
      {'id': 'MR_PF6', 'name': 'Metro Station 6', 'startX': 50.0, 'endX': 150.0, 'y': 150.0},
    ];
  }

  static List<Map<String, dynamic>> _createMetroRingTrainStops() {
    return [
      {'id': 'MR_TS1', 'x': 300.0, 'y': 100.0, 'active': true},
      {'id': 'MR_TS2', 'x': 700.0, 'y': 150.0, 'active': true},
      {'id': 'MR_TS3', 'x': 1100.0, 'y': 250.0, 'active': true},
      {'id': 'MR_TS4', 'x': 900.0, 'y': 300.0, 'active': true},
      {'id': 'MR_TS5', 'x': 500.0, 'y': 250.0, 'active': true},
      {'id': 'MR_TS6', 'x': 100.0, 'y': 150.0, 'active': true},
    ];
  }

  static List<Map<String, dynamic>> _createMetroRingBufferStops() {
    return []; // No buffer stops in a ring line
  }

  static List<Map<String, dynamic>> _createMetroRingAxleCounters() {
    return [
      {'id': 'MR_AC1', 'x': 150.0, 'y': 100.0, 'blockId': 'MR100'},
      {'id': 'MR_AC2', 'x': 500.0, 'y': 100.0, 'blockId': 'MR102'},
      {'id': 'MR_AC3', 'x': 850.0, 'y': 175.0, 'blockId': 'MR104'},
      {'id': 'MR_AC4', 'x': 1100.0, 'y': 275.0, 'blockId': 'MR106'},
      {'id': 'MR_AC5', 'x': 750.0, 'y': 300.0, 'blockId': 'MR108'},
      {'id': 'MR_AC6', 'x': 350.0, 'y': 225.0, 'blockId': 'MR110'},
    ];
  }

  static List<Map<String, dynamic>> _createMetroRingTransponders() {
    return [
      {'id': 'MR_T1', 'x': 200.0, 'y': 100.0, 'type': 'CBTC'},
      {'id': 'MR_T2', 'x': 600.0, 'y': 125.0, 'type': 'CBTC'},
      {'id': 'MR_T3', 'x': 1000.0, 'y': 225.0, 'type': 'CBTC'},
      {'id': 'MR_T4', 'x': 1000.0, 'y': 300.0, 'type': 'CBTC'},
      {'id': 'MR_T5', 'x': 600.0, 'y': 275.0, 'type': 'CBTC'},
      {'id': 'MR_T6', 'x': 200.0, 'y': 175.0, 'type': 'CBTC'},
    ];
  }

  // ============================================================================
  // MAINLINE JUNCTION WITH GOODS YARD DATA
  // ============================================================================

  static Map<String, dynamic> _mainlineJunctionData() {
    return {
      'blocks': _createMainlineJunctionBlocks(),
      'signals': _createMainlineJunctionSignals(),
      'points': _createMainlineJunctionPoints(),
      'crossovers': _createMainlineJunctionCrossovers(),
      'platforms': _createMainlineJunctionPlatforms(),
      'trainStops': _createMainlineJunctionTrainStops(),
      'bufferStops': _createMainlineJunctionBufferStops(),
      'axleCounters': _createMainlineJunctionAxleCounters(),
      'transponders': _createMainlineJunctionTransponders(),
    };
  }

  static List<Map<String, dynamic>> _createMainlineJunctionBlocks() {
    return [
      // Main passenger line (y=100)
      {'id': 'ML100', 'startX': -1000.0, 'endX': -600.0, 'y': 100.0, 'name': 'Main West Approach', 'occupied': false},
      {'id': 'ML101', 'startX': -600.0, 'endX': -200.0, 'y': 100.0, 'name': 'Platform 1 Approach', 'occupied': false},
      {'id': 'ML102', 'startX': -200.0, 'endX': 200.0, 'y': 100.0, 'name': 'Platform 1', 'occupied': false},
      {'id': 'ML103', 'startX': 200.0, 'endX': 600.0, 'y': 100.0, 'name': 'Junction East', 'occupied': false},
      {'id': 'ML104', 'startX': 600.0, 'endX': 1000.0, 'y': 100.0, 'name': 'Main East Departure', 'occupied': false},

      // Secondary passenger line (y=200)
      {'id': 'ML200', 'startX': -1000.0, 'endX': -600.0, 'y': 200.0, 'name': 'Secondary West Approach', 'occupied': false},
      {'id': 'ML201', 'startX': -600.0, 'endX': -200.0, 'y': 200.0, 'name': 'Platform 2 Approach', 'occupied': false},
      {'id': 'ML202', 'startX': -200.0, 'endX': 200.0, 'y': 200.0, 'name': 'Platform 2', 'occupied': false},
      {'id': 'ML203', 'startX': 200.0, 'endX': 600.0, 'y': 200.0, 'name': 'Junction Central', 'occupied': false},

      // Goods yard sidings (y=300-400)
      {'id': 'GY300', 'startX': -400.0, 'endX': 0.0, 'y': 300.0, 'name': 'Goods Siding 1', 'occupied': false},
      {'id': 'GY301', 'startX': -400.0, 'endX': 0.0, 'y': 350.0, 'name': 'Goods Siding 2', 'occupied': false},
      {'id': 'GY302', 'startX': -400.0, 'endX': 0.0, 'y': 400.0, 'name': 'Goods Siding 3', 'occupied': false},
      {'id': 'GY303', 'startX': 0.0, 'endX': 400.0, 'y': 350.0, 'name': 'Goods Main', 'occupied': false},

      // Branch line (y=50)
      {'id': 'BR100', 'startX': 600.0, 'endX': 1000.0, 'y': 50.0, 'name': 'Branch Line', 'occupied': false},
      {'id': 'BR101', 'startX': 1000.0, 'endX': 1400.0, 'y': 50.0, 'name': 'Branch Platform', 'occupied': false},
    ];
  }

  static List<Map<String, dynamic>> _createMainlineJunctionSignals() {
    return [
      // Main line signals
      {'id': 'ML_S1', 'x': -900.0, 'y': 80.0, 'aspect': 'green'},
      {'id': 'ML_S2', 'x': -550.0, 'y': 80.0, 'aspect': 'green'},
      {'id': 'ML_S3', 'x': -150.0, 'y': 80.0, 'aspect': 'green'},
      {'id': 'ML_S4', 'x': 250.0, 'y': 80.0, 'aspect': 'green'},
      {'id': 'ML_S5', 'x': 650.0, 'y': 80.0, 'aspect': 'green'},

      // Secondary line signals
      {'id': 'ML_S6', 'x': -900.0, 'y': 180.0, 'aspect': 'green'},
      {'id': 'ML_S7', 'x': -550.0, 'y': 180.0, 'aspect': 'green'},
      {'id': 'ML_S8', 'x': -150.0, 'y': 180.0, 'aspect': 'green'},
      {'id': 'ML_S9', 'x': 250.0, 'y': 180.0, 'aspect': 'green'},

      // Goods yard signals
      {'id': 'GY_S1', 'x': -350.0, 'y': 280.0, 'aspect': 'red'},
      {'id': 'GY_S2', 'x': -350.0, 'y': 330.0, 'aspect': 'red'},
      {'id': 'GY_S3', 'x': -350.0, 'y': 380.0, 'aspect': 'red'},
      {'id': 'GY_S4', 'x': 50.0, 'y': 330.0, 'aspect': 'red'},

      // Branch line signals
      {'id': 'BR_S1', 'x': 700.0, 'y': 30.0, 'aspect': 'green'},
      {'id': 'BR_S2', 'x': 1100.0, 'y': 30.0, 'aspect': 'green'},
    ];
  }

  static List<Map<String, dynamic>> _createMainlineJunctionPoints() {
    return [
      {'id': 'ML_P1', 'x': -500.0, 'y': 100.0, 'position': 'normal'},
      {'id': 'ML_P2', 'x': -300.0, 'y': 200.0, 'position': 'normal'},
      {'id': 'ML_P3', 'x': 300.0, 'y': 100.0, 'position': 'normal'},
      {'id': 'ML_P4', 'x': 450.0, 'y': 150.0, 'position': 'normal'},
      {'id': 'ML_P5', 'x': 700.0, 'y': 75.0, 'position': 'normal'},
      {'id': 'GY_P1', 'x': -350.0, 'y': 250.0, 'position': 'normal'},
      {'id': 'GY_P2', 'x': -250.0, 'y': 300.0, 'position': 'normal'},
      {'id': 'GY_P3', 'x': -150.0, 'y': 350.0, 'position': 'normal'},
    ];
  }

  static List<Map<String, dynamic>> _createMainlineJunctionCrossovers() {
    return [
      {
        'id': 'ML_XO1',
        'name': 'Main Crossover',
        'pointIds': ['ML_P1', 'ML_P2'],
        'blockId': 'ML101',
        'type': 'doubleDiamond',
      },
      {
        'id': 'ML_XO2',
        'name': 'Junction Crossover',
        'pointIds': ['ML_P3', 'ML_P4'],
        'blockId': 'ML103',
        'type': 'righthand',
      },
      {
        'id': 'GY_XO1',
        'name': 'Goods Yard Entry',
        'pointIds': ['GY_P1', 'GY_P2', 'GY_P3'],
        'blockId': 'GY303',
        'type': 'singleSlip',
      },
    ];
  }

  static List<Map<String, dynamic>> _createMainlineJunctionPlatforms() {
    return [
      {'id': 'ML_PF1', 'name': 'Main Platform 1', 'startX': -150.0, 'endX': 150.0, 'y': 100.0},
      {'id': 'ML_PF2', 'name': 'Main Platform 2', 'startX': -150.0, 'endX': 150.0, 'y': 200.0},
      {'id': 'BR_PF1', 'name': 'Branch Platform', 'startX': 1050.0, 'endX': 1350.0, 'y': 50.0},
    ];
  }

  static List<Map<String, dynamic>> _createMainlineJunctionTrainStops() {
    return [
      {'id': 'ML_TS1', 'x': 0.0, 'y': 100.0, 'active': true},
      {'id': 'ML_TS2', 'x': 0.0, 'y': 200.0, 'active': true},
      {'id': 'BR_TS1', 'x': 1200.0, 'y': 50.0, 'active': true},
    ];
  }

  static List<Map<String, dynamic>> _createMainlineJunctionBufferStops() {
    return [
      {'id': 'ML_BS1', 'x': -1000.0, 'y': 100.0},
      {'id': 'ML_BS2', 'x': -1000.0, 'y': 200.0},
      {'id': 'ML_BS3', 'x': 1000.0, 'y': 100.0},
      {'id': 'BR_BS1', 'x': 1400.0, 'y': 50.0},
      {'id': 'GY_BS1', 'x': -400.0, 'y': 300.0},
      {'id': 'GY_BS2', 'x': -400.0, 'y': 350.0},
      {'id': 'GY_BS3', 'x': -400.0, 'y': 400.0},
    ];
  }

  static List<Map<String, dynamic>> _createMainlineJunctionAxleCounters() {
    return [
      {'id': 'ML_AC1', 'x': -800.0, 'y': 100.0, 'blockId': 'ML100'},
      {'id': 'ML_AC2', 'x': -400.0, 'y': 100.0, 'blockId': 'ML101'},
      {'id': 'ML_AC3', 'x': 0.0, 'y': 100.0, 'blockId': 'ML102'},
      {'id': 'ML_AC4', 'x': 400.0, 'y': 100.0, 'blockId': 'ML103'},
      {'id': 'ML_AC5', 'x': -800.0, 'y': 200.0, 'blockId': 'ML200'},
      {'id': 'ML_AC6', 'x': -400.0, 'y': 200.0, 'blockId': 'ML201'},
      {'id': 'ML_AC7', 'x': 0.0, 'y': 200.0, 'blockId': 'ML202'},
      {'id': 'GY_AC1', 'x': -200.0, 'y': 350.0, 'blockId': 'GY303'},
      {'id': 'BR_AC1', 'x': 800.0, 'y': 50.0, 'blockId': 'BR100'},
    ];
  }

  static List<Map<String, dynamic>> _createMainlineJunctionTransponders() {
    return [
      {'id': 'ML_T1', 'x': -700.0, 'y': 100.0, 'type': 'CBTC'},
      {'id': 'ML_T2', 'x': -300.0, 'y': 100.0, 'type': 'CBTC'},
      {'id': 'ML_T3', 'x': -700.0, 'y': 200.0, 'type': 'CBTC'},
      {'id': 'ML_T4', 'x': -300.0, 'y': 200.0, 'type': 'CBTC'},
      {'id': 'BR_T1', 'x': 900.0, 'y': 50.0, 'type': 'CBTC'},
    ];
  }
}
