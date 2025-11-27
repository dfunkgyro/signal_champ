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
        .replaceAll('208', 'Track 208')
        .replaceAll('210', 'Track 210')
        .replaceAll('211', 'Track 211')
        .replaceAll('213', 'Track 213')
        .replaceAll('300', 'Track 300')
        .replaceAll('301', 'Track 301')
        .replaceAll('302', 'Track 302')
        .replaceAll('303', 'Track 303')
        .replaceAll('crossover106', 'Crossover 106')
        .replaceAll('crossover109', 'Crossover 109')
        .replaceAll('crossover_211_212', 'Crossover 211-212')
        .replaceAll('crossover_303_304', 'Crossover 303-304')
        .replaceAll('→', ' → ');
  }

  List<Map<String, dynamic>> _getAllCrossoverRoutes() {
    return [
      // Left section crossovers (76A/76B, 77A/77B)
      {
        'route': '208→crossover_211_212→211',
        'description': 'Eastbound (Upper Track → Lower Track via 76A/76B reversed)',
      },
      {
        'route': '210→crossover_211_212→213',
        'description': 'Eastbound (Upper Track → Lower Track via 77A/77B reversed)',
      },
      {
        'route': '211→crossover_211_212→208',
        'description': 'Westbound (Lower Track → Upper Track via 76B/76A reversed)',
      },
      {
        'route': '213→crossover_211_212→210',
        'description': 'Westbound (Lower Track → Upper Track via 77B/77A reversed)',
      },

      // Middle section crossovers (78A/78B)
      {
        'route': '104→crossover106→crossover109→109',
        'description': 'Eastbound (Upper Track → Lower Track via 78A/78B reversed)',
      },
      {
        'route': '109→crossover109→crossover106→104',
        'description': 'Westbound (Lower Track → Upper Track via 78B/78A reversed)',
      },

      // Right section crossovers (79A/79B, 80A/80B)
      {
        'route': '300→crossover_303_304→301',
        'description': 'Eastbound (Upper Track → Lower Track via 79A/79B reversed)',
      },
      {
        'route': '302→crossover_303_304→303',
        'description': 'Eastbound (Upper Track → Lower Track via 80A/80B reversed)',
      },
      {
        'route': '301→crossover_303_304→300',
        'description': 'Westbound (Lower Track → Upper Track via 79B/79A reversed)',
      },
      {
        'route': '303→crossover_303_304→302',
        'description': 'Westbound (Lower Track → Upper Track via 80B/80A reversed)',
      },
    ];
  }
}
