import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/terminal_station_controller.dart';
import '../screens/terminal_station_models.dart';
import '../theme/design_tokens.dart';
import '../services/widget_preferences_service.dart';
import '../services/speech_recognition_service.dart';

/// Enhanced Search bar widget with voice recognition and customization
class RailwaySearchBarEnhanced extends StatefulWidget {
  final Function(double x, double y)? onNavigate;
  final double? viewportWidth;
  final double? viewportHeight;

  const RailwaySearchBarEnhanced({
    Key? key,
    this.onNavigate,
    this.viewportWidth,
    this.viewportHeight,
  }) : super(key: key);

  @override
  State<RailwaySearchBarEnhanced> createState() => _RailwaySearchBarEnhancedState();
}

class _RailwaySearchBarEnhancedState extends State<RailwaySearchBarEnhanced> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<SearchResult> _searchResults = [];
  bool _showResults = false;
  int _selectedIndex = -1;
  bool _isListeningForWakeWord = false;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query, TerminalStationController controller) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
      return;
    }

    final results = <SearchResult>[];
    final lowerQuery = query.toLowerCase();

    // Search blocks
    for (final block in controller.blocks.values) {
      if (block.id.toLowerCase().contains(lowerQuery) ||
          (block.name?.toLowerCase().contains(lowerQuery) ?? false)) {
        results.add(SearchResult(
          id: block.id,
          name: block.name ?? 'Block ${block.id}',
          type: 'Block',
          x: block.centerX,
          y: block.y,
          icon: Icons.view_column,
          color: block.occupied ? Colors.red : Colors.green,
          subtitle: block.occupied ? 'Occupied' : 'Clear',
        ));
      }
    }

    // Search signals
    for (final signal in controller.signals.values) {
      if (signal.id.toLowerCase().contains(lowerQuery)) {
        results.add(SearchResult(
          id: signal.id,
          name: 'Signal ${signal.id}',
          type: 'Signal',
          x: signal.x,
          y: signal.y,
          icon: Icons.traffic,
          color: signal.aspect == SignalAspect.green ? Colors.green :
                 signal.aspect == SignalAspect.blue ? Colors.blue : Colors.red,
          subtitle: signal.aspect.name.toUpperCase(),
        ));
      }
    }

    // Search points/tracks
    for (final point in controller.points.values) {
      if (point.id.toLowerCase().contains(lowerQuery)) {
        results.add(SearchResult(
          id: point.id,
          name: 'Point ${point.id}',
          type: 'Point',
          x: point.x,
          y: point.y,
          icon: Icons.alt_route,
          color: point.locked ? Colors.red : Colors.orange,
          subtitle: '${point.position.name.toUpperCase()}${point.locked ? ' (Locked)' : ''}',
        ));
      }
    }

    // Search stations/platforms
    for (final platform in controller.platforms) {
      if (platform.id.toLowerCase().contains(lowerQuery) ||
          platform.name.toLowerCase().contains(lowerQuery)) {
        results.add(SearchResult(
          id: platform.id,
          name: platform.name,
          type: 'Platform',
          x: platform.centerX,
          y: platform.y,
          icon: Icons.subway,
          color: platform.occupied ? Colors.purple : Colors.blue,
          subtitle: platform.occupied ? 'Train at platform' : 'Empty',
        ));
      }
    }

    // Search axle counters
    for (final counter in controller.axleCounters.values) {
      if (counter.id.toLowerCase().contains(lowerQuery) ||
          counter.blockId.toLowerCase().contains(lowerQuery)) {
        results.add(SearchResult(
          id: counter.id,
          name: counter.id.toUpperCase(),
          type: 'Axle Counter',
          x: counter.x,
          y: counter.y,
          icon: Icons.speed,
          color: counter.count > 0 ? Colors.amber : Colors.grey,
          subtitle: 'Count: ${counter.count}',
        ));
      }
    }

    // Search trains
    for (final train in controller.trains) {
      if (train.id.toLowerCase().contains(lowerQuery) ||
          train.name.toLowerCase().contains(lowerQuery) ||
          train.vin.toLowerCase().contains(lowerQuery)) {
        results.add(SearchResult(
          id: train.id,
          name: '${train.name} (VIN: ${train.vin})',
          type: 'Train',
          x: train.x,
          y: train.y,
          icon: Icons.train,
          color: train.color,
          subtitle: '${train.trainType.name.toUpperCase()} - ${train.controlMode.name} mode',
        ));
      }
    }

    // Search crossovers (special named blocks)
    final crossoverBlocks = controller.blocks.values.where(
      (block) => block.name != null && block.name!.toLowerCase().contains('crossover')
    );
    for (final block in crossoverBlocks) {
      if (lowerQuery.contains('cross') || block.name!.toLowerCase().contains(lowerQuery)) {
        if (!results.any((r) => r.id == block.id)) {
          results.add(SearchResult(
            id: block.id,
            name: block.name!,
            type: 'Crossover',
            x: block.centerX,
            y: block.y,
            icon: Icons.compare_arrows,
            color: Colors.cyan,
            subtitle: block.occupied ? 'Occupied' : 'Clear',
          ));
        }
      }
    }

    // Search transponders/tags
    for (final transponder in controller.transponders.values) {
      if (transponder.id.toLowerCase().contains(lowerQuery)) {
        results.add(SearchResult(
          id: transponder.id,
          name: transponder.id.toUpperCase(),
          type: 'Transponder',
          x: transponder.x,
          y: transponder.y,
          icon: Icons.sensors,
          color: Colors.indigo,
          subtitle: transponder.type.toString().split('.').last,
        ));
      }
    }

    setState(() {
      _searchResults = results;
      _showResults = results.isNotEmpty;
      _selectedIndex = results.isNotEmpty ? 0 : -1;
    });
  }

  void _selectResult(SearchResult result, TerminalStationController controller) {
    // Navigate to the item with smooth animation, centering it in viewport
    controller.panToPosition(
      result.x,
      result.y,
      zoom: 1.5,
      viewportWidth: widget.viewportWidth,
      viewportHeight: widget.viewportHeight,
    );
    controller.highlightItem(result.id, result.type.toLowerCase());

    // Show thumbnail tooltip
    _showThumbnail(result);

    // Close search results
    setState(() {
      _showResults = false;
      _searchController.clear();
    });

    _focusNode.unfocus();
  }

  void _showThumbnail(SearchResult result) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 80,
        right: 340,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: result.color, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(result.icon, color: result.color, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      result.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  result.type,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                Text(
                  result.subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Position: (${result.x.toInt()}, ${result.y.toInt()})',
                  style: TextStyle(color: Colors.grey[500], fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  /// Start voice search
  Future<void> _startVoiceSearch(
    SpeechRecognitionService speechService,
    TerminalStationController controller,
    WidgetPreferencesService prefs,
  ) async {
    if (!prefs.voiceEnabled) {
      _showSnackBar('Voice search is disabled in settings');
      return;
    }

    if (!speechService.isAvailable) {
      final initialized = await speechService.initialize();
      if (!initialized) {
        _showSnackBar('Speech recognition not available');
        return;
      }
    }

    await speechService.startListening(
      onResult: (text) {
        setState(() {
          _searchController.text = text;
        });
        _performSearch(text, controller);
      },
    );
  }

  /// Start wake word listening
  Future<void> _toggleWakeWordListening(
    SpeechRecognitionService speechService,
    TerminalStationController controller,
    WidgetPreferencesService prefs,
  ) async {
    if (!prefs.searchWakeWordEnabled) {
      _showSnackBar('"Search for" wake word is disabled in settings');
      return;
    }

    if (!speechService.isAvailable) {
      final initialized = await speechService.initialize();
      if (!initialized) {
        _showSnackBar('Speech recognition not available');
        return;
      }
    }

    if (_isListeningForWakeWord) {
      await speechService.stopListening();
      setState(() {
        _isListeningForWakeWord = false;
      });
    } else {
      await speechService.startWakeWordListening(
        onWakeWordDetected: (wakeWord) async {
          if (wakeWord.contains('search')) {
            // Stop wake word listening and start search listening
            setState(() {
              _isListeningForWakeWord = false;
            });
            await _startVoiceSearch(speechService, controller, prefs);
          }
        },
      );
      setState(() {
        _isListeningForWakeWord = true;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer3<TerminalStationController, WidgetPreferencesService, SpeechRecognitionService>(
      builder: (context, controller, prefs, speechService, _) {
        return Container(
          padding: AppSpacing.compactPadding,
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.grey900,
                      AppColors.grey850,
                    ],
                  )
                : null,
            color: isDark ? null : theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.grey700 : theme.dividerColor,
                width: 1,
              ),
            ),
            boxShadow: AppElevation.getShadow(AppElevation.level2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search input with modern design and voice button
              TextField(
                controller: _searchController,
                focusNode: _focusNode,
                style: AppTypography.body.copyWith(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: prefs.searchBarTextSize,
                ),
                decoration: InputDecoration(
                  hintText: 'Search railway elements...',
                  hintStyle: AppTypography.body.copyWith(
                    color: isDark ? AppColors.grey500 : Colors.grey[600],
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: prefs.searchBarColor,
                    size: AppIconSize.sm,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Voice search button
                      if (prefs.voiceEnabled)
                        IconButton(
                          icon: Icon(
                            speechService.isListening
                                ? Icons.mic
                                : Icons.mic_none,
                            color: speechService.isListening
                                ? Colors.red
                                : prefs.searchBarColor,
                            size: AppIconSize.sm,
                          ),
                          onPressed: () => _startVoiceSearch(
                            speechService,
                            controller,
                            prefs,
                          ),
                          tooltip: 'Voice search',
                        ),
                      // Wake word toggle button
                      if (prefs.searchWakeWordEnabled)
                        IconButton(
                          icon: Icon(
                            _isListeningForWakeWord
                                ? Icons.hearing
                                : Icons.hearing_disabled,
                            color: _isListeningForWakeWord
                                ? Colors.green
                                : Colors.grey,
                            size: AppIconSize.sm,
                          ),
                          onPressed: () => _toggleWakeWordListening(
                            speechService,
                            controller,
                            prefs,
                          ),
                          tooltip: _isListeningForWakeWord
                              ? '"Search for" wake word active'
                              : 'Enable "search for" wake word',
                        ),
                      // Clear button
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: isDark ? AppColors.grey400 : Colors.grey[700],
                            size: AppIconSize.sm,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('', controller);
                          },
                          tooltip: 'Clear search',
                        ),
                    ],
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.grey800 : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: AppBorderRadius.medium,
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppBorderRadius.medium,
                    borderSide: BorderSide(
                      color: prefs.searchBarColor,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
                onChanged: (value) => _performSearch(value, controller),
                onSubmitted: (value) {
                  if (_searchResults.isNotEmpty && _selectedIndex >= 0) {
                    _selectResult(_searchResults[_selectedIndex], controller);
                  }
                },
              ),

              // Voice status indicator
              if (speechService.isListening || _isListeningForWakeWord)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isListeningForWakeWord ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isListeningForWakeWord
                            ? 'Listening for "search for..."'
                            : 'Listening...',
                        style: TextStyle(
                          fontSize: 10,
                          color: _isListeningForWakeWord ? Colors.green : Colors.red,
                        ),
                      ),
                      if (speechService.lastWords.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '"${speechService.lastWords}"',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[400],
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              // Search results dropdown with modern styling
              if (_showResults && _searchResults.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(top: AppSpacing.sm),
                  constraints: const BoxConstraints(maxHeight: 350),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.grey850 : Colors.white,
                    borderRadius: AppBorderRadius.medium,
                    border: Border.all(
                      color: isDark ? AppColors.grey700 : Colors.grey[300]!,
                    ),
                    boxShadow: AppElevation.getShadow(AppElevation.level4),
                  ),
                  child: ClipRRect(
                    borderRadius: AppBorderRadius.medium,
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: isDark ? AppColors.grey800 : Colors.grey[200],
                      ),
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        final isSelected = index == _selectedIndex;

                        return Material(
                          color: isSelected
                              ? prefs.searchBarColor.withOpacity(0.15)
                              : Colors.transparent,
                          child: InkWell(
                            onTap: () => _selectResult(result, controller),
                            onHover: (hovering) {
                              if (hovering) {
                                setState(() => _selectedIndex = index);
                              }
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              child: Row(
                                children: [
                                  // Icon with colored background
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: result.color.withOpacity(0.15),
                                      borderRadius: AppBorderRadius.small,
                                    ),
                                    child: Icon(
                                      result.icon,
                                      color: result.color,
                                      size: AppIconSize.sm,
                                    ),
                                  ),
                                  SizedBox(width: AppSpacing.md),

                                  // Text content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          result.name,
                                          style: AppTypography.body.copyWith(
                                            color: isDark ? Colors.white : Colors.black87,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: AppSpacing.xs / 2),
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: AppSpacing.sm,
                                                vertical: AppSpacing.xs / 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: result.color.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(
                                                  AppBorderRadius.xs,
                                                ),
                                              ),
                                              child: Text(
                                                result.type,
                                                style: AppTypography.captionSmall.copyWith(
                                                  color: result.color,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: AppSpacing.sm),
                                            Expanded(
                                              child: Text(
                                                result.subtitle,
                                                style: AppTypography.caption.copyWith(
                                                  color: isDark
                                                      ? AppColors.grey400
                                                      : Colors.grey[600],
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Position coordinates
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.grey800
                                          : Colors.grey[100],
                                      borderRadius: AppBorderRadius.small,
                                    ),
                                    child: Text(
                                      '${result.x.toInt()}, ${result.y.toInt()}',
                                      style: AppTypography.captionSmall.copyWith(
                                        color: isDark
                                            ? AppColors.grey500
                                            : Colors.grey[700],
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class SearchResult {
  final String id;
  final String name;
  final String type;
  final double x;
  final double y;
  final IconData icon;
  final Color color;
  final String subtitle;

  SearchResult({
    required this.id,
    required this.name,
    required this.type,
    required this.x,
    required this.y,
    required this.icon,
    required this.color,
    required this.subtitle,
  });
}
