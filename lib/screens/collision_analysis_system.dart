// MA1 v3.0 - Collision Analysis & Forensic System
import 'dart:math';

// ============================================================================
// COLLISION SEVERITY LEVELS
// ============================================================================
enum CollisionSeverity {
  nearMiss,      // Distance < 80 units
  minor,         // Low speed collision
  major,         // High speed collision
  catastrophic   // Multiple trains or critical location
}

// ============================================================================
// ROOT CAUSE CATEGORIES
// ============================================================================
enum CollisionCause {
  operatorError,           // Human error in manual mode
  signalFailure,          // Signal showed wrong aspect
  pointMisalignment,      // Points in wrong position
  signalPassedAtDanger,   // Train passed red signal (SPAD)
  manualModeError,        // Manual control misused
  speedExceeded,          // Train traveling too fast
  blockOccupiedIgnored,   // Entered occupied block
  routeNotSet,            // No route set for movement
  simultaneousMovement,   // Conflicting routes active
  systemFailure,          // Software/hardware issue
  bufferStopCollision,    // Hit buffer stops
}

// ============================================================================
// RESPONSIBILITY ASSIGNMENT
// ============================================================================
enum Responsibility {
  trainDriver,        // Driver action/inaction
  signaller,         // Route setting error
  systemController,  // Interlocking failure
  maintenance,       // Equipment failure
  externalFactors,   // Weather, vandalism, etc
  underInvestigation // Not yet determined
}

// ============================================================================
// PRE-COLLISION EVENT TRACKING
// ============================================================================
class PreCollisionEvent {
  final DateTime timestamp;
  final String trainId;
  final String description;
  final String location;
  final double trainSpeed;
  final Map<String, dynamic> systemState;

  PreCollisionEvent({
    required this.timestamp,
    required this.trainId,
    required this.description,
    required this.location,
    required this.trainSpeed,
    required this.systemState,
  });
}

// ============================================================================
// COLLISION INCIDENT DATA
// ============================================================================
class CollisionIncident {
  final String id;
  final DateTime timestamp;
  final List<String> trainsInvolved;
  final String location;
  final CollisionSeverity severity;
  final List<CollisionCause> rootCauses;
  final Responsibility responsibility;
  final String specificParty;
  final List<PreCollisionEvent> leadingEvents;
  final Map<String, dynamic> systemStateAtCollision;
  final List<String> preventionRecommendations;
  final String forensicSummary;

  CollisionIncident({
    required this.id,
    required this.timestamp,
    required this.trainsInvolved,
    required this.location,
    required this.severity,
    required this.rootCauses,
    required this.responsibility,
    required this.specificParty,
    required this.leadingEvents,
    required this.systemStateAtCollision,
    required this.preventionRecommendations,
    required this.forensicSummary,
  });
}

// ============================================================================
// COLLISION ANALYSIS SYSTEM
// ============================================================================
class CollisionAnalysisSystem {
  final List<PreCollisionEvent> _eventHistory = [];
  final List<CollisionIncident> _incidentHistory = [];
  static const int _eventHistoryDuration = 60; // seconds

  List<CollisionIncident> get incidentHistory => List.unmodifiable(_incidentHistory);

  // Track events for forensic analysis
  void trackEvent({
    required String trainId,
    required String description,
    required String location,
    required double trainSpeed,
    required Map<String, dynamic> systemState,
  }) {
    final event = PreCollisionEvent(
      timestamp: DateTime.now(),
      trainId: trainId,
      description: description,
      location: location,
      trainSpeed: trainSpeed,
      systemState: Map.from(systemState),
    );

    _eventHistory.add(event);

    // Keep only last 60 seconds of events
    final cutoffTime = DateTime.now().subtract(
      Duration(seconds: _eventHistoryDuration),
    );
    _eventHistory.removeWhere((e) => e.timestamp.isBefore(cutoffTime));
  }

  // Analyze collision and generate forensic report
  CollisionIncident analyzeCollision({
    required List<String> trainsInvolved,
    required String location,
    required Map<String, dynamic> currentSystemState,
  }) {
    final incidentId = 'INC-${DateTime.now().millisecondsSinceEpoch}';
    final timestamp = DateTime.now();

    // Determine severity
    final severity = _determineSeverity(trainsInvolved, currentSystemState);

    // Get leading events (last 60 seconds)
    final leadingEvents = _getLeadingEvents(trainsInvolved);

    // Root cause analysis
    final rootCauses = _analyzeRootCauses(
      trainsInvolved,
      location,
      currentSystemState,
      leadingEvents,
    );

    // Assign responsibility
    final responsibilityInfo = _assignResponsibility(rootCauses, leadingEvents);

    // Generate prevention recommendations
    final recommendations = _generateRecommendations(rootCauses, severity);

    // Create forensic summary
    final forensicSummary = _createForensicSummary(
      trainsInvolved,
      location,
      severity,
      rootCauses,
      leadingEvents,
    );

    final incident = CollisionIncident(
      id: incidentId,
      timestamp: timestamp,
      trainsInvolved: trainsInvolved,
      location: location,
      severity: severity,
      rootCauses: rootCauses,
      responsibility: responsibilityInfo['type'] as Responsibility,
      specificParty: responsibilityInfo['party'] as String,
      leadingEvents: leadingEvents,
      systemStateAtCollision: Map.from(currentSystemState),
      preventionRecommendations: recommendations,
      forensicSummary: forensicSummary,
    );

    _incidentHistory.add(incident);
    return incident;
  }

  // Determine collision severity
  CollisionSeverity _determineSeverity(
    List<String> trains,
    Map<String, dynamic> systemState,
  ) {
    if (trains.length > 2) return CollisionSeverity.catastrophic;

    // Check if buffer stop collision
    final isBufferCollision = systemState['isBufferCollision'] == true;
    if (isBufferCollision) return CollisionSeverity.major;

    // Check if near buffer stops (critical location)
    final location = systemState['location'] as String? ?? '';
    if (location.contains('buffer') || location.contains('111')) {
      return CollisionSeverity.major;
    }

    // Check speeds
    final speeds = trains.map((t) {
      return (systemState['trains'] as Map<String, dynamic>?)?[t]?['speed'] as double? ?? 0.0;
    }).toList();

    final maxSpeed = speeds.isEmpty ? 0.0 : speeds.reduce(max);

    if (maxSpeed > 5.0) return CollisionSeverity.catastrophic;
    if (maxSpeed > 3.0) return CollisionSeverity.major;
    if (maxSpeed > 1.0) return CollisionSeverity.minor;
    
    return CollisionSeverity.nearMiss;
  }

  // Get relevant leading events
  List<PreCollisionEvent> _getLeadingEvents(List<String> trainsInvolved) {
    return _eventHistory
        .where((e) => trainsInvolved.contains(e.trainId))
        .toList();
  }

  // Analyze root causes
  List<CollisionCause> _analyzeRootCauses(
    List<String> trains,
    String location,
    Map<String, dynamic> systemState,
    List<PreCollisionEvent> events,
  ) {
    final causes = <CollisionCause>[];

    // Check for buffer stop collision
    if (systemState['isBufferCollision'] == true) {
      causes.add(CollisionCause.bufferStopCollision);
      causes.add(CollisionCause.manualModeError); // Only manual trains hit buffer
    }

    // Check for manual mode errors
    final hasManualTrain = events.any((e) => 
      e.description.contains('manual') || 
      e.systemState['manualMode'] == true
    );
    if (hasManualTrain && !causes.contains(CollisionCause.manualModeError)) {
      causes.add(CollisionCause.manualModeError);
    }

    // Check for SPAD (Signal Passed At Danger)
    final hasSPAD = events.any((e) => 
      e.description.contains('red signal') || 
      e.description.contains('SPAD')
    );
    if (hasSPAD) {
      causes.add(CollisionCause.signalPassedAtDanger);
    }

    // Check for point misalignment
    final hasPointIssue = events.any((e) => 
      e.description.contains('point') || 
      e.description.contains('switch')
    );
    if (hasPointIssue) {
      causes.add(CollisionCause.pointMisalignment);
    }

    // Check for occupied block entry
    final hasBlockIssue = events.any((e) => 
      e.description.contains('occupied') || 
      e.description.contains('block')
    );
    if (hasBlockIssue) {
      causes.add(CollisionCause.blockOccupiedIgnored);
    }

    // Check for excessive speed
    final hasSpeedIssue = events.any((e) => e.trainSpeed > 4.0);
    if (hasSpeedIssue) {
      causes.add(CollisionCause.speedExceeded);
    }

    // Check for route setting issues
    final hasRouteIssue = events.any((e) => 
      e.description.contains('route') || 
      e.systemState['routeSet'] == false
    );
    if (hasRouteIssue) {
      causes.add(CollisionCause.routeNotSet);
    }

    // Check for signal failure
    final hasSignalFailure = events.any((e) => 
      e.description.contains('signal failure') || 
      e.description.contains('signal error')
    );
    if (hasSignalFailure) {
      causes.add(CollisionCause.signalFailure);
    }

    // Check for simultaneous movement
    if (trains.length > 1) {
      final movingTrains = events
          .where((e) => e.trainSpeed > 0.1)
          .map((e) => e.trainId)
          .toSet();
      if (movingTrains.length > 1) {
        causes.add(CollisionCause.simultaneousMovement);
      }
    }

    // Default if no specific cause found
    if (causes.isEmpty) {
      causes.add(CollisionCause.operatorError);
    }

    return causes;
  }

  // Assign responsibility
  Map<String, dynamic> _assignResponsibility(
    List<CollisionCause> causes,
    List<PreCollisionEvent> events,
  ) {
    // Buffer collision → Train driver
    if (causes.contains(CollisionCause.bufferStopCollision)) {
      final trainId = events.isNotEmpty ? events.last.trainId : 'Unknown';
      return {
        'type': Responsibility.trainDriver,
        'party': 'Driver of train $trainId (manual mode)',
      };
    }

    // Manual mode errors → Train driver
    if (causes.contains(CollisionCause.manualModeError) ||
        causes.contains(CollisionCause.speedExceeded) ||
        causes.contains(CollisionCause.signalPassedAtDanger)) {
      final trainId = events.isNotEmpty ? events.last.trainId : 'Unknown';
      return {
        'type': Responsibility.trainDriver,
        'party': 'Driver of train $trainId',
      };
    }

    // Route/signal issues → Signaller
    if (causes.contains(CollisionCause.routeNotSet) ||
        causes.contains(CollisionCause.simultaneousMovement)) {
      return {
        'type': Responsibility.signaller,
        'party': 'Signaller/Controller',
      };
    }

    // Point issues → Maintenance
    if (causes.contains(CollisionCause.pointMisalignment)) {
      return {
        'type': Responsibility.maintenance,
        'party': 'Point maintenance crew',
      };
    }

    // Signal failure → System controller
    if (causes.contains(CollisionCause.signalFailure)) {
      return {
        'type': Responsibility.systemController,
        'party': 'Signalling system',
      };
    }

    // Default
    return {
      'type': Responsibility.underInvestigation,
      'party': 'Under investigation',
    };
  }

  // Generate prevention recommendations
  List<String> _generateRecommendations(
    List<CollisionCause> causes,
    CollisionSeverity severity,
  ) {
    final recommendations = <String>[];

    if (causes.contains(CollisionCause.bufferStopCollision)) {
      recommendations.add('Install buffer stop warning system');
      recommendations.add('Implement automatic braking near buffer stops');
      recommendations.add('Review manual mode operating procedures');
    }

    if (causes.contains(CollisionCause.manualModeError)) {
      recommendations.add('Implement additional manual mode safeguards');
      recommendations.add('Provide driver training on manual operations');
      recommendations.add('Consider restricting manual mode to qualified operators');
    }

    if (causes.contains(CollisionCause.signalPassedAtDanger)) {
      recommendations.add('Install Automatic Train Protection (ATP) system');
      recommendations.add('Review driver attention monitoring');
    }

    if (causes.contains(CollisionCause.speedExceeded)) {
      recommendations.add('Implement automatic speed enforcement');
      recommendations.add('Add speed warning systems');
    }

    if (causes.contains(CollisionCause.pointMisalignment)) {
      recommendations.add('Increase point inspection frequency');
      recommendations.add('Install point position indicators');
    }

    if (causes.contains(CollisionCause.routeNotSet)) {
      recommendations.add('Enhance route visualization for operators');
      recommendations.add('Add pre-movement checklist');
    }

    if (causes.contains(CollisionCause.simultaneousMovement)) {
      recommendations.add('Review interlocking logic');
      recommendations.add('Implement conflict detection alarms');
    }

    if (severity == CollisionSeverity.catastrophic ||
        severity == CollisionSeverity.major) {
      recommendations.add('Conduct full safety review');
      recommendations.add('Suspend operations pending investigation');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Conduct thorough incident investigation');
      recommendations.add('Review all safety procedures');
    }

    return recommendations;
  }

  // Create forensic summary
  String _createForensicSummary(
    List<String> trains,
    String location,
    CollisionSeverity severity,
    List<CollisionCause> causes,
    List<PreCollisionEvent> events,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('FORENSIC ANALYSIS REPORT');
    buffer.writeln('=' * 50);
    buffer.writeln();
    buffer.writeln('INCIDENT OVERVIEW:');
    buffer.writeln('Trains involved: ${trains.join(", ")}');
    buffer.writeln('Location: $location');
    buffer.writeln('Severity: ${severity.name.toUpperCase()}');
    buffer.writeln();
    buffer.writeln('ROOT CAUSES IDENTIFIED:');
    for (var cause in causes) {
      buffer.writeln('• ${_formatCauseName(cause)}');
    }
    buffer.writeln();
    buffer.writeln('TIMELINE (Last 60 seconds):');
    for (var i = 0; i < events.length && i < 10; i++) {
      final event = events[events.length - 1 - i];
      final secondsAgo = DateTime.now().difference(event.timestamp).inSeconds;
      buffer.writeln('T-${secondsAgo}s: ${event.trainId} - ${event.description}');
    }
    buffer.writeln();
    buffer.writeln('=' * 50);

    return buffer.toString();
  }

  String _formatCauseName(CollisionCause cause) {
    switch (cause) {
      case CollisionCause.operatorError:
        return 'Operator Error';
      case CollisionCause.signalFailure:
        return 'Signal System Failure';
      case CollisionCause.pointMisalignment:
        return 'Point Misalignment';
      case CollisionCause.signalPassedAtDanger:
        return 'Signal Passed At Danger (SPAD)';
      case CollisionCause.manualModeError:
        return 'Manual Mode Operational Error';
      case CollisionCause.speedExceeded:
        return 'Speed Limit Exceeded';
      case CollisionCause.blockOccupiedIgnored:
        return 'Block Occupation Ignored';
      case CollisionCause.routeNotSet:
        return 'Route Not Properly Set';
      case CollisionCause.simultaneousMovement:
        return 'Simultaneous Conflicting Movement';
      case CollisionCause.systemFailure:
        return 'System/Equipment Failure';
      case CollisionCause.bufferStopCollision:
        return 'Buffer Stop Collision';
    }
  }

  // Get recent incidents (last N)
  List<CollisionIncident> getRecentIncidents({int count = 10}) {
    return _incidentHistory.reversed.take(count).toList();
  }

  /// Export collision report as formatted text
  String exportCollisionReport({
    int? incidentCount,
    bool includeTimeline = true,
    bool includeRecommendations = true,
  }) {
    final buffer = StringBuffer();
    final incidents = incidentCount != null
        ? getRecentIncidents(count: incidentCount)
        : _incidentHistory;

    // Header
    buffer.writeln('=' * 80);
    buffer.writeln('RAILWAY COLLISION ANALYSIS REPORT');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total Incidents: ${incidents.length}');
    buffer.writeln('=' * 80);
    buffer.writeln();

    if (incidents.isEmpty) {
      buffer.writeln('✅ No collision incidents recorded.');
      buffer.writeln();
      return buffer.toString();
    }

    // Statistics
    buffer.writeln('SUMMARY STATISTICS');
    buffer.writeln('-' * 80);
    final severityCounts = <CollisionSeverity, int>{};
    final causeCounts = <CollisionCause, int>{};

    for (var incident in incidents) {
      severityCounts[incident.severity] = (severityCounts[incident.severity] ?? 0) + 1;
      for (var cause in incident.rootCauses) {
        causeCounts[cause] = (causeCounts[cause] ?? 0) + 1;
      }
    }

    buffer.writeln('By Severity:');
    for (var entry in severityCounts.entries) {
      buffer.writeln('  ${_formatSeverityName(entry.key)}: ${entry.value}');
    }

    buffer.writeln('\nTop Root Causes:');
    final sortedCauses = causeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (var entry in sortedCauses.take(5)) {
      buffer.writeln('  ${_formatCauseName(entry.key)}: ${entry.value} incidents');
    }
    buffer.writeln();

    // Detailed incidents
    buffer.writeln('=' * 80);
    buffer.writeln('DETAILED INCIDENT REPORTS');
    buffer.writeln('=' * 80);
    buffer.writeln();

    for (var i = 0; i < incidents.length; i++) {
      final incident = incidents[i];
      buffer.writeln('INCIDENT #${i + 1}: ${incident.id}');
      buffer.writeln('-' * 80);
      buffer.writeln('Timestamp: ${incident.timestamp}');
      buffer.writeln('Location: ${incident.location}');
      buffer.writeln('Trains Involved: ${incident.trainsInvolved.join(", ")}');
      buffer.writeln('Severity: ${_formatSeverityName(incident.severity)}');
      buffer.writeln('Responsibility: ${_formatResponsibilityName(incident.responsibility)} - ${incident.specificParty}');
      buffer.writeln();

      buffer.writeln('Root Causes:');
      for (var cause in incident.rootCauses) {
        buffer.writeln('  • ${_formatCauseName(cause)}');
      }
      buffer.writeln();

      if (includeTimeline && incident.leadingEvents.isNotEmpty) {
        buffer.writeln('Timeline (Leading Events):');
        for (var event in incident.leadingEvents.take(10)) {
          final secondsAgo = incident.timestamp.difference(event.timestamp).inSeconds;
          buffer.writeln('  T-${secondsAgo}s: ${event.trainId} @ ${event.location}');
          buffer.writeln('          ${event.description} (${event.trainSpeed.toStringAsFixed(1)} m/s)');
        }
        buffer.writeln();
      }

      buffer.writeln('Forensic Summary:');
      buffer.writeln(incident.forensicSummary);
      buffer.writeln();

      if (includeRecommendations) {
        buffer.writeln('Prevention Recommendations:');
        for (var rec in incident.preventionRecommendations) {
          buffer.writeln('  • $rec');
        }
        buffer.writeln();
      }

      buffer.writeln('=' * 80);
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Export collision report as CSV format
  String exportCollisionReportCSV() {
    final buffer = StringBuffer();

    // CSV Header
    buffer.writeln('Incident ID,Timestamp,Location,Trains Involved,Severity,Root Causes,Responsibility,Specific Party');

    for (var incident in _incidentHistory) {
      final trainsStr = incident.trainsInvolved.join(';');
      final causesStr = incident.rootCauses.map((c) => _formatCauseName(c)).join(';');

      buffer.writeln([
        incident.id,
        incident.timestamp.toIso8601String(),
        incident.location,
        trainsStr,
        _formatSeverityName(incident.severity),
        causesStr,
        _formatResponsibilityName(incident.responsibility),
        incident.specificParty,
      ].map((s) => '"$s"').join(','));
    }

    return buffer.toString();
  }

  /// Export collision report as JSON format
  String exportCollisionReportJSON() {
    final incidents = _incidentHistory.map((incident) => {
      'id': incident.id,
      'timestamp': incident.timestamp.toIso8601String(),
      'location': incident.location,
      'trainsInvolved': incident.trainsInvolved,
      'severity': _formatSeverityName(incident.severity),
      'rootCauses': incident.rootCauses.map((c) => _formatCauseName(c)).toList(),
      'responsibility': _formatResponsibilityName(incident.responsibility),
      'specificParty': incident.specificParty,
      'leadingEvents': incident.leadingEvents.map((e) => {
        'timestamp': e.timestamp.toIso8601String(),
        'trainId': e.trainId,
        'description': e.description,
        'location': e.location,
        'trainSpeed': e.trainSpeed,
      }).toList(),
      'preventionRecommendations': incident.preventionRecommendations,
      'forensicSummary': incident.forensicSummary,
    }).toList();

    // Simple JSON serialization
    return _jsonEncode(incidents);
  }

  /// Simple JSON encoder (without dart:convert dependency)
  String _jsonEncode(List<Map<String, dynamic>> data) {
    final buffer = StringBuffer();
    buffer.write('[');
    for (var i = 0; i < data.length; i++) {
      if (i > 0) buffer.write(',');
      buffer.write(_jsonEncodeMap(data[i]));
    }
    buffer.write(']');
    return buffer.toString();
  }

  String _jsonEncodeMap(Map<String, dynamic> map) {
    final buffer = StringBuffer();
    buffer.write('{');
    var first = true;
    map.forEach((key, value) {
      if (!first) buffer.write(',');
      first = false;
      buffer.write('"$key":');
      if (value is String) {
        buffer.write('"${value.replaceAll('"', '\\"')}"');
      } else if (value is List) {
        buffer.write('[');
        for (var i = 0; i < value.length; i++) {
          if (i > 0) buffer.write(',');
          if (value[i] is String) {
            buffer.write('"${value[i].replaceAll('"', '\\"')}"');
          } else if (value[i] is Map) {
            buffer.write(_jsonEncodeMap(value[i] as Map<String, dynamic>));
          } else {
            buffer.write(value[i].toString());
          }
        }
        buffer.write(']');
      } else {
        buffer.write(value.toString());
      }
    });
    buffer.write('}');
    return buffer.toString();
  }

  String _formatSeverityName(CollisionSeverity severity) {
    switch (severity) {
      case CollisionSeverity.nearMiss:
        return 'Near Miss';
      case CollisionSeverity.minor:
        return 'Minor';
      case CollisionSeverity.major:
        return 'Major';
      case CollisionSeverity.catastrophic:
        return 'Catastrophic';
    }
  }

  String _formatResponsibilityName(Responsibility resp) {
    switch (resp) {
      case Responsibility.trainDriver:
        return 'Train Driver';
      case Responsibility.signaller:
        return 'Signaller';
      case Responsibility.systemController:
        return 'System Controller';
      case Responsibility.maintenance:
        return 'Maintenance';
      case Responsibility.externalFactors:
        return 'External Factors';
      case Responsibility.underInvestigation:
        return 'Under Investigation';
    }
  }

  // Clear history
  void clearHistory() {
    _eventHistory.clear();
    _incidentHistory.clear();
  }
}
