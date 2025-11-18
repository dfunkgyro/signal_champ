import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connection_service.dart';
import '../services/auth_service.dart';

/// Widget to display connection status for AI and Supabase
class ConnectionIndicator extends StatelessWidget {
  final bool showDetails;

  const ConnectionIndicator({
    Key? key,
    this.showDetails = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final connectionService = context.watch<ConnectionService>();
    final authService = context.watch<AuthService>();

    if (showDetails) {
      return _buildDetailedIndicator(connectionService, authService);
    } else {
      return _buildCompactIndicator(connectionService, authService);
    }
  }

  Widget _buildCompactIndicator(
    ConnectionService connectionService,
    AuthService authService,
  ) {
    final isConnected = connectionService.isSupabaseConnected ||
        connectionService.isAiConnected ||
        authService.isConnected;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isConnected
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.cloud_done : Icons.cloud_off,
            size: 14,
            color: isConnected ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          if (connectionService.fallbackMode)
            const Text(
              'Offline',
              style: TextStyle(fontSize: 10, color: Colors.orange),
            )
          else
            Text(
              'Online',
              style: TextStyle(
                fontSize: 10,
                color: isConnected ? Colors.green : Colors.orange,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailedIndicator(
    ConnectionService connectionService,
    AuthService authService,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Connection Status',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          _buildStatusRow(
            'Supabase',
            connectionService.isSupabaseConnected,
            connectionService.supabaseStatus,
          ),
          const SizedBox(height: 4),
          _buildStatusRow(
            'AI Service',
            connectionService.isAiConnected,
            connectionService.aiStatus,
          ),
          const SizedBox(height: 4),
          _buildStatusRow(
            'Auth',
            authService.isConnected,
            authService.connectionStatus,
          ),
          if (connectionService.fallbackMode) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, size: 12, color: Colors.orange),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Fallback mode active',
                      style: TextStyle(fontSize: 10, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isConnected, String status) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isConnected ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ),
        Flexible(
          child: Text(
            status,
            style: TextStyle(
              fontSize: 9,
              color: isConnected ? Colors.green : Colors.red,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
