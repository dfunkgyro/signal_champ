import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/connection_service.dart';
import '../services/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

/// Comprehensive connection debugging panel
class ConnectionDebugPanel extends StatefulWidget {
  const ConnectionDebugPanel({Key? key}) : super(key: key);

  @override
  State<ConnectionDebugPanel> createState() => _ConnectionDebugPanelState();
}

class _ConnectionDebugPanelState extends State<ConnectionDebugPanel> {
  final List<String> _debugLogs = [];
  bool _isTestingOpenAI = false;
  bool _isTestingSupabase = false;
  String? _openAiTestResult;
  String? _supabaseTestResult;

  @override
  void initState() {
    super.initState();
    _runInitialDiagnostics();
  }

  void _addLog(String message) {
    setState(() {
      _debugLogs.insert(0, '[${DateTime.now().toLocal()}] $message');
      if (_debugLogs.length > 100) {
        _debugLogs.removeLast();
      }
    });
  }

  Future<void> _runInitialDiagnostics() async {
    _addLog('Starting connection diagnostics...');

    // Check .env file
    try {
      final envFile = File('assets/.env');
      if (await envFile.exists()) {
        _addLog('✓ .env file found');
      } else {
        _addLog('✗ .env file NOT found in assets/ directory');
      }
    } catch (e) {
      _addLog('✗ Error checking .env file: $e');
    }

    // Check environment variables
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    final openAiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

    if (supabaseUrl.isEmpty) {
      _addLog('✗ SUPABASE_URL is empty or not loaded');
    } else if (supabaseUrl.contains('your-project-id')) {
      _addLog('✗ SUPABASE_URL contains placeholder value');
    } else {
      _addLog('✓ SUPABASE_URL loaded: ${supabaseUrl.substring(0, 20)}...');
    }

    if (supabaseKey.isEmpty) {
      _addLog('✗ SUPABASE_ANON_KEY is empty or not loaded');
    } else if (supabaseKey.contains('your-anon-key')) {
      _addLog('✗ SUPABASE_ANON_KEY contains placeholder value');
    } else {
      _addLog('✓ SUPABASE_ANON_KEY loaded: ${supabaseKey.substring(0, 20)}...');
    }

    if (openAiKey == null || openAiKey.isEmpty) {
      _addLog('✗ OPENAI_API_KEY is empty or not loaded');
    } else if (openAiKey.contains('your_api_key')) {
      _addLog('✗ OPENAI_API_KEY contains placeholder value');
    } else {
      _addLog('✓ OPENAI_API_KEY loaded: ${openAiKey.substring(0, 10)}...');
    }

    _addLog('Diagnostics complete');
  }

  Future<void> _testOpenAIConnection(ConnectionService connectionService) async {
    setState(() {
      _isTestingOpenAI = true;
      _openAiTestResult = null;
    });

    _addLog('Testing OpenAI connection...');

    try {
      final success = await connectionService.checkAiConnection();

      setState(() {
        _openAiTestResult = success
            ? '✓ OpenAI connection successful'
            : '✗ OpenAI connection failed: ${connectionService.aiStatus}';
        _isTestingOpenAI = false;
      });

      _addLog(_openAiTestResult!);

      if (!success) {
        _addLog('OpenAI troubleshooting:');
        _addLog('1. Check if API key is valid');
        _addLog('2. Verify internet connection');
        _addLog('3. Check if you have OpenAI API credits');
        _addLog('4. Ensure API key starts with "sk-"');
      }
    } catch (e) {
      setState(() {
        _openAiTestResult = '✗ Error testing OpenAI: $e';
        _isTestingOpenAI = false;
      });
      _addLog(_openAiTestResult!);
    }
  }

  Future<void> _testSupabaseConnection(ConnectionService connectionService) async {
    setState(() {
      _isTestingSupabase = true;
      _supabaseTestResult = null;
    });

    _addLog('Testing Supabase connection...');

    try {
      final success = await connectionService.checkSupabaseConnection();

      setState(() {
        _supabaseTestResult = success
            ? '✓ Supabase connection successful'
            : '✗ Supabase connection failed: ${connectionService.supabaseStatus}';
        _isTestingSupabase = false;
      });

      _addLog(_supabaseTestResult!);

      if (!success) {
        _addLog('Supabase troubleshooting:');
        _addLog('1. Check if URL and key are correct');
        _addLog('2. Verify internet connection');
        _addLog('3. Ensure Supabase project is active');
        _addLog('4. Check if connection_test table exists');
        _addLog('5. Try creating connection_test table in SQL editor');
      }
    } catch (e) {
      setState(() {
        _supabaseTestResult = '✗ Error testing Supabase: $e';
        _isTestingSupabase = false;
      });
      _addLog(_supabaseTestResult!);
    }
  }

  void _copyLogsToClipboard() {
    final logsText = _debugLogs.join('\n');
    Clipboard.setData(ClipboardData(text: logsText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs copied to clipboard')),
    );
  }

  void _clearLogs() {
    setState(() {
      _debugLogs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ConnectionService, AuthService>(
      builder: (context, connectionService, authService, _) {
        return Dialog(
          child: Container(
            width: 700,
            height: 600,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.bug_report, size: 28),
                    const SizedBox(width: 8),
                    const Text(
                      'Connection Diagnostics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),

                // Status cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusCard(
                        'OpenAI API',
                        connectionService.isAiConnected,
                        connectionService.aiStatus,
                        Icons.psychology,
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatusCard(
                        'Supabase',
                        connectionService.isSupabaseConnected,
                        connectionService.supabaseStatus,
                        Icons.cloud,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatusCard(
                        'Auth',
                        authService.isConnected,
                        authService.connectionStatus,
                        Icons.person,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Test buttons
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isTestingOpenAI
                          ? null
                          : () => _testOpenAIConnection(connectionService),
                      icon: _isTestingOpenAI
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow),
                      label: const Text('Test OpenAI'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isTestingSupabase
                          ? null
                          : () => _testSupabaseConnection(connectionService),
                      icon: _isTestingSupabase
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow),
                      label: const Text('Test Supabase'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _copyLogsToClipboard,
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Logs'),
                    ),
                    TextButton.icon(
                      onPressed: _clearLogs,
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Clear'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Test results
                if (_openAiTestResult != null || _supabaseTestResult != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_openAiTestResult != null)
                          Text(
                            _openAiTestResult!,
                            style: TextStyle(
                              color: _openAiTestResult!.startsWith('✓')
                                  ? Colors.green[700]
                                  : Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (_supabaseTestResult != null)
                          Text(
                            _supabaseTestResult!,
                            style: TextStyle(
                              color: _supabaseTestResult!.startsWith('✓')
                                  ? Colors.green[700]
                                  : Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Debug logs
                const Text(
                  'Debug Logs',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[700]!),
                    ),
                    child: _debugLogs.isEmpty
                        ? const Center(
                            child: Text(
                              'No logs yet',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _debugLogs.length,
                            itemBuilder: (context, index) {
                              final log = _debugLogs[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  log,
                                  style: TextStyle(
                                    color: log.contains('✗')
                                        ? Colors.red[300]
                                        : log.contains('✓')
                                            ? Colors.green[300]
                                            : Colors.white,
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),

                // Help section
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ensure assets/.env file exists with valid credentials. '
                          'See assets/.env.example for template.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(
    String title,
    bool isConnected,
    String status,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isConnected ? color.withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? color : Colors.grey[400]!,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isConnected ? color : Colors.grey[600],
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isConnected ? color : Colors.grey[400]!,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isConnected ? 'CONNECTED' : 'DISCONNECTED',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
