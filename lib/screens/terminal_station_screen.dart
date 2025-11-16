import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'terminal_station_models.dart';
import '../controllers/terminal_station_controller.dart';
import '../widgets/collision_alarm_ui.dart';
import 'dart:math' as math;

// ============================================================================
// TERMINAL STATION SCREEN
// ============================================================================

import 'terminal_station_painter.dart';

class TerminalStationScreen extends StatefulWidget {
  const TerminalStationScreen({Key? key}) : super(key: key);

  @override
  State<TerminalStationScreen> createState() => _TerminalStationScreenState();
}

class _TerminalStationScreenState extends State<TerminalStationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _animationTick = 0;
  double _cameraOffsetX = 0;
  double _zoom = 0.8;
  bool _showLeftPanel = true;
  bool _showRightPanel = true;
  bool _showTopPanel = false;
  String? _selectedBlockForTrain;

  // NEW: Canvas size controls
  double _canvasWidth = 1600.0; // Default width
  double _canvasHeight = 400.0; // Default height
  final double _defaultCanvasWidth = 1600.0;
  final double _defaultCanvasHeight = 400.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(() {
        if (mounted) {
          setState(() {
            _animationTick++;
          });
        }
        context.read<TerminalStationController>().updateSimulation();
      });
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
      _canvasWidth = (_canvasWidth - 100.0).clamp(800.0, 3000.0);
    });
  }

  void _increaseCanvasHeight() {
    setState(() {
      _canvasHeight += 50.0;
    });
  }

  void _decreaseCanvasHeight() {
    setState(() {
      _canvasHeight = (_canvasHeight - 50.0).clamp(300.0, 1000.0);
    });
  }

  void _resetCanvasSize() {
    setState(() {
      _canvasWidth = _defaultCanvasWidth;
      _canvasHeight = _defaultCanvasHeight;
      _cameraOffsetX = 0;
      _zoom = 0.8;
    });
  }

  // NEW: Zoom control methods
  void _zoomIn() {
    setState(() {
      _zoom = (_zoom * 1.2).clamp(0.3, 3.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoom = (_zoom / 1.2).clamp(0.3, 3.0);
    });
  }

  void _resetZoom() {
    setState(() {
      _zoom = 0.8;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TerminalStationController>();
    final layoutConfig = controller.currentLayoutConfig;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Railway Simulator'),
        actions: [
          // Layout selector dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<LayoutStyle>(
              value: controller.currentLayoutStyle,
              icon: const Icon(Icons.dashboard_customize, color: Colors.white),
              dropdownColor: Theme.of(context).primaryColor,
              underline: Container(),
              items: [
                DropdownMenuItem(
                  value: LayoutStyle.compact,
                  child: Row(
                    children: const [
                      Icon(Icons.compress, size: 16, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Compact', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: LayoutStyle.standard,
                  child: Row(
                    children: const [
                      Icon(Icons.dashboard, size: 16, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Standard', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: LayoutStyle.expanded,
                  child: Row(
                    children: const [
                      Icon(Icons.expand, size: 16, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Expanded', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
              onChanged: (LayoutStyle? style) {
                if (style != null) {
                  controller.setLayoutStyle(style);
                  setState(() {
                    _zoom = layoutConfig.defaultZoom;
                  });
                }
              },
            ),
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
      body: Column(
        children: [
          // SPAD Alarm - make it smaller and positioned at top
          Container(
            height: 80,
            child: Consumer<TerminalStationController>(
              builder: (context, controller, _) {
                return CollisionAlarmWidget(
                  isActive: controller.spadAlarmActive,
                  currentIncident: controller.currentSpadIncident,
                  onDismiss: () => controller.acknowledgeSPADAlarm(),
                  isSPAD: true,
                  trainStopId: controller.spadTrainStopId,
                );
              },
            ),
          ),
          // Collision Alarm - make it smaller
          Container(
            height: 80,
            child: Consumer<TerminalStationController>(
              builder: (context, controller, _) {
                return CollisionAlarmWidget(
                  isActive: controller.collisionAlarmActive,
                  currentIncident: controller.currentCollisionIncident,
                  onDismiss: () => controller.acknowledgeCollisionAlarm(),
                  onAutoRecover: () {
                    controller.startAutomaticCollisionRecovery();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🤖 Automatic recovery started'),
                        backgroundColor: Colors.blue,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  onManualRecover: () {
                    controller.startManualCollisionRecovery();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎮 Manual recovery enabled'),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  onForceResolve: () => controller.forceCollisionResolution(),
                );
              },
            ),
          ),

          // Layout Info Banner
          _buildLayoutInfoBanner(controller, layoutConfig),

          // Top Control Panel
          if (_showTopPanel) _buildTopControlPanel(layoutConfig),

          Expanded(
            child: Stack(
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
                if (_showLeftPanel)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: layoutConfig.leftPanelWidth,
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
                      child: _buildControlPanel(layoutConfig),
                    ),
                  ),

                // Layer 4: Right Sidebar (higher z-order)
                if (_showRightPanel)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: layoutConfig.rightPanelWidth,
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
                      child: _buildStatusPanel(layoutConfig),
                    ),
                  ),

                // Layer 5: Toggle buttons (highest z-order)
                // Left panel toggle button
                Positioned(
                  left: _showLeftPanel ? layoutConfig.leftPanelWidth : 0,
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
                ),

                // Right panel toggle button
                Positioned(
                  right: _showRightPanel ? layoutConfig.rightPanelWidth : 0,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Floating zoom controls
  Widget _buildFloatingZoomControls() {
    return Consumer<TerminalStationController>(
      builder: (context, controller, _) {
        final layoutConfig = controller.currentLayoutConfig;
        final buttonSize = layoutConfig.zoomControlSize;
        final isCompact = layoutConfig.compactControls;

        return Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: EdgeInsets.all(isCompact ? 6 : 8),
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
                  style: TextStyle(
                    fontSize: layoutConfig.labelFontSize * 0.9,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: isCompact ? 4 : 8),
                // Zoom in button
                SizedBox(
                  width: buttonSize,
                  height: buttonSize,
                  child: FloatingActionButton(
                    onPressed: _zoomIn,
                    heroTag: 'zoom_in',
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.zoom_in, size: buttonSize * 0.5),
                  ),
                ),
                SizedBox(height: isCompact ? 4 : 8),
                // Zoom reset button
                SizedBox(
                  width: buttonSize,
                  height: buttonSize,
                  child: FloatingActionButton(
                    onPressed: _resetZoom,
                    heroTag: 'zoom_reset',
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.refresh, size: buttonSize * 0.5),
                  ),
                ),
                SizedBox(height: isCompact ? 4 : 8),
                // Zoom out button
                SizedBox(
                  width: buttonSize,
                  height: buttonSize,
                  child: FloatingActionButton(
                    onPressed: _zoomOut,
                    heroTag: 'zoom_out',
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.zoom_out, size: buttonSize * 0.5),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

  // Layout Info Banner
  Widget _buildLayoutInfoBanner(TerminalStationController controller, LayoutConfiguration layoutConfig) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getLayoutColor(layoutConfig.style).withOpacity(0.2),
            _getLayoutColor(layoutConfig.style).withOpacity(0.1),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: _getLayoutColor(layoutConfig.style),
            width: 2,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getLayoutIcon(layoutConfig.style),
            size: 18,
            color: _getLayoutColor(layoutConfig.style),
          ),
          const SizedBox(width: 8),
          Text(
            'Layout: ${controller.getLayoutStyleName()} - ${controller.getLayoutStyleDescription()}',
            style: TextStyle(
              fontSize: layoutConfig.controlFontSize - 1,
              fontWeight: FontWeight.w600,
              color: _getLayoutColor(layoutConfig.style),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLayoutColor(LayoutStyle style) {
    switch (style) {
      case LayoutStyle.compact:
        return Colors.purple;
      case LayoutStyle.standard:
        return Colors.blue;
      case LayoutStyle.expanded:
        return Colors.green;
    }
  }

  IconData _getLayoutIcon(LayoutStyle style) {
    switch (style) {
      case LayoutStyle.compact:
        return Icons.compress;
      case LayoutStyle.standard:
        return Icons.dashboard;
      case LayoutStyle.expanded:
        return Icons.expand;
    }
  }

  // Top Control Panel Method
  Widget _buildTopControlPanel(LayoutConfiguration layoutConfig) {
    return Container(
      height: layoutConfig.topPanelHeight,
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
    );
  }

  // Top Panel Points Section
  Widget _buildTopPointsSection(TerminalStationController controller) {
    final point78A = controller.points['78A'];
    final point78B = controller.points['78B'];
    final ab104Occupied = controller.ace.isABOccupied('AB104');
    final ab106Occupied = controller.ace.isABOccupied('AB106');
    final ab109Occupied = controller.ace.isABOccupied('AB109');

    final ab106DeadlockActive = ab106Occupied;
    final anyABDeadlock = ab104Occupied || ab106Occupied || ab109Occupied;

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
                  color: ab106DeadlockActive ? Colors.deepOrange : Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  ab106DeadlockActive ? 'AB106 DEADLOCK' : 'AB DEADLOCKED',
                  style: const TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Point 78A Control
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        '78A',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: (ab104Occupied || ab106Occupied)
                                ? (ab106Occupied
                                    ? Colors.deepOrange
                                    : Colors.red)
                                : Colors.black),
                      ),
                      if (ab104Occupied || ab106Occupied) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.block,
                            size: 10,
                            color:
                                ab106Occupied ? Colors.deepOrange : Colors.red),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: ((ab104Occupied || ab106Occupied) ||
                                (point78A?.locked ?? false))
                            ? null
                            : () {
                                point78A!.position = PointPosition.normal;
                                controller.notifyListeners();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              point78A?.position == PointPosition.normal
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
                        onPressed: ((ab104Occupied || ab106Occupied) ||
                                (point78A?.locked ?? false))
                            ? null
                            : () {
                                point78A!.position = PointPosition.reverse;
                                controller.notifyListeners();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              point78A?.position == PointPosition.reverse
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
                  const SizedBox(height: 4),
                  Text(
                    ab106Occupied
                        ? 'AB106 Occupied'
                        : ab104Occupied
                            ? 'AB104 Occupied'
                            : 'Free',
                    style: TextStyle(
                      fontSize: 8,
                      color: ab106Occupied
                          ? Colors.deepOrange
                          : ab104Occupied
                              ? Colors.red
                              : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Point 78B Control
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        '78B',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: (ab109Occupied || ab106Occupied)
                                ? (ab106Occupied
                                    ? Colors.deepOrange
                                    : Colors.red)
                                : Colors.black),
                      ),
                      if (ab109Occupied || ab106Occupied) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.block,
                            size: 10,
                            color:
                                ab106Occupied ? Colors.deepOrange : Colors.red),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: ((ab109Occupied || ab106Occupied) ||
                                (point78B?.locked ?? false))
                            ? null
                            : () {
                                point78B!.position = PointPosition.normal;
                                controller.notifyListeners();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              point78B?.position == PointPosition.normal
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
                        onPressed: ((ab109Occupied || ab106Occupied) ||
                                (point78B?.locked ?? false))
                            ? null
                            : () {
                                point78B!.position = PointPosition.reverse;
                                controller.notifyListeners();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              point78B?.position == PointPosition.reverse
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
                  const SizedBox(height: 4),
                  Text(
                    ab106Occupied
                        ? 'AB106 Occupied'
                        : ab109Occupied
                            ? 'AB109 Occupied'
                            : 'Free',
                    style: TextStyle(
                      fontSize: 8,
                      color: ab106Occupied
                          ? Colors.deepOrange
                          : ab109Occupied
                              ? Colors.red
                              : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // AB106 status indicator
        if (ab106Occupied) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.deepOrange.withOpacity(0.1),
              border: Border.all(color: Colors.deepOrange),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning, size: 12, color: Colors.deepOrange),
                const SizedBox(width: 4),
                Text(
                  'Crossover Occupied - Both Points Locked',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
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
            // Add Train Button
            ElevatedButton(
              onPressed: () => controller.addTrain(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
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

  Widget _buildControlPanel(LayoutConfiguration layoutConfig) {
    return Container(
      width: layoutConfig.leftPanelWidth,
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
              const Divider(height: 32),

              // NEW: Canvas Controls Section
              _buildCanvasControlsSection(),
              const Divider(height: 32),

              // Smart Train Addition
              _buildAddTrainSection(controller),
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
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _selectedBlockForTrain != null
              ? () {
                  controller.addTrainToBlock(_selectedBlockForTrain!);
                  setState(() {
                    _selectedBlockForTrain = null;
                  });
                }
              : null,
          icon: const Icon(Icons.add),
          label: Text(_selectedBlockForTrain != null
              ? 'Add Train to Block $_selectedBlockForTrain'
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

  Widget _buildStationCanvas() {
    return Container(
      color: Colors.grey[200],
      child: Consumer<TerminalStationController>(
        builder: (context, controller, _) {
          return GestureDetector(
            onPanUpdate: (details) {
              setState(() => _cameraOffsetX += details.delta.dx / _zoom);
            },
            child: CustomPaint(
              size: Size(_canvasWidth, _canvasHeight),
              painter: TerminalStationPainter(
                controller: controller,
                cameraOffsetX: _cameraOffsetX,
                zoom: _zoom,
                animationTick: _animationTick,
                canvasWidth: _canvasWidth,
                canvasHeight: _canvasHeight,
                layoutConfig: controller.currentLayoutConfig,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusPanel(LayoutConfiguration layoutConfig) {
    return Container(
      width: layoutConfig.rightPanelWidth,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
            left: BorderSide(color: Theme.of(context).colorScheme.outline)),
      ),
      child: Consumer<TerminalStationController>(
        builder: (context, controller, _) {
          final stats = controller.getStats();
          return ListView(
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
                          style:
                              TextStyle(fontSize: 10, color: Colors.grey[600])),
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
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: () => controller.resetACE(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
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
                        children: controller.axleCounters.entries.map((entry) {
                          final counter = entry.value;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey[300]!),
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

                      // AB Results
                      const Text('AB Occupation Results:',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...['AB100', 'AB105', 'AB106', 'AB108', 'AB111']
                          .map((abId) {
                        final isOccupied = controller.ace.isABOccupied(abId);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 4),
                          color:
                              isOccupied ? Colors.purple[50] : Colors.grey[50],
                          child: ListTile(
                            dense: true,
                            title: Text(abId,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isOccupied ? Colors.purple : Colors.grey,
                                )),
                            subtitle:
                                Text(isOccupied ? 'OCCUPIED' : 'UNOCCUPIED',
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
                                color:
                                    isOccupied ? Colors.purple : Colors.green,
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
              _buildStatusCard('Trains', '${stats['trains']}', Colors.blue),
              _buildStatusCard('Occupied Blocks', '${stats['occupied_blocks']}',
                  Colors.orange),
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
              _buildStatusCard(
                  'Active Routes', '${stats['active_routes']}', Colors.green),
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
                  stats['train_stops_enabled'] ? Colors.red : Colors.grey),
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
                  stats['point_78a_deadlocked'] ? Colors.red : Colors.green),
              _buildStatusCard(
                  'Point 78B Deadlocked',
                  stats['point_78b_deadlocked'] ? 'YES' : 'NO',
                  stats['point_78b_deadlocked'] ? Colors.red : Colors.green),
              _buildStatusCard(
                  'AB104 Occupied',
                  stats['ab104_occupied'] ? 'YES' : 'NO',
                  stats['ab104_occupied'] ? Colors.orange : Colors.green),
              _buildStatusCard(
                  'AB106 Occupied',
                  stats['ab106_occupied'] ? 'YES' : 'NO',
                  stats['ab106_occupied'] ? Colors.deepOrange : Colors.green),
              _buildStatusCard(
                  'AB109 Occupied',
                  stats['ab109_occupied'] ? 'YES' : 'NO',
                  stats['ab109_occupied'] ? Colors.orange : Colors.green),
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
                final isDeadlocked =
                    (point.id == '78A' && stats['point_78a_deadlocked']) ||
                        (point.id == '78B' && stats['point_78b_deadlocked']);
                final deadlockReason = point.id == '78A'
                    ? (stats['ab106_occupied'] ? 'AB106' : 'AB104')
                    : (stats['ab106_occupied'] ? 'AB106' : 'AB109');

                return Card(
                  child: ListTile(
                    dense: true,
                    title: Row(
                      children: [
                        Text(point.id, style: const TextStyle(fontSize: 13)),
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
                final isPendingCancellation =
                    controller.isRoutePendingCancellation(reservation.signalId);
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
                    } else if (event.contains('⚠️') || event.contains('🟡')) {
                      textColor = Colors.orangeAccent;
                    } else if (event.contains('🔒') || event.contains('🔓')) {
                      textColor = Colors.blueAccent;
                    } else if (event.contains('🔄') || event.contains('🔧')) {
                      textColor = Colors.yellowAccent;
                    } else if (event.contains('✅') || event.contains('🎉')) {
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
                              backgroundColor: controller.axleCountersVisible
                                  ? Colors.purple
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
                            icon: const Icon(Icons.cleaning_services, size: 16),
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
                                value: 'AB111', // NEW
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
                                        fontSize: 11, color: Colors.white),
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
}
