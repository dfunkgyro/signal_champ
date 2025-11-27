import 'package:flutter/material.dart';
import '../models/railway_model.dart';

/// Displays all possible crossover routes with current active route highlighted
class CrossoverRouteTable extends StatefulWidget {
  final RailwayModel model;

  const CrossoverRouteTable({
    Key? key,
    required this.model,
  }) : super(key: key);

  @override
  State<CrossoverRouteTable> createState() => _CrossoverRouteTableState();
}

class _CrossoverRouteTableState extends State<CrossoverRouteTable> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    // Get all crossover routes
    final routes = _getAllCrossoverRoutes();

    // Find active route from trains
    String? activeRoute;
    for (final train in widget.model.trains) {
      if (train.isOnCrossover && train.currentCrossoverRoute != null) {
        activeRoute = train.currentCrossoverRoute;
        break;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.alt_route,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Crossover Route Table',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final route in routes)
                    _buildRouteItem(
                      context,
                      route,
                      isActive: activeRoute == route['route'],
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRouteItem(
    BuildContext context,
    Map<String, dynamic> route, {
    bool isActive = false,
  }) {
    final routeText = route['route'] as String;
    final description = route['description'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isActive
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatRoute(routeText),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }

  String _formatRoute(String route) {
    // Replace block IDs with "Track" labels
    return route
        .replaceAll('104', 'Track 104')
        .replaceAll('109', 'Track 109')
        .replaceAll('→', ' → ');
  }

  List<Map<String, dynamic>> _getAllCrossoverRoutes() {
    return [
      {
        'route': '104→crossover106→crossover109→109',
        'description': 'Eastbound (Upper Track → Lower Track via 78A/78B reversed)',
      },
      {
        'route': '109→crossover109→crossover106→104',
        'description': 'Westbound (Lower Track → Upper Track via 78B/78A reversed)',
      },
    ];
  }
}
