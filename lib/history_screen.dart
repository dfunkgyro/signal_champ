import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);
  
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _simulations = [];
  bool _isLoading = true;
  String _sortBy = 'date';
  String _filterBy = 'all';
  
  @override
  void initState() {
    super.initState();
    _loadHistory();
  }
  
  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    
    try {
      final supabase = context.read<SupabaseService>();
      final simulations = await supabase.loadSimulationStates(limit: 50);
      
      setState(() {
        _simulations = simulations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading history: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulation History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onSelected: (value) {
              setState(() => _sortBy = value);
              _sortSimulations();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'date',
                child: Text('Sort by Date'),
              ),
              const PopupMenuItem(
                value: 'trains',
                child: Text('Sort by Train Count'),
              ),
              const PopupMenuItem(
                value: 'duration',
                child: Text('Sort by Duration'),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onSelected: (value) {
              setState(() => _filterBy = value);
              _filterSimulations();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Simulations'),
              ),
              const PopupMenuItem(
                value: 'today',
                child: Text('Today'),
              ),
              const PopupMenuItem(
                value: 'week',
                child: Text('This Week'),
              ),
              const PopupMenuItem(
                value: 'month',
                child: Text('This Month'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _simulations.isEmpty
              ? _buildEmptyState()
              : _buildHistoryList(),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No simulation history',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Run simulations to see them here',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to simulation
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Simulation'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHistoryList() {
    return Column(
      children: [
        // Stats Summary
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.assignment,
                label: 'Total',
                value: _simulations.length.toString(),
              ),
              _buildStatItem(
                icon: Icons.train,
                label: 'Avg Trains',
                value: _calculateAverageTrains().toStringAsFixed(1),
              ),
              _buildStatItem(
                icon: Icons.timer,
                label: 'Total Time',
                value: _formatTotalTime(),
              ),
            ],
          ),
        ),
        
        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _simulations.length,
            itemBuilder: (context, index) {
              final simulation = _simulations[index];
              return _buildHistoryCard(simulation);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
  
  Widget _buildHistoryCard(Map<String, dynamic> simulation) {
    final createdAt = DateTime.parse(simulation['created_at'] as String);
    final trainCount = simulation['train_count'] as int? ?? 0;
    final stateData = simulation['state_data'] as Map<String, dynamic>? ?? {};
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showSimulationDetails(simulation),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.train,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Simulation ${simulation['id'].toString().substring(0, 8)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _formatDate(createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showOptionsMenu(simulation),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildChip(
                    icon: Icons.train,
                    label: '$trainCount trains',
                  ),
                  const SizedBox(width: 8),
                  _buildChip(
                    icon: Icons.grid_on,
                    label: '${stateData['blocks']?.length ?? 0} blocks',
                  ),
                  const SizedBox(width: 8),
                  _buildChip(
                    icon: Icons.traffic,
                    label: '${stateData['signals']?.length ?? 0} signals',
                  ),
                ],
              ),
              if (stateData['duration'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Duration: ${_formatDuration(stateData['duration'])}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
  
  void _showSimulationDetails(Map<String, dynamic> simulation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Simulation Details',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                _buildDetailRow('ID', simulation['id'].toString()),
                _buildDetailRow('Date', _formatDate(DateTime.parse(simulation['created_at']))),
                _buildDetailRow('Trains', simulation['train_count'].toString()),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Load simulation
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.restore),
                        label: const Text('Load'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Share simulation
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  
  void _showOptionsMenu(Map<String, dynamic> simulation) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Load Simulation'),
            onTap: () {
              Navigator.pop(context);
              // Load simulation
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () {
              Navigator.pop(context);
              // Share simulation
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(simulation);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  void _confirmDelete(Map<String, dynamic> simulation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Simulation'),
        content: const Text('Are you sure you want to delete this simulation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSimulation(simulation);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  void _deleteSimulation(Map<String, dynamic> simulation) {
    setState(() {
      _simulations.remove(simulation);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Simulation deleted')),
    );
  }
  
  void _sortSimulations() {
    setState(() {
      switch (_sortBy) {
        case 'date':
          _simulations.sort((a, b) => 
            DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
          break;
        case 'trains':
          _simulations.sort((a, b) => 
            (b['train_count'] as int).compareTo(a['train_count'] as int));
          break;
      }
    });
  }
  
  void _filterSimulations() {
    _loadHistory(); // Reload with filter
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE HH:mm').format(date);
    } else {
      return DateFormat('MMM dd, yyyy HH:mm').format(date);
    }
  }
  
  String _formatDuration(dynamic duration) {
    if (duration is int) {
      final minutes = duration ~/ 60;
      final seconds = duration % 60;
      return '${minutes}m ${seconds}s';
    }
    return 'N/A';
  }
  
  double _calculateAverageTrains() {
    if (_simulations.isEmpty) return 0.0;
    final total = _simulations.fold<int>(
      0,
      (sum, sim) => sum + (sim['train_count'] as int? ?? 0),
    );
    return total / _simulations.length;
  }
  
  String _formatTotalTime() {
    // Calculate total simulation time
    return '12h 34m'; // Placeholder
  }
}
