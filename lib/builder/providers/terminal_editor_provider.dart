import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:rail_champ/controllers/terminal_station_controller.dart' as sim;
import 'package:rail_champ/models/layout_configuration.dart';

import '../models/terminal_editor_models.dart';

enum ResizeHandle { start, end }

enum ValidationSeverity { error, warning, info }
enum ValidationLevel { low, standard, high }

class TerminalEditorProvider with ChangeNotifier {
  static const double _magnetThreshold = 14.0;
  static const double _defaultGapAngle = 15.0;
  static const double _defaultGapLength = 12.0;
  final Map<String, TrackSegment> _segments = {};
  final Map<String, Crossover> _crossovers = {};
  final Map<String, TrackPoint> _points = {};
  final Map<String, Signal> _signals = {};
  final Map<String, Platform> _platforms = {};
  final Map<String, TrainStop> _trainStops = {};
  final Map<String, BufferStop> _bufferStops = {};
  final Map<String, AxleCounter> _axleCounters = {};
  final Map<String, Transponder> _transponders = {};
  final Map<String, WifiAntenna> _wifiAntennas = {};
  final Map<String, TextAnnotation> _textAnnotations = {};

  EditorTool _tool = EditorTool.select;
  SelectedComponent? _selected;
  final Set<SelectedComponent> _selection = {};
  bool _snapToGrid = true;
  bool _magnetEnabled = true;
  bool _panMode = false;
  bool _largeHitboxes = true;
  bool _handlesFirst = true;
  static const double _dragThreshold = 6.0;
  bool _draggingActive = false;
  double _gridSize = 20.0;
  bool _gridVisible = true;
  Color _backgroundColor = const Color(0xFFF7F7F7);
  BuilderRenderStyle _renderStyle = BuilderRenderStyle.simulation;
  final Map<String, BuilderRenderStyle> _renderOverrides = {};
  bool _compassVisible = true;
  bool _guidewayDirectionsVisible = true;
  bool _alphaGammaVisible = true;
  final Map<String, Offset> _alphaGammaJunctions = {};

  bool _isDragging = false;
  ResizeHandle? _resizeHandle;
  Offset? _dragStart;
  bool _pendingHistory = false;
  Rect? _marqueeRect;
  Offset? _marqueeStart;

  final List<_EditorState> _undoStack = [];
  final List<_EditorState> _redoStack = [];

  EditorTool get tool => _tool;
  SelectedComponent? get selected => _selected;
  Set<SelectedComponent> get selection => Set.unmodifiable(_selection);
  bool get snapToGrid => _snapToGrid;
  bool get magnetEnabled => _magnetEnabled;
  bool get panMode => _panMode;
  bool get largeHitboxes => _largeHitboxes;
  bool get handlesFirst => _handlesFirst;
  double get gridSize => _gridSize;
  bool get gridVisible => _gridVisible;
  Color get backgroundColor => _backgroundColor;
  BuilderRenderStyle get renderStyle => _renderStyle;
  bool get compassVisible => _compassVisible;
  bool get guidewayDirectionsVisible => _guidewayDirectionsVisible;
  bool get alphaGammaVisible => _alphaGammaVisible;
  Map<String, Offset> get alphaGammaJunctions => _alphaGammaJunctions;
  bool get isDragging => _isDragging;
  ResizeHandle? get resizeHandle => _resizeHandle;
  Rect? get marqueeRect => _marqueeRect;
  double get defaultGapAngle => _defaultGapAngle;
  double get defaultGapLength => _defaultGapLength;

  Map<String, TrackSegment> get segments => _segments;
  Map<String, Crossover> get crossovers => _crossovers;
  Map<String, TrackPoint> get points => _points;
  Map<String, Signal> get signals => _signals;
  Map<String, Platform> get platforms => _platforms;
  Map<String, TrainStop> get trainStops => _trainStops;
  Map<String, BufferStop> get bufferStops => _bufferStops;
  Map<String, AxleCounter> get axleCounters => _axleCounters;
  Map<String, Transponder> get transponders => _transponders;
  Map<String, WifiAntenna> get wifiAntennas => _wifiAntennas;
  Map<String, TextAnnotation> get textAnnotations => _textAnnotations;

  TerminalEditorProvider() {
    _seedTerminalStationLayout();
  }

  void setTool(EditorTool tool) {
    _tool = tool;
    if (tool != EditorTool.marqueeSelect) {
      _marqueeRect = null;
      _marqueeStart = null;
    }
    notifyListeners();
  }

  void loadTerminalStationLayout() {
    _pushHistory();
    _seedTerminalStationLayout(clearHistory: false);
    notifyListeners();
  }

  void loadSimulationDefaultLayout() {
    _pushHistory();
    final layout = Map<String, dynamic>.from(
      sim.TerminalStationController.buildDefaultLayoutJson(),
    );
    _importSimulationLayout(layout);
    notifyListeners();
  }

  void loadSimulationLayoutConfiguration(LayoutConfiguration configuration) {
    _pushHistory();
    if (configuration.data.isEmpty) {
      final layout = Map<String, dynamic>.from(
        sim.TerminalStationController.buildDefaultLayoutJson(),
      );
      _importSimulationLayout(layout);
    } else {
      _importSimulationLayout(Map<String, dynamic>.from(configuration.data));
    }
    notifyListeners();
  }

  void toggleSnapToGrid() {
    _snapToGrid = !_snapToGrid;
    notifyListeners();
  }

  void toggleMagnet() {
    _magnetEnabled = !_magnetEnabled;
    notifyListeners();
  }

  void togglePanMode() {
    _panMode = !_panMode;
    notifyListeners();
  }

  void updateGridSize(double value) {
    _gridSize = value.clamp(5.0, 200.0);
    notifyListeners();
  }

  void toggleGridVisible() {
    _gridVisible = !_gridVisible;
    notifyListeners();
  }

  void updateBackgroundColor(Color color) {
    _backgroundColor = color;
    notifyListeners();
  }

  void updateRenderStyle(BuilderRenderStyle style) {
    _renderStyle = style;
    notifyListeners();
  }

  void updateLargeHitboxes(bool value) {
    _largeHitboxes = value;
    notifyListeners();
  }

  void updateHandlesFirst(bool value) {
    _handlesFirst = value;
    notifyListeners();
  }

  BuilderRenderStyle getRenderStyleFor(
      EditorComponentType type, String id) {
    return _renderOverrides[_renderKey(type, id)] ?? _renderStyle;
  }

  BuilderRenderStyle? getRenderStyleOverride(
      EditorComponentType type, String id) {
    return _renderOverrides[_renderKey(type, id)];
  }

  void setRenderStyleOverrideForSelection(BuilderRenderStyle? style) {
    if (_selection.isEmpty) return;
    _pushHistory();
    for (final selected in _selection) {
      final key = _renderKey(selected.type, selected.id);
      if (style == null) {
        _renderOverrides.remove(key);
      } else {
        _renderOverrides[key] = style;
      }
    }
    notifyListeners();
  }

  void nudgeSelection(Offset delta) {
    if (_selection.isEmpty) return;
    _pushHistory();
    _applyDeltaToSelection(delta);
    notifyListeners();
  }

  void toggleCompassVisible() {
    _compassVisible = !_compassVisible;
    notifyListeners();
  }

  void toggleGuidewayDirectionsVisible() {
    _guidewayDirectionsVisible = !_guidewayDirectionsVisible;
    notifyListeners();
  }

  void toggleAlphaGammaVisible() {
    _alphaGammaVisible = !_alphaGammaVisible;
    notifyListeners();
  }

  void selectAt(Offset position) {
    final hit = _hitTest(position);
    _selected = hit;
    _selection
      ..clear()
      ..addAll(hit == null ? const [] : [hit]);
    notifyListeners();
  }

  void toggleSelectAt(Offset position) {
    final hit = _hitTest(position);
    if (hit == null) {
      notifyListeners();
      return;
    }
    if (_selection.contains(hit)) {
      _selection.remove(hit);
      if (_selected == hit) {
        _selected = _selection.isNotEmpty ? _selection.first : null;
      }
    } else {
      _selection.add(hit);
      _selected ??= hit;
    }
    notifyListeners();
  }

  void selectById(EditorComponentType type, String id) {
    _selected = SelectedComponent(type: type, id: id);
    _selection
      ..clear()
      ..add(_selected!);
    notifyListeners();
  }

  void toggleSelectById(EditorComponentType type, String id) {
    final item = SelectedComponent(type: type, id: id);
    if (_selection.contains(item)) {
      _selection.remove(item);
      if (_selected == item) {
        _selected = _selection.isNotEmpty ? _selection.first : null;
      }
    } else {
      _selection.add(item);
      _selected ??= item;
    }
    notifyListeners();
  }

  SelectedComponent? hitTestAt(Offset position) {
    return _hitTest(position);
  }

  double gapAngleForCrossover(Crossover crossover) {
    return crossover.gapAngle == 0 ? _defaultGapAngle : crossover.gapAngle;
  }

  double gapAngleForPoint(TrackPoint point) {
    final pos = Offset(point.x, point.y);
    Crossover? nearest;
    double best = double.infinity;
    for (final crossover in _crossovers.values) {
      final dist = (Offset(crossover.x, crossover.y) - pos).distance;
      if (dist < best && dist <= 80) {
        best = dist;
        nearest = crossover;
      }
    }
    if (nearest == null) return _defaultGapAngle;
    return gapAngleForCrossover(nearest);
  }

  double gapLengthForPoint(TrackPoint point) {
    final angle = gapAngleForPoint(point).abs();
    final scale = (angle / _defaultGapAngle).clamp(0.6, 1.8);
    return _defaultGapLength * scale;
  }

  List<List<Offset>> getCrossoverRenderLines(Crossover crossover) {
    final center = Offset(crossover.x, crossover.y);
    final nearbyPoints = _points.values
        .where((point) =>
            (Offset(point.x, point.y) - center).distance <= 80)
        .toList();
    final linesFromPoints =
        _crossoverLinesFromPoints(crossover, center, nearbyPoints);
    if (linesFromPoints.isNotEmpty) return linesFromPoints;
    return _crossoverLinesFromSegments(center);
  }

  void startMarquee(Offset position) {
    _marqueeStart = position;
    _marqueeRect = Rect.fromPoints(position, position);
    notifyListeners();
  }

  void updateMarquee(Offset position) {
    if (_marqueeStart == null) return;
    _marqueeRect = Rect.fromPoints(_marqueeStart!, position);
    notifyListeners();
  }

  void endMarquee({bool additive = false}) {
    final rect = _marqueeRect;
    if (rect == null) return;
    _marqueeRect = null;
    _marqueeStart = null;
    if (rect.width.abs() < 4 && rect.height.abs() < 4) {
      selectAt(rect.center);
      return;
    }
    _selectInRect(rect, additive: additive);
    notifyListeners();
  }

  void _selectInRect(Rect rect, {bool additive = false}) {
    final normalized = Rect.fromLTRB(
      rect.left < rect.right ? rect.left : rect.right,
      rect.top < rect.bottom ? rect.top : rect.bottom,
      rect.right > rect.left ? rect.right : rect.left,
      rect.bottom > rect.top ? rect.bottom : rect.top,
    );
    final hits = <SelectedComponent>{};

    void addIf(bool hit, EditorComponentType type, String id) {
      if (hit) {
        hits.add(SelectedComponent(type: type, id: id));
      }
    }

    for (final entry in _segments.entries) {
      final seg = entry.value;
      final start = Offset(seg.startX, seg.startY);
      final end = seg.endPoint();
      final bounds = Rect.fromPoints(start, end).inflate(_hitboxRadius);
      addIf(bounds.overlaps(normalized), EditorComponentType.trackSegment, entry.key);
    }
    for (final entry in _platforms.entries) {
      final platform = entry.value;
      final left = platform.startX < platform.endX
          ? platform.startX
          : platform.endX;
      final right = platform.startX > platform.endX
          ? platform.startX
          : platform.endX;
      final bounds = Rect.fromLTRB(
        left,
        platform.y - _hitboxRadius,
        right,
        platform.y + _hitboxRadius,
      );
      addIf(bounds.overlaps(normalized), EditorComponentType.platform, entry.key);
    }

    void addPointLike(EditorComponentType type, String id, double x, double y,
        {double radius = 0}) {
      final bounds = Rect.fromCircle(
        center: Offset(x, y),
        radius: _hitboxRadius + radius,
      );
      addIf(bounds.overlaps(normalized), type, id);
    }

    for (final entry in _crossovers.entries) {
      final xo = entry.value;
      addPointLike(EditorComponentType.crossover, entry.key, xo.x, xo.y, radius: 8);
    }
    for (final entry in _points.entries) {
      final point = entry.value;
      addPointLike(EditorComponentType.point, entry.key, point.x, point.y, radius: 6);
    }
    for (final entry in _signals.entries) {
      final signal = entry.value;
      addPointLike(EditorComponentType.signal, entry.key, signal.x, signal.y, radius: 6);
    }
    for (final entry in _trainStops.entries) {
      final stop = entry.value;
      addPointLike(EditorComponentType.trainStop, entry.key, stop.x, stop.y, radius: 6);
    }
    for (final entry in _bufferStops.entries) {
      final stop = entry.value;
      addPointLike(EditorComponentType.bufferStop, entry.key, stop.x, stop.y, radius: 6);
    }
    for (final entry in _axleCounters.entries) {
      final counter = entry.value;
      addPointLike(EditorComponentType.axleCounter, entry.key, counter.x, counter.y, radius: 6);
    }
    for (final entry in _transponders.entries) {
      final transponder = entry.value;
      addPointLike(EditorComponentType.transponder, entry.key, transponder.x, transponder.y, radius: 6);
    }
    for (final entry in _wifiAntennas.entries) {
      final wifi = entry.value;
      addPointLike(EditorComponentType.wifiAntenna, entry.key, wifi.x, wifi.y, radius: 6);
    }
    for (final entry in _textAnnotations.entries) {
      final text = entry.value;
      addPointLike(EditorComponentType.textAnnotation, entry.key, text.x, text.y,
          radius: 12);
    }

    if (!additive) {
      _selection
        ..clear()
        ..addAll(hits);
    } else {
      _selection.addAll(hits);
    }

    if (_selection.isEmpty) {
      _selected = null;
    } else if (_selected == null || !_selection.contains(_selected)) {
      _selected = _selection.first;
    }
  }

  void selectOnly(EditorComponentType type, String id) {
    final item = SelectedComponent(type: type, id: id);
    _selection
      ..clear()
      ..add(item);
    _selected = item;
    notifyListeners();
  }

  void selectNext({required bool forward}) {
    final items = _selectionOrder();
    if (items.isEmpty) {
      _selected = null;
      _selection.clear();
      notifyListeners();
      return;
    }

    final currentIndex =
        _selected == null ? -1 : items.indexWhere((item) => item == _selected);
    final nextIndex = forward
        ? (currentIndex + 1) % items.length
        : (currentIndex - 1 + items.length) % items.length;
    _selected = items[nextIndex];
    _selection
      ..clear()
      ..add(_selected!);
    notifyListeners();
  }

  void clearSelection() {
    _selected = null;
    _selection.clear();
    notifyListeners();
  }


  void selectAllOfType(EditorComponentType type) {
    _selection.clear();
    switch (type) {
      case EditorComponentType.trackSegment:
        _selection.addAll(_segments.keys
            .map((id) => SelectedComponent(type: type, id: id)));
        break;
      case EditorComponentType.crossover:
        _selection.addAll(_crossovers.keys
            .map((id) => SelectedComponent(type: type, id: id)));
        break;
      case EditorComponentType.point:
        _selection.addAll(_points.keys
            .map((id) => SelectedComponent(type: type, id: id)));
        break;
      case EditorComponentType.signal:
        _selection.addAll(_signals.keys
            .map((id) => SelectedComponent(type: type, id: id)));
        break;
      case EditorComponentType.platform:
        _selection.addAll(_platforms.keys
            .map((id) => SelectedComponent(type: type, id: id)));
        break;
      case EditorComponentType.trainStop:
        _selection.addAll(_trainStops.keys
            .map((id) => SelectedComponent(type: type, id: id)));
        break;
      case EditorComponentType.bufferStop:
        _selection.addAll(_bufferStops.keys
            .map((id) => SelectedComponent(type: type, id: id)));
        break;
      case EditorComponentType.axleCounter:
        _selection.addAll(_axleCounters.keys
            .map((id) => SelectedComponent(type: type, id: id)));
        break;
      case EditorComponentType.transponder:
        _selection.addAll(_transponders.keys
            .map((id) => SelectedComponent(type: type, id: id)));
        break;
      case EditorComponentType.wifiAntenna:
        _selection.addAll(_wifiAntennas.keys
            .map((id) => SelectedComponent(type: type, id: id)));
        break;
      case EditorComponentType.textAnnotation:
        _selection.addAll(_textAnnotations.keys
            .map((id) => SelectedComponent(type: type, id: id)));
        break;
    }
    _selected = _selection.isNotEmpty ? _selection.first : null;
    notifyListeners();
  }

  void updateSelectedPosition({double? x, double? y}) {
    if (_selection.length != 1 || _selected == null) return;
    _pushHistory();
    final selected = _selected!;
    switch (selected.type) {
      case EditorComponentType.trackSegment:
        final segment = _segments[selected.id];
        if (segment == null) return;
        final dx = x != null ? x - segment.startX : 0.0;
        final dy = y != null ? y - segment.startY : 0.0;
        _segments[selected.id] = segment.copyWith(
          startX: segment.startX + dx,
          startY: segment.startY + dy,
        );
        _applyMagnetToSegment(selected.id);
        break;
      case EditorComponentType.crossover:
        final xo = _crossovers[selected.id];
        if (xo == null) return;
        _crossovers[selected.id] = xo.copyWith(
          x: x ?? xo.x,
          y: y ?? xo.y,
        );
        break;
      case EditorComponentType.point:
        final point = _points[selected.id];
        if (point == null) return;
        _points[selected.id] = point.copyWith(
          x: x ?? point.x,
          y: y ?? point.y,
        );
        break;
      case EditorComponentType.signal:
        final signal = _signals[selected.id];
        if (signal == null) return;
        _signals[selected.id] = signal.copyWith(
          x: x ?? signal.x,
          y: y ?? signal.y,
        );
        break;
      case EditorComponentType.platform:
        final platform = _platforms[selected.id];
        if (platform == null) return;
        final currentCenter = (platform.startX + platform.endX) / 2;
        final newCenter = x ?? currentCenter;
        final delta = newCenter - currentCenter;
        _platforms[selected.id] = platform.copyWith(
          startX: platform.startX + delta,
          endX: platform.endX + delta,
          y: y ?? platform.y,
        );
        break;
      case EditorComponentType.trainStop:
        final stop = _trainStops[selected.id];
        if (stop == null) return;
        _trainStops[selected.id] = stop.copyWith(
          x: x ?? stop.x,
          y: y ?? stop.y,
        );
        break;
      case EditorComponentType.bufferStop:
        final stop = _bufferStops[selected.id];
        if (stop == null) return;
        _bufferStops[selected.id] = stop.copyWith(
          x: x ?? stop.x,
          y: y ?? stop.y,
        );
        break;
      case EditorComponentType.axleCounter:
        final counter = _axleCounters[selected.id];
        if (counter == null) return;
        _axleCounters[selected.id] = counter.copyWith(
          x: x ?? counter.x,
          y: y ?? counter.y,
        );
        break;
      case EditorComponentType.transponder:
        final transponder = _transponders[selected.id];
        if (transponder == null) return;
        _transponders[selected.id] = transponder.copyWith(
          x: x ?? transponder.x,
          y: y ?? transponder.y,
        );
        break;
      case EditorComponentType.wifiAntenna:
        final wifi = _wifiAntennas[selected.id];
        if (wifi == null) return;
        _wifiAntennas[selected.id] = wifi.copyWith(
          x: x ?? wifi.x,
          y: y ?? wifi.y,
        );
        break;
      case EditorComponentType.textAnnotation:
        final text = _textAnnotations[selected.id];
        if (text == null) return;
        _textAnnotations[selected.id] = text.copyWith(
          x: x ?? text.x,
          y: y ?? text.y,
        );
        break;
    }
    notifyListeners();
  }

  void addAt(Offset position) {
    final snapped = _snapOffset(position);
    switch (_tool) {
      case EditorTool.addTrackStraight:
        _pushHistory();
        _addTrackSegment(snapped, angleDeg: _inheritAngle());
        break;
      case EditorTool.addTrackBendLeft:
        _pushHistory();
        _addTrackSegment(snapped, angleDeg: _inheritAngle() - 45);
        break;
      case EditorTool.addTrackBendRight:
        _pushHistory();
        _addTrackSegment(snapped, angleDeg: _inheritAngle() + 45);
        break;
      case EditorTool.addTrackCurveOctagon:
        _pushHistory();
        _addOctagonCurve(snapped, _inheritAngle());
        break;
      case EditorTool.addCrossoverRight:
        _pushHistory();
        _addCrossover(snapped, CrossoverType.righthand);
        break;
      case EditorTool.addCrossoverLeft:
        _pushHistory();
        _addCrossover(snapped, CrossoverType.lefthand);
        break;
      case EditorTool.addCrossoverDiamond:
        _pushHistory();
        _addCrossover(snapped, CrossoverType.doubleDiamond);
        break;
      case EditorTool.addPoint:
        _pushHistory();
        _addPoint(snapped);
        break;
      case EditorTool.addSignal:
        _pushHistory();
        _addSignal(snapped);
        break;
      case EditorTool.addPlatform:
        _pushHistory();
        _addPlatform(snapped);
        break;
      case EditorTool.addTrainStop:
        _pushHistory();
        _addTrainStop(snapped);
        break;
      case EditorTool.addBufferStop:
        _pushHistory();
        _addBufferStop(snapped);
        break;
      case EditorTool.addAxleCounter:
        _pushHistory();
        _addAxleCounter(snapped);
        break;
      case EditorTool.addTransponder:
        _pushHistory();
        _addTransponder(snapped);
        break;
      case EditorTool.addWifiAntenna:
        _pushHistory();
        _addWifiAntenna(snapped);
        break;
      case EditorTool.addText:
        _pushHistory();
        _addText(snapped);
        break;
      case EditorTool.select:
      case EditorTool.marqueeSelect:
      case EditorTool.move:
        break;
    }
  }

  void startDrag(Offset position) {
    if (!_pendingHistory) {
      _pushHistory();
      _pendingHistory = true;
    }
    _isDragging = true;
    _dragStart = position;
    _draggingActive = false;
    notifyListeners();
  }

  void updateDrag(Offset position) {
    if (!_isDragging || _selected == null) return;
    final snapped = _snapOffset(position);
    if (!_draggingActive && _dragStart != null) {
      if ((snapped - _dragStart!).distance < _dragThreshold) {
        return;
      }
      _draggingActive = true;
    }

    switch (_selected!.type) {
      case EditorComponentType.trackSegment:
        _dragSegment(snapped);
        break;
      case EditorComponentType.platform:
        _dragPlatform(snapped);
        break;
      case EditorComponentType.crossover:
        _updateCrossover(snapped);
        break;
      case EditorComponentType.point:
        _updatePoint(snapped);
        break;
      case EditorComponentType.signal:
        _updateSignal(snapped);
        break;
      case EditorComponentType.trainStop:
        _updateTrainStop(snapped);
        break;
      case EditorComponentType.bufferStop:
        _updateBufferStop(snapped);
        break;
      case EditorComponentType.axleCounter:
        _updateAxleCounter(snapped);
        break;
      case EditorComponentType.transponder:
        _updateTransponder(snapped);
        break;
      case EditorComponentType.wifiAntenna:
        _updateWifi(snapped);
        break;
      case EditorComponentType.textAnnotation:
        _updateText(snapped);
        break;
    }
  }

  void endDrag() {
    _isDragging = false;
    _draggingActive = false;
    _resizeHandle = null;
    _dragStart = null;
    _pendingHistory = false;
    notifyListeners();
  }

  void deleteSelected() {
    if (_selection.isEmpty) return;
    _pushHistory();
    for (final selected in _selection) {
      switch (selected.type) {
        case EditorComponentType.trackSegment:
          _segments.remove(selected.id);
          break;
        case EditorComponentType.crossover:
          _crossovers.remove(selected.id);
          break;
        case EditorComponentType.point:
          _points.remove(selected.id);
          break;
        case EditorComponentType.signal:
          _signals.remove(selected.id);
          break;
        case EditorComponentType.platform:
          _platforms.remove(selected.id);
          break;
        case EditorComponentType.trainStop:
          _trainStops.remove(selected.id);
          break;
        case EditorComponentType.bufferStop:
          _bufferStops.remove(selected.id);
          break;
        case EditorComponentType.axleCounter:
          _axleCounters.remove(selected.id);
          break;
        case EditorComponentType.transponder:
          _transponders.remove(selected.id);
          break;
        case EditorComponentType.wifiAntenna:
          _wifiAntennas.remove(selected.id);
          break;
        case EditorComponentType.textAnnotation:
          _textAnnotations.remove(selected.id);
          break;
      }
      _renderOverrides.remove(_renderKey(selected.type, selected.id));
    }
    _selected = null;
    _selection.clear();
    notifyListeners();
  }

  void _importSimulationLayout(Map<String, dynamic> data) {
    _segments.clear();
    _crossovers.clear();
    _points.clear();
    _signals.clear();
    _platforms.clear();
    _trainStops.clear();
    _bufferStops.clear();
    _axleCounters.clear();
    _transponders.clear();
    _wifiAntennas.clear();
    _textAnnotations.clear();

    final blocks = data['blocks'] as List? ?? const [];
    for (final blockJson in blocks) {
      final block = blockJson as Map<String, dynamic>;
      final id = block['id'] as String;
      final startX = (block['startX'] as num).toDouble();
      final endX = (block['endX'] as num).toDouble();
      final startY = (block['y'] as num).toDouble();
      final endY = (block['endY'] as num?)?.toDouble() ?? startY;
      final dx = endX - startX;
      final dy = endY - startY;
      final length = math.sqrt(dx * dx + dy * dy);
      final angleDeg =
          length == 0 ? 0.0 : math.atan2(dy, dx) * 180.0 / math.pi;
      _segments[id] = TrackSegment(
        id: id,
        name: block['name'] as String? ?? id,
        description: '',
        notes: '',
        color: const Color(0xFF2E86AB),
        style: TrackStyle.ballast,
        guidewayDirection: GuidewayDirection.gd1,
        startX: startX,
        startY: startY,
        length: length,
        angleDeg: angleDeg,
        occupied: block['occupied'] as bool? ?? false,
      );
    }

    final points = data['points'] as List? ?? const [];
    for (final pointJson in points) {
      final point = pointJson as Map<String, dynamic>;
      final id = point['id'] as String;
      _points[id] = TrackPoint(
        id: id,
        name: point['name'] as String? ?? id,
        description: '',
        notes: '',
        color: const Color(0xFF2A9D8F),
        x: (point['x'] as num).toDouble(),
        y: (point['y'] as num).toDouble(),
        position: _parsePointPosition(point['position']),
        locked: point['locked'] as bool? ?? false,
        style: PointStyle.classic,
        orientation: PointOrientation.upRight,
        autoDetectOrientation: false,
      );
    }

    final signals = data['signals'] as List? ?? const [];
    for (final signalJson in signals) {
      final signal = signalJson as Map<String, dynamic>;
      final id = signal['id'] as String;
      _signals[id] = Signal(
        id: id,
        name: id,
        description: '',
        notes: '',
        color: const Color(0xFFE63946),
        x: (signal['x'] as num).toDouble(),
        y: (signal['y'] as num).toDouble(),
        direction: _parseSignalDirection(signal['direction']),
        aspect: _parseSignalAspect(signal['aspect']),
      );
    }

    final platforms = data['platforms'] as List? ?? const [];
    for (final platformJson in platforms) {
      final platform = platformJson as Map<String, dynamic>;
      final id = platform['id'] as String;
      _platforms[id] = Platform(
        id: id,
        name: platform['name'] as String? ?? id,
        description: '',
        notes: '',
        color: const Color(0xFF6D597A),
        startX: (platform['startX'] as num).toDouble(),
        endX: (platform['endX'] as num).toDouble(),
        y: (platform['y'] as num).toDouble(),
      );
    }

    final trainStops = data['trainStops'] as List? ?? const [];
    for (final stopJson in trainStops) {
      final stop = stopJson as Map<String, dynamic>;
      final id = stop['id'] as String;
      final enabled = stop['enabled'] as bool? ?? stop['active'] as bool? ?? true;
      _trainStops[id] = TrainStop(
        id: id,
        name: id,
        description: '',
        notes: '',
        color: const Color(0xFFF4A261),
        x: (stop['x'] as num).toDouble(),
        y: (stop['y'] as num).toDouble(),
        enabled: enabled,
      );
    }

    final bufferStops = data['bufferStops'] as List? ?? const [];
    for (final stopJson in bufferStops) {
      final stop = stopJson as Map<String, dynamic>;
      final id = stop['id'] as String;
      _bufferStops[id] = BufferStop(
        id: id,
        name: id,
        description: '',
        notes: '',
        color: const Color(0xFFB00020),
        x: (stop['x'] as num).toDouble(),
        y: (stop['y'] as num).toDouble(),
      );
    }

    final axleCounters = data['axleCounters'] as List? ?? const [];
    for (final counterJson in axleCounters) {
      final counter = counterJson as Map<String, dynamic>;
      final id = counter['id'] as String;
      _axleCounters[id] = AxleCounter(
        id: id,
        name: id,
        description: '',
        notes: '',
        color: const Color(0xFF457B9D),
        x: (counter['x'] as num).toDouble(),
        y: (counter['y'] as num).toDouble(),
        flipped: counter['flipped'] as bool? ?? false,
      );
    }

    final transponders = data['transponders'] as List? ?? const [];
    for (final transponderJson in transponders) {
      final transponder = transponderJson as Map<String, dynamic>;
      final id = transponder['id'] as String;
      _transponders[id] = Transponder(
        id: id,
        name: id,
        description: transponder['description'] as String? ?? '',
        notes: '',
        color: const Color(0xFF118AB2),
        x: (transponder['x'] as num).toDouble(),
        y: (transponder['y'] as num).toDouble(),
        type: _parseTransponderType(transponder['type']),
      );
    }

    final wifiAntennas = data['wifiAntennas'] as List? ?? const [];
    for (final wifiJson in wifiAntennas) {
      final wifi = wifiJson as Map<String, dynamic>;
      final id = wifi['id'] as String;
      _wifiAntennas[id] = WifiAntenna(
        id: id,
        name: id,
        description: '',
        notes: '',
        color: const Color(0xFF06D6A0),
        x: (wifi['x'] as num).toDouble(),
        y: (wifi['y'] as num).toDouble(),
        isActive: wifi['isActive'] as bool? ?? true,
      );
    }

    final crossovers = data['crossovers'] as List? ?? const [];
    for (final crossoverJson in crossovers) {
      final crossover = crossoverJson as Map<String, dynamic>;
      final id = crossover['id'] as String;
      final pointIds =
          List<String>.from(crossover['pointIds'] as List? ?? const []);
      final position = _resolveCrossoverPosition(
        pointIds,
        crossover['blockId'] as String?,
      );
      _crossovers[id] = Crossover(
        id: id,
        name: crossover['name'] as String? ?? id,
        description: '',
        notes: '',
        color: const Color(0xFF4C566A),
        style: TrackStyle.ballast,
        x: position.dx,
        y: position.dy,
        type: _parseCrossoverType(crossover['type']),
        gapAngle: (crossover['gapAngle'] as num?)?.toDouble() ?? _defaultGapAngle,
      );
    }

    _selected = null;
  }

  String _enumName(dynamic value) {
    final raw = value?.toString() ?? '';
    if (raw.contains('.')) {
      return raw.split('.').last;
    }
    return raw;
  }

  SignalAspect _parseSignalAspect(dynamic value) {
    final name = _enumName(value);
    return SignalAspect.values.firstWhere(
      (aspect) => aspect.name == name,
      orElse: () => SignalAspect.red,
    );
  }

  SignalDirection _parseSignalDirection(dynamic value) {
    final name = _enumName(value);
    return SignalDirection.values.firstWhere(
      (dir) => dir.name == name,
      orElse: () => SignalDirection.east,
    );
  }

  PointPosition _parsePointPosition(dynamic value) {
    final name = _enumName(value);
    return PointPosition.values.firstWhere(
      (pos) => pos.name == name,
      orElse: () => PointPosition.normal,
    );
  }

  TransponderType _parseTransponderType(dynamic value) {
    final name = _enumName(value);
    if (name.toUpperCase() == 'CBTC') {
      return TransponderType.t1;
    }
    return TransponderType.values.firstWhere(
      (type) => type.name == name,
      orElse: () => TransponderType.t1,
    );
  }

  CrossoverType _parseCrossoverType(dynamic value) {
    final name = _enumName(value);
    return CrossoverType.values.firstWhere(
      (type) => type.name == name,
      orElse: () => CrossoverType.righthand,
    );
  }

  Offset _resolveCrossoverPosition(List<String> pointIds, String? blockId) {
    final points = pointIds
        .map((id) => _points[id])
        .whereType<TrackPoint>()
        .toList();
    if (points.isNotEmpty) {
      final avgX = points.fold<double>(0, (sum, p) => sum + p.x) / points.length;
      final avgY = points.fold<double>(0, (sum, p) => sum + p.y) / points.length;
      return Offset(avgX, avgY);
    }

    if (blockId != null) {
      final segment = _segments[blockId];
      if (segment != null) {
        final end = segment.endPoint();
        return Offset(
          (segment.startX + end.dx) / 2,
          (segment.startY + end.dy) / 2,
        );
      }
    }

    return Offset.zero;
  }

  void setResizeHandle(ResizeHandle? handle) {
    _resizeHandle = handle;
    notifyListeners();
  }

  void updateSignalAspect(SignalAspect aspect) {
    if (_selected?.type != EditorComponentType.signal) return;
    final signal = _signals[_selected!.id];
    if (signal == null) return;
    _pushHistory();
    _signals[_selected!.id] = signal.copyWith(aspect: aspect);
    notifyListeners();
  }

  void updateSignalDirection(SignalDirection direction) {
    if (_selected?.type != EditorComponentType.signal) return;
    final signal = _signals[_selected!.id];
    if (signal == null) return;
    _pushHistory();
    _signals[_selected!.id] = signal.copyWith(direction: direction);
    notifyListeners();
  }

  void updateSelectedTrackStyle(TrackStyle style) {
    if (_selected?.type != EditorComponentType.trackSegment) return;
    final segment = _segments[_selected!.id];
    if (segment == null) return;
    _pushHistory();
    _segments[_selected!.id] = segment.copyWith(style: style);
    notifyListeners();
  }

  void updateSelectedGuidewayDirection(GuidewayDirection direction) {
    if (_selected?.type != EditorComponentType.trackSegment) return;
    final segment = _segments[_selected!.id];
    if (segment == null) return;
    _pushHistory();
    _segments[_selected!.id] =
        segment.copyWith(guidewayDirection: direction);
    notifyListeners();
  }

  void toggleAlphaGamma(String junctionId, Offset position) {
    if (_alphaGammaJunctions.containsKey(junctionId)) {
      _alphaGammaJunctions.remove(junctionId);
    } else {
      _alphaGammaJunctions[junctionId] = position;
    }
    notifyListeners();
  }

  List<Junction> detectJunctions() {
    final endpoints = <Offset>[];
    final endpointSegments = <Offset, List<TrackSegment>>{};
    for (final segment in _segments.values) {
      final start = Offset(segment.startX, segment.startY);
      final end = segment.endPoint();
      endpoints.add(start);
      endpoints.add(end);
      endpointSegments.putIfAbsent(start, () => []).add(segment);
      endpointSegments.putIfAbsent(end, () => []).add(segment);
    }

    final junctions = <Junction>[];
    const threshold = 16.0;
    final used = <Offset>{};
    for (final endpoint in endpoints) {
      if (used.contains(endpoint)) continue;
      final cluster = endpoints
          .where((p) => (p - endpoint).distance <= threshold)
          .toList();
      if (cluster.length < 2) continue;
      used.addAll(cluster);
      final center = _clusterCenter(cluster);
      final id = _junctionId(center);
      final segments = <TrackSegment>{};
      for (final p in cluster) {
        segments.addAll(endpointSegments[p] ?? const []);
      }
      if (_isBranchingJunction(segments.toList())) {
        final isAlphaGamma = _alphaGammaJunctions.containsKey(id);
        junctions.add(Junction(id: id, position: center, isAlphaGamma: isAlphaGamma));
      }
    }

    junctions.sort((a, b) => a.id.compareTo(b.id));
    return junctions;
  }

  List<ValidationIssue> validateLayout(ValidationLevel level) {
    final issues = <ValidationIssue>[];
    const endpointThreshold = 14.0;
    const proximityThreshold = 18.0;

    final segmentList = _segments.values.toList();
    final endpoints = <_Endpoint>[];
    for (final segment in segmentList) {
      final start = Offset(segment.startX, segment.startY);
      final end = segment.endPoint();
      endpoints.add(_Endpoint(segment.id, start));
      endpoints.add(_Endpoint(segment.id, end));
    }

    if (level != ValidationLevel.low || segmentList.length <= 200) {
      for (final endpoint in endpoints) {
        final connected = _isEndpointConnected(endpoint, endpoints);
        final nearPoint =
            _nearPointToAny(endpoint.position, _points.values, proximityThreshold);
        final nearCrossover =
            _nearCrossover(endpoint.position, _crossovers.values, proximityThreshold);
        final nearBuffer =
            _nearBufferStop(endpoint.position, _bufferStops.values, proximityThreshold);
        if (!connected && !nearPoint && !nearCrossover && !nearBuffer) {
          issues.add(ValidationIssue(
            severity: ValidationSeverity.warning,
            message:
                'Unconnected track end near ${endpoint.position.dx.toStringAsFixed(1)}, ${endpoint.position.dy.toStringAsFixed(1)}',
          ));
        }
      }
    }

    if (level != ValidationLevel.low && segmentList.length <= 200) {
      for (var i = 0; i < segmentList.length; i++) {
        for (var j = i + 1; j < segmentList.length; j++) {
          if (_segmentsOverlap(segmentList[i], segmentList[j])) {
            issues.add(ValidationIssue(
              severity: ValidationSeverity.warning,
              message:
                  'Overlapping segments: ${segmentList[i].id} and ${segmentList[j].id}',
            ));
          }
        }
      }
    }

    if (level != ValidationLevel.low) {
      for (final point in _points.values) {
        if (!_nearSegment(point.x, point.y, segmentList, proximityThreshold)) {
          issues.add(ValidationIssue(
            severity: ValidationSeverity.warning,
            message: 'Point ${point.id} is not on a track',
          ));
        }
      }

      for (final signal in _signals.values) {
        if (!_nearSegment(signal.x, signal.y, segmentList, proximityThreshold)) {
          issues.add(ValidationIssue(
            severity: ValidationSeverity.warning,
            message: 'Signal ${signal.id} is not near a track',
          ));
        }
      }

      for (final stop in _trainStops.values) {
        if (!_nearSignal(stop.x, stop.y, _signals.values, 35)) {
          issues.add(ValidationIssue(
            severity: ValidationSeverity.warning,
            message: 'Train stop ${stop.id} is not near a signal',
          ));
        }
      }
    }

    if (level != ValidationLevel.low) {
      for (final stop in _bufferStops.values) {
        final nearEndpoint = endpoints.any((endpoint) =>
            (endpoint.position - Offset(stop.x, stop.y)).distance <= proximityThreshold);
        if (!nearEndpoint) {
          issues.add(ValidationIssue(
            severity: ValidationSeverity.warning,
            message: 'Buffer stop ${stop.id} is not near a track end',
          ));
        }
      }
    }

    if (level == ValidationLevel.high) {
      for (final segment in segmentList) {
        final dx = segment.endPoint().dx - segment.startX;
        final dy = segment.endPoint().dy - segment.startY;
        final orientation = _dominantOrientation(dx, dy);
        final dirOk = segment.guidewayDirection == GuidewayDirection.gd1
            ? (orientation == _AxisOrientation.east ||
                orientation == _AxisOrientation.north)
            : (orientation == _AxisOrientation.west ||
                orientation == _AxisOrientation.south);
        if (!dirOk) {
          issues.add(ValidationIssue(
            severity: ValidationSeverity.info,
            message:
                'Guideway direction on ${segment.id} looks opposite to its axis',
          ));
        }
      }

      for (final point in _points.values) {
        if (!_hasBranchingSegments(point)) {
          issues.add(ValidationIssue(
            severity: ValidationSeverity.warning,
            message:
                'Point ${point.id} is not near a branching track pair',
          ));
        }
      }

      for (final crossover in _crossovers.values) {
        final requiredPoints =
            crossover.type == CrossoverType.doubleDiamond ? 4 : 2;
        final nearbyPoints = _points.values.where((point) {
          return (Offset(point.x, point.y) - Offset(crossover.x, crossover.y))
                  .distance <=
              60;
        }).length;
        if (nearbyPoints < requiredPoints) {
          issues.add(ValidationIssue(
            severity: ValidationSeverity.warning,
            message:
                'Crossover ${crossover.id} has only $nearbyPoints nearby points',
          ));
        }
      }

      final signalsList = _signals.values.toList();
      for (var i = 0; i < signalsList.length; i++) {
        for (var j = i + 1; j < signalsList.length; j++) {
          if ((signalsList[i].y - signalsList[j].y).abs() < 25 &&
              (signalsList[i].x - signalsList[j].x).abs() < 80) {
            issues.add(ValidationIssue(
              severity: ValidationSeverity.warning,
              message:
                  'Signals ${signalsList[i].id} and ${signalsList[j].id} are too close',
            ));
          }
        }
      }
    }

    if (issues.isEmpty) {
      issues.add(ValidationIssue(
        severity: ValidationSeverity.info,
        message: 'No issues detected. Layout is ready for train movement.',
      ));
    }

    return issues;
  }

  void updateSelectedCrossoverStyle(TrackStyle style) {
    if (_selected?.type != EditorComponentType.crossover) return;
    final crossover = _crossovers[_selected!.id];
    if (crossover == null) return;
    _pushHistory();
    _crossovers[_selected!.id] = crossover.copyWith(style: style);
    notifyListeners();
  }

  void updateSelectedCrossoverGapAngle(double angle) {
    if (_selected?.type != EditorComponentType.crossover) return;
    final crossover = _crossovers[_selected!.id];
    if (crossover == null) return;
    final clamped = angle.clamp(1.0, 60.0);
    _pushHistory();
    _crossovers[_selected!.id] = crossover.copyWith(gapAngle: clamped);
    notifyListeners();
  }

  void updateSelectedName(String name) {
    if (_selected == null) return;
    switch (_selected!.type) {
      case EditorComponentType.trackSegment:
        final item = _segments[_selected!.id];
        if (item == null) return;
        _pushHistory();
        _segments[_selected!.id] = item.copyWith(name: name);
        break;
      case EditorComponentType.crossover:
        final item = _crossovers[_selected!.id];
        if (item == null) return;
        _pushHistory();
        _crossovers[_selected!.id] = item.copyWith(name: name);
        break;
      case EditorComponentType.point:
        final item = _points[_selected!.id];
        if (item == null) return;
        _pushHistory();
        _points[_selected!.id] = item.copyWith(name: name);
        break;
      case EditorComponentType.signal:
        final item = _signals[_selected!.id];
        if (item == null) return;
        _pushHistory();
        _signals[_selected!.id] = item.copyWith(name: name);
        break;
      case EditorComponentType.platform:
        final item = _platforms[_selected!.id];
        if (item == null) return;
        _pushHistory();
        _platforms[_selected!.id] = item.copyWith(name: name);
        break;
      case EditorComponentType.trainStop:
        final item = _trainStops[_selected!.id];
        if (item == null) return;
        _pushHistory();
        _trainStops[_selected!.id] = item.copyWith(name: name);
        break;
      case EditorComponentType.bufferStop:
        final item = _bufferStops[_selected!.id];
        if (item == null) return;
        _pushHistory();
        _bufferStops[_selected!.id] = item.copyWith(name: name);
        break;
      case EditorComponentType.axleCounter:
        final item = _axleCounters[_selected!.id];
        if (item == null) return;
        _pushHistory();
        _axleCounters[_selected!.id] = item.copyWith(name: name);
        break;
      case EditorComponentType.transponder:
        final item = _transponders[_selected!.id];
        if (item == null) return;
        _pushHistory();
        _transponders[_selected!.id] = item.copyWith(name: name);
        break;
      case EditorComponentType.wifiAntenna:
        final item = _wifiAntennas[_selected!.id];
        if (item == null) return;
        _pushHistory();
        _wifiAntennas[_selected!.id] = item.copyWith(name: name);
        break;
      case EditorComponentType.textAnnotation:
        final item = _textAnnotations[_selected!.id];
        if (item == null) return;
        _pushHistory();
        _textAnnotations[_selected!.id] = item.copyWith(name: name);
        break;
    }
    notifyListeners();
  }

  void updateSelectedColor(Color color) {
    if (_selected == null) return;
    _pushHistory();
    switch (_selected!.type) {
      case EditorComponentType.trackSegment:
        final item = _segments[_selected!.id];
        if (item == null) return;
        _segments[_selected!.id] = item.copyWith(color: color);
        break;
      case EditorComponentType.crossover:
        final item = _crossovers[_selected!.id];
        if (item == null) return;
        _crossovers[_selected!.id] = item.copyWith(color: color);
        break;
      case EditorComponentType.point:
        final item = _points[_selected!.id];
        if (item == null) return;
        _points[_selected!.id] = item.copyWith(color: color);
        break;
      case EditorComponentType.signal:
        final item = _signals[_selected!.id];
        if (item == null) return;
        _signals[_selected!.id] = item.copyWith(color: color);
        break;
      case EditorComponentType.platform:
        final item = _platforms[_selected!.id];
        if (item == null) return;
        _platforms[_selected!.id] = item.copyWith(color: color);
        break;
      case EditorComponentType.trainStop:
        final item = _trainStops[_selected!.id];
        if (item == null) return;
        _trainStops[_selected!.id] = item.copyWith(color: color);
        break;
      case EditorComponentType.bufferStop:
        final item = _bufferStops[_selected!.id];
        if (item == null) return;
        _bufferStops[_selected!.id] = item.copyWith(color: color);
        break;
      case EditorComponentType.axleCounter:
        final item = _axleCounters[_selected!.id];
        if (item == null) return;
        _axleCounters[_selected!.id] = item.copyWith(color: color);
        break;
      case EditorComponentType.transponder:
        final item = _transponders[_selected!.id];
        if (item == null) return;
        _transponders[_selected!.id] = item.copyWith(color: color);
        break;
      case EditorComponentType.wifiAntenna:
        final item = _wifiAntennas[_selected!.id];
        if (item == null) return;
        _wifiAntennas[_selected!.id] = item.copyWith(color: color);
        break;
      case EditorComponentType.textAnnotation:
        final item = _textAnnotations[_selected!.id];
        if (item == null) return;
        _textAnnotations[_selected!.id] = item.copyWith(color: color);
        break;
    }
    notifyListeners();
  }

  void updateSelectedDescription(String description) {
    if (_selected == null) return;
    _pushHistory();
    _updateSelectedMetadata(description: description);
  }

  void updateSelectedNotes(String notes) {
    if (_selected == null) return;
    _pushHistory();
    _updateSelectedMetadata(notes: notes);
  }

  void updateSelectedText(String text) {
    if (_selected?.type != EditorComponentType.textAnnotation) return;
    final item = _textAnnotations[_selected!.id];
    if (item == null) return;
    _pushHistory();
    _textAnnotations[_selected!.id] = item.copyWith(text: text);
    notifyListeners();
  }

  bool renameSelectedId(String newId) {
    if (_selected == null) return false;
    if (newId.trim().isEmpty) return false;
    if (_idExistsForType(_selected!.type, newId)) return false;

    _pushHistory();
    switch (_selected!.type) {
      case EditorComponentType.trackSegment:
        final item = _segments.remove(_selected!.id);
        if (item == null) return false;
        _segments[newId] = item.copyWith(id: newId, name: item.name);
        break;
      case EditorComponentType.crossover:
        final item = _crossovers.remove(_selected!.id);
        if (item == null) return false;
        _crossovers[newId] = item.copyWith(id: newId, name: item.name);
        break;
      case EditorComponentType.point:
        final item = _points.remove(_selected!.id);
        if (item == null) return false;
        _points[newId] = item.copyWith(id: newId, name: item.name);
        break;
      case EditorComponentType.signal:
        final item = _signals.remove(_selected!.id);
        if (item == null) return false;
        _signals[newId] = item.copyWith(id: newId, name: item.name);
        break;
      case EditorComponentType.platform:
        final item = _platforms.remove(_selected!.id);
        if (item == null) return false;
        _platforms[newId] = item.copyWith(id: newId, name: item.name);
        break;
      case EditorComponentType.trainStop:
        final item = _trainStops.remove(_selected!.id);
        if (item == null) return false;
        _trainStops[newId] = item.copyWith(id: newId, name: item.name);
        break;
      case EditorComponentType.bufferStop:
        final item = _bufferStops.remove(_selected!.id);
        if (item == null) return false;
        _bufferStops[newId] = item.copyWith(id: newId, name: item.name);
        break;
      case EditorComponentType.axleCounter:
        final item = _axleCounters.remove(_selected!.id);
        if (item == null) return false;
        _axleCounters[newId] = item.copyWith(id: newId, name: item.name);
        break;
      case EditorComponentType.transponder:
        final item = _transponders.remove(_selected!.id);
        if (item == null) return false;
        _transponders[newId] = item.copyWith(id: newId, name: item.name);
        break;
      case EditorComponentType.wifiAntenna:
        final item = _wifiAntennas.remove(_selected!.id);
        if (item == null) return false;
        _wifiAntennas[newId] = item.copyWith(id: newId, name: item.name);
        break;
      case EditorComponentType.textAnnotation:
        final item = _textAnnotations.remove(_selected!.id);
        if (item == null) return false;
        _textAnnotations[newId] = item.copyWith(id: newId, name: item.name);
        break;
    }
    _selected = SelectedComponent(type: _selected!.type, id: newId);
    notifyListeners();
    return true;
  }

  void updatePointPosition(PointPosition position) {
    if (_selected?.type != EditorComponentType.point) return;
    final point = _points[_selected!.id];
    if (point == null) return;
    _pushHistory();
    _points[_selected!.id] = point.copyWith(position: position);
    notifyListeners();
  }

  void updatePointStyle(PointStyle style) {
    if (_selected?.type != EditorComponentType.point) return;
    final point = _points[_selected!.id];
    if (point == null) return;
    _pushHistory();
    _points[_selected!.id] = point.copyWith(style: style);
    notifyListeners();
  }

  void updatePointOrientation(PointOrientation orientation) {
    if (_selected?.type != EditorComponentType.point) return;
    final point = _points[_selected!.id];
    if (point == null) return;
    _pushHistory();
    _points[_selected!.id] = point.copyWith(orientation: orientation);
    notifyListeners();
  }

  void togglePointAutoDetectOrientation() {
    if (_selected?.type != EditorComponentType.point) return;
    final point = _points[_selected!.id];
    if (point == null) return;
    _pushHistory();
    final enabled = !point.autoDetectOrientation;
    final orientation = enabled
        ? _detectPointOrientation(point.x, point.y, point.orientation)
        : point.orientation;
    _points[_selected!.id] = point.copyWith(
      autoDetectOrientation: enabled,
      orientation: orientation,
    );
    notifyListeners();
  }

  void toggleWifiActive() {
    if (_selected?.type != EditorComponentType.wifiAntenna) return;
    final wifi = _wifiAntennas[_selected!.id];
    if (wifi == null) return;
    _pushHistory();
    _wifiAntennas[_selected!.id] = wifi.copyWith(isActive: !wifi.isActive);
    notifyListeners();
  }

  void toggleAxleCounterFlipped() {
    if (_selected?.type != EditorComponentType.axleCounter) return;
    final counter = _axleCounters[_selected!.id];
    if (counter == null) return;
    _pushHistory();
    _axleCounters[_selected!.id] = counter.copyWith(flipped: !counter.flipped);
    notifyListeners();
  }

  void _updateSelectedMetadata({String? description, String? notes}) {
    switch (_selected!.type) {
      case EditorComponentType.trackSegment:
        final item = _segments[_selected!.id];
        if (item == null) return;
        _segments[_selected!.id] =
            item.copyWith(description: description ?? item.description, notes: notes ?? item.notes);
        break;
      case EditorComponentType.crossover:
        final item = _crossovers[_selected!.id];
        if (item == null) return;
        _crossovers[_selected!.id] =
            item.copyWith(description: description ?? item.description, notes: notes ?? item.notes);
        break;
      case EditorComponentType.point:
        final item = _points[_selected!.id];
        if (item == null) return;
        _points[_selected!.id] =
            item.copyWith(description: description ?? item.description, notes: notes ?? item.notes);
        break;
      case EditorComponentType.signal:
        final item = _signals[_selected!.id];
        if (item == null) return;
        _signals[_selected!.id] =
            item.copyWith(description: description ?? item.description, notes: notes ?? item.notes);
        break;
      case EditorComponentType.platform:
        final item = _platforms[_selected!.id];
        if (item == null) return;
        _platforms[_selected!.id] =
            item.copyWith(description: description ?? item.description, notes: notes ?? item.notes);
        break;
      case EditorComponentType.trainStop:
        final item = _trainStops[_selected!.id];
        if (item == null) return;
        _trainStops[_selected!.id] =
            item.copyWith(description: description ?? item.description, notes: notes ?? item.notes);
        break;
      case EditorComponentType.bufferStop:
        final item = _bufferStops[_selected!.id];
        if (item == null) return;
        _bufferStops[_selected!.id] =
            item.copyWith(description: description ?? item.description, notes: notes ?? item.notes);
        break;
      case EditorComponentType.axleCounter:
        final item = _axleCounters[_selected!.id];
        if (item == null) return;
        _axleCounters[_selected!.id] =
            item.copyWith(description: description ?? item.description, notes: notes ?? item.notes);
        break;
      case EditorComponentType.transponder:
        final item = _transponders[_selected!.id];
        if (item == null) return;
        _transponders[_selected!.id] =
            item.copyWith(description: description ?? item.description, notes: notes ?? item.notes);
        break;
      case EditorComponentType.wifiAntenna:
        final item = _wifiAntennas[_selected!.id];
        if (item == null) return;
        _wifiAntennas[_selected!.id] =
            item.copyWith(description: description ?? item.description, notes: notes ?? item.notes);
        break;
      case EditorComponentType.textAnnotation:
        final item = _textAnnotations[_selected!.id];
        if (item == null) return;
        _textAnnotations[_selected!.id] =
            item.copyWith(description: description ?? item.description, notes: notes ?? item.notes);
        break;
    }
    notifyListeners();
  }

  ResizeHandle? hitTestHandle(Offset position) {
    if (_selection.length != 1) return null;
    if (_selected?.type == EditorComponentType.trackSegment) {
      final segment = _segments[_selected!.id];
      if (segment == null) return null;
      final start = Offset(segment.startX, segment.startY);
      final end = segment.endPoint();
      if (_nearPoint(position, start, _hitboxRadius)) {
        return ResizeHandle.start;
      }
      if (_nearPoint(position, end, _hitboxRadius)) {
        return ResizeHandle.end;
      }
    }

    if (_selected?.type == EditorComponentType.platform) {
      final platform = _platforms[_selected!.id];
      if (platform == null) return null;
      if (_nearPoint(position, Offset(platform.startX, platform.y), _hitboxRadius)) {
        return ResizeHandle.start;
      }
      if (_nearPoint(position, Offset(platform.endX, platform.y), _hitboxRadius)) {
        return ResizeHandle.end;
      }
    }

    return null;
  }

  void _dragSegment(Offset position) {
    final segment = _segments[_selected!.id];
    if (segment == null) return;
    final end = segment.endPoint();
    if (_resizeHandle != null) {
      if (_resizeHandle == ResizeHandle.start) {
        final newStart = position;
        final dx = end.dx - newStart.dx;
        final dy = end.dy - newStart.dy;
        final length = math.sqrt(dx * dx + dy * dy);
        final angle = math.atan2(dy, dx) * 180.0 / math.pi;
        _segments[_selected!.id] = segment.copyWith(
          startX: newStart.dx,
          startY: newStart.dy,
          length: length,
          angleDeg: angle,
        );
      } else {
        final dx = position.dx - segment.startX;
        final dy = position.dy - segment.startY;
        final length = math.sqrt(dx * dx + dy * dy);
        final angle = math.atan2(dy, dx) * 180.0 / math.pi;
        _segments[_selected!.id] = segment.copyWith(
          length: length,
          angleDeg: angle,
        );
      }
      _applyMagnetToSegment(_selected!.id);
      notifyListeners();
      return;
    }

    if (_dragStart == null) return;
    final delta = position - _dragStart!;
    _dragStart = position;
    if (_selection.length > 1) {
      _applyDeltaToSelection(delta);
      notifyListeners();
      return;
    }
    _segments[_selected!.id] = segment.copyWith(
      startX: segment.startX + delta.dx,
      startY: segment.startY + delta.dy,
    );
    _applyMagnetToSegment(_selected!.id);
    notifyListeners();
  }

  void _dragPlatform(Offset position) {
    final platform = _platforms[_selected!.id];
    if (platform == null) return;
    if (_resizeHandle != null) {
      if (_resizeHandle == ResizeHandle.start) {
        _platforms[_selected!.id] = platform.copyWith(startX: position.dx);
      } else {
        _platforms[_selected!.id] = platform.copyWith(endX: position.dx);
      }
      notifyListeners();
      return;
    }

    if (_dragStart == null) return;
    final delta = position - _dragStart!;
    _dragStart = position;
    if (_selection.length > 1) {
      _applyDeltaToSelection(delta);
      notifyListeners();
      return;
    }
    _platforms[_selected!.id] = platform.copyWith(
      startX: platform.startX + delta.dx,
      endX: platform.endX + delta.dx,
      y: platform.y + delta.dy,
    );
    notifyListeners();
  }

  void _updateCrossover(Offset position) {
    final xo = _crossovers[_selected!.id];
    if (xo == null) return;
    _crossovers[_selected!.id] = xo.copyWith(x: position.dx, y: position.dy);
    notifyListeners();
  }

  void _updatePoint(Offset position) {
    final point = _points[_selected!.id];
    if (point == null) return;
    var updated = point.copyWith(x: position.dx, y: position.dy);
    if (updated.autoDetectOrientation) {
      final orientation =
          _detectPointOrientation(position.dx, position.dy, updated.orientation);
      updated = updated.copyWith(orientation: orientation);
    }
    _points[_selected!.id] = updated;
    notifyListeners();
  }

  void _updateSignal(Offset position) {
    final signal = _signals[_selected!.id];
    if (signal == null) return;
    _signals[_selected!.id] = signal.copyWith(x: position.dx, y: position.dy);
    notifyListeners();
  }

  void _updateTrainStop(Offset position) {
    final stop = _trainStops[_selected!.id];
    if (stop == null) return;
    _trainStops[_selected!.id] = stop.copyWith(x: position.dx, y: position.dy);
    notifyListeners();
  }

  void _updateBufferStop(Offset position) {
    final stop = _bufferStops[_selected!.id];
    if (stop == null) return;
    _bufferStops[_selected!.id] = stop.copyWith(x: position.dx, y: position.dy);
    notifyListeners();
  }

  void _updateAxleCounter(Offset position) {
    final counter = _axleCounters[_selected!.id];
    if (counter == null) return;
    _axleCounters[_selected!.id] =
        counter.copyWith(x: position.dx, y: position.dy);
    notifyListeners();
  }

  void _updateTransponder(Offset position) {
    final transponder = _transponders[_selected!.id];
    if (transponder == null) return;
    _transponders[_selected!.id] =
        transponder.copyWith(x: position.dx, y: position.dy);
    notifyListeners();
  }

  void _updateWifi(Offset position) {
    final wifi = _wifiAntennas[_selected!.id];
    if (wifi == null) return;
    _wifiAntennas[_selected!.id] = wifi.copyWith(x: position.dx, y: position.dy);
    notifyListeners();
  }

  void _updateText(Offset position) {
    final text = _textAnnotations[_selected!.id];
    if (text == null) return;
    _textAnnotations[_selected!.id] = text.copyWith(x: position.dx, y: position.dy);
    notifyListeners();
  }

  void _applyDeltaToSelection(Offset delta) {
    for (final selected in _selection) {
      switch (selected.type) {
        case EditorComponentType.trackSegment:
          final segment = _segments[selected.id];
          if (segment != null) {
            _segments[selected.id] = segment.copyWith(
              startX: segment.startX + delta.dx,
              startY: segment.startY + delta.dy,
            );
            _applyMagnetToSegment(selected.id);
          }
          break;
        case EditorComponentType.platform:
          final platform = _platforms[selected.id];
          if (platform != null) {
            _platforms[selected.id] = platform.copyWith(
              startX: platform.startX + delta.dx,
              endX: platform.endX + delta.dx,
              y: platform.y + delta.dy,
            );
          }
          break;
        case EditorComponentType.crossover:
          final xo = _crossovers[selected.id];
          if (xo != null) {
            _crossovers[selected.id] = xo.copyWith(
              x: xo.x + delta.dx,
              y: xo.y + delta.dy,
            );
          }
          break;
        case EditorComponentType.point:
          final point = _points[selected.id];
          if (point != null) {
            _points[selected.id] =
                point.copyWith(x: point.x + delta.dx, y: point.y + delta.dy);
          }
          break;
        case EditorComponentType.signal:
          final signal = _signals[selected.id];
          if (signal != null) {
            _signals[selected.id] =
                signal.copyWith(x: signal.x + delta.dx, y: signal.y + delta.dy);
          }
          break;
        case EditorComponentType.trainStop:
          final stop = _trainStops[selected.id];
          if (stop != null) {
            _trainStops[selected.id] =
                stop.copyWith(x: stop.x + delta.dx, y: stop.y + delta.dy);
          }
          break;
        case EditorComponentType.bufferStop:
          final stop = _bufferStops[selected.id];
          if (stop != null) {
            _bufferStops[selected.id] =
                stop.copyWith(x: stop.x + delta.dx, y: stop.y + delta.dy);
          }
          break;
        case EditorComponentType.axleCounter:
          final counter = _axleCounters[selected.id];
          if (counter != null) {
            _axleCounters[selected.id] = counter.copyWith(
              x: counter.x + delta.dx,
              y: counter.y + delta.dy,
            );
          }
          break;
        case EditorComponentType.transponder:
          final transponder = _transponders[selected.id];
          if (transponder != null) {
            _transponders[selected.id] = transponder.copyWith(
              x: transponder.x + delta.dx,
              y: transponder.y + delta.dy,
            );
          }
          break;
        case EditorComponentType.wifiAntenna:
          final wifi = _wifiAntennas[selected.id];
          if (wifi != null) {
            _wifiAntennas[selected.id] =
                wifi.copyWith(x: wifi.x + delta.dx, y: wifi.y + delta.dy);
          }
          break;
        case EditorComponentType.textAnnotation:
          final text = _textAnnotations[selected.id];
          if (text != null) {
            _textAnnotations[selected.id] =
                text.copyWith(x: text.x + delta.dx, y: text.y + delta.dy);
          }
          break;
      }
    }
  }

  SelectedComponent? _hitTest(Offset position) {
    for (final entry in _signals.entries) {
      if (_nearPoint(position, Offset(entry.value.x, entry.value.y), _hitboxRadius + 6)) {
        return SelectedComponent(
          type: EditorComponentType.signal,
          id: entry.key,
        );
      }
    }

    for (final entry in _points.entries) {
      if (_nearPoint(position, Offset(entry.value.x, entry.value.y), _hitboxRadius + 2)) {
        return SelectedComponent(
          type: EditorComponentType.point,
          id: entry.key,
        );
      }
    }

    for (final entry in _trainStops.entries) {
      if (_nearPoint(position, Offset(entry.value.x, entry.value.y), _hitboxRadius + 2)) {
        return SelectedComponent(
          type: EditorComponentType.trainStop,
          id: entry.key,
        );
      }
    }

    for (final entry in _bufferStops.entries) {
      if (_nearPoint(position, Offset(entry.value.x, entry.value.y), _hitboxRadius + 2)) {
        return SelectedComponent(
          type: EditorComponentType.bufferStop,
          id: entry.key,
        );
      }
    }

    for (final entry in _axleCounters.entries) {
      if (_nearPoint(position, Offset(entry.value.x, entry.value.y), _hitboxRadius + 2)) {
        return SelectedComponent(
          type: EditorComponentType.axleCounter,
          id: entry.key,
        );
      }
    }

    for (final entry in _transponders.entries) {
      if (_nearPoint(position, Offset(entry.value.x, entry.value.y), _hitboxRadius + 2)) {
        return SelectedComponent(
          type: EditorComponentType.transponder,
          id: entry.key,
        );
      }
    }

    for (final entry in _wifiAntennas.entries) {
      if (_nearPoint(position, Offset(entry.value.x, entry.value.y), _hitboxRadius + 4)) {
        return SelectedComponent(
          type: EditorComponentType.wifiAntenna,
          id: entry.key,
        );
      }
    }

    for (final entry in _textAnnotations.entries) {
      final text = entry.value;
      final rect = Rect.fromLTWH(text.x - 60, text.y - 16, 120, 32);
      if (rect.contains(position)) {
        return SelectedComponent(
          type: EditorComponentType.textAnnotation,
          id: entry.key,
        );
      }
    }

    for (final entry in _crossovers.entries) {
      if (_nearPoint(position, Offset(entry.value.x, entry.value.y), _hitboxRadius + 6)) {
        return SelectedComponent(
          type: EditorComponentType.crossover,
          id: entry.key,
        );
      }
    }

    for (final entry in _platforms.entries) {
      final platform = entry.value;
      if (_nearLine(
          position,
          Offset(platform.startX, platform.y),
          Offset(platform.endX, platform.y),
          _hitboxRadius + 4)) {
        return SelectedComponent(
          type: EditorComponentType.platform,
          id: entry.key,
        );
      }
    }

    for (final entry in _segments.entries) {
      final segment = entry.value;
      final start = Offset(segment.startX, segment.startY);
      final end = segment.endPoint();
      if (_nearLine(
          position, start, end, _hitboxRadius - 2)) {
        return SelectedComponent(
          type: EditorComponentType.trackSegment,
          id: entry.key,
        );
      }
    }

    return null;
  }

  void _addTrackSegment(Offset position, {required double angleDeg}) {
    final id = 'T${_segments.length + 1}';
    const length = 180.0;
    final start = _resolveStart(position, angleDeg);
    final segment = TrackSegment(
      id: id,
      name: id,
      description: '',
      notes: '',
      color: const Color(0xFF2E86AB),
      style: TrackStyle.ballast,
      guidewayDirection: GuidewayDirection.gd1,
      startX: start.dx,
      startY: start.dy,
      length: length,
      angleDeg: angleDeg,
    );
    _segments[id] = segment;
    _applyMagnetToSegment(id);
    _selected = SelectedComponent(type: EditorComponentType.trackSegment, id: id);
    _selection
      ..clear()
      ..add(_selected!);
    notifyListeners();
  }

  void _addCrossover(Offset position, CrossoverType type) {
    final id = 'X${_crossovers.length + 1}';
    final xo = Crossover(
      id: id,
      name: id,
      description: '',
      notes: '',
      color: const Color(0xFF4C566A),
      style: TrackStyle.ballast,
      x: position.dx,
      y: position.dy,
      type: type,
    );
    _crossovers[id] = xo;
    _addCrossoverPoints(xo);
    _selected = SelectedComponent(type: EditorComponentType.crossover, id: id);
    _selection
      ..clear()
      ..add(_selected!);
    notifyListeners();
  }

  void _addPoint(Offset position) {
    final id = 'P${_points.length + 1}';
    final point = TrackPoint(
      id: id,
      name: id,
      description: '',
      notes: '',
      color: const Color(0xFF2A9D8F),
      x: position.dx,
      y: position.dy,
      style: PointStyle.classic,
      orientation: PointOrientation.upRight,
      autoDetectOrientation: false,
    );
    _points[id] = point;
    _selected = SelectedComponent(type: EditorComponentType.point, id: id);
    _selection
      ..clear()
      ..add(_selected!);
    notifyListeners();
  }

  void _addSignal(Offset position) {
    final id = 'S${_signals.length + 1}';
    final signal = Signal(
      id: id,
      name: id,
      description: '',
      notes: '',
      color: const Color(0xFFE63946),
      x: position.dx,
      y: position.dy,
    );
    _signals[id] = signal;
    _selected = SelectedComponent(type: EditorComponentType.signal, id: id);
    _selection
      ..clear()
      ..add(_selected!);
    notifyListeners();
  }

  void _addPlatform(Offset position) {
    final id = 'PL${_platforms.length + 1}';
    final length = 220.0;
    final platform = Platform(
      id: id,
      name: 'Platform ${_platforms.length + 1}',
      description: '',
      notes: '',
      color: const Color(0xFF6D597A),
      startX: position.dx - length / 2,
      endX: position.dx + length / 2,
      y: position.dy,
    );
    _platforms[id] = platform;
    _selected = SelectedComponent(type: EditorComponentType.platform, id: id);
    _selection
      ..clear()
      ..add(_selected!);
    notifyListeners();
  }

  void _addTrainStop(Offset position) {
    final id = 'TS${_trainStops.length + 1}';
    final stop = TrainStop(
      id: id,
      name: id,
      description: '',
      notes: '',
      color: const Color(0xFFF4A261),
      x: position.dx,
      y: position.dy,
    );
    _trainStops[id] = stop;
    _selected = SelectedComponent(type: EditorComponentType.trainStop, id: id);
    _selection
      ..clear()
      ..add(_selected!);
    notifyListeners();
  }

  void _addBufferStop(Offset position) {
    final id = 'BS${_bufferStops.length + 1}';
    final stop = BufferStop(
      id: id,
      name: id,
      description: '',
      notes: '',
      color: const Color(0xFFB00020),
      x: position.dx,
      y: position.dy,
    );
    _bufferStops[id] = stop;
    _selected = SelectedComponent(type: EditorComponentType.bufferStop, id: id);
    _selection
      ..clear()
      ..add(_selected!);
    notifyListeners();
  }

  void _addAxleCounter(Offset position) {
    final id = 'AC${_axleCounters.length + 1}';
    final counter = AxleCounter(
      id: id,
      name: id,
      description: '',
      notes: '',
      color: const Color(0xFF457B9D),
      x: position.dx,
      y: position.dy,
    );
    _axleCounters[id] = counter;
    _selected = SelectedComponent(type: EditorComponentType.axleCounter, id: id);
    _selection
      ..clear()
      ..add(_selected!);
    notifyListeners();
  }

  void _addTransponder(Offset position) {
    final id = 'T${_transponders.length + 1}';
    final transponder = Transponder(
      id: id,
      name: id,
      description: '',
      notes: '',
      color: const Color(0xFF118AB2),
      x: position.dx,
      y: position.dy,
    );
    _transponders[id] = transponder;
    _selected = SelectedComponent(type: EditorComponentType.transponder, id: id);
    _selection
      ..clear()
      ..add(_selected!);
    notifyListeners();
  }

  void _addWifiAntenna(Offset position) {
    final id = 'W${_wifiAntennas.length + 1}';
    final wifi = WifiAntenna(
      id: id,
      name: id,
      description: '',
      notes: '',
      color: const Color(0xFF06D6A0),
      x: position.dx,
      y: position.dy,
    );
    _wifiAntennas[id] = wifi;
    _selected = SelectedComponent(type: EditorComponentType.wifiAntenna, id: id);
    _selection
      ..clear()
      ..add(_selected!);
    notifyListeners();
  }

  void _addText(Offset position) {
    final id = 'TXT${_textAnnotations.length + 1}';
    final text = TextAnnotation(
      id: id,
      name: id,
      description: '',
      notes: '',
      color: const Color(0xFF5A3E2B),
      text: 'New Text',
      x: position.dx,
      y: position.dy,
    );
    _textAnnotations[id] = text;
    _selected = SelectedComponent(type: EditorComponentType.textAnnotation, id: id);
    _selection
      ..clear()
      ..add(_selected!);
    notifyListeners();
  }

  void _addOctagonCurve(Offset position, double baseAngle) {
    const segmentLength = 60.0;
    Offset start = _resolveStart(position, baseAngle);

    for (int i = 0; i < 8; i++) {
      final angle = baseAngle + (i * 45);
      final id = 'T${_segments.length + 1}';
      final segment = TrackSegment(
        id: id,
        name: id,
        description: '',
        notes: '',
        color: const Color(0xFF2E86AB),
        style: TrackStyle.ballast,
        guidewayDirection: GuidewayDirection.gd1,
        startX: start.dx,
        startY: start.dy,
        length: segmentLength,
        angleDeg: angle,
      );
      _segments[id] = segment;
      _applyMagnetToSegment(id);
      start = segment.endPoint();
    }

    _selected = SelectedComponent(
      type: EditorComponentType.trackSegment,
      id: _segments.keys.last,
    );
    _selection
      ..clear()
      ..add(_selected!);
    notifyListeners();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_captureState());
    final prev = _undoStack.removeLast();
    _restoreState(prev);
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_captureState());
    final next = _redoStack.removeLast();
    _restoreState(next);
    notifyListeners();
  }

  void _pushHistory() {
    _undoStack.add(_captureState());
    _redoStack.clear();
  }

  _EditorState _captureState() {
    return _EditorState(
      segments: _segments.map((k, v) => MapEntry(k, v.copyWith())),
      crossovers: _crossovers.map((k, v) => MapEntry(k, v.copyWith())),
      points: _points.map((k, v) => MapEntry(k, v.copyWith())),
      signals: _signals.map((k, v) => MapEntry(k, v.copyWith())),
      platforms: _platforms.map((k, v) => MapEntry(k, v.copyWith())),
      trainStops: _trainStops.map((k, v) => MapEntry(k, v.copyWith())),
      bufferStops: _bufferStops.map((k, v) => MapEntry(k, v.copyWith())),
      axleCounters: _axleCounters.map((k, v) => MapEntry(k, v.copyWith())),
      transponders: _transponders.map((k, v) => MapEntry(k, v.copyWith())),
      wifiAntennas: _wifiAntennas.map((k, v) => MapEntry(k, v.copyWith())),
      textAnnotations:
          _textAnnotations.map((k, v) => MapEntry(k, v.copyWith())),
      renderOverrides: Map<String, BuilderRenderStyle>.from(_renderOverrides),
      selected: _selected == null
          ? null
          : SelectedComponent(type: _selected!.type, id: _selected!.id),
    );
  }

  void _restoreState(_EditorState state) {
    _segments
      ..clear()
      ..addAll(state.segments);
    _crossovers
      ..clear()
      ..addAll(state.crossovers);
    _points
      ..clear()
      ..addAll(state.points);
    _signals
      ..clear()
      ..addAll(state.signals);
    _platforms
      ..clear()
      ..addAll(state.platforms);
    _trainStops
      ..clear()
      ..addAll(state.trainStops);
    _bufferStops
      ..clear()
      ..addAll(state.bufferStops);
    _axleCounters
      ..clear()
      ..addAll(state.axleCounters);
    _transponders
      ..clear()
      ..addAll(state.transponders);
    _wifiAntennas
      ..clear()
      ..addAll(state.wifiAntennas);
    _textAnnotations
      ..clear()
      ..addAll(state.textAnnotations);
    _selected = state.selected;
    _selection
      ..clear()
      ..addAll(_selected == null ? const [] : [_selected!]);
    _renderOverrides
      ..clear()
      ..addAll(state.renderOverrides);
  }

  List<SelectedComponent> _selectionOrder() {
    final items = <SelectedComponent>[];

    void addItems(EditorComponentType type, Iterable<String> ids) {
      final sorted = ids.toList()..sort();
      for (final id in sorted) {
        items.add(SelectedComponent(type: type, id: id));
      }
    }

    addItems(EditorComponentType.trackSegment, _segments.keys);
    addItems(EditorComponentType.crossover, _crossovers.keys);
    addItems(EditorComponentType.point, _points.keys);
    addItems(EditorComponentType.signal, _signals.keys);
    addItems(EditorComponentType.platform, _platforms.keys);
    addItems(EditorComponentType.trainStop, _trainStops.keys);
    addItems(EditorComponentType.bufferStop, _bufferStops.keys);
    addItems(EditorComponentType.axleCounter, _axleCounters.keys);
    addItems(EditorComponentType.transponder, _transponders.keys);
    addItems(EditorComponentType.wifiAntenna, _wifiAntennas.keys);
    addItems(EditorComponentType.textAnnotation, _textAnnotations.keys);

    return items;
  }

  void _applyMagnetToSegment(String segmentId) {
    if (!_magnetEnabled) return;
    final segment = _segments[segmentId];
    if (segment == null) return;

    final start = Offset(segment.startX, segment.startY);
    final end = segment.endPoint();
    final startSnap = _findNearestEndpoint(start, segmentId);
    final endSnap = _findNearestEndpoint(end, segmentId);

    if (startSnap != null) {
      final delta = startSnap - start;
      _segments[segmentId] = segment.copyWith(
        startX: segment.startX + delta.dx,
        startY: segment.startY + delta.dy,
      );
      return;
    }

    if (endSnap != null) {
      final dx = endSnap.dx - segment.startX;
      final dy = endSnap.dy - segment.startY;
      final length = math.sqrt(dx * dx + dy * dy);
      final angle = math.atan2(dy, dx) * 180.0 / math.pi;
      _segments[segmentId] = segment.copyWith(
        length: length,
        angleDeg: angle,
      );
    }
  }

  Offset? _findNearestEndpoint(Offset position, String ignoreId) {
    double minDist = _magnetThreshold;
    Offset? nearest;
    for (final entry in _segments.entries) {
      if (entry.key == ignoreId) continue;
      final start = Offset(entry.value.startX, entry.value.startY);
      final end = entry.value.endPoint();
      final distStart = (position - start).distance;
      if (distStart < minDist) {
        minDist = distStart;
        nearest = start;
      }
      final distEnd = (position - end).distance;
      if (distEnd < minDist) {
        minDist = distEnd;
        nearest = end;
      }
    }
    return nearest;
  }
  Offset _resolveStart(Offset position, double angleDeg) {
    final selected = _selected;
    if (selected?.type == EditorComponentType.trackSegment) {
      final segment = _segments[selected!.id];
      if (segment != null) {
        return segment.endPoint();
      }
    }
    return position;
  }

  double _inheritAngle() {
    final selected = _selected;
    if (selected?.type == EditorComponentType.trackSegment) {
      final segment = _segments[selected!.id];
      if (segment != null) return segment.angleDeg;
    }
    return 0;
  }

  void _addCrossoverPoints(Crossover crossover) {
    const spacing = 32.0;
    final pointsToAdd = <Offset>[];

    switch (crossover.type) {
      case CrossoverType.righthand:
        pointsToAdd.add(Offset(crossover.x - spacing, crossover.y - spacing));
        pointsToAdd.add(Offset(crossover.x + spacing, crossover.y + spacing));
        break;
      case CrossoverType.lefthand:
        pointsToAdd.add(Offset(crossover.x - spacing, crossover.y + spacing));
        pointsToAdd.add(Offset(crossover.x + spacing, crossover.y - spacing));
        break;
      case CrossoverType.doubleDiamond:
        pointsToAdd.add(Offset(crossover.x - spacing, crossover.y - spacing));
        pointsToAdd.add(Offset(crossover.x + spacing, crossover.y - spacing));
        pointsToAdd.add(Offset(crossover.x - spacing, crossover.y + spacing));
        pointsToAdd.add(Offset(crossover.x + spacing, crossover.y + spacing));
        break;
      case CrossoverType.singleSlip:
      case CrossoverType.doubleSlip:
        pointsToAdd.add(Offset(crossover.x - spacing, crossover.y));
        pointsToAdd.add(Offset(crossover.x + spacing, crossover.y));
        pointsToAdd.add(Offset(crossover.x, crossover.y - spacing));
        break;
    }

    for (final pointPos in pointsToAdd) {
      final snapped = _snapOffset(pointPos);
      final id = 'P${_points.length + 1}';
      _points[id] = TrackPoint(
        id: id,
        name: id,
        description: '',
        notes: '',
        color: const Color(0xFF2A9D8F),
        x: snapped.dx,
        y: snapped.dy,
      );
    }
  }

  Offset _snapOffset(Offset position) {
    if (!_snapToGrid) return position;
    return Offset(_snapValue(position.dx), _snapValue(position.dy));
  }

  double _snapValue(double value) {
    return (value / _gridSize).roundToDouble() * _gridSize;
  }

  bool _nearPoint(Offset a, Offset b, double radius) {
    return (a - b).distance <= radius;
  }

  double get _hitboxRadius => _largeHitboxes ? 24.0 : 14.0;

  String _renderKey(EditorComponentType type, String id) => '${type.name}:$id';

  bool _nearLine(Offset point, Offset start, Offset end, double tolerance) {
    final length = (end - start).distance;
    if (length == 0) return false;
    final t = ((point.dx - start.dx) * (end.dx - start.dx) +
            (point.dy - start.dy) * (end.dy - start.dy)) /
        (length * length);
    if (t < 0 || t > 1) return false;
    final projection =
        Offset(start.dx + t * (end.dx - start.dx), start.dy + t * (end.dy - start.dy));
    return (point - projection).distance <= tolerance;
  }

  List<List<Offset>> _crossoverLinesFromPoints(
    Crossover crossover,
    Offset center,
    List<TrackPoint> points,
  ) {
    if (points.isEmpty) return [];

    Offset? inQuadrant(bool left, bool up) {
      TrackPoint? best;
      double bestDist = double.infinity;
      for (final point in points) {
        final dx = point.x - center.dx;
        final dy = point.y - center.dy;
        final isLeft = dx <= 0;
        final isUp = dy <= 0;
        if (isLeft != left || isUp != up) continue;
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist < bestDist) {
          bestDist = dist;
          best = point;
        }
      }
      if (best == null) return null;
      return Offset(best.x, best.y);
    }

    Offset? upLeft = inQuadrant(true, true);
    Offset? upRight = inQuadrant(false, true);
    Offset? downLeft = inQuadrant(true, false);
    Offset? downRight = inQuadrant(false, false);

    Offset? leftMost;
    Offset? rightMost;
    Offset? topMost;
    Offset? bottomMost;
    for (final point in points) {
      final pos = Offset(point.x, point.y);
      leftMost ??= pos;
      rightMost ??= pos;
      topMost ??= pos;
      bottomMost ??= pos;
      if (pos.dx < leftMost!.dx) leftMost = pos;
      if (pos.dx > rightMost!.dx) rightMost = pos;
      if (pos.dy < topMost!.dy) topMost = pos;
      if (pos.dy > bottomMost!.dy) bottomMost = pos;
    }

    final lines = <List<Offset>>[];
    void addLine(Offset? a, Offset? b) {
      if (a == null || b == null) return;
      if ((a - b).distance < 1) return;
      lines.add([a, b]);
    }

    switch (crossover.type) {
      case CrossoverType.righthand:
        addLine(upLeft, downRight);
        break;
      case CrossoverType.lefthand:
        addLine(downLeft, upRight);
        break;
      case CrossoverType.doubleDiamond:
        addLine(upLeft, downRight);
        addLine(downLeft, upRight);
        break;
      case CrossoverType.singleSlip:
      case CrossoverType.doubleSlip:
        addLine(leftMost, rightMost);
        addLine(upRight ?? upLeft, downLeft ?? downRight);
        break;
    }

    if (lines.isNotEmpty) return lines;
    if (points.length < 2) return [];
    final pair = _farthestPair(points.map((p) => Offset(p.x, p.y)).toList());
    if (pair.isNotEmpty) lines.add(pair);
    if (crossover.type == CrossoverType.doubleDiamond && points.length >= 4) {
      final remaining = points
          .map((p) => Offset(p.x, p.y))
          .where((p) => !pair.contains(p))
          .toList();
      final second = _farthestPair(remaining);
      if (second.isNotEmpty) lines.add(second);
    }
    return lines;
  }

  List<List<Offset>> _crossoverLinesFromSegments(Offset center) {
    const threshold = 28.0;
    const lineLength = 90.0;
    final lines = <List<Offset>>[];
    final angles = <double>[];
    for (final segment in _segments.values) {
      final start = Offset(segment.startX, segment.startY);
      final end = segment.endPoint();
      if (_distanceToLine(center, start, end) > threshold) continue;
      final dir = end - start;
      if (dir.distance == 0) continue;
      final angle = math.atan2(dir.dy, dir.dx) * 180 / math.pi;
      if (angles.any((a) => _angleDiffDegrees(a, angle) < 12)) continue;
      angles.add(angle);
      final unit = dir / dir.distance;
      final half = lineLength / 2;
      lines.add([center - unit * half, center + unit * half]);
    }
    return lines;
  }

  List<Offset> _farthestPair(List<Offset> points) {
    if (points.length < 2) return const [];
    double best = -1;
    Offset? a;
    Offset? b;
    for (var i = 0; i < points.length; i++) {
      for (var j = i + 1; j < points.length; j++) {
        final dist = (points[i] - points[j]).distance;
        if (dist > best) {
          best = dist;
          a = points[i];
          b = points[j];
        }
      }
    }
    if (a == null || b == null) return const [];
    return [a!, b!];
  }

  bool _isEndpointConnected(_Endpoint endpoint, List<_Endpoint> endpoints) {
    for (final other in endpoints) {
      if (other.segmentId == endpoint.segmentId) continue;
      if ((endpoint.position - other.position).distance <= 14) {
        return true;
      }
    }
    return false;
  }

  bool _nearPointToAny(
      Offset position, Iterable<TrackPoint> points, double radius) {
    for (final point in points) {
      if ((position - Offset(point.x, point.y)).distance <= radius) {
        return true;
      }
    }
    return false;
  }

  bool _nearCrossover(
      Offset position, Iterable<Crossover> crossovers, double radius) {
    for (final crossover in crossovers) {
      if ((position - Offset(crossover.x, crossover.y)).distance <= radius) {
        return true;
      }
    }
    return false;
  }

  bool _nearBufferStop(
      Offset position, Iterable<BufferStop> stops, double radius) {
    for (final stop in stops) {
      if ((position - Offset(stop.x, stop.y)).distance <= radius) {
        return true;
      }
    }
    return false;
  }

  bool _nearSegment(
      double x, double y, List<TrackSegment> segments, double tolerance) {
    final point = Offset(x, y);
    for (final segment in segments) {
      final start = Offset(segment.startX, segment.startY);
      final end = segment.endPoint();
      if (_nearLine(point, start, end, tolerance)) {
        return true;
      }
    }
    return false;
  }

  bool _nearSignal(double x, double y, Iterable<Signal> signals, double radius) {
    final point = Offset(x, y);
    for (final signal in signals) {
      if ((point - Offset(signal.x, signal.y)).distance <= radius) {
        return true;
      }
    }
    return false;
  }

  bool _segmentsOverlap(TrackSegment a, TrackSegment b) {
    final aStart = Offset(a.startX, a.startY);
    final aEnd = a.endPoint();
    final bStart = Offset(b.startX, b.startY);
    final bEnd = b.endPoint();

    final aVec = aEnd - aStart;
    final bVec = bEnd - bStart;
    final cross = aVec.dx * bVec.dy - aVec.dy * bVec.dx;
    if (cross.abs() > 0.01) {
      return false;
    }
    final aLen = aVec.distance;
    if (aLen == 0) return false;
    final aUnit = aVec / aLen;
    final projStart = (bStart - aStart).dx * aUnit.dx +
        (bStart - aStart).dy * aUnit.dy;
    final projEnd = (bEnd - aStart).dx * aUnit.dx +
        (bEnd - aStart).dy * aUnit.dy;
    final minA = 0.0;
    final maxA = aLen;
    final minB = math.min(projStart, projEnd);
    final maxB = math.max(projStart, projEnd);
    final overlap = math.max(minA, minB) <= math.min(maxA, maxB);
    if (!overlap) return false;

    final dist = _distanceToLine(bStart, aStart, aEnd);
    return dist < 6;
  }

  bool _isBranchingJunction(List<TrackSegment> segments) {
    if (segments.length < 2) return false;
    final base = segments.first;
    for (final segment in segments.skip(1)) {
      final diff = _angleDiffDegrees(base.angleDeg, segment.angleDeg);
      if (diff > 12) return true;
    }
    return false;
  }

  Offset _clusterCenter(List<Offset> points) {
    var x = 0.0;
    var y = 0.0;
    for (final p in points) {
      x += p.dx;
      y += p.dy;
    }
    return Offset(x / points.length, y / points.length);
  }

  String _junctionId(Offset position) {
    final x = position.dx.round();
    final y = position.dy.round();
    return 'J_${x}_${y}';
  }

  bool _hasBranchingSegments(TrackPoint point) {
    final hits = _segmentHitsNearPoint(Offset(point.x, point.y), 24);
    if (hits.length < 2) return false;
    final base = hits.first.segment;
    for (final hit in hits.skip(1)) {
      final diff = _angleDiffDegrees(base.angleDeg, hit.segment.angleDeg);
      if (diff > 12) return true;
    }
    return false;
  }

  _AxisOrientation _dominantOrientation(double dx, double dy) {
    if (dx.abs() >= dy.abs()) {
      return dx >= 0 ? _AxisOrientation.east : _AxisOrientation.west;
    }
    return dy >= 0 ? _AxisOrientation.south : _AxisOrientation.north;
  }

  bool _idExistsForType(EditorComponentType type, String id) {
    switch (type) {
      case EditorComponentType.trackSegment:
        return _segments.containsKey(id);
      case EditorComponentType.crossover:
        return _crossovers.containsKey(id);
      case EditorComponentType.point:
        return _points.containsKey(id);
      case EditorComponentType.signal:
        return _signals.containsKey(id);
      case EditorComponentType.platform:
        return _platforms.containsKey(id);
      case EditorComponentType.trainStop:
        return _trainStops.containsKey(id);
      case EditorComponentType.bufferStop:
        return _bufferStops.containsKey(id);
      case EditorComponentType.axleCounter:
        return _axleCounters.containsKey(id);
      case EditorComponentType.transponder:
        return _transponders.containsKey(id);
      case EditorComponentType.wifiAntenna:
        return _wifiAntennas.containsKey(id);
      case EditorComponentType.textAnnotation:
        return _textAnnotations.containsKey(id);
    }
  }

  void _seedTerminalStationLayout({bool clearHistory = true}) {
    if (clearHistory) {
      _undoStack.clear();
      _redoStack.clear();
    }
    _segments.clear();
    _crossovers.clear();
    _points.clear();
    _signals.clear();
    _platforms.clear();
    _trainStops.clear();
    _bufferStops.clear();
    _axleCounters.clear();
    _transponders.clear();
    _wifiAntennas.clear();
    _textAnnotations.clear();
    _alphaGammaJunctions.clear();

    void addBlock(String id, double startX, double endX, double y) {
      _segments[id] = TrackSegment(
        id: id,
        name: id,
        description: '',
        notes: '',
        color: const Color(0xFF2E86AB),
        style: TrackStyle.ballast,
        guidewayDirection: GuidewayDirection.gd1,
        startX: startX,
        startY: y,
        length: endX - startX,
        angleDeg: 0,
      );
    }

    void addPlatform(
      String id,
      String name,
      double startX,
      double endX,
      double y,
    ) {
      _platforms[id] = Platform(
        id: id,
        name: name,
        description: '',
        notes: '',
        color: const Color(0xFF6D597A),
        startX: startX,
        endX: endX,
        y: y,
      );
    }

    void addSignal(
      String id,
      double x,
      double y, {
      SignalDirection direction = SignalDirection.east,
    }) {
      _signals[id] = Signal(
        id: id,
        name: id,
        description: '',
        notes: '',
        color: const Color(0xFFE63946),
        x: x,
        y: y,
        direction: direction,
      );
    }

    void addTrainStop(String id, double x, double y) {
      _trainStops[id] = TrainStop(
        id: id,
        name: id,
        description: '',
        notes: '',
        color: const Color(0xFFF4A261),
        x: x,
        y: y,
      );
    }

    void addBufferStop(String id, double x, double y) {
      _bufferStops[id] = BufferStop(
        id: id,
        name: id,
        description: '',
        notes: '',
        color: const Color(0xFFB00020),
        x: x,
        y: y,
      );
    }

    void addAxleCounter(String id, double x, double y) {
      _axleCounters[id] = AxleCounter(
        id: id,
        name: id,
        description: '',
        notes: '',
        color: const Color(0xFF457B9D),
        x: x,
        y: y,
      );
    }

    void addWifi(String id, double x, double y) {
      _wifiAntennas[id] = WifiAntenna(
        id: id,
        name: id,
        description: '',
        notes: '',
        color: const Color(0xFF06D6A0),
        x: x,
        y: y,
      );
    }

    Color transponderColor(TransponderType type) {
      switch (type) {
        case TransponderType.t1:
          return const Color(0xFF118AB2);
        case TransponderType.t2:
          return const Color(0xFF06D6A0);
        case TransponderType.t3:
          return const Color(0xFFF4A261);
        case TransponderType.t6:
          return const Color(0xFF9B5DE5);
      }
    }

    void addTransponder(
      String id,
      TransponderType type,
      double x,
      double y, {
      String description = '',
    }) {
      _transponders[id] = Transponder(
        id: id,
        name: id,
        description: description,
        notes: '',
        color: transponderColor(type),
        x: x,
        y: y,
        type: type,
      );
    }

    // Left section upper track (y=100)
    addBlock('198', -1800, -1700, 100);
    addBlock('196', -1700, -1600, 100);
    addBlock('200', -1600, -1400, 100);
    addBlock('202', -1400, -1200, 100);
    addBlock('204', -1200, -1000, 100);
    addBlock('206', -1000, -800, 100);
    addBlock('208', -800, -600, 100);
    addBlock('210', -600, -450, 100);
    addBlock('210A', -450, -300, 100);
    addBlock('212', -300, -200, 100);
    addBlock('214', -200, 0, 100);

    // Left section lower track (y=300)
    addBlock('199', -1800, -1700, 300);
    addBlock('197', -1700, -1600, 300);
    addBlock('201', -1600, -1400, 300);
    addBlock('203', -1400, -1200, 300);
    addBlock('205', -1200, -1000, 300);
    addBlock('207', -1000, -800, 300);
    addBlock('209', -800, -600, 300);
    addBlock('211', -600, -450, 300);
    addBlock('211A', -450, -300, 300);
    addBlock('213', -300, -200, 300);
    addBlock('215', -200, 0, 300);

    // Middle section upper track (y=100)
    addBlock('100', 0, 200, 100);
    addBlock('102', 200, 400, 100);
    addBlock('104', 400, 600, 100);
    addBlock('106', 600, 800, 100);
    addBlock('108', 800, 1000, 100);
    addBlock('110', 1000, 1200, 100);
    addBlock('112', 1200, 1400, 100);
    addBlock('114', 1400, 1600, 100);

    // Middle section lower track (y=300)
    addBlock('101', 0, 200, 300);
    addBlock('103', 200, 400, 300);
    addBlock('105', 400, 600, 300);
    addBlock('107', 600, 800, 300);
    addBlock('109', 800, 1000, 300);
    addBlock('111', 1000, 1200, 300);
    addBlock('113', 1200, 1400, 300);
    addBlock('115', 1400, 1600, 300);

    // Right section upper track (y=100)
    addBlock('300', 1600, 1800, 100);
    addBlock('302', 1800, 2100, 100);
    addBlock('304', 2100, 2300, 100);
    addBlock('306', 2300, 2500, 100);
    addBlock('308', 2500, 2700, 100);
    addBlock('310', 2700, 2900, 100);
    addBlock('312', 2900, 3100, 100);
    addBlock('314', 3100, 3300, 100);
    addBlock('316', 3300, 3400, 100);
    addBlock('318', 3400, 3500, 100);

    // Right section lower track (y=300)
    addBlock('301', 1600, 1800, 300);
    addBlock('303', 1800, 2100, 300);
    addBlock('305', 2100, 2300, 300);
    addBlock('307', 2300, 2500, 300);
    addBlock('309', 2500, 2700, 300);
    addBlock('311', 2700, 2900, 300);
    addBlock('313', 2900, 3100, 300);
    addBlock('315', 3100, 3300, 300);
    addBlock('317', 3300, 3400, 300);
    addBlock('319', 3400, 3500, 300);

    _crossovers['crossover_211_212'] = const Crossover(
      id: 'crossover_211_212',
      name: 'West Terminal Double Diamond',
      description: '',
      notes: '',
      color: Color(0xFF4C566A),
      style: TrackStyle.ballast,
      x: -450,
      y: 200,
      type: CrossoverType.doubleDiamond,
    );
    _crossovers['crossover106'] = const Crossover(
      id: 'crossover106',
      name: 'Central Station Crossover Upper',
      description: '',
      notes: '',
      color: Color(0xFF4C566A),
      style: TrackStyle.ballast,
      x: 450,
      y: 150,
      type: CrossoverType.righthand,
    );
    _crossovers['crossover109'] = const Crossover(
      id: 'crossover109',
      name: 'Central Station Crossover Lower',
      description: '',
      notes: '',
      color: Color(0xFF4C566A),
      style: TrackStyle.ballast,
      x: 550,
      y: 200,
      type: CrossoverType.lefthand,
    );
    _crossovers['crossover_303_304'] = const Crossover(
      id: 'crossover_303_304',
      name: 'East Terminal Double Diamond',
      description: '',
      notes: '',
      color: Color(0xFF4C566A),
      style: TrackStyle.ballast,
      x: 1950,
      y: 200,
      type: CrossoverType.doubleDiamond,
    );

    _points['76A'] = const TrackPoint(
      id: '76A',
      name: '76A',
      description: '',
      notes: '',
      color: Color(0xFF2A9D8F),
      x: -600,
      y: 100,
      orientation: PointOrientation.downRight,
      autoDetectOrientation: false,
    );
    _points['77A'] = const TrackPoint(
      id: '77A',
      name: '77A',
      description: '',
      notes: '',
      color: Color(0xFF2A9D8F),
      x: -300,
      y: 100,
      orientation: PointOrientation.downLeft,
      autoDetectOrientation: false,
    );
    _points['77B'] = const TrackPoint(
      id: '77B',
      name: '77B',
      description: '',
      notes: '',
      color: Color(0xFF2A9D8F),
      x: -600,
      y: 300,
      orientation: PointOrientation.upRight,
      autoDetectOrientation: false,
    );
    _points['76B'] = const TrackPoint(
      id: '76B',
      name: '76B',
      description: '',
      notes: '',
      color: Color(0xFF2A9D8F),
      x: -300,
      y: 300,
      orientation: PointOrientation.upLeft,
      autoDetectOrientation: false,
    );
    _points['78A'] = const TrackPoint(
      id: '78A',
      name: '78A',
      description: '',
      notes: '',
      color: Color(0xFF2A9D8F),
      x: 400,
      y: 100,
      orientation: PointOrientation.downRight,
      autoDetectOrientation: false,
    );
    _points['78B'] = const TrackPoint(
      id: '78B',
      name: '78B',
      description: '',
      notes: '',
      color: Color(0xFF2A9D8F),
      x: 600,
      y: 300,
      orientation: PointOrientation.upLeft,
      autoDetectOrientation: false,
    );
    _points['79A'] = const TrackPoint(
      id: '79A',
      name: '79A',
      description: '',
      notes: '',
      color: Color(0xFF2A9D8F),
      x: 1800,
      y: 100,
      orientation: PointOrientation.downRight,
      autoDetectOrientation: false,
    );
    _points['80A'] = const TrackPoint(
      id: '80A',
      name: '80A',
      description: '',
      notes: '',
      color: Color(0xFF2A9D8F),
      x: 2100,
      y: 100,
      orientation: PointOrientation.downLeft,
      autoDetectOrientation: false,
    );
    _points['80B'] = const TrackPoint(
      id: '80B',
      name: '80B',
      description: '',
      notes: '',
      color: Color(0xFF2A9D8F),
      x: 1800,
      y: 300,
      orientation: PointOrientation.upRight,
      autoDetectOrientation: false,
    );
    _points['79B'] = const TrackPoint(
      id: '79B',
      name: '79B',
      description: '',
      notes: '',
      color: Color(0xFF2A9D8F),
      x: 2100,
      y: 300,
      orientation: PointOrientation.upLeft,
      autoDetectOrientation: false,
    );

    // Platforms
    addPlatform('P1', 'West Terminal Platform 1', -1200, -800, 100);
    addPlatform('P2', 'West Terminal Platform 2', -1200, -800, 300);
    addPlatform('P3', 'Central Terminal Platform 1', 800, 1200, 100);
    addPlatform('P4', 'Central Terminal Platform 2', 800, 1200, 300);
    addPlatform('P5', 'East Terminal Platform 1', 2400, 2800, 100);
    addPlatform('P6', 'East Terminal Platform 2', 2400, 2800, 300);

    // Buffer stops
    addBufferStop('BS1', -1800, 100);
    addBufferStop('BS2', -1800, 300);
    addBufferStop('BS3', 3500, 100);
    addBufferStop('BS4', 3500, 300);

    // Signals
    addSignal('L01', -1510, 80, direction: SignalDirection.east);
    addSignal('L02', -795, 320, direction: SignalDirection.east);
    addSignal('L03', -795, 80, direction: SignalDirection.east);
    addSignal('L04', -205, 320, direction: SignalDirection.west);
    addSignal('L05', -205, 80, direction: SignalDirection.west);
    addSignal('L06', -1210, 80, direction: SignalDirection.west);
    addSignal('L07', -1210, 320, direction: SignalDirection.west);
    addSignal('L09', -1510, 320, direction: SignalDirection.east);

    addSignal('C31', 205, 80, direction: SignalDirection.east);
    addSignal('C33', 1205, 80, direction: SignalDirection.east);
    addSignal('C01', 770, 80, direction: SignalDirection.west);
    addSignal('C30', 770, 320, direction: SignalDirection.west);
    addSignal('C03', 1230, 320, direction: SignalDirection.east);

    addSignal('R01', 1600, 80, direction: SignalDirection.east);
    addSignal('R02', 3100, 80, direction: SignalDirection.east);
    addSignal('R03', 2790, 80, direction: SignalDirection.east);
    addSignal('R04', 3100, 320, direction: SignalDirection.west);
    addSignal('R05', 2790, 320, direction: SignalDirection.west);
    addSignal('R06', 2390, 320, direction: SignalDirection.west);
    addSignal('R07', 1600, 320, direction: SignalDirection.east);
    addSignal('R08', 2390, 80, direction: SignalDirection.west);

    // Train stops
    addTrainStop('TL01', -1500, 120);
    addTrainStop('TL02', -785, 320);
    addTrainStop('TL03', -785, 120);
    addTrainStop('TL04', -215, 340);
    addTrainStop('TL05', -215, 120);
    addTrainStop('TL06', -1220, 120);
    addTrainStop('TL07', -1220, 340);
    addTrainStop('TL09', -1500, 320);

    addTrainStop('T31', 215, 120);
    addTrainStop('T33', 1215, 120);
    addTrainStop('T30', 760, 340);
    addTrainStop('TC01', 760, 120);
    addTrainStop('TC03', 1240, 340);

    addTrainStop('TR01', 1610, 120);
    addTrainStop('TR02', 3090, 120);
    addTrainStop('TR03', 2800, 120);
    addTrainStop('TR04', 3090, 340);
    addTrainStop('TR05', 2800, 340);
    addTrainStop('TR06', 2380, 340);
    addTrainStop('TR07', 1610, 340);
    addTrainStop('TR08', 2380, 120);

    // Axle counters
    addAxleCounter('ac198', -1750, 120);
    addAxleCounter('ac196', -1650, 120);
    addAxleCounter('ac200', -1500, 120);
    addAxleCounter('ac202', -1300, 120);
    addAxleCounter('ac204', -1100, 120);
    addAxleCounter('ac206', -900, 120);
    addAxleCounter('ac208', -700, 120);
    addAxleCounter('ac210', -500, 120);
    addAxleCounter('ac212', -300, 120);
    addAxleCounter('ac214', -100, 120);

    addAxleCounter('ac199', -1750, 320);
    addAxleCounter('ac197', -1650, 320);
    addAxleCounter('ac201', -1500, 320);
    addAxleCounter('ac203', -1300, 320);
    addAxleCounter('ac205', -1100, 320);
    addAxleCounter('ac207', -900, 320);
    addAxleCounter('ac209', -700, 320);
    addAxleCounter('ac211', -500, 320);
    addAxleCounter('ac213', -300, 320);
    addAxleCounter('ac215', -100, 320);

    addAxleCounter('ac_cx76_NW', -570, 130);
    addAxleCounter('ac_cx76_NE', -330, 130);
    addAxleCounter('ac_cx76_SW', -590, 270);
    addAxleCounter('ac_cx76_SE', -310, 270);

    addAxleCounter('ac104', 550, 120);
    addAxleCounter('ac108', 700, 120);
    addAxleCounter('ac112', 1300, 120);
    addAxleCounter('ac101', 595, 320);
    addAxleCounter('ac109', 850, 320);
    addAxleCounter('ac111', 1150, 320);
    addAxleCounter('ac78a_west', 395, 100);
    addAxleCounter('ac78a_east', 605, 300);

    addAxleCounter('ac300', 1700, 120);
    addAxleCounter('ac302', 1900, 120);
    addAxleCounter('ac304', 2100, 120);
    addAxleCounter('ac306', 2300, 120);
    addAxleCounter('ac308', 2500, 120);
    addAxleCounter('ac310', 2700, 120);
    addAxleCounter('ac312', 2900, 120);
    addAxleCounter('ac314', 3100, 120);
    addAxleCounter('ac316', 3250, 120);
    addAxleCounter('ac318', 3350, 120);

    addAxleCounter('ac301', 1700, 320);
    addAxleCounter('ac303', 1900, 320);
    addAxleCounter('ac305', 2100, 320);
    addAxleCounter('ac307', 2300, 320);
    addAxleCounter('ac309', 2500, 320);
    addAxleCounter('ac311', 2700, 320);
    addAxleCounter('ac313', 2900, 320);
    addAxleCounter('ac315', 3100, 320);
    addAxleCounter('ac317', 3250, 320);
    addAxleCounter('ac319', 3350, 320);

    addAxleCounter('ac_cx79_NW', 1830, 130);
    addAxleCounter('ac_cx79_NE', 2070, 130);
    addAxleCounter('ac_cx79_SW', 1850, 270);
    addAxleCounter('ac_cx79_SE', 2050, 270);

    addAxleCounter('ac103', 300, 320);
    addAxleCounter('ac113', 1300, 320);
    addAxleCounter('ac114', 1500, 120);
    addAxleCounter('ac115', 1500, 320);
    addAxleCounter('ac210', -700, 120);
    addAxleCounter('ac212', -400, 120);

    // WiFi
    addWifi('W_L1', -1500, 200);
    addWifi('W_L2', -1200, 200);
    addWifi('W_L3', -800, 200);
    addWifi('W_L4', -400, 200);
    addWifi('W_L5', -100, 200);
    addWifi('W_C1', 100, 200);
    addWifi('W_C2', 400, 200);
    addWifi('W_C3', 600, 200);
    addWifi('W_C4', 1000, 200);
    addWifi('W_C5', 1400, 200);
    addWifi('W_R1', 1700, 200);
    addWifi('W_R2', 2000, 200);
    addWifi('W_R3', 2400, 200);
    addWifi('W_R4', 2600, 200);
    addWifi('W_R5', 3000, 200);

    // Transponders
    addTransponder('T6_P1', TransponderType.t6, -775, 100,
        description: 'T6 - Accurate Stopping Tag P1');
    addTransponder('T6_P2', TransponderType.t6, -775, 300,
        description: 'T6 - Accurate Stopping Tag P2');
    addTransponder('T6_P3', TransponderType.t6, 1225, 100,
        description: 'T6 - Accurate Stopping Tag P3');
    addTransponder('T6_P4', TransponderType.t6, 1225, 300,
        description: 'T6 - Accurate Stopping Tag P4');
    addTransponder('T6_P5', TransponderType.t6, 2825, 100,
        description: 'T6 - Accurate Stopping Tag P5');
    addTransponder('T6_P6', TransponderType.t6, 2825, 300,
        description: 'T6 - Accurate Stopping Tag P6');

    addTransponder('T1_WEST_END_UP', TransponderType.t1, -1400, 100,
        description: 'T1 - West End Tag Upper');
    addTransponder('T1_WEST_END_LOW', TransponderType.t1, -1400, 300,
        description: 'T1 - West End Tag Lower');
    addTransponder('T1_EAST_END_UP', TransponderType.t1, 3000, 100,
        description: 'T1 - East End Tag Upper');
    addTransponder('T1_EAST_END_LOW', TransponderType.t1, 3000, 300,
        description: 'T1 - East End Tag Lower');

    addTransponder('T1_XO_WEST_1', TransponderType.t1, -550, 100,
        description: 'T1 - West Crossover Tag');
    addTransponder('T1_XO_WEST_2', TransponderType.t1, -550, 300,
        description: 'T1 - West Crossover Tag');
    addTransponder('T1_XO_WEST_3', TransponderType.t1, -450, 100,
        description: 'T1 - West Crossover Tag');
    addTransponder('T1_XO_WEST_4', TransponderType.t1, -450, 300,
        description: 'T1 - West Crossover Tag');

    addTransponder('T1_XO_MID_1', TransponderType.t1, 400, 100,
        description: 'T1 - Middle Crossover Tag (Entry Upper)');
    addTransponder('T1_XO_MID_2', TransponderType.t1, 500, 200,
        description: 'T1 - Middle Crossover Tag (Midpoint)');
    addTransponder('T1_XO_MID_3', TransponderType.t1, 500, 200,
        description: 'T1 - Middle Crossover Tag (Midpoint)');
    addTransponder('T1_XO_MID_4', TransponderType.t1, 600, 300,
        description: 'T1 - Middle Crossover Tag (Exit Lower)');

    addTransponder('T1_XO_EAST_1', TransponderType.t1, 1900, 100,
        description: 'T1 - East Crossover Tag');
    addTransponder('T1_XO_EAST_2', TransponderType.t1, 1900, 300,
        description: 'T1 - East Crossover Tag');
    addTransponder('T1_XO_EAST_3', TransponderType.t1, 2000, 100,
        description: 'T1 - East Crossover Tag');
    addTransponder('T1_XO_EAST_4', TransponderType.t1, 2000, 300,
        description: 'T1 - East Crossover Tag');

    final westToCentralDist = 1600.0;
    final westToCentralStart = -800.0 + 25;
    final spacing1 = westToCentralDist / 10;
    addTransponder('T1_WC_1_UP', TransponderType.t1,
        westToCentralStart + spacing1 * 1, 100,
        description: 'T1 - Crossover Tag');
    addTransponder('T1_WC_1_LOW', TransponderType.t1,
        westToCentralStart + spacing1 * 1, 300,
        description: 'T1 - Crossover Tag');
    addTransponder('T1_WC_2_UP', TransponderType.t1,
        westToCentralStart + spacing1 * 2, 100,
        description: 'T1 - Crossover Tag');
    addTransponder('T1_WC_2_LOW', TransponderType.t1,
        westToCentralStart + spacing1 * 2, 300,
        description: 'T1 - Crossover Tag');
    addTransponder('T1_WC_3_UP', TransponderType.t1,
        westToCentralStart + spacing1 * 3, 100,
        description: 'T1 - Crossover Tag');
    addTransponder('T1_WC_3_LOW', TransponderType.t1,
        westToCentralStart + spacing1 * 3, 300,
        description: 'T1 - Crossover Tag');
    addTransponder('T2_WC_1_UP', TransponderType.t2,
        westToCentralStart + spacing1 * 4, 100,
        description: 'T2 - Cross Border Tag');
    addTransponder('T2_WC_1_LOW', TransponderType.t2,
        westToCentralStart + spacing1 * 4, 300,
        description: 'T2 - Cross Border Tag');
    addTransponder('T3_WC_UP', TransponderType.t3,
        westToCentralStart + spacing1 * 5, 100,
        description: 'T3 - Border Tag');
    addTransponder('T3_WC_LOW', TransponderType.t3,
        westToCentralStart + spacing1 * 5, 300,
        description: 'T3 - Border Tag');
    addTransponder('T2_WC_2_UP', TransponderType.t2,
        westToCentralStart + spacing1 * 6, 100,
        description: 'T2 - Cross Border Tag');
    addTransponder('T2_WC_2_LOW', TransponderType.t2,
        westToCentralStart + spacing1 * 6, 300,
        description: 'T2 - Cross Border Tag');
    addTransponder('T1_WC_4_UP', TransponderType.t1,
        westToCentralStart + spacing1 * 7, 100,
        description: 'T1 - Crossover Tag');
    addTransponder('T1_WC_4_LOW', TransponderType.t1,
        westToCentralStart + spacing1 * 7, 300,
        description: 'T1 - Crossover Tag');
    addTransponder('T1_WC_5_UP', TransponderType.t1,
        westToCentralStart + spacing1 * 8, 100,
        description: 'T1 - Crossover Tag');
    addTransponder('T1_WC_5_LOW', TransponderType.t1,
        westToCentralStart + spacing1 * 8, 300,
        description: 'T1 - Crossover Tag');
    addTransponder('T1_WC_6_UP', TransponderType.t1,
        westToCentralStart + spacing1 * 9, 100,
        description: 'T1 - Crossover Tag');
    addTransponder('T1_WC_6_LOW', TransponderType.t1,
        westToCentralStart + spacing1 * 9, 300,
        description: 'T1 - Crossover Tag');

    final centralToEastDist = 1200.0;
    final centralToEastStart = 1200.0 + 25;
    final spacing2 = centralToEastDist / 10;
    addTransponder('T1_CE_1_UP', TransponderType.t1,
        centralToEastStart + spacing2 * 1, 100,
        description: 'T1 - Crossover Tag');
    addTransponder('T1_CE_1_LOW', TransponderType.t1,
        centralToEastStart + spacing2 * 1, 300,
        description: 'T1 - Crossover Tag');
    addTransponder('T1_CE_2_UP', TransponderType.t1,
        centralToEastStart + spacing2 * 2, 100,
        description: 'T1 - Crossover Tag');
    addTransponder('T1_CE_2_LOW', TransponderType.t1,
        centralToEastStart + spacing2 * 2, 300,
        description: 'T1 - Crossover Tag');
    addTransponder('T1_CE_3_UP', TransponderType.t1,
        centralToEastStart + spacing2 * 3, 100,
        description: 'T1 - Crossover Tag');
    addTransponder('T1_CE_3_LOW', TransponderType.t1,
        centralToEastStart + spacing2 * 3, 300,
        description: 'T1 - Crossover Tag');
    addTransponder('T2_CE_1_UP', TransponderType.t2,
        centralToEastStart + spacing2 * 4, 100,
        description: 'T2 - Cross Border Tag');
    addTransponder('T2_CE_1_LOW', TransponderType.t2,
        centralToEastStart + spacing2 * 4, 300,
        description: 'T2 - Cross Border Tag');
    addTransponder('T3_CE_UP', TransponderType.t3,
        centralToEastStart + spacing2 * 5, 100,
        description: 'T3 - Border Tag');
    addTransponder('T3_CE_LOW', TransponderType.t3,
        centralToEastStart + spacing2 * 5, 300,
        description: 'T3 - Border Tag');
    addTransponder('T2_CE_2_UP', TransponderType.t2,
        centralToEastStart + spacing2 * 6, 100,
        description: 'T2 - Cross Border Tag');
    addTransponder('T2_CE_2_LOW', TransponderType.t2,
        centralToEastStart + spacing2 * 6, 300,
        description: 'T2 - Cross Border Tag');
    addTransponder('T1_CE_4_UP', TransponderType.t1,
        centralToEastStart + spacing2 * 7, 100,
        description: 'T1 - Crossover Tag');
    addTransponder('T1_CE_4_LOW', TransponderType.t1,
        centralToEastStart + spacing2 * 7, 300,
        description: 'T1 - Crossover Tag');
    addTransponder('T1_CE_5_UP', TransponderType.t1,
        centralToEastStart + spacing2 * 8, 100,
        description: 'T1 - Crossover Tag');
    addTransponder('T1_CE_5_LOW', TransponderType.t1,
        centralToEastStart + spacing2 * 8, 300,
        description: 'T1 - Crossover Tag');
    addTransponder('T1_CE_6_UP', TransponderType.t1,
        centralToEastStart + spacing2 * 9, 100,
        description: 'T1 - Crossover Tag');
    addTransponder('T1_CE_6_LOW', TransponderType.t1,
        centralToEastStart + spacing2 * 9, 300,
        description: 'T1 - Crossover Tag');

    _textAnnotations['TXT1'] = const TextAnnotation(
      id: 'TXT1',
      name: 'TXT1',
      description: '',
      notes: '',
      color: Color(0xFF5A3E2B),
      text: 'Terminal Station Default Layout',
      x: 200,
      y: 40,
    );

    _selected = null;
  }

  String exportXml() {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
      builder.element('terminalStation', nest: () {
        builder.element('settings', nest: () {}, attributes: {
          'backgroundColor': _colorToHex(_backgroundColor),
          'gridVisible': _gridVisible.toString(),
          'gridSize': _gridSize.toStringAsFixed(2),
          'snapToGrid': _snapToGrid.toString(),
          'magnetEnabled': _magnetEnabled.toString(),
          'guidewayVisible': _guidewayDirectionsVisible.toString(),
          'compassVisible': _compassVisible.toString(),
          'alphaGammaVisible': _alphaGammaVisible.toString(),
        });
        builder.element('junctions', nest: () {
          for (final entry in _alphaGammaJunctions.entries) {
            builder.element('junction', nest: () {}, attributes: {
              'id': entry.key,
              'x': entry.value.dx.toStringAsFixed(2),
              'y': entry.value.dy.toStringAsFixed(2),
              'alphaGamma': 'true',
            });
          }
        });
        builder.element('blocks', nest: () {
        for (final segment in _segments.values) {
          final end = segment.endPoint();
      builder.element('block', nest: () {}, attributes: {
        'id': segment.id,
        'name': segment.name,
        'description': segment.description,
        'notes': segment.notes,
        'color': _colorToHex(segment.color),
        'style': segment.style.name,
        'guidewayDirection': segment.guidewayDirection.name,
        'startX': segment.startX.toStringAsFixed(2),
        'startY': segment.startY.toStringAsFixed(2),
        'endX': end.dx.toStringAsFixed(2),
            'endY': end.dy.toStringAsFixed(2),
            'length': segment.length.toStringAsFixed(2),
            'angleDeg': segment.angleDeg.toStringAsFixed(2),
            'occupied': segment.occupied.toString(),
          });
        }
      });
      builder.element('crossovers', nest: () {
        for (final xo in _crossovers.values) {
      builder.element('crossover', nest: () {}, attributes: {
        'id': xo.id,
        'name': xo.name,
        'description': xo.description,
        'notes': xo.notes,
        'color': _colorToHex(xo.color),
        'style': xo.style.name,
        'x': xo.x.toStringAsFixed(2),
        'y': xo.y.toStringAsFixed(2),
        'type': xo.type.name,
        'gapAngle': xo.gapAngle.toStringAsFixed(2),
          });
        }
      });
      builder.element('points', nest: () {
        for (final point in _points.values) {
      builder.element('point', nest: () {}, attributes: {
        'id': point.id,
        'name': point.name,
        'description': point.description,
        'notes': point.notes,
        'color': _colorToHex(point.color),
        'x': point.x.toStringAsFixed(2),
        'y': point.y.toStringAsFixed(2),
            'position': point.position.name,
            'locked': point.locked.toString(),
            'style': point.style.name,
            'orientation': point.orientation.name,
            'autoDetectOrientation': point.autoDetectOrientation.toString(),
          });
        }
      });
      builder.element('signals', nest: () {
        for (final signal in _signals.values) {
      builder.element('signal', nest: () {}, attributes: {
        'id': signal.id,
        'name': signal.name,
        'description': signal.description,
        'notes': signal.notes,
        'color': _colorToHex(signal.color),
        'x': signal.x.toStringAsFixed(2),
        'y': signal.y.toStringAsFixed(2),
            'direction': signal.direction.name,
            'aspect': signal.aspect.name,
          });
        }
      });
      builder.element('platforms', nest: () {
        for (final platform in _platforms.values) {
      builder.element('platform', nest: () {}, attributes: {
        'id': platform.id,
        'name': platform.name,
        'description': platform.description,
        'notes': platform.notes,
        'color': _colorToHex(platform.color),
        'startX': platform.startX.toStringAsFixed(2),
        'endX': platform.endX.toStringAsFixed(2),
        'y': platform.y.toStringAsFixed(2),
            'occupied': platform.occupied.toString(),
          });
        }
      });
      builder.element('trainStops', nest: () {
        for (final stop in _trainStops.values) {
      builder.element('trainStop', nest: () {}, attributes: {
        'id': stop.id,
        'name': stop.name,
        'description': stop.description,
        'notes': stop.notes,
        'color': _colorToHex(stop.color),
        'x': stop.x.toStringAsFixed(2),
        'y': stop.y.toStringAsFixed(2),
        'enabled': stop.enabled.toString(),
          });
        }
      });
      builder.element('bufferStops', nest: () {
        for (final stop in _bufferStops.values) {
      builder.element('bufferStop', nest: () {}, attributes: {
        'id': stop.id,
        'name': stop.name,
        'description': stop.description,
        'notes': stop.notes,
        'color': _colorToHex(stop.color),
        'x': stop.x.toStringAsFixed(2),
        'y': stop.y.toStringAsFixed(2),
        'width': stop.width.toStringAsFixed(2),
            'height': stop.height.toStringAsFixed(2),
          });
        }
      });
      builder.element('axleCounters', nest: () {
        for (final counter in _axleCounters.values) {
      builder.element('axleCounter', nest: () {}, attributes: {
        'id': counter.id,
        'name': counter.name,
        'description': counter.description,
        'notes': counter.notes,
        'color': _colorToHex(counter.color),
        'x': counter.x.toStringAsFixed(2),
        'y': counter.y.toStringAsFixed(2),
        'flipped': counter.flipped.toString(),
          });
        }
      });
      builder.element('transponders', nest: () {
        for (final transponder in _transponders.values) {
      builder.element('transponder', nest: () {}, attributes: {
        'id': transponder.id,
        'name': transponder.name,
        'description': transponder.description,
        'notes': transponder.notes,
        'color': _colorToHex(transponder.color),
        'x': transponder.x.toStringAsFixed(2),
        'y': transponder.y.toStringAsFixed(2),
        'type': transponder.type.name,
          });
        }
      });
      builder.element('wifiAntennas', nest: () {
        for (final wifi in _wifiAntennas.values) {
      builder.element('wifiAntenna', nest: () {}, attributes: {
        'id': wifi.id,
        'name': wifi.name,
        'description': wifi.description,
        'notes': wifi.notes,
        'color': _colorToHex(wifi.color),
        'x': wifi.x.toStringAsFixed(2),
        'y': wifi.y.toStringAsFixed(2),
        'isActive': wifi.isActive.toString(),
          });
        }
      });
      builder.element('texts', nest: () {
        for (final text in _textAnnotations.values) {
      builder.element('text', nest: () {}, attributes: {
        'id': text.id,
        'name': text.name,
        'description': text.description,
        'notes': text.notes,
        'color': _colorToHex(text.color),
        'x': text.x.toStringAsFixed(2),
        'y': text.y.toStringAsFixed(2),
        'value': text.text,
          });
        }
      });
    });
    return builder.buildDocument().toXmlString(pretty: true);
  }

  void importXml(String xmlContent) {
    final document = XmlDocument.parse(xmlContent);
    final roots = document.findElements('terminalStation');
    if (roots.isEmpty) return;
    final root = roots.first;

    _pushHistory();
    _segments.clear();
    _crossovers.clear();
    _points.clear();
    _signals.clear();
    _platforms.clear();
    _trainStops.clear();
    _bufferStops.clear();
    _axleCounters.clear();
    _transponders.clear();
    _wifiAntennas.clear();
    _textAnnotations.clear();

    final settings = root.getElement('settings');
    if (settings != null) {
      _backgroundColor = _parseColor(
          settings.getAttribute('backgroundColor'), _backgroundColor);
      _gridVisible = _parseBool(settings, 'gridVisible', _gridVisible);
      _gridSize = _parseDouble(settings, 'gridSize', _gridSize);
      _snapToGrid = _parseBool(settings, 'snapToGrid', _snapToGrid);
      _magnetEnabled = _parseBool(settings, 'magnetEnabled', _magnetEnabled);
      _guidewayDirectionsVisible = _parseBool(
          settings, 'guidewayVisible', _guidewayDirectionsVisible);
      _compassVisible =
          _parseBool(settings, 'compassVisible', _compassVisible);
      _alphaGammaVisible =
          _parseBool(settings, 'alphaGammaVisible', _alphaGammaVisible);
    }

    final junctions = root.getElement('junctions');
    if (junctions != null) {
      for (final node in junctions.findElements('junction')) {
        final id = node.getAttribute('id');
        if (id == null || id.isEmpty) continue;
        final x = _parseDouble(node, 'x', 0);
        final y = _parseDouble(node, 'y', 0);
        final alpha = _parseBool(node, 'alphaGamma', false);
        if (alpha) {
          _alphaGammaJunctions[id] = Offset(x, y);
        }
      }
    }

    for (final block in root.findAllElements('block')) {
      final id = block.getAttribute('id') ?? 'T${_segments.length + 1}';
      final startX = _parseDouble(block, 'startX', 0);
      final startY = _parseDouble(block, 'startY', _parseDouble(block, 'y', 0));
      final endX = _parseDouble(block, 'endX', startX + 120);
      final endY = _parseDouble(block, 'endY', startY);
      final dx = endX - startX;
      final dy = endY - startY;
      final length =
          _parseDouble(block, 'length', math.sqrt(dx * dx + dy * dy));
      final angleDeg = _parseDouble(
          block, 'angleDeg', math.atan2(dy, dx) * 180.0 / math.pi);
      _segments[id] = TrackSegment(
        id: id,
        name: block.getAttribute('name') ?? id,
        description: block.getAttribute('description') ?? '',
        notes: block.getAttribute('notes') ?? '',
        color: _parseColor(block.getAttribute('color'), const Color(0xFF2E86AB)),
        style: _parseTrackStyle(block.getAttribute('style')),
        guidewayDirection:
            _parseGuidewayDirection(block.getAttribute('guidewayDirection')),
        startX: startX,
        startY: startY,
        length: length,
        angleDeg: angleDeg,
        occupied: _parseBool(block, 'occupied', false),
      );
    }

    for (final xo in root.findAllElements('crossover')) {
      final id = xo.getAttribute('id') ?? 'X${_crossovers.length + 1}';
      _crossovers[id] = Crossover(
        id: id,
        name: xo.getAttribute('name') ?? id,
        description: xo.getAttribute('description') ?? '',
        notes: xo.getAttribute('notes') ?? '',
        color: _parseColor(xo.getAttribute('color'), const Color(0xFF4C566A)),
        style: _parseTrackStyle(xo.getAttribute('style')),
        x: _parseDouble(xo, 'x', 0),
        y: _parseDouble(xo, 'y', 0),
        type: CrossoverType.values.firstWhere(
          (t) => t.name == xo.getAttribute('type'),
          orElse: () => CrossoverType.righthand,
        ),
        gapAngle: _parseDouble(xo, 'gapAngle', _defaultGapAngle),
      );
    }

    for (final point in root.findAllElements('point')) {
      final id = point.getAttribute('id') ?? 'P${_points.length + 1}';
      _points[id] = TrackPoint(
        id: id,
        name: point.getAttribute('name') ?? id,
        description: point.getAttribute('description') ?? '',
        notes: point.getAttribute('notes') ?? '',
        color: _parseColor(point.getAttribute('color'), const Color(0xFF2A9D8F)),
        x: _parseDouble(point, 'x', 0),
        y: _parseDouble(point, 'y', 0),
        position: PointPosition.values.firstWhere(
          (p) => p.name == point.getAttribute('position'),
          orElse: () => PointPosition.normal,
        ),
        locked: _parseBool(point, 'locked', false),
        style: _parsePointStyle(point.getAttribute('style')),
        orientation: _parsePointOrientation(point.getAttribute('orientation')),
        autoDetectOrientation:
            _parseBool(point, 'autoDetectOrientation', false),
      );
    }

    for (final signal in root.findAllElements('signal')) {
      final id = signal.getAttribute('id') ?? 'S${_signals.length + 1}';
      _signals[id] = Signal(
        id: id,
        name: signal.getAttribute('name') ?? id,
        description: signal.getAttribute('description') ?? '',
        notes: signal.getAttribute('notes') ?? '',
        color: _parseColor(signal.getAttribute('color'), const Color(0xFFE63946)),
        x: _parseDouble(signal, 'x', 0),
        y: _parseDouble(signal, 'y', 0),
        direction: SignalDirection.values.firstWhere(
          (d) => d.name == signal.getAttribute('direction'),
          orElse: () => SignalDirection.east,
        ),
        aspect: SignalAspect.values.firstWhere(
          (a) => a.name == signal.getAttribute('aspect'),
          orElse: () => SignalAspect.red,
        ),
      );
    }

    for (final platform in root.findAllElements('platform')) {
      final id = platform.getAttribute('id') ?? 'PL${_platforms.length + 1}';
      _platforms[id] = Platform(
        id: id,
        name: platform.getAttribute('name') ?? id,
        description: platform.getAttribute('description') ?? '',
        notes: platform.getAttribute('notes') ?? '',
        color: _parseColor(platform.getAttribute('color'), const Color(0xFF6D597A)),
        startX: _parseDouble(platform, 'startX', 0),
        endX: _parseDouble(platform, 'endX', 120),
        y: _parseDouble(platform, 'y', 0),
        occupied: _parseBool(platform, 'occupied', false),
      );
    }

    for (final stop in root.findAllElements('trainStop')) {
      final id = stop.getAttribute('id') ?? 'TS${_trainStops.length + 1}';
      _trainStops[id] = TrainStop(
        id: id,
        name: stop.getAttribute('name') ?? id,
        description: stop.getAttribute('description') ?? '',
        notes: stop.getAttribute('notes') ?? '',
        color: _parseColor(stop.getAttribute('color'), const Color(0xFFF4A261)),
        x: _parseDouble(stop, 'x', 0),
        y: _parseDouble(stop, 'y', 0),
        enabled: _parseBool(stop, 'enabled', true),
      );
    }

    for (final stop in root.findAllElements('bufferStop')) {
      final id = stop.getAttribute('id') ?? 'BS${_bufferStops.length + 1}';
      _bufferStops[id] = BufferStop(
        id: id,
        name: stop.getAttribute('name') ?? id,
        description: stop.getAttribute('description') ?? '',
        notes: stop.getAttribute('notes') ?? '',
        color: _parseColor(stop.getAttribute('color'), const Color(0xFFB00020)),
        x: _parseDouble(stop, 'x', 0),
        y: _parseDouble(stop, 'y', 0),
        width: _parseDouble(stop, 'width', 32),
        height: _parseDouble(stop, 'height', 18),
      );
    }

    for (final counter in root.findAllElements('axleCounter')) {
      final id = counter.getAttribute('id') ?? 'AC${_axleCounters.length + 1}';
      _axleCounters[id] = AxleCounter(
        id: id,
        name: counter.getAttribute('name') ?? id,
        description: counter.getAttribute('description') ?? '',
        notes: counter.getAttribute('notes') ?? '',
        color: _parseColor(counter.getAttribute('color'), const Color(0xFF457B9D)),
        x: _parseDouble(counter, 'x', 0),
        y: _parseDouble(counter, 'y', 0),
        flipped: _parseBool(counter, 'flipped', false),
      );
    }

    for (final transponder in root.findAllElements('transponder')) {
      final id = transponder.getAttribute('id') ?? 'T${_transponders.length + 1}';
      _transponders[id] = Transponder(
        id: id,
        name: transponder.getAttribute('name') ?? id,
        description: transponder.getAttribute('description') ?? '',
        notes: transponder.getAttribute('notes') ?? '',
        color: _parseColor(transponder.getAttribute('color'), const Color(0xFF118AB2)),
        x: _parseDouble(transponder, 'x', 0),
        y: _parseDouble(transponder, 'y', 0),
        type: TransponderType.values.firstWhere(
          (t) => t.name == transponder.getAttribute('type'),
          orElse: () => TransponderType.t1,
        ),
      );
    }

    for (final wifi in root.findAllElements('wifiAntenna')) {
      final id = wifi.getAttribute('id') ?? 'W${_wifiAntennas.length + 1}';
      _wifiAntennas[id] = WifiAntenna(
        id: id,
        name: wifi.getAttribute('name') ?? id,
        description: wifi.getAttribute('description') ?? '',
        notes: wifi.getAttribute('notes') ?? '',
        color: _parseColor(wifi.getAttribute('color'), const Color(0xFF06D6A0)),
        x: _parseDouble(wifi, 'x', 0),
        y: _parseDouble(wifi, 'y', 0),
        isActive: _parseBool(wifi, 'isActive', true),
      );
    }

    for (final text in root.findAllElements('text')) {
      final id = text.getAttribute('id') ?? 'TXT${_textAnnotations.length + 1}';
      _textAnnotations[id] = TextAnnotation(
        id: id,
        name: text.getAttribute('name') ?? id,
        description: text.getAttribute('description') ?? '',
        notes: text.getAttribute('notes') ?? '',
        color: _parseColor(text.getAttribute('color'), const Color(0xFF5A3E2B)),
        text: text.getAttribute('value') ?? '',
        x: _parseDouble(text, 'x', 0),
        y: _parseDouble(text, 'y', 0),
      );
    }

    _selected = null;
    notifyListeners();
  }

  double _parseDouble(XmlElement element, String name, double fallback) {
    final value = element.getAttribute(name);
    if (value == null) return fallback;
    return double.tryParse(value) ?? fallback;
  }

  bool _parseBool(XmlElement element, String name, bool fallback) {
    final value = element.getAttribute(name);
    if (value == null) return fallback;
    return value.toLowerCase() == 'true';
  }

  Color _parseColor(String? value, Color fallback) {
    if (value == null || value.isEmpty) return fallback;
    final normalized = value.replaceAll('#', '');
    if (normalized.length == 6) {
      final parsed = int.tryParse(normalized, radix: 16);
      if (parsed == null) return fallback;
      return Color(0xFF000000 | parsed);
    }
    if (normalized.length == 8) {
      final parsed = int.tryParse(normalized, radix: 16);
      if (parsed == null) return fallback;
      return Color(parsed);
    }
    return fallback;
  }

  TrackStyle _parseTrackStyle(String? value) {
    if (value == null || value.isEmpty) return TrackStyle.ballast;
    return TrackStyle.values.firstWhere(
      (style) => style.name == value,
      orElse: () => TrackStyle.ballast,
    );
  }

  GuidewayDirection _parseGuidewayDirection(String? value) {
    if (value == null || value.isEmpty) return GuidewayDirection.gd1;
    return GuidewayDirection.values.firstWhere(
      (dir) => dir.name == value,
      orElse: () => GuidewayDirection.gd1,
    );
  }

  PointStyle _parsePointStyle(String? value) {
    if (value == null || value.isEmpty) return PointStyle.classic;
    return PointStyle.values.firstWhere(
      (style) => style.name == value,
      orElse: () => PointStyle.classic,
    );
  }

  PointOrientation _parsePointOrientation(String? value) {
    if (value == null || value.isEmpty) return PointOrientation.upRight;
    return PointOrientation.values.firstWhere(
      (orientation) => orientation.name == value,
      orElse: () => PointOrientation.upRight,
    );
  }

  PointOrientation _detectPointOrientation(
    double x,
    double y,
    PointOrientation fallback,
  ) {
    final position = Offset(x, y);
    final hits = _segmentHitsNearPoint(position, 32);
    if (hits.isEmpty) return fallback;

    final mainline = hits.first;
    _SegmentHit? branch;
    const minAngleDiff = 15.0;
    for (final hit in hits.skip(1)) {
      final diff =
          _angleDiffDegrees(mainline.segment.angleDeg, hit.segment.angleDeg);
      if (diff >= minAngleDiff) {
        branch = hit;
        break;
      }
    }
    branch ??= hits.length > 1 ? hits[1] : null;
    if (branch == null) return fallback;

    final dir = _segmentDirectionFromPoint(branch.segment, branch.t);
    if (dir == Offset.zero) return fallback;
    final isRight = dir.dx >= 0;
    final isUp = dir.dy < 0;
    if (isUp && isRight) return PointOrientation.upRight;
    if (isUp && !isRight) return PointOrientation.upLeft;
    if (!isUp && isRight) return PointOrientation.downRight;
    return PointOrientation.downLeft;
  }

  List<_SegmentHit> _segmentHitsNearPoint(Offset point, double maxDistance) {
    final hits = <_SegmentHit>[];
    for (final segment in _segments.values) {
      final start = Offset(segment.startX, segment.startY);
      final end = segment.endPoint();
      final projection = _closestPointOnSegment(point, start, end);
      final distance = (point - projection.point).distance;
      if (distance <= maxDistance) {
        hits.add(_SegmentHit(
          segment: segment,
          distance: distance,
          t: projection.t,
        ));
      }
    }
    hits.sort((a, b) => a.distance.compareTo(b.distance));
    return hits;
  }

  Offset _segmentDirectionFromPoint(TrackSegment segment, double t) {
    final start = Offset(segment.startX, segment.startY);
    final end = segment.endPoint();
    if ((end - start).distance == 0) return Offset.zero;
    if (t <= 0.5) {
      return (end - start);
    }
    return (start - end);
  }

  _Projection _closestPointOnSegment(Offset point, Offset start, Offset end) {
    final length = (end - start).distance;
    if (length == 0) return _Projection(point: start, t: 0);
    final t = ((point.dx - start.dx) * (end.dx - start.dx) +
            (point.dy - start.dy) * (end.dy - start.dy)) /
        (length * length);
    final clamped = t.clamp(0.0, 1.0);
    final projection =
        Offset(start.dx + clamped * (end.dx - start.dx), start.dy + clamped * (end.dy - start.dy));
    return _Projection(point: projection, t: clamped);
  }

  double _distanceToLine(Offset point, Offset start, Offset end) {
    final length = (end - start).distance;
    if (length == 0) return double.infinity;
    final t = ((point.dx - start.dx) * (end.dx - start.dx) +
            (point.dy - start.dy) * (end.dy - start.dy)) /
        (length * length);
    final clamped = t.clamp(0.0, 1.0);
    final projection =
        Offset(start.dx + clamped * (end.dx - start.dx), start.dy + clamped * (end.dy - start.dy));
    return (point - projection).distance;
  }

  double _angleDiffDegrees(double a, double b) {
    final diff = (a - b).abs() % 360;
    return diff > 180 ? 360 - diff : diff;
  }

  String _colorToHex(Color color) {
    final rgb = color.value & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  Map<String, dynamic> exportSimulationLayout() {
    final blocks = _segments.values.map((segment) {
      final end = segment.endPoint();
      return {
        'id': segment.id,
        'name': segment.name,
        'startX': segment.startX,
        'endX': end.dx,
        'y': segment.startY,
        'endY': end.dy,
        'occupied': segment.occupied,
      };
    }).toList();

    final signals = _signals.values.map((signal) {
      final aspect = signal.aspect == SignalAspect.yellow
          ? SignalAspect.red
          : signal.aspect;
      return {
        'id': signal.id,
        'x': signal.x,
        'y': signal.y,
        'aspect': aspect.name,
      };
    }).toList();

    final points = _points.values.map((point) {
      return {
        'id': point.id,
        'x': point.x,
        'y': point.y,
        'position': point.position.name,
      };
    }).toList();

    final crossovers = _crossovers.values.map((crossover) {
      final position = Offset(crossover.x, crossover.y);
      return {
        'id': crossover.id,
        'name': crossover.name,
        'pointIds': _nearbyPointIds(position, 80),
        'blockId': _nearestSegmentId(position),
        'type': crossover.type.name,
        'gapAngle': gapAngleForCrossover(crossover),
      };
    }).toList();

    final platforms = _platforms.values.map((platform) {
      return {
        'id': platform.id,
        'name': platform.name,
        'startX': platform.startX,
        'endX': platform.endX,
        'y': platform.y,
      };
    }).toList();

    final trainStops = _trainStops.values.map((stop) {
      final position = Offset(stop.x, stop.y);
      return {
        'id': stop.id,
        'signalId': _nearestSignalId(position),
        'x': stop.x,
        'y': stop.y,
        'active': stop.enabled,
      };
    }).toList();

    final bufferStops = _bufferStops.values.map((stop) {
      return {
        'id': stop.id,
        'x': stop.x,
        'y': stop.y,
      };
    }).toList();

    final axleCounters = _axleCounters.values.map((counter) {
      final position = Offset(counter.x, counter.y);
      return {
        'id': counter.id,
        'blockId': _nearestSegmentId(position),
        'x': counter.x,
        'y': counter.y,
        'flipped': counter.flipped,
      };
    }).toList();

    final transponders = _transponders.values.map((transponder) {
      return {
        'id': transponder.id,
        'x': transponder.x,
        'y': transponder.y,
        'type': transponder.type.name,
        'description': transponder.description,
      };
    }).toList();

    final wifiAntennas = _wifiAntennas.values.map((wifi) {
      return {
        'id': wifi.id,
        'x': wifi.x,
        'y': wifi.y,
        'isActive': wifi.isActive,
      };
    }).toList();

    return {
      'version': '1.0',
      'dynamicRouting': true,
      'blocks': blocks,
      'signals': signals,
      'points': points,
      'crossovers': crossovers,
      'platforms': platforms,
      'trainStops': trainStops,
      'bufferStops': bufferStops,
      'axleCounters': axleCounters,
      'transponders': transponders,
      'wifiAntennas': wifiAntennas,
    };
  }

  String _nearestSegmentId(Offset position) {
    String? bestId;
    double bestDistance = double.infinity;
    for (final segment in _segments.values) {
      final start = Offset(segment.startX, segment.startY);
      final end = segment.endPoint();
      final distance = _distanceToLine(position, start, end);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestId = segment.id;
      }
    }
    return bestId ?? '';
  }

  String _nearestSignalId(Offset position) {
    String? bestId;
    double bestDistance = double.infinity;
    for (final signal in _signals.values) {
      final distance =
          (position - Offset(signal.x, signal.y)).distance;
      if (distance < bestDistance) {
        bestDistance = distance;
        bestId = signal.id;
      }
    }
    return bestId ?? '';
  }

  List<String> _nearbyPointIds(Offset position, double radius) {
    return _points.values
        .where((point) =>
            (position - Offset(point.x, point.y)).distance <= radius)
        .map((point) => point.id)
        .toList();
  }
}

class _EditorState {
  final Map<String, TrackSegment> segments;
  final Map<String, Crossover> crossovers;
  final Map<String, TrackPoint> points;
  final Map<String, Signal> signals;
  final Map<String, Platform> platforms;
  final Map<String, TrainStop> trainStops;
  final Map<String, BufferStop> bufferStops;
  final Map<String, AxleCounter> axleCounters;
  final Map<String, Transponder> transponders;
  final Map<String, WifiAntenna> wifiAntennas;
  final Map<String, TextAnnotation> textAnnotations;
  final Map<String, BuilderRenderStyle> renderOverrides;
  final SelectedComponent? selected;

  _EditorState({
    required this.segments,
    required this.crossovers,
    required this.points,
    required this.signals,
    required this.platforms,
    required this.trainStops,
    required this.bufferStops,
    required this.axleCounters,
    required this.transponders,
    required this.wifiAntennas,
    required this.textAnnotations,
    required this.renderOverrides,
    required this.selected,
  });
}

enum _AxisOrientation { north, south, east, west }

class ValidationIssue {
  final ValidationSeverity severity;
  final String message;

  const ValidationIssue({
    required this.severity,
    required this.message,
  });
}

class _Endpoint {
  final String segmentId;
  final Offset position;

  const _Endpoint(this.segmentId, this.position);
}

class Junction {
  final String id;
  final Offset position;
  final bool isAlphaGamma;

  const Junction({
    required this.id,
    required this.position,
    required this.isAlphaGamma,
  });
}

class _SegmentHit {
  final TrackSegment segment;
  final double distance;
  final double t;

  const _SegmentHit({
    required this.segment,
    required this.distance,
    required this.t,
  });
}

class _Projection {
  final Offset point;
  final double t;

  const _Projection({
    required this.point,
    required this.t,
  });
}
