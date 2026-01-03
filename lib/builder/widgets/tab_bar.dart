import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/railway_model.dart' as railway;
import '../providers/railway_provider.dart';

class TabBarWidget extends StatelessWidget {
  const TabBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RailwayProvider>(context);

    return Container(
      height: 48,
      color: Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: provider.tabs.length,
              itemBuilder: (context, index) {
                final tab = provider.tabs[index];
                return _buildTabItem(tab, index, provider, context);
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => provider.addNewTab(),
            tooltip: 'New Tab',
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(railway.WorkspaceTab tab, int index,
      RailwayProvider provider, BuildContext context) {
    final isActive = index == provider.currentTabIndex;

    return GestureDetector(
      onTap: () {
        provider.switchTab(index);
      },
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? Colors.blue : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                _getTabIcon(tab.fileType),
                size: 16,
                color: isActive ? Colors.blue : Colors.grey[600],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '${tab.title}${tab.hasUnsavedChanges ? ' •' : ''}',
                style: TextStyle(
                  color: isActive ? Colors.blue : Colors.grey[700],
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (provider.tabs.length > 1)
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () => _showCloseTabDialog(context, index, provider),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getTabIcon(railway.FileType fileType) {
    switch (fileType) {
      case railway.FileType.xml:
        return Icons.code;
      case railway.FileType.svg:
        return Icons.image;
      case railway.FileType.json:
        return Icons.data_object;
      case railway.FileType.newFile:
        return Icons.edit_document;
    }
  }

  void _showCloseTabDialog(
      BuildContext context, int index, RailwayProvider provider) {
    final tab = provider.tabs[index];

    if (tab.hasUnsavedChanges) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: Text('Save changes to "${tab.title}" before closing?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                provider.closeTab(index);
              },
              child: const Text('Don\'t Save'),
            ),
            TextButton(
              onPressed: () {
                provider.markTabSaved();
                Navigator.of(context).pop();
                provider.closeTab(index);
              },
              child: const Text('Save'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } else {
      provider.closeTab(index);
    }
  }
}
