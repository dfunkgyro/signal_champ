import 'package:flutter/foundation.dart';
import '../screens/terminal_station_models.dart';

/// Control Table Entry - represents a single row in the control table
/// This defines the conditions under which a signal can display a specific aspect
class ControlTableEntry {
  final String id;
  final String signalId;
  final String routeId;
  final String routeName;

  /// The aspect this entry allows (green, yellow, blue)
  SignalAspect targetAspect;

  /// List of block IDs that must be clear for signal to show target aspect
  List<String> requiredBlocksClear;

  /// Map of point IDs to required positions
  Map<String, PointPosition> requiredPointPositions;

  /// List of conflicting routes that must not be active
  List<String> conflictingRoutes;

  /// Blocks that this signal protects (the route path)
  List<String> protectedBlocks;

  /// Approach blocks - blocks where train presence is required for signal clearance
  /// Used for approach control (e.g., signal only clears when train is approaching)
  List<String> approachBlocks;

  /// Blocks that form the path of this route
  List<String> pathBlocks;

  /// Release condition - description of when route can be released
  String releaseCondition;

  /// Additional custom conditions (for special signal logic)
  Map<String, dynamic> customConditions;

  /// Whether this entry is enabled
  bool enabled;

  /// User notes for this control table entry
  String notes;

  ControlTableEntry({
    required this.id,
    required this.signalId,
    required this.routeId,
    required this.routeName,
    this.targetAspect = SignalAspect.green,
    this.requiredBlocksClear = const [],
    this.requiredPointPositions = const {},
    this.conflictingRoutes = const [],
    this.protectedBlocks = const [],
    this.approachBlocks = const [],
    this.pathBlocks = const [],
    this.releaseCondition = 'Train clears all protected blocks',
    this.customConditions = const {},
    this.enabled = true,
    this.notes = '',
  });

  /// Create a copy with modified fields
  ControlTableEntry copyWith({
    String? id,
    String? signalId,
    String? routeId,
    String? routeName,
    SignalAspect? targetAspect,
    List<String>? requiredBlocksClear,
    Map<String, PointPosition>? requiredPointPositions,
    List<String>? conflictingRoutes,
    List<String>? protectedBlocks,
    List<String>? approachBlocks,
    List<String>? pathBlocks,
    String? releaseCondition,
    Map<String, dynamic>? customConditions,
    bool? enabled,
    String? notes,
  }) {
    return ControlTableEntry(
      id: id ?? this.id,
      signalId: signalId ?? this.signalId,
      routeId: routeId ?? this.routeId,
      routeName: routeName ?? this.routeName,
      targetAspect: targetAspect ?? this.targetAspect,
      requiredBlocksClear: requiredBlocksClear ?? this.requiredBlocksClear,
      requiredPointPositions: requiredPointPositions ?? this.requiredPointPositions,
      conflictingRoutes: conflictingRoutes ?? this.conflictingRoutes,
      protectedBlocks: protectedBlocks ?? this.protectedBlocks,
      approachBlocks: approachBlocks ?? this.approachBlocks,
      pathBlocks: pathBlocks ?? this.pathBlocks,
      releaseCondition: releaseCondition ?? this.releaseCondition,
      customConditions: customConditions ?? this.customConditions,
      enabled: enabled ?? this.enabled,
      notes: notes ?? this.notes,
    );
  }

  /// Convert to JSON for saving
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'signalId': signalId,
      'routeId': routeId,
      'routeName': routeName,
      'targetAspect': targetAspect.name,
      'requiredBlocksClear': requiredBlocksClear,
      'requiredPointPositions': requiredPointPositions.map(
        (key, value) => MapEntry(key, value.name),
      ),
      'conflictingRoutes': conflictingRoutes,
      'protectedBlocks': protectedBlocks,
      'approachBlocks': approachBlocks,
      'pathBlocks': pathBlocks,
      'releaseCondition': releaseCondition,
      'customConditions': customConditions,
      'enabled': enabled,
      'notes': notes,
    };
  }

  /// Create from JSON
  factory ControlTableEntry.fromJson(Map<String, dynamic> json) {
    return ControlTableEntry(
      id: json['id'] as String,
      signalId: json['signalId'] as String,
      routeId: json['routeId'] as String,
      routeName: json['routeName'] as String,
      targetAspect: SignalAspect.values.firstWhere(
        (e) => e.name == json['targetAspect'],
        orElse: () => SignalAspect.green,
      ),
      requiredBlocksClear: List<String>.from(json['requiredBlocksClear'] ?? []),
      requiredPointPositions: (json['requiredPointPositions'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(
                key,
                PointPosition.values.firstWhere((e) => e.name == value),
              )) ??
          {},
      conflictingRoutes: List<String>.from(json['conflictingRoutes'] ?? []),
      protectedBlocks: List<String>.from(json['protectedBlocks'] ?? []),
      approachBlocks: List<String>.from(json['approachBlocks'] ?? []),
      pathBlocks: List<String>.from(json['pathBlocks'] ?? []),
      releaseCondition: json['releaseCondition'] as String? ?? 'Train clears all protected blocks',
      customConditions: json['customConditions'] as Map<String, dynamic>? ?? {},
      enabled: json['enabled'] as bool? ?? true,
      notes: json['notes'] as String? ?? '',
    );
  }

  /// Create from existing SignalRoute
  factory ControlTableEntry.fromSignalRoute({
    required String signalId,
    required SignalRoute route,
    SignalAspect targetAspect = SignalAspect.green,
  }) {
    return ControlTableEntry(
      id: '${signalId}_${route.id}',
      signalId: signalId,
      routeId: route.id,
      routeName: route.name,
      targetAspect: targetAspect,
      requiredBlocksClear: List.from(route.requiredBlocksClear),
      requiredPointPositions: Map.from(route.requiredPointPositions),
      conflictingRoutes: List.from(route.conflictingRoutes),
      protectedBlocks: List.from(route.protectedBlocks),
      pathBlocks: List.from(route.pathBlocks),
      approachBlocks: [],
      releaseCondition: 'Train clears all protected blocks',
      customConditions: {},
      enabled: true,
      notes: '',
    );
  }
}

/// Control Table Configuration - contains all control table entries for the layout
class ControlTableConfiguration extends ChangeNotifier {
  /// Map of control table entries by ID
  Map<String, ControlTableEntry> entries = {};

  /// Whether the control table has unsaved changes
  bool hasUnsavedChanges = false;

  /// Add or update an entry
  void updateEntry(ControlTableEntry entry) {
    entries[entry.id] = entry;
    hasUnsavedChanges = true;
    notifyListeners();
  }

  /// Remove an entry
  void removeEntry(String entryId) {
    entries.remove(entryId);
    hasUnsavedChanges = true;
    notifyListeners();
  }

  /// Get all entries for a specific signal
  List<ControlTableEntry> getEntriesForSignal(String signalId) {
    return entries.values
        .where((entry) => entry.signalId == signalId)
        .toList()
      ..sort((a, b) => a.routeName.compareTo(b.routeName));
  }

  /// Get entry by ID
  ControlTableEntry? getEntry(String entryId) {
    return entries[entryId];
  }

  /// Clear all entries
  void clear() {
    entries.clear();
    hasUnsavedChanges = false;
    notifyListeners();
  }

  /// Load entries from JSON
  void fromJson(Map<String, dynamic> json) {
    entries.clear();
    final entriesList = json['entries'] as List?;
    if (entriesList != null) {
      for (var entryJson in entriesList) {
        final entry = ControlTableEntry.fromJson(entryJson as Map<String, dynamic>);
        entries[entry.id] = entry;
      }
    }
    hasUnsavedChanges = false;
    notifyListeners();
  }

  /// Convert to JSON for saving
  Map<String, dynamic> toJson() {
    return {
      'entries': entries.values.map((e) => e.toJson()).toList(),
    };
  }

  /// Mark as saved
  void markAsSaved() {
    hasUnsavedChanges = false;
    notifyListeners();
  }

  /// Initialize from existing signals and routes
  void initializeFromSignals(Map<String, Signal> signals) {
    entries.clear();
    for (var signal in signals.values) {
      for (var route in signal.routes) {
        final entry = ControlTableEntry.fromSignalRoute(
          signalId: signal.id,
          route: route,
          targetAspect: SignalAspect.green,
        );
        entries[entry.id] = entry;
      }
    }
    hasUnsavedChanges = false;
    notifyListeners();
  }
}
