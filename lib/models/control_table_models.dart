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

/// Point Control Table Entry - defines conditions for point movement
/// Includes deadlocking and flank protection
class PointControlTableEntry {
  final String id;
  final String pointId;

  /// Deadlock conditions - blocks that prevent point movement when occupied
  List<String> deadlockBlocks;

  /// Approach blocks that prevent point movement
  List<String> deadlockApproachBlocks;

  /// Flank protection - points that lock this point when in specific positions
  Map<String, PointPosition> flankProtectionPoints;

  /// Whether this point can be moved manually
  bool manualControlEnabled;

  /// Notes about this point's interlocking
  String notes;

  PointControlTableEntry({
    required this.id,
    required this.pointId,
    this.deadlockBlocks = const [],
    this.deadlockApproachBlocks = const [],
    this.flankProtectionPoints = const {},
    this.manualControlEnabled = true,
    this.notes = '',
  });

  PointControlTableEntry copyWith({
    String? id,
    String? pointId,
    List<String>? deadlockBlocks,
    List<String>? deadlockApproachBlocks,
    Map<String, PointPosition>? flankProtectionPoints,
    bool? manualControlEnabled,
    String? notes,
  }) {
    return PointControlTableEntry(
      id: id ?? this.id,
      pointId: pointId ?? this.pointId,
      deadlockBlocks: deadlockBlocks ?? this.deadlockBlocks,
      deadlockApproachBlocks: deadlockApproachBlocks ?? this.deadlockApproachBlocks,
      flankProtectionPoints: flankProtectionPoints ?? this.flankProtectionPoints,
      manualControlEnabled: manualControlEnabled ?? this.manualControlEnabled,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pointId': pointId,
      'deadlockBlocks': deadlockBlocks,
      'deadlockApproachBlocks': deadlockApproachBlocks,
      'flankProtectionPoints': flankProtectionPoints.map(
        (key, value) => MapEntry(key, value.name),
      ),
      'manualControlEnabled': manualControlEnabled,
      'notes': notes,
    };
  }

  factory PointControlTableEntry.fromJson(Map<String, dynamic> json) {
    return PointControlTableEntry(
      id: json['id'] as String,
      pointId: json['pointId'] as String,
      deadlockBlocks: List<String>.from(json['deadlockBlocks'] ?? []),
      deadlockApproachBlocks: List<String>.from(json['deadlockApproachBlocks'] ?? []),
      flankProtectionPoints: (json['flankProtectionPoints'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(
                key,
                PointPosition.values.firstWhere((e) => e.name == value),
              )) ??
          {},
      manualControlEnabled: json['manualControlEnabled'] as bool? ?? true,
      notes: json['notes'] as String? ?? '',
    );
  }
}

/// AB (Approach Block) Configuration
/// Defines an approach blocking section with associated axle counters
class ABConfiguration {
  final String id;
  String name;

  /// The two axle counter IDs that form this AB
  String axleCounter1Id;
  String axleCounter2Id;

  /// Whether this AB is enabled
  bool enabled;

  /// Color to highlight when active (default purple)
  String highlightColor;

  /// Notes about this AB
  String notes;

  ABConfiguration({
    required this.id,
    required this.name,
    required this.axleCounter1Id,
    required this.axleCounter2Id,
    this.enabled = true,
    this.highlightColor = 'purple',
    this.notes = '',
  });

  ABConfiguration copyWith({
    String? id,
    String? name,
    String? axleCounter1Id,
    String? axleCounter2Id,
    bool? enabled,
    String? highlightColor,
    String? notes,
  }) {
    return ABConfiguration(
      id: id ?? this.id,
      name: name ?? this.name,
      axleCounter1Id: axleCounter1Id ?? this.axleCounter1Id,
      axleCounter2Id: axleCounter2Id ?? this.axleCounter2Id,
      enabled: enabled ?? this.enabled,
      highlightColor: highlightColor ?? this.highlightColor,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'axleCounter1Id': axleCounter1Id,
      'axleCounter2Id': axleCounter2Id,
      'enabled': enabled,
      'highlightColor': highlightColor,
      'notes': notes,
    };
  }

  factory ABConfiguration.fromJson(Map<String, dynamic> json) {
    return ABConfiguration(
      id: json['id'] as String,
      name: json['name'] as String,
      axleCounter1Id: json['axleCounter1Id'] as String,
      axleCounter2Id: json['axleCounter2Id'] as String,
      enabled: json['enabled'] as bool? ?? true,
      highlightColor: json['highlightColor'] as String? ?? 'purple',
      notes: json['notes'] as String? ?? '',
    );
  }

  /// Check if train wheels are detected (AB is occupied)
  bool isOccupied(Map<String, dynamic> axleCounters) {
    final ac1 = axleCounters[axleCounter1Id];
    final ac2 = axleCounters[axleCounter2Id];

    if (ac1 == null || ac2 == null) return false;

    // AB is occupied if axle count difference between counters is non-zero
    final count1 = ac1['count'] as int? ?? 0;
    final count2 = ac2['count'] as int? ?? 0;

    return (count1 - count2).abs() > 0;
  }
}

/// Extended Control Table Configuration with Points and AB
class ExtendedControlTableConfiguration extends ControlTableConfiguration {
  /// Map of point control table entries by point ID
  Map<String, PointControlTableEntry> pointEntries = {};

  /// Map of AB configurations by AB ID
  Map<String, ABConfiguration> abConfigurations = {};

  @override
  void updateEntry(ControlTableEntry entry) {
    super.updateEntry(entry);
  }

  /// Add or update a point entry
  void updatePointEntry(PointControlTableEntry entry) {
    pointEntries[entry.id] = entry;
    hasUnsavedChanges = true;
    notifyListeners();
  }

  /// Remove a point entry
  void removePointEntry(String entryId) {
    pointEntries.remove(entryId);
    hasUnsavedChanges = true;
    notifyListeners();
  }

  /// Get point entry by point ID
  PointControlTableEntry? getPointEntry(String pointId) {
    return pointEntries[pointId];
  }

  /// Add or update an AB configuration
  void updateABConfiguration(ABConfiguration config) {
    abConfigurations[config.id] = config;
    hasUnsavedChanges = true;
    notifyListeners();
  }

  /// Remove an AB configuration
  void removeABConfiguration(String configId) {
    abConfigurations.remove(configId);
    hasUnsavedChanges = true;
    notifyListeners();
  }

  /// Get AB configuration by ID
  ABConfiguration? getABConfiguration(String id) {
    return abConfigurations[id];
  }

  @override
  void clear() {
    super.clear();
    pointEntries.clear();
    abConfigurations.clear();
  }

  @override
  void fromJson(Map<String, dynamic> json) {
    super.fromJson(json);

    pointEntries.clear();
    final pointEntriesList = json['pointEntries'] as List?;
    if (pointEntriesList != null) {
      for (var entryJson in pointEntriesList) {
        final entry = PointControlTableEntry.fromJson(entryJson as Map<String, dynamic>);
        pointEntries[entry.id] = entry;
      }
    }

    abConfigurations.clear();
    final abConfigsList = json['abConfigurations'] as List?;
    if (abConfigsList != null) {
      for (var configJson in abConfigsList) {
        final config = ABConfiguration.fromJson(configJson as Map<String, dynamic>);
        abConfigurations[config.id] = config;
      }
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['pointEntries'] = pointEntries.values.map((e) => e.toJson()).toList();
    json['abConfigurations'] = abConfigurations.values.map((e) => e.toJson()).toList();
    return json;
  }

  /// Initialize point entries from existing points
  void initializePointEntries(Map<String, Point> points) {
    pointEntries.clear();
    for (var point in points.values) {
      final entry = PointControlTableEntry(
        id: point.id,
        pointId: point.id,
        deadlockBlocks: [],
        deadlockApproachBlocks: [],
        flankProtectionPoints: {},
        manualControlEnabled: true,
        notes: '',
      );
      pointEntries[entry.id] = entry;
    }
    hasUnsavedChanges = true;
    notifyListeners();
  }
}
