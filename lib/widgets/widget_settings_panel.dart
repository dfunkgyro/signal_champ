import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/widget_preferences_service.dart';
import '../services/speech_recognition_service.dart';
import '../services/text_to_speech_service.dart';

/// Comprehensive widget customization settings panel
class WidgetSettingsPanel extends StatefulWidget {
  const WidgetSettingsPanel({Key? key}) : super(key: key);

  @override
  State<WidgetSettingsPanel> createState() => _WidgetSettingsPanelState();
}

class _WidgetSettingsPanelState extends State<WidgetSettingsPanel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefsService = Provider.of<WidgetPreferencesService>(context);
    final ttsService = Provider.of<TextToSpeechService>(context);
    final speechService = Provider.of<SpeechRecognitionService>(context);

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 700,
        height: 800,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E1E1E),
              const Color(0xFF2A2A2A),
            ],
          ),
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(context, prefsService),

            // Content
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Minimap Settings
                      _buildMinimapSettings(prefsService),
                      const SizedBox(height: 32),

                      // Search Widget Settings
                      _buildSearchWidgetSettings(prefsService),
                      const SizedBox(height: 32),

                      // Auto-Pan Settings
                      _buildAutoPanSettings(prefsService),
                      const SizedBox(height: 32),

                      // AI Agent Settings
                      _buildAiAgentSettings(prefsService),
                      const SizedBox(height: 32),

                      // Voice Settings
                      _buildVoiceSettings(prefsService, ttsService, speechService),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Footer with action buttons
            _buildFooter(context, prefsService),
          ],
        ),
      ),
    );
  }

  /// Build header with title and close button
  Widget _buildHeader(BuildContext context, WidgetPreferencesService prefsService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.settings,
            color: Colors.orange,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text(
            'Widget Customization Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  /// Build minimap settings section
  Widget _buildMinimapSettings(WidgetPreferencesService prefsService) {
    return _buildSection(
      icon: Icons.map,
      title: 'Minimap Settings',
      children: [
        // Width slider
        _buildSlider(
          label: 'Width',
          value: prefsService.minimapWidth,
          min: 200,
          max: 400,
          divisions: 40,
          onChanged: (value) => prefsService.setMinimapWidth(value),
        ),

        // Height slider
        _buildSlider(
          label: 'Height',
          value: prefsService.minimapHeight,
          min: 100,
          max: 200,
          divisions: 20,
          onChanged: (value) => prefsService.setMinimapHeight(value),
        ),

        // Border width slider
        _buildSlider(
          label: 'Border Width',
          value: prefsService.minimapBorderWidth,
          min: 1,
          max: 5,
          divisions: 8,
          onChanged: (value) => prefsService.setMinimapBorderWidth(value),
        ),

        const SizedBox(height: 16),

        // Border color picker
        _buildColorPicker(
          label: 'Border Color',
          currentColor: prefsService.minimapBorderColor,
          onColorSelected: (color) => prefsService.setMinimapBorderColor(color),
        ),

        const SizedBox(height: 12),

        // Header color picker
        _buildColorPicker(
          label: 'Header Color',
          currentColor: prefsService.minimapHeaderColor,
          onColorSelected: (color) => prefsService.setMinimapHeaderColor(color),
        ),

        const SizedBox(height: 12),

        // Background color picker
        _buildColorPicker(
          label: 'Background Color',
          currentColor: prefsService.minimapBackgroundColor,
          onColorSelected: (color) => prefsService.setMinimapBackgroundColor(color),
          includeCustom: true,
        ),
      ],
    );
  }

  /// Build search widget settings section
  Widget _buildSearchWidgetSettings(WidgetPreferencesService prefsService) {
    return _buildSection(
      icon: Icons.search,
      title: 'Search Widget Settings',
      children: [
        // Height slider
        _buildSlider(
          label: 'Height',
          value: prefsService.searchBarHeight,
          min: 40,
          max: 80,
          divisions: 8,
          onChanged: (value) => prefsService.setSearchBarHeight(value),
        ),

        // Text size slider
        _buildSlider(
          label: 'Text Size',
          value: prefsService.searchBarTextSize,
          min: 12,
          max: 18,
          divisions: 12,
          onChanged: (value) => prefsService.setSearchBarTextSize(value),
        ),

        const SizedBox(height: 16),

        // Accent color picker
        _buildColorPicker(
          label: 'Accent Color',
          currentColor: prefsService.searchBarColor,
          onColorSelected: (color) => prefsService.setSearchBarColor(color),
        ),
      ],
    );
  }

  /// Build AI agent settings section
  Widget _buildAiAgentSettings(WidgetPreferencesService prefsService) {
    return _buildSection(
      icon: Icons.smart_toy,
      title: 'AI Agent Settings',
      children: [
        // Collapsed size section
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            'Collapsed Size',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _buildSlider(
          label: 'Width',
          value: prefsService.aiAgentWidth,
          min: 200,
          max: 400,
          divisions: 40,
          onChanged: (value) => prefsService.setAiAgentWidth(value),
        ),
        _buildSlider(
          label: 'Height',
          value: prefsService.aiAgentHeight,
          min: 60,
          max: 120,
          divisions: 12,
          onChanged: (value) => prefsService.setAiAgentHeight(value),
        ),

        const SizedBox(height: 16),

        // Expanded size section
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            'Expanded Size',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _buildSlider(
          label: 'Width',
          value: prefsService.aiAgentExpandedWidth,
          min: 300,
          max: 600,
          divisions: 30,
          onChanged: (value) => prefsService.setAiAgentExpandedWidth(value),
        ),
        _buildSlider(
          label: 'Height',
          value: prefsService.aiAgentExpandedHeight,
          min: 400,
          max: 700,
          divisions: 30,
          onChanged: (value) => prefsService.setAiAgentExpandedHeight(value),
        ),

        const SizedBox(height: 16),

        // Gradient color picker
        _buildColorPicker(
          label: 'Gradient Color',
          currentColor: prefsService.aiAgentColor,
          onColorSelected: (color) => prefsService.setAiAgentColor(color),
        ),
      ],
    );
  }

  /// Build auto-pan settings section
  Widget _buildAutoPanSettings(WidgetPreferencesService prefsService) {
    return _buildSection(
      icon: Icons.my_location,
      title: 'Auto-Pan Settings',
      children: [
        Text(
          'Apply an offset after auto-centering.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        _buildSlider(
          label: 'X Offset',
          value: prefsService.autoPanOffsetX,
          min: -1000,
          max: 1000,
          divisions: 200,
          onChanged: (value) => prefsService.setAutoPanOffsetX(value),
        ),
        _buildSlider(
          label: 'Y Offset',
          value: prefsService.autoPanOffsetY,
          min: -1000,
          max: 1000,
          divisions: 200,
          onChanged: (value) => prefsService.setAutoPanOffsetY(value),
        ),
      ],
    );
  }

  /// Build voice settings section
  Widget _buildVoiceSettings(
    WidgetPreferencesService prefsService,
    TextToSpeechService ttsService,
    SpeechRecognitionService speechService,
  ) {
    return _buildSection(
      icon: Icons.mic,
      title: 'Voice Settings',
      children: [
        // Voice enabled toggle
        _buildToggle(
          label: 'Voice Input Enabled',
          value: prefsService.voiceEnabled,
          onChanged: (value) => prefsService.setVoiceEnabled(value),
        ),

        const SizedBox(height: 12),

        // TTS enabled toggle
        _buildToggle(
          label: 'Text-to-Speech Enabled',
          value: prefsService.ttsEnabled,
          onChanged: (value) => prefsService.setTtsEnabled(value),
        ),

        const SizedBox(height: 12),

        // Search wake word toggle
        _buildToggle(
          label: '"Search for" Wake Word',
          value: prefsService.searchWakeWordEnabled,
          onChanged: (value) => prefsService.setSearchWakeWordEnabled(value),
          subtitle: 'Say "search for" to activate search bar',
        ),

        const SizedBox(height: 12),

        // SSM wake word toggle
        _buildToggle(
          label: '"SSM" Wake Word',
          value: prefsService.ssmWakeWordEnabled,
          onChanged: (value) => prefsService.setSsmWakeWordEnabled(value),
          subtitle: 'Say "SSM" to activate AI agent',
        ),

        const SizedBox(height: 16),

        // Language dropdown
        _buildLanguageDropdown(prefsService),

        const SizedBox(height: 16),

        // Speech rate slider
        _buildSlider(
          label: 'Speech Rate',
          value: prefsService.speechRate,
          min: 0.5,
          max: 2.0,
          divisions: 15,
          onChanged: (value) {
            prefsService.setSpeechRate(value);
            // Also update TTS service if available
            if (ttsService.isAvailable) {
              ttsService.setSpeechRate(value);
            }
          },
        ),

        // Voice pitch slider
        _buildSlider(
          label: 'Voice Pitch',
          value: prefsService.voicePitch,
          min: 0.5,
          max: 2.0,
          divisions: 15,
          onChanged: (value) {
            prefsService.setVoicePitch(value);
            // Also update TTS service if available
            if (ttsService.isAvailable) {
              ttsService.setPitch(value);
            }
          },
        ),

        const SizedBox(height: 16),

        // Test speech button
        Center(
          child: ElevatedButton.icon(
            onPressed: ttsService.isAvailable && prefsService.ttsEnabled
                ? () async {
                    await ttsService.testSpeak();
                  }
                : null,
            icon: const Icon(Icons.volume_up),
            label: const Text('Test Speech'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build footer with action buttons
  Widget _buildFooter(BuildContext context, WidgetPreferencesService prefsService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Reset to defaults button
          TextButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF2A2A2A),
                  title: const Text(
                    'Reset to Defaults',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'Are you sure you want to reset all settings to their default values?',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await prefsService.resetToDefaults();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Settings reset to defaults'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.refresh, color: Colors.orange),
            label: const Text(
              'Reset to Defaults',
              style: TextStyle(color: Colors.orange),
            ),
          ),

          // Close button
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Build a section with header and children
  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Icon(
                icon,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  /// Build a slider control
  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.orange,
            inactiveTrackColor: Colors.orange.withOpacity(0.3),
            thumbColor: Colors.orange,
            overlayColor: Colors.orange.withOpacity(0.2),
            valueIndicatorColor: Colors.orange,
            valueIndicatorTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: value.toStringAsFixed(1),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  /// Build a color picker with presets
  Widget _buildColorPicker({
    required String label,
    required Color currentColor,
    required ValueChanged<Color> onColorSelected,
    bool includeCustom = false,
  }) {
    final presets = WidgetPreferencesService.getColorPresets();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...presets.map((preset) {
              final color = preset['color'] as Color;
              final isSelected = color.value == currentColor.value;

              return InkWell(
                onTap: () => onColorSelected(color),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 50,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        )
                      : null,
                ),
              );
            }),
            if (includeCustom)
              InkWell(
                onTap: () {
                  // Custom color picker could be added here
                  // For now, we'll show a simple dark/light toggle
                  final isDark = currentColor.computeLuminance() < 0.5;
                  onColorSelected(
                    isDark ? const Color(0xFFEEEEEE) : const Color(0xFF212121),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 50,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black, Colors.white],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.palette,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Build a toggle switch
  Widget _buildToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? Colors.orange.withOpacity(0.5) : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.orange,
            activeTrackColor: Colors.orange.withOpacity(0.5),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  /// Build language dropdown
  Widget _buildLanguageDropdown(WidgetPreferencesService prefsService) {
    final languages = [
      {'code': 'en-US', 'name': 'English (US)'},
      {'code': 'en-GB', 'name': 'English (UK)'},
      {'code': 'es-ES', 'name': 'Spanish'},
      {'code': 'fr-FR', 'name': 'French'},
      {'code': 'de-DE', 'name': 'German'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Language',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.orange.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: prefsService.voiceLanguage,
              isExpanded: true,
              dropdownColor: const Color(0xFF2A2A2A),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.orange),
              items: languages.map((lang) {
                return DropdownMenuItem<String>(
                  value: lang['code'],
                  child: Row(
                    children: [
                      const Icon(
                        Icons.language,
                        color: Colors.orange,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(lang['name']!),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  prefsService.setVoiceLanguage(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
