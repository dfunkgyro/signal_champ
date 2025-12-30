import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../controllers/terminal_station_controller.dart';
import '../services/control_table_ai_service.dart';
import '../models/control_table_models.dart';

/// AI-powered Control Table Panel for the right sidebar
/// Provides automatic analysis, chat interface, and suggestion review
class AIControlTablePanel extends StatefulWidget {
  final String title;

  const AIControlTablePanel({
    Key? key,
    this.title = 'Control Table AI',
  }) : super(key: key);

  @override
  State<AIControlTablePanel> createState() => _AIControlTablePanelState();
}

class _AIControlTablePanelState extends State<AIControlTablePanel> with SingleTickerProviderStateMixin {
  late ControlTableAIService _aiService;
  late TabController _tabController;

  // Analysis state
  ControlTableAnalysis? _currentAnalysis;
  bool _isAnalyzing = false;
  bool _autoAnalyzed = false;

  // Chat state
  final List<ChatMessage> _chatHistory = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  bool _isChatLoading = false;

  // Suggestions state
  final List<ControlTableSuggestion> _allSuggestions = [];
  final List<ControlTableSuggestion> _suggestionHistory = [];
  String _suggestionFilter = 'all'; // all, pending, applied

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeAIService();
  }

  void _initializeAIService() async {
    try {
      await dotenv.load(fileName: 'assets/.env');
      final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

      if (apiKey.isEmpty) {
        _showError('OpenAI API key not found in .env file');
        return;
      }

      _aiService = ControlTableAIService(apiKey: apiKey);

      // Auto-analyze on load
      if (!_autoAnalyzed) {
        _autoAnalyzed = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          _performAnalysis();
        });
      }
    } catch (e) {
      _showError('Failed to initialize AI service: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _performAnalysis() async {
    if (_isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
    });

    final controller = context.read<TerminalStationController>();

    try {
      final analysis = await _aiService.analyzeControlTable(
        signals: controller.signals,
        points: controller.points,
        blocks: controller.blocks,
        axleCounters: controller.axleCounters,
        controlTableConfig: controller.controlTableConfig,
      );

      setState(() {
        _currentAnalysis = analysis;
        _isAnalyzing = false;

        // Add new suggestions
        for (var suggestion in analysis.suggestions) {
          if (!_allSuggestions.any((s) => s.id == suggestion.id)) {
            _allSuggestions.add(suggestion);
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis complete: ${analysis.conflicts.length} issues found, ${analysis.suggestions.length} suggestions'),
            backgroundColor: Colors.green[700],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      _showError('Analysis failed: $e');
    }
  }

  Future<void> _sendChatMessage() async {
    final message = _chatController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _chatHistory.add(ChatMessage(content: message, isUser: true));
      _chatController.clear();
      _isChatLoading = true;
    });

    _scrollChatToBottom();

    final controller = context.read<TerminalStationController>();

    try {
      final response = await _aiService.processChatMessage(
        userMessage: message,
        conversationHistory: _chatHistory,
        signals: controller.signals,
        points: controller.points,
        blocks: controller.blocks,
        axleCounters: controller.axleCounters,
        controlTableConfig: controller.controlTableConfig,
      );

      setState(() {
        _chatHistory.add(ChatMessage(content: response.message, isUser: false));
        _isChatLoading = false;

        // Add any suggestions from the chat
        for (var suggestion in response.suggestions) {
          if (!_allSuggestions.any((s) => s.id == suggestion.id)) {
            _allSuggestions.add(suggestion);
          }
        }
      });

      _scrollChatToBottom();
    } catch (e) {
      setState(() {
        _isChatLoading = false;
      });
      _showError('Chat error: $e');
    }
  }

  void _scrollChatToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _applySuggestion(ControlTableSuggestion suggestion) {
    final controller = context.read<TerminalStationController>();

    try {
      // Apply the suggestion based on type
      final action = suggestion.changes['action'];

      switch (action) {
        case 'add_ab':
          _applyABSuggestion(controller, suggestion.changes['data']);
          break;
        case 'update_signal_entry':
          _applySignalEntrySuggestion(controller, suggestion.changes['data']);
          break;
        case 'update_point_entry':
          _applyPointEntrySuggestion(controller, suggestion.changes['data']);
          break;
        case 'add_conflict':
          _applyConflictSuggestion(controller, suggestion.changes['data']);
          break;
        default:
          _showError('Unknown suggestion action: $action');
          return;
      }

      setState(() {
        suggestion.applied = true;
        _suggestionHistory.add(suggestion);
      });

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Applied: ${suggestion.title}'),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () => _undoSuggestion(suggestion),
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to apply suggestion: $e');
    }
  }

  void _applyABSuggestion(TerminalStationController controller, Map<String, dynamic> data) {
    // Implementation for adding AB configuration
    final abConfig = ABConfiguration(
      id: data['id'] ?? 'AB_${DateTime.now().millisecondsSinceEpoch}',
      name: data['name'] ?? 'New AB',
      axleCounter1Id: data['axleCounter1Id'] ?? '',
      axleCounter2Id: data['axleCounter2Id'] ?? '',
      enabled: data['enabled'] ?? true,
    );
    controller.controlTableConfig.updateABConfiguration(abConfig);
  }

  void _applySignalEntrySuggestion(TerminalStationController controller, Map<String, dynamic> data) {
    // Implementation for updating signal entry
    // This would modify the specific control table entry
  }

  void _applyPointEntrySuggestion(TerminalStationController controller, Map<String, dynamic> data) {
    // Implementation for updating point entry
  }

  void _applyConflictSuggestion(TerminalStationController controller, Map<String, dynamic> data) {
    // Implementation for adding conflict markers
  }

  void _undoSuggestion(ControlTableSuggestion suggestion) {
    // Implementation for undoing a suggestion
    setState(() {
      suggestion.applied = false;
      _suggestionHistory.remove(suggestion);
    });

    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Undone: ${suggestion.title}'),
          backgroundColor: Colors.orange[700],
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _batchApplySuggestions() {
    final pendingSuggestions = _allSuggestions.where((s) => !s.applied).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text('Apply All Suggestions?', style: TextStyle(color: Colors.white)),
        content: Text(
          'This will apply ${pendingSuggestions.length} pending suggestions to your control table.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              for (var suggestion in pendingSuggestions) {
                _applySuggestion(suggestion);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            child: const Text('Apply All'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border.all(color: Colors.purple[700]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),

          // Tab Bar
          _buildTabBar(),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAnalysisTab(),
                _buildChatTab(),
                _buildSuggestionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.purple[900],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.smart_toy, color: Colors.white, size: 20),
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
          if (_isAnalyzing)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.purple[900],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        tabs: [
          Tab(
            icon: Icon(Icons.analytics, size: 18),
            text: 'Analysis',
          ),
          Tab(
            icon: Icon(Icons.chat, size: 18),
            text: 'Chat',
          ),
          Tab(
            icon: Icon(Icons.checklist, size: 18),
            text: 'Suggestions',
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisTab() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Refresh button
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _performAnalysis,
                  icon: Icon(Icons.refresh, size: 16),
                  label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze Control Table'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[700],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Analysis Results
          if (_currentAnalysis != null) ...[
            // Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.summarize, color: Colors.blue[300], size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Summary',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentAnalysis!.summary,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Conflicts
            if (_currentAnalysis!.conflicts.isNotEmpty) ...[
              Text(
                'Issues Found (${_currentAnalysis!.conflicts.length})',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _currentAnalysis!.conflicts.length,
                  itemBuilder: (context, index) {
                    final conflict = _currentAnalysis!.conflicts[index];
                    return _buildConflictCard(conflict);
                  },
                ),
              ),
            ] else ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'No issues detected!',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ] else if (!_isAnalyzing) ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.analytics_outlined, color: Colors.grey[600], size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Click "Analyze" to start',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConflictCard(ConflictReport conflict) {
    Color severityColor;
    IconData severityIcon;

    switch (conflict.severity) {
      case 'critical':
        severityColor = Colors.red;
        severityIcon = Icons.error;
        break;
      case 'warning':
        severityColor = Colors.orange;
        severityIcon = Icons.warning;
        break;
      default:
        severityColor = Colors.blue;
        severityIcon = Icons.info;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: severityColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(severityIcon, color: severityColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  conflict.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            conflict.description,
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          if (conflict.affectedItems.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: conflict.affectedItems
                  .map((item) => Chip(
                        label: Text(item, style: TextStyle(fontSize: 9)),
                        backgroundColor: severityColor.withOpacity(0.2),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
          ],
          if (conflict.suggestion.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green[900]?.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.green[300], size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      conflict.suggestion,
                      style: TextStyle(color: Colors.green[200], fontSize: 10),
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

  Widget _buildChatTab() {
    return Column(
      children: [
        // Chat messages
        Expanded(
          child: _chatHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, color: Colors.grey[600], size: 64),
                      const SizedBox(height: 16),
                      Text(
                        'Ask me anything about your control table!',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Examples:\n• "Why is signal S01 conflicting?"\n• "Suggest ABs for Platform 1"\n• "Review my point protection"',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _chatScrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: _chatHistory.length,
                  itemBuilder: (context, index) {
                    final message = _chatHistory[index];
                    return _buildChatMessage(message);
                  },
                ),
        ),

        // Loading indicator
        if (_isChatLoading)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'AI is thinking...',
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
              ],
            ),
          ),

        // Chat input
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            border: Border(top: BorderSide(color: Colors.grey[700]!)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: InputDecoration(
                    hintText: 'Ask a question...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendChatMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isChatLoading ? null : _sendChatMessage,
                icon: Icon(Icons.send),
                color: Colors.purple[300],
                disabledColor: Colors.grey[600],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.purple[700] : Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.content,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildSuggestionsTab() {
    final filteredSuggestions = _allSuggestions.where((s) {
      if (_suggestionFilter == 'pending') return !s.applied;
      if (_suggestionFilter == 'applied') return s.applied;
      return true;
    }).toList();

    return Column(
      children: [
        // Filter and batch apply
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            border: Border(bottom: BorderSide(color: Colors.grey[700]!)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'all', label: Text('All', style: TextStyle(fontSize: 11))),
                        ButtonSegment(value: 'pending', label: Text('Pending', style: TextStyle(fontSize: 11))),
                        ButtonSegment(value: 'applied', label: Text('Applied', style: TextStyle(fontSize: 11))),
                      ],
                      selected: {_suggestionFilter},
                      onSelectionChanged: (Set<String> selected) {
                        setState(() {
                          _suggestionFilter = selected.first;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _allSuggestions.any((s) => !s.applied) ? _batchApplySuggestions : null,
                      icon: Icon(Icons.check_circle, size: 16),
                      label: Text('Apply All Pending'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Suggestions list
        Expanded(
          child: filteredSuggestions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.checklist, color: Colors.grey[600], size: 64),
                      const SizedBox(height: 16),
                      Text(
                        _suggestionFilter == 'all'
                            ? 'No suggestions yet'
                            : _suggestionFilter == 'pending'
                                ? 'No pending suggestions'
                                : 'No applied suggestions',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Run an analysis or ask in chat',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredSuggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = filteredSuggestions[index];
                    return _buildSuggestionCard(suggestion);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSuggestionCard(ControlTableSuggestion suggestion) {
    Color priorityColor;
    switch (suggestion.priority) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      default:
        priorityColor = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: suggestion.applied ? Colors.green : priorityColor,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  suggestion.priority.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  suggestion.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (suggestion.applied)
                Icon(Icons.check_circle, color: Colors.green, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            suggestion.description,
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 8),
          if (!suggestion.applied)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _applySuggestion(suggestion),
                    icon: Icon(Icons.check, size: 14),
                    label: Text('Apply'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _allSuggestions.remove(suggestion);
                    });
                  },
                  icon: Icon(Icons.close, size: 16),
                  color: Colors.red[300],
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            )
          else
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[500], size: 14),
                const SizedBox(width: 4),
                Text(
                  'Applied • ${_formatTimestamp(suggestion.timestamp)}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 10),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _undoSuggestion(suggestion),
                  child: Text('Undo', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}
