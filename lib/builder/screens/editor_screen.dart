import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/railway_provider.dart';
import '../widgets/toolbox_panel.dart';
import '../widgets/properties_panel.dart';
import '../widgets/canvas_view.dart';
import '../widgets/top_toolbar.dart';
import '../widgets/left_sidebar.dart';
import '../widgets/right_sidebar.dart';
import '../widgets/tab_bar.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const TopToolbar(),
          const TabBarWidget(),
          Expanded(
            child: Row(
              children: [
                Consumer<RailwayProvider>(
                  builder: (context, provider, child) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: provider.leftSidebarVisible ? 280 : 0,
                      child: provider.leftSidebarVisible
                          ? const LeftSidebar()
                          : const SizedBox.shrink(),
                    );
                  },
                ),
                Expanded(
                  child: Container(
                    color: Colors.grey[100],
                    child: const CanvasView(),
                  ),
                ),
                Consumer<RailwayProvider>(
                  builder: (context, provider, child) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: provider.rightSidebarVisible ? 320 : 0,
                      child: provider.rightSidebarVisible
                          ? const RightSidebar()
                          : const SizedBox.shrink(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
