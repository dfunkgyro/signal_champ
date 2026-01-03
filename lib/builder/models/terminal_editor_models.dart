import 'dart:math';
import 'dart:ui';

enum EditorTool {
  select,
  marqueeSelect,
  move,
  addTrackStraight,
  addTrackBendLeft,
  addTrackBendRight,
  addTrackCurveOctagon,
  addCrossoverRight,
  addCrossoverLeft,
  addCrossoverDiamond,
  addPoint,
  addSignal,
  addPlatform,
  addTrainStop,
  addBufferStop,
  addAxleCounter,
  addTransponder,
  addWifiAntenna,
  addText,
}

enum EditorComponentType {
  trackSegment,
  crossover,
  point,
  signal,
  platform,
  trainStop,
  bufferStop,
  axleCounter,
  transponder,
  wifiAntenna,
  textAnnotation,
}

enum SignalAspect { red, green, yellow, blue }

enum SignalDirection { east, west }

enum PointPosition { normal, reverse }

enum CrossoverType { lefthand, righthand, doubleDiamond, singleSlip, doubleSlip }

enum TransponderType { t1, t2, t3, t6 }

enum PointStyle {
  classic,
  blade,
  chevron,
  wedge,
  indicator,
  bridge,
  terminalGap,
}

enum PointOrientation {
  upLeft,
  upRight,
  downLeft,
  downRight,
}

enum TrackStyle {
  ballast,
  slab,
  gravel,
  bridge,
  tunnel,
  yard,
  service,
  elevated,
  industrial,
  metro,
}

enum GuidewayDirection {
  gd0,
  gd1,
}

enum BuilderRenderStyle {
  simulation,
  builderClassic,
}

class TrackSegment {
  final String id;
  final String name;
  final String description;
  final String notes;
  final Color color;
  final TrackStyle style;
  final GuidewayDirection guidewayDirection;
  final double startX;
  final double startY;
  final double length;
  final double angleDeg;
  final bool occupied;

  const TrackSegment({
    required this.id,
    required this.name,
    required this.description,
    required this.notes,
    required this.color,
    this.style = TrackStyle.ballast,
    this.guidewayDirection = GuidewayDirection.gd1,
    required this.startX,
    required this.startY,
    required this.length,
    required this.angleDeg,
    this.occupied = false,
  });

  TrackSegment copyWith({
    String? id,
    String? name,
    String? description,
    String? notes,
    Color? color,
    TrackStyle? style,
    GuidewayDirection? guidewayDirection,
    double? startX,
    double? startY,
    double? length,
    double? angleDeg,
    bool? occupied,
  }) {
    return TrackSegment(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      color: color ?? this.color,
      style: style ?? this.style,
      guidewayDirection: guidewayDirection ?? this.guidewayDirection,
      startX: startX ?? this.startX,
      startY: startY ?? this.startY,
      length: length ?? this.length,
      angleDeg: angleDeg ?? this.angleDeg,
      occupied: occupied ?? this.occupied,
    );
  }

  Offset endPoint() {
    final radians = angleDeg * 3.141592653589793 / 180.0;
    return Offset(
      startX + length * cos(radians),
      startY + length * sin(radians),
    );
  }
}

class Crossover {
  final String id;
  final String name;
  final String description;
  final String notes;
  final Color color;
  final TrackStyle style;
  final double x;
  final double y;
  final CrossoverType type;
  final double gapAngle;

  const Crossover({
    required this.id,
    required this.name,
    required this.description,
    required this.notes,
    required this.color,
    this.style = TrackStyle.ballast,
    required this.x,
    required this.y,
    this.type = CrossoverType.righthand,
    this.gapAngle = 15.0,
  });

  Crossover copyWith({
    String? id,
    String? name,
    String? description,
    String? notes,
    Color? color,
    TrackStyle? style,
    double? x,
    double? y,
    CrossoverType? type,
    double? gapAngle,
  }) {
    return Crossover(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      color: color ?? this.color,
      style: style ?? this.style,
      x: x ?? this.x,
      y: y ?? this.y,
      type: type ?? this.type,
      gapAngle: gapAngle ?? this.gapAngle,
    );
  }
}

class TrackPoint {
  final String id;
  final String name;
  final String description;
  final String notes;
  final Color color;
  final double x;
  final double y;
  final PointPosition position;
  final bool locked;
  final PointStyle style;
  final PointOrientation orientation;
  final bool autoDetectOrientation;

  const TrackPoint({
    required this.id,
    required this.name,
    required this.description,
    required this.notes,
    required this.color,
    required this.x,
    required this.y,
    this.position = PointPosition.normal,
    this.locked = false,
    this.style = PointStyle.classic,
    this.orientation = PointOrientation.upRight,
    this.autoDetectOrientation = false,
  });

  TrackPoint copyWith({
    String? id,
    String? name,
    String? description,
    String? notes,
    Color? color,
    double? x,
    double? y,
    PointPosition? position,
    bool? locked,
    PointStyle? style,
    PointOrientation? orientation,
    bool? autoDetectOrientation,
  }) {
    return TrackPoint(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      color: color ?? this.color,
      x: x ?? this.x,
      y: y ?? this.y,
      position: position ?? this.position,
      locked: locked ?? this.locked,
      style: style ?? this.style,
      orientation: orientation ?? this.orientation,
      autoDetectOrientation:
          autoDetectOrientation ?? this.autoDetectOrientation,
    );
  }
}

class Signal {
  final String id;
  final String name;
  final String description;
  final String notes;
  final Color color;
  final double x;
  final double y;
  final SignalDirection direction;
  final SignalAspect aspect;

  const Signal({
    required this.id,
    required this.name,
    required this.description,
    required this.notes,
    required this.color,
    required this.x,
    required this.y,
    this.direction = SignalDirection.east,
    this.aspect = SignalAspect.red,
  });

  Signal copyWith({
    String? id,
    String? name,
    String? description,
    String? notes,
    Color? color,
    double? x,
    double? y,
    SignalDirection? direction,
    SignalAspect? aspect,
  }) {
    return Signal(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      color: color ?? this.color,
      x: x ?? this.x,
      y: y ?? this.y,
      direction: direction ?? this.direction,
      aspect: aspect ?? this.aspect,
    );
  }
}

class Platform {
  final String id;
  final String name;
  final String description;
  final String notes;
  final Color color;
  final double startX;
  final double endX;
  final double y;
  final bool occupied;

  const Platform({
    required this.id,
    required this.name,
    required this.description,
    required this.notes,
    required this.color,
    required this.startX,
    required this.endX,
    required this.y,
    this.occupied = false,
  });

  double get centerX => (startX + endX) / 2;
  double get length => (endX - startX).abs();

  Platform copyWith({
    String? id,
    String? name,
    String? description,
    String? notes,
    Color? color,
    double? startX,
    double? endX,
    double? y,
    bool? occupied,
  }) {
    return Platform(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      color: color ?? this.color,
      startX: startX ?? this.startX,
      endX: endX ?? this.endX,
      y: y ?? this.y,
      occupied: occupied ?? this.occupied,
    );
  }
}

class TrainStop {
  final String id;
  final String name;
  final String description;
  final String notes;
  final Color color;
  final double x;
  final double y;
  final bool enabled;

  const TrainStop({
    required this.id,
    required this.name,
    required this.description,
    required this.notes,
    required this.color,
    required this.x,
    required this.y,
    this.enabled = true,
  });

  TrainStop copyWith({
    String? id,
    String? name,
    String? description,
    String? notes,
    Color? color,
    double? x,
    double? y,
    bool? enabled,
  }) {
    return TrainStop(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      color: color ?? this.color,
      x: x ?? this.x,
      y: y ?? this.y,
      enabled: enabled ?? this.enabled,
    );
  }
}

class BufferStop {
  final String id;
  final String name;
  final String description;
  final String notes;
  final Color color;
  final double x;
  final double y;
  final double width;
  final double height;

  const BufferStop({
    required this.id,
    required this.name,
    required this.description,
    required this.notes,
    required this.color,
    required this.x,
    required this.y,
    this.width = 32,
    this.height = 18,
  });

  BufferStop copyWith({
    String? id,
    String? name,
    String? description,
    String? notes,
    Color? color,
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    return BufferStop(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      color: color ?? this.color,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}

class AxleCounter {
  final String id;
  final String name;
  final String description;
  final String notes;
  final Color color;
  final double x;
  final double y;
  final bool flipped;

  const AxleCounter({
    required this.id,
    required this.name,
    required this.description,
    required this.notes,
    required this.color,
    required this.x,
    required this.y,
    this.flipped = false,
  });

  AxleCounter copyWith({
    String? id,
    String? name,
    String? description,
    String? notes,
    Color? color,
    double? x,
    double? y,
    bool? flipped,
  }) {
    return AxleCounter(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      color: color ?? this.color,
      x: x ?? this.x,
      y: y ?? this.y,
      flipped: flipped ?? this.flipped,
    );
  }
}

class Transponder {
  final String id;
  final String name;
  final String description;
  final String notes;
  final Color color;
  final double x;
  final double y;
  final TransponderType type;

  const Transponder({
    required this.id,
    required this.name,
    required this.description,
    required this.notes,
    required this.color,
    required this.x,
    required this.y,
    this.type = TransponderType.t1,
  });

  Transponder copyWith({
    String? id,
    String? name,
    String? description,
    String? notes,
    Color? color,
    double? x,
    double? y,
    TransponderType? type,
  }) {
    return Transponder(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      color: color ?? this.color,
      x: x ?? this.x,
      y: y ?? this.y,
      type: type ?? this.type,
    );
  }
}

class WifiAntenna {
  final String id;
  final String name;
  final String description;
  final String notes;
  final Color color;
  final double x;
  final double y;
  final bool isActive;

  const WifiAntenna({
    required this.id,
    required this.name,
    required this.description,
    required this.notes,
    required this.color,
    required this.x,
    required this.y,
    this.isActive = true,
  });

  WifiAntenna copyWith({
    String? id,
    String? name,
    String? description,
    String? notes,
    Color? color,
    double? x,
    double? y,
    bool? isActive,
  }) {
    return WifiAntenna(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      color: color ?? this.color,
      x: x ?? this.x,
      y: y ?? this.y,
      isActive: isActive ?? this.isActive,
    );
  }
}

class TextAnnotation {
  final String id;
  final String name;
  final String description;
  final String notes;
  final Color color;
  final String text;
  final double x;
  final double y;

  const TextAnnotation({
    required this.id,
    required this.name,
    required this.description,
    required this.notes,
    required this.color,
    required this.text,
    required this.x,
    required this.y,
  });

  TextAnnotation copyWith({
    String? id,
    String? name,
    String? description,
    String? notes,
    Color? color,
    String? text,
    double? x,
    double? y,
  }) {
    return TextAnnotation(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      color: color ?? this.color,
      text: text ?? this.text,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }
}

class SelectedComponent {
  final EditorComponentType type;
  final String id;

  const SelectedComponent({
    required this.type,
    required this.id,
  });

  @override
  bool operator ==(Object other) {
    return other is SelectedComponent &&
        other.type == type &&
        other.id == id;
  }

  @override
  int get hashCode => Object.hash(type, id);
}
