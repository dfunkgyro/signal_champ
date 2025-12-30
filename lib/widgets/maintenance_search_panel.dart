import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/terminal_station_controller.dart';
import '../screens/terminal_station_models.dart';

/// Component type for search results
class ComponentSearchResult {
  final String type;
  final String id;
  final double x;
  final double y;
  final String subtitle;
  final Color color;

  ComponentSearchResult({
    required this.type,
    required this.id,
    required this.x,
    required this.y,
    required this.subtitle,
    required this.color,
  });
}

/// Maintenance mode right panel - search and auto-pan to components
class MaintenanceSearchPanel extends StatefulWidget {
  final String title;
  final double? viewportWidth;
  final double? viewportHeight;

  const MaintenanceSearchPanel({
    Key? key,
    this.title = 'Search',
    this.viewportWidth,
    this.viewportHeight,
  }) : super(key: key);

  @override
  State<MaintenanceSearchPanel> createState() => _MaintenanceSearchPanelState();
}

class _MaintenanceSearchPanelState extends State<MaintenanceSearchPanel> {
  final TextEditingController _searchController = TextEditingController();
  List<ComponentSearchResult> _searchResults = [];
  String _searchQuery = '';
  String _selectedComponentId = '';
  String _filterType = 'all'; // all, signals, points, blocks, axleCounters

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _updateSearchResults();
    });
  }

  void _updateSearchResults() {
    final controller =
        Provider.of<TerminalStationController>(context, listen: false);
    _searchResults.clear();

    // Search signals
    if (_filterType == 'all' || _filterType == 'signals') {
      for (final signal in controller.signals.values) {
        if (_matchesQuery(signal.id)) {
          _searchResults.add(ComponentSearchResult(
            type: 'signal',
            id: signal.id,
            x: signal.x,
            y: signal.y,
            subtitle: 'Direction: ${signal.direction.name}',
            color: Colors.green,
          ));
        }
      }
    }

    // Search points
    if (_filterType == 'all' || _filterType == 'points') {
      for (final point in controller.points.values) {
        if (_matchesQuery(point.id)) {
          _searchResults.add(ComponentSearchResult(
            type: 'point',
            id: point.id,
            x: point.x,
            y: point.y,
            subtitle: 'Position: ${point.currentPosition.name}',
            color: Colors.blue,
          ));
        }
      }
    }

    // Search blocks
    if (_filterType == 'all' || _filterType == 'blocks') {
      for (final block in controller.blockSections.values) {
        if (_matchesQuery(block.id)) {
          _searchResults.add(ComponentSearchResult(
            type: 'block',
            id: block.id,
            x: block.centerX,
            y: block.y,
            subtitle: 'State: ${block.state.name.toUpperCase()}',
            color: Colors.purple,
          ));
        }
      }
    }

    // Search axle counters
    if (_filterType == 'all' || _filterType == 'axleCounters') {
      for (final ac in controller.axleCounters.values) {
        if (_matchesQuery(ac.id)) {
          _searchResults.add(ComponentSearchResult(
            type: 'axleCounter',
            id: ac.id,
            x: ac.x,
            y: ac.y,
            subtitle: 'Count: ${ac.count}, Block: ${ac.blockId}',
            color: Colors.cyan,
          ));
        }
      }
    }

    // Sort results alphabetically by ID
    _searchResults.sort((a, b) => a.id.compareTo(b.id));
  }

  bool _matchesQuery(String text) {
    if (_searchQuery.isEmpty) return true;
    return text.toLowerCase().contains(_searchQuery);
  }

  void _panToComponent(ComponentSearchResult result) {
    final controller =
        Provider.of<TerminalStationController>(context, listen: false);

    // Select the component
    controller.selectComponent(result.type, result.id);

    // Pan to the component's position
    controller.requestCanvasCenter(Offset(result.x, result.y));

    setState(() {
      _selectedComponentId = result.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TerminalStationController>(context);

    // Update search results when controller changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateSearchResults();
        setState(() {});
      }
    });

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          left: BorderSide(color: Colors.grey[700]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              border: Border(
                bottom: BorderSide(color: Colors.grey[700]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Search Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[700]!),
              ),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search components...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter chips
                Wrap(
                  spacing: 8,
                  children: [
                    _buildFilterChip('All', 'all'),
                    _buildFilterChip('Signals', 'signals'),
                    _buildFilterChip('Points', 'points'),
                    _buildFilterChip('Blocks', 'blocks'),
                    _buildFilterChip('ACs', 'axleCounters'),
                  ],
                ),
              ],
            ),
          ),

          // Results count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              border: Border(
                bottom: BorderSide(color: Colors.grey[700]!),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '${_searchResults.length} result${_searchResults.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Search Results List
          Expanded(
            child: _searchResults.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final result = _searchResults[index];
                      final isSelected = result.id == _selectedComponentId;
                      return _buildSearchResultItem(result, isSelected);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterType = value;
          _updateSearchResults();
        });
      },
      selectedColor: Colors.orange.withOpacity(0.3),
      checkmarkColor: Colors.orange,
      labelStyle: TextStyle(
        color: isSelected ? Colors.orange : Colors.grey[400],
        fontSize: 11,
      ),
      backgroundColor: Colors.grey[800],
      side: BorderSide(
        color: isSelected ? Colors.orange : Colors.grey[700]!,
      ),
    );
  }

  Widget _buildSearchResultItem(ComponentSearchResult result, bool isSelected) {
    return InkWell(
      onTap: () => _panToComponent(result),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.withOpacity(0.2) : Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey[700]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: result.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.id,
                    style: TextStyle(
                      color: isSelected ? Colors.orange : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.my_location,
                    color: Colors.orange,
                    size: 16,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'X: ${result.x.toStringAsFixed(1)}, Y: ${result.y.toStringAsFixed(1)}',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
            if (result.subtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  result.subtitle,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isEmpty ? Icons.search : Icons.search_off,
            color: Colors.grey[600],
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'Enter search query'
                : 'No results found',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Try a different search term',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
