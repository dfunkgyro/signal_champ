import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/block_model.dart';

class SvgCanvas extends StatefulWidget {
  final String svgContent;
  final List<Block> blocks;
  final Block? selectedBlock;
  final Function(Block) onBlockSelected;

  const SvgCanvas({
    super.key,
    required this.svgContent,
    required this.blocks,
    required this.selectedBlock,
    required this.onBlockSelected,
  });

  @override
  State<SvgCanvas> createState() => _SvgCanvasState();
}

class _SvgCanvasState extends State<SvgCanvas> {
  final TransformationController _transformationController =
      TransformationController();
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          _buildToolbar(),
          Expanded(
            child: Center(
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.1,
                maxScale: 4.0,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                onInteractionUpdate: (details) {
                  setState(() {
                    _scale =
                        _transformationController.value.getMaxScaleOnAxis();
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    color: Colors.white,
                  ),
                  child: Stack(
                    children: [
                      if (widget.svgContent.isNotEmpty)
                        SvgPicture.string(
                          widget.svgContent,
                          fit: BoxFit.contain,
                        ),
                      ...widget.blocks.map((block) {
                        return Positioned(
                          left: block.startX,
                          top: block.y - 5,
                          child: GestureDetector(
                            onTap: () => widget.onBlockSelected(block),
                            child: Container(
                              width: block.length,
                              height: 10,
                              decoration: BoxDecoration(
                                color: widget.selectedBlock?.id == block.id
                                    ? Colors.blue.withOpacity(0.3)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: widget.selectedBlock?.id == block.id
                                      ? Colors.blue
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey[200],
      child: Row(
        children: [
          _buildZoomButton(Icons.zoom_out, () => _zoomOut()),
          _buildZoomButton(Icons.zoom_in, () => _zoomIn()),
          _buildZoomButton(Icons.refresh, () => _resetZoom()),
          const SizedBox(width: 16),
          Text('Zoom: ${(_scale * 100).toStringAsFixed(0)}%'),
          const Spacer(),
          _buildViewButton('Show Grid', Icons.grid_on),
          const SizedBox(width: 8),
          _buildViewButton('Show Coordinates', Icons.pin_drop),
        ],
      ),
    );
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      tooltip: _getZoomTooltip(icon),
    );
  }

  Widget _buildViewButton(String text, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
    );
  }

  String _getZoomTooltip(IconData icon) {
    switch (icon) {
      case Icons.zoom_out:
        return 'Zoom Out';
      case Icons.zoom_in:
        return 'Zoom In';
      case Icons.refresh:
        return 'Reset Zoom';
      default:
        return '';
    }
  }

  void _zoomOut() {
    _transformationController.value =
        _transformationController.value.scaled(0.8, 0.8);
    setState(() {
      _scale = _transformationController.value.getMaxScaleOnAxis();
    });
  }

  void _zoomIn() {
    _transformationController.value =
        _transformationController.value.scaled(1.2, 1.2);
    setState(() {
      _scale = _transformationController.value.getMaxScaleOnAxis();
    });
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() {
      _scale = 1.0;
    });
  }
}
