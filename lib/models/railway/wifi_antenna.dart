class WifiAntenna {
  final String id;
  final double x;
  final double y;
  final bool isActive;

  WifiAntenna({
    required this.id,
    required this.x,
    required this.y,
    this.isActive = true,
  });
}
