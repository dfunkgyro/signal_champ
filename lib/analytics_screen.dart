import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:rail_champ/services/supabase_service.dart';
import 'package:rail_champ/diagnostic_ai.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);
  
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'today';
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Insights'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedPeriod,
            onSelected: (value) {
              setState(() => _selectedPeriod = value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'today', child: Text('Today')),
              PopupMenuItem(value: 'week', child: Text('This Week')),
              PopupMenuItem(value: 'month', child: Text('This Month')),
              PopupMenuItem(value: 'all', child: Text('All Time')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Key Metrics
              _buildKeyMetrics(),
              
              const SizedBox(height: 24),
              
              // Performance Chart
              _buildSectionHeader('Performance Over Time'),
              const SizedBox(height: 12),
              _buildPerformanceChart(),
              
              const SizedBox(height: 24),
              
              // Train Statistics
              _buildSectionHeader('Train Statistics'),
              const SizedBox(height: 12),
              _buildTrainStats(),
              
              const SizedBox(height: 24),
              
              // Signal Efficiency
              _buildSectionHeader('Signal Efficiency'),
              const SizedBox(height: 12),
              _buildSignalEfficiency(),
              
              const SizedBox(height: 24),
              
              // Block Usage Heatmap
              _buildSectionHeader('Block Usage'),
              const SizedBox(height: 12),
              _buildBlockUsageChart(),
              
              const SizedBox(height: 24),
              
              // AI Insights
              _buildSectionHeader('AI Insights'),
              const SizedBox(height: 12),
              _buildAIInsights(),
              
              const SizedBox(height: 24),
              
              // System Health
              _buildSectionHeader('System Health'),
              const SizedBox(height: 12),
              _buildSystemHealth(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  Widget _buildKeyMetrics() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildMetricCard(
          title: 'Total Simulations',
          value: '47',
          icon: Icons.play_circle,
          color: Colors.blue,
          trend: '+12%',
          trendUp: true,
        ),
        _buildMetricCard(
          title: 'Avg Duration',
          value: '18m',
          icon: Icons.timer,
          color: Colors.orange,
          trend: '+5m',
          trendUp: false,
        ),
        _buildMetricCard(
          title: 'Efficiency Score',
          value: '87%',
          icon: Icons.trending_up,
          color: Colors.green,
          trend: '+3%',
          trendUp: true,
        ),
        _buildMetricCard(
          title: 'Incidents',
          value: '3',
          icon: Icons.warning,
          color: Colors.red,
          trend: '-2',
          trendUp: true,
        ),
      ],
    );
  }
  
  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
    required bool trendUp,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: trendUp ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendUp ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: trendUp ? Colors.green : Colors.red,
                      ),
                      Text(
                        trend,
                        style: TextStyle(
                          fontSize: 10,
                          color: trendUp ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPerformanceChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey[300],
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                      if (value.toInt() >= 0 && value.toInt() < days.length) {
                        return Text(
                          days[value.toInt()],
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: const [
                    FlSpot(0, 65),
                    FlSpot(1, 72),
                    FlSpot(2, 78),
                    FlSpot(3, 75),
                    FlSpot(4, 82),
                    FlSpot(5, 87),
                    FlSpot(6, 85),
                  ],
                  isCurved: true,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTrainStats() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatRow('Avg Trains per Sim', '4.2', Colors.blue),
            const Divider(),
            _buildStatRow('Max Concurrent', '8', Colors.orange),
            const Divider(),
            _buildStatRow('Total Distance', '1,234 km', Colors.green),
            const Divider(),
            _buildStatRow('Avg Speed', '65 km/h', Colors.purple),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSignalEfficiency() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProgressBar('Signal C31', 0.92, Colors.green),
            const SizedBox(height: 16),
            _buildProgressBar('Signal C32', 0.85, Colors.blue),
            const SizedBox(height: 16),
            _buildProgressBar('Signal C33', 0.78, Colors.orange),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
  
  Widget _buildBlockUsageChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 100,
              barGroups: [
                _makeBarGroup(0, 85, Colors.blue),
                _makeBarGroup(1, 72, Colors.orange),
                _makeBarGroup(2, 95, Colors.red),
                _makeBarGroup(3, 68, Colors.green),
                _makeBarGroup(4, 78, Colors.purple),
              ],
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text('B${value.toInt() + 1}');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text('${value.toInt()}%');
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ),
    );
  }
  
  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 20,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }
  
  Widget _buildAIInsights() {
    return Consumer<DiagnosticAI>(
      builder: (context, diagnostic, _) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'AI Recommendations',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInsightItem(
                  'Consider adding more trains during peak hours for better throughput',
                  Icons.info,
                  Colors.blue,
                ),
                const SizedBox(height: 12),
                _buildInsightItem(
                  'Block B3 shows high congestion - review signal timing',
                  Icons.warning,
                  Colors.orange,
                ),
                const SizedBox(height: 12),
                _buildInsightItem(
                  'Overall performance improved by 12% this week!',
                  Icons.check_circle,
                  Colors.green,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildInsightItem(String text, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSystemHealth() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Overall Health', style: TextStyle(fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Excellent',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildHealthMetric('CPU Usage', 0.45, Colors.green),
            const SizedBox(height: 12),
            _buildHealthMetric('Memory', 0.62, Colors.blue),
            const SizedBox(height: 12),
            _buildHealthMetric('Network', 0.35, Colors.green),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHealthMetric(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
  
  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate loading
    setState(() => _isLoading = false);
  }
}
