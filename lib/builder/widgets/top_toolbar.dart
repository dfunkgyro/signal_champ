import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import '../providers/railway_provider.dart';
import '../utils/sample_data.dart';

class TopToolbar extends StatelessWidget {
  const TopToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RailwayProvider>(context);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Row(
            children: [
              Icon(Icons.train, color: Colors.blue[700], size: 28),
              const SizedBox(width: 8),
              const Text(
                'Railway Track Editor',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              _buildViewToggle(
                icon: Icons.grid_on,
                tooltip: 'Toggle Grid',
                active: provider.showGrid,
                onTap: () => provider.showGrid = !provider.showGrid,
              ),
              const SizedBox(width: 8),
              _buildViewToggle(
                icon: Icons.pin_drop,
                tooltip: 'Toggle Coordinates',
                active: provider.showCoordinates,
                onTap: () =>
                    provider.showCoordinates = !provider.showCoordinates,
              ),
            ],
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              _buildToolbarButton(
                icon: Icons.zoom_out,
                tooltip: 'Zoom Out',
                onTap: () {
                  if (provider.zoomLevel > 0.2) {
                    provider.zoomLevel = provider.zoomLevel - 0.1;
                  }
                },
              ),
              const SizedBox(width: 8),
              Text(
                '${(provider.zoomLevel * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              _buildToolbarButton(
                icon: Icons.zoom_in,
                tooltip: 'Zoom In',
                onTap: () {
                  if (provider.zoomLevel < 3.0) {
                    provider.zoomLevel = provider.zoomLevel + 0.1;
                  }
                },
              ),
              const SizedBox(width: 8),
              _buildToolbarButton(
                icon: Icons.refresh,
                tooltip: 'Reset Zoom',
                onTap: () => provider.zoomLevel = 1.0,
              ),
            ],
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              _buildImportExportButton(
                icon: Icons.upload_file,
                label: 'Import',
                onTap: () => _showImportMenu(context),
              ),
              const SizedBox(width: 8),
              _buildImportExportButton(
                icon: Icons.download,
                label: 'Export',
                onTap: () => _showExportMenu(context),
              ),
              const SizedBox(width: 8),
              _buildImportExportButton(
                icon: Icons.library_add,
                label: 'Load Sample',
                onTap: () => _loadSampleData(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle({
    required IconData icon,
    required String tooltip,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: active ? Colors.blue[50] : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active ? Colors.blue : Colors.grey[300]!,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        color: active ? Colors.blue[700] : Colors.grey[600],
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: onTap,
    );
  }

  Widget _buildImportExportButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[50],
        foregroundColor: Colors.blue[700],
        elevation: 0,
      ),
    );
  }

  void _showImportMenu(BuildContext context) {
    final provider = Provider.of<RailwayProvider>(context, listen: false);

    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
      items: [
        PopupMenuItem(
          child: const Text('Import XML'),
          onTap: () => _showImportDialog(context, 'XML'),
        ),
        PopupMenuItem(
          child: const Text('Import SVG'),
          onTap: () => _showImportDialog(context, 'SVG'),
        ),
        PopupMenuItem(
          child: const Text('Import JSON'),
          onTap: () => _showImportDialog(context, 'JSON'),
        ),
      ],
    );
  }

  void _showExportMenu(BuildContext context) {
    final provider = Provider.of<RailwayProvider>(context, listen: false);

    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
      items: [
        PopupMenuItem(
          child: const Text('Export as XML'),
          onTap: () =>
              _showExportDialog(context, 'XML', provider.exportCurrentToXml()),
        ),
        PopupMenuItem(
          child: const Text('Export as SVG'),
          onTap: () =>
              _showExportDialog(context, 'SVG', provider.exportCurrentToSvg()),
        ),
        PopupMenuItem(
          child: const Text('Export as JSON'),
          onTap: () => _showExportDialog(
              context, 'JSON', provider.exportCurrentToJson()),
        ),
      ],
    );
  }

  void _showImportDialog(BuildContext context, String format) {
    final controller = TextEditingController();
    final provider = Provider.of<RailwayProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Import $format'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: Column(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  expands: true,
                  decoration: InputDecoration(
                    hintText: 'Paste your $format content here...',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (controller.text.isNotEmpty) {
                        try {
                          switch (format) {
                            case 'XML':
                              provider.importFromXml(controller.text);
                              break;
                            case 'SVG':
                              provider.importFromSvg(controller.text);
                              break;
                            case 'JSON':
                              provider.importFromJson(controller.text);
                              break;
                          }
                          Navigator.of(context).pop();
                          _showSuccessSnackbar(
                              context, '$format imported successfully');
                        } catch (e) {
                          _showErrorSnackbar(
                              context, 'Failed to import $format: $e');
                        }
                      }
                    },
                    child: const Text('Import'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context, String format, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exported $format'),
        content: SizedBox(
          width: 700,
          height: 500,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      content,
                      style: const TextStyle(
                          fontFamily: 'Monospace', fontSize: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy to Clipboard',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: content));
                      _showSuccessSnackbar(
                          context, '$format copied to clipboard');
                    },
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _loadSampleData(BuildContext context) {
    final provider = Provider.of<RailwayProvider>(context, listen: false);
    try {
      provider.importFromXml(SampleData.sampleXml);
      _showSuccessSnackbar(context, 'Sample data loaded successfully');
    } catch (e) {
      _showErrorSnackbar(context, 'Failed to load sample data: $e');
    }
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
