import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/terminal_station_controller.dart';
import '../screens/terminal_station_models.dart';

/// Search result type for railway items
class RailwaySearchResult {
  final String id;
  final String type; // 'train', 'signal', 'block', 'point'
  final String displayName;
  final double? x;
  final double? y;
  final dynamic data; // The actual object (Train, Signal, BlockSection, Point)

  RailwaySearchResult({
    required this.id,
    required this.type,
    required this.displayName,
    this.x,
    this.y,
    this.data,
  });
}

/// Railway search widget with auto-complete and result selection
class RailwaySearchWidget extends StatefulWidget {
  final Function(RailwaySearchResult)? onResultSelected;
  final bool compact; // If true, shows smaller compact version
  final bool showResultsOverlay; // If true, shows results in overlay instead of dropdown

  const RailwaySearchWidget({
    Key? key,
    this.onResultSelected,
    this.compact = false,
    this.showResultsOverlay = false,
  }) : super(key: key);

  @override
  State<RailwaySearchWidget> createState() => _RailwaySearchWidgetState();
}

class _RailwaySearchWidgetState extends State<RailwaySearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<RailwaySearchResult> _searchResults = [];
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() => _showResults = false);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
      return;
    }

    final controller = Provider.of<TerminalStationController>(context, listen: false);
    final results = <RailwaySearchResult>[];

    // Search trains
    for (final train in controller.trains) {
      if (train.id.toLowerCase().contains(query) ||
          'train ${train.id}'.toLowerCase().contains(query)) {
        results.add(RailwaySearchResult(
          id: train.id,
          type: 'train',
          displayName: 'Train ${train.id} (${train.type.name.toUpperCase()})',
          x: train.x,
          y: train.y,
          data: train,
        ));
      }
    }

    // Search signals
    controller.signals.forEach((id, signal) {
      if (id.toLowerCase().contains(query) ||
          'signal $id'.toLowerCase().contains(query)) {
        results.add(RailwaySearchResult(
          id: id,
          type: 'signal',
          displayName: 'Signal $id (${signal.currentAspect.name})',
          x: signal.x,
          y: signal.y,
          data: signal,
        ));
      }
    });

    // Search blocks
    controller.blocks.forEach((id, block) {
      if (id.toLowerCase().contains(query) ||
          'block $id'.toLowerCase().contains(query)) {
        results.add(RailwaySearchResult(
          id: id,
          type: 'block',
          displayName: 'Block $id (${block.occupied ? "Occupied" : "Clear"})',
          x: (block.startX + block.endX) / 2,
          y: block.y,
          data: block,
        ));
      }
    });

    // Search points
    controller.points.forEach((id, point) {
      if (id.toLowerCase().contains(query) ||
          'point $id'.toLowerCase().contains(query)) {
        results.add(RailwaySearchResult(
          id: id,
          type: 'point',
          displayName: 'Point $id (${point.isNormal ? "Normal" : "Reverse"})',
          x: point.x,
          y: point.y,
          data: point,
        ));
      }
    });

    setState(() {
      _searchResults = results;
      _showResults = results.isNotEmpty;
    });
  }

  void _onResultSelected(RailwaySearchResult result) {
    setState(() {
      _searchController.text = result.displayName;
      _showResults = false;
    });

    if (widget.onResultSelected != null) {
      widget.onResultSelected!(result);
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'train':
        return Icons.train;
      case 'signal':
        return Icons.traffic;
      case 'block':
        return Icons.view_module;
      case 'point':
        return Icons.merge_type;
      default:
        return Icons.search;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'train':
        return Colors.blue;
      case 'signal':
        return Colors.red;
      case 'block':
        return Colors.green;
      case 'point':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactSearch();
    }
    return _buildFullSearch();
  }

  Widget _buildCompactSearch() {
    return Container(
      width: 200,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            focusNode: _focusNode,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                          _showResults = false;
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          if (_showResults) _buildResultsList(compact: true),
        ],
      ),
    );
  }

  Widget _buildFullSearch() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: 'Search trains, signals, blocks, points...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                          _showResults = false;
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          if (_showResults) _buildResultsList(),
        ],
      ),
    );
  }

  Widget _buildResultsList({bool compact = false}) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: BoxConstraints(
        maxHeight: compact ? 200 : 300,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(8),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final result = _searchResults[index];
            return ListTile(
              dense: compact,
              leading: Icon(
                _getIconForType(result.type),
                color: _getColorForType(result.type),
                size: compact ? 20 : 24,
              ),
              title: Text(
                result.displayName,
                style: TextStyle(fontSize: compact ? 12 : 14),
              ),
              subtitle: compact ? null : Text(
                'Type: ${result.type.toUpperCase()}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Icon(
                Icons.arrow_forward,
                size: compact ? 16 : 20,
              ),
              onTap: () => _onResultSelected(result),
            );
          },
        ),
      ),
    );
  }
}
