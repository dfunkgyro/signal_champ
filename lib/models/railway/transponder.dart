import 'enums.dart';

class Transponder {
  final String id;
  final TransponderType type;
  final double x;
  final double y;
  final String description;

  Transponder({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.description,
  });
}
