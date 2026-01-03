import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'dart:math';

import '../models/railway_model.dart' as railway;
import '../utils/xml_parser.dart';
import '../utils/svg_generator.dart';
import '../utils/xml_generator.dart';

class RailwayProvider with ChangeNotifier {
  final List<railway.WorkspaceTab> _tabs = [];
  int _currentTabIndex = 0;
  String _currentSvg = '';
  bool _isLoading = false;
  String? _errorMessage;

  railway.ToolMode _currentTool = railway.ToolMode.select;
  railway.TransformMode _transformMode = railway.TransformMode.select;
  railway.Selection? _selectedElement;
  bool _leftSidebarVisible = true;
  bool _rightSidebarVisible = true;
  railway.GridSettings _gridSettings = const railway.GridSettings();
  double _zoomLevel = 1.0;

  railway.DraggableTool? _draggedTool;
  Offset? _dragPosition;
  bool _isDraggingElement = false;
  Offset? _elementDragStart;

  bool _isTransforming = false;
  Offset _transformStart = Offset.zero;
  double _rotationAngle = 0.0;
  double _scaleFactor = 1.0;

  List<railway.Measurement> _measurements = [];
  List<railway.TextAnnotation> _textAnnotations = [];
  bool _isMeasuring = false;
  Offset? _measureStart;
  Offset? _measureEnd;

  railway.RailwayData get data => _currentTab.data;
  List<railway.WorkspaceTab> get tabs => _tabs;
  int get currentTabIndex => _currentTabIndex;
  railway.WorkspaceTab get _currentTab => _tabs[_currentTabIndex];
  String get currentSvg => _currentSvg;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  railway.ToolMode get currentTool => _currentTool;
  railway.TransformMode get transformMode => _transformMode;
  railway.Selection? get selectedElement => _selectedElement;
  bool get leftSidebarVisible => _leftSidebarVisible;
  bool get rightSidebarVisible => _rightSidebarVisible;
  railway.GridSettings get gridSettings => _gridSettings;
  double get zoomLevel => _zoomLevel;
  bool get showGrid => _gridSettings.enabled;
  bool get showCoordinates => _gridSettings.showCoordinates;
  railway.DraggableTool? get draggedTool => _draggedTool;
  Offset? get dragPosition => _dragPosition;
  bool get isDraggingElement => _isDraggingElement;
  bool get isTransforming => _isTransforming;
  double get rotationAngle => _rotationAngle;
  double get scaleFactor => _scaleFactor;
  bool get hasUnsavedChanges => _currentTab.hasUnsavedChanges;
  List<railway.Measurement> get measurements => _measurements;
  List<railway.TextAnnotation> get textAnnotations => _textAnnotations;
  bool get isMeasuring => _isMeasuring;

  Offset? get measureStart => _measureStart;
  Offset? get measureEnd => _measureEnd;

  set currentTool(railway.ToolMode tool) {
    _currentTool = tool;
    _selectedElement = null;
    _isMeasuring = false;
    _measureStart = null;
    _measureEnd = null;
    notifyListeners();
  }

  set transformMode(railway.TransformMode mode) {
    _transformMode = mode;
    notifyListeners();
  }

  set leftSidebarVisible(bool visible) {
    _leftSidebarVisible = visible;
    notifyListeners();
  }

  set rightSidebarVisible(bool visible) {
    _rightSidebarVisible = visible;
    notifyListeners();
  }

  set gridSettings(railway.GridSettings settings) {
    _gridSettings = settings;
    _updateCurrentSvg();
    notifyListeners();
  }

  set zoomLevel(double zoom) {
    _zoomLevel = zoom.clamp(0.1, 5.0);
    notifyListeners();
  }

  set showGrid(bool show) {
    _gridSettings = _gridSettings.copyWith(enabled: show);
    _updateCurrentSvg();
    notifyListeners();
  }

  set showCoordinates(bool show) {
    _gridSettings = _gridSettings.copyWith(showCoordinates: show);
    notifyListeners();
  }

  void addNewTab() {
    final newTab = railway.WorkspaceTab(
      id: 'tab_${DateTime.now().millisecondsSinceEpoch}',
      title: 'New Track ${_tabs.length + 1}',
      data: railway.RailwayData(
        blocks: [],
        points: [],
        signals: [],
        platforms: [],
      ),
    );
    _tabs.add(newTab);
    _currentTabIndex = _tabs.length - 1;
    _updateCurrentSvg();
    notifyListeners();
  }

  void switchTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      _currentTabIndex = index;
      _updateCurrentSvg();
      notifyListeners();
    }
  }

  void closeTab(int index) {
    if (_tabs[index].hasUnsavedChanges) {
      return;
    }
    _tabs.removeAt(index);
    if (_currentTabIndex >= _tabs.length) {
      _currentTabIndex = max(0, _tabs.length - 1);
    }
    if (_tabs.isEmpty) {
      addNewTab();
    }
    _updateCurrentSvg();
    notifyListeners();
  }

  void updateTabData(railway.RailwayData newData, {bool regenerateSvg = true}) {
    _tabs[_currentTabIndex] = _currentTab.copyWith(
      data: newData,
      hasUnsavedChanges: true,
    );
    if (regenerateSvg) {
      _updateCurrentSvg();
    }
    notifyListeners();
  }

  void markTabSaved() {
    _tabs[_currentTabIndex] = _currentTab.copyWith(
      hasUnsavedChanges: false,
    );
    notifyListeners();
  }

  void initializeWithDefault() {
    _isLoading = true;
    notifyListeners();

    try {
      final defaultBlocks = [
        railway.Block(
          id: 'track1',
          startX: 100,
          endX: 500,
          y: 200,
          occupied: false,
          occupyingTrain: 'none',
          type: railway.BlockType.straight,
        ),
        railway.Block(
          id: 'track2',
          startX: 100,
          endX: 500,
          y: 300,
          occupied: false,
          occupyingTrain: 'none',
          type: railway.BlockType.straight,
        ),
      ];

      updateTabData(railway.RailwayData(
        blocks: defaultBlocks,
        points: [],
        signals: [],
        platforms: [],
      ));
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to initialize: $e';
      _currentSvg = _generateErrorSvg(_errorMessage!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectElement(dynamic element, String type) {
    _selectedElement = railway.Selection(element: element, type: type);
    notifyListeners();
  }

  void clearSelection() {
    _selectedElement = null;
    notifyListeners();
  }

  Offset _snapToGrid(Offset position) {
    if (!_gridSettings.snapToGrid) return position;

    final cellSize = _gridSettings.cellSize;
    final snappedX = (position.dx / cellSize).round() * cellSize;
    final snappedY = (position.dy / cellSize).round() * cellSize;

    return Offset(snappedX, snappedY);
  }

  List<railway.ConnectionPoint> _findNearbyConnections(
      Offset position, double radius) {
    final connections = <railway.ConnectionPoint>[];
    final radiusSquared = radius * radius;

    for (final block in data.blocks) {
      final startDist =
          pow(position.dx - block.startX, 2) + pow(position.dy - block.y, 2);
      final endDist =
          pow(position.dx - block.endX, 2) + pow(position.dy - block.y, 2);
      final centerDist =
          pow(position.dx - block.centerX, 2) + pow(position.dy - block.y, 2);

      if (startDist <= radiusSquared) {
        connections.add(railway.ConnectionPoint(
          elementId: block.id,
          elementType: 'block',
          x: block.startX,
          y: block.y,
          type: railway.ConnectionType.start,
        ));
      }
      if (endDist <= radiusSquared) {
        connections.add(railway.ConnectionPoint(
          elementId: block.id,
          elementType: 'block',
          x: block.endX,
          y: block.y,
          type: railway.ConnectionType.end,
        ));
      }
      if (centerDist <= radiusSquared) {
        connections.add(railway.ConnectionPoint(
          elementId: block.id,
          elementType: 'block',
          x: block.centerX,
          y: block.y,
          type: railway.ConnectionType.center,
        ));
      }
    }

    for (final point in data.points) {
      final dist =
          pow(position.dx - point.x, 2) + pow(position.dy - point.y, 2);
      if (dist <= radiusSquared) {
        connections.add(railway.ConnectionPoint(
          elementId: point.id,
          elementType: 'point',
          x: point.x,
          y: point.y,
          type: railway.ConnectionType.point,
        ));
      }
    }

    for (final signal in data.signals) {
      final dist =
          pow(position.dx - signal.x, 2) + pow(position.dy - signal.y, 2);
      if (dist <= radiusSquared) {
        connections.add(railway.ConnectionPoint(
          elementId: signal.id,
          elementType: 'signal',
          x: signal.x,
          y: signal.y,
          type: railway.ConnectionType.signal,
        ));
      }
    }

    for (final platform in data.platforms) {
      final startDist = pow(position.dx - platform.startX, 2) +
          pow(position.dy - platform.y, 2);
      final endDist = pow(position.dx - platform.endX, 2) +
          pow(position.dy - platform.y, 2);

      if (startDist <= radiusSquared) {
        connections.add(railway.ConnectionPoint(
          elementId: platform.id,
          elementType: 'platform',
          x: platform.startX,
          y: platform.y,
          type: railway.ConnectionType.platformStart,
        ));
      }
      if (endDist <= radiusSquared) {
        connections.add(railway.ConnectionPoint(
          elementId: platform.id,
          elementType: 'platform',
          x: platform.endX,
          y: platform.y,
          type: railway.ConnectionType.platformEnd,
        ));
      }
    }

    return connections;
  }

  Offset _snapToConnections(Offset position) {
    const snapRadius = 15.0;
    final nearbyConnections = _findNearbyConnections(position, snapRadius);

    if (nearbyConnections.isEmpty) return position;

    railway.ConnectionPoint? closestConnection;
    double minDistance = double.infinity;

    for (final connection in nearbyConnections) {
      final distance = (position - Offset(connection.x, connection.y)).distance;
      if (distance < minDistance) {
        minDistance = distance;
        closestConnection = connection;
      }
    }

    return closestConnection != null
        ? Offset(closestConnection.x, closestConnection.y)
        : position;
  }

  void startDrag(railway.DraggableTool tool, Offset position) {
    _draggedTool = tool;
    _dragPosition = position;
    _currentTool = tool.toolMode;
    notifyListeners();
  }

  void updateDragPosition(Offset position) {
    _dragPosition = position;
    notifyListeners();
  }

  void endDrag(Offset dropPosition) {
    if (_draggedTool != null) {
      _handleDrop(_draggedTool!, dropPosition);
    }
    _draggedTool = null;
    _dragPosition = null;
    notifyListeners();
  }

  void _handleDrop(railway.DraggableTool tool, Offset position) {
    var finalPosition = position;

    if (_gridSettings.snapToGrid) {
      finalPosition = _snapToGrid(finalPosition);
      finalPosition = _snapToConnections(finalPosition);
    }

    switch (tool.toolMode) {
      case railway.ToolMode.block:
        _createBlockAtPosition(tool, finalPosition);
        break;
      case railway.ToolMode.signal:
        _createSignalAtPosition(tool, finalPosition);
        break;
      case railway.ToolMode.point:
        _createPointAtPosition(tool, finalPosition);
        break;
      case railway.ToolMode.platform:
        _createPlatformAtPosition(tool, finalPosition);
        break;
      case railway.ToolMode.text:
        _createTextAnnotationAtPosition(finalPosition);
        break;
      case railway.ToolMode.route:
      case railway.ToolMode.select:
      case railway.ToolMode.delete:
      case railway.ToolMode.measure:
        break;
    }
  }

  void _createBlockAtPosition(railway.DraggableTool tool, Offset position) {
    final block = railway.Block(
      id: '${tool.id}_${DateTime.now().millisecondsSinceEpoch}',
      startX: position.dx - 50,
      endX: position.dx + 50,
      y: position.dy,
      occupied: false,
      occupyingTrain: 'none',
      type: tool.blockType ?? railway.BlockType.straight,
    );
    addBlock(block);
  }

  void _createSignalAtPosition(railway.DraggableTool tool, Offset position) {
    final signal = railway.Signal(
      id: 'S${DateTime.now().millisecondsSinceEpoch}',
      x: position.dx,
      y: position.dy,
      aspect: 'red',
      state: 'unset',
      routes: [],
    );
    addSignal(signal);
  }

  void _createPointAtPosition(railway.DraggableTool tool, Offset position) {
    final point = railway.Point(
      id: 'P${DateTime.now().millisecondsSinceEpoch}',
      x: position.dx,
      y: position.dy,
      position: 'normal',
      locked: false,
    );
    addPoint(point);
  }

  void _createPlatformAtPosition(railway.DraggableTool tool, Offset position) {
    final platform = railway.Platform(
      id: 'PL${DateTime.now().millisecondsSinceEpoch}',
      name: 'Platform ${DateTime.now().millisecond}',
      startX: position.dx - 75,
      endX: position.dx + 75,
      y: position.dy,
      occupied: false,
    );
    addPlatform(platform);
  }

  void _createTextAnnotationAtPosition(Offset position) {
    final textAnnotation = railway.TextAnnotation(
      id: 'T${DateTime.now().millisecondsSinceEpoch}',
      text: 'New Text',
      position: position,
    );
    _textAnnotations.add(textAnnotation);
    notifyListeners();
  }

  void startElementDrag(Offset startPosition) {
    if (_selectedElement == null) return;

    _isDraggingElement = true;
    _elementDragStart = startPosition;
    notifyListeners();
  }

  void updateElementDrag(Offset currentPosition) {
    if (!_isDraggingElement || _selectedElement == null) return;

    var newPosition = currentPosition;

    if (_gridSettings.snapToGrid) {
      newPosition = _snapToGrid(newPosition);
      newPosition = _snapToConnections(newPosition);
    }

    _updateElementPosition(_selectedElement!, newPosition);
  }

  void endElementDrag() {
    _isDraggingElement = false;
    _elementDragStart = null;
    _markUnsavedChanges();
    _forceSvgUpdate();
  }

  void _updateElementPosition(railway.Selection selection, Offset newPosition) {
    switch (selection.type) {
      case 'block':
        final block = selection.element as railway.Block;
        final deltaX =
            newPosition.dx - (_elementDragStart?.dx ?? block.centerX);
        final updatedBlock = block.copyWith(
          startX: block.startX + deltaX,
          endX: block.endX + deltaX,
        );
        updateBlock(block.id, updatedBlock, regenerateSvg: false);
        break;

      case 'point':
        final point = selection.element as railway.Point;
        final updatedPoint = point.copyWith(
          x: newPosition.dx,
          y: newPosition.dy,
        );
        updatePoint(point.id, updatedPoint, regenerateSvg: false);
        break;

      case 'signal':
        final signal = selection.element as railway.Signal;
        final updatedSignal = signal.copyWith(
          x: newPosition.dx,
          y: newPosition.dy,
        );
        updateSignal(signal.id, updatedSignal, regenerateSvg: false);
        break;

      case 'platform':
        final platform = selection.element as railway.Platform;
        final deltaX = newPosition.dx -
            (_elementDragStart?.dx ?? platform.startX + platform.length / 2);
        final updatedPlatform = platform.copyWith(
          startX: platform.startX + deltaX,
          endX: platform.endX + deltaX,
        );
        updatePlatform(platform.id, updatedPlatform, regenerateSvg: false);
        break;
    }
  }

  void startTransform(Offset startPosition) {
    _isTransforming = true;
    _transformStart = startPosition;
    notifyListeners();
  }

  void updateRotation(double deltaAngle) {
    _rotationAngle += deltaAngle;
    notifyListeners();
  }

  void updateScale(double deltaScale) {
    _scaleFactor = (_scaleFactor + deltaScale).clamp(0.1, 5.0);
    notifyListeners();
  }

  void endTransform() {
    _isTransforming = false;
    _rotationAngle = 0.0;
    _scaleFactor = 1.0;
    _markUnsavedChanges();
    notifyListeners();
  }

  void duplicateSelectedElement() {
    if (_selectedElement == null) return;

    switch (_selectedElement!.type) {
      case 'block':
        final original = _selectedElement!.element as railway.Block;
        final duplicated = original.copyWith(
          id: '${original.id}_copy_${DateTime.now().millisecond}',
          startX: original.startX + 50,
          endX: original.endX + 50,
        );
        addBlock(duplicated);
        break;

      case 'point':
        final original = _selectedElement!.element as railway.Point;
        final duplicated = original.copyWith(
          id: '${original.id}_copy_${DateTime.now().millisecond}',
          x: original.x + 30,
          y: original.y + 30,
        );
        addPoint(duplicated);
        break;

      case 'signal':
        final original = _selectedElement!.element as railway.Signal;
        final duplicated = original.copyWith(
          id: '${original.id}_copy_${DateTime.now().millisecond}',
          x: original.x + 30,
          y: original.y + 30,
        );
        addSignal(duplicated);
        break;

      case 'platform':
        final original = _selectedElement!.element as railway.Platform;
        final duplicated = original.copyWith(
          id: '${original.id}_copy_${DateTime.now().millisecond}',
          startX: original.startX + 50,
          endX: original.endX + 50,
        );
        addPlatform(duplicated);
        break;
    }

    _markUnsavedChanges();
  }

  void startMeasurement(Offset startPosition) {
    _isMeasuring = true;
    _measureStart = startPosition;
    _measureEnd = null;
    notifyListeners();
  }

  void updateMeasurement(Offset currentPosition) {
    if (!_isMeasuring) return;
    _measureEnd = currentPosition;
    notifyListeners();
  }

  void endMeasurement() {
    if (_isMeasuring && _measureStart != null && _measureEnd != null) {
      final distance = (_measureStart! - _measureEnd!).distance;
      final measurement = railway.Measurement(
        id: 'M${DateTime.now().millisecondsSinceEpoch}',
        start: _measureStart!,
        end: _measureEnd!,
        distance: distance,
        timestamp: DateTime.now(),
      );
      _measurements.add(measurement);
    }
    _isMeasuring = false;
    _measureStart = null;
    _measureEnd = null;
    notifyListeners();
  }

  void clearMeasurements() {
    _measurements.clear();
    notifyListeners();
  }

  void updateTextAnnotation(String id, String newText) {
    final index = _textAnnotations.indexWhere((text) => text.id == id);
    if (index != -1) {
      final oldText = _textAnnotations[index];
      _textAnnotations[index] = railway.TextAnnotation(
        id: oldText.id,
        text: newText,
        position: oldText.position,
        fontSize: oldText.fontSize,
        color: oldText.color,
        createdAt: oldText.createdAt,
      );
      notifyListeners();
    }
  }

  void deleteTextAnnotation(String id) {
    _textAnnotations.removeWhere((text) => text.id == id);
    notifyListeners();
  }

  void importFromXml(String xmlContent, {String? filePath}) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final railwayData = XmlParser.parseRailwayData(xmlContent);
      final newTab = railway.WorkspaceTab(
        id: 'tab_${DateTime.now().millisecondsSinceEpoch}',
        title: filePath?.split('/').last ?? 'Imported XML',
        data: railwayData,
        filePath: filePath,
        fileType: railway.FileType.xml,
      );
      _tabs.add(newTab);
      _currentTabIndex = _tabs.length - 1;
      _updateCurrentSvg();
    } catch (e) {
      _errorMessage = 'Failed to import XML: $e';
      _currentSvg = _generateErrorSvg(_errorMessage!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void importFromSvg(String svgContent, {String? filePath}) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newTab = railway.WorkspaceTab(
        id: 'tab_${DateTime.now().millisecondsSinceEpoch}',
        title: filePath?.split('/').last ?? 'Imported SVG',
        data: railway.RailwayData(
          blocks: [],
          points: [],
          signals: [],
          platforms: [],
        ),
        filePath: filePath,
        fileType: railway.FileType.svg,
      );
      _tabs.add(newTab);
      _currentTabIndex = _tabs.length - 1;
      _updateCurrentSvg();
    } catch (e) {
      _errorMessage = 'Failed to import SVG: $e';
      _currentSvg = _generateErrorSvg(_errorMessage!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void importFromJson(String jsonContent, {String? filePath}) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> jsonData = json.decode(jsonContent);
      final railwayData = railway.RailwayData.fromJson(jsonData);
      final newTab = railway.WorkspaceTab(
        id: 'tab_${DateTime.now().millisecondsSinceEpoch}',
        title: filePath?.split('/').last ?? 'Imported JSON',
        data: railwayData,
        filePath: filePath,
        fileType: railway.FileType.json,
      );
      _tabs.add(newTab);
      _currentTabIndex = _tabs.length - 1;
      _updateCurrentSvg();
    } catch (e) {
      _errorMessage = 'Failed to import JSON: $e';
      _currentSvg = _generateErrorSvg(_errorMessage!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String exportCurrentToXml() {
    return XmlGenerator.generateXml(_currentTab.data);
  }

  String exportCurrentToSvg() {
    return _currentSvg;
  }

  String exportCurrentToJson() {
    return json.encode(_currentTab.data.toJson());
  }

  void _forceSvgUpdate() {
    _updateCurrentSvg();
    notifyListeners();
  }

  void addBlock(railway.Block block) {
    final newBlocks = [...data.blocks, block];
    updateTabData(data.copyWith(blocks: newBlocks), regenerateSvg: false);
    _forceSvgUpdate();
  }

  void updateBlock(String blockId, railway.Block updatedBlock, {bool regenerateSvg = true}) {
    final index = data.blocks.indexWhere((b) => b.id == blockId);
    if (index != -1) {
      final newBlocks = List<railway.Block>.from(data.blocks);
      newBlocks[index] = updatedBlock;
      updateTabData(data.copyWith(blocks: newBlocks), regenerateSvg: regenerateSvg);
    }
  }

  void deleteBlock(String blockId) {
    final newBlocks = data.blocks.where((b) => b.id != blockId).toList();
    if (_selectedElement?.type == 'block' &&
        (_selectedElement?.element as railway.Block).id == blockId) {
      _selectedElement = null;
    }
    updateTabData(data.copyWith(blocks: newBlocks));
  }

  void addPoint(railway.Point point) {
    final newPoints = [...data.points, point];
    updateTabData(data.copyWith(points: newPoints));
  }

  void updatePoint(String pointId, railway.Point updatedPoint, {bool regenerateSvg = true}) {
    final index = data.points.indexWhere((p) => p.id == pointId);
    if (index != -1) {
      final newPoints = List<railway.Point>.from(data.points);
      newPoints[index] = updatedPoint;
      updateTabData(data.copyWith(points: newPoints), regenerateSvg: regenerateSvg);
    }
  }

  void deletePoint(String pointId) {
    final newPoints = data.points.where((p) => p.id != pointId).toList();
    if (_selectedElement?.type == 'point' &&
        (_selectedElement?.element as railway.Point).id == pointId) {
      _selectedElement = null;
    }
    updateTabData(data.copyWith(points: newPoints));
  }

  void addSignal(railway.Signal signal) {
    final newSignals = [...data.signals, signal];
    updateTabData(data.copyWith(signals: newSignals));
  }

  void updateSignal(String signalId, railway.Signal updatedSignal, {bool regenerateSvg = true}) {
    final index = data.signals.indexWhere((s) => s.id == signalId);
    if (index != -1) {
      final newSignals = List<railway.Signal>.from(data.signals);
      newSignals[index] = updatedSignal;
      updateTabData(data.copyWith(signals: newSignals), regenerateSvg: regenerateSvg);
    }
  }

  void deleteSignal(String signalId) {
    final newSignals = data.signals.where((s) => s.id != signalId).toList();
    if (_selectedElement?.type == 'signal' &&
        (_selectedElement?.element as railway.Signal).id == signalId) {
      _selectedElement = null;
    }
    updateTabData(data.copyWith(signals: newSignals));
  }

  void addPlatform(railway.Platform platform) {
    final newPlatforms = [...data.platforms, platform];
    updateTabData(data.copyWith(platforms: newPlatforms));
  }

  void updatePlatform(String platformId, railway.Platform updatedPlatform, {bool regenerateSvg = true}) {
    final index = data.platforms.indexWhere((p) => p.id == platformId);
    if (index != -1) {
      final newPlatforms = List<railway.Platform>.from(data.platforms);
      newPlatforms[index] = updatedPlatform;
      updateTabData(data.copyWith(platforms: newPlatforms), regenerateSvg: regenerateSvg);
    }
  }

  void deletePlatform(String platformId) {
    final newPlatforms =
        data.platforms.where((p) => p.id != platformId).toList();
    if (_selectedElement?.type == 'platform' &&
        (_selectedElement?.element as railway.Platform).id == platformId) {
      _selectedElement = null;
    }
    updateTabData(data.copyWith(platforms: newPlatforms));
  }

  void addRouteToSignal(String signalId, railway.Route route) {
    final signalIndex = data.signals.indexWhere((s) => s.id == signalId);
    if (signalIndex != -1) {
      final newSignals = List<railway.Signal>.from(data.signals);
      final signal = newSignals[signalIndex];
      newSignals[signalIndex] = signal.copyWith(
        routes: [...signal.routes, route],
      );
      updateTabData(data.copyWith(signals: newSignals));
    }
  }

  void applyGeneratedLayout(
    railway.RailwayData generatedData, {
    List<railway.TextAnnotation> textAnnotations = const [],
    bool replaceExisting = true,
  }) {
    final currentData = data;
    final mergedData = replaceExisting
        ? generatedData
        : currentData.copyWith(
            blocks: [...currentData.blocks, ...generatedData.blocks],
            points: [...currentData.points, ...generatedData.points],
            signals: [...currentData.signals, ...generatedData.signals],
            platforms: [...currentData.platforms, ...generatedData.platforms],
          );

    updateTabData(mergedData, regenerateSvg: false);
    _textAnnotations = replaceExisting
        ? [...textAnnotations]
        : [..._textAnnotations, ...textAnnotations];
    _markUnsavedChanges();
    _forceSvgUpdate();
  }

  void updateRouteInSignal(
      String signalId, String routeId, railway.Route updatedRoute) {
    final signalIndex = data.signals.indexWhere((s) => s.id == signalId);
    if (signalIndex != -1) {
      final newSignals = List<railway.Signal>.from(data.signals);
      final signal = newSignals[signalIndex];
      final routeIndex = signal.routes.indexWhere((r) => r.id == routeId);
      if (routeIndex != -1) {
        final newRoutes = List<railway.Route>.from(signal.routes);
        newRoutes[routeIndex] = updatedRoute;
        newSignals[signalIndex] = signal.copyWith(routes: newRoutes);
        updateTabData(data.copyWith(signals: newSignals));
      }
    }
  }

  void deleteRouteFromSignal(String signalId, String routeId) {
    final signalIndex = data.signals.indexWhere((s) => s.id == signalId);
    if (signalIndex != -1) {
      final newSignals = List<railway.Signal>.from(data.signals);
      final signal = newSignals[signalIndex];
      newSignals[signalIndex] = signal.copyWith(
        routes: signal.routes.where((r) => r.id != routeId).toList(),
      );
      updateTabData(data.copyWith(signals: newSignals));
    }
  }

  void _updateCurrentSvg() {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _currentSvg = SvgGenerator.generateSvg(_currentTab.data,
          showGrid: _gridSettings.enabled,
          measurements: _measurements,
          textAnnotations: _textAnnotations,
          isMeasuring: _isMeasuring,
          measureStart: _measureStart,
          measureEnd: _measureEnd);
    } catch (e, stackTrace) {
      _errorMessage = 'Failed to generate SVG: $e';
      _currentSvg = _generateErrorSvg(_errorMessage!);
      print('SVG Error: $e');
      print('Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _markUnsavedChanges() {
    if (!_currentTab.hasUnsavedChanges) {
      _tabs[_currentTabIndex] = _currentTab.copyWith(hasUnsavedChanges: true);
    }
  }

  String _generateErrorSvg(String error) {
    return '''
<svg width="400" height="200" viewBox="0 0 400 200" xmlns="http://www.w3.org/2000/svg">
  <rect width="400" height="200" fill="#ffebee" rx="8"/>
  <text x="200" y="80" text-anchor="middle" font-family="Arial" font-size="16" fill="#d32f2f" font-weight="bold">
    SVG Generation Error
  </text>
  <text x="200" y="110" text-anchor="middle" font-family="Arial" font-size="12" fill="#d32f2f">
    $error
  </text>
  <text x="200" y="140" text-anchor="middle" font-family="Arial" font-size="12" fill="#666">
    Check console for details
  </text>
</svg>
''';
  }

  RailwayProvider() {
    addNewTab();
  }
}
