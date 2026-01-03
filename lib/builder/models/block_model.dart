class Block {
  final String id;
  double startX;
  double endX;
  double y;
  bool occupied;
  String occupyingTrain;

  Block({
    required this.id,
    required this.startX,
    required this.endX,
    required this.y,
    required this.occupied,
    required this.occupyingTrain,
  });

  double get length => endX - startX;
  double get centerX => (startX + endX) / 2;

  Block copyWith({
    String? id,
    double? startX,
    double? endX,
    double? y,
    bool? occupied,
    String? occupyingTrain,
  }) {
    return Block(
      id: id ?? this.id,
      startX: startX ?? this.startX,
      endX: endX ?? this.endX,
      y: y ?? this.y,
      occupied: occupied ?? this.occupied,
      occupyingTrain: occupyingTrain ?? this.occupyingTrain,
    );
  }
}
