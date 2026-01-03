import 'package:flutter/material.dart';

enum GraphNodeType {
  block,
  crossover,
  point,
  signal,
  platform,
  trainStop,
  bufferStop,
  axleCounter,
  transponder,
  wifiAntenna,
  routeReservation,
  movementAuthority,
  train,
  text,
}

class GraphNode {
  final String id;
  final GraphNodeType type;
  final Offset position;
  final String label;

  const GraphNode({
    required this.id,
    required this.type,
    required this.position,
    required this.label,
  });

  GraphNode copyWith({
    String? id,
    GraphNodeType? type,
    Offset? position,
    String? label,
  }) {
    return GraphNode(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      label: label ?? this.label,
    );
  }
}

class GraphEdge {
  final String id;
  final String fromNodeId;
  final String toNodeId;

  const GraphEdge({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
  });
}

class GraphData {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;

  const GraphData({
    required this.nodes,
    required this.edges,
  });

  GraphData copyWith({
    List<GraphNode>? nodes,
    List<GraphEdge>? edges,
  }) {
    return GraphData(
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
    );
  }
}
