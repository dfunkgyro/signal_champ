class AxleCounter {
  final String id;
  final String blockId;
  final double x;
  final double y;
  int count;
  DateTime? lastDetectionTime;
  bool d1Active;
  bool d2Active;
  String lastDirection;
  final bool isTwin;
  final String? twinLabel;
  String? lastTrainDetected;
  DateTime? lastTrainDetectionTime;

  AxleCounter({
    required this.id,
    required this.blockId,
    required this.x,
    required this.y,
    this.count = 0,
    this.lastDetectionTime,
    this.d1Active = false,
    this.d2Active = false,
    this.lastDirection = '',
    this.isTwin = false,
    this.twinLabel,
    this.lastTrainDetected,
    this.lastTrainDetectionTime,
  });
}
