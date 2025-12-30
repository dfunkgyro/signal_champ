import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'terminal_station_models.dart';
import 'package:rail_champ/controllers/terminal_station_controller.dart';
import 'package:rail_champ/controllers/canvas_theme_controller.dart';
import '../widgets/collision_alarm_ui.dart';
import '../widgets/ai_agent_panel.dart';
import '../widgets/relay_rack_panel.dart';
import '../widgets/dot_matrix_display.dart';
import '../widgets/layer_panel.dart';
import '../widgets/component_palette.dart';
import '../widgets/block_control_panel.dart';
import 'scenario_marketplace_screen.dart';
import 'dart:math' as math;

// ============================================================================
// TERMINAL STATION SCREEN
// ============================================================================

import 'terminal_station_painter.dart';
import '../widgets/railway_search_bar.dart';
import '../widgets/mini_map_widget.dart';
import '../services/widget_preferences_service.dart';
import '../services/sound_service.dart';
import '../widgets/crossover_route_table_terminal.dart';
import '../widgets/layout_selector_dropdown.dart';
import '../widgets/control_table_panel.dart';
import '../widgets/ai_control_table_panel.dart';
import '../widgets/maintenance_component_list_panel.dart';
import '../widgets/maintenance_search_panel.dart';
import '../widgets/maintenance_property_editor.dart';
import '../widgets/maintenance_toolbar.dart';
import '../widgets/canvas_drop_target.dart';
import '../controllers/maintenance_edit_controller.dart';
import '../services/layout_xml_service.dart';

class TerminalStationScreen extends StatefulWidget {
  const TerminalStationScreen({Key? key}) : super(key: key);

  @override
  State<TerminalStationScreen> createState() => _TerminalStationScreenState();
}

class _TerminalStationScreenState extends State<TerminalStationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late TerminalStationController _controller;
  late MaintenanceEditController _maintenanceEditController;
  int _animationTick = 0;
  double _cameraOffsetX = 0;
  double _cameraOffsetY = 0; // FIXED: Add Y-axis panning support
  double _zoom = 0.8;
  bool _showLeftPanel = true;
  bool _showRightPanel = true;
  bool _showTopPanel = false;
  String? _selectedBlockForTrain;
  TrainType _selectedTrainType = TrainType.m1;
  String? _selectedDestination;
  bool _assignToTimetable = false;
  bool _showGhostTrains = false;

  // Edit Mode: Component dragging state
  bool _isDraggingComponent = false;
  String? _draggingComponentId;
  String? _draggingComponentType;
  Offset? _dragStartPosition;

  // Edit Mode: Marquee selection state
  bool _isDrawingMarquee = false;
  Offset? _marqueeStart;
  Offset? _marqueeEnd;

  // Edit Mode: Scroll controllers for edit mode navigation
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  // Draggable Add Train Button position
  Offset _addTrainButtonPosition = const Offset(100, 100); // Default position
  
  // Draggable Simulation Button position
  Offset _simButtonOffset = const Offset(20, 200); // Default position

  // Top panel adjustable height
  double _topPanelHeight = 120.0; // Default height
  final double _minTopPanelHeight = 80.0;
  final double _maxTopPanelHeight = 300.0;

  // FIXED: Canvas size controls for expanded 7000×1200 closed-loop network
  double _canvasWidth = 7000.0; // Expanded width for full loop
  double _canvasHeight = 1200.0; // Expanded height for return line
  final double _defaultCanvasWidth = 7000.0;
  final double _defaultCanvasHeight = 1200.0;

  // Hit detection radii (Euclidean distance in canvas units)
  static const double _hitRadiusSignal = 30.0;
  static const double _hitRadiusPoint = 20.0;
  static const double _hitRadiusPlatform = 25.0;
  static const double _hitRadiusTrainStop = 20.0;
  static const double _hitRadiusBufferStop = 20.0;
  static const double _hitRadiusAxleCounter = 20.0;
  static const double _hitRadiusTransponder = 20.0;
  static const double _hitRadiusWifiAntenna = 25.0;
  static const double _hitRadiusTrain = 40.0;
  static const double _hitRadiusBlock = 20.0;
  static const double _hitRadiusResizeHandle = 12.0;

  @override
  void initState() {
    super.initState();

    // Initialize controller and add camera sync listener
    _controller = context.read<TerminalStationController>();
    _controller.addListener(_syncCameraState);

    // Initialize maintenance edit controller
    _maintenanceEditController = MaintenanceEditController(_controller);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(() {
        if (mounted) {
          setState(() {
            _animationTick++;
          });
        }
        _controller.updateSimulation();
      });
    _animationController.repeat();
  }

  /// Syncs local camera state with controller's camera state
  /// This enables search and other features to pan/zoom the viewport
  void _syncCameraState() {
    if (mounted) {
      setState(() {
        _cameraOffsetX = _controller.cameraOffsetX;
        _cameraOffsetY = _controller.cameraOffsetY;
        _zoom = _controller.cameraZoom;
      });
      _applyPendingCanvasCenter();
    }
  }

  void _applyPendingCanvasCenter() {
    final target = _controller.consumeCanvasCenter();
    if (target == null) return;
    if (_controller.editModeEnabled) {
      if (!_horizontalScrollController.hasClients ||
          !_verticalScrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _controller.requestCanvasCenter(target);
        });
        return;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;

      final leftPanelWidth = _showLeftPanel
          ? (_controller.maintenanceModeEnabled
              ? 300.0
              : (_controller.controlTableModeEnabled ? 380.0 : 320.0))
          : 0.0;
      final rightPanelWidth = _showRightPanel
          ? (_controller.maintenanceModeEnabled
              ? 320.0
              : (_controller.controlTableModeEnabled ? 380.0 : 320.0))
          : 0.0;

      final visibleWidth = size.width - leftPanelWidth - rightPanelWidth;
      final toolbarHeight = _controller.maintenanceModeEnabled ? 56.0 : 0.0;
      final visibleHeight = size.height - toolbarHeight;
      final centerYOffset =
          (_controller.maintenanceModeEnabled || _controller.controlTableModeEnabled)
              ? 120.0
              : 0.0;

      if (!_controller.editModeEnabled) {
        final panelShiftX =
            ((leftPanelWidth - rightPanelWidth) / 2) / _zoom;
        final panelShiftY = (toolbarHeight / 2) / _zoom;
        final adjustedTarget = Offset(
          target.dx - panelShiftX,
          target.dy + (centerYOffset / _zoom) - panelShiftY,
        );
        _controller.panToPosition(
          adjustedTarget.dx,
          adjustedTarget.dy,
          zoom: _zoom,
          viewportWidth: visibleWidth,
          viewportHeight: visibleHeight,
        );
        return;
      }

      final canvasMinX = -_canvasWidth / 2;
      final canvasMinY = -_canvasHeight / 2;
      final scrollableWidth = _canvasWidth * _zoom;
      final scrollableHeight = _canvasHeight * _zoom;

      final targetLocalX = leftPanelWidth + (visibleWidth / 2);
      final targetLocalY =
          toolbarHeight + (visibleHeight / 2) + centerYOffset;

      final rawScrollX = ((target.dx - canvasMinX) * _zoom) - targetLocalX;
      final rawScrollY = ((target.dy - canvasMinY) * _zoom) - targetLocalY;

      final maxScrollX = (scrollableWidth - size.width).clamp(0.0, double.infinity);
      final maxScrollY = (scrollableHeight - size.height).clamp(0.0, double.infinity);

      final scrollX = rawScrollX.clamp(0.0, maxScrollX);
      final scrollY = rawScrollY.clamp(0.0, maxScrollY);

      _horizontalScrollController.animateTo(
        scrollX,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      _verticalScrollController.animateTo(
        scrollY,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }



  @override
  void dispose() {
    _controller.removeListener(_syncCameraState);
    _animationController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  // NEW: Canvas size control methods
  void _increaseCanvasWidth() {
    setState(() {
      _canvasWidth += 100.0;
    });
  }

  void _decreaseCanvasWidth() {
    setState(() {
      _canvasWidth = (_canvasWidth - 100.0)
          .clamp(800.0, 8000.0); // FIXED: Allow up to 8000
    });
  }

  void _increaseCanvasHeight() {
    setState(() {
      _canvasHeight = (_canvasHeight + 50.0)
          .clamp(300.0, 1500.0); // FIXED: Clamp to max 1500
    });
  }

  void _decreaseCanvasHeight() {
    setState(() {
      _canvasHeight = (_canvasHeight - 50.0)
          .clamp(300.0, 1500.0); // FIXED: Allow up to 1500
    });
  }

  void _resetCanvasSize() {
    setState(() {
      _canvasWidth = _defaultCanvasWidth;
      _canvasHeight = _defaultCanvasHeight;
      _cameraOffsetX = 0;
      _cameraOffsetY = 0; // FIXED: Reset Y offset too
      _zoom = 0.8;
    });
  }

  // NEW: Zoom control methods
  void _zoomIn() {
    final newZoom = (_controller.cameraZoom * 1.2).clamp(0.3, 3.0);
    _controller.updateCameraPosition(
      _controller.cameraOffsetX,
      _controller.cameraOffsetY,
      newZoom,
    );
    _controller.disableAutoFollow();
  }

  void _zoomOut() {
    final newZoom = (_controller.cameraZoom / 1.2).clamp(0.3, 3.0);
    _controller.updateCameraPosition(
      _controller.cameraOffsetX,
      _controller.cameraOffsetY,
      newZoom,
    );
    _controller.disableAutoFollow();
  }

  void _resetZoom() {
    setState(() {
      _zoom = 0.8;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Railway Simulator'),
        actions: [
          Consumer<TerminalStationController>(
            builder: (context, controller, child) => IconButton(
              icon: Icon(
                Icons.table_chart,
                color: controller.controlTableModeEnabled ? Colors.blue : null,
              ),
              onPressed: () {
                controller.toggleControlTableMode();
              },
              tooltip: controller.controlTableModeEnabled
                  ? 'Exit Control Table Mode'
                  : 'Control Table Mode - Edit Signal Logic',
            ),
          ),
          Consumer<TerminalStationController>(
            builder: (context, controller, child) => IconButton(
              icon: Icon(
                Icons.build_circle,
                color: controller.maintenanceModeEnabled ? Colors.orange : null,
              ),
              onPressed: () {
                controller.toggleMaintenanceMode();
              },
              tooltip: controller.maintenanceModeEnabled
                  ? 'Exit Maintenance Mode'
                  : 'Maintenance Mode - Edit Layout',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.dashboard_customize),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ScenarioMarketplaceScreen(),
                ),
              );
            },
            tooltip: 'Scenario Builder & Marketplace',
          ),
          IconButton(
            icon: Icon(
              _showTopPanel ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              size: 30,
            ),
            onPressed: () => setState(() => _showTopPanel = !_showTopPanel),
            tooltip: _showTopPanel ? 'Hide Top Panel' : 'Show Top Panel',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfo(context),
          ),
        ],
      ),
      body: ChangeNotifierProvider<MaintenanceEditController>.value(
        value: _maintenanceEditController,
        child: Stack(
          children: [
            // Main canvas area - now takes full available space
            Stack(
              children: [
              // Layer 1: Railway Canvas (bottom layer)
              _buildStationCanvas(),

              // Layer 2: Floating Zoom Controls (NEW)
              Positioned(
                right: 20,
                bottom: 20,
                child: _buildFloatingZoomControls(),
              ),

              // Layer 3: Left Sidebar (higher z-order)
              Consumer<TerminalStationController>(
                builder: (context, controller, child) {
                  if (!_showLeftPanel) return const SizedBox.shrink();

                  // Show Maintenance Component List in maintenance mode
                  if (controller.maintenanceModeEnabled) {
                    return const Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: MaintenanceComponentListPanel(
                        title: 'Components',
                      ),
                    );
                  }

                  // Show Control Table Panel in control table mode
                  if (controller.controlTableModeEnabled) {
                    return Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 380,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          border: Border(
                            right: BorderSide(
                              color: Theme.of(context).colorScheme.outline,
                              width: 2,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                              offset: const Offset(2, 0),
                            ),
                          ],
                        ),
                        child: const ControlTablePanel(
                          title: 'Control Table (Left)',
                          isLeftSidebar: true,
                        ),
                      ),
                    );
                  }

                  // Show Control Panel
                  return Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 320,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border(
                          right: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                            width: 2,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                            offset: const Offset(2, 0),
                          ),
                        ],
                      ),
                      child: _buildControlPanel(),
                    ),
                  );
                },
              ),

              // Layer 4: Right Sidebar (higher z-order)
              // Layer 4: Right Sidebar (higher z-order)
              Consumer<TerminalStationController>(
                builder: (context, controller, child) {
                  if (!_showRightPanel) return const SizedBox.shrink();

                  // Show Maintenance Property Editor in maintenance mode
                  if (controller.maintenanceModeEnabled) {
                    return const Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: MaintenancePropertyEditor(
                        title: 'Properties',
                      ),
                    );
                  }

                  // Show Control Table Panel in control table mode
                  if (controller.controlTableModeEnabled) {
                    return Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 380,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          border: Border(
                            left: BorderSide(
                              color: Theme.of(context).colorScheme.outline,
                              width: 2,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                              offset: const Offset(-2, 0),
                            ),
                          ],
                        ),
                        child: const AIControlTablePanel(
                          title: 'Control Table AI',
                        ),
                      ),
                    );
                  }

                  return Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 320,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border(
                          left: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                            width: 2,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                            offset: const Offset(-2, 0),
                          ),
                        ],
                      ),
                      child: _buildStatusPanel(),
                    ),
                  );
                },
              ),

              // Layer 5: Toggle buttons (highest z-order)
              // Left panel toggle button
              Consumer<TerminalStationController>(
                builder: (context, controller, child) {
                  final panelWidth = controller.maintenanceModeEnabled
                      ? 300.0
                      : (controller.controlTableModeEnabled ? 380.0 : 320.0);
                  return Positioned(
                    left: _showLeftPanel ? panelWidth : 0,
                    top: 10,
                    child: Material(
                      elevation: 8,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      child: InkWell(
                        onTap: () =>
                            setState(() => _showLeftPanel = !_showLeftPanel),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            _showLeftPanel
                                ? Icons.chevron_left
                                : Icons.chevron_right,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Right panel toggle button
              Consumer<TerminalStationController>(
                builder: (context, controller, child) {
                  final panelWidth = controller.maintenanceModeEnabled
                      ? 320.0
                      : (controller.controlTableModeEnabled ? 380.0 : 320.0);
                  return Positioned(
                    right: _showRightPanel ? panelWidth : 0,
                    top: 10,
                child: Material(
                  elevation: 8,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  child: InkWell(
                    onTap: () =>
                        setState(() => _showRightPanel = !_showRightPanel),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        _showRightPanel
                            ? Icons.chevron_right
                            : Icons.chevron_left,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                  );
                },
              ),
            ],
          ),

          // Maintenance Mode Toolbar
          Consumer<TerminalStationController>(
            builder: (context, controller, child) {
              if (!controller.maintenanceModeEnabled) {
                return const SizedBox.shrink();
              }

              return Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: MaintenanceToolbar(
                  onSave: () => _handleMaintenanceSave(context),
                  onExport: () => _handleMaintenanceExport(context),
                  onImport: () => _handleMaintenanceImport(context),
                  onValidate: () => _handleMaintenanceValidation(context),
                ),
              );
            },
          ),

          // SPAD Alarm - overlay at top (Layer 6)
          Positioned(
            left: _showLeftPanel ? 320 : 0,
            right: _showRightPanel ? 320 : 0,
            top: 0,
            child: Consumer<TerminalStationController>(
              builder: (context, controller, _) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: controller.spadAlarmActive ? 80 : 0,
                  child: controller.spadAlarmActive
                      ? CollisionAlarmWidget(
                          isActive: controller.spadAlarmActive,
                          currentIncident: controller.currentSpadIncident,
                          onDismiss: () => controller.acknowledgeSPADAlarm(),
                          isSPAD: true,
                          trainStopId: controller.spadTrainStopId,
                        )
                      : const SizedBox.shrink(),
                );
              },
            ),
          ),

          // Collision Alarm - overlay below SPAD alarm (Layer 7)
          Positioned(
            left: _showLeftPanel ? 320 : 0,
            right: _showRightPanel ? 320 : 0,
            top: 0,
            child: Consumer<TerminalStationController>(
              builder: (context, controller, _) {
                final spadOffset = controller.spadAlarmActive ? 80.0 : 0.0;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.only(top: spadOffset),
                  height: controller.collisionAlarmActive ? 80 : 0,
                  child: controller.collisionAlarmActive
                      ? CollisionAlarmWidget(
                          isActive: controller.collisionAlarmActive,
                          currentIncident: controller.currentCollisionIncident,
                          onDismiss: () =>
                              controller.acknowledgeCollisionAlarm(),
                          onForceResolve: () {
                            controller.forceCollisionResolution();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🔄 Force recovery: Train moved back 100 units'),
                                backgroundColor: Colors.purple,
                                duration: Duration(seconds: 3),
                              ),
                            );
                          },
                          onRemoveTrains: () {
                            controller.removeCollisionTrains();
                          },
                        )
                      : const SizedBox.shrink(),
                );
              },
            ),
          ),

          // Top Control Panel - overlay (Layer 8)
          if (_showTopPanel)
            Positioned(
              left: _showLeftPanel ? 320 : 0,
              right: _showRightPanel ? 320 : 0,
              top: 0,
              child: Consumer<TerminalStationController>(
                builder: (context, controller, _) {
                  final spadOffset = controller.spadAlarmActive ? 80.0 : 0.0;
                  final collisionOffset =
                      controller.collisionAlarmActive ? 80.0 : 0.0;
                  return Container(
                    margin: EdgeInsets.only(top: spadOffset + collisionOffset),
                    child: _buildTopControlPanel(),
                  );
                },
              ),
            ),

          // AI Agent Panel - floating draggable assistant (Layer 9)
          Consumer<TerminalStationController>(
            builder: (context, controller, _) {
              return controller.aiAgentVisible
                  ? const AIAgentPanel()
                  : const SizedBox.shrink();
            },
          ),

          // Edit Mode Toolbar - bottom center (Layer 10)
          // Draggable Floating Add Train Button (Layer 11)
          Consumer<TerminalStationController>(
            builder: (context, controller, _) {
              return Positioned(
                left: _addTrainButtonPosition.dx,
                top: _addTrainButtonPosition.dy,
                child: Draggable(
                  feedback: Material(
                    elevation: 8,
                    shape: const CircleBorder(),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_circle,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  childWhenDragging: Container(),
                  onDragEnd: (details) {
                    setState(() {
                      _addTrainButtonPosition = details.offset;
                    });
                  },
                  child: Material(
                    elevation: 8,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: controller.editModeEnabled ? null : () => controller.addTrain(),
                      customBorder: const CircleBorder(),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: controller.editModeEnabled ? Colors.grey : Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_circle,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Draggable Floating Simulation Button (Layer 12)
          Consumer<TerminalStationController>(
            builder: (context, controller, _) {
              return Positioned(
                left: _simButtonOffset.dx,
                top: _simButtonOffset.dy,
                child: Draggable(
                  feedback: Material(
                    elevation: 8,
                    shape: const CircleBorder(),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: controller.isRunning ? Colors.orange.withOpacity(0.7) : Colors.green.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        controller.isRunning ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  childWhenDragging: Container(),
                  onDragEnd: (details) {
                    setState(() {
                      _simButtonOffset = details.offset;
                    });
                  },
                  child: Material(
                    elevation: 8,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () {
                        if (controller.isRunning) {
                          controller.pauseSimulation();
                        } else {
                          controller.startSimulation();
                        }
                      },
                      customBorder: const CircleBorder(),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: controller.isRunning ? Colors.orange : Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          controller.isRunning ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Dot Matrix Display moved to right sidebar (removed from here)
        ],
      ),
    ));
  }

  // NEW: Floating zoom controls
  Widget _buildFloatingZoomControls() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Zoom label
            Text(
              'Zoom: ${(_zoom * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            // Zoom in button
            FloatingActionButton.small(
              onPressed: _zoomIn,
              heroTag: 'zoom_in',
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              child: const Icon(Icons.zoom_in),
            ),
            const SizedBox(height: 8),
            // Zoom reset button
            FloatingActionButton.small(
              onPressed: _resetZoom,
              heroTag: 'zoom_reset',
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
              child: const Icon(Icons.refresh),
            ),
            const SizedBox(height: 8),
            // Zoom out button
            FloatingActionButton.small(
              onPressed: _zoomOut,
              heroTag: 'zoom_out',
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              child: const Icon(Icons.zoom_out),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainStopControls(TerminalStationController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Train Stop Controls',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        // Toggle all train stops
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  controller.trainStopsEnabled
                      ? Icons.flag
                      : Icons.flag_outlined,
                  color:
                      controller.trainStopsEnabled ? Colors.red : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'All Train Stops',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        controller.trainStopsEnabled ? 'Enabled' : 'Disabled',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: controller.trainStopsEnabled,
                  onChanged: (value) => controller.toggleAllTrainStops(),
                  activeColor: Colors.red,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Individual train stop controls
        const Text('Individual Train Stops:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: controller.trainStops.entries.map((entry) {
            final trainStop = entry.value;
            return Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: trainStop.active
                                ? Colors.red
                                : (trainStop.enabled
                                    ? Colors.green
                                    : Colors.grey),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          trainStop.id,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: trainStop.active
                                ? Colors.red
                                : (trainStop.enabled
                                    ? Colors.green
                                    : Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ElevatedButton(
                      onPressed: () => controller.toggleTrainStop(trainStop.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            trainStop.enabled ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: const Size(0, 30),
                      ),
                      child: Text(
                        trainStop.enabled ? 'DISABLE' : 'ENABLE',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 12),
        const Text(
          'Note: Train stops automatically activate when their associated signal is red. Manual trains must stop at active train stops.',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  // Top Control Panel Method
  Widget _buildTopControlPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: _topPanelHeight,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline,
                width: 2,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                spreadRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Consumer<TerminalStationController>(
            builder: (context, controller, _) {
              return Column(
                children: [
              // Header with close button
              Container(
                height: 16,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.3),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Quick Controls',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => setState(() => _showTopPanel = false),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Close Top Panel',
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Block Control Section (NEW - moved from left sidebar)
                        SizedBox(
                          width: 350,
                          child: const BlockControlPanel(),
                        ),

                        const VerticalDivider(width: 16),

                        // Canvas Theme Section
                        _buildCanvasThemeSection(),

                        const VerticalDivider(width: 16),

                        // Points Control Section
                        _buildTopPointsSection(controller),

                        const VerticalDivider(width: 16),

                        // Signal Control Section
                        _buildTopSignalsSection(controller),

                        const VerticalDivider(width: 16),

                        // Train Control Section
                        _buildTopTrainControls(controller),

                        const VerticalDivider(width: 16),

                        // Quick Actions Section
                        _buildTopQuickActions(controller),
                      ],
                    ),
                  ),
                ),
              ),
                ],
              );
            },
          ),
        ),
        // Drag handle for resizing top panel
        GestureDetector(
          onVerticalDragUpdate: (details) {
            setState(() {
              _topPanelHeight = (_topPanelHeight + details.delta.dy)
                  .clamp(_minTopPanelHeight, _maxTopPanelHeight);
            });
          },
          child: Container(
            height: 8,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Canvas Theme Section
  Widget _buildCanvasThemeSection() {
    return Consumer<CanvasThemeController>(
      builder: (context, canvasThemeController, _) {
        return SizedBox(
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.palette,
                      size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 4),
                  const Text(
                    'Canvas Theme',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: DropdownButton<CanvasTheme>(
                  value: canvasThemeController.currentTheme,
                  isExpanded: true,
                  underline: Container(),
                  style: const TextStyle(fontSize: 11),
                  items: CanvasTheme.values.map((theme) {
                    return DropdownMenuItem(
                      value: theme,
                      child: Text(
                        canvasThemeController.getThemeDisplayName(theme),
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (theme) {
                    if (theme != null) {
                      canvasThemeController.setCanvasTheme(theme);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPointControl(
    BuildContext context,
    TerminalStationController controller,
    String pointId, {
    bool isDeadlocked = false,
    String? deadlockReason,
  }) {
    final point = controller.points[pointId];
    if (point == null) return const SizedBox.shrink();

    final isLocked = isDeadlocked || point.locked;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                pointId,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isLocked ? Colors.red : Colors.black),
              ),
              if (isLocked) ...[
                const SizedBox(width: 4),
                const Icon(Icons.block, size: 10, color: Colors.red),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              ElevatedButton(
                onPressed: isLocked
                    ? null
                    : () {
                        point.position = PointPosition.normal;
                        controller.notifyListeners();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: point.position == PointPosition.normal
                      ? Colors.red
                      : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(40, 30),
                ),
                child: const Text('N', style: TextStyle(fontSize: 10)),
              ),
              const SizedBox(width: 4),
              ElevatedButton(
                onPressed: isLocked
                    ? null
                    : () {
                        point.position = PointPosition.reverse;
                        controller.notifyListeners();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: point.position == PointPosition.reverse
                      ? Colors.green
                      : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(40, 30),
                ),
                child: const Text('R', style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
          if (deadlockReason != null) ...[
            const SizedBox(height: 4),
            Text(
              deadlockReason,
              style: TextStyle(
                fontSize: 8,
                color: isLocked ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Top Panel Points Section
  Widget _buildTopPointsSection(TerminalStationController controller) {
    // Deadlock logic for 78A/B - AB104, AB106, AB107 removed
    final ab109Occupied = controller.ace.isABOccupied('AB109');
    final anyABDeadlock = ab109Occupied;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Points Control',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            if (anyABDeadlock) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'AB DEADLOCKED',
                  style: TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // 76A/B
              _buildPointControl(context, controller, '76A'),
              _buildPointControl(context, controller, '76B'),
              // 77A/B
              _buildPointControl(context, controller, '77A'),
              _buildPointControl(context, controller, '77B'),
              // 78A/B (with specific deadlock logic)
              _buildPointControl(
                context,
                controller,
                '78A',
                isDeadlocked: false, // AB104, AB106 removed
                deadlockReason: 'Free',
              ),
              _buildPointControl(
                context,
                controller,
                '78B',
                isDeadlocked: ab109Occupied,
                deadlockReason: ab109Occupied ? 'AB109 Occ' : 'Free',
              ),
              // 79A/B
              _buildPointControl(context, controller, '79A'),
              _buildPointControl(context, controller, '79B'),
              // 80A/B
              _buildPointControl(context, controller, '80A'),
              _buildPointControl(context, controller, '80B'),
            ],
          ),
        ),
      ],
    );
  }

  // Top Panel Signals Section
  Widget _buildTopSignalsSection(TerminalStationController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Signal Control',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: controller.signals.entries.map((entry) {
            final signal = entry.value;
            return Column(
              children: [
                // Signal ID and Aspect
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: signal.aspect == SignalAspect.green
                            ? Colors.green
                            : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      signal.id,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Route Buttons
                Column(
                  children: signal.routes.map((route) {
                    final isActive = signal.activeRouteId == route.id;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      child: ElevatedButton(
                        onPressed: isActive
                            ? null
                            : () => controller.setRoute(signal.id, route.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isActive ? Colors.blue : Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          minimumSize: const Size(0, 24),
                        ),
                        child: Text(
                          route.name.split(' ').first,
                          style: const TextStyle(fontSize: 9),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                // Release Button for active routes
                if (signal.activeRouteId != null)
                  ElevatedButton(
                    onPressed: () => controller.releaseRoute(signal.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      minimumSize: const Size(0, 20),
                    ),
                    child: const Text('RELEASE', style: TextStyle(fontSize: 8)),
                  ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // Top Panel Train Controls
  Widget _buildTopTrainControls(TerminalStationController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Train Control',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Container(
          width: 300,
          height: 160,
          child: ListView(
            scrollDirection: Axis.vertical,
            children: controller.trains.map((train) {
              final platformId = _getPlatformForTrain(train);
              final canOpenDoors = platformId != null;
              final hasEmergencyBrake = train.emergencyBrake;

              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: train.controlMode == TrainControlMode.manual
                      ? Colors.blue.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Train Info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: train.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              train.name,
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              train.direction > 0
                                  ? Icons.arrow_forward
                                  : Icons.arrow_back,
                              size: 10,
                              color: train.direction > 0
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            if (hasEmergencyBrake) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.emergency,
                                  size: 10, color: Colors.red),
                            ],
                          ],
                        ),
                        Text(
                          'Block: ${train.currentBlockId ?? "N/A"}',
                          style: const TextStyle(fontSize: 9),
                        ),
                        Text(
                          'Speed: ${train.speed.toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 9),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: train.controlMode == TrainControlMode.manual
                                ? Colors.blue
                                : Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            train.controlMode == TrainControlMode.manual
                                ? 'MANUAL'
                                : 'AUTO',
                            style: const TextStyle(
                                fontSize: 8, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // Train Controls
                    Column(
                      children: [
                        // Emergency Brake Reset Button
                        if (hasEmergencyBrake) ...[
                          ElevatedButton(
                            onPressed: () =>
                                controller.resetTrainEmergencyBrake(train.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              minimumSize: const Size(0, 20),
                            ),
                            child: const Text('RESET BRAKE',
                                style: TextStyle(fontSize: 8)),
                          ),
                          const SizedBox(height: 2),
                        ],

                        // Mode Toggle
                        ElevatedButton(
                          onPressed: () => controller.toggleTrainMode(train.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                train.controlMode == TrainControlMode.manual
                                    ? Colors.blue
                                    : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            minimumSize: const Size(0, 20),
                          ),
                          child: Text(
                            train.controlMode == TrainControlMode.manual
                                ? 'AUTO'
                                : 'MAN',
                            style: const TextStyle(fontSize: 8),
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Movement Controls
                        Row(
                          children: [
                            if (train.controlMode ==
                                TrainControlMode.automatic) ...[
                              // Auto Mode Controls
                              ElevatedButton(
                                onPressed: () =>
                                    controller.departAutoTrain(train.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  minimumSize: const Size(0, 18),
                                ),
                                child: const Text('GO',
                                    style: TextStyle(fontSize: 8)),
                              ),
                              const SizedBox(width: 2),
                              ElevatedButton(
                                onPressed: () => controller
                                    .emergencyBrakeAutoTrain(train.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  minimumSize: const Size(0, 18),
                                ),
                                child: const Text('STOP',
                                    style: TextStyle(fontSize: 8)),
                              ),
                            ] else ...[
                              // Manual Mode Controls
                              ElevatedButton(
                                onPressed: () =>
                                    controller.departTrain(train.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  minimumSize: const Size(0, 18),
                                ),
                                child: const Text('GO',
                                    style: TextStyle(fontSize: 8)),
                              ),
                              const SizedBox(width: 2),
                              ElevatedButton(
                                onPressed: () => controller.stopTrain(train.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  minimumSize: const Size(0, 18),
                                ),
                                child: const Text('STOP',
                                    style: TextStyle(fontSize: 8)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        // Additional Controls
                        Row(
                          children: [
                            // Door Control
                            ElevatedButton(
                              onPressed: canOpenDoors
                                  ? () => controller.toggleTrainDoors(train.id)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: train.doorsOpen
                                    ? Colors.orange
                                    : Colors.purple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                minimumSize: const Size(0, 18),
                              ),
                              child: Text(
                                train.doorsOpen ? 'CLOSE' : 'OPEN',
                                style: const TextStyle(fontSize: 8),
                              ),
                            ),
                            const SizedBox(width: 2),
                            ElevatedButton(
                              onPressed: () =>
                                  controller.reverseTrain(train.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                minimumSize: const Size(0, 18),
                              ),
                              child: const Text('REV',
                                  style: TextStyle(fontSize: 8)),
                            ),
                            const SizedBox(width: 2),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 12),
                              onPressed: () => controller.removeTrain(train.id),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Remove Train',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Top Panel Quick Actions
  Widget _buildTopQuickActions(TerminalStationController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Signal Visibility Toggle
            ElevatedButton(
              onPressed: () => controller.toggleSignalsVisibility(),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    controller.signalsVisible ? Colors.green : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 30),
              ),
              child: Text(
                'Signals: ${controller.signalsVisible ? 'ON' : 'OFF'}',
                style: const TextStyle(fontSize: 10),
              ),
            ),
            // Self-normalizing Points Toggle
            ElevatedButton(
              onPressed: () => controller.toggleSelfNormalizingPoints(),
              style: ElevatedButton.styleFrom(
                backgroundColor: controller.selfNormalizingPoints
                    ? Colors.green
                    : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 30),
              ),
              child: Text(
                'Self-Norm: ${controller.selfNormalizingPoints ? 'ON' : 'OFF'}',
                style: const TextStyle(fontSize: 10),
              ),
            ),
            // Add Train Button - DISABLED in edit mode
            ElevatedButton(
              onPressed: controller.editModeEnabled ? null : () => controller.addTrain(),
              style: ElevatedButton.styleFrom(
                backgroundColor: controller.editModeEnabled ? Colors.grey : Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 30),
              ),
              child: const Text('Add Train', style: TextStyle(fontSize: 10)),
            ),
            // Start/Stop Simulation
            ElevatedButton(
              onPressed: controller.isRunning
                  ? controller.pauseSimulation
                  : controller.startSimulation,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    controller.isRunning ? Colors.orange : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 30),
              ),
              child: Text(
                controller.isRunning ? 'Pause' : 'Start',
                style: const TextStyle(fontSize: 10),
              ),
            ),
            // Reset Simulation
            ElevatedButton(
              onPressed: controller.resetSimulation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 30),
              ),
              child: const Text('Reset', style: TextStyle(fontSize: 10)),
            ),
            // NEW: Canvas size quick controls
            ElevatedButton(
              onPressed: _increaseCanvasWidth,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 30),
              ),
              child: const Text('Width+', style: TextStyle(fontSize: 10)),
            ),
            ElevatedButton(
              onPressed: _decreaseCanvasWidth,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 30),
              ),
              child: const Text('Width-', style: TextStyle(fontSize: 10)),
            ),
            ElevatedButton(
              onPressed: _increaseCanvasHeight,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 30),
              ),
              child: const Text('Height+', style: TextStyle(fontSize: 10)),
            ),
            ElevatedButton(
              onPressed: _decreaseCanvasHeight,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 30),
              ),
              child: const Text('Height-', style: TextStyle(fontSize: 10)),
            ),
            ElevatedButton(
              onPressed: _resetCanvasSize,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 30),
              ),
              child: const Text('Reset Canvas', style: TextStyle(fontSize: 10)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlPanel() {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
            right: BorderSide(color: Theme.of(context).colorScheme.outline)),
      ),
      child: Consumer<TerminalStationController>(
        builder: (context, controller, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Simulation Controls
              Text('Simulation',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // Signal Visibility Toggle
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        controller.signalsVisible
                            ? Icons.traffic
                            : Icons.traffic_outlined,
                        color: controller.signalsVisible
                            ? Colors.green
                            : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Signals',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              controller.signalsVisible ? 'Visible' : 'Hidden',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: controller.signalsVisible,
                        onChanged: (value) =>
                            controller.toggleSignalsVisibility(),
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Grid Toggle
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        controller.gridVisible ? Icons.grid_on : Icons.grid_off,
                        color:
                            controller.gridVisible ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Grid',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              controller.gridVisible ? 'Visible' : 'Hidden',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: controller.gridVisible,
                        onChanged: (value) => controller.toggleGrid(),
                        activeColor: Colors.blue,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Traction Current Toggle
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        controller.tractionCurrentOn
                            ? Icons.bolt
                            : Icons.bolt_outlined,
                        color: controller.tractionCurrentOn
                            ? Colors.amber
                            : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Traction Current',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              controller.tractionCurrentOn ? 'ON' : 'OFF',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: controller.tractionCurrentOn,
                        onChanged: (value) =>
                            controller.toggleTractionCurrent(),
                        activeColor: Colors.amber,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Tooltips Toggle
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        controller.tooltipsEnabled
                            ? Icons.info
                            : Icons.info_outline,
                        color: controller.tooltipsEnabled
                            ? Colors.purple
                            : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tooltips',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              controller.tooltipsEnabled
                                  ? 'Enabled'
                                  : 'Disabled',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: controller.tooltipsEnabled,
                        onChanged: (value) => controller.toggleTooltips(),
                        activeColor: Colors.purple,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // AI Agent Toggle
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        controller.aiAgentVisible
                            ? Icons.smart_toy
                            : Icons.smart_toy_outlined,
                        color: controller.aiAgentVisible
                            ? Colors.cyan
                            : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AI Agent',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              controller.aiAgentVisible ? 'Visible' : 'Hidden',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: controller.aiAgentVisible,
                        onChanged: (value) => controller.toggleAiAgent(),
                        activeColor: Colors.cyan,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Relay Rack Toggle
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        controller.relayRackVisible
                            ? Icons.electrical_services
                            : Icons.electrical_services_outlined,
                        color: controller.relayRackVisible
                            ? Colors.orange
                            : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Relay Rack',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              controller.relayRackVisible
                                  ? 'Visible'
                                  : 'Hidden',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: controller.relayRackVisible,
                        onChanged: (value) => controller.toggleRelayRack(),
                        activeColor: Colors.orange,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Audio Toggle
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        SoundService().isEnabled
                            ? Icons.volume_up
                            : Icons.volume_off,
                        color: SoundService().isEnabled
                            ? Colors.blue
                            : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Audio',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              SoundService().isEnabled ? 'Unmuted' : 'Muted',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: SoundService().isEnabled,
                        onChanged: (value) {
                          setState(() {
                            SoundService().setEnabled(value);
                          });
                        },
                        activeColor: Colors.blue,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Voice Wake Word Toggles
              Consumer<WidgetPreferencesService>(
                builder: (context, prefs, _) {
                  return Column(
                    children: [
                      // Search Wake Word Toggle
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(
                                prefs.searchWakeWordEnabled
                                    ? Icons.search
                                    : Icons.search_off,
                                color: prefs.searchWakeWordEnabled
                                    ? Colors.purple
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Search Wake Word',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      prefs.searchWakeWordEnabled
                                          ? 'Say "search for"'
                                          : 'Disabled',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: prefs.searchWakeWordEnabled,
                                onChanged: (value) =>
                                    prefs.setSearchWakeWordEnabled(value),
                                activeColor: Colors.purple,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // SSM Wake Word Toggle
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(
                                prefs.ssmWakeWordEnabled
                                    ? Icons.smart_toy
                                    : Icons.smart_toy_outlined,
                                color: prefs.ssmWakeWordEnabled
                                    ? Colors.cyan
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'SSM Wake Word',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      prefs.ssmWakeWordEnabled
                                          ? 'Say "SSM"'
                                          : 'Disabled',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: prefs.ssmWakeWordEnabled,
                                onChanged: (value) =>
                                    prefs.setSsmWakeWordEnabled(value),
                                activeColor: Colors.cyan,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.isRunning
                          ? controller.pauseSimulation
                          : controller.startSimulation,
                      icon: Icon(controller.isRunning
                          ? Icons.pause
                          : Icons.play_arrow),
                      label: Text(controller.isRunning ? 'Pause' : 'Start'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            controller.isRunning ? Colors.orange : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.stop),
                    color: Colors.red,
                    onPressed: controller.resetSimulation,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Speed: ${controller.simulationSpeed.toStringAsFixed(1)}x'),
              Slider(
                value: controller.simulationSpeed,
                min: 0.1,
                max: 3.0,
                onChanged: controller.setSimulationSpeed,
              ),

              // Self-normalizing points toggle
              Row(
                children: [
                  const Text('Self-normalizing Points:'),
                  const Spacer(),
                  Switch(
                    value: controller.selfNormalizingPoints,
                    onChanged: (value) =>
                        controller.toggleSelfNormalizingPoints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Timetable toggle
              Card(
                color: controller.timetableActive ? Colors.green[50] : null,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: controller.timetableActive
                            ? Colors.green
                            : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Auto Timetable Service',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              controller.timetableActive
                                  ? 'Active - Trains auto-dispatch'
                                  : 'Inactive',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: controller.timetableActive,
                        onChanged: (value) =>
                            controller.toggleTimetableActive(),
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // FIXED: CBTC Controls Section
              Text('CBTC (Communications-Based Train Control)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // CBTC Device toggle
                      Row(
                        children: [
                          Icon(
                            Icons.radio,
                            color: controller.cbtcDevicesEnabled
                                ? Colors.blue
                                : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CBTC Devices',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  controller.cbtcDevicesEnabled
                                      ? 'Enabled (Transponders + WiFi)'
                                      : 'Disabled',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: controller.cbtcDevicesEnabled,
                            onChanged: (value) =>
                                controller.toggleCbtcDevices(value),
                            activeColor: Colors.blue,
                          ),
                        ],
                      ),
                      const Divider(),
                      // CBTC Mode toggle
                      Row(
                        children: [
                          Icon(
                            Icons.settings_input_antenna,
                            color: controller.cbtcModeActive
                                ? Colors.green
                                : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CBTC Mode (Moving Block)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  controller.cbtcModeActive
                                      ? 'Active - Signals Blue'
                                      : 'Inactive - Fixed Block',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: controller.cbtcModeActive,
                            onChanged: controller.cbtcDevicesEnabled
                                ? (value) => controller.toggleCbtcMode(value)
                                : null,
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 32),

              // Smart Train Addition
              _buildAddTrainSection(controller),
              const Divider(height: 32),

              // Point Control Panel
              _buildPointControlPanel(controller),
              const Divider(height: 32),

              // WiFi Control Panel
              _buildWiFiControlPanel(controller),
              const Divider(height: 32),

              // Timetable Management Panel
              _buildTimetableManagementPanel(controller),
              const Divider(height: 32),

              // Axle Counter Controls
              _buildAxleCounterControlsSection(controller),
              const Divider(height: 32),

              // AB Reset Controls
              _buildABResetSection(controller),
              const Divider(height: 32),

              // Enhanced Train Management Section
              Text('Train Management',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // Simulation Timer
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Text('Simulation Timer',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800])),
                      const SizedBox(height: 8),
                      Text(controller.getFormattedRunningTime(),
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace')),
                      const SizedBox(height: 4),
                      Text('Running Time',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Quick Train Actions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick Actions',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: controller.trains.isNotEmpty
                                ? () {
                                    for (var train in controller.trains) {
                                      if (train.controlMode ==
                                          TrainControlMode.automatic) {
                                        controller.departAutoTrain(train.id);
                                      } else {
                                        controller.departTrain(train.id);
                                      }
                                    }
                                  }
                                : null,
                            icon: const Icon(Icons.play_arrow, size: 16),
                            label: const Text('All Go'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: controller.trains.isNotEmpty
                                ? () {
                                    for (var train in controller.trains) {
                                      controller.stopTrain(train.id);
                                    }
                                  }
                                : null,
                            icon: const Icon(Icons.stop, size: 16),
                            label: const Text('All Stop'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: controller.trains.isNotEmpty
                                ? () {
                                    for (var train in controller.trains) {
                                      if (train.emergencyBrake) {
                                        controller
                                            .resetTrainEmergencyBrake(train.id);
                                      }
                                    }
                                  }
                                : null,
                            icon: const Icon(Icons.emergency, size: 16),
                            label: const Text('Reset All E-Brake'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Train Statistics
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Train Statistics',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Trains:', style: TextStyle(fontSize: 12)),
                          Text('${controller.trains.length}',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Auto Mode:', style: TextStyle(fontSize: 12)),
                          Text(
                              '${controller.trains.where((t) => t.controlMode == TrainControlMode.automatic).length}',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Manual Mode:', style: TextStyle(fontSize: 12)),
                          Text(
                              '${controller.trains.where((t) => t.controlMode == TrainControlMode.manual).length}',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Moving:', style: TextStyle(fontSize: 12)),
                          Text(
                              '${controller.trains.where((t) => t.speed > 0).length}',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Stopped:', style: TextStyle(fontSize: 12)),
                          Text(
                              '${controller.trains.where((t) => t.speed == 0).length}',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Emergency Brake:',
                              style: TextStyle(fontSize: 12)),
                          Text(
                              '${controller.trains.where((t) => t.emergencyBrake).length}',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Individual Train Controls
              Text('Individual Train Controls',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              ...controller.trains.map((train) => Card(
                    color: train.controlMode == TrainControlMode.manual
                        ? Colors.blue.shade50
                        : Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Train Header
                          Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: train.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  train.name,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Icon(
                                train.direction > 0
                                    ? Icons.arrow_forward
                                    : Icons.arrow_back,
                                size: 16,
                                color: train.direction > 0
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              if (train.emergencyBrake)
                                Icon(Icons.emergency,
                                    size: 16, color: Colors.red),
                              if (train.doorsOpen)
                                Icon(Icons.door_sliding,
                                    size: 16, color: Colors.orange),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Train Status Info
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Block: ${train.currentBlockId ?? "N/A"}',
                                        style: const TextStyle(fontSize: 11)),
                                    Text(
                                        'Speed: ${train.speed.toStringAsFixed(1)}',
                                        style: const TextStyle(fontSize: 11)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: train.controlMode ==
                                          TrainControlMode.manual
                                      ? Colors.blue
                                      : Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  train.controlMode == TrainControlMode.manual
                                      ? 'MANUAL'
                                      : 'AUTO',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Enhanced Train Controls Section
                          // Train Type Selector
                          Row(
                            children: [
                              const Text('Type: ',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButton<TrainType>(
                                    value: train.trainType,
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.black),
                                    items: TrainType.values.map((type) {
                                      return DropdownMenuItem(
                                        value: type,
                                        child: Text(_getTrainTypeName(type)),
                                      );
                                    }).toList(),
                                    onChanged: (newType) {
                                      if (newType != null) {
                                        controller.updateTrainType(
                                            train.id, newType);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // CBTC Mode Selector (only for CBTC trains)
                          if (train.isCbtcTrain) ...[
                            Row(
                              children: [
                                const Text('CBTC Mode: ',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getCbtcModeColor(train.cbtcMode)
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButton<CbtcMode>(
                                      value: train.cbtcMode,
                                      isExpanded: true,
                                      underline: const SizedBox(),
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.black),
                                      items: CbtcMode.values.map((mode) {
                                        return DropdownMenuItem(
                                          value: mode,
                                          child: Text(_getCbtcModeName(mode)),
                                        );
                                      }).toList(),
                                      onChanged: (newMode) {
                                        if (newMode != null) {
                                          controller.updateTrainCbtcMode(
                                              train.id, newMode);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],

                          // Destination Control
                          Row(
                            children: [
                              const Text('Dest: ',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButton<String>(
                                    value: train.smcDestination,
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    hint: const Text('Set destination',
                                        style: TextStyle(fontSize: 11)),
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.black),
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('None'),
                                      ),
                                      ..._getDestinationOptions(),
                                    ],
                                    onChanged: (destination) {
                                      controller.setTrainDestination(
                                          train.id, destination);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Control Buttons - Row 1: Mode and Movement
                          Row(
                            children: [
                              // Mode Toggle
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      controller.toggleTrainMode(train.id),
                                  icon: Icon(
                                    train.controlMode == TrainControlMode.manual
                                        ? Icons.smart_toy
                                        : Icons.gamepad,
                                    size: 14,
                                  ),
                                  label: Text(
                                    train.controlMode == TrainControlMode.manual
                                        ? 'Auto'
                                        : 'Manual',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: train.controlMode ==
                                            TrainControlMode.manual
                                        ? Colors.blue
                                        : Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 6),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),

                              // Movement Controls
                              if (train.controlMode ==
                                  TrainControlMode.automatic) ...[
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        controller.departAutoTrain(train.id),
                                    icon:
                                        const Icon(Icons.play_arrow, size: 14),
                                    label: const Text('Go',
                                        style: TextStyle(fontSize: 11)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 6),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => controller
                                        .emergencyBrakeAutoTrain(train.id),
                                    icon: const Icon(Icons.emergency, size: 14),
                                    label: const Text('E-Stop',
                                        style: TextStyle(fontSize: 11)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 6),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        controller.departTrain(train.id),
                                    icon:
                                        const Icon(Icons.play_arrow, size: 14),
                                    label: const Text('Go',
                                        style: TextStyle(fontSize: 11)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 6),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        controller.stopTrain(train.id),
                                    icon: const Icon(Icons.stop, size: 14),
                                    label: const Text('Stop',
                                        style: TextStyle(fontSize: 11)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 6),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Control Buttons - Row 2: Additional Controls
                          Row(
                            children: [
                              // Door Control
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _getPlatformForTrain(train) != null
                                      ? () =>
                                          controller.toggleTrainDoors(train.id)
                                      : null,
                                  icon: Icon(
                                    train.doorsOpen
                                        ? Icons.door_sliding
                                        : Icons.door_front_door,
                                    size: 14,
                                  ),
                                  label: Text(
                                    train.doorsOpen ? 'Close' : 'Open',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: train.doorsOpen
                                        ? Colors.orange
                                        : Colors.purple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 6),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),

                              // Reverse
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      controller.reverseTrain(train.id),
                                  icon: const Icon(Icons.swap_horiz, size: 14),
                                  label: const Text('Reverse',
                                      style: TextStyle(fontSize: 11)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 6),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),

                              // Emergency Brake Reset
                              if (train.emergencyBrake)
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => controller
                                        .resetTrainEmergencyBrake(train.id),
                                    icon: const Icon(Icons.emergency, size: 14),
                                    label: const Text('Reset',
                                        style: TextStyle(fontSize: 11)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 6),
                                    ),
                                  ),
                                )
                              else
                                const Expanded(child: SizedBox()),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Control Buttons - Row 3: Delete
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      controller.removeTrain(train.id),
                                  icon: const Icon(Icons.delete,
                                      size: 14, color: Colors.red),
                                  label: const Text('Remove Train',
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.red)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.red),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),
              const Divider(height: 32),

              // Points Control
              Text('Points Control',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...controller.points.entries.map((entry) {
                final point = entry.value;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: point.position == PointPosition.normal
                                    ? Colors.red
                                    : Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(point.id,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Icon(
                              point.locked ? Icons.lock : Icons.lock_open,
                              size: 16,
                              color: point.locked ? Colors.red : Colors.green,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    controller.togglePointLock(point.id),
                                child: Text(point.locked ? 'UNLOCK' : 'LOCK'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: point.locked
                                    ? null
                                    : () {
                                        // Manual point control
                                        final newPosition = point.position ==
                                                PointPosition.normal
                                            ? PointPosition.reverse
                                            : PointPosition.normal;
                                        point.position = newPosition;
                                        controller.notifyListeners();
                                      },
                                child: Text(
                                    point.position == PointPosition.normal
                                        ? 'REVERSE'
                                        : 'NORMAL'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const Divider(height: 32),
              _buildTrainStopControls(controller),

              // Route Setting Controls
              Text('Route Setting',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...controller.signals.entries.map((entry) {
                final signal = entry.value;
                if (signal.routes.isEmpty) return const SizedBox.shrink();

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: signal.aspect == SignalAspect.green
                                    ? Colors.green
                                    : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(signal.id,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...signal.routes.map((route) {
                          final isActive = signal.activeRouteId == route.id;
                          final isPendingCancellation =
                              controller.isRoutePendingCancellation(signal.id);

                          Color buttonColor;
                          if (isPendingCancellation) {
                            buttonColor = Colors.yellow[700]!;
                          } else if (isActive) {
                            buttonColor = Colors.blue.shade100;
                          } else {
                            buttonColor = Colors.orange;
                          }

                          return InkWell(
                            onTap: isActive
                                ? () => controller.cancelRoute(signal.id)
                                : () =>
                                    controller.setRoute(signal.id, route.id),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: buttonColor,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isActive
                                      ? Colors.blue
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      route.name,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: isPendingCancellation
                                              ? Colors.brown[900]
                                              : isActive
                                                  ? Colors.blue
                                                  : Colors.brown[900]),
                                    ),
                                  ),
                                  if (isPendingCancellation)
                                    const Icon(Icons.access_time,
                                        size: 12, color: Colors.brown),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }),

              const Divider(height: 32),

              // Camera Controls
              Text('View',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _cameraOffsetX += 200),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('←'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _cameraOffsetX -= 200),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('→'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _zoomIn,
                      icon: const Icon(Icons.zoom_in),
                      label: const Text('+'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _zoomOut,
                      icon: const Icon(Icons.zoom_out),
                      label: const Text('-'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Export Layout Button
              ElevatedButton.icon(
                onPressed: () => _exportLayout(controller),
                icon: const Icon(Icons.download),
                label: const Text('Export Layout XML'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // NEW: Canvas controls section for the control panel
  Widget _buildCanvasControlsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Canvas Size Controls',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        // Current Dimensions
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Width:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${_canvasWidth.toInt()} px',
                        style: const TextStyle(fontFamily: 'monospace')),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Height:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${_canvasHeight.toInt()} px',
                        style: const TextStyle(fontFamily: 'monospace')),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Zoom:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${(_zoom * 100).toInt()}%',
                        style: const TextStyle(fontFamily: 'monospace')),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Width Controls
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Canvas Width',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _decreaseCanvasWidth,
                        icon: const Icon(Icons.remove, size: 16),
                        label: const Text('Decrease Width'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _increaseCanvasWidth,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Increase Width'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Height Controls
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Canvas Height',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _decreaseCanvasHeight,
                        icon: const Icon(Icons.remove, size: 16),
                        label: const Text('Decrease Height'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _increaseCanvasHeight,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Increase Height'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Reset Button
        ElevatedButton.icon(
          onPressed: _resetCanvasSize,
          icon: const Icon(Icons.restart_alt),
          label: const Text('Reset Canvas to Default Size'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 40),
          ),
        ),

        const SizedBox(height: 8),
        const Text(
          'Note: Increasing canvas size provides more space for trains to move. '
          'Decreasing size creates a more compact view.',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildAddTrainSection(TerminalStationController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Add Train to Block',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        // Train Type Selector
        const Text('Train Type:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        DropdownButton<TrainType>(
          isExpanded: true,
          value: _selectedTrainType,
          items: TrainType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(_getTrainTypeDisplayName(type)),
            );
          }).toList(),
          onChanged: (type) {
            if (type != null) {
              setState(() {
                _selectedTrainType = type;
              });
            }
          },
        ),
        const SizedBox(height: 12),

        // Block Selector
        const Text('Target Block:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        DropdownButton<String>(
          isExpanded: true,
          hint: const Text('Select Safe Block'),
          value: _selectedBlockForTrain,
          items: controller.getSafeBlocksForTrainAdd().map((blockId) {
            return DropdownMenuItem(
              value: blockId,
              child: Text('Block $blockId'),
            );
          }).toList(),
          onChanged: (blockId) {
            setState(() {
              _selectedBlockForTrain = blockId;
            });
          },
        ),
        const SizedBox(height: 12),

        // Destination Selector
        const Text('Destination (Optional):',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        DropdownButton<String>(
          isExpanded: true,
          hint: const Text('No Destination'),
          value: _selectedDestination,
          items: [
            const DropdownMenuItem(value: null, child: Text('No Destination')),
            ...controller.blocks.keys.map((blockId) {
              return DropdownMenuItem(
                value: 'B:$blockId',
                child: Text('Block $blockId'),
              );
            }),
            ...controller.platforms.map((platform) {
              return DropdownMenuItem(
                value: 'P:${platform.id}',
                child: Text(platform.name),
              );
            }),
          ],
          onChanged: (dest) {
            setState(() {
              _selectedDestination = dest;
            });
          },
        ),
        const SizedBox(height: 12),

        // Timetable Assignment Checkbox
        CheckboxListTile(
          title:
              const Text('Assign to Timetable', style: TextStyle(fontSize: 12)),
          subtitle: Text(
            _assignToTimetable
                ? 'Auto-assign to next ghost train slot'
                : 'Manual operation',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
          value: _assignToTimetable,
          onChanged: (value) {
            setState(() {
              _assignToTimetable = value ?? false;
            });
          },
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 8),

        // Add Train Button
        ElevatedButton.icon(
          onPressed: _selectedBlockForTrain != null
              ? () {
                  controller.addTrainToBlock(
                    _selectedBlockForTrain!,
                    trainType: _selectedTrainType,
                    destination: _selectedDestination,
                    assignToTimetable: _assignToTimetable,
                  );
                  setState(() {
                    _selectedBlockForTrain = null;
                    _selectedDestination = null;
                    _selectedTrainType = TrainType.m1;
                    _assignToTimetable = false;
                  });
                }
              : null,
          icon: const Icon(Icons.add),
          label: Text(_selectedBlockForTrain != null
              ? 'Add ${_getTrainTypeDisplayName(_selectedTrainType)} to Block $_selectedBlockForTrain'
              : 'Select a Block First'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
        if (controller.getSafeBlocksForTrainAdd().isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'No safe blocks available',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
      ],
    );
  }

  String _getTrainTypeDisplayName(TrainType type) {
    switch (type) {
      case TrainType.m1:
        return 'M1 (Single Unit - 2 wheels)';
      case TrainType.m2:
        return 'M2 (Double Unit - 4 wheels)';
      case TrainType.cbtcM1:
        return 'CBTC M1 (Single Unit - 2 wheels)';
      case TrainType.cbtcM2:
        return 'CBTC M2 (Double Unit - 4 wheels)';
        case TrainType.m4:
        return 'M4 (Single Unit - 8 wheels)';
      case TrainType.m8:
        return 'M8 (Double Unit - 16 wheels)';
      case TrainType.cbtcM4:
        return 'CBTC M4 (Single Unit - 8 wheels)';
      case TrainType.cbtcM8:
        return 'CBTC M8 (Double Unit - 16 wheels)';
    }
  }

  Widget _buildAxleCounterControlsSection(
      TerminalStationController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Axle Counter System',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        // Toggle axle counter visibility
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  controller.axleCountersVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: controller.axleCountersVisible
                      ? Colors.green
                      : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Axle Counters',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        controller.axleCountersVisible ? 'Visible' : 'Hidden',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: controller.axleCountersVisible,
                  onChanged: (value) =>
                      controller.toggleAxleCounterVisibility(),
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Display axle counter counts
        if (controller.axleCountersVisible) ...[
          const Text(
            'Axle Counter Readings:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: controller.axleCounters.entries.map((entry) {
              final counter = entry.value;
              final displayId = counter.twinLabel ?? counter.id;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      counter.count > 0 ? Colors.purple[50] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: counter.count > 0
                        ? const Color.fromARGB(255, 161, 85, 175)
                        : Colors.grey,
                    width: 2,
                  ),
                ),
                child: Text(
                  '$displayId: ${counter.count}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: counter.count > 0
                        ? Colors.purple[900]
                        : Colors.grey[700],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildABResetSection(TerminalStationController controller) {
    final abList = [
      'AB100',
      'AB105',
      'AB106',
      'AB108',
      'AB111'
    ]; // Updated AB sections

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('AB Occupation Reset',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Reset individual AB occupations and their associated axle counters:',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),

        // AB Reset Cards
        ...abList.map((abId) {
          final isOccupied = controller.ace.isABOccupied(abId);
          final count = controller.ace.abResults[abId] ?? 0;

          return Card(
            color: isOccupied ? Colors.purple[50] : Colors.grey[100],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // AB Status Indicator
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isOccupied ? Colors.purple : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // AB Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          abId,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isOccupied
                                ? Colors.purple[900]
                                : Colors.grey[700],
                          ),
                        ),
                        Text(
                          'Count: $count ${isOccupied ? "(OCCUPIED)" : "(Clear)"}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Reset Button
                  ElevatedButton.icon(
                    onPressed: isOccupied
                        ? () => controller.resetIndividualAB(abId)
                        : null,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reset'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),

        const SizedBox(height: 12),

        // Reset All Button
        ElevatedButton.icon(
          onPressed: () => controller.resetACE(),
          icon: const Icon(Icons.restart_alt),
          label: const Text('Reset All Axle Counters'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 40),
          ),
        ),
      ],
    );
  }

  /// Convert screen/local coordinates to canvas coordinates
  /// Handles different coordinate systems for normal vs edit mode
  Offset _screenToCanvasCoords(Offset localPosition, bool isEditMode) {
    if (isEditMode) {
      // In edit mode, the painter transformation combined with the camera offset logic
      // results in a simple mapping: localPosition = canvasCoord * zoom + scrollOffset.
      // So canvasCoord = (localPosition - scrollOffset) / zoom.
      
      final scrollOffsetX = _horizontalScrollController.hasClients
          ? _horizontalScrollController.offset
          : 0.0;
      final scrollOffsetY = _verticalScrollController.hasClients
          ? _verticalScrollController.offset
          : 0.0;
      
      final canvasX = (localPosition.dx - scrollOffsetX) / _zoom;
      final canvasY = (localPosition.dy - scrollOffsetY) / _zoom;
      return Offset(canvasX, canvasY);
    } else {
      // Normal mode uses centered canvas with pan/zoom
      final canvasX = (localPosition.dx - (_canvasWidth / 2)) / _zoom - _cameraOffsetX;
      final canvasY = (localPosition.dy - (_canvasHeight / 2)) / _zoom - _cameraOffsetY;
      return Offset(canvasX, canvasY);
    }
  }

  /// Calculate Euclidean distance between two points
  double _calculateDistance(double x1, double y1, double x2, double y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Find the closest component to the given canvas coordinates
  /// Returns a map with 'type', 'id', and 'distance' keys, or null if no component is within range
  Map<String, dynamic>? _findClosestComponent(
    TerminalStationController controller,
    double canvasX,
    double canvasY,
  ) {
    Map<String, dynamic>? closest;
    double minDistance = double.infinity;

    // Check signals
    for (final signal in controller.signals.values) {
      if (!controller.maintenanceModeEnabled && !signal.commissioned) {
        continue;
      }
      final distance = _calculateDistance(canvasX, canvasY, signal.x, signal.y);
      if (distance < _hitRadiusSignal && distance < minDistance) {
        minDistance = distance;
        closest = {
          'type': 'signal',
          'id': signal.id,
          'distance': distance,
          'x': signal.x,
          'y': signal.y,
        };
      }
    }

    // Check points
    for (final point in controller.points.values) {
      final distance = _calculateDistance(canvasX, canvasY, point.x, point.y);
      if (distance < _hitRadiusPoint && distance < minDistance) {
        minDistance = distance;
        closest = {
          'type': 'point',
          'id': point.id,
          'distance': distance,
          'x': point.x,
          'y': point.y,
        };
      }
    }

    // Check platforms (rectangular hit detection, but use distance to nearest edge)
    for (final platform in controller.platforms) {
      // Check if within rectangular bounds
      if (canvasX >= platform.startX && canvasX <= platform.endX) {
        final distance = (canvasY - platform.y).abs();
        if (distance < _hitRadiusPlatform && distance < minDistance) {
          minDistance = distance;
          closest = {
            'type': 'platform',
            'id': platform.id,
            'distance': distance,
            'x': (platform.startX + platform.endX) / 2,
            'y': platform.y,
          };
        }
      }
    }

    // Check train stops
    for (final trainStop in controller.trainStops.values) {
      final distance = _calculateDistance(canvasX, canvasY, trainStop.x, trainStop.y);
      if (distance < _hitRadiusTrainStop && distance < minDistance) {
        minDistance = distance;
        closest = {
          'type': 'trainstop',
          'id': trainStop.id,
          'distance': distance,
          'x': trainStop.x,
          'y': trainStop.y,
        };
      }
    }

    // Check buffer stops
    for (final bufferStop in controller.bufferStops.values) {
      final distance = _calculateDistance(canvasX, canvasY, bufferStop.x, bufferStop.y);
      if (distance < _hitRadiusBufferStop && distance < minDistance) {
        minDistance = distance;
        closest = {
          'type': 'bufferstop',
          'id': bufferStop.id,
          'distance': distance,
          'x': bufferStop.x,
          'y': bufferStop.y,
        };
      }
    }

    // Check axle counters
    for (final counter in controller.axleCounters.values) {
      final distance = _calculateDistance(canvasX, canvasY, counter.x, counter.y);
      if (distance < _hitRadiusAxleCounter && distance < minDistance) {
        minDistance = distance;
        closest = {
          'type': 'axlecounter',
          'id': counter.id,
          'distance': distance,
          'x': counter.x,
          'y': counter.y,
        };
      }
    }

    // Check transponders
    for (final transponder in controller.transponders.values) {
      final distance = _calculateDistance(canvasX, canvasY, transponder.x, transponder.y);
      if (distance < _hitRadiusTransponder && distance < minDistance) {
        minDistance = distance;
        closest = {
          'type': 'transponder',
          'id': transponder.id,
          'distance': distance,
          'x': transponder.x,
          'y': transponder.y,
        };
      }
    }

    // Check wifi antennas
    for (final antenna in controller.wifiAntennas.values) {
      final distance = _calculateDistance(canvasX, canvasY, antenna.x, antenna.y);
      if (distance < _hitRadiusWifiAntenna && distance < minDistance) {
        minDistance = distance;
        closest = {
          'type': 'wifiantenna',
          'id': antenna.id,
          'distance': distance,
          'x': antenna.x,
          'y': antenna.y,
        };
      }
    }

    // Check trains
    for (final train in controller.trains) {
      final distance = _calculateDistance(canvasX, canvasY, train.x, train.y);
      if (distance < _hitRadiusTrain && distance < minDistance) {
        minDistance = distance;
        closest = {
          'type': 'train',
          'id': train.name,
          'distance': distance,
          'x': train.x,
          'y': train.y,
        };
      }
    }

    return closest;
  }

  Widget _buildStationCanvas() {
    return Container(
      color: Colors.grey[200],
      child: Consumer<TerminalStationController>(
        builder: (context, controller, _) {
          // Wrap in CanvasDropTarget for drag-and-drop from palette
          final canvasWidget = controller.editModeEnabled
              ? _buildScrollableCanvas(controller)
              : _buildCanvasContent(controller);

          // In edit mode, enable drop target for palette components
          if (controller.editModeEnabled) {
            return CanvasDropTarget(
              toCanvasCoords: (localPosition) =>
                  _screenToCanvasCoords(localPosition, true),
              child: canvasWidget,
            );
          }

          // Normal mode: standard canvas without drop target
          return canvasWidget;
        },
      ),
    );
  }

  /// Build scrollable canvas for edit mode with scrollbars
  Widget _buildScrollableCanvas(TerminalStationController controller) {
    // Use actual canvas dimensions for scrollable area
    // Canvas coordinates are centered, so they range from -width/2 to +width/2
    final canvasMinX = -_canvasWidth / 2;
    final canvasMaxX = _canvasWidth / 2;
    final canvasMinY = -_canvasHeight / 2;
    final canvasMaxY = _canvasHeight / 2;

    final canvasWidth = _canvasWidth;
    final canvasHeight = _canvasHeight;

    // Get current viewport size
    final viewportWidth = MediaQuery.of(context).size.width;
    final viewportHeight = MediaQuery.of(context).size.height;

    // Calculate scrollable area size (canvas size * zoom)
    final scrollableWidth = canvasWidth * _zoom;
    final scrollableHeight = canvasHeight * _zoom;

    return Scrollbar(
      controller: _horizontalScrollController,
      thumbVisibility: true,
      trackVisibility: true,
      child: Scrollbar(
        controller: _verticalScrollController,
        thumbVisibility: true,
        trackVisibility: true,
        notificationPredicate: (notification) => notification.depth == 1,
        child: SingleChildScrollView(
          controller: _horizontalScrollController,
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            controller: _verticalScrollController,
            scrollDirection: Axis.vertical,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification) {
                  // Update camera offset based on scroll position
                  // Convert scroll position to canvas coordinates (centered at 0,0)
                  setState(() {
                    _cameraOffsetX = (_horizontalScrollController.offset / _zoom) + canvasMinX;
                    _cameraOffsetY = (_verticalScrollController.offset / _zoom) + canvasMinY;
                  });
                }
                return true;
              },
              child: SizedBox(
                width: scrollableWidth.clamp(viewportWidth, double.infinity),
                height: scrollableHeight.clamp(viewportHeight, double.infinity),
                child: _buildCanvasContent(controller),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build the actual canvas content (used by both scrollable and normal modes)
  Widget _buildCanvasContent(TerminalStationController controller) {
    return MouseRegion(
      onHover: (event) {
        if (!controller.tooltipsEnabled) return;

        // Convert screen coordinates to canvas coordinates
        final localPosition = event.localPosition;
        final canvasCoords = _screenToCanvasCoords(localPosition, controller.editModeEnabled);

        // Check for hovered objects (signals, points, trains, etc.)
        _detectHoveredObject(controller, canvasCoords.dx, canvasCoords.dy);
      },
      onExit: (event) {
        controller.setHoveredObject(null);
      },
      child: GestureDetector(
        onTapDown: (details) {
          // Convert screen coordinates to canvas coordinates
          final canvasCoords = _screenToCanvasCoords(details.localPosition, controller.editModeEnabled);

          // Handle click based on edit mode state
          if (controller.editModeEnabled) {
            _handleEditModeClick(controller, canvasCoords.dx, canvasCoords.dy);
          } else {
            _handleCanvasClick(controller, canvasCoords.dx, canvasCoords.dy);
          }
        },
        onPanStart: (details) {
          final canvasCoords = _screenToCanvasCoords(details.localPosition, controller.editModeEnabled);
          final canvasX = canvasCoords.dx;
          final canvasY = canvasCoords.dy;

          // FIXED: In edit mode, check if clicking on ANY component (not just selected one)
          if (controller.editModeEnabled) {
            // Check for platform resize handles FIRST (if platform is selected)
            if (controller.selectedComponentType == 'platform' &&
                controller.selectedComponentId != null) {
              try {
                final selectedPlatform = controller.platforms.firstWhere(
                  (p) => p.id == controller.selectedComponentId,
                );

                // Check if clicking on left or right resize handle using Euclidean distance
                final leftHandleDist = _calculateDistance(
                  canvasX, canvasY, selectedPlatform.startX, selectedPlatform.y);
                final rightHandleDist = _calculateDistance(
                  canvasX, canvasY, selectedPlatform.endX, selectedPlatform.y);

                if (leftHandleDist < _hitRadiusResizeHandle) {
                  // Clicked on left resize handle
                  controller.startResizingPlatform(selectedPlatform.id, 'left');
                  return; // Start resizing, don't drag
                } else if (rightHandleDist < _hitRadiusResizeHandle) {
                  // Clicked on right resize handle
                  controller.startResizingPlatform(selectedPlatform.id, 'right');
                  return; // Start resizing, don't drag
                }
              } catch (e) {
                // Platform not found
              }
            }

            // Find the closest component using Euclidean distance
            final closestComponent = _findClosestComponent(controller, canvasX, canvasY);

            // If we found a component, select it and start dragging (Pointer/Quick Select mode)
            if (closestComponent != null) {
              final componentType = closestComponent['type'] as String;
              final componentId = closestComponent['id'] as String;

              if (controller.selectionMode == SelectionMode.pointer ||
                  controller.selectionMode == SelectionMode.quickSelect) {
                controller.selectComponent(componentType, componentId);
                _isDraggingComponent = true;
                _draggingComponentId = componentId;
                _draggingComponentType = componentType;
                _dragStartPosition = Offset(canvasX, canvasY);
                return; // Start dragging component
              }
            }

            // Check if using Marquee tool
            if (controller.selectionMode == SelectionMode.marquee) {
              // Start drawing marquee rectangle
              setState(() {
                _isDrawingMarquee = true;
                _marqueeStart = details.localPosition;
                _marqueeEnd = details.localPosition;
              });
              return; // Start marquee selection
            }

            // Check if using Lasso tool
            if (controller.selectionMode == SelectionMode.lasso) {
              // Start drawing lasso path (future implementation)
              return;
            }

            // No component clicked and not using selection tool - clear selection
            if (controller.selectionMode == SelectionMode.pointer) {
              controller.clearSelection();
            }
          }

                // NORMAL MODE: Pan the camera (edit mode off)
                if (!controller.editModeEnabled) {
                  _controller.disableAutoFollow();
                }
              },
              onPanUpdate: (details) {
                // EDIT MODE BEHAVIOR
                if (controller.editModeEnabled) {
                  // Check if resizing a platform
                  if (controller.isResizingPlatform) {
                    final canvasCoords = _screenToCanvasCoords(details.localPosition, controller.editModeEnabled);
                    controller.updatePlatformResize(canvasCoords.dx);
                  } else if (_isDraggingComponent &&
                      _draggingComponentId != null &&
                      _draggingComponentType != null) {
                    // Dragging a selected component
                    final dx = details.delta.dx / _zoom;
                    final dy = details.delta.dy / _zoom;
                    _moveComponent(controller, _draggingComponentType!,
                        _draggingComponentId!, dx, dy);
                  } else if (_isDrawingMarquee && _marqueeStart != null) {
                    // Drawing marquee selection rectangle
                    setState(() {
                      _marqueeEnd = details.localPosition;
                    });
                  }
                  // CRITICAL: Do NOT pan canvas in edit mode - use scrollbars instead
                } else {
                  // NORMAL MODE: Pan the camera (edit mode off)
                  _controller.updateCameraPosition(
                    _controller.cameraOffsetX + details.delta.dx / _controller.cameraZoom,
                    _controller.cameraOffsetY + details.delta.dy / _controller.cameraZoom,
                    _controller.cameraZoom,
                  );
                }
              },
        onPanEnd: (details) {
          // Finalize platform resize
          if (controller.isResizingPlatform) {
            controller.endPlatformResize();
            return;
          }

          // Finalize marquee selection
          if (_isDrawingMarquee && _marqueeStart != null && _marqueeEnd != null) {
            // Convert screen coordinates to canvas coordinates
            final canvasStart = _screenToCanvasCoords(_marqueeStart!, controller.editModeEnabled);
            final canvasEnd = _screenToCanvasCoords(_marqueeEnd!, controller.editModeEnabled);

            // Call controller to select all components in rectangle
            controller.selectInRectangle(canvasStart.dx, canvasStart.dy, canvasEnd.dx, canvasEnd.dy);

                  setState(() {
                    _isDrawingMarquee = false;
                    _marqueeStart = null;
                    _marqueeEnd = null;
                  });
                }

                // Stop dragging component
                if (_isDraggingComponent) {
                  _isDraggingComponent = false;
                  _draggingComponentId = null;
                  _draggingComponentType = null;
                  _dragStartPosition = null;
                }
              },
              child: Consumer<CanvasThemeController>(
                builder: (context, canvasThemeController, _) {
                  return Stack(
                    children: [
                      // Main railway canvas
                      CustomPaint(
                        size: Size(_canvasWidth, _canvasHeight),
                        painter: TerminalStationPainter(
                          controller: controller,
                          cameraOffsetX: _cameraOffsetX,
                          cameraOffsetY:
                              _cameraOffsetY, // FIXED: Pass Y offset to painter
                          zoom: _zoom,
                          animationTick: _animationTick,
                          canvasWidth: _canvasWidth,
                          canvasHeight: _canvasHeight,
                          themeData: canvasThemeController.getThemeData(),
                        ),
                      ),
                      // Marquee selection rectangle overlay
                      if (_isDrawingMarquee && _marqueeStart != null && _marqueeEnd != null)
                        CustomPaint(
                          size: Size(_canvasWidth, _canvasHeight),
                          painter: MarqueeSelectionPainter(
                            start: _marqueeStart!,
                            end: _marqueeEnd!,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          );
  }

  // Helper method to detect hovered object on the canvas using Euclidean distance
  void _detectHoveredObject(
      TerminalStationController controller, double canvasX, double canvasY) {
    Map<String, dynamic>? closest;
    double minDistance = double.infinity;

    // Check signals
    for (final signal in controller.signals.values) {
      if (!controller.maintenanceModeEnabled && !signal.commissioned) {
        continue;
      }
      final distance = _calculateDistance(canvasX, canvasY, signal.x, signal.y);
      if (distance < _hitRadiusSignal && distance < minDistance) {
        minDistance = distance;
        closest = {
          'type': 'Signal',
          'id': signal.id,
          'x': signal.x,
          'y': signal.y,
          'aspect': signal.aspect.name,
        };
      }
    }

    // Check crossovers (by checking their constituent points)
    for (final crossover in controller.crossovers.values) {
      // Get center position of crossover by averaging its points
      final points = crossover.pointIds
          .map((pid) => controller.points[pid])
          .where((p) => p != null)
          .cast<Point>()
          .toList();

      if (points.isNotEmpty) {
        final centerX = points.map((p) => p.x).reduce((a, b) => a + b) / points.length;
        final centerY = points.map((p) => p.y).reduce((a, b) => a + b) / points.length;
        final distance = _calculateDistance(canvasX, canvasY, centerX, centerY);

        // Use larger hit radius for crossovers (they're bigger structures)
        if (distance < 60.0 && distance < minDistance) {
          minDistance = distance;
          closest = {
            'type': 'Crossover',
            'id': crossover.id,
            'name': crossover.name,
            'x': centerX,
            'y': centerY,
            'crossoverType': crossover.type.name,
            'pointIds': crossover.pointIds,
            'blockId': crossover.blockId,
            'isActive': crossover.isActive,
          };
        }
      }
    }

    // Check points
    for (final point in controller.points.values) {
      final distance = _calculateDistance(canvasX, canvasY, point.x, point.y);
      if (distance < _hitRadiusPoint && distance < minDistance) {
        minDistance = distance;
        closest = {
          'type': 'Point',
          'id': point.id,
          'name': point.name,
          'x': point.x,
          'y': point.y,
          'position': point.position.name,
          'crossoverId': point.crossoverId,
        };
      }
    }

    // Check platforms (rectangular hit detection)
    for (final platform in controller.platforms) {
      final centerX = (platform.startX + platform.endX) / 2;
      if (canvasX >= platform.startX && canvasX <= platform.endX) {
        final distance = (platform.y - canvasY).abs();
        if (distance < _hitRadiusPlatform && distance < minDistance) {
          minDistance = distance;
          closest = {
            'type': 'Platform',
            'id': platform.id,
            'name': platform.name,
            'x': centerX,
            'y': platform.y,
          };
        }
      }
    }

    // Check train stops
    for (final stop in controller.trainStops.values) {
      final distance = _calculateDistance(canvasX, canvasY, stop.x, stop.y);
      if (distance < _hitRadiusTrainStop && distance < minDistance) {
        minDistance = distance;
        closest = {
          'type': 'Train Stop',
          'id': stop.id,
          'x': stop.x,
          'y': stop.y,
          'active': stop.active ? 'Yes' : 'No',
        };
      }
    }

    // Check buffer stops
    for (final buffer in controller.bufferStops.values) {
      final distance = _calculateDistance(canvasX, canvasY, buffer.x, buffer.y);
      if (distance < _hitRadiusBufferStop && distance < minDistance) {
        minDistance = distance;
        closest = {
          'type': 'Buffer Stop',
          'id': buffer.id,
          'x': buffer.x,
          'y': buffer.y,
        };
      }
    }

    // Check axle counters
    for (final counter in controller.axleCounters.values) {
      final distance = _calculateDistance(canvasX, canvasY, counter.x, counter.y);
      if (distance < _hitRadiusAxleCounter && distance < minDistance) {
        minDistance = distance;
        closest = {
          'type': 'Axle Counter',
          'id': counter.id,
          'x': counter.x,
          'y': counter.y,
          'blockId': counter.blockId,
        };
      }
    }

    // Check transponders
    for (final transponder in controller.transponders.values) {
      final distance = _calculateDistance(canvasX, canvasY, transponder.x, transponder.y);
      if (distance < _hitRadiusTransponder && distance < minDistance) {
        minDistance = distance;
        closest = {
          'type': 'Transponder',
          'id': transponder.id,
          'x': transponder.x,
          'y': transponder.y,
        };
      }
    }

    // Check wifi antennas
    for (final antenna in controller.wifiAntennas.values) {
      final distance = _calculateDistance(canvasX, canvasY, antenna.x, antenna.y);
      if (distance < _hitRadiusWifiAntenna && distance < minDistance) {
        minDistance = distance;
        closest = {
          'type': 'WiFi Antenna',
          'id': antenna.id,
          'x': antenna.x,
          'y': antenna.y,
        };
      }
    }

    // Check trains
    for (final train in controller.trains) {
      final distance = _calculateDistance(canvasX, canvasY, train.x, train.y);
      if (distance < _hitRadiusTrain && distance < minDistance) {
        minDistance = distance;
        closest = {
          'type': 'Train',
          'id': train.name,
          'x': train.x,
          'y': train.y,
          'speed': train.speed.toStringAsFixed(1),
        };
      }
    }

    // Check blocks (rectangular hit detection)
    for (final block in controller.blocks.values) {
      if (canvasX >= block.startX && canvasX <= block.endX) {
        final distance = (block.y - canvasY).abs();
        if (distance < _hitRadiusBlock && distance < minDistance) {
          minDistance = distance;
          closest = {
            'type': 'Block',
            'id': block.id,
            'x': (block.startX + block.endX) / 2,
            'y': block.y,
            'occupied': block.occupied ? 'Yes' : 'No',
          };
        }
      }
    }

    // Set the closest hovered object or clear if none found
    controller.setHoveredObject(closest);
  }

  // Handle click on canvas objects (signals, points, and blocks) using Euclidean distance
  void _handleCanvasClick(
      TerminalStationController controller, double canvasX, double canvasY) {
    // Find the closest clickable component
    String? closestType;
    String? closestId;
    double minDistance = double.infinity;

    // Check for signal clicks
    for (final signal in controller.signals.values) {
      if (!signal.commissioned) continue;
      final distance = _calculateDistance(canvasX, canvasY, signal.x, signal.y);
      if (distance < _hitRadiusSignal && distance < minDistance) {
        minDistance = distance;
        closestType = 'signal';
        closestId = signal.id;
      }
    }

    // Check for point clicks
    for (final point in controller.points.values) {
      final distance = _calculateDistance(canvasX, canvasY, point.x, point.y);
      if (distance < _hitRadiusPoint && distance < minDistance) {
        minDistance = distance;
        closestType = 'point';
        closestId = point.id;
      }
    }

    // Check for block clicks
    for (final block in controller.blocks.values) {
      if (canvasX >= block.startX && canvasX <= block.endX) {
        final distance = (canvasY - block.y).abs();
        if (distance < 15 && distance < minDistance) {
          minDistance = distance;
          closestType = 'block';
          closestId = block.id;
        }
      }
    }

    // Show dialog for the closest component
    if (closestType == 'signal' && closestId != null) {
      final signal = controller.signals[closestId];
      if (signal != null) _showSignalRouteDialog(controller, signal);
    } else if (closestType == 'point' && closestId != null) {
      final point = controller.points[closestId];
      if (point != null) _showPointDialog(controller, point);
    } else if (closestType == 'block' && closestId != null) {
      final block = controller.blocks[closestId];
      if (block != null) {
        // Toggle block status directly
        controller.toggleBlockClosed(block.id);
        final isClosed = controller.isBlockClosed(block.id);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Block ${block.id} ${isClosed ? "CLOSED" : "OPENED"}'),
            duration: const Duration(seconds: 1),
            backgroundColor: isClosed ? Colors.red : Colors.green,
          ),
        );
      }
    }
  }

  /// Handle click in edit mode - select components instead of showing dialogs using Euclidean distance
  void _handleEditModeClick(
      TerminalStationController controller, double canvasX, double canvasY) {
    // Find the closest component using improved hit detection
    final closestComponent = _findClosestComponent(controller, canvasX, canvasY);

    if (closestComponent != null) {
      final componentType = closestComponent['type'] as String;
      final componentId = closestComponent['id'] as String;
      controller.selectComponent(componentType, componentId);
      controller.logEvent('📍 Selected $componentType $componentId');
    } else {
      // No component clicked - clear selection
      controller.clearSelection();
    }
  }

  /// Check if user is clicking on a specific component using Euclidean distance
  bool _isClickingOnComponent(TerminalStationController controller,
      String type, String id, double canvasX, double canvasY) {
    switch (type.toLowerCase()) {
      case 'signal':
        final signal = controller.signals[id];
        if (signal != null) {
          final distance = _calculateDistance(canvasX, canvasY, signal.x, signal.y);
          return distance < _hitRadiusSignal;
        }
        break;
      case 'point':
        final point = controller.points[id];
        if (point != null) {
          final distance = _calculateDistance(canvasX, canvasY, point.x, point.y);
          return distance < _hitRadiusPoint;
        }
        break;
      case 'platform':
        try {
          final platform = controller.platforms.firstWhere((p) => p.id == id);
          return canvasX >= platform.startX &&
              canvasX <= platform.endX &&
              (canvasY - platform.y).abs() < _hitRadiusPlatform;
        } catch (e) {
          return false;
        }
      case 'trainstop':
        final trainStop = controller.trainStops[id];
        if (trainStop != null) {
          final distance = _calculateDistance(canvasX, canvasY, trainStop.x, trainStop.y);
          return distance < _hitRadiusTrainStop;
        }
        break;
      case 'bufferstop':
        final bufferStop = controller.bufferStops[id];
        if (bufferStop != null) {
          final distance = _calculateDistance(canvasX, canvasY, bufferStop.x, bufferStop.y);
          return distance < _hitRadiusBufferStop;
        }
        break;
      case 'axlecounter':
        final axleCounter = controller.axleCounters[id];
        if (axleCounter != null) {
          final distance = _calculateDistance(canvasX, canvasY, axleCounter.x, axleCounter.y);
          return distance < _hitRadiusAxleCounter;
        }
        break;
      case 'transponder':
        final transponder = controller.transponders[id];
        if (transponder != null) {
          final distance = _calculateDistance(canvasX, canvasY, transponder.x, transponder.y);
          return distance < _hitRadiusTransponder;
        }
        break;
      case 'wifiantenna':
        final wifiAntenna = controller.wifiAntennas[id];
        if (wifiAntenna != null) {
          final distance = _calculateDistance(canvasX, canvasY, wifiAntenna.x, wifiAntenna.y);
          return distance < _hitRadiusWifiAntenna;
        }
        break;
      case 'block':
        final block = controller.blocks[id];
        if (block != null) {
          return canvasX >= block.startX &&
              canvasX <= block.endX &&
              (canvasY - block.y).abs() < _hitRadiusBlock;
        }
        break;
      case 'train':
        final train = controller.trains.firstWhere((t) => t.name == id, orElse: () => controller.trains.first);
        final distance = _calculateDistance(canvasX, canvasY, train.x, train.y);
        return distance < _hitRadiusTrain;
    }
    return false;
  }

  /// Move a component with optional snap-to-grid
  void _moveComponent(TerminalStationController controller, String type,
      String id, double dx, double dy) {
    switch (type.toLowerCase()) {
      case 'signal':
        final signal = controller.signals[id];
        if (signal != null) {
          signal.x += dx;
          signal.y += dy;
          // Snap to grid if enabled
          if (controller.gridVisible) {
            signal.x = controller.snapToGrid(signal.x);
            signal.y = controller.snapToGrid(signal.y);
          }
          controller.notifyListeners();
        }
        break;
      case 'point':
        final point = controller.points[id];
        if (point != null) {
          point.x += dx;
          point.y += dy;
          if (controller.gridVisible) {
            point.x = controller.snapToGrid(point.x);
            point.y = controller.snapToGrid(point.y);
          }
          controller.notifyListeners();
        }
        break;
      case 'platform':
        try {
          final platform = controller.platforms.firstWhere((p) => p.id == id);
          final length = platform.endX - platform.startX;
          platform.startX += dx;
          platform.endX = platform.startX + length;
          platform.y += dy;
          if (controller.gridVisible) {
            platform.startX = controller.snapToGrid(platform.startX);
            platform.endX = controller.snapToGrid(platform.endX);
            platform.y = controller.snapToGrid(platform.y);
          }
          controller.notifyListeners();
        } catch (e) {
          // Platform not found
        }
        break;
      case 'trainstop':
        final trainStop = controller.trainStops[id];
        if (trainStop != null) {
          trainStop.x += dx;
          trainStop.y += dy;
          if (controller.gridVisible) {
            trainStop.x = controller.snapToGrid(trainStop.x);
            trainStop.y = controller.snapToGrid(trainStop.y);
          }
          controller.notifyListeners();
        }
        break;
      case 'bufferstop':
        final bufferStop = controller.bufferStops[id];
        if (bufferStop != null) {
          bufferStop.x += dx;
          bufferStop.y += dy;
          if (controller.gridVisible) {
            bufferStop.x = controller.snapToGrid(bufferStop.x);
            bufferStop.y = controller.snapToGrid(bufferStop.y);
          }
          controller.notifyListeners();
        }
        break;
      case 'axlecounter':
        final axleCounter = controller.axleCounters[id];
        if (axleCounter != null) {
          axleCounter.x += dx;
          axleCounter.y += dy;
          if (controller.gridVisible) {
            axleCounter.x = controller.snapToGrid(axleCounter.x);
            axleCounter.y = controller.snapToGrid(axleCounter.y);
          }
          controller.notifyListeners();
        }
        break;
      case 'transponder':
        final transponder = controller.transponders[id];
        if (transponder != null) {
          transponder.x += dx;
          transponder.y += dy;
          if (controller.gridVisible) {
            transponder.x = controller.snapToGrid(transponder.x);
            transponder.y = controller.snapToGrid(transponder.y);
          }
          controller.notifyListeners();
        }
        break;
      case 'wifiantenna':
        final wifiAntenna = controller.wifiAntennas[id];
        if (wifiAntenna != null) {
          wifiAntenna.x += dx;
          wifiAntenna.y += dy;
          if (controller.gridVisible) {
            wifiAntenna.x = controller.snapToGrid(wifiAntenna.x);
            wifiAntenna.y = controller.snapToGrid(wifiAntenna.y);
          }
          controller.notifyListeners();
        }
        break;
      case 'block':
        final block = controller.blocks[id];
        if (block != null) {
          final length = block.endX - block.startX;
          block.startX += dx;
          block.endX = block.startX + length;
          block.y += dy;
          if (controller.gridVisible) {
            block.startX = controller.snapToGrid(block.startX);
            block.endX = controller.snapToGrid(block.endX);
            block.y = controller.snapToGrid(block.y);
          }
          controller.notifyListeners();
        }
        break;
      case 'train':
        final train = controller.trains.firstWhere((t) => t.name == id, orElse: () => controller.trains.first);
        train.x += dx;
        train.y += dy;
        if (controller.gridVisible) {
          train.x = controller.snapToGrid(train.x);
          train.y = controller.snapToGrid(train.y);
        }
        controller.notifyListeners();
        break;
    }
  }

  // Show dialog to select signal route
  void _showSignalRouteDialog(
      TerminalStationController controller, Signal signal) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Signal ${signal.id}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Aspect: ${signal.aspect.name.toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Route State: ${signal.routeState.name}'),
              const SizedBox(height: 16),
              const Text('Select Route:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...signal.routes.map((route) {
                final isActive = signal.activeRouteId == route.id;
                return ListTile(
                  title: Text(route.name),
                  subtitle: Text(route.id),
                  trailing: isActive
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  selected: isActive,
                  onTap: () {
                    if (isActive) {
                      controller.cancelRoute(signal.id);
                    } else {
                      controller.setRoute(signal.id, route.id);
                    }
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ],
          ),
          actions: [
            if (signal.activeRouteId != null)
              TextButton(
                onPressed: () {
                  controller.cancelRoute(signal.id);
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel Route'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Show point control dialog
  void _showPointDialog(TerminalStationController controller, Point point) {
    final isReserved = controller.isPointReserved(point.id);
    final reservedPosition = controller.getPointReservation(point.id);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Point ${point.id}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Position: ${point.position.name.toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Locked: ${point.locked ? "YES" : "NO"}'),
              if (isReserved) ...[
                const SizedBox(height: 8),
                Text('🔒 Reserved: ${reservedPosition!.name.toUpperCase()}',
                    style: const TextStyle(
                        color: Colors.orange, fontWeight: FontWeight.bold)),
              ],
              const SizedBox(height: 16),
              const Text('Actions:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            if (!point.locked && !isReserved)
              TextButton.icon(
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Toggle Position'),
                onPressed: () {
                  controller.swingPoint(point.id);
                  Navigator.of(context).pop();
                },
              ),
            TextButton.icon(
              icon: Icon(isReserved ? Icons.lock_open : Icons.lock),
              label: Text(isReserved ? 'Remove Reservation' : 'Reserve Normal'),
              onPressed: () {
                if (isReserved) {
                  controller.unreservePoint(point.id);
                } else {
                  controller.reservePoint(point.id, PointPosition.normal);
                }
                Navigator.of(context).pop();
              },
            ),
            if (!isReserved)
              TextButton.icon(
                icon: const Icon(Icons.lock),
                label: const Text('Reserve Reverse'),
                onPressed: () {
                  controller.reservePoint(point.id, PointPosition.reverse);
                  Navigator.of(context).pop();
                },
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }



  Widget _buildStatusPanel() {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
            left: BorderSide(color: Theme.of(context).colorScheme.outline)),
      ),
      child: Consumer<TerminalStationController>(
        builder: (context, controller, _) {
          final stats = controller.getStats();

          // Calculate viewport dimensions for search navigation
          final screenSize = MediaQuery.of(context).size;
          final leftPanelWidth = _showLeftPanel ? 320.0 : 0.0;
          final rightPanelWidth = _showRightPanel ? 320.0 : 0.0;
          final viewportWidth = screenSize.width - leftPanelWidth - rightPanelWidth;
          final viewportHeight = screenSize.height - kToolbarHeight;

          return Column(
            children: [
              // Search Bar at the top with viewport dimensions for navigation
              RailwaySearchBarEnhanced(
                viewportWidth: viewportWidth,
                viewportHeight: viewportHeight,
              ),

              // Mini Map
              if (_controller.miniMapVisible)
                MiniMapWidgetEnhanced(
                  canvasWidth: _canvasWidth,
                  canvasHeight: _canvasHeight,
                  cameraOffsetX: _cameraOffsetX,
                  cameraOffsetY: _cameraOffsetY,
                  cameraZoom: _zoom,
                  viewportWidth: viewportWidth,
                  viewportHeight: viewportHeight,
                  onNavigate: (x, y) {
                    _controller.panToPosition(
                      x,
                      y,
                      viewportWidth: viewportWidth,
                      viewportHeight: viewportHeight,
                    );
                    _controller.disableAutoFollow();
                  },
                ),

              // Dot Matrix Display - relocated under minimap
              if (_controller.dotMatrixDisplayVisible)
                Container(
                  width: 280,
                  height: 300, // Optimized height for better readability
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: const DotMatrixDisplay(),
                ),

              // Rest of the status panel content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Simulation Running Time
                    Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Text('Simulation Running',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800])),
                            const SizedBox(height: 8),
                            Text(controller.getFormattedRunningTime(),
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace')),
                            const SizedBox(height: 4),
                            Text('HH:MM:SS',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Axle Counter Evaluator (ACE) Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Axle Counter Evaluator (ACE)',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                const Spacer(),
                                ElevatedButton(
                                  onPressed: () => controller.resetACE(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    minimumSize: const Size(0, 30),
                                  ),
                                  child: const Text('Reset ACE',
                                      style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Axle Counter Results
                            const Text('Axle Counter Results:',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children:
                                  controller.axleCounters.entries.map((entry) {
                                final counter = entry.value;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(4),
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(counter.id,
                                          style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold)),
                                      Text('${counter.count}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: counter.count != 0
                                                ? Colors.purple
                                                : Colors.grey,
                                          )),
                                      if (counter.lastDirection.isNotEmpty)
                                        Text(counter.lastDirection,
                                            style: TextStyle(
                                              fontSize: 8,
                                              color: Colors.grey[600],
                                            )),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 12),

                            // AB Results - ALL 10 COMPREHENSIVE ABs
                            const Text('AB Occupation Results (All 10 ABs):',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ...['AB100', 'AB101', 'AB104', 'AB105', 'AB106', 'AB107', 'AB108', 'AB109', 'AB111', 'AB112']
                                .map((abId) {
                              final isOccupied =
                                  controller.ace.isABOccupied(abId);
                              return Card(
                                margin: const EdgeInsets.only(bottom: 4),
                                color: isOccupied
                                    ? Colors.purple[50]
                                    : Colors.grey[50],
                                child: ListTile(
                                  dense: true,
                                  title: Text(abId,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isOccupied
                                            ? Colors.purple
                                            : Colors.grey,
                                      )),
                                  subtitle: Text(
                                      isOccupied ? 'OCCUPIED' : 'UNOCCUPIED',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isOccupied
                                            ? Colors.purple
                                            : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      )),
                                  trailing: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: isOccupied
                                          ? Colors.purple
                                          : Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text('Status',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildStatusCard(
                        'Trains', '${stats['trains']}', Colors.blue),
                    _buildStatusCard('Occupied Blocks',
                        '${stats['occupied_blocks']}', Colors.orange),
                    // Release Status
                    _buildStatusCard(
                        'Pending Cancellations',
                        '${stats['pending_cancellations']}',
                        stats['pending_cancellations'] > 0
                            ? Colors.orange
                            : Colors.grey),
                    _buildStatusCard(
                        'Release State',
                        '${stats['release_state']}',
                        stats['release_state'] == 'counting'
                            ? Colors.orange
                            : stats['release_state'] == 'completed'
                                ? Colors.green
                                : Colors.grey),
                    if (stats['release_countdown'] > 0)
                      _buildStatusCard('Release Countdown',
                          '${stats['release_countdown']}s', Colors.orange),
                    _buildStatusCard('Active Routes',
                        '${stats['active_routes']}', Colors.green),
                    _buildStatusCard('Route Reservations',
                        '${stats['route_reservations']}', Colors.teal),
                    _buildStatusCard(
                        'Self-normalizing',
                        stats['self_normalizing_points'] ? 'ON' : 'OFF',
                        stats['self_normalizing_points']
                            ? Colors.green
                            : Colors.grey),
                    _buildStatusCard(
                        'Train Stops',
                        stats['train_stops_enabled'] ? 'ENABLED' : 'DISABLED',
                        stats['train_stops_enabled']
                            ? Colors.red
                            : Colors.grey),
                    _buildStatusCard('Active Train Stops',
                        '${stats['active_train_stops']}', Colors.orange),
                    _buildStatusCard(
                        'Signals',
                        stats['signals_visible'] ? 'VISIBLE' : 'HIDDEN',
                        stats['signals_visible'] ? Colors.green : Colors.grey),
                    // AB Deadlock Status
                    _buildStatusCard(
                        'Point 78A Deadlocked',
                        stats['point_78a_deadlocked'] ? 'YES' : 'NO',
                        stats['point_78a_deadlocked']
                            ? Colors.red
                            : Colors.green),
                    _buildStatusCard(
                        'Point 78B Deadlocked',
                        stats['point_78b_deadlocked'] ? 'YES' : 'NO',
                        stats['point_78b_deadlocked']
                            ? Colors.red
                            : Colors.green),
                    _buildStatusCard(
                        'AB104 Occupied',
                        stats['ab104_occupied'] ? 'YES' : 'NO',
                        stats['ab104_occupied'] ? Colors.orange : Colors.green),
                    _buildStatusCard(
                        'AB106 Occupied',
                        stats['ab106_occupied'] ? 'YES' : 'NO',
                        stats['ab106_occupied']
                            ? Colors.deepOrange
                            : Colors.green),
                    _buildStatusCard(
                        'AB109 Occupied',
                        stats['ab109_occupied'] ? 'YES' : 'NO',
                        stats['ab109_occupied'] ? Colors.orange : Colors.green),
                    const Divider(height: 32),

                    // Layout Selector Dropdown
                    const LayoutSelectorDropdown(),
                    const Divider(height: 32),

                    // Crossover Route Table
                    CrossoverRouteTableTerminal(controller: controller),
                    const Divider(height: 32),

                    // Points Status
                    Text('Points',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...controller.points.entries.map((entry) {
                      final point = entry.value;
                      final isDeadlocked = (point.id == '78A' &&
                              stats['point_78a_deadlocked']) ||
                          (point.id == '78B' && stats['point_78b_deadlocked']);
                      final deadlockReason = point.id == '78A'
                          ? (stats['ab106_occupied'] ? 'AB106' : 'AB104')
                          : (stats['ab106_occupied'] ? 'AB106' : 'AB109');

                      return Card(
                        child: ListTile(
                          dense: true,
                          title: Row(
                            children: [
                              Text(point.id,
                                  style: const TextStyle(fontSize: 13)),
                              if (isDeadlocked) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: stats['ab106_occupied']
                                        ? Colors.deepOrange
                                        : Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    deadlockReason,
                                    style: const TextStyle(
                                      fontSize: 8,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                              '${point.position.name.toUpperCase()} '
                              '${point.locked ? '(LOCKED)' : '(UNLOCKED)'} '
                              '${isDeadlocked ? '🔒' : ''}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDeadlocked
                                    ? (stats['ab106_occupied']
                                        ? Colors.deepOrange
                                        : Colors.red)
                                    : Colors.black,
                              )),
                          trailing: Icon(
                            point.locked ? Icons.lock : Icons.lock_open,
                            size: 16,
                            color: isDeadlocked
                                ? (stats['ab106_occupied']
                                    ? Colors.deepOrange
                                    : Colors.red)
                                : (point.locked ? Colors.red : Colors.green),
                          ),
                        ),
                      );
                    }),
                    const Divider(height: 32),

                    // Route Reservations
                    Text('Active Reservations',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...controller.routeReservations.values.map((reservation) {
                      final isPendingCancellation = controller
                          .isRoutePendingCancellation(reservation.signalId);
                      return Card(
                        child: ListTile(
                          dense: true,
                          leading: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: isPendingCancellation
                                  ? Colors.orange
                                  : Colors.yellow,
                              shape: BoxShape.circle,
                            ),
                          ),
                          title: Text(
                              '${reservation.signalId} → ${reservation.trainId.replaceAll('T', '').replaceAll('route_active', 'Active')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isPendingCancellation
                                    ? Colors.orange
                                    : Colors.brown,
                              )),
                          subtitle: Text(
                              'Blocks: ${reservation.reservedBlocks.join(', ')}',
                              style: const TextStyle(fontSize: 10)),
                          trailing: isPendingCancellation
                              ? const Icon(Icons.access_time,
                                  size: 16, color: Colors.orange)
                              : null,
                        ),
                      );
                    }),
                    if (controller.routeReservations.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No active route reservations',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ),
                    const Divider(height: 32),

                    // Event Log
                    Text('Event Log',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ListView.builder(
                        itemCount: controller.eventLog.length,
                        itemBuilder: (context, index) {
                          final event = controller.eventLog[index];
                          Color textColor = Colors.greenAccent;

                          // Color code events based on content
                          if (event.contains('❌') ||
                              event.contains('🚨') ||
                              event.contains('💥')) {
                            textColor = Colors.redAccent;
                          } else if (event.contains('⚠️') ||
                              event.contains('🟡')) {
                            textColor = Colors.orangeAccent;
                          } else if (event.contains('🔒') ||
                              event.contains('🔓')) {
                            textColor = Colors.blueAccent;
                          } else if (event.contains('🔄') ||
                              event.contains('🔧')) {
                            textColor = Colors.yellowAccent;
                          } else if (event.contains('✅') ||
                              event.contains('🎉')) {
                            textColor = Colors.greenAccent;
                          } else if (event.contains('🔢')) {
                            textColor = Colors.purpleAccent;
                          }

                          return Text(
                            event,
                            style: TextStyle(
                                fontSize: 10,
                                color: textColor,
                                fontFamily: 'monospace'),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Current Time and Date
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Text(
                              controller.getCurrentTime(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.getCurrentDate(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Simulation Running Time
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Simulation Running Time',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    controller.getFormattedRunningTime(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Quick Actions Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quick Actions',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                // Signal Visibility Toggle
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      controller.toggleSignalsVisibility(),
                                  icon: Icon(
                                    controller.signalsVisible
                                        ? Icons.traffic
                                        : Icons.traffic_outlined,
                                    size: 16,
                                  ),
                                  label: Text(
                                    'Signals: ${controller.signalsVisible ? 'ON' : 'OFF'}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: controller.signalsVisible
                                        ? Colors.green
                                        : Colors.grey,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                  ),
                                ),

                                // Axle Counter Visibility Toggle
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      controller.toggleAxleCounterVisibility(),
                                  icon: Icon(
                                    controller.axleCountersVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    size: 16,
                                  ),
                                  label: Text(
                                    'Axle Counters: ${controller.axleCountersVisible ? 'ON' : 'OFF'}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        controller.axleCountersVisible
                                            ? Colors.purple
                                            : Colors.grey,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                  ),
                                ),

                                // Mini Map Visibility Toggle
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      controller.toggleMiniMapVisibility(),
                                  icon: Icon(
                                    controller.miniMapVisible
                                        ? Icons.map
                                        : Icons.map_outlined,
                                    size: 16,
                                  ),
                                  label: Text(
                                    'Mini Map: ${controller.miniMapVisible ? 'ON' : 'OFF'}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        controller.miniMapVisible
                                            ? Colors.blue
                                            : Colors.grey,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                  ),
                                ),

                                // Dot Matrix Display Visibility Toggle
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      controller.toggleDotMatrixDisplayVisibility(),
                                  icon: Icon(
                                    controller.dotMatrixDisplayVisible
                                        ? Icons.grid_on
                                        : Icons.grid_off,
                                    size: 16,
                                  ),
                                  label: Text(
                                    'Train Info: ${controller.dotMatrixDisplayVisible ? 'ON' : 'OFF'}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        controller.dotMatrixDisplayVisible
                                            ? Colors.orange
                                            : Colors.grey,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                  ),
                                ),

                                // Reset ACE
                                ElevatedButton.icon(
                                  onPressed: () => controller.resetACE(),
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text(
                                    'Reset ACE',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                  ),
                                ),

                                // Reset Individual AB Sections
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.cleaning_services,
                                      size: 16),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'AB104',
                                      child: Text('Reset AB104'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'AB106',
                                      child: Text('Reset AB106'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'AB109',
                                      child: Text('Reset AB109'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'AB111',
                                      child: Text('Reset AB111'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'AB105',
                                      child: Text('Reset AB105'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'AB100',
                                      child: Text('Reset AB100'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'AB108',
                                      child: Text('Reset AB108'),
                                    ),
                                  ],
                                  onSelected: (abId) =>
                                      controller.resetIndividualAB(abId),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.cleaning_services,
                                            size: 16, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text(
                                          'Reset AB',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Export Layout
                                ElevatedButton.icon(
                                  onPressed: () => _exportLayout(controller),
                                  icon: const Icon(Icons.download, size: 16),
                                  label: const Text(
                                    'Export XML',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Relay Rack Panel
                    if (controller.relayRackVisible) const RelayRackPanel(),

                    if (controller.relayRackVisible) const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(String label, String value, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  void _showInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enhanced Terminal Station'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🚀 NEW FEATURES:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green)),
              SizedBox(height: 8),
              Text('• Signal Visibility Toggle: Show/hide all signals'),
              Text('• Visual Train Doors: Black rectangles show open doors'),
              Text('• Smart Train Placement: Add trains to safe blocks only'),
              Text('• Auto Train Controls: Depart & Emergency Brake buttons'),
              Text('• Point Lock/Unlock: Manual control when unlocked'),
              Text('• Self-normalizing Points: Auto-return to normal'),
              Text(
                  '• Route Reservations: Green highlights show protected blocks'),
              Text(
                  '• Direction Labels: Clear Eastbound/Westbound road identification'),
              Text('• Simulation Timer: Tracks running time'),
              Text(
                  '• Comprehensive Train Controls: Full control in left sidebar'),
              Text('• AB Section Deadlocking: Points lock when track occupied'),
              Text('• Crossover Detection: AB106 monitors crossover occupancy'),
              Text('• Enhanced Collision Recovery: Faster recovery process'),
              Text('• Canvas Size Controls: Adjust width and height'),
              Text('• Floating Zoom Controls: Easy zoom in/out/reset'),
              SizedBox(height: 12),
              Text('🔧 BUG FIXES:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blue)),
              SizedBox(height: 8),
              Text('✅ C31 Route 1: Yellow reservations only up to block 110'),
              Text('✅ C31 Route 2: Now shows block 104 properly'),
              Text('✅ C30 Route 1 & 2: Now show block 109 properly'),
              Text('✅ C30 Route 2: Now shows block 104 in yellow reservation'),
              Text('✅ Auto trains in block 111 now properly reverse'),
              Text('✅ Signal C33 only protects eastbound movement'),
              Text('✅ Signal C31 only protects eastbound movement'),
              Text('✅ Permissive movement logic enhanced'),
              Text('✅ No more teleportation or off-screen trains'),
              Text(
                  '✅ Route reservations only show when signal is green and train is using route'),
              Text('✅ Collision recovery no longer blocks train movement'),
              Text('✅ Points properly route trains through crossovers'),
              Text('✅ C31 shows red if block 104 has a train'),
              Text('✅ C30 shows red if block 109 has a train'),
              SizedBox(height: 12),
              Text('🎯 ENHANCEMENTS:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.orange)),
              SizedBox(height: 8),
              Text('• Visual route reservations with green highlights'),
              Text('• Emergency brake for auto trains'),
              Text('• Point manual override when unlocked'),
              Text('• Enhanced signal protection directions'),
              Text('• Better train movement commitment logic'),
              Text('• Direction arrows and road names on tracks'),
              Text('• Comprehensive train statistics and quick actions'),
              Text('• Axle counter system with twin counters on crossover'),
              Text('• AB section occupancy detection and visualization'),
              Text('• Point deadlocking based on AB section occupancy'),
              Text('• Faster collision recovery with visual guidance'),
              Text('• Two running rails on crossover tracks'),
              Text('• Dynamic canvas sizing with width/height controls'),
              Text('• Floating zoom controls in bottom-right corner'),
              SizedBox(height: 12),
              Text('⚠️ AUTO MODE RESTRICTIONS:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red)),
              SizedBox(height: 8),
              Text(
                  '• Auto trains cannot travel from block 101→103→105 (Westbound Road)'),
              Text('• This route is manual mode only'),
              Text('• Use manual mode for full directional flexibility'),
              SizedBox(height: 12),
              Text('🔒 SAFETY FEATURES:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.purple)),
              SizedBox(height: 8),
              Text('• AB104 occupation deadlocks point 78A'),
              Text('• AB109 occupation deadlocks point 78B'),
              Text('• AB106 occupation deadlocks both points 78A and 78B'),
              Text('• Automatic point unlocking when AB sections clear'),
              Text(
                  '• Visual deadlock indicators on points and in status panel'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // === MAINTENANCE MODE HANDLERS ===
  // ============================================================================

  void _handleMaintenanceSave(BuildContext context) {
    _maintenanceEditController.isDirty = false;
    _maintenanceEditController.notifyListeners();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Layout changes saved'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleMaintenanceExport(BuildContext context) async {
    try {
      final xml = LayoutXMLService.exportToXML(_controller);

      // Show export dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Layout XML'),
          content: SingleChildScrollView(
            child: SelectableText(
              xml,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // Copy to clipboard functionality would go here
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('XML copied to clipboard'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleMaintenanceImport(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Layout XML'),
        content: const Text(
          'Import functionality would allow you to paste XML or select a file to import.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _handleMaintenanceValidation(BuildContext context) {
    _maintenanceEditController.validateLayout();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _maintenanceEditController.validationIssues.isEmpty
                  ? Icons.check_circle
                  : Icons.warning,
              color: _maintenanceEditController.validationIssues.isEmpty
                  ? Colors.green
                  : Colors.orange,
            ),
            const SizedBox(width: 12),
            const Text('Validation Results'),
          ],
        ),
        content: _maintenanceEditController.validationIssues.isEmpty
            ? const Text('No issues found! Layout is valid.')
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _maintenanceEditController.validationIssues
                      .map((issue) => ListTile(
                            leading: Icon(issue.icon, color: issue.color),
                            title: Text(issue.message),
                            subtitle: Text(
                              '${issue.componentType}: ${issue.componentId}',
                            ),
                          ))
                      .toList(),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
// === HELPER METHODS ===
// ============================================================================

  /// Add helper method to check if train is at platform
  String? _getPlatformForTrain(Train train) {
    // Platform 1: y=100, x=980-1240
    if (train.y >= 80 && train.y <= 120 && train.x >= 980 && train.x <= 1240) {
      return 'P1';
    }
    // Platform 2: y=300, x=980-1240
    if (train.y >= 280 && train.y <= 320 && train.x >= 980 && train.x <= 1240) {
      return 'P2';
    }
    return null;
  }

  void _exportLayout(TerminalStationController controller) {
    try {
      final xmlContent = controller.exportLayoutAsXML();
      final bytes = utf8.encode(xmlContent);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Layout Exported')
          ]),
          content: SizedBox(
            width: 600,
            height: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('XML layout has been generated successfully!',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('Preview:'),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        xmlContent,
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 11),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Size: ${(bytes.length / 1024).toStringAsFixed(2)} KB',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Copy feature requires clipboard permission')),
                );
              },
              child: const Text('Copy XML'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Export Failed')
          ]),
          content: Text('Error exporting layout: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

// Helper methods for enhanced train controls
  String _getTrainTypeName(TrainType type) {
    switch (type) {
      case TrainType.m1:
        return 'M1 (Single)';
      case TrainType.m2:
        return 'M2 (Double)';
      case TrainType.cbtcM1:
        return 'CBTC M1';
      case TrainType.cbtcM2:
        return 'CBTC M2';
      case TrainType.m4:
        return 'M4 (Single)';
      case TrainType.m8:
        return 'M8 (Double)';
      case TrainType.cbtcM4:
        return 'CBTC M4';
      case TrainType.cbtcM8:
        return 'CBTC M8';
    }
  }

  String _getCbtcModeName(CbtcMode mode) {
    switch (mode) {
      case CbtcMode.auto:
        return 'Auto (Cyan)';
      case CbtcMode.pm:
        return 'PM (Orange)';
      case CbtcMode.rm:
        return 'RM (Brown)';
      case CbtcMode.off:
        return 'Off (White)';
      case CbtcMode.storage:
        return 'Storage (Green)';
    }
  }

  Color _getCbtcModeColor(CbtcMode mode) {
    switch (mode) {
      case CbtcMode.auto:
        return Colors.cyan;
      case CbtcMode.pm:
        return Colors.orange;
      case CbtcMode.rm:
        return Colors.brown;
      case CbtcMode.off:
        return Colors.white;
      case CbtcMode.storage:
        return Colors.green;
    }
  }

  List<DropdownMenuItem<String>> _getDestinationOptions() {
    return [
      // Blocks
      const DropdownMenuItem(value: 'B:100', child: Text('Block 100')),
      const DropdownMenuItem(value: 'B:102', child: Text('Block 102')),
      const DropdownMenuItem(value: 'B:104', child: Text('Block 104')),
      const DropdownMenuItem(value: 'B:106', child: Text('Block 106')),
      const DropdownMenuItem(value: 'B:108', child: Text('Block 108')),
      const DropdownMenuItem(value: 'B:110', child: Text('Block 110')),
      const DropdownMenuItem(value: 'B:112', child: Text('Block 112')),
      const DropdownMenuItem(value: 'B:114', child: Text('Block 114')),
      const DropdownMenuItem(value: 'B:101', child: Text('Block 101')),
      const DropdownMenuItem(value: 'B:103', child: Text('Block 103')),
      const DropdownMenuItem(value: 'B:105', child: Text('Block 105')),
      const DropdownMenuItem(value: 'B:107', child: Text('Block 107')),
      const DropdownMenuItem(value: 'B:109', child: Text('Block 109')),
      const DropdownMenuItem(value: 'B:111', child: Text('Block 111')),
      // Stations/Platforms
      const DropdownMenuItem(
          value: 'S:Terminal-P1', child: Text('Terminal Station - Platform 1')),
      const DropdownMenuItem(
          value: 'S:Terminal-P2', child: Text('Terminal Station - Platform 2')),
      const DropdownMenuItem(
          value: 'S:Terminal-Bay',
          child: Text('Terminal Station - Bay Platform')),
    ];
  }

// ============================================================================
// POINT CONTROL PANEL
// ============================================================================
  Widget _buildPointControlPanel(TerminalStationController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Point Control Panel',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Control all 10 points across the network',
            style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: controller.points.entries.map((entry) {
            final point = entry.value;
            final isNormal = point.position == PointPosition.normal;

            return ElevatedButton(
              onPressed:
                  point.locked ? null : () => controller.swingPoint(point.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: isNormal ? Colors.green : Colors.orange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(point.id,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    isNormal ? 'NORMAL' : 'REVERSE',
                    style: const TextStyle(fontSize: 9),
                  ),
                  if (point.locked) const Icon(Icons.lock, size: 12),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

// ============================================================================
// WIFI CONTROL PANEL
// ============================================================================
  Widget _buildWiFiControlPanel(TerminalStationController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('WiFi Antenna Control',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            // Ghost Train Visibility Toggle
            Consumer<TerminalStationController>(
              builder: (context, ctrl, _) => IconButton(
                icon: Icon(ctrl.showGhostTrains
                    ? Icons.visibility
                    : Icons.visibility_off),
                tooltip: 'Toggle Ghost Trains (Shadow Mode)',
                onPressed: () => ctrl.toggleGhostTrainsVisibility(),
                color: ctrl.showGhostTrains ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('15 WiFi antennas across all 3 sections',
            style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 12),

        // Group by section
        _buildWiFiSection('LEFT SECTION',
            ['W_L1', 'W_L2', 'W_L3', 'W_L4', 'W_L5'], controller),
        const Divider(),
        _buildWiFiSection('MIDDLE SECTION',
            ['W_C1', 'W_C2', 'W_C3', 'W_C4', 'W_C5'], controller),
        const Divider(),
        _buildWiFiSection('RIGHT SECTION',
            ['W_R1', 'W_R2', 'W_R3', 'W_R4', 'W_R5'], controller),
      ],
    );
  }

  Widget _buildWiFiSection(String title, List<String> wifiIds,
      TerminalStationController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: wifiIds.map((wifiId) {
            final wifi = controller.wifiAntennas[wifiId];
            if (wifi == null) return const SizedBox.shrink();

            return Card(
              color: wifi.isActive ? Colors.green[50] : Colors.grey[200],
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wifi,
                          color: wifi.isActive ? Colors.green : Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(wifiId,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Switch(
                      value: wifi.isActive,
                      onChanged: (value) =>
                          controller.toggleWifiAntenna(wifiId),
                      activeColor: Colors.green,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

// ============================================================================
// TIMETABLE MANAGEMENT PANEL
// ============================================================================
  Widget _buildTimetableManagementPanel(TerminalStationController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Timetable Management',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        // Timetable Active Toggle
        Card(
          color:
              controller.timetableActive ? Colors.green[50] : Colors.grey[100],
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  controller.timetableActive
                      ? Icons.schedule
                      : Icons.schedule_outlined,
                  color:
                      controller.timetableActive ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Timetable Service',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        controller.timetableActive
                            ? 'Active - Automated Operation'
                            : 'Inactive',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: controller.timetableActive,
                  onChanged: (value) => controller.toggleTimetableActive(),
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Generate Ghost Trains Button
        ElevatedButton.icon(
          onPressed: () {
            controller.generateGhostTrainsForAllServices();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Generated ${controller.ghostTrains.length} ghost trains')),
            );
          },
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Generate Ghost Trains'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),

        Text(
            '${controller.ghostTrains.length} ghost trains | ${controller.getAvailableGhostTrains().length} available',
            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 12),

        // Train Assignment Section
        if (controller.trains.isNotEmpty) ...[
          const Text('Assign Trains to Timetable',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...controller.trains.map((train) {
            final isAssigned = train.assignedTimetableId != null;

            return Card(
              color: isAssigned ? Colors.blue[50] : null,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: train.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            train.name,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (isAssigned)
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 16),
                      ],
                    ),
                    if (isAssigned) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Assigned to: ${train.assignedTimetableId}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                      if (train.earlyLateSeconds != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          train.earlyLateSeconds! > 0
                              ? 'Running LATE by ${train.earlyLateSeconds}s'
                              : train.earlyLateSeconds! < 0
                                  ? 'Running EARLY by ${-train.earlyLateSeconds!}s'
                                  : 'ON TIME',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: train.earlyLateSeconds! > 0
                                ? Colors.red
                                : train.earlyLateSeconds! < 0
                                    ? Colors.orange
                                    : Colors.green,
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isAssigned &&
                            controller.getAvailableGhostTrains().isNotEmpty)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final ghostTrain =
                                    controller.getAvailableGhostTrains().first;
                                controller.assignTrainToTimetableSlot(
                                    train.id, ghostTrain.id);
                              },
                              icon: const Icon(Icons.add_task, size: 14),
                              label: const Text('Assign',
                                  style: TextStyle(fontSize: 11)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                              ),
                            ),
                          ),
                        if (isAssigned) ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => controller
                                  .unassignTrainFromTimetable(train.id),
                              icon: const Icon(Icons.remove_circle, size: 14),
                              label: const Text('Unassign',
                                  style: TextStyle(fontSize: 11)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (controller.getAvailableGhostTrains().isNotEmpty)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  final ghostTrain = controller
                                      .getAvailableGhostTrains()
                                      .first;
                                  controller.reassignTrainToTimetableSlot(
                                      train.id, ghostTrain.id);
                                },
                                icon: const Icon(Icons.swap_horiz, size: 14),
                                label: const Text('Reassign',
                                    style: TextStyle(fontSize: 11)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ],
    );
  }
}

/// Custom painter for marquee selection rectangle
class MarqueeSelectionPainter extends CustomPainter {
  final Offset start;
  final Offset end;

  MarqueeSelectionPainter({required this.start, required this.end});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw selection rectangle with dashed border
    final rect = Rect.fromPoints(start, end);

    // Fill with semi-transparent cyan
    final fillPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, fillPaint);

    // Draw dashed border
    final borderPaint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw dashed lines
    _drawDashedRect(canvas, rect, borderPaint, dashWidth: 8, dashSpace: 4);
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint, {required double dashWidth, required double dashSpace}) {
    // Top edge
    _drawDashedLine(canvas, rect.topLeft, rect.topRight, paint, dashWidth, dashSpace);
    // Right edge
    _drawDashedLine(canvas, rect.topRight, rect.bottomRight, paint, dashWidth, dashSpace);
    // Bottom edge
    _drawDashedLine(canvas, rect.bottomRight, rect.bottomLeft, paint, dashWidth, dashSpace);
    // Left edge
    _drawDashedLine(canvas, rect.bottomLeft, rect.topLeft, paint, dashWidth, dashSpace);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint, double dashWidth, double dashSpace) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final dashCount = (distance / (dashWidth + dashSpace)).floor();

    final unitX = dx / distance;
    final unitY = dy / distance;

    for (int i = 0; i < dashCount; i++) {
      final startX = start.dx + (dashWidth + dashSpace) * i * unitX;
      final startY = start.dy + (dashWidth + dashSpace) * i * unitY;
      final endX = startX + dashWidth * unitX;
      final endY = startY + dashWidth * unitY;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(MarqueeSelectionPainter oldDelegate) {
    return start != oldDelegate.start || end != oldDelegate.end;
  }
}



