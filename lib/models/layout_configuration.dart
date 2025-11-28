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

  /// Get all predefined layouts
  static List<LayoutConfiguration> getAll() {
    return [
      classicTerminal,
      expressThroughStation,
      complexJunction,
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
      {'id': '1A', 'x': -750.0, 'y': 80.0, 'aspect': 'green'},
      {'id': '1B', 'x': -350.0, 'y': 80.0, 'aspect': 'yellow'},
      {'id': '1C', 'x': 50.0, 'y': 80.0, 'aspect': 'green'},
      {'id': '2A', 'x': -750.0, 'y': 320.0, 'aspect': 'green'},
      {'id': '2B', 'x': -350.0, 'y': 320.0, 'aspect': 'yellow'},
      {'id': '2C', 'x': 50.0, 'y': 320.0, 'aspect': 'green'},
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
      {'id': 'ES1', 'x': -900.0, 'y': 30.0, 'aspect': 'green'},
      {'id': 'ES2', 'x': -400.0, 'y': 30.0, 'aspect': 'green'},
      {'id': 'LS1', 'x': -900.0, 'y': 130.0, 'aspect': 'green'},
      {'id': 'LS2', 'x': -400.0, 'y': 130.0, 'aspect': 'yellow'},
      {'id': 'RS1', 'x': -900.0, 'y': 270.0, 'aspect': 'green'},
      {'id': 'RS2', 'x': -400.0, 'y': 270.0, 'aspect': 'green'},
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
      {'id': 'JN1', 'x': -700.0, 'y': 30.0, 'aspect': 'green'},
      {'id': 'JN2', 'x': -100.0, 'y': 30.0, 'aspect': 'yellow'},
      {'id': 'JS1', 'x': -700.0, 'y': 370.0, 'aspect': 'green'},
      {'id': 'JS2', 'x': -100.0, 'y': 370.0, 'aspect': 'yellow'},
      {'id': 'JW1', 'x': -700.0, 'y': 180.0, 'aspect': 'green'},
      {'id': 'JE1', 'x': 500.0, 'y': 180.0, 'aspect': 'green'},
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
}
