import 'enums.dart';

class Point {
  final String id;
  final double x;
  final double y;
  PointPosition position;
  double animationProgress;
  String? reservedByVin; // VIN of train that has reserved this point
  String? reservedDestination; // Destination of reserving train

  Point({
    required this.id,
    required this.x,
    required this.y,
    this.position = PointPosition.normal,
    this.animationProgress = 0.0,
    this.reservedByVin,
    this.reservedDestination,
  });
}
