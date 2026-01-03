import 'package:flutter/material.dart';

import '../providers/railway_provider.dart';
import '../services/openai_agent_service.dart';

class AIAgentPanel extends StatefulWidget {
  final RailwayProvider provider;

  const AIAgentPanel({
    super.key,
    required this.provider,
  });

  @override
  State<AIAgentPanel> createState() => _AIAgentPanelState();
}

class _AIAgentPanelState extends State<AIAgentPanel> {
  final TextEditingController _promptController = TextEditingController();
  late Future<OpenAiConfig> _configFuture;
  OpenAiAgentService? _service;
  bool _replaceExisting = true;
  bool _includeLabels = true;
  bool _isBusy = false;
  String? _statusMessage;
  AIAgentResponse? _lastResponse;

  @override
  void initState() {
    super.initState();
    _configFuture = OpenAiConfig.loadFromAssets();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OpenAiConfig>(
      future: _configFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildErrorState(
              'Failed to load assets/.env: ${snapshot.error}');
        }
        final config = snapshot.data!;
        _service ??= OpenAiAgentService(config: config);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(config),
              const SizedBox(height: 16),
              _buildPromptInput(),
              const SizedBox(height: 12),
              _buildOptions(),
              const SizedBox(height: 12),
              _buildActions(config),
              if (_statusMessage != null) ...[
                const SizedBox(height: 12),
                _buildStatusMessage(_statusMessage!),
              ],
              if (_lastResponse != null) ...[
                const SizedBox(height: 16),
                _buildResponseSummary(_lastResponse!),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(OpenAiConfig config) {
    final statusColor = config.enabled ? Colors.green : Colors.red;
    final statusText =
        config.enabled ? 'Enabled' : 'Disabled (USE_OPENAI=false)';
    final keyStatus = config.apiKey.isEmpty ? 'Missing' : 'Set';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.smart_toy, color: Colors.blueGrey),
              const SizedBox(width: 8),
              const Text(
                'OpenAI Railway Agent',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Status: ', style: TextStyle(color: Colors.grey[600])),
              Text(statusText, style: TextStyle(color: statusColor)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Model: ', style: TextStyle(color: Colors.grey[600])),
              Text(config.model),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('API Key: ', style: TextStyle(color: Colors.grey[600])),
              Text(keyStatus),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromptInput() {
    return TextField(
      controller: _promptController,
      minLines: 4,
      maxLines: 8,
      decoration: const InputDecoration(
        labelText: 'Describe the railway layout or validation request',
        alignLabelWithHint: true,
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildOptions() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Replace existing layout'),
          subtitle: const Text('Disable to merge into current layout'),
          value: _replaceExisting,
          onChanged: _isBusy ? null : (value) {
            setState(() => _replaceExisting = value);
          },
        ),
        SwitchListTile(
          title: const Text('Apply automatic labels'),
          subtitle: const Text('Use AI generated labels and annotations'),
          value: _includeLabels,
          onChanged: _isBusy ? null : (value) {
            setState(() => _includeLabels = value);
          },
        ),
      ],
    );
  }

  Widget _buildActions(OpenAiConfig config) {
    final canRun =
        !_isBusy && config.enabled && config.apiKey.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: canRun ? _onGenerateLayout : null,
          icon: _isBusy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_fix_high),
          label: const Text('Generate Layout'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: canRun ? _onValidateLayout : null,
          icon: const Icon(Icons.fact_check),
          label: const Text('Validate Layout'),
        ),
        if (_lastResponse?.recommendedLayout != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _isBusy ? null : _applyRecommendedLayout,
            icon: const Icon(Icons.build_circle_outlined),
            label: const Text('Apply Recommendations'),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Text(message, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _buildResponseSummary(AIAgentResponse response) {
    final validation = response.validation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Agent Summary',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (validation != null) ...[
          _buildValidationSummary(validation),
          const SizedBox(height: 12),
        ],
        if (response.advice.isNotEmpty) ...[
          const Text(
            'Advice',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          ...response.advice.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $tip'),
              )),
        ],
      ],
    );
  }

  Widget _buildValidationSummary(AIAgentValidation validation) {
    final canRunText = validation.canSupportMultipleTrains == null
        ? 'Unknown'
        : validation.canSupportMultipleTrains == true
            ? 'Yes'
            : 'No';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            validation.summary.isEmpty
                ? 'Validation summary not provided.'
                : validation.summary,
          ),
          const SizedBox(height: 8),
          Text('Multiple trains supported: $canRunText'),
          if (validation.issues.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Issues',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            ...validation.issues.map((issue) {
              final suggestion = issue.suggestion;
              final suffix = suggestion == null || suggestion.isEmpty
                  ? ''
                  : ' (${suggestion})';
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('[${issue.severity}] ${issue.message}$suffix'),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }

  Future<void> _onGenerateLayout() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      _showSnack('Please describe the layout you want to create.');
      return;
    }

    setState(() {
      _isBusy = true;
      _statusMessage = 'Generating layout with OpenAI...';
    });

    try {
      final response = await _service!.generateLayout(
        description: prompt,
        currentData: widget.provider.data,
      );
      final layout = response.layout;
      if (layout != null) {
        widget.provider.applyGeneratedLayout(
          layout.data,
          textAnnotations: _includeLabels ? layout.labels : const [],
          replaceExisting: _replaceExisting,
        );
        _statusMessage = 'Layout applied successfully.';
      } else {
        _statusMessage = 'No layout data returned by the agent.';
      }
      _lastResponse = response;
    } catch (error) {
      _statusMessage = 'Generation failed: $error';
    } finally {
      setState(() => _isBusy = false);
    }
  }

  Future<void> _onValidateLayout() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      _showSnack('Please describe what you want validated.');
      return;
    }

    setState(() {
      _isBusy = true;
      _statusMessage = 'Validating layout with OpenAI...';
    });

    try {
      final response = await _service!.validateLayout(
        description: prompt,
        currentData: widget.provider.data,
      );
      _lastResponse = response;
      _statusMessage = 'Validation complete.';
    } catch (error) {
      _statusMessage = 'Validation failed: $error';
    } finally {
      setState(() => _isBusy = false);
    }
  }

  void _applyRecommendedLayout() {
    final recommended = _lastResponse?.recommendedLayout;
    if (recommended == null) {
      return;
    }

    widget.provider.applyGeneratedLayout(
      recommended.data,
      textAnnotations: _includeLabels ? recommended.labels : const [],
      replaceExisting: _replaceExisting,
    );
    setState(() {
      _statusMessage = 'Recommended layout applied.';
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
