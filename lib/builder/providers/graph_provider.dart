import 'dart:math';

import 'package:flutter/material.dart';

import '../models/graph_model.dart';

class GraphProvider with ChangeNotifier {
  GraphData _data = const GraphData(nodes: [], edges: []);
  GraphNode? _selectedNode;
  bool _connectMode = false;
  String? _pendingConnectionFromId;
  String? _errorMessage;

  GraphProvider() {
    _seedSampleGraph();
  }

  GraphData get data => _data;
  GraphNode? get selectedNode => _selectedNode;
  bool get connectMode => _connectMode;
  String? get pendingConnectionFromId => _pendingConnectionFromId;
  String? get errorMessage => _errorMessage;

  void toggleConnectMode() {
    _connectMode = !_connectMode;
    _pendingConnectionFromId = null;
    notifyListeners();
  }

  void selectNode(GraphNode? node) {
    _selectedNode = node;
    notifyListeners();
  }

  void addNode(GraphNodeType type, Offset position) {
    final id = '${type.name}_${DateTime.now().millisecondsSinceEpoch}';
    final label = _defaultLabelFor(type);
    final node = GraphNode(id: id, type: type, position: position, label: label);
    _data = _data.copyWith(nodes: [..._data.nodes, node]);
    _selectedNode = node;
    notifyListeners();
  }

  void updateNodePosition(String nodeId, Offset position) {
    _data = _data.copyWith(
      nodes: _data.nodes.map((node) {
        if (node.id == nodeId) {
          return node.copyWith(position: position);
        }
        return node;
      }).toList(),
    );
    notifyListeners();
  }

  void updateNodeLabel(String nodeId, String label) {
    _data = _data.copyWith(
      nodes: _data.nodes.map((node) {
        if (node.id == nodeId) {
          return node.copyWith(label: label);
        }
        return node;
      }).toList(),
    );
    notifyListeners();
  }

  void beginConnection(GraphNode node) {
    if (!_connectMode) return;
    _pendingConnectionFromId = node.id;
    notifyListeners();
  }

  void completeConnection(GraphNode node) {
    if (!_connectMode || _pendingConnectionFromId == null) return;
    if (_pendingConnectionFromId == node.id) {
      _pendingConnectionFromId = null;
      notifyListeners();
      return;
    }
    final exists = _data.edges.any((edge) =>
        (edge.fromNodeId == _pendingConnectionFromId &&
            edge.toNodeId == node.id) ||
        (edge.fromNodeId == node.id &&
            edge.toNodeId == _pendingConnectionFromId));
    if (exists) {
      _errorMessage = 'Connection already exists.';
    } else {
      final edge = GraphEdge(
        id: 'edge_${DateTime.now().millisecondsSinceEpoch}',
        fromNodeId: _pendingConnectionFromId!,
        toNodeId: node.id,
      );
      _data = _data.copyWith(edges: [..._data.edges, edge]);
      _errorMessage = null;
    }
    _pendingConnectionFromId = null;
    notifyListeners();
  }

  void deleteSelectedNode() {
    if (_selectedNode == null) return;
    final nodeId = _selectedNode!.id;
    _data = _data.copyWith(
      nodes: _data.nodes.where((node) => node.id != nodeId).toList(),
      edges: _data.edges
          .where((edge) =>
              edge.fromNodeId != nodeId && edge.toNodeId != nodeId)
          .toList(),
    );
    _selectedNode = null;
    notifyListeners();
  }

  void removeEdge(String edgeId) {
    _data = _data.copyWith(
      edges: _data.edges.where((edge) => edge.id != edgeId).toList(),
    );
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _seedSampleGraph() {
    final nodes = <GraphNode>[
      const GraphNode(
        id: 'block_1',
        type: GraphNodeType.block,
        position: Offset(200, 200),
        label: 'Block A',
      ),
      const GraphNode(
        id: 'block_2',
        type: GraphNodeType.block,
        position: Offset(500, 200),
        label: 'Block B',
      ),
      const GraphNode(
        id: 'crossover_1',
        type: GraphNodeType.crossover,
        position: Offset(350, 200),
        label: 'Crossover X1',
      ),
      const GraphNode(
        id: 'signal_1',
        type: GraphNodeType.signal,
        position: Offset(350, 80),
        label: 'Signal 1',
      ),
      const GraphNode(
        id: 'platform_1',
        type: GraphNodeType.platform,
        position: Offset(350, 360),
        label: 'Platform 1',
      ),
      const GraphNode(
        id: 'buffer_1',
        type: GraphNodeType.bufferStop,
        position: Offset(100, 200),
        label: 'Buffer A',
      ),
      const GraphNode(
        id: 'axle_1',
        type: GraphNodeType.axleCounter,
        position: Offset(600, 200),
        label: 'Axle Counter',
      ),
      const GraphNode(
        id: 'wifi_1',
        type: GraphNodeType.wifiAntenna,
        position: Offset(520, 100),
        label: 'WiFi',
      ),
      const GraphNode(
        id: 'train_1',
        type: GraphNodeType.train,
        position: Offset(260, 120),
        label: 'Train M2',
      ),
    ];

    final edges = <GraphEdge>[
      const GraphEdge(id: 'edge_1', fromNodeId: 'block_1', toNodeId: 'block_2'),
      const GraphEdge(id: 'edge_2', fromNodeId: 'signal_1', toNodeId: 'block_1'),
      const GraphEdge(
          id: 'edge_3', fromNodeId: 'platform_1', toNodeId: 'block_2'),
    ];

    _data = GraphData(nodes: nodes, edges: edges);
  }

  String _defaultLabelFor(GraphNodeType type) {
    switch (type) {
      case GraphNodeType.block:
        return 'Block ${_randomSuffix()}';
      case GraphNodeType.crossover:
        return 'Crossover ${_randomSuffix()}';
      case GraphNodeType.point:
        return 'Point ${_randomSuffix()}';
      case GraphNodeType.signal:
        return 'Signal ${_randomSuffix()}';
      case GraphNodeType.platform:
        return 'Platform ${_randomSuffix()}';
      case GraphNodeType.trainStop:
        return 'Train Stop ${_randomSuffix()}';
      case GraphNodeType.bufferStop:
        return 'Buffer ${_randomSuffix()}';
      case GraphNodeType.axleCounter:
        return 'Axle Counter ${_randomSuffix()}';
      case GraphNodeType.transponder:
        return 'Transponder ${_randomSuffix()}';
      case GraphNodeType.wifiAntenna:
        return 'WiFi ${_randomSuffix()}';
      case GraphNodeType.routeReservation:
        return 'Reservation ${_randomSuffix()}';
      case GraphNodeType.movementAuthority:
        return 'Authority ${_randomSuffix()}';
      case GraphNodeType.train:
        return 'Train ${_randomSuffix()}';
      case GraphNodeType.text:
        return 'Note ${_randomSuffix()}';
    }
  }

  String _randomSuffix() {
    return (Random().nextInt(900) + 100).toString();
  }
}
