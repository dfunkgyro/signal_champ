import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/analytics_service.dart';
import '../services/connection_service.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isAuthenticated = false;
  final _passwordController = TextEditingController();
  final String _correctPassword = 'password'; // As specified by user

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _checkPassword() {
    if (_passwordController.text == _correctPassword) {
      setState(() => _isAuthenticated = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect password'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return _buildPasswordScreen();
    }

    return _buildAnalyticsScreen();
  }

  Widget _buildPasswordScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              const Text(
                'Enter Password',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'This section is password protected',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.key),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _checkPassword(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkPassword,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Unlock'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsScreen() {
    final analyticsService = context.watch<AnalyticsService>();
    final connectionService = context.watch<ConnectionService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              analyticsService.getAppUsageStats();
              connectionService.checkAllConnections();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await analyticsService.getAppUsageStats();
          await connectionService.checkAllConnections();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Connection Status Card
            _buildConnectionStatusCard(connectionService),
            const SizedBox(height: 16),

            // Device Info Card
            _buildDeviceInfoCard(analyticsService),
            const SizedBox(height: 16),

            // Location Card
            _buildLocationCard(analyticsService),
            const SizedBox(height: 16),

            // App Usage Card
            _buildAppUsageCard(analyticsService),
            const SizedBox(height: 16),

            // Analytics Summary Card
            _buildAnalyticsSummaryCard(analyticsService),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatusCard(ConnectionService connectionService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wifi, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Connection Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Supabase Status
            _buildStatusRow(
              'Supabase',
              connectionService.supabaseStatus,
              connectionService.isSupabaseConnected,
            ),
            const SizedBox(height: 8),

            // AI Status
            _buildStatusRow(
              'AI Service',
              connectionService.aiStatus,
              connectionService.isAiConnected,
            ),
            const SizedBox(height: 8),

            // Fallback Mode
            if (connectionService.fallbackMode)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'App is running in fallback mode (offline)',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String status, bool isConnected) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isConnected ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        Text(
          status,
          style: TextStyle(
            color: isConnected ? Colors.green : Colors.red,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceInfoCard(AnalyticsService analyticsService) {
    final deviceInfo = analyticsService.deviceInfo;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.phone_android, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Device Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            if (deviceInfo.isEmpty)
              const Text('Loading device info...')
            else
              ...deviceInfo.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(entry.value.toString()),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(AnalyticsService analyticsService) {
    final position = analyticsService.currentPosition;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: analyticsService.isLocationEnabled,
                  onChanged: (value) async {
                    if (value) {
                      await analyticsService.requestLocationPermission();
                      await analyticsService.startLocationTracking();
                    }
                  },
                ),
              ],
            ),
            const Divider(),
            if (position != null) ...[
              _buildInfoRow('Latitude', position.latitude.toStringAsFixed(6)),
              _buildInfoRow('Longitude', position.longitude.toStringAsFixed(6)),
              _buildInfoRow('Accuracy', '${position.accuracy.toStringAsFixed(1)}m'),
              _buildInfoRow('Altitude', '${position.altitude.toStringAsFixed(1)}m'),
              _buildInfoRow('Speed', '${position.speed.toStringAsFixed(1)} m/s'),
            ] else
              const Text('Location not available'),
            const SizedBox(height: 8),
            if (!analyticsService.isLocationEnabled)
              ElevatedButton.icon(
                onPressed: () async {
                  await analyticsService.requestLocationPermission();
                  await analyticsService.startLocationTracking();
                },
                icon: const Icon(Icons.location_on),
                label: const Text('Enable Location'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppUsageCard(AnalyticsService analyticsService) {
    final appUsageStats = analyticsService.appUsageStats;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'App Usage Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            if (!analyticsService.isAppUsagePermissionGranted) ...[
              const Text('Permission not granted'),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  final granted = await analyticsService.requestAppUsagePermission();
                  if (!granted && mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Permission Required'),
                        content: const Text(
                          'Please grant Usage Access permission in Settings:\n\n'
                          'Settings > Apps > Special Access > Usage Access',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.settings),
                label: const Text('Request Permission'),
              ),
            ] else if (appUsageStats.isEmpty) ...[
              const Text('No usage data available'),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => analyticsService.getAppUsageStats(),
                icon: const Icon(Icons.refresh),
                label: const Text('Load Usage Stats'),
              ),
            ] else ...[
              Text('Total Apps: ${appUsageStats.length}'),
              const SizedBox(height: 8),
              ...appUsageStats.take(5).map((app) {
                final hours = app.usage.inHours;
                final minutes = app.usage.inMinutes % 60;
                return ListTile(
                  dense: true,
                  title: Text(app.appName),
                  subtitle: Text(app.packageName),
                  trailing: Text('${hours}h ${minutes}m'),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsSummaryCard(AnalyticsService analyticsService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Analytics Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            FutureBuilder<Map<String, dynamic>>(
              future: analyticsService.getAnalyticsSummary(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData) {
                  return const Text('No data available');
                }

                final summary = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Status', analyticsService.analyticsStatus),
                    _buildInfoRow(
                      'Location Enabled',
                      summary['location_enabled'].toString(),
                    ),
                    _buildInfoRow(
                      'App Usage Permission',
                      summary['app_usage_permission'].toString(),
                    ),
                    if (summary['total_events'] != null)
                      _buildInfoRow(
                        'Total Events (30 days)',
                        summary['total_events'].toString(),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
