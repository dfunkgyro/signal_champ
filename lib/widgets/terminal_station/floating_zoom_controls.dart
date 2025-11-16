import 'package:flutter/material.dart';

class FloatingZoomControls extends StatelessWidget {
  final double zoom;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetZoom;

  const FloatingZoomControls({
    Key? key,
    required this.zoom,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetZoom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              'Zoom: ${(zoom * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            // Zoom in button
            FloatingActionButton.small(
              onPressed: onZoomIn,
              heroTag: 'zoom_in',
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              child: const Icon(Icons.zoom_in),
            ),
            const SizedBox(height: 8),
            // Zoom reset button
            FloatingActionButton.small(
              onPressed: onResetZoom,
              heroTag: 'zoom_reset',
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
              child: const Icon(Icons.refresh),
            ),
            const SizedBox(height: 8),
            // Zoom out button
            FloatingActionButton.small(
              onPressed: onZoomOut,
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
}
