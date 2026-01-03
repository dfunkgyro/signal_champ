import 'package:flutter/material.dart';

import '../widgets/graph_canvas.dart';
import '../widgets/graph_toolbar.dart';
import '../widgets/graph_sidebar.dart';

class GraphEditorScreen extends StatelessWidget {
  const GraphEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const GraphToolbar(),
          Expanded(
            child: Row(
              children: const [
                GraphToolboxPanel(),
                Expanded(child: GraphCanvas()),
                GraphPropertiesPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
