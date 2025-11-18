import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/terminal_station_controller.dart';
import '../screens/terminal_station_models.dart';

/// Search bar widget for railway system - allows searching blocks, signals, tracks, stations, platforms, axle counters, tags, crossovers, and trains
class RailwaySearchBar extends StatefulWidget {
  final Function(double x, double y)? onNavigate;

  const RailwaySearchBar({Key? key, this.onNavigate}) : super(key: key);

  @override
  State<RailwaySearchBar> createState() => _RailwaySearchBarState();
}

class _RailwaySearchBarState extends State<RailwaySearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<SearchResult> _searchResults = [];
  bool _showResults = false;
  int _selectedIndex = -1;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query, TerminalStationController controller) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
      return;
    }

    final results = <SearchResult>[];
    final lowerQuery = query.toLowerCase();

    // Search blocks
    for (final block in controller.blocks.values) {
      if (block.id.toLowerCase().contains(lowerQuery) ||
          (block.name?.toLowerCase().contains(lowerQuery) ?? false)) {
        results.add(SearchResult(
          id: block.id,
          name: block.name ?? 'Block ${block.id}',
          type: 'Block',
          x: block.centerX,
          y: block.y,
          icon: Icons.view_column,
          color: block.occupied ? Colors.red : Colors.green,
          subtitle: block.occupied ? 'Occupied' : 'Clear',
        ));
      }
    }

    // Search signals
    for (final signal in controller.signals.values) {
      if (signal.id.toLowerCase().contains(lowerQuery)) {
        results.add(SearchResult(
          id: signal.id,
          name: 'Signal ${signal.id}',
          type: 'Signal',
          x: signal.x,
          y: signal.y,
          icon: Icons.traffic,
          color: signal.aspect == SignalAspect.green ? Colors.green :
                 signal.aspect == SignalAspect.blue ? Colors.blue : Colors.red,
          subtitle: signal.aspect.name.toUpperCase(),
        ));
      }
    }

    // Search points/tracks
    for (final point in controller.points.values) {
      if (point.id.toLowerCase().contains(lowerQuery)) {
        results.add(SearchResult(
          id: point.id,
          name: 'Point ${point.id}',
          type: 'Point',
          x: point.x,
          y: point.y,
          icon: Icons.alt_route,
          color: point.locked ? Colors.red : Colors.orange,
          subtitle: '${point.position.name.toUpperCase()}${point.locked ? ' (Locked)' : ''}',
        ));
      }
    }

    // Search stations/platforms
    for (final platform in controller.platforms) {
      if (platform.id.toLowerCase().contains(lowerQuery) ||
          platform.name.toLowerCase().contains(lowerQuery)) {
        results.add(SearchResult(
          id: platform.id,
          name: platform.name,
          type: 'Platform',
          x: platform.centerX,
          y: platform.y,
          icon: Icons.subway,
          color: platform.occupied ? Colors.purple : Colors.blue,
          subtitle: platform.occupied ? 'Train at platform' : 'Empty',
        ));
      }
    }

    // Search axle counters
    for (final counter in controller.axleCounters.values) {
      if (counter.id.toLowerCase().contains(lowerQuery) ||
          counter.blockId.toLowerCase().contains(lowerQuery)) {
        results.add(SearchResult(
          id: counter.id,
          name: counter.id.toUpperCase(),
          type: 'Axle Counter',
          x: counter.x,
          y: counter.y,
          icon: Icons.speed,
          color: counter.count > 0 ? Colors.amber : Colors.grey,
          subtitle: 'Count: ${counter.count}',
        ));
      }
    }

    // Search trains
    for (final train in controller.trains) {
      if (train.id.toLowerCase().contains(lowerQuery) ||
          train.name.toLowerCase().contains(lowerQuery) ||
          train.vin.toLowerCase().contains(lowerQuery)) {
        results.add(SearchResult(
          id: train.id,
          name: '${train.name} (VIN: ${train.vin})',
          type: 'Train',
          x: train.x,
          y: train.y,
          icon: Icons.train,
          color: train.color,
          subtitle: '${train.trainType.name.toUpperCase()} - ${train.controlMode.name} mode',
        ));
      }
    }

    // Search crossovers (special named blocks)
    final crossoverBlocks = controller.blocks.values.where(
      (block) => block.name != null && block.name!.toLowerCase().contains('crossover')
    );
    for (final block in crossoverBlocks) {
      if (lowerQuery.contains('cross') || block.name!.toLowerCase().contains(lowerQuery)) {
        if (!results.any((r) => r.id == block.id)) {
          results.add(SearchResult(
            id: block.id,
            name: block.name!,
            type: 'Crossover',
            x: block.centerX,
            y: block.y,
            icon: Icons.compare_arrows,
            color: Colors.cyan,
            subtitle: block.occupied ? 'Occupied' : 'Clear',
          ));
        }
      }
    }

    // Search transponders/tags
    for (final transponder in controller.transponders.values) {
      if (transponder.id.toLowerCase().contains(lowerQuery)) {
        results.add(SearchResult(
          id: transponder.id,
          name: transponder.id.toUpperCase(),
          type: 'Transponder',
          x: transponder.x,
          y: transponder.y,
          icon: Icons.sensors,
          color: Colors.indigo,
          subtitle: transponder.type.toString().split('.').last,
        ));
      }
    }

    setState(() {
      _searchResults = results;
      _showResults = results.isNotEmpty;
      _selectedIndex = results.isNotEmpty ? 0 : -1;
    });
  }

  void _selectResult(SearchResult result, TerminalStationController controller) {
    // Navigate to the item with smooth animation
    controller.panToPosition(result.x, result.y, zoom: 1.5);
    controller.highlightItem(result.id, result.type.toLowerCase());

    // Show thumbnail tooltip
    _showThumbnail(result);

    // Close search results
    setState(() {
      _showResults = false;
      _searchController.clear();
    });

    _focusNode.unfocus();
  }

  void _showThumbnail(SearchResult result) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 80,
        right: 340,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: result.color, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(result.icon, color: result.color, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      result.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  result.type,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                Text(
                  result.subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Position: (${result.x.toInt()}, ${result.y.toInt()})',
                  style: TextStyle(color: Colors.grey[500], fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent && _showResults && _searchResults.isNotEmpty) {
      if (event.logicalKey.keyLabel == 'Arrow Down') {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % _searchResults.length;
        });
      } else if (event.logicalKey.keyLabel == 'Arrow Up') {
        setState(() {
          _selectedIndex = (_selectedIndex - 1) % _searchResults.length;
          if (_selectedIndex < 0) _selectedIndex = _searchResults.length - 1;
        });
      } else if (event.logicalKey.keyLabel == 'Enter' && _selectedIndex >= 0) {
        final controller = context.read<TerminalStationController>();
        _selectResult(_searchResults[_selectedIndex], controller);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TerminalStationController>(
      builder: (context, controller, _) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            border: Border(
              bottom: BorderSide(color: Colors.grey[700]!, width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search input
              TextField(
                controller: _searchController,
                focusNode: _focusNode,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search blocks, signals, trains, platforms...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: const Icon(Icons.search, color: Colors.blue),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('', controller);
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) => _performSearch(value, controller),
                onSubmitted: (value) {
                  if (_searchResults.isNotEmpty && _selectedIndex >= 0) {
                    _selectResult(_searchResults[_selectedIndex], controller);
                  }
                },
              ),

              // Search results dropdown
              if (_showResults && _searchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[700]!),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final result = _searchResults[index];
                      final isSelected = index == _selectedIndex;

                      return Container(
                        color: isSelected ? Colors.blue.withOpacity(0.3) : null,
                        child: ListTile(
                          dense: true,
                          leading: Icon(result.icon, color: result.color, size: 20),
                          title: Text(
                            result.name,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          subtitle: Text(
                            '${result.type} - ${result.subtitle}',
                            style: TextStyle(color: Colors.grey[400], fontSize: 11),
                          ),
                          trailing: Text(
                            '(${result.x.toInt()}, ${result.y.toInt()})',
                            style: TextStyle(color: Colors.grey[500], fontSize: 10),
                          ),
                          onTap: () => _selectResult(result, controller),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class SearchResult {
  final String id;
  final String name;
  final String type;
  final double x;
  final double y;
  final IconData icon;
  final Color color;
  final String subtitle;

  SearchResult({
    required this.id,
    required this.name,
    required this.type,
    required this.x,
    required this.y,
    required this.icon,
    required this.color,
    required this.subtitle,
  });
}
