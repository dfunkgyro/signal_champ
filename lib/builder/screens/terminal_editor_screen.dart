import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4, Vector3;
import 'package:provider/provider.dart';

import 'package:rail_champ/models/layout_configuration.dart';
import '../models/terminal_editor_models.dart';
import '../providers/supabase_status_provider.dart';
import '../providers/terminal_editor_provider.dart';
import '../services/openai_agent_service.dart';
import '../services/openai_terminal_agent_service.dart';
import '../services/supabase_service.dart';
import '../widgets/terminal_editor_canvas.dart';

class TerminalEditorScreen extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>>? onApplyLayout;

  const TerminalEditorScreen({super.key, this.onApplyLayout});

  @override
  State<TerminalEditorScreen> createState() => _TerminalEditorScreenState();
}

class _TerminalEditorScreenState extends State<TerminalEditorScreen> {
  final TransformationController _controller = TransformationController();
  final GlobalKey _toolbarKey = GlobalKey();
  bool _showLeftPanel = true;
  bool _showRightPanel = true;
  Size _canvasSize = const Size(6000, 4000);
  final List<LayoutConfiguration> _layoutOptions = PredefinedLayouts.getAll();
  String _selectedLayoutId = 'default_full_terminal';

  static const double _leftPanelWidth = 230;
  static const double _rightPanelWidth = 260;
  double _topBarHeight = 56;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateToolbarHeight();
    });
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.tab): _NextIntent(),
        SingleActivator(LogicalKeyboardKey.tab, shift: true): _PrevIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, control: true): _UndoIntent(),
        SingleActivator(LogicalKeyboardKey.keyY, control: true): _RedoIntent(),
        SingleActivator(LogicalKeyboardKey.arrowUp): _NudgeIntent(Offset(0, -5)),
        SingleActivator(LogicalKeyboardKey.arrowDown): _NudgeIntent(Offset(0, 5)),
        SingleActivator(LogicalKeyboardKey.arrowLeft): _NudgeIntent(Offset(-5, 0)),
        SingleActivator(LogicalKeyboardKey.arrowRight): _NudgeIntent(Offset(5, 0)),
        SingleActivator(LogicalKeyboardKey.arrowUp, shift: true):
            _NudgeIntent(Offset(0, -20)),
        SingleActivator(LogicalKeyboardKey.arrowDown, shift: true):
            _NudgeIntent(Offset(0, 20)),
        SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true):
            _NudgeIntent(Offset(-20, 0)),
        SingleActivator(LogicalKeyboardKey.arrowRight, shift: true):
            _NudgeIntent(Offset(20, 0)),
      },
      child: Actions(
        actions: {
          _NextIntent: CallbackAction<_NextIntent>(
            onInvoke: (_) =>
                context.read<TerminalEditorProvider>().selectNext(forward: true),
          ),
          _PrevIntent: CallbackAction<_PrevIntent>(
            onInvoke: (_) =>
                context.read<TerminalEditorProvider>().selectNext(forward: false),
          ),
          _UndoIntent: CallbackAction<_UndoIntent>(
            onInvoke: (_) => context.read<TerminalEditorProvider>().undo(),
          ),
          _RedoIntent: CallbackAction<_RedoIntent>(
            onInvoke: (_) => context.read<TerminalEditorProvider>().redo(),
          ),
          _NudgeIntent: CallbackAction<_NudgeIntent>(
            onInvoke: (intent) =>
                context.read<TerminalEditorProvider>().nudgeSelection(intent.delta),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: Column(
              children: [
                _EditorToolbar(
                  key: _toolbarKey,
                  controller: _controller,
                  showLeftPanel: _showLeftPanel,
                  showRightPanel: _showRightPanel,
                  onToggleLeftPanel: () {
                    setState(() {
                      _showLeftPanel = !_showLeftPanel;
                    });
                  },
                  onToggleRightPanel: () {
                    setState(() {
                      _showRightPanel = !_showRightPanel;
                    });
                  },
                  onLoadTerminalStation: () {
                    context.read<TerminalEditorProvider>().loadTerminalStationLayout();
                    setState(() {
                      _canvasSize = const Size(7000, 1200);
                    });
                  },
                  layoutOptions: _layoutOptions,
                  selectedLayoutId: _selectedLayoutId,
                  onLayoutSelected: (layoutId) {
                    final layout = _layoutOptions.firstWhere(
                      (option) => option.id == layoutId,
                      orElse: () => _layoutOptions.first,
                    );
                    context
                        .read<TerminalEditorProvider>()
                        .loadSimulationLayoutConfiguration(layout);
                    setState(() {
                      _selectedLayoutId = layoutId;
                      _canvasSize = layoutId == 'default_full_terminal'
                          ? const Size(7000, 1200)
                          : const Size(6000, 4000);
                    });
                  },
                  renderStyle:
                      context.watch<TerminalEditorProvider>().renderStyle,
                  onRenderStyleChanged: (style) {
                    context.read<TerminalEditorProvider>().updateRenderStyle(style);
                  },
                  backgroundColor:
                      context.watch<TerminalEditorProvider>().backgroundColor,
                  onBackgroundColorChanged: (color) {
                    context
                        .read<TerminalEditorProvider>()
                        .updateBackgroundColor(color);
                  },
                  gridVisible:
                      context.watch<TerminalEditorProvider>().gridVisible,
                  onToggleGridVisible: () {
                    context.read<TerminalEditorProvider>().toggleGridVisible();
                  },
                  compassVisible:
                      context.watch<TerminalEditorProvider>().compassVisible,
                  onToggleCompassVisible: () {
                    context.read<TerminalEditorProvider>().toggleCompassVisible();
                  },
                  guidewayVisible: context
                      .watch<TerminalEditorProvider>()
                      .guidewayDirectionsVisible,
                  onToggleGuidewayVisible: () {
                    context
                        .read<TerminalEditorProvider>()
                        .toggleGuidewayDirectionsVisible();
                  },
                  alphaGammaVisible: context
                      .watch<TerminalEditorProvider>()
                      .alphaGammaVisible,
                  onToggleAlphaGammaVisible: () {
                    context
                        .read<TerminalEditorProvider>()
                        .toggleAlphaGammaVisible();
                  },
                  onValidateLayout: () {
                    showDialog<void>(
                      context: context,
                      builder: (context) => _ValidationDialog(
                        provider: context.read<TerminalEditorProvider>(),
                      ),
                    );
                  },
                  onApplyLayout: widget.onApplyLayout,
                ),
                Expanded(
                  child: Row(
                    children: [
                      if (_showLeftPanel) const _ToolPalette(),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final viewSize = Size(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            );
                            return Stack(
                              children: [
                                TerminalEditorCanvas(
                                  controller: _controller,
                                  canvasSize: _canvasSize,
                                ),
                                Positioned(
                                  left: 24,
                                  right: 40,
                                  bottom: 6,
                                  child: _AxisScrollBar(
                                    axis: Axis.horizontal,
                                    controller: _controller,
                                    viewSize: viewSize,
                                    canvasSize: _canvasSize,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      if (_showRightPanel)
                        _PropertiesPanel(
                          controller: _controller,
                          canvasSize: _canvasSize,
                          onCanvasSizeChanged: (size) {
                            setState(() {
                              _canvasSize = size;
                            });
                          },
                          leftPanelWidth:
                              _showLeftPanel ? _leftPanelWidth : 0,
                          rightPanelWidth:
                              _showRightPanel ? _rightPanelWidth : 0,
                          topBarHeight: _topBarHeight,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateToolbarHeight() {
    final context = _toolbarKey.currentContext;
    if (context == null) return;
    final box = context.findRenderObject();
    if (box is! RenderBox) return;
    final height = box.size.height;
    if ((height - _topBarHeight).abs() < 0.5) return;
    setState(() {
      _topBarHeight = height;
    });
  }
}

class _NextIntent extends Intent {
  const _NextIntent();
}

class _PrevIntent extends Intent {
  const _PrevIntent();
}

class _UndoIntent extends Intent {
  const _UndoIntent();
}

class _RedoIntent extends Intent {
  const _RedoIntent();
}

class _NudgeIntent extends Intent {
  final Offset delta;

  const _NudgeIntent(this.delta);
}

class _EditorToolbar extends StatelessWidget {
  final TransformationController controller;
  final bool showLeftPanel;
  final bool showRightPanel;
  final VoidCallback onToggleLeftPanel;
  final VoidCallback onToggleRightPanel;
  final VoidCallback onLoadTerminalStation;
  final List<LayoutConfiguration> layoutOptions;
  final String selectedLayoutId;
  final ValueChanged<String> onLayoutSelected;
  final BuilderRenderStyle renderStyle;
  final ValueChanged<BuilderRenderStyle> onRenderStyleChanged;
  final Color backgroundColor;
  final ValueChanged<Color> onBackgroundColorChanged;
  final bool gridVisible;
  final VoidCallback onToggleGridVisible;
  final bool compassVisible;
  final VoidCallback onToggleCompassVisible;
  final bool guidewayVisible;
  final VoidCallback onToggleGuidewayVisible;
  final bool alphaGammaVisible;
  final VoidCallback onToggleAlphaGammaVisible;
  final VoidCallback onValidateLayout;
  final ValueChanged<Map<String, dynamic>>? onApplyLayout;

  const _EditorToolbar({
    super.key,
    required this.controller,
    required this.showLeftPanel,
    required this.showRightPanel,
    required this.onToggleLeftPanel,
    required this.onToggleRightPanel,
    required this.onLoadTerminalStation,
    required this.layoutOptions,
    required this.selectedLayoutId,
    required this.onLayoutSelected,
    required this.renderStyle,
    required this.onRenderStyleChanged,
    required this.backgroundColor,
    required this.onBackgroundColorChanged,
    required this.gridVisible,
    required this.onToggleGridVisible,
    required this.compassVisible,
    required this.onToggleCompassVisible,
    required this.guidewayVisible,
    required this.onToggleGuidewayVisible,
    required this.alphaGammaVisible,
    required this.onToggleAlphaGammaVisible,
    required this.onValidateLayout,
    this.onApplyLayout,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TerminalEditorProvider>(context);

    Future<void> exportXml() async {
      const typeGroup = XTypeGroup(
        label: 'XML',
        extensions: ['xml'],
      );
      final location = await getSaveLocation(
        acceptedTypeGroups: [typeGroup],
        suggestedName: 'terminal_station_layout.xml',
      );
      if (location == null) return;
      final path = location.path;
      final xmlContent = provider.exportXml();
      final file = File(path);
      await file.writeAsString(xmlContent);
    }

    Future<void> importXml() async {
      const typeGroup = XTypeGroup(
        label: 'XML',
        extensions: ['xml'],
      );
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return;
      final content = await file.readAsString();
      provider.importXml(content);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1D3557),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            'Terminal Station Layout Editor',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip:
                showLeftPanel ? 'Hide Tool Palette' : 'Show Tool Palette',
            onPressed: onToggleLeftPanel,
            icon: Icon(
              showLeftPanel ? Icons.view_sidebar : Icons.view_sidebar_outlined,
              color: Colors.white,
            ),
          ),
          IconButton(
            tooltip: showRightPanel
                ? 'Hide Properties Panel'
                : 'Show Properties Panel',
            onPressed: onToggleRightPanel,
            icon: Icon(
              showRightPanel
                  ? Icons.view_sidebar
                  : Icons.view_sidebar_outlined,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: provider.panMode ? 'Pan Mode On' : 'Pan Mode Off',
            onPressed: provider.togglePanMode,
            icon: Icon(
              provider.panMode ? Icons.pan_tool : Icons.pan_tool_outlined,
              color: Colors.white,
            ),
          ),
          IconButton(
            tooltip: gridVisible ? 'Hide Grid' : 'Show Grid',
            onPressed: onToggleGridVisible,
            icon: Icon(
              gridVisible ? Icons.grid_on : Icons.grid_off,
              color: Colors.white,
            ),
          ),
          IconButton(
            tooltip: guidewayVisible ? 'Hide Guideway' : 'Show Guideway',
            onPressed: onToggleGuidewayVisible,
            icon: Icon(
              guidewayVisible ? Icons.route : Icons.route_outlined,
              color: Colors.white,
            ),
          ),
          IconButton(
            tooltip:
                alphaGammaVisible ? 'Hide Alpha/Gamma' : 'Show Alpha/Gamma',
            onPressed: onToggleAlphaGammaVisible,
            icon: Icon(
              alphaGammaVisible ? Icons.hub : Icons.hub_outlined,
              color: Colors.white,
            ),
          ),
          IconButton(
            tooltip: compassVisible ? 'Hide Compass' : 'Show Compass',
            onPressed: onToggleCompassVisible,
            icon: Icon(
              compassVisible
                  ? Icons.explore
                  : Icons.explore_outlined,
              color: Colors.white,
            ),
          ),
          IconButton(
            tooltip: 'Canvas Background',
            onPressed: () async {
              final picked = await showDialog<Color>(
                context: context,
                builder: (context) =>
                    _ColorPickerDialog(initial: backgroundColor),
              );
              if (picked != null) {
                onBackgroundColorChanged(picked);
              }
            },
            icon: const Icon(Icons.palette, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Validate Layout',
            onPressed: onValidateLayout,
            icon: const Icon(Icons.fact_check, color: Colors.white),
          ),
          TextButton.icon(
            onPressed: importXml,
            icon: const Icon(Icons.file_open, color: Colors.white),
            label: const Text('Import XML',
                style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onLoadTerminalStation,
            icon: const Icon(Icons.train, color: Colors.white),
            label: const Text('Load Terminal Layout',
                style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2A3C63),
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedLayoutId,
                dropdownColor: const Color(0xFF1D3557),
                iconEnabledColor: Colors.white,
                onChanged: (value) {
                  if (value != null) {
                    onLayoutSelected(value);
                  }
                },
                items: layoutOptions
                    .map((layout) => DropdownMenuItem<String>(
                          value: layout.id,
                          child: Text(
                            layout.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2A3C63),
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<BuilderRenderStyle>(
                value: renderStyle,
                dropdownColor: const Color(0xFF1D3557),
                iconEnabledColor: Colors.white,
                onChanged: (value) {
                  if (value != null) {
                    onRenderStyleChanged(value);
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: BuilderRenderStyle.simulation,
                    child: Text(
                      'Simulation Painter',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DropdownMenuItem(
                    value: BuilderRenderStyle.builderClassic,
                    child: Text(
                      'Builder Classic',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () {
              provider.loadSimulationDefaultLayout();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Loaded simulation default layout.'),
                ),
              );
            },
            icon: const Icon(Icons.map, color: Colors.white),
            label: const Text('Load Simulation Default',
                style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: exportXml,
            icon: const Icon(Icons.save_alt, color: Colors.white),
            label:
                const Text('Export XML', style: TextStyle(color: Colors.white)),
          ),
          if (onApplyLayout != null) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => onApplyLayout!(provider.exportSimulationLayout()),
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: const Text(
                'Run Simulation',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Zoom In',
            onPressed: () {
              controller.value = controller.value.scaled(1.2, 1.2);
            },
            icon: const Icon(Icons.zoom_in, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Zoom Out',
            onPressed: () {
              controller.value = controller.value.scaled(0.8, 0.8);
            },
            icon: const Icon(Icons.zoom_out, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Reset View',
            onPressed: () {
              controller.value = Matrix4.identity();
            },
            icon: const Icon(Icons.center_focus_strong, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Undo',
            onPressed: provider.undo,
            icon: const Icon(Icons.undo, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Redo',
            onPressed: provider.redo,
            icon: const Icon(Icons.redo, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              IconButton(
                tooltip: provider.magnetEnabled ? 'Magnet On' : 'Magnet Off',
                onPressed: provider.toggleMagnet,
                icon: Icon(
                  provider.magnetEnabled ? Icons.link : Icons.link_off,
                  color: Colors.white,
                ),
              ),
              Switch(
                value: provider.snapToGrid,
                onChanged: (_) => provider.toggleSnapToGrid(),
                activeColor: Colors.cyanAccent,
              ),
              const Text(
                'Snap',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: TextEditingController(
                    text: provider.gridSize.toStringAsFixed(0),
                  ),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    border: OutlineInputBorder(),
                    labelText: 'Grid',
                    labelStyle: TextStyle(fontSize: 11),
                  ),
                  onSubmitted: (value) {
                    final parsed = double.tryParse(value);
                    if (parsed != null) {
                      provider.updateGridSize(parsed);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolPalette extends StatelessWidget {
  const _ToolPalette();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TerminalEditorProvider>(context);

    return Container(
      width: 230,
      color: const Color(0xFFF2F2F2),
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          _ToolButton(
            label: 'Select',
            icon: Icons.mouse,
            isActive: provider.tool == EditorTool.select,
            onTap: () => provider.setTool(EditorTool.select),
          ),
          _ToolButton(
            label: 'Marquee Select',
            icon: Icons.crop_square,
            isActive: provider.tool == EditorTool.marqueeSelect,
            onTap: () => provider.setTool(EditorTool.marqueeSelect),
          ),
          _ToolButton(
            label: 'Move',
            icon: Icons.open_with,
            isActive: provider.tool == EditorTool.move,
            onTap: () => provider.setTool(EditorTool.move),
          ),
          const SizedBox(height: 12),
          const Text(
            'Track',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          _ToolButton(
            label: 'Track Straight',
            icon: Icons.straighten,
            isActive: provider.tool == EditorTool.addTrackStraight,
            onTap: () => provider.setTool(EditorTool.addTrackStraight),
          ),
          _ToolButton(
            label: 'Bend 45 Left',
            icon: Icons.turn_left,
            isActive: provider.tool == EditorTool.addTrackBendLeft,
            onTap: () => provider.setTool(EditorTool.addTrackBendLeft),
          ),
          _ToolButton(
            label: 'Bend 45 Right',
            icon: Icons.turn_right,
            isActive: provider.tool == EditorTool.addTrackBendRight,
            onTap: () => provider.setTool(EditorTool.addTrackBendRight),
          ),
          _ToolButton(
            label: 'Curve Octagon',
            icon: Icons.blur_circular,
            isActive: provider.tool == EditorTool.addTrackCurveOctagon,
            onTap: () => provider.setTool(EditorTool.addTrackCurveOctagon),
          ),
          _ToolButton(
            label: 'Crossover Right',
            icon: Icons.close,
            isActive: provider.tool == EditorTool.addCrossoverRight,
            onTap: () => provider.setTool(EditorTool.addCrossoverRight),
          ),
          _ToolButton(
            label: 'Crossover Left',
            icon: Icons.close,
            isActive: provider.tool == EditorTool.addCrossoverLeft,
            onTap: () => provider.setTool(EditorTool.addCrossoverLeft),
          ),
          _ToolButton(
            label: 'Crossover Diamond',
            icon: Icons.close,
            isActive: provider.tool == EditorTool.addCrossoverDiamond,
            onTap: () => provider.setTool(EditorTool.addCrossoverDiamond),
          ),
          _ToolButton(
            label: 'Point',
            icon: Icons.change_history,
            isActive: provider.tool == EditorTool.addPoint,
            onTap: () => provider.setTool(EditorTool.addPoint),
          ),
          _ToolButton(
            label: 'Platform',
            icon: Icons.train,
            isActive: provider.tool == EditorTool.addPlatform,
            onTap: () => provider.setTool(EditorTool.addPlatform),
          ),
          _ToolButton(
            label: 'Buffer Stop',
            icon: Icons.block,
            isActive: provider.tool == EditorTool.addBufferStop,
            onTap: () => provider.setTool(EditorTool.addBufferStop),
          ),
          const SizedBox(height: 12),
          const Text(
            'Signals & Control',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          _ToolButton(
            label: 'Signal',
            icon: Icons.traffic,
            isActive: provider.tool == EditorTool.addSignal,
            onTap: () => provider.setTool(EditorTool.addSignal),
          ),
          _ToolButton(
            label: 'Train Stop',
            icon: Icons.stop_circle,
            isActive: provider.tool == EditorTool.addTrainStop,
            onTap: () => provider.setTool(EditorTool.addTrainStop),
          ),
          const SizedBox(height: 12),
          const Text(
            'CBTC & Sensors',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          _ToolButton(
            label: 'Axle Counter',
            icon: Icons.adjust,
            isActive: provider.tool == EditorTool.addAxleCounter,
            onTap: () => provider.setTool(EditorTool.addAxleCounter),
          ),
          _ToolButton(
            label: 'Transponder',
            icon: Icons.hexagon,
            isActive: provider.tool == EditorTool.addTransponder,
            onTap: () => provider.setTool(EditorTool.addTransponder),
          ),
          _ToolButton(
            label: 'WiFi Antenna',
            icon: Icons.wifi,
            isActive: provider.tool == EditorTool.addWifiAntenna,
            onTap: () => provider.setTool(EditorTool.addWifiAntenna),
          ),
          const SizedBox(height: 12),
          const Text(
            'Annotations',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          _ToolButton(
            label: 'Text',
            icon: Icons.text_fields,
            isActive: provider.tool == EditorTool.addText,
            onTap: () => provider.setTool(EditorTool.addText),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: provider.deleteSelected,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete Selected'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE63946),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ToolButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFDDEAF6) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? const Color(0xFF457B9D) : Colors.black12,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF1D3557)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PropertiesPanel extends StatefulWidget {
  final TransformationController controller;
  final Size canvasSize;
  final ValueChanged<Size> onCanvasSizeChanged;
  final double leftPanelWidth;
  final double rightPanelWidth;
  final double topBarHeight;

  const _PropertiesPanel({
    required this.controller,
    required this.canvasSize,
    required this.onCanvasSizeChanged,
    required this.leftPanelWidth,
    required this.rightPanelWidth,
    required this.topBarHeight,
  });

  @override
  State<_PropertiesPanel> createState() => _PropertiesPanelState();
}

class _PropertiesPanelState extends State<_PropertiesPanel> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _xController = TextEditingController();
  final TextEditingController _yController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _canvasWidthController = TextEditingController();
  final TextEditingController _canvasHeightController = TextEditingController();
  final TextEditingController _aiPromptController = TextEditingController();
  static const Size _defaultCanvasSize = Size(6000, 4000);
  SelectedComponent? _lastSelected;
  EditorComponentType? _bulkSelectType;
  EditorComponentType? _pickType;
  EditorComponentType? _searchTypeFilter;
  String? _idError;
  bool _includeDescription = false;
  bool _showType = true;
  Size _lastCanvasSize = Size.zero;
  bool _supabaseBusy = false;
  String? _supabaseMessage;
  bool _aiBusy = false;
  String? _aiMessage;
  List<String> _aiAdvice = const [];
  String? _aiRecommendedXml;
  late Future<OpenAiConfig> _openAiConfigFuture;
  OpenAiTerminalAgentService? _openAiService;

  @override
  void initState() {
    super.initState();
    _openAiConfigFuture = OpenAiConfig.loadFromAssets();
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _textController.dispose();
    _xController.dispose();
    _yController.dispose();
    _searchController.dispose();
    _canvasWidthController.dispose();
    _canvasHeightController.dispose();
    _aiPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TerminalEditorProvider>(context);
    final supabaseStatus = context.watch<SupabaseStatusProvider>();
    final selected = provider.selected ??
        (provider.selection.isNotEmpty ? provider.selection.first : null);
    _syncControllers(provider, selected);
    _syncCanvasSize();

    final searchItems = _buildSearchItems(
      provider,
      _searchController.text,
      includeDescription: _includeDescription,
      filterType: _searchTypeFilter,
    );
    final pickItems = _pickType == null
        ? const <_SearchItem>[]
        : _buildSearchItems(
            provider,
            '',
            includeDescription: false,
            filterType: _pickType,
          );
    final selectionItems = provider.selection
        .map((selected) => _searchItemForSelected(provider, selected))
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    return Container(
      width: 260,
      color: const Color(0xFFF7F7F7),
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text('Canvas',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _canvasWidthController,
                  decoration: const InputDecoration(
                    labelText: 'Width',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => _applyCanvasSize(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _canvasHeightController,
                  decoration: const InputDecoration(
                    labelText: 'Height',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => _applyCanvasSize(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyCanvasSize,
                  child: const Text('Apply'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetCanvasSize,
                  child: const Text('Reset'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Pan Controls',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Center(
            child: SizedBox(
              width: 120,
              child: Column(
                children: [
                  IconButton(
                    tooltip: 'Pan Up',
                    onPressed: () => _panBy(0, 80),
                    icon: const Icon(Icons.keyboard_arrow_up),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Pan Left',
                        onPressed: () => _panBy(80, 0),
                        icon: const Icon(Icons.keyboard_arrow_left),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        tooltip: 'Pan Right',
                        onPressed: () => _panBy(-80, 0),
                        icon: const Icon(Icons.keyboard_arrow_right),
                      ),
                    ],
                  ),
                  IconButton(
                    tooltip: 'Pan Down',
                    onPressed: () => _panBy(0, -80),
                    icon: const Icon(Icons.keyboard_arrow_down),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Search',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Find by id or name...',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<EditorComponentType?>(
            value: _searchTypeFilter,
            decoration: const InputDecoration(
              labelText: 'Filter by type',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<EditorComponentType?>(
                value: null,
                child: Text('All types'),
              ),
              ...EditorComponentType.values.map(
                (type) => DropdownMenuItem<EditorComponentType?>(
                  value: type,
                  child: Text(type.name),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _searchTypeFilter = value;
              });
            },
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Include description'),
            value: _includeDescription,
            onChanged: (value) {
              setState(() {
                _includeDescription = value ?? false;
              });
            },
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Show type'),
            value: _showType,
            onChanged: (value) {
              setState(() {
                _showType = value ?? true;
              });
            },
          ),
          if (_searchController.text.isNotEmpty || _searchTypeFilter != null)
            ...searchItems.map((item) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('${item.id} - ${item.name}',
                    style: const TextStyle(fontSize: 12)),
                subtitle: _showType
                    ? Text(item.type.name,
                        style: const TextStyle(fontSize: 10))
                    : null,
                onTap: () => _panTo(item, provider),
              );
            }).toList(),
          const SizedBox(height: 12),
          const Text('Selection',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Large hitboxes'),
            value: provider.largeHitboxes,
            onChanged: (value) {
              provider.updateLargeHitboxes(value ?? true);
            },
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Handles first for resize'),
            value: provider.handlesFirst,
            onChanged: (value) {
              provider.updateHandlesFirst(value ?? true);
            },
          ),

          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<EditorComponentType?>(
                  value: _bulkSelectType,
                  decoration: const InputDecoration(
                    labelText: 'Select all of type',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<EditorComponentType?>(
                      value: null,
                      child: Text('Choose type'),
                    ),
                    ...EditorComponentType.values
                        .map((type) => DropdownMenuItem<EditorComponentType?>(
                              value: type,
                              child: Text(type.name),
                            ))
                        .toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _bulkSelectType = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _bulkSelectType == null
                    ? null
                    : () => provider.selectAllOfType(_bulkSelectType!),
                child: const Text('Select'),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Text('Pick items',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<EditorComponentType?>(
            value: _pickType,
            decoration: const InputDecoration(
              labelText: 'Choose type',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<EditorComponentType?>(
                value: null,
                child: Text('None'),
              ),
              ...EditorComponentType.values
                  .map((type) => DropdownMenuItem<EditorComponentType?>(
                        value: type,
                        child: Text(type.name),
                      ))
                  .toList(),
            ],
            onChanged: (value) {
              setState(() {
                _pickType = value;
              });
            },
          ),
          if (_pickType != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: ListView(
                children: pickItems.map((item) {
                  final isSelected = provider.selection.any((selected) =>
                      selected.type == item.type && selected.id == item.id);
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: isSelected,
                    title: Text(
                      '${item.id} - ${item.name}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    secondary: IconButton(
                      tooltip: 'Center on item',
                      icon: const Icon(Icons.center_focus_strong, size: 18),
                      onPressed: () => _panTo(item, provider),
                    ),
                    onChanged: (_) =>
                        provider.toggleSelectById(item.type, item.id),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Text('Selected items',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (selectionItems.isEmpty)
            const Text('No items selected.',
                style: TextStyle(color: Colors.black54))
          else
            SizedBox(
              height: 140,
              child: ListView(
                children: selectionItems.map((item) {
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('${item.id} - ${item.name}',
                        style: const TextStyle(fontSize: 12)),
                    subtitle: Text(item.type.name,
                        style: const TextStyle(fontSize: 10)),
                    trailing: IconButton(
                      tooltip: 'Remove from selection',
                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                      onPressed: () =>
                          provider.toggleSelectById(item.type, item.id),
                    ),
                    onTap: () => _panTo(item, provider),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 12),
          const Text('Move controls',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (provider.selection.isEmpty)
            const Text('Select items to move.',
                style: TextStyle(color: Colors.black54))
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Nudge up',
                  onPressed: () => provider.nudgeSelection(const Offset(0, -5)),
                  icon: const Icon(Icons.keyboard_arrow_up),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Nudge left',
                  onPressed: () => provider.nudgeSelection(const Offset(-5, 0)),
                  icon: const Icon(Icons.keyboard_arrow_left),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Nudge right',
                  onPressed: () => provider.nudgeSelection(const Offset(5, 0)),
                  icon: const Icon(Icons.keyboard_arrow_right),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Nudge down',
                  onPressed: () => provider.nudgeSelection(const Offset(0, 5)),
                  icon: const Icon(Icons.keyboard_arrow_down),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => provider.nudgeSelection(const Offset(-20, 0)),
                  child: const Text('Left 20'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => provider.nudgeSelection(const Offset(20, 0)),
                  child: const Text('Right 20'),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => provider.nudgeSelection(const Offset(0, -20)),
                  child: const Text('Up 20'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => provider.nudgeSelection(const Offset(0, 20)),
                  child: const Text('Down 20'),
                ),
              ],
            ),
            if (provider.selection.length == 1) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _xController,
                      decoration: const InputDecoration(
                        labelText: 'X',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _yController,
                      decoration: const InputDecoration(
                        labelText: 'Y',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ElevatedButton(
                onPressed: () {
                  final x = double.tryParse(_xController.text.trim());
                  final y = double.tryParse(_yController.text.trim());
                  if (x == null && y == null) return;
                  provider.updateSelectedPosition(x: x, y: y);
                },
                child: const Text('Apply Position'),
              ),
            ],
          ],
          const SizedBox(height: 12),
          const Text('Appearance',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (provider.selection.isEmpty)
            const Text('Select items to edit styles.',
                style: TextStyle(color: Colors.black54))
          else ...[
            Text('Selected items: ${provider.selection.length}'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => provider
                        .setRenderStyleOverrideForSelection(null),
                    child: const Text('Use Default'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => provider.setRenderStyleOverrideForSelection(
                        BuilderRenderStyle.simulation),
                    child: const Text('Simulation'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => provider.setRenderStyleOverrideForSelection(
                        BuilderRenderStyle.builderClassic),
                    child: const Text('Builder'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _buildSupabaseSection(provider, supabaseStatus),
          const SizedBox(height: 12),
          _buildAIAgentSection(provider),
          const SizedBox(height: 12),
          _buildJunctions(provider),
          const SizedBox(height: 12),
          if (provider.selection.isEmpty)
            const Text(
              'Select a component to edit.',
              style: TextStyle(color: Colors.black54),
            )
          else ...[
            Text(
              provider.selection.length == 1
                  ? 'Selected: ${selected?.type.name.toUpperCase()}'
                  : 'Selected: ${provider.selection.length} items',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (provider.selection.length == 1 && selected != null)
              _buildCoordinates(provider, selected),
            const SizedBox(height: 12),
            if (provider.selection.length == 1) ...[
              TextField(
                controller: _idController,
                decoration: InputDecoration(
                  labelText: 'ID',
                  errorText: _idError,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (value) {
                  final ok = provider.renameSelectedId(value.trim());
                  setState(() {
                    _idError = ok ? null : 'ID already exists or invalid';
                  });
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) {
                  provider.updateSelectedName(value.trim());
                },
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onSubmitted: (value) {
                provider.updateSelectedDescription(value.trim());
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onSubmitted: (value) {
                provider.updateSelectedNotes(value.trim());
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Color',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDialog<Color>(
                      context: context,
                      builder: (context) => _ColorPickerDialog(
                        initial: _metadataFor(provider, selected!).color,
                      ),
                    );
                    if (picked != null) {
                      provider.updateSelectedColor(picked);
                    }
                  },
                  child: Container(
                    width: 36,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _metadataFor(provider, selected!).color,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.black26),
                    ),
                  ),
                ),
              ],
            ),
            if (selected!.type == EditorComponentType.textAnnotation) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Text',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                onSubmitted: (value) {
                  provider.updateSelectedText(value.trim());
                },
              ),
            ],
            const SizedBox(height: 16),
            if (provider.selection.length == 1)
              _buildTypeSpecific(provider, selected!)
            else
              const Text('Type-specific settings are available for single selection.',
                  style: TextStyle(color: Colors.black54)),
          ],
        ],
      ),
    );
  }

  Widget _buildJunctions(TerminalEditorProvider provider) {
    final junctions = provider.detectJunctions();
    if (junctions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Alpha/Gamma Junctions',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...junctions.map((junction) {
          return SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              '${junction.id} (${junction.position.dx.toStringAsFixed(0)}, '
              '${junction.position.dy.toStringAsFixed(0)})',
              style: const TextStyle(fontSize: 12),
            ),
            value: junction.isAlphaGamma,
            onChanged: (_) =>
                provider.toggleAlphaGamma(junction.id, junction.position),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSupabaseSection(
    TerminalEditorProvider provider,
    SupabaseStatusProvider statusProvider,
  ) {
    final status = statusProvider.status;
    final statusColor = _supabaseStatusColor(status);
    final statusLabel = _supabaseStatusLabel(status);
    final message = _supabaseMessage ?? statusProvider.message;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Supabase',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(statusLabel,
                  style: TextStyle(fontSize: 12, color: statusColor)),
            ],
          ),
          if (message != null && message.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(message, style: const TextStyle(fontSize: 11)),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _supabaseBusy
                      ? null
                      : () => _refreshSupabase(statusProvider),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _supabaseBusy
                      ? null
                      : () => _showSupabaseSaveDialog(provider),
                  icon: const Icon(Icons.cloud_upload, size: 16),
                  label: const Text('Save'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: _supabaseBusy ? null : () => _loadLatestLayout(provider),
            icon: const Icon(Icons.cloud_download, size: 16),
            label: const Text('Load Latest Layout'),
          ),
          if (statusProvider.recentLayouts.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Recent',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            ...statusProvider.recentLayouts.map((layout) {
              return Text(
                '${layout['name'] ?? 'Layout'} • ${layout['created_at'] ?? ''}',
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildAIAgentSection(TerminalEditorProvider provider) {
    return FutureBuilder<OpenAiConfig>(
      future: _openAiConfigFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildAiCard(
            statusText: 'Loading...',
            statusColor: const Color(0xFFF4A261),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return _buildAiCard(
            statusText: 'Error',
            statusColor: const Color(0xFFE63946),
            child: Text('Failed to load assets/.env: ${snapshot.error}',
                style: const TextStyle(fontSize: 11)),
          );
        }

        final config = snapshot.data!;
        _openAiService ??= OpenAiTerminalAgentService(config: config);
        final enabled = config.enabled && config.apiKey.isNotEmpty;
        final statusColor =
            enabled ? const Color(0xFF2A9D8F) : const Color(0xFFE63946);
        final statusText =
            enabled ? 'Ready' : 'Disabled (check USE_OPENAI / API key)';

        return _buildAiCard(
          statusText: statusText,
          statusColor: statusColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _aiPromptController,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Describe the layout or validation request...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          _aiBusy || !enabled ? null : () => _runAiGenerate(provider),
                      icon: const Icon(Icons.auto_fix_high, size: 16),
                      label: const Text('Generate'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _aiBusy || !enabled ? null : () => _runAiValidate(provider),
                      icon: const Icon(Icons.fact_check, size: 16),
                      label: const Text('Validate'),
                    ),
                  ),
                ],
              ),
              if (_aiRecommendedXml != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _aiBusy ? null : _applyAiRecommendation,
                  icon: const Icon(Icons.build_circle_outlined, size: 16),
                  label: const Text('Apply Recommendation'),
                ),
              ],
              if (_aiMessage != null && _aiMessage!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_aiMessage!, style: const TextStyle(fontSize: 11)),
              ],
              if (_aiAdvice.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Advice',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                ..._aiAdvice.map((tip) => Text('• $tip',
                    style: const TextStyle(fontSize: 11))),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAiCard({
    required String statusText,
    required Color statusColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('OpenAI Agent',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(statusText,
                  style: TextStyle(fontSize: 12, color: statusColor)),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Future<void> _runAiGenerate(TerminalEditorProvider provider) async {
    final prompt = _aiPromptController.text.trim();
    if (prompt.isEmpty) {
      _showMessage('Please describe the layout you want.');
      return;
    }

    setState(() {
      _aiBusy = true;
      _aiMessage = 'Generating layout...';
      _aiAdvice = const [];
      _aiRecommendedXml = null;
    });

    try {
      final response = await _openAiService!.generateLayout(
        description: prompt,
        currentXml: provider.exportXml(),
      );
      if (response.xmlLayout == null) {
        _aiMessage = 'No XML layout returned by the agent.';
      } else {
        provider.importXml(response.xmlLayout!);
        _aiMessage = response.summary.isEmpty
            ? 'Layout applied from OpenAI.'
            : response.summary;
      }
      _aiAdvice = response.advice;
      _aiRecommendedXml = response.recommendedXml;
    } catch (error) {
      _aiMessage = 'Generation failed: $error';
    } finally {
      if (mounted) {
        setState(() {
          _aiBusy = false;
        });
      }
    }
  }

  Future<void> _runAiValidate(TerminalEditorProvider provider) async {
    final prompt = _aiPromptController.text.trim();
    if (prompt.isEmpty) {
      _showMessage('Please describe what you want validated.');
      return;
    }

    setState(() {
      _aiBusy = true;
      _aiMessage = 'Validating layout...';
      _aiAdvice = const [];
      _aiRecommendedXml = null;
    });

    try {
      final response = await _openAiService!.validateLayout(
        description: prompt,
        currentXml: provider.exportXml(),
      );
      _aiMessage = response.summary.isEmpty
          ? 'Validation complete.'
          : response.summary;
      _aiAdvice = response.advice;
      _aiRecommendedXml = response.recommendedXml;
    } catch (error) {
      _aiMessage = 'Validation failed: $error';
    } finally {
      if (mounted) {
        setState(() {
          _aiBusy = false;
        });
      }
    }
  }

  void _applyAiRecommendation() {
    final xml = _aiRecommendedXml;
    if (xml == null || xml.trim().isEmpty) {
      _showMessage('No recommended XML available.');
      return;
    }
    context.read<TerminalEditorProvider>().importXml(xml);
    _showMessage('Recommended layout applied.');
  }

  Color _supabaseStatusColor(SupabaseConnectionStatus status) {
    switch (status) {
      case SupabaseConnectionStatus.connected:
        return const Color(0xFF2A9D8F);
      case SupabaseConnectionStatus.checking:
        return const Color(0xFFF4A261);
      case SupabaseConnectionStatus.disconnected:
        return const Color(0xFF9E9E9E);
      case SupabaseConnectionStatus.error:
        return const Color(0xFFE63946);
      case SupabaseConnectionStatus.idle:
      default:
        return const Color(0xFFB0BEC5);
    }
  }

  String _supabaseStatusLabel(SupabaseConnectionStatus status) {
    switch (status) {
      case SupabaseConnectionStatus.connected:
        return 'Connected';
      case SupabaseConnectionStatus.checking:
        return 'Checking';
      case SupabaseConnectionStatus.disconnected:
        return 'Disabled';
      case SupabaseConnectionStatus.error:
        return 'Error';
      case SupabaseConnectionStatus.idle:
      default:
        return 'Idle';
    }
  }

  Future<void> _refreshSupabase(SupabaseStatusProvider statusProvider) async {
    setState(() {
      _supabaseBusy = true;
      _supabaseMessage = 'Checking connection...';
    });
    await statusProvider.checkConnection();
    await statusProvider.refreshRecentLayouts();
    setState(() {
      _supabaseBusy = false;
      _supabaseMessage = null;
    });
  }

  Future<void> _showSupabaseSaveDialog(
      TerminalEditorProvider provider) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save layout to Supabase'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Layout name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (accepted != true) return;
    final name = nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Please enter a layout name.');
      return;
    }
    await _saveLayoutToSupabase(
      provider,
      name: name,
      description: descriptionController.text.trim(),
    );
  }

  Future<void> _saveLayoutToSupabase(
    TerminalEditorProvider provider, {
    required String name,
    required String description,
  }) async {
    setState(() {
      _supabaseBusy = true;
      _supabaseMessage = 'Saving layout...';
    });

    try {
      final xmlContent = provider.exportXml();
      final stats = _layoutStats(provider);
      await SupabaseService.instance.saveLayout(
        name: name,
        description: description,
        xmlContent: xmlContent,
        stats: stats,
      );
      _showMessage('Layout saved to Supabase.');
    } catch (error) {
      _showMessage('Save failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _supabaseBusy = false;
          _supabaseMessage = null;
        });
      }
    }
  }

  Future<void> _loadLatestLayout(TerminalEditorProvider provider) async {
    setState(() {
      _supabaseBusy = true;
      _supabaseMessage = 'Loading latest layout...';
    });

    try {
      final record = await SupabaseService.instance.fetchLatestLayout();
      if (record == null) {
        _showMessage('No layouts found in Supabase.');
      } else {
        final xml = record['xml_content']?.toString() ?? '';
        if (xml.isEmpty) {
          _showMessage('Latest layout is missing XML content.');
        } else {
          provider.importXml(xml);
          _showMessage('Loaded "${record['name'] ?? 'layout'}".');
        }
      }
    } catch (error) {
      _showMessage('Load failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _supabaseBusy = false;
          _supabaseMessage = null;
        });
      }
    }
  }

  Map<String, dynamic> _layoutStats(TerminalEditorProvider provider) {
    return {
      'segments': provider.segments.length,
      'crossovers': provider.crossovers.length,
      'points': provider.points.length,
      'signals': provider.signals.length,
      'platforms': provider.platforms.length,
      'trainStops': provider.trainStops.length,
      'bufferStops': provider.bufferStops.length,
      'axleCounters': provider.axleCounters.length,
      'transponders': provider.transponders.length,
      'wifiAntennas': provider.wifiAntennas.length,
      'textAnnotations': provider.textAnnotations.length,
    };
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildTypeSpecific(
      TerminalEditorProvider provider, SelectedComponent selected) {
    switch (selected.type) {
      case EditorComponentType.trackSegment:
        return _TrackSegmentEditor(provider: provider);
      case EditorComponentType.crossover:
        return _CrossoverEditor(provider: provider);
      case EditorComponentType.signal:
        return _SignalEditor(provider: provider);
      case EditorComponentType.point:
        return _PointEditor(provider: provider);
      case EditorComponentType.wifiAntenna:
        return _WifiEditor(provider: provider);
      case EditorComponentType.axleCounter:
        return _AxleCounterEditor(provider: provider);
      default:
        return const SizedBox.shrink();
    }
  }

  void _syncControllers(
      TerminalEditorProvider provider, SelectedComponent? selected) {
    if (selected == null) {
      _lastSelected = null;
      return;
    }
    if (_lastSelected?.id == selected.id &&
        _lastSelected?.type == selected.type) {
      return;
    }
    final meta = _metadataFor(provider, selected);
    _idController.text = meta.id;
    _nameController.text = meta.name;
    _descriptionController.text = meta.description;
    _notesController.text = meta.notes;
    _textController.text = meta.text ?? '';
    final pos = _positionForSelected(provider, selected);
    _xController.text = pos.dx.toStringAsFixed(1);
    _yController.text = pos.dy.toStringAsFixed(1);
    _idError = null;
    _lastSelected = selected;
  }

  void _syncCanvasSize() {
    if (_lastCanvasSize == widget.canvasSize) return;
    _canvasWidthController.text = widget.canvasSize.width.toStringAsFixed(0);
    _canvasHeightController.text = widget.canvasSize.height.toStringAsFixed(0);
    _lastCanvasSize = widget.canvasSize;
  }

  void _applyCanvasSize() {
    final width = double.tryParse(_canvasWidthController.text.trim());
    final height = double.tryParse(_canvasHeightController.text.trim());
    if (width == null || height == null) return;
    if (width < 500 || height < 500) return;
    widget.onCanvasSizeChanged(Size(width, height));
  }

  void _resetCanvasSize() {
    widget.onCanvasSizeChanged(_defaultCanvasSize);
  }

  void _panBy(double dx, double dy) {
    final current = widget.controller.value;
    widget.controller.value = current.clone()..translate(dx, dy);
  }

  Widget _buildCoordinates(
      TerminalEditorProvider provider, SelectedComponent selected) {
    final position = _positionForSelected(provider, selected);
    return Row(
      children: [
        Expanded(
          child: Text(
            'X: ${position.dx.toStringAsFixed(1)}',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
        Expanded(
          child: Text(
            'Y: ${position.dy.toStringAsFixed(1)}',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
      ],
    );
  }

  Offset _positionForSelected(
      TerminalEditorProvider provider, SelectedComponent selected) {
    switch (selected.type) {
      case EditorComponentType.trackSegment:
        final seg = provider.segments[selected.id]!;
        final end = seg.endPoint();
        return Offset(
          (seg.startX + end.dx) / 2,
          (seg.startY + end.dy) / 2,
        );
      case EditorComponentType.crossover:
        final xo = provider.crossovers[selected.id]!;
        return Offset(xo.x, xo.y);
      case EditorComponentType.point:
        final point = provider.points[selected.id]!;
        return Offset(point.x, point.y);
      case EditorComponentType.signal:
        final signal = provider.signals[selected.id]!;
        return Offset(signal.x, signal.y);
      case EditorComponentType.platform:
        final platform = provider.platforms[selected.id]!;
        return Offset(platform.centerX, platform.y);
      case EditorComponentType.trainStop:
        final stop = provider.trainStops[selected.id]!;
        return Offset(stop.x, stop.y);
      case EditorComponentType.bufferStop:
        final stop = provider.bufferStops[selected.id]!;
        return Offset(stop.x, stop.y);
      case EditorComponentType.axleCounter:
        final counter = provider.axleCounters[selected.id]!;
        return Offset(counter.x, counter.y);
      case EditorComponentType.transponder:
        final transponder = provider.transponders[selected.id]!;
        return Offset(transponder.x, transponder.y);
      case EditorComponentType.wifiAntenna:
        final wifi = provider.wifiAntennas[selected.id]!;
        return Offset(wifi.x, wifi.y);
      case EditorComponentType.textAnnotation:
        final text = provider.textAnnotations[selected.id]!;
        return Offset(text.x, text.y);
    }
  }

  _SearchItem _searchItemForSelected(
      TerminalEditorProvider provider, SelectedComponent selected) {
    final meta = _metadataFor(provider, selected);
    return _SearchItem(
      type: selected.type,
      id: meta.id,
      name: meta.name,
      position: _positionForSelected(provider, selected),
    );
  }

  _Metadata _metadataFor(
      TerminalEditorProvider provider, SelectedComponent selected) {
    switch (selected.type) {
      case EditorComponentType.trackSegment:
        final item = provider.segments[selected.id]!;
        return _Metadata(
            id: item.id,
            name: item.name,
            description: item.description,
            notes: item.notes,
            color: item.color);
      case EditorComponentType.crossover:
        final item = provider.crossovers[selected.id]!;
        return _Metadata(
            id: item.id,
            name: item.name,
            description: item.description,
            notes: item.notes,
            color: item.color);
      case EditorComponentType.point:
        final item = provider.points[selected.id]!;
        return _Metadata(
            id: item.id,
            name: item.name,
            description: item.description,
            notes: item.notes,
            color: item.color);
      case EditorComponentType.signal:
        final item = provider.signals[selected.id]!;
        return _Metadata(
            id: item.id,
            name: item.name,
            description: item.description,
            notes: item.notes,
            color: item.color);
      case EditorComponentType.platform:
        final item = provider.platforms[selected.id]!;
        return _Metadata(
            id: item.id,
            name: item.name,
            description: item.description,
            notes: item.notes,
            color: item.color);
      case EditorComponentType.trainStop:
        final item = provider.trainStops[selected.id]!;
        return _Metadata(
            id: item.id,
            name: item.name,
            description: item.description,
            notes: item.notes,
            color: item.color);
      case EditorComponentType.bufferStop:
        final item = provider.bufferStops[selected.id]!;
        return _Metadata(
            id: item.id,
            name: item.name,
            description: item.description,
            notes: item.notes,
            color: item.color);
      case EditorComponentType.axleCounter:
        final item = provider.axleCounters[selected.id]!;
        return _Metadata(
            id: item.id,
            name: item.name,
            description: item.description,
            notes: item.notes,
            color: item.color);
      case EditorComponentType.transponder:
        final item = provider.transponders[selected.id]!;
        return _Metadata(
            id: item.id,
            name: item.name,
            description: item.description,
            notes: item.notes,
            color: item.color);
      case EditorComponentType.wifiAntenna:
        final item = provider.wifiAntennas[selected.id]!;
        return _Metadata(
            id: item.id,
            name: item.name,
            description: item.description,
            notes: item.notes,
            color: item.color);
      case EditorComponentType.textAnnotation:
        final item = provider.textAnnotations[selected.id]!;
        return _Metadata(
            id: item.id,
            name: item.name,
            description: item.description,
            notes: item.notes,
            color: item.color,
            text: item.text);
    }
  }

  List<_SearchItem> _buildSearchItems(
    TerminalEditorProvider provider,
    String query, {
    required bool includeDescription,
    EditorComponentType? filterType,
  }) {
    final q = query.trim().toLowerCase();
    final listAll = q.isEmpty && filterType != null;
    if (q.isEmpty && !listAll) return [];

    final items = <_SearchItem>[];
    void addItem(
      EditorComponentType type,
      String id,
      String name,
      String description,
      Offset pos,
    ) {
      if (filterType != null && type != filterType) {
        return;
      }
      final matches = id.toLowerCase().contains(q) ||
          name.toLowerCase().contains(q) ||
          (includeDescription && description.toLowerCase().contains(q));
      if (listAll || matches) {
        items.add(_SearchItem(type: type, id: id, name: name, position: pos));
      }
    }

    for (final entry in provider.segments.entries) {
      final seg = entry.value;
      final end = seg.endPoint();
      addItem(
        EditorComponentType.trackSegment,
        seg.id,
        seg.name,
        seg.description,
        Offset((seg.startX + end.dx) / 2, (seg.startY + end.dy) / 2),
      );
    }
    for (final entry in provider.crossovers.entries) {
      final xo = entry.value;
      addItem(EditorComponentType.crossover, xo.id, xo.name, xo.description,
          Offset(xo.x, xo.y));
    }
    for (final entry in provider.points.entries) {
      final point = entry.value;
      addItem(EditorComponentType.point, point.id, point.name, point.description,
          Offset(point.x, point.y));
    }
    for (final entry in provider.signals.entries) {
      final signal = entry.value;
      addItem(EditorComponentType.signal, signal.id, signal.name, signal.description,
          Offset(signal.x, signal.y));
    }
    for (final entry in provider.platforms.entries) {
      final platform = entry.value;
      addItem(
        EditorComponentType.platform,
        platform.id,
        platform.name,
        platform.description,
        Offset((platform.startX + platform.endX) / 2, platform.y),
      );
    }
    for (final entry in provider.trainStops.entries) {
      final stop = entry.value;
      addItem(EditorComponentType.trainStop, stop.id, stop.name, stop.description,
          Offset(stop.x, stop.y));
    }
    for (final entry in provider.bufferStops.entries) {
      final stop = entry.value;
      addItem(EditorComponentType.bufferStop, stop.id, stop.name, stop.description,
          Offset(stop.x, stop.y));
    }
    for (final entry in provider.axleCounters.entries) {
      final counter = entry.value;
      addItem(EditorComponentType.axleCounter, counter.id, counter.name, counter.description,
          Offset(counter.x, counter.y));
    }
    for (final entry in provider.transponders.entries) {
      final transponder = entry.value;
      addItem(EditorComponentType.transponder, transponder.id, transponder.name,
          transponder.description, Offset(transponder.x, transponder.y));
    }
    for (final entry in provider.wifiAntennas.entries) {
      final wifi = entry.value;
      addItem(EditorComponentType.wifiAntenna, wifi.id, wifi.name, wifi.description,
          Offset(wifi.x, wifi.y));
    }
    for (final entry in provider.textAnnotations.entries) {
      final text = entry.value;
      addItem(EditorComponentType.textAnnotation, text.id, text.name, text.description,
          Offset(text.x, text.y));
    }

    items.sort((a, b) => a.id.compareTo(b.id));
    return items;
  }

  void _panTo(_SearchItem item, TerminalEditorProvider provider) {
    provider.selectById(item.type, item.id);
    final size = MediaQuery.of(context).size;
    final visibleWidth =
        size.width - widget.leftPanelWidth - widget.rightPanelWidth;
    final visibleHeight = size.height - widget.topBarHeight;
    final scale = widget.controller.value.getMaxScaleOnAxis();
    final centerX = widget.leftPanelWidth + visibleWidth / 2;
    final centerY = widget.topBarHeight + visibleHeight / 2;
    final target = Offset(
      centerX - item.position.dx * scale,
      centerY - item.position.dy * scale,
    );
    widget.controller.value = Matrix4.identity()
      ..translate(target.dx, target.dy)
      ..scale(scale);
  }
}

class _Metadata {
  final String id;
  final String name;
  final String description;
  final String notes;
  final Color color;
  final String? text;

  _Metadata({
    required this.id,
    required this.name,
    required this.description,
    required this.notes,
    required this.color,
    this.text,
  });
}

class _SearchItem {
  final EditorComponentType type;
  final String id;
  final String name;
  final Offset position;

  _SearchItem({
    required this.type,
    required this.id,
    required this.name,
    required this.position,
  });
}

class _ColorPickerDialog extends StatelessWidget {
  final Color initial;

  const _ColorPickerDialog({required this.initial});

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFF2E86AB),
      Color(0xFF4C566A),
      Color(0xFF2A9D8F),
      Color(0xFFE63946),
      Color(0xFF6D597A),
      Color(0xFFF4A261),
      Color(0xFFB00020),
      Color(0xFF457B9D),
      Color(0xFF118AB2),
      Color(0xFF06D6A0),
      Color(0xFF5A3E2B),
      Color(0xFF9B5DE5),
      Color(0xFF4361EE),
      Color(0xFFF72585),
      Color(0xFF00B4D8),
      Color(0xFF43AA8B),
    ];

    return AlertDialog(
      title: const Text('Pick Color'),
      content: SizedBox(
        width: 240,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((color) {
            final selected = color.value == initial.value;
            return GestureDetector(
              onTap: () => Navigator.of(context).pop(color),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: selected ? Colors.black : Colors.black26,
                    width: selected ? 2 : 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _TrackSegmentEditor extends StatelessWidget {
  final TerminalEditorProvider provider;

  const _TrackSegmentEditor({required this.provider});

  @override
  Widget build(BuildContext context) {
    final selected = provider.selected;
    if (selected == null) return const SizedBox.shrink();
    final segment = provider.segments[selected.id];
    if (segment == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Track ${selected.id}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('Guideway Direction'),
        DropdownButton<GuidewayDirection>(
          value: segment.guidewayDirection,
          onChanged: (value) {
            if (value != null) {
              provider.updateSelectedGuidewayDirection(value);
            }
          },
          items: GuidewayDirection.values
              .map((dir) => DropdownMenuItem(
                    value: dir,
                    child: Text(_guidewayLabel(dir)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        const Text('Material Style'),
        DropdownButton<TrackStyle>(
          value: segment.style,
          onChanged: (value) {
            if (value != null) {
              provider.updateSelectedTrackStyle(value);
            }
          },
          items: TrackStyle.values
              .map((style) => DropdownMenuItem(
                    value: style,
                    child: Text(_trackStyleLabel(style)),
                  ))
              .toList(),
        ),
      ],
    );
  }

  String _trackStyleLabel(TrackStyle style) {
    switch (style) {
      case TrackStyle.ballast:
        return 'Ballast';
      case TrackStyle.slab:
        return 'Slab';
      case TrackStyle.gravel:
        return 'Gravel';
      case TrackStyle.bridge:
        return 'Bridge';
      case TrackStyle.tunnel:
        return 'Tunnel';
      case TrackStyle.yard:
        return 'Yard';
      case TrackStyle.service:
        return 'Service';
      case TrackStyle.elevated:
        return 'Elevated';
      case TrackStyle.industrial:
        return 'Industrial';
      case TrackStyle.metro:
        return 'Metro';
    }
  }

  String _guidewayLabel(GuidewayDirection direction) {
    switch (direction) {
      case GuidewayDirection.gd0:
        return 'GD0 (South/West)';
      case GuidewayDirection.gd1:
        return 'GD1 (North/East)';
    }
  }
}

class _CrossoverEditor extends StatelessWidget {
  final TerminalEditorProvider provider;

  const _CrossoverEditor({required this.provider});

  @override
  Widget build(BuildContext context) {
    final selected = provider.selected;
    if (selected == null) return const SizedBox.shrink();
    final crossover = provider.crossovers[selected.id];
    if (crossover == null) return const SizedBox.shrink();
    final effectiveAngle = crossover.gapAngle == 0
        ? provider.defaultGapAngle
        : crossover.gapAngle;
    final gapController = TextEditingController(
      text: effectiveAngle.toStringAsFixed(1),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Crossover ${selected.id}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('Material Style'),
        DropdownButton<TrackStyle>(
          value: crossover.style,
          onChanged: (value) {
            if (value != null) {
              provider.updateSelectedCrossoverStyle(value);
            }
          },
          items: TrackStyle.values
              .map((style) => DropdownMenuItem(
                    value: style,
                    child: Text(_trackStyleLabel(style)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        Text('Gap angle (${effectiveAngle.toStringAsFixed(1)}°)'),
        Slider(
          value: effectiveAngle.clamp(1.0, 60.0),
          min: 1.0,
          max: 60.0,
          divisions: 59,
          label: effectiveAngle.toStringAsFixed(1),
          onChanged: provider.updateSelectedCrossoverGapAngle,
        ),
        TextField(
          controller: gapController,
          decoration: const InputDecoration(
            labelText: 'Gap angle (deg)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          keyboardType: TextInputType.number,
          onSubmitted: (value) {
            final parsed = double.tryParse(value.trim());
            if (parsed == null) return;
            provider.updateSelectedCrossoverGapAngle(parsed);
          },
        ),
      ],
    );
  }

  String _trackStyleLabel(TrackStyle style) {
    switch (style) {
      case TrackStyle.ballast:
        return 'Ballast';
      case TrackStyle.slab:
        return 'Slab';
      case TrackStyle.gravel:
        return 'Gravel';
      case TrackStyle.bridge:
        return 'Bridge';
      case TrackStyle.tunnel:
        return 'Tunnel';
      case TrackStyle.yard:
        return 'Yard';
      case TrackStyle.service:
        return 'Service';
      case TrackStyle.elevated:
        return 'Elevated';
      case TrackStyle.industrial:
        return 'Industrial';
      case TrackStyle.metro:
        return 'Metro';
    }
  }
}

class _SignalEditor extends StatelessWidget {
  final TerminalEditorProvider provider;

  const _SignalEditor({required this.provider});

  @override
  Widget build(BuildContext context) {
    final selected = provider.selected;
    if (selected == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Signal ${selected.id}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('Aspect'),
        DropdownButton<SignalAspect>(
          value: provider.signals[selected.id]?.aspect ?? SignalAspect.red,
          onChanged: (value) {
            if (value != null) provider.updateSignalAspect(value);
          },
          items: SignalAspect.values
              .map((aspect) => DropdownMenuItem(
                    value: aspect,
                    child: Text(aspect.name.toUpperCase()),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        const Text('Direction'),
        DropdownButton<SignalDirection>(
          value:
              provider.signals[selected.id]?.direction ?? SignalDirection.east,
          onChanged: (value) {
            if (value != null) provider.updateSignalDirection(value);
          },
          items: SignalDirection.values
              .map((dir) => DropdownMenuItem(
                    value: dir,
                    child: Text(dir.name.toUpperCase()),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _PointEditor extends StatelessWidget {
  final TerminalEditorProvider provider;

  const _PointEditor({required this.provider});

  @override
  Widget build(BuildContext context) {
    final selected = provider.selected;
    if (selected == null) return const SizedBox.shrink();
    final point = provider.points[selected.id];
    if (point == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Point ${selected.id}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Auto Detect Orientation'),
          value: point.autoDetectOrientation,
          onChanged: (_) => provider.togglePointAutoDetectOrientation(),
        ),
        const SizedBox(height: 6),
        const Text('Orientation'),
        DropdownButton<PointOrientation>(
          value: point.orientation,
          onChanged: point.autoDetectOrientation
              ? null
              : (value) {
                  if (value != null) {
                    provider.updatePointOrientation(value);
                  }
                },
          items: PointOrientation.values
              .map((orientation) => DropdownMenuItem(
                    value: orientation,
                    child: Text(_pointOrientationLabel(orientation)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        const Text('Position'),
        DropdownButton<PointPosition>(
          value: provider.points[selected.id]?.position ??
              PointPosition.normal,
          onChanged: (value) {
            if (value != null) provider.updatePointPosition(value);
          },
          items: PointPosition.values
              .map((pos) => DropdownMenuItem(
                    value: pos,
                    child: Text(pos.name.toUpperCase()),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        const Text('Style'),
        DropdownButton<PointStyle>(
          value: point.style,
          onChanged: (value) {
            if (value != null) provider.updatePointStyle(value);
          },
          items: PointStyle.values
              .map((style) => DropdownMenuItem(
                    value: style,
                    child: Text(_pointStyleLabel(style)),
                  ))
              .toList(),
        ),
      ],
    );
  }

  String _pointStyleLabel(PointStyle style) {
    switch (style) {
      case PointStyle.classic:
        return 'Classic Gap';
      case PointStyle.blade:
        return 'Blade Shift';
      case PointStyle.chevron:
        return 'Chevron';
      case PointStyle.wedge:
        return 'Wedge';
      case PointStyle.indicator:
        return 'Indicator';
      case PointStyle.bridge:
        return 'Bridge Link';
      case PointStyle.terminalGap:
        return 'Terminal Gap';
    }
  }

  String _pointOrientationLabel(PointOrientation orientation) {
    switch (orientation) {
      case PointOrientation.upLeft:
        return 'Up-Left';
      case PointOrientation.upRight:
        return 'Up-Right';
      case PointOrientation.downLeft:
        return 'Down-Left';
      case PointOrientation.downRight:
        return 'Down-Right';
    }
  }
}

class _WifiEditor extends StatelessWidget {
  final TerminalEditorProvider provider;

  const _WifiEditor({required this.provider});

  @override
  Widget build(BuildContext context) {
    final selected = provider.selected;
    if (selected == null) return const SizedBox.shrink();
    final wifi = provider.wifiAntennas[selected.id];
    if (wifi == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('WiFi ${selected.id}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SwitchListTile(
          value: wifi.isActive,
          onChanged: (_) => provider.toggleWifiActive(),
          title: const Text('Active'),
        ),
      ],
    );
  }
}

class _AxleCounterEditor extends StatelessWidget {
  final TerminalEditorProvider provider;

  const _AxleCounterEditor({required this.provider});

  @override
  Widget build(BuildContext context) {
    final selected = provider.selected;
    if (selected == null) return const SizedBox.shrink();
    final counter = provider.axleCounters[selected.id];
    if (counter == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Axle Counter ${selected.id}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SwitchListTile(
          value: counter.flipped,
          onChanged: (_) => provider.toggleAxleCounterFlipped(),
          title: const Text('Flipped'),
        ),
      ],
    );
  }
}

class _AxisScrollBar extends StatefulWidget {
  final Axis axis;
  final TransformationController controller;
  final Size viewSize;
  final Size canvasSize;

  const _AxisScrollBar({
    required this.axis,
    required this.controller,
    required this.viewSize,
    required this.canvasSize,
  });

  @override
  State<_AxisScrollBar> createState() => _AxisScrollBarState();
}

class _AxisScrollBarState extends State<_AxisScrollBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTransformChanged);
  }

  @override
  void didUpdateWidget(covariant _AxisScrollBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTransformChanged);
      widget.controller.addListener(_onTransformChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTransformChanged);
    super.dispose();
  }

  void _onTransformChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.controller.value.getMaxScaleOnAxis();
    final translation = widget.controller.value.getTranslation();
    final maxOffset = _maxOffset(scale);
    final value = maxOffset <= 0 ? 0.0 : (-_axisValue(translation) / maxOffset);

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
      ),
      child: Slider(
        value: value.clamp(0.0, 1.0),
        onChanged: maxOffset <= 0
            ? null
            : (v) {
                final newOffset = -v * maxOffset;
                _setAxisTranslation(newOffset, translation, scale);
              },
      ),
    );
  }

  double _axisValue(Vector3 translation) {
    return widget.axis == Axis.horizontal ? translation.x : translation.y;
  }

  double _maxOffset(double scale) {
    final scaledCanvas = widget.axis == Axis.horizontal
        ? widget.canvasSize.width * scale
        : widget.canvasSize.height * scale;
    final view = widget.axis == Axis.horizontal
        ? widget.viewSize.width
        : widget.viewSize.height;
    final maxOffset = scaledCanvas - view;
    return maxOffset > 0 ? maxOffset : 0;
  }

  void _setAxisTranslation(
      double newOffset, Vector3 translation, double scale) {
    final current = Matrix4.identity();
    if (widget.axis == Axis.horizontal) {
      current.setTranslation(Vector3(newOffset, translation.y, 0));
    } else {
      current.setTranslation(Vector3(translation.x, newOffset, 0));
    }
    current.scale(scale);
    widget.controller.value = current;
  }
}

class _ValidationDialog extends StatefulWidget {
  final TerminalEditorProvider provider;

  const _ValidationDialog({required this.provider});

  @override
  State<_ValidationDialog> createState() => _ValidationDialogState();
}

class _ValidationDialogState extends State<_ValidationDialog> {
  ValidationLevel _level = ValidationLevel.standard;
  late List<ValidationIssue> _issues;

  @override
  void initState() {
    super.initState();
    _issues = widget.provider.validateLayout(_level);
  }

  @override
  Widget build(BuildContext context) {
    final counts = <ValidationSeverity, int>{
      ValidationSeverity.error: 0,
      ValidationSeverity.warning: 0,
      ValidationSeverity.info: 0,
    };
    for (final issue in _issues) {
      counts[issue.severity] = (counts[issue.severity] ?? 0) + 1;
    }

    return AlertDialog(
      title: const Text('Layout Validation'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('Validation Level'),
                const Spacer(),
                DropdownButton<ValidationLevel>(
                  value: _level,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _level = value;
                      _issues = widget.provider.validateLayout(_level);
                    });
                  },
                  items: ValidationLevel.values
                      .map((level) => DropdownMenuItem(
                            value: level,
                            child: Text(_levelLabel(level)),
                          ))
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Errors: ${counts[ValidationSeverity.error]}  '
              'Warnings: ${counts[ValidationSeverity.warning]}  '
              'Info: ${counts[ValidationSeverity.info]}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _issues.length,
                separatorBuilder: (_, __) => const Divider(height: 12),
                itemBuilder: (context, index) {
                  final issue = _issues[index];
                  final color = _severityColor(issue.severity);
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, color: color, size: 10),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          issue.message,
                          style: TextStyle(fontSize: 12, color: color),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  String _levelLabel(ValidationLevel level) {
    switch (level) {
      case ValidationLevel.low:
        return 'Low';
      case ValidationLevel.standard:
        return 'Standard';
      case ValidationLevel.high:
        return 'High';
    }
  }

  Color _severityColor(ValidationSeverity severity) {
    switch (severity) {
      case ValidationSeverity.error:
        return const Color(0xFFB00020);
      case ValidationSeverity.warning:
        return const Color(0xFFEF6C00);
      case ValidationSeverity.info:
        return const Color(0xFF1D3557);
    }
  }
}
