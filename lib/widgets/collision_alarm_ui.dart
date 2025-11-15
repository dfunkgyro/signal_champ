// MA1 v3.0 - Collision Alarm UI Components
import 'package:flutter/material.dart';
import '../screens/collision_analysis_system.dart';

// ============================================================================
// COLLISION ALARM WIDGET (Red Flashing Banner)
// ============================================================================
class CollisionAlarmWidget extends StatefulWidget {
  final bool isActive;
  final CollisionIncident? currentIncident;
  final VoidCallback onDismiss;
  final bool isSPAD; // New parameter for SPAD incidents
  final String? trainStopId; // New parameter for train stop ID
  final VoidCallback? onAutoRecover; // New: Auto recovery callback
  final VoidCallback? onManualRecover; // New: Manual recovery callback
  final VoidCallback? onForceResolve; // New: Force resolve callback

  const CollisionAlarmWidget({
    Key? key,
    required this.isActive,
    required this.currentIncident,
    required this.onDismiss,
    this.isSPAD = false,
    this.trainStopId,
    this.onAutoRecover,
    this.onManualRecover,
    this.onForceResolve,
  }) : super(key: key);

  @override
  State<CollisionAlarmWidget> createState() => _CollisionAlarmWidgetState();
}

class _CollisionAlarmWidgetState extends State<CollisionAlarmWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: widget.isSPAD ? Colors.orange.shade900 : Colors.red.shade900,
      end: widget.isSPAD ? Colors.orange.shade600 : Colors.red.shade600,
    ).animate(_controller);
  }

  @override
  void didUpdateWidget(CollisionAlarmWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSPAD != oldWidget.isSPAD) {
      _colorAnimation = ColorTween(
        begin: widget.isSPAD ? Colors.orange.shade900 : Colors.red.shade900,
        end: widget.isSPAD ? Colors.orange.shade600 : Colors.red.shade600,
      ).animate(_controller);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive || widget.currentIncident == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            boxShadow: [
              BoxShadow(
                color: (widget.isSPAD ? Colors.orange : Colors.red)
                    .withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                widget.isSPAD ? Icons.warning_amber : Icons.warning,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.isSPAD
                          ? '🚨 SPAD DETECTED'
                          : '🚨 COLLISION DETECTED',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isSPAD
                          ? 'TrainStop: ${widget.trainStopId} | '
                              'Train: ${widget.currentIncident!.trainsInvolved.join(", ")} | '
                              'SPAD Violation'
                          : 'Location: ${widget.currentIncident!.location} | '
                              'Trains: ${widget.currentIncident!.trainsInvolved.join(", ")} | '
                              'Severity: ${widget.currentIncident!.severity.name.toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    if (widget.isSPAD) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Manual train failed to stop at activated TrainStop',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Recovery buttons (only show for collision, not SPAD)
              ElevatedButton.icon(
                onPressed: () {
                  _showIncidentReport(
                      context, widget.currentIncident!, widget.isSPAD);
                },
                icon: const Icon(Icons.article),
                label: const Text('Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: widget.isSPAD
                      ? Colors.orange.shade900
                      : Colors.red.shade900,
                ),
              ),
              const SizedBox(width: 8),
              if (widget.onForceResolve != null) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    widget.onForceResolve?.call();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Collision forcefully resolved'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.done_all),
                  label: const Text('Force Recovery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (widget.isSPAD) ...[
                ElevatedButton.icon(
                  onPressed: widget.onDismiss,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Acknowledge'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showIncidentReport(
      BuildContext context, CollisionIncident incident, bool isSPAD) {
    showDialog(
      context: context,
      builder: (context) =>
          IncidentReportDialog(incident: incident, isSPAD: isSPAD),
    );
  }

  void _confirmForceResolve(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Force Resolve Collision'),
          ],
        ),
        content: const Text(
            'This will immediately clear the collision state and reset all involved trains. '
            'Use this only if automatic recovery has failed or you need to override the system.\n\n'
            'Are you sure you want to proceed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onForceResolve?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Collision forcefully resolved'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
            ),
            child: const Text('Force Resolve'),
          ),
        ],
      ),
    );
  }
}

// Update IncidentReportDialog to show SPAD-specific information
class IncidentReportDialog extends StatelessWidget {
  final CollisionIncident incident;
  final bool isSPAD;

  const IncidentReportDialog({
    Key? key,
    required this.incident,
    this.isSPAD = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(isSPAD ? Icons.warning_amber : Icons.assignment,
                    size: 32, color: isSPAD ? Colors.orange : Colors.red),
                const SizedBox(width: 12),
                Text(
                  isSPAD ? 'SPAD Incident Report' : 'Collision Incident Report',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(thickness: 2),
            const SizedBox(height: 16),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Incident ID & Timestamp
                    _buildSection(
                      'Incident Information',
                      [
                        _buildInfoRow('Incident ID', incident.id),
                        _buildInfoRow(
                          'Timestamp',
                          _formatDateTime(incident.timestamp),
                        ),
                        if (isSPAD)
                          _buildInfoRow('Incident Type',
                              'SPAD (Signal Passed At Danger)'),
                        _buildInfoRow(
                          'Severity',
                          incident.severity.name.toUpperCase(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // SPAD-specific information
                    if (isSPAD) ...[
                      _buildSection(
                        'SPAD Details',
                        [
                          _buildInfoRow(
                            'Violation Type',
                            'TrainStop Activation Ignored',
                          ),
                          _buildInfoRow(
                            'Train Involved',
                            incident.trainsInvolved.join(', '),
                          ),
                          _buildInfoRow(
                            'Responsible Party',
                            incident.specificParty,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Root Causes
                      _buildSection(
                        'Root Cause Analysis',
                        incident.rootCauses.map((cause) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.error,
                                    color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _formatCauseName(cause),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // Responsibility
                      _buildSection(
                        'Responsibility',
                        [
                          _buildInfoRow(
                            'Assigned To',
                            incident.responsibility.name.toUpperCase(),
                          ),
                          _buildInfoRow(
                            'Specific Party',
                            incident.specificParty,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Leading Events
                      _buildSection(
                        'Timeline (Last 60 seconds)',
                        incident.leadingEvents.reversed.take(10).map((event) {
                          final secondsAgo = incident.timestamp
                              .difference(event.timestamp)
                              .inSeconds;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'T-${secondsAgo}s',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${event.trainId}: ${event.description}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // Prevention Recommendations
                      _buildSection(
                        'Prevention Recommendations',
                        incident.preventionRecommendations.map((rec) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    rec,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // Forensic Summary
                      _buildSection(
                        'Forensic Summary',
                        [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              incident.forensicSummary,
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Footer Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // Export functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Report exported (feature coming soon)'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Export Report'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  String _formatCauseName(CollisionCause cause) {
    switch (cause) {
      case CollisionCause.operatorError:
        return 'Operator Error';
      case CollisionCause.signalFailure:
        return 'Signal System Failure';
      case CollisionCause.pointMisalignment:
        return 'Point Misalignment';
      case CollisionCause.signalPassedAtDanger:
        return 'Signal Passed At Danger (SPAD)';
      case CollisionCause.manualModeError:
        return 'Manual Mode Operational Error';
      case CollisionCause.speedExceeded:
        return 'Speed Limit Exceeded';
      case CollisionCause.blockOccupiedIgnored:
        return 'Block Occupation Ignored';
      case CollisionCause.routeNotSet:
        return 'Route Not Properly Set';
      case CollisionCause.simultaneousMovement:
        return 'Simultaneous Conflicting Movement';
      case CollisionCause.systemFailure:
        return 'System/Equipment Failure';
      case CollisionCause.bufferStopCollision:
        return 'Buffer Stop Collision';
    }
  }
}
