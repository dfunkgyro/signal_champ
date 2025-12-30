import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rail_champ/controllers/terminal_station_controller.dart';
import '../models/control_table_models.dart';
import '../models/direction_models.dart';
import '../screens/terminal_station_models.dart';

/// Specialized AI service for Control Table analysis and suggestions
/// Uses OpenAI to provide expert signalling advice and automated control table generation
class ControlTableAIService {
  final String _apiKey;
  final String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  final String _model;

  ControlTableAIService({
    required String apiKey,
    String model = 'gpt-4-turbo-preview',
  })  : _apiKey = apiKey,
        _model = model;

  /// Analyze the current railway layout and control table configuration
  /// Provides comprehensive analysis with safety checks and optimization suggestions
  Future<ControlTableAnalysis> analyzeControlTable({
    required Map<String, Signal> signals,
    required Map<String, Point> points,
    required Map<String, BlockSection> blocks,
    required Map<String, AxleCounter> axleCounters,
    required ExtendedControlTableConfiguration controlTableConfig,
  }) async {
    final context = _buildContextString(
      signals: signals,
      points: points,
      blocks: blocks,
      axleCounters: axleCounters,
      controlTableConfig: controlTableConfig,
    );

    final systemPrompt = _buildAnalysisSystemPrompt();

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': 'Analyze this railway control table configuration:\n\n$context'},
          ],
          'temperature': 0.3, // Lower temperature for more consistent technical analysis
          'max_tokens': 4000,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final content = jsonResponse['choices'][0]['message']['content'] as String;
        return _parseAnalysisResponse(content);
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      return ControlTableAnalysis(
        success: false,
        errorMessage: 'Analysis failed: $e',
        suggestions: [],
        conflicts: [],
        summary: 'Unable to complete analysis',
      );
    }
  }

  /// Process user chat messages and return AI responses
  Future<ChatResponse> processChatMessage({
    required String userMessage,
    required List<ChatMessage> conversationHistory,
    required Map<String, Signal> signals,
    required Map<String, Point> points,
    required Map<String, BlockSection> blocks,
    required Map<String, AxleCounter> axleCounters,
    required ExtendedControlTableConfiguration controlTableConfig,
  }) async {
    final context = _buildContextString(
      signals: signals,
      points: points,
      blocks: blocks,
      axleCounters: axleCounters,
      controlTableConfig: controlTableConfig,
    );

    final systemPrompt = _buildChatSystemPrompt(context);

    // Build conversation history
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      ...conversationHistory.map((msg) => {
            'role': msg.isUser ? 'user' : 'assistant',
            'content': msg.content,
          }),
      {'role': 'user', 'content': userMessage},
    ];

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'temperature': 0.5,
          'max_tokens': 2000,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final content = jsonResponse['choices'][0]['message']['content'] as String;

        return ChatResponse(
          success: true,
          message: content,
          suggestions: _extractSuggestionsFromChat(content),
        );
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      return ChatResponse(
        success: false,
        message: 'Sorry, I encountered an error: $e',
        suggestions: [],
      );
    }
  }

  /// Generate AB (Approach Block) suggestions based on signal and axle counter placement
  Future<List<ABSuggestion>> suggestABConfigurations({
    required Map<String, Signal> signals,
    required Map<String, AxleCounter> axleCounters,
    required Map<String, BlockSection> blocks,
  }) async {
    final context = '''
SIGNALS:
${signals.entries.map((e) => '- ${e.key}: ${e.value.direction.name} at position (${e.value.position.dx.toStringAsFixed(1)}, ${e.value.position.dy.toStringAsFixed(1)})').join('\n')}

AXLE COUNTERS:
${axleCounters.entries.map((e) => '- ${e.key}: count=${e.value.count} at position (${e.value.position.dx.toStringAsFixed(1)}, ${e.value.position.dy.toStringAsFixed(1)})').join('\n')}

BLOCKS:
${blocks.entries.map((e) => '- ${e.key}: ${e.value.occupied ? "OCCUPIED" : "CLEAR"}').join('\n')}
''';

    final systemPrompt = '''
You are a railway signalling expert specializing in Approach Block (AB) configuration.

Approach Blocks use two axle counters to detect train presence between them. They are essential for:
1. Signal approach locking - preventing signal clearing when train detected approaching
2. Route interlocking - ensuring routes are held while trains are in approach
3. Safety critical operations

Analyze the provided railway layout and suggest optimal AB configurations.

For each suggestion, provide:
1. A descriptive name (e.g., "Signal S01 Approach", "Platform 1 Entry")
2. The two axle counters that should form the AB (must be sequential/adjacent)
3. The purpose/reason for this AB configuration
4. Which signals would benefit from this AB

Respond in JSON format:
{
  "suggestions": [
    {
      "name": "AB name",
      "axleCounter1": "AC_ID1",
      "axleCounter2": "AC_ID2",
      "purpose": "description",
      "relatedSignals": ["S01", "S02"]
    }
  ]
}
''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': context},
          ],
          'temperature': 0.3,
          'max_tokens': 2000,
        }),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final content = jsonResponse['choices'][0]['message']['content'] as String;
        return _parseABSuggestions(content);
      }
    } catch (e) {
      print('Error generating AB suggestions: $e');
    }

    return [];
  }

  /// Analyze signal reservations and identify configuration issues
  /// This is critical for safety - ensures yellow reservations are correct
  Future<List<ReservationAnalysisResult>> analyzeReservations({
    required Map<String, Signal> signals,
    required Map<String, BlockSection> blocks,
    required ExtendedControlTableConfiguration controlTableConfig,
  }) async {
    final context = _buildReservationContext(signals, blocks, controlTableConfig);

    final systemPrompt = '''
You are a railway signalling safety expert specializing in route reservation validation.

CRITICAL SAFETY CONCEPT - Yellow Reservations:
When a signal shows GREEN, it must reserve (protect) specific track blocks with YELLOW highlighting.
These yellow reservations prevent conflicting routes and ensure train safety.

SAFETY RULES FOR RESERVATIONS:
1. MUST reserve ALL blocks in the train's path
2. MUST reserve flank protection blocks (prevent side collisions)
3. MUST reserve point protection blocks (prevent point movement under train)
4. MISSING reservations = CRITICAL SAFETY HAZARD (collision risk!)
5. Extra reservations = Warning (inefficiency, not safety issue)

ANALYZE EACH SIGNAL ROUTE:
For each signal and route, check if the requiredBlocks list includes:
- All blocks the train will physically traverse
- Flank protection blocks adjacent to points
- Approach blocks for safety margins

Respond in JSON format with issues found:
{
  "issues": [
    {
      "signalId": "S02",
      "routeId": "route_1",
      "severity": "CRITICAL" | "WARNING" | "INFO",
      "issueType": "missing_block" | "extra_block" | "flank_protection" | "point_protection",
      "blockId": "BLK_104",
      "explanation": "Block 104 must be reserved for flank protection of point 78A",
      "suggestedFix": "Add 'BLK_104' to requiredBlocks array",
      "safetyImpact": "Without this reservation, point 78A could move while train approaching, causing derailment"
    }
  ]
}

Focus on CRITICAL issues (missing blocks) first, then warnings (extra blocks).
''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': 'Analyze these signal reservations for safety:\n\n$context'},
          ],
          'temperature': 0.2, // Low temperature for safety-critical analysis
          'max_tokens': 3000,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final content = jsonResponse['choices'][0]['message']['content'] as String;
        return _parseReservationAnalysis(content);
      }
    } catch (e) {
      print('Error analyzing reservations: $e');
    }

    return [];
  }

  String _buildReservationContext(
    Map<String, Signal> signals,
    Map<String, BlockSection> blocks,
    ExtendedControlTableConfiguration controlTableConfig,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('=== SIGNAL ROUTE RESERVATIONS ===\n');

    for (var signal in signals.values) {
      buffer.writeln('Signal ${signal.id} (${signal.direction.name}):');

      for (var route in signal.routes) {
        final entryKey = '${signal.id}_${route.id}';
        final controlEntry = controlTableConfig.entries[entryKey];

        buffer.writeln('  Route: ${route.name} (ID: ${route.id})');
        buffer.writeln(
            '    Required Blocks (from route): ${route.requiredBlocksClear.join(", ")}');

        if (controlEntry != null) {
          buffer.writeln(
              '    Required Blocks (from control table): ${controlEntry.requiredBlocksClear.join(", ")}');
          if (controlEntry.approachBlocks.isNotEmpty) {
            buffer.writeln(
                '    Approach Blocks: ${controlEntry.approachBlocks.join(", ")}');
          }
        }

        if (route.requiredPointPositions.isNotEmpty) {
          buffer.writeln('    Required Point Positions:');
          route.requiredPointPositions.forEach((pointId, position) {
            buffer.writeln('      - $pointId: ${position.name}');
          });
        }

        buffer.writeln();
      }
    }

    buffer.writeln('\n=== AVAILABLE BLOCKS ===');
    for (var block in blocks.values) {
      buffer.writeln('- ${block.id}: ${block.occupied ? "OCCUPIED" : "CLEAR"}');
    }

    return buffer.toString();
  }

  List<ReservationAnalysisResult> _parseReservationAnalysis(String content) {
    try {
      // Remove markdown code blocks if present
      String jsonContent = content.trim();
      if (jsonContent.startsWith('```json')) {
        jsonContent = jsonContent.substring(7);
      }
      if (jsonContent.startsWith('```')) {
        jsonContent = jsonContent.substring(3);
      }
      if (jsonContent.endsWith('```')) {
        jsonContent = jsonContent.substring(0, jsonContent.length - 3);
      }

      final parsed = jsonDecode(jsonContent.trim());
      final issues = parsed['issues'] as List? ?? [];

      return issues.map((issue) {
        return ReservationAnalysisResult(
          signalId: issue['signalId'] ?? '',
          routeId: issue['routeId'] ?? '',
          severity: issue['severity'] ?? 'WARNING',
          issueType: issue['issueType'] ?? 'unknown',
          blockId: issue['blockId'] ?? '',
          explanation: issue['explanation'] ?? '',
          suggestedFix: issue['suggestedFix'] ?? '',
          safetyImpact: issue['safetyImpact'] ?? '',
        );
      }).toList();
    } catch (e) {
      print('Error parsing reservation analysis: $e');
      print('Content: $content');
      return [];
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  String _buildContextString({
    required Map<String, Signal> signals,
    required Map<String, Point> points,
    required Map<String, BlockSection> blocks,
    required Map<String, AxleCounter> axleCounters,
    required ExtendedControlTableConfiguration controlTableConfig,
  }) {
    final buffer = StringBuffer();

    // Signals and Routes
    buffer.writeln('=== SIGNALS AND ROUTES ===');
    for (var signal in signals.values) {
      final gd = signal.direction.guidewayDirection.abbreviation;
      final cardinalDir = signal.direction.name.toUpperCase();
      final junctionInfo = signal.isAtJunction
          ? ' [Junction: ${signal.junctionId}, Position: ${signal.junctionPosition.abbreviation}]'
          : '';
      buffer.writeln('Signal ${signal.id} (Direction: $cardinalDir, $gd)$junctionInfo:');

      for (var route in signal.routes) {
        final entryKey = '${signal.id}_${route.id}';
        final entry = controlTableConfig.entries[entryKey];
        if (entry != null) {
          buffer.writeln('  Route ${route.id}:');
          buffer.writeln('    Target: ${entry.targetAspect.name}');

          // Add directional requirements
          if (entry.requiredGD != null) {
            buffer.writeln('    Required GD: ${entry.requiredGD!.abbreviation}');
          }
          if (entry.junctionPosition != null && entry.junctionPosition != JunctionPosition.none) {
            buffer.writeln('    Junction Position: ${entry.junctionPosition!.displayName}');
          }
          if (entry.directionChange != null) {
            buffer.writeln('    Direction Change: ${entry.directionChange!.changeType}');
          }

          buffer.writeln('    Required Blocks Clear: ${entry.requiredBlocksClear.join(", ")}');
          buffer.writeln('    Approach Blocks: ${entry.approachBlocks.join(", ")}');
          buffer.writeln('    Protected Blocks: ${entry.protectedBlocks.join(", ")}');
          buffer.writeln('    Point Positions: ${entry.requiredPointPositions.entries.map((e) => '${e.key}=${e.value.name}').join(", ")}');
          buffer.writeln('    Conflicts: ${entry.conflictingRoutes.join(", ")}');
          buffer.writeln('    Enabled: ${entry.enabled}');
        }
      }
    }

    // Points
    buffer.writeln('\n=== POINTS ===');
    for (var point in points.values) {
      final entry = controlTableConfig.getPointEntry(point.id);
      final junctionInfo = point.isJunctionPoint
          ? ' [Junction: ${point.junctionId}]'
          : '';
      buffer.writeln('Point ${point.id} (${point.name})$junctionInfo:');
      buffer.writeln('  Current: ${point.position.name}, Locked: ${point.locked}');

      // Add junction direction change info if applicable
      if (point.currentDirectionChange != null) {
        buffer.writeln('  Direction Change (${point.position.name}): ${point.currentDirectionChange!.changeType}');
        buffer.writeln('    Approach: ${point.currentDirectionChange!.approachDirection.name} (${point.currentDirectionChange!.approachGD.abbreviation})');
        buffer.writeln('    Exit: ${point.currentDirectionChange!.exitDirection.name} (${point.currentDirectionChange!.exitGD.abbreviation})');
      }

      if (entry != null) {
        buffer.writeln('  Deadlock Blocks: ${entry.deadlockBlocks.join(", ")}');
        buffer.writeln('  Deadlock ABs: ${entry.deadlockApproachBlocks.join(", ")}');
        buffer.writeln('  Flank Protection: ${entry.flankProtectionPoints.entries.map((e) => '${e.key}=${e.value.name}').join(", ")}');
      }
    }

    // Blocks
    buffer.writeln('\n=== BLOCKS ===');
    for (var block in blocks.values) {
      final dirInfo = block.primaryDirection != null
          ? ' (Direction: ${block.primaryDirection!.name.toUpperCase()}, ${block.guidewayDirection!.abbreviation}${block.isBidirectional ? ", Bidirectional" : ""})'
          : '';
      buffer.writeln('Block ${block.id}: ${block.occupied ? "OCCUPIED" : "CLEAR"}$dirInfo');
    }

    // Axle Counters
    buffer.writeln('\n=== AXLE COUNTERS ===');
    for (var ac in axleCounters.values) {
      buffer.writeln('${ac.id}: count=${ac.count}');
    }

    // ABs
    buffer.writeln('\n=== APPROACH BLOCKS (ABs) ===');
    for (var ab in controlTableConfig.abConfigurations.values) {
      buffer.writeln(
          '${ab.name} (${ab.id}): ${ab.axleCounter1Id} -> ${ab.axleCounter2Id}, Enabled: ${ab.enabled}');
    }

    return buffer.toString();
  }

  String _buildAnalysisSystemPrompt() {
    return '''
You are an expert railway signalling engineer specializing in control table analysis and safety validation.

Your task is to analyze railway control table configurations and provide:
1. Safety conflict detection (routes that could be set simultaneously causing danger)
2. Missing protection (signals without adequate approach blocks or point protection)
3. Deadlock prevention (points without proper deadlock blocks)
4. Optimization opportunities (redundant rules, missing efficiency improvements)
5. AB configuration suggestions
6. Directional logic validation (GD0/GD1 compliance and junction position correctness)

RAILWAY DIRECTIONAL CONCEPTS:

Cardinal Directions:
- North (N), East (E), South (S), West (W) - physical direction of track/train travel

Guideway Directions (GD):
- GD0: Trains traveling SOUTH or WEST (decreasing/backward direction)
- GD1: Trains traveling NORTH or EAST (increasing/forward direction)

Junction Positions (Alpha/Gamma):
- Alpha (α): Main/through route at a junction
- Gamma (γ): Diverging route at a junction
- At junctions, trains can change GD (e.g., GD0 → GD1 or GD1 → GD0)
- 3-way junctions allow left/right/straight routing with potential GD changes

CRITICAL SAFETY RULES:
- Conflicting routes MUST have each other listed in conflictingRoutes
- All routes requiring point positions MUST have those points in requiredPointPositions
- Points MUST have deadlock blocks to prevent movement when trains present
- Signals should have approach blocks for approach locking
- Flank protection points should lock points that could create danger
- Routes with GD changes at junctions MUST have correct junction position (Alpha/Gamma) configured
- Blocks should be marked with their primary direction and GD (unless bidirectional)
- Opposing GD traffic on same block (if not bidirectional) is a CRITICAL safety hazard

Respond in JSON format:
{
  "summary": "Brief overview of findings",
  "conflicts": [
    {
      "type": "route_conflict|missing_protection|deadlock_issue|optimization",
      "severity": "critical|warning|info",
      "title": "Issue title",
      "description": "Detailed description",
      "affectedItems": ["S01_R1", "S02_R1"],
      "suggestion": "How to fix"
    }
  ],
  "suggestions": [
    {
      "type": "signal_rule|point_rule|ab_config|conflict_fix",
      "title": "Suggestion title",
      "description": "What to do",
      "priority": "high|medium|low",
      "changes": {
        "action": "add_ab|update_signal_entry|update_point_entry|add_conflict",
        "data": {}
      }
    }
  ]
}
''';
  }

  String _buildChatSystemPrompt(String context) {
    return '''
You are an expert railway signalling consultant helping configure a railway control table system.

You have access to the current railway configuration:

$context

DIRECTIONAL CONCEPTS YOU UNDERSTAND:

Cardinal Directions: North (N), East (E), South (S), West (W)

Guideway Directions (GD):
- GD0: Trains traveling SOUTH or WEST (decreasing direction)
- GD1: Trains traveling NORTH or EAST (increasing direction)

Junction Positions:
- Alpha (α): Main/through route at junctions
- Gamma (γ): Diverging route at junctions
- Junctions can cause GD changes (GD0→GD1 or GD1→GD0)
- 3-way junctions allow trains to go left, right, or straight, changing GD allocation

You can:
1. Answer questions about the current configuration (including directional logic)
2. Explain signalling concepts, GD0/GD1, and Alpha/Gamma positions
3. Suggest improvements and optimizations with directional awareness
4. Help diagnose conflicts and safety issues including directional violations
5. Generate specific configuration suggestions respecting GD requirements
6. Explain junction routing and direction changes
7. Validate that routes have correct GD and junction position configurations

When providing suggestions that can be applied, format them clearly and explain what changes you're recommending.

Be concise but thorough. Use railway signalling terminology correctly. Always consider directional logic in your recommendations.
''';
  }

  ControlTableAnalysis _parseAnalysisResponse(String content) {
    try {
      // Try to extract JSON from the response
      final jsonStart = content.indexOf('{');
      final jsonEnd = content.lastIndexOf('}') + 1;

      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        final jsonStr = content.substring(jsonStart, jsonEnd);
        final json = jsonDecode(jsonStr);

        return ControlTableAnalysis(
          success: true,
          summary: json['summary'] ?? 'Analysis complete',
          conflicts: (json['conflicts'] as List?)?.map((c) => ConflictReport.fromJson(c)).toList() ?? [],
          suggestions: (json['suggestions'] as List?)?.map((s) => ControlTableSuggestion.fromJson(s)).toList() ?? [],
        );
      }
    } catch (e) {
      print('Error parsing analysis response: $e');
    }

    // Fallback: return the content as summary
    return ControlTableAnalysis(
      success: true,
      summary: content,
      conflicts: [],
      suggestions: [],
    );
  }

  List<ControlTableSuggestion> _extractSuggestionsFromChat(String content) {
    // Extract any structured suggestions from chat response
    // This is a simple implementation - can be enhanced
    return [];
  }

  List<ABSuggestion> _parseABSuggestions(String content) {
    try {
      final jsonStart = content.indexOf('{');
      final jsonEnd = content.lastIndexOf('}') + 1;

      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        final jsonStr = content.substring(jsonStart, jsonEnd);
        final json = jsonDecode(jsonStr);

        return (json['suggestions'] as List?)?.map((s) => ABSuggestion.fromJson(s)).toList() ?? [];
      }
    } catch (e) {
      print('Error parsing AB suggestions: $e');
    }
    return [];
  }
}

// ============================================================================
// DATA MODELS
// ============================================================================

class ControlTableAnalysis {
  final bool success;
  final String summary;
  final List<ConflictReport> conflicts;
  final List<ControlTableSuggestion> suggestions;
  final String? errorMessage;

  ControlTableAnalysis({
    required this.success,
    required this.summary,
    required this.conflicts,
    required this.suggestions,
    this.errorMessage,
  });
}

class ConflictReport {
  final String type; // route_conflict, missing_protection, deadlock_issue, optimization
  final String severity; // critical, warning, info
  final String title;
  final String description;
  final List<String> affectedItems;
  final String suggestion;

  ConflictReport({
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.affectedItems,
    required this.suggestion,
  });

  factory ConflictReport.fromJson(Map<String, dynamic> json) {
    return ConflictReport(
      type: json['type'] ?? 'unknown',
      severity: json['severity'] ?? 'info',
      title: json['title'] ?? 'Issue',
      description: json['description'] ?? '',
      affectedItems: List<String>.from(json['affectedItems'] ?? []),
      suggestion: json['suggestion'] ?? '',
    );
  }
}

class ControlTableSuggestion {
  final String id;
  final String type; // signal_rule, point_rule, ab_config, conflict_fix
  final String title;
  final String description;
  final String priority; // high, medium, low
  final Map<String, dynamic> changes;
  bool applied;
  DateTime timestamp;

  ControlTableSuggestion({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    required this.changes,
    this.applied = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ControlTableSuggestion.fromJson(Map<String, dynamic> json) {
    return ControlTableSuggestion(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: json['type'] ?? 'unknown',
      title: json['title'] ?? 'Suggestion',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'medium',
      changes: json['changes'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'priority': priority,
      'changes': changes,
      'applied': applied,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class ABSuggestion {
  final String name;
  final String axleCounter1;
  final String axleCounter2;
  final String purpose;
  final List<String> relatedSignals;

  ABSuggestion({
    required this.name,
    required this.axleCounter1,
    required this.axleCounter2,
    required this.purpose,
    required this.relatedSignals,
  });

  factory ABSuggestion.fromJson(Map<String, dynamic> json) {
    return ABSuggestion(
      name: json['name'] ?? 'Unnamed AB',
      axleCounter1: json['axleCounter1'] ?? '',
      axleCounter2: json['axleCounter2'] ?? '',
      purpose: json['purpose'] ?? '',
      relatedSignals: List<String>.from(json['relatedSignals'] ?? []),
    );
  }
}

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChatResponse {
  final bool success;
  final String message;
  final List<ControlTableSuggestion> suggestions;

  ChatResponse({
    required this.success,
    required this.message,
    required this.suggestions,
  });
}

/// Result of AI reservation analysis for a signal route
class ReservationAnalysisResult {
  final String signalId;
  final String routeId;
  final String severity; // CRITICAL, WARNING, INFO
  final String issueType; // missing_block, extra_block, flank_protection, etc.
  final String blockId;
  final String explanation;
  final String suggestedFix;
  final String safetyImpact;

  ReservationAnalysisResult({
    required this.signalId,
    required this.routeId,
    required this.severity,
    required this.issueType,
    required this.blockId,
    required this.explanation,
    required this.suggestedFix,
    required this.safetyImpact,
  });

  bool get isCritical => severity == 'CRITICAL';
  bool get isWarning => severity == 'WARNING';

  Color get severityColor {
    switch (severity) {
      case 'CRITICAL':
        return Colors.red;
      case 'WARNING':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}



