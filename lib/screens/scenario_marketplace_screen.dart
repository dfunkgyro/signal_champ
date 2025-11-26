import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/scenario_models.dart';
import '../services/scenario_service.dart';
import 'scenario_builder_screen.dart';
import 'scenario_player_screen.dart';

class ScenarioMarketplaceScreen extends StatefulWidget {
  const ScenarioMarketplaceScreen({super.key});

  @override
  State<ScenarioMarketplaceScreen> createState() =>
      _ScenarioMarketplaceScreenState();
}

class _ScenarioMarketplaceScreenState extends State<ScenarioMarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ScenarioCategory? _filterCategory;
  ScenarioDifficulty? _filterDifficulty;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final scenarioService = context.read<ScenarioService>();
    await Future.wait([
      scenarioService.loadFeaturedScenarios(),
      scenarioService.loadCommunityScenarios(),
      scenarioService.loadMyScenarios(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scenario Marketplace'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.star), text: 'Featured'),
            Tab(icon: Icon(Icons.public), text: 'Community'),
            Tab(icon: Icon(Icons.person), text: 'My Scenarios'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search and filter bar
          _buildSearchBar(theme),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFeaturedTab(),
                _buildCommunityTab(),
                _buildMyScenariosTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewScenario,
        icon: const Icon(Icons.add),
        label: const Text('New Scenario'),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          // Search field
          TextField(
            decoration: InputDecoration(
              hintText: 'Search scenarios...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _applyFilters();
            },
          ),
          const SizedBox(height: 12),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Category filter
                FilterChip(
                  label: Text(_filterCategory?.displayName ?? 'All Categories'),
                  avatar: Icon(
                    _filterCategory?.icon ?? Icons.category,
                    size: 18,
                  ),
                  selected: _filterCategory != null,
                  onSelected: (_) => _showCategoryFilter(),
                ),
                const SizedBox(width: 8),

                // Difficulty filter
                FilterChip(
                  label: Text(
                      _filterDifficulty?.displayName ?? 'All Difficulties'),
                  avatar: _filterDifficulty != null
                      ? Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _filterDifficulty!.color,
                            shape: BoxShape.circle,
                          ),
                        )
                      : const Icon(Icons.signal_cellular_alt, size: 18),
                  selected: _filterDifficulty != null,
                  onSelected: (_) => _showDifficultyFilter(),
                ),
                const SizedBox(width: 8),

                // Clear filters
                if (_filterCategory != null || _filterDifficulty != null)
                  ActionChip(
                    label: const Text('Clear Filters'),
                    avatar: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      setState(() {
                        _filterCategory = null;
                        _filterDifficulty = null;
                      });
                      _applyFilters();
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedTab() {
    return Consumer<ScenarioService>(
      builder: (context, scenarioService, child) {
        if (scenarioService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (scenarioService.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(scenarioService.error!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final scenarios = scenarioService.featuredScenarios;

        if (scenarios.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64),
                SizedBox(height: 16),
                Text('No featured scenarios available'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: scenarios.length,
            itemBuilder: (context, index) {
              return _buildScenarioCard(scenarios[index], isFeatured: true);
            },
          ),
        );
      },
    );
  }

  Widget _buildCommunityTab() {
    return Consumer<ScenarioService>(
      builder: (context, scenarioService, child) {
        if (scenarioService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (scenarioService.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(scenarioService.error!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final scenarios = _filterScenarios(scenarioService.communityScenarios);

        if (scenarios.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64),
                SizedBox(height: 16),
                Text('No community scenarios found'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: scenarios.length,
            itemBuilder: (context, index) {
              return _buildScenarioCard(scenarios[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildMyScenariosTab() {
    return Consumer<ScenarioService>(
      builder: (context, scenarioService, child) {
        if (scenarioService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (scenarioService.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(scenarioService.error!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final scenarios = scenarioService.myScenarios;

        if (scenarios.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inbox, size: 64),
                const SizedBox(height: 16),
                const Text('No scenarios yet'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _createNewScenario,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Your First Scenario'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: scenarios.length,
            itemBuilder: (context, index) {
              return _buildScenarioCard(scenarios[index], isOwned: true);
            },
          ),
        );
      },
    );
  }

  Widget _buildScenarioCard(RailwayScenario scenario,
      {bool isFeatured = false, bool isOwned = false}) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openScenario(scenario),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Container(
              height: 120,
              color: theme.colorScheme.primaryContainer,
              child: scenario.thumbnailUrl != null
                  ? Image.network(
                      scenario.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildPlaceholderThumbnail(),
                    )
                  : _buildPlaceholderThumbnail(),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        if (isFeatured)
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                        if (isFeatured) const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            scenario.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Description
                    Text(
                      scenario.description,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),

                    // Metadata row
                    Row(
                      children: [
                        Icon(scenario.category.icon, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          scenario.category.displayName,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: scenario.difficulty.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          scenario.difficulty.displayName,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Stats row
                    Row(
                      children: [
                        const Icon(Icons.download, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${scenario.downloads}',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.star, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${scenario.rating.toStringAsFixed(1)} (${scenario.ratingCount})',
                          style: theme.textTheme.bodySmall,
                        ),
                        const Spacer(),
                        if (isOwned && scenario.isPublic)
                          const Icon(Icons.cloud_done, size: 14),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            if (!isOwned)
              ButtonBar(
                children: [
                  TextButton.icon(
                    onPressed: () => _downloadScenario(scenario),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Download'),
                  ),
                ],
              )
            else
              ButtonBar(
                children: [
                  TextButton.icon(
                    onPressed: () => _editScenario(scenario),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 18),
                    onPressed: () => _showScenarioMenu(scenario),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderThumbnail() {
    final theme = Theme.of(context);
    return Center(
      child: Icon(
        Icons.railway_alert,
        size: 48,
        color: theme.colorScheme.onPrimaryContainer.withOpacity(0.5),
      ),
    );
  }

  List<RailwayScenario> _filterScenarios(List<RailwayScenario> scenarios) {
    var filtered = scenarios;

    if (_filterCategory != null) {
      filtered = filtered.where((s) => s.category == _filterCategory).toList();
    }

    if (_filterDifficulty != null) {
      filtered =
          filtered.where((s) => s.difficulty == _filterDifficulty).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((s) {
        return s.name.toLowerCase().contains(query) ||
            s.description.toLowerCase().contains(query) ||
            s.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    return filtered;
  }

  void _showCategoryFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('All Categories'),
              onTap: () {
                setState(() => _filterCategory = null);
                Navigator.pop(context);
                _applyFilters();
              },
            ),
            ...ScenarioCategory.values.map((category) {
              return ListTile(
                leading: Icon(category.icon),
                title: Text(category.displayName),
                selected: _filterCategory == category,
                onTap: () {
                  setState(() => _filterCategory = category);
                  Navigator.pop(context);
                  _applyFilters();
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showDifficultyFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Difficulty'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('All Difficulties'),
              onTap: () {
                setState(() => _filterDifficulty = null);
                Navigator.pop(context);
                _applyFilters();
              },
            ),
            ...ScenarioDifficulty.values.map((difficulty) {
              return ListTile(
                leading: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: difficulty.color,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(difficulty.displayName),
                selected: _filterDifficulty == difficulty,
                onTap: () {
                  setState(() => _filterDifficulty = difficulty);
                  Navigator.pop(context);
                  _applyFilters();
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _applyFilters() {
    final scenarioService = context.read<ScenarioService>();
    scenarioService.loadCommunityScenarios(
      category: _filterCategory,
      difficulty: _filterDifficulty,
      searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
    );
  }

  void _openScenario(RailwayScenario scenario) {
    // Navigate to scenario player
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ScenarioPlayerScreen(scenario: scenario),
      ),
    );
  }

  Future<void> _downloadScenario(RailwayScenario scenario) async {
    final scenarioService = context.read<ScenarioService>();
    final downloaded = await scenarioService.duplicateScenario(scenario.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(downloaded != null
              ? 'Scenario downloaded successfully'
              : 'Failed to download scenario'),
          backgroundColor: downloaded != null ? Colors.green : Colors.red,
        ),
      );

      if (downloaded != null) {
        // Switch to "My Scenarios" tab
        _tabController.animateTo(2);
      }
    }
  }

  void _createNewScenario() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ScenarioBuilderScreen(),
      ),
    ).then((_) => _loadData());
  }

  void _editScenario(RailwayScenario scenario) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScenarioBuilderScreen(scenarioId: scenario.id),
      ),
    ).then((_) => _loadData());
  }

  void _showScenarioMenu(RailwayScenario scenario) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () {
              Navigator.pop(context);
              _editScenario(scenario);
            },
          ),
          ListTile(
            leading:
                Icon(scenario.isPublic ? Icons.cloud_off : Icons.cloud_upload),
            title: Text(scenario.isPublic ? 'Unpublish' : 'Publish'),
            onTap: () {
              Navigator.pop(context);
              if (scenario.isPublic) {
                _unpublishScenario(scenario);
              } else {
                _publishScenario(scenario);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.content_copy),
            title: const Text('Duplicate'),
            onTap: () {
              Navigator.pop(context);
              _duplicateScenario(scenario);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _deleteScenario(scenario);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _publishScenario(RailwayScenario scenario) async {
    final scenarioService = context.read<ScenarioService>();
    final success = await scenarioService.publishScenario(scenario.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Scenario published successfully'
              : 'Failed to publish scenario'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        _loadData();
      }
    }
  }

  Future<void> _unpublishScenario(RailwayScenario scenario) async {
    final scenarioService = context.read<ScenarioService>();
    final success = await scenarioService.unpublishScenario(scenario.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Scenario unpublished'
              : 'Failed to unpublish scenario'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        _loadData();
      }
    }
  }

  Future<void> _duplicateScenario(RailwayScenario scenario) async {
    final scenarioService = context.read<ScenarioService>();
    final duplicated = await scenarioService.duplicateScenario(scenario.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(duplicated != null
              ? 'Scenario duplicated successfully'
              : 'Failed to duplicate scenario'),
          backgroundColor: duplicated != null ? Colors.green : Colors.red,
        ),
      );

      if (duplicated != null) {
        _loadData();
      }
    }
  }

  Future<void> _deleteScenario(RailwayScenario scenario) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Scenario'),
        content: Text('Are you sure you want to delete "${scenario.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final scenarioService = context.read<ScenarioService>();
    final success = await scenarioService.deleteScenario(scenario.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Scenario deleted successfully'
              : 'Failed to delete scenario'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        _loadData();
      }
    }
  }
}
