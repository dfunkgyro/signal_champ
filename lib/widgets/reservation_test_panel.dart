import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/terminal_station_controller.dart';
import '../services/reservation_validator.dart';

/// Panel for testing signal reservations in Control Table mode
class ReservationTestPanel extends StatefulWidget {
  final String title;

  const ReservationTestPanel({
    Key? key,
    this.title = 'Reservation Test',
  }) : super(key: key);

  @override
  State<ReservationTestPanel> createState() => _ReservationTestPanelState();
}

class _ReservationTestPanelState extends State<ReservationTestPanel> {
  Map<String, List<ReservationTestResult>> _testResults = {};
  ReservationTestSummary? _summary;
  bool _isTesting = false;
  String? _selectedSignalId;
  String? _selectedRouteId;
  ReservationTestResult? _selectedResult;

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TerminalStationController>(context);
    final validator = ReservationValidator(controller);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(validator),

          // Summary
          if (_summary != null) _buildSummary(),

          // Test Results
          Expanded(
            child: _testResults.isEmpty
                ? _buildEmptyState()
                : _buildResultsList(controller),
          ),

          // Selected Result Detail
          if (_selectedResult != null) _buildSelectedResultPanel(),
        ],
      ),
    );
  }

  Widget _buildHeader(ReservationValidator validator) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        border: Border(
          bottom: BorderSide(color: Colors.grey[700]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isTesting ? null : () => _testAllSignals(validator),
                  icon: _isTesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow, size: 18),
                  label: Text(_isTesting ? 'Testing...' : 'Test All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _testResults.isEmpty
                      ? null
                      : () {
                          setState(() {
                            _testResults.clear();
                            _summary = null;
                            _selectedResult = null;
                          });
                        },
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Clear'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[400],
                    side: BorderSide(color: Colors.grey[700]!),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        border: Border(
          bottom: BorderSide(color: Colors.grey[700]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryStat(
                'Total',
                _summary!.totalTests.toString(),
                Colors.blue,
              ),
              _buildSummaryStat(
                'Passed',
                _summary!.passed.toString(),
                Colors.green,
              ),
              _buildSummaryStat(
                'Failed',
                _summary!.failed.toString(),
                Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryStat(
                'Critical',
                _summary!.criticalIssues.toString(),
                Colors.red,
              ),
              _buildSummaryStat(
                'Warnings',
                _summary!.warnings.toString(),
                Colors.orange,
              ),
              _buildSummaryStat(
                'Pass Rate',
                '${_summary!.passRate.toStringAsFixed(1)}%',
                _summary!.passRate >= 90 ? Colors.green : Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_outline,
            color: Colors.grey[600],
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No tests run yet',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click "Test All" to validate\nall signal reservations',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(TerminalStationController controller) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _testResults.length,
      itemBuilder: (context, index) {
        final signalId = _testResults.keys.elementAt(index);
        final results = _testResults[signalId]!;
        return _buildSignalCard(signalId, results, controller);
      },
    );
  }

  Widget _buildSignalCard(
    String signalId,
    List<ReservationTestResult> results,
    TerminalStationController controller,
  ) {
    final signal = controller.signals[signalId];
    if (signal == null) return const SizedBox.shrink();

    final allPassed = results.every((r) => r.passed);
    final hasCritical = results.any((r) => r.severity == ReservationIssueSeverity.critical);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasCritical
              ? Colors.red
              : allPassed
                  ? Colors.green
                  : Colors.orange,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Signal Header
          InkWell(
            onTap: () {
              setState(() {
                if (_selectedSignalId == signalId) {
                  _selectedSignalId = null;
                } else {
                  _selectedSignalId = signalId;
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    allPassed ? Icons.check_circle : Icons.error,
                    color: hasCritical
                        ? Colors.red
                        : allPassed
                            ? Colors.green
                            : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          signalId,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${results.length} route(s) - ${allPassed ? "All passed" : "${results.where((r) => !r.passed).length} issue(s)"}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _selectedSignalId == signalId
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),

          // Routes (expandable)
          if (_selectedSignalId == signalId)
            ...results.map((result) => _buildRouteItem(result)),
        ],
      ),
    );
  }

  Widget _buildRouteItem(ReservationTestResult result) {
    return InkWell(
      onTap: () {
        setState(() {
          if (_selectedResult?.routeId == result.routeId &&
              _selectedResult?.signalId == result.signalId) {
            _selectedResult = null;
          } else {
            _selectedResult = result;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _selectedResult?.routeId == result.routeId &&
                  _selectedResult?.signalId == result.signalId
              ? Colors.orange.withOpacity(0.1)
              : Colors.transparent,
          border: Border(
            top: BorderSide(color: Colors.grey[800]!),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: result.severityColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                result.severityLabel,
                style: TextStyle(
                  color: result.severityColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.routeName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.summary,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              result.passed ? Icons.check : Icons.arrow_forward,
              color: result.passed ? Colors.green : Colors.orange,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedResultPanel() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        border: Border(
          top: BorderSide(color: Colors.grey[700]!, width: 2),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _selectedResult!.severityIcon,
                  color: _selectedResult!.severityColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_selectedResult!.signalId} - ${_selectedResult!.routeName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  color: Colors.grey[400],
                  iconSize: 20,
                  onPressed: () {
                    setState(() {
                      _selectedResult = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Explanation
            _buildDetailSection('Explanation', _selectedResult!.explanation),
            const SizedBox(height: 16),

            // Expected vs Actual
            _buildBlockComparison(),
            const SizedBox(height: 16),

            // Suggested Fix
            _buildDetailSection('Suggested Fix', _selectedResult!.suggestedFix),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to control table entry for this signal/route
                      _showControlTableEntry();
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit Control Table'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: Text(
            content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlockComparison() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Block Comparison',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildBlockList(
                'Expected',
                _selectedResult!.expectedBlocks.toList(),
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBlockList(
                'Actual',
                _selectedResult!.actualBlocks.toList(),
                Colors.green,
              ),
            ),
          ],
        ),
        if (_selectedResult!.missingBlocks.isNotEmpty ||
            _selectedResult!.extraBlocks.isNotEmpty) ...[
          const SizedBox(height: 12),
          if (_selectedResult!.missingBlocks.isNotEmpty)
            _buildBlockList(
              'Missing (CRITICAL!)',
              _selectedResult!.missingBlocks.toList(),
              Colors.red,
            ),
          if (_selectedResult!.extraBlocks.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildBlockList(
              'Extra (Warning)',
              _selectedResult!.extraBlocks.toList(),
              Colors.orange,
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildBlockList(String title, List<String> blocks, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...blocks.map((block) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 6, color: color),
                    const SizedBox(width: 6),
                    Text(
                      block,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  void _testAllSignals(ReservationValidator validator) async {
    setState(() {
      _isTesting = true;
      _testResults.clear();
      _selectedResult = null;
    });

    // Simulate async testing
    await Future.delayed(const Duration(milliseconds: 500));

    final results = validator.testAllSignals();
    final summary = validator.getSummary(results);

    setState(() {
      _testResults = results;
      _summary = summary;
      _isTesting = false;
    });
  }

  void _showControlTableEntry() {
    // This would navigate to or highlight the control table entry
    // for the selected signal/route
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Open control table for ${_selectedResult!.signalId} - ${_selectedResult!.routeName}',
        ),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () {
            // Navigate to control table entry
          },
        ),
      ),
    );
  }
}
