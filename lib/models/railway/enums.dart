// ============================================================================
// RAILWAY ENUMS
// ============================================================================

enum SignalState { red, green, yellow, blue }

enum PointPosition { normal, reverse }

enum TrainStatus { moving, stopped, waiting, completed, reversing }

enum Direction { east, west }

enum TransponderType { t1, t2, t3, t6 }

enum CbtcMode {
  auto,      // Automatic mode - cyan
  pm,        // Protective Manual mode - orange
  rm,        // Restrictive Manual mode - brown
  off,       // Off mode - white
  storage    // Storage mode - green
}
