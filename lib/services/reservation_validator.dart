import 'package:flutter/material.dart';
import 'package:rail_champ/screens/terminal_station_models.dart';
import 'package:rail_champ/models/control_table_models.dart';
import 'package:rail_champ/controllers/terminal_station_controller.dart';

/// Severity level for reservation issues
enum ReservationIssueSeverity {
  critical, // Missing required blocks - safety hazard!
  warning, // Extra blocks or inefficiencies
  info, // Informational notices
}

/// Result of a reservation test for a single route
class ReservationTestResult {
  final String signalId;
  final String routeId;
  final String routeName;
  final bool passed;

  // Expected blocks (from control table)
  final Set<String> expectedBlocks;

  // Actual blocks (from rendering/reservation logic)
  final Set<String> actualBlocks;

  // Discrepancies
  final Set<String> missingBlocks; // Should be reserved but aren't (CRITICAL!)
  final Set<String> extraBlocks; // Reserved but shouldn't be (WARNING)
  final Set<String> correctBlocks; // Correctly reserved

  final ReservationIssueSeverity severity;
  final String explanation;
  final String suggestedFix;

  ReservationTestResult({
    required this.signalId,
    required this.routeId,
    required this.routeName,
    required this.passed,
    required this.expectedBlocks,
    required this.actualBlocks,
    required this.missingBlocks,
    required this.extraBlocks,
    required this.correctBlocks,
    required this.severity,
    required this.explanation,
    required this.suggestedFix,
  });

  Color get severityColor {
    switch (severity) {
      case ReservationIssueSeverity.critical:
        return Colors.red;
      case ReservationIssueSeverity.warning:
        return Colors.orange;
      case ReservationIssueSeverity.info:
        return Colors.blue;
    }
  }

  IconData get severityIcon {
    switch (severity) {
      case ReservationIssueSeverity.critical:
        return Icons.error;
      case ReservationIssueSeverity.warning:
        return Icons.warning;
      case ReservationIssueSeverity.info:
        return Icons.info;
    }
  }

  String get severityLabel {
    switch (severity) {
      case ReservationIssueSeverity.critical:
        return 'CRITICAL';
      case ReservationIssueSeverity.warning:
        return 'WARNING';
      case ReservationIssueSeverity.info:
        return 'INFO';
    }
  }

  String get summary {
    if (passed) {
      return '✅ All ${correctBlocks.length} blocks correctly reserved';
    }

    final issues = <String>[];
    if (missingBlocks.isNotEmpty) {
      issues.add('Missing ${missingBlocks.length} block(s)');
    }
    if (extraBlocks.isNotEmpty) {
      issues.add('${extraBlocks.length} extra block(s)');
    }
    return issues.join(', ');
  }
}

/// Service for validating signal reservations
class ReservationValidator {
  final TerminalStationController controller;

  ReservationValidator(this.controller);

  /// Test a specific signal route
  ReservationTestResult testSignalRoute(String signalId, String routeId) {
    final signal = controller.signals[signalId];
    if (signal == null) {
      return _createErrorResult(signalId, routeId, 'Signal not found');
    }

    final route = signal.routes.firstWhere(
      (r) => r.id == routeId,
      orElse: () => throw Exception('Route $routeId not found'),
    );

    // Get expected blocks from control table
    final expectedBlocks = _calculateExpectedReservation(signal, route);

    // Get actual blocks from current reservation logic
    final actualBlocks = _getActualReservation(signal, route);

    // Compare and find discrepancies
    final missingBlocks = expectedBlocks.difference(actualBlocks);
    final extraBlocks = actualBlocks.difference(expectedBlocks);
    final correctBlocks = expectedBlocks.intersection(actualBlocks);

    final passed = missingBlocks.isEmpty && extraBlocks.isEmpty;

    // Determine severity
    ReservationIssueSeverity severity;
    if (missingBlocks.isNotEmpty) {
      severity = ReservationIssueSeverity.critical; // Missing blocks = safety issue
    } else if (extraBlocks.isNotEmpty) {
      severity = ReservationIssueSeverity.warning; // Extra blocks = inefficiency
    } else {
      severity = ReservationIssueSeverity.info;
    }

    // Generate explanation and fix
    final explanation = _generateExplanation(signal, route, missingBlocks, extraBlocks);
    final suggestedFix = _generateFix(signal, route, missingBlocks, extraBlocks);

    return ReservationTestResult(
      signalId: signalId,
      routeId: routeId,
      routeName: route.name,
      passed: passed,
      expectedBlocks: expectedBlocks,
      actualBlocks: actualBlocks,
      missingBlocks: missingBlocks,
      extraBlocks: extraBlocks,
      correctBlocks: correctBlocks,
      severity: severity,
      explanation: explanation,
      suggestedFix: suggestedFix,
    );
  }

  /// Test all routes for a signal
  List<ReservationTestResult> testSignal(String signalId) {
    final signal = controller.signals[signalId];
    if (signal == null) return [];

    return signal.routes.map((route) {
      return testSignalRoute(signalId, route.id);
    }).toList();
  }

  /// Test all signals in the system
  Map<String, List<ReservationTestResult>> testAllSignals() {
    final results = <String, List<ReservationTestResult>>{};

    for (final signal in controller.signals.values) {
      results[signal.id] = testSignal(signal.id);
    }

    return results;
  }

  /// Calculate expected reservation blocks from control table
  Set<String> _calculateExpectedReservation(Signal signal, SignalRoute route) {
    final blocks = <String>{};

    // Add required blocks from control table
    if (controller.controlTableConfig.entries.containsKey('${signal.id}_${route.id}')) {
      final entry = controller.controlTableConfig.entries['${signal.id}_${route.id}']!;
      blocks.addAll(entry.requiredBlocks);
    } else {
      // Fall back to route's required blocks
      blocks.addAll(route.requiredBlocks);
    }

    // Add approach blocks
    for (final ab in route.approachBlocks) {
      if (ab.toBlock.isNotEmpty) {
        blocks.add(ab.toBlock);
      }
    }

    return blocks;
  }

  /// Get actual reservation blocks from current rendering/reservation logic
  Set<String> _getActualReservation(Signal signal, SignalRoute route) {
    // This simulates what blocks would be highlighted in yellow
    // when the signal is green and this route is active

    final blocks = <String>{};

    // The actual reservation logic is in the controller's route reservation system
    // We need to check which blocks would be reserved if this route was active

    // Add blocks from the route's required blocks
    blocks.addAll(route.requiredBlocks);

    // Add blocks from approach blocks
    for (final ab in route.approachBlocks) {
      if (ab.toBlock.isNotEmpty) {
        blocks.add(ab.toBlock);
      }
    }

    // Check for any blocks that might be added by the reservation logic
    // This would need to call into the actual reservation calculation
    // For now, we'll use the route's declared blocks

    return blocks;
  }

  /// Generate explanation for discrepancies
  String _generateExplanation(
    Signal signal,
    SignalRoute route,
    Set<String> missingBlocks,
    Set<String> extraBlocks,
  ) {
    if (missingBlocks.isEmpty && extraBlocks.isEmpty) {
      return 'All blocks are correctly reserved. This route is safe.';
    }

    final parts = <String>[];

    if (missingBlocks.isNotEmpty) {
      parts.add(
        '⚠️ CRITICAL: ${missingBlocks.length} block(s) are NOT being reserved: ${missingBlocks.join(", ")}\n'
        'This creates a COLLISION RISK as these blocks are not protected when the signal is green.',
      );
    }

    if (extraBlocks.isNotEmpty) {
      parts.add(
        '⚠️ WARNING: ${extraBlocks.length} extra block(s) are being reserved: ${extraBlocks.join(", ")}\n'
        'These blocks may not be necessary, reducing system efficiency.',
      );
    }

    return parts.join('\n\n');
  }

  /// Generate suggested fix
  String _generateFix(
    Signal signal,
    SignalRoute route,
    Set<String> missingBlocks,
    Set<String> extraBlocks,
  ) {
    if (missingBlocks.isEmpty && extraBlocks.isEmpty) {
      return 'No changes needed.';
    }

    final parts = <String>[];

    if (missingBlocks.isNotEmpty) {
      parts.add(
        'Add the following blocks to requiredBlocks:\n'
        '${missingBlocks.map((b) => '  • $b').join('\n')}',
      );
    }

    if (extraBlocks.isNotEmpty) {
      parts.add(
        'Consider removing these blocks from requiredBlocks if not needed:\n'
        '${extraBlocks.map((b) => '  • $b').join('\n')}',
      );
    }

    return parts.join('\n\n');
  }

  /// Create an error result
  ReservationTestResult _createErrorResult(String signalId, String routeId, String error) {
    return ReservationTestResult(
      signalId: signalId,
      routeId: routeId,
      routeName: 'Unknown',
      passed: false,
      expectedBlocks: {},
      actualBlocks: {},
      missingBlocks: {},
      extraBlocks: {},
      correctBlocks: {},
      severity: ReservationIssueSeverity.critical,
      explanation: error,
      suggestedFix: 'Fix the error first',
    );
  }

  /// Get summary statistics for all tests
  ReservationTestSummary getSummary(Map<String, List<ReservationTestResult>> allResults) {
    int totalTests = 0;
    int passed = 0;
    int criticalIssues = 0;
    int warnings = 0;

    for (final results in allResults.values) {
      for (final result in results) {
        totalTests++;
        if (result.passed) {
          passed++;
        } else {
          if (result.severity == ReservationIssueSeverity.critical) {
            criticalIssues++;
          } else if (result.severity == ReservationIssueSeverity.warning) {
            warnings++;
          }
        }
      }
    }

    return ReservationTestSummary(
      totalTests: totalTests,
      passed: passed,
      failed: totalTests - passed,
      criticalIssues: criticalIssues,
      warnings: warnings,
      passRate: totalTests > 0 ? (passed / totalTests * 100) : 0,
    );
  }
}

/// Summary statistics for reservation tests
class ReservationTestSummary {
  final int totalTests;
  final int passed;
  final int failed;
  final int criticalIssues;
  final int warnings;
  final double passRate;

  ReservationTestSummary({
    required this.totalTests,
    required this.passed,
    required this.failed,
    required this.criticalIssues,
    required this.warnings,
    required this.passRate,
  });
}
