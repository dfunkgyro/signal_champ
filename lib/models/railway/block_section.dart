class BlockSection {
  final String id;
  final double startX;
  final double endX;
  final double y;
  final String? nextBlock;
  final String? prevBlock;
  bool occupied;
  final bool isCrossover;
  final bool isReversingArea;
  bool closedBySmc; // SMC track closure status

  BlockSection({
    required this.id,
    required this.startX,
    required this.endX,
    required this.y,
    this.nextBlock,
    this.prevBlock,
    this.occupied = false,
    this.isCrossover = false,
    this.isReversingArea = false,
    this.closedBySmc = false,
  });
}
