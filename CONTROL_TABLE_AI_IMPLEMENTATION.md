# Control Table AI Implementation

## Overview

The Control Table AI system provides an intelligent assistant for railway signalling control table configuration. It uses OpenAI's GPT-4 to analyze, suggest improvements, and help configure complex railway interlocking rules.

## Architecture

### Left Sidebar (Manual Control)
- **Widget**: `ControlTablePanel` (unchanged)
- **Purpose**: Manual editing of control table
- **Features**:
  - Signal route configuration
  - Point deadlocking and flank protection
  - AB (Approach Block) management
  - Manual rule editing

### Right Sidebar (AI Assistant)
- **Widget**: `AIControlTablePanel` (NEW)
- **Purpose**: AI-powered analysis and assistance
- **Features**:
  - Automatic analysis on load
  - Interactive chat interface
  - Structured suggestions with manual review
  - Batch apply functionality
  - Suggestion history and undo mechanism

## Key Components

### 1. AI Service Layer
**File**: `lib/services/control_table_ai_service.dart`

**Capabilities**:
- Control table analysis and safety validation
- Conflict detection (route conflicts, missing protection, deadlock issues)
- AB configuration suggestions
- Signal rule recommendations
- Point deadlocking/flank protection suggestions
- Interactive chat for questions and guidance

**Key Methods**:
```dart
// Comprehensive control table analysis
Future<ControlTableAnalysis> analyzeControlTable({...})

// Chat interface for user questions
Future<ChatResponse> processChatMessage({...})

// Generate AB suggestions based on layout
Future<List<ABSuggestion>> suggestABConfigurations({...})
```

### 2. AI Control Table Panel UI
**File**: `lib/widgets/ai_control_table_panel.dart`

**Three-Tab Interface**:

#### Tab 1: Analysis
- Auto-analyze button
- Safety issues and conflicts display
- Severity-based color coding (critical/warning/info)
- Affected items visualization
- Suggested fixes

#### Tab 2: Chat
- Interactive chat with AI expert
- Context-aware responses
- Suggestion extraction from conversations
- Example questions provided

#### Tab 3: Suggestions
- Filterable list (all/pending/applied)
- Priority-based organization (high/medium/low)
- Individual apply with preview
- Batch apply all pending
- Undo functionality
- Timestamp tracking

### 3. Data Models

**ControlTableAnalysis**:
```dart
class ControlTableAnalysis {
  final bool success;
  final String summary;
  final List<ConflictReport> conflicts;
  final List<ControlTableSuggestion> suggestions;
}
```

**ConflictReport**:
```dart
class ConflictReport {
  final String type; // route_conflict, missing_protection, etc.
  final String severity; // critical, warning, info
  final String title;
  final String description;
  final List<String> affectedItems;
  final String suggestion;
}
```

**ControlTableSuggestion**:
```dart
class ControlTableSuggestion {
  final String id;
  final String type; // signal_rule, point_rule, ab_config, etc.
  final String title;
  final String description;
  final String priority; // high, medium, low
  final Map<String, dynamic> changes;
  bool applied;
  DateTime timestamp;
}
```

## AI Capabilities

### 1. Safety Analysis
- **Route Conflicts**: Detects routes that could be set simultaneously causing danger
- **Missing Protection**: Identifies signals without adequate approach blocks
- **Deadlock Prevention**: Finds points without proper deadlock blocks
- **Flank Protection**: Validates point locking configurations

### 2. Configuration Suggestions
- **AB Configuration**: Suggests approach blocks based on signal and axle counter placement
- **Signal Rules**: Recommends required blocks, point positions, and conflicting routes
- **Point Rules**: Suggests deadlock blocks and flank protection points
- **Optimization**: Identifies redundant rules and efficiency improvements

### 3. Interactive Assistance
- **Question Answering**: Explains current configuration and signalling concepts
- **Best Practices**: Provides expert railway signalling guidance
- **Troubleshooting**: Helps diagnose conflicts and safety issues
- **Learning**: Teaches proper signalling terminology and concepts

## Configuration

### Environment Setup

1. Create `assets/.env` file (copy from `assets/.env.template`):
```env
OPENAI_API_KEY=your_openai_api_key_here
```

2. The API key is loaded automatically on app startup via `flutter_dotenv`

3. Default model: `gpt-4-turbo-preview` (configurable in service constructor)

### API Key Security
- **Never commit** `assets/.env` to version control
- File should be in `.gitignore`
- Store production keys in secure environment variables
- Use separate keys for development and production

## User Workflow

### Auto-Analysis Mode
1. User opens Control Table mode
2. AI automatically analyzes the current configuration
3. Results displayed immediately in Analysis tab
4. Issues categorized by severity
5. Suggestions available for review

### Interactive Chat Mode
1. User switches to Chat tab
2. Asks questions about configuration
3. AI provides expert guidance with context
4. Can request specific analyses
5. Suggestions extracted and added to review list

### Suggestion Review & Application
1. All suggestions appear in Suggestions tab
2. User can filter by status (all/pending/applied)
3. Each suggestion shows:
   - Priority level (high/medium/low)
   - Description and reasoning
   - Affected components
4. Options:
   - **Apply**: Single suggestion with immediate effect
   - **Apply All**: Batch apply all pending suggestions
   - **Undo**: Revert applied suggestion
   - **Dismiss**: Remove suggestion from list

### Safety Features
- **Manual Review Required**: No auto-application of changes
- **Preview Before Apply**: Clear description of changes
- **Undo Mechanism**: Revert recent changes
- **History Tracking**: All applied suggestions logged with timestamps
- **Conflict Warnings**: Critical issues highlighted prominently

## Example Use Cases

### 1. New Layout Configuration
```
User: Opens new railway layout
AI: Automatically analyzes layout
AI: Suggests initial AB configurations
AI: Identifies missing signal conflicts
User: Reviews and applies suggestions in batch
```

### 2. Safety Validation
```
User: "Review my control table for safety issues"
AI: Performs comprehensive safety analysis
AI: Reports 3 critical route conflicts
AI: Suggests specific conflict markers to add
User: Applies conflict fixes one by one
```

### 3. AB Configuration Help
```
User: "What ABs should I configure for Platform 1?"
AI: Analyzes Platform 1 signals and axle counters
AI: Suggests 2 approach blocks with reasoning
AI: Explains which signals benefit from each AB
User: Applies suggested AB configurations
```

### 4. Learning Mode
```
User: "Why is signal S01 conflicting with S02?"
AI: Explains the conflict based on current routes
AI: Shows which blocks/points overlap
AI: Suggests adding conflict marker or changing routes
User: Better understands the issue
```

## Technical Details

### API Communication
- **Endpoint**: OpenAI Chat Completions API
- **Model**: GPT-4 Turbo (can use GPT-3.5 for cost savings)
- **Temperature**: 0.3 for analysis (consistent), 0.5 for chat (creative)
- **Max Tokens**: 2000-4000 depending on task
- **Timeout**: 20-30 seconds with retry logic

### Context Provided to AI
```
=== SIGNALS AND ROUTES ===
Signal S01 (left):
  Route R1:
    Target: green
    Required Blocks Clear: 100, 101
    Approach Blocks: AB_S01
    Point Positions: P1=normal
    Conflicts: S02_R1

=== POINTS ===
Point P1 (Main Junction):
  Current: normal, Locked: false
  Deadlock Blocks: 100
  Flank Protection: P2=reverse

=== BLOCKS ===
Block 100: CLEAR
Block 101: OCCUPIED

=== AXLE COUNTERS ===
AC_01: count=0
AC_02: count=2

=== APPROACH BLOCKS ===
Signal S01 Approach (AB_S01): AC_01 ↔ AC_02
```

### Performance Considerations
- **API Latency**: 2-10 seconds per request
- **Cost**: ~$0.01-0.03 per analysis (GPT-4)
- **Caching**: Analysis results cached until configuration changes
- **Rate Limits**: Respects OpenAI rate limits with retry logic
- **Offline Mode**: Graceful degradation when API unavailable

## Future Enhancements

### Planned Features
1. **Visual Diff Preview**: Show exact changes before applying
2. **Confidence Scores**: AI confidence level for each suggestion
3. **Learning from Corrections**: Improve suggestions based on user feedback
4. **Multi-Language Support**: Prompts in different languages
5. **Export Analysis Reports**: PDF/JSON export of findings
6. **Historical Comparison**: Compare against previous configurations
7. **Simulation Integration**: Test suggestions in simulation before applying
8. **Voice Interface**: Voice commands and responses
9. **Local Model Option**: Run without cloud API (privacy)
10. **Collaborative Review**: Share suggestions with team

### Optimization Ideas
1. **Incremental Analysis**: Only analyze changed sections
2. **Background Processing**: Analyze during idle time
3. **Suggestion Prioritization**: ML-based priority scoring
4. **Pattern Recognition**: Learn from common configurations
5. **Cost Optimization**: Use GPT-3.5 for simple queries

## Troubleshooting

### API Key Issues
```
Error: "OpenAI API key not found in .env file"
Solution: Create assets/.env with OPENAI_API_KEY=...
```

### Analysis Failures
```
Error: "Analysis failed: timeout"
Solution: Check internet connection, try again
```

### Chat Not Responding
```
Error: "Chat error: rate limit exceeded"
Solution: Wait 30 seconds and try again
```

### Suggestions Not Applying
```
Error: "Failed to apply suggestion: invalid data"
Solution: Check console for details, may need manual intervention
```

## Contributing

When adding new AI capabilities:

1. **Update System Prompts**: Modify prompts in `control_table_ai_service.dart`
2. **Add Data Models**: Create new classes for suggestion types
3. **Implement Apply Logic**: Add handlers in `_applySuggestion()`
4. **Update UI**: Add visual elements for new suggestion types
5. **Test Thoroughly**: Verify with real configurations
6. **Document**: Update this file with new capabilities

## License & Attribution

Built with:
- OpenAI GPT-4 API for intelligent analysis
- Flutter for cross-platform UI
- Provider for state management
- flutter_dotenv for configuration management

---

**Last Updated**: December 25, 2025
**Version**: 1.0.0
**Author**: Signal Champ Development Team
