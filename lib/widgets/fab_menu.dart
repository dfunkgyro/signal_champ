import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Floating Action Button Menu for common actions
/// Expands to show multiple action options
class FABMenu extends StatefulWidget {
  final List<FABMenuItem> items;
  final IconData mainIcon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const FABMenu({
    Key? key,
    required this.items,
    this.mainIcon = Icons.add_rounded,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  State<FABMenu> createState() => _FABMenuState();
}

class _FABMenuState extends State<FABMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.normal,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Menu Items
        ...List.generate(
          widget.items.length,
          (index) => ScaleTransition(
            scale: CurvedAnimation(
              parent: _expandAnimation,
              curve: Interval(
                0.0,
                1.0 - (index * 0.1).clamp(0.0, 0.5),
                curve: Curves.easeOut,
              ),
            ),
            child: FadeTransition(
              opacity: _expandAnimation,
              child: Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: _buildMenuItem(
                  context,
                  widget.items[index],
                  theme,
                ),
              ),
            ),
          ),
        ),

        // Main FAB
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: widget.backgroundColor ?? theme.colorScheme.primary,
          foregroundColor: widget.foregroundColor ?? Colors.white,
          elevation: AppElevation.level4,
          tooltip: widget.tooltip ?? 'Menu',
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0.0, // 45 degrees when expanded
            duration: AppAnimations.normal,
            child: Icon(
              _isExpanded ? Icons.close_rounded : widget.mainIcon,
              size: AppIconSize.lg,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    FABMenuItem item,
    ThemeData theme,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Material(
          elevation: AppElevation.level3,
          borderRadius: AppBorderRadius.medium,
          color: isDark ? AppColors.surfaceDarkElevated : Colors.white,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              item.label,
              style: AppTypography.body.copyWith(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        SizedBox(width: AppSpacing.md),

        // Button
        FloatingActionButton.small(
          onPressed: () {
            _toggle();
            item.onPressed();
          },
          backgroundColor: item.backgroundColor ?? theme.colorScheme.secondary,
          foregroundColor: item.foregroundColor ?? Colors.white,
          elevation: AppElevation.level3,
          heroTag: item.label,
          tooltip: item.label,
          child: Icon(item.icon, size: AppIconSize.sm),
        ),
      ],
    );
  }
}

/// Menu Item for FAB Menu
class FABMenuItem {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const FABMenuItem({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });
}

/// Speed Dial style FAB (alternative implementation)
/// Opens radially instead of vertically
class SpeedDialFAB extends StatefulWidget {
  final List<SpeedDialAction> actions;
  final IconData mainIcon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const SpeedDialFAB({
    Key? key,
    required this.actions,
    this.mainIcon = Icons.add_rounded,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  State<SpeedDialFAB> createState() => _SpeedDialFABState();
}

class _SpeedDialFABState extends State<SpeedDialFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.normal,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      alignment: Alignment.bottomRight,
      clipBehavior: Clip.none,
      children: [
        // Backdrop
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggle,
              child: AnimatedContainer(
                duration: AppAnimations.fast,
                color: Colors.black.withOpacity(_isExpanded ? 0.3 : 0.0),
              ),
            ),
          ),

        // Actions in radial layout
        ...List.generate(
          widget.actions.length,
          (index) => _buildActionButton(
            context,
            widget.actions[index],
            index,
            widget.actions.length,
            theme,
          ),
        ),

        // Main FAB
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: widget.backgroundColor ?? theme.colorScheme.primary,
          foregroundColor: widget.foregroundColor ?? Colors.white,
          elevation: AppElevation.level4,
          tooltip: widget.tooltip ?? 'Actions',
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0.0,
            duration: AppAnimations.normal,
            child: Icon(
              _isExpanded ? Icons.close_rounded : widget.mainIcon,
              size: AppIconSize.lg,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    SpeedDialAction action,
    int index,
    int total,
    ThemeData theme,
  ) {
    final angle = (index * 45.0) - 90.0; // Spread in arc from top
    final radians = angle * (3.14159 / 180.0);
    final distance = 80.0;

    final offsetX = distance * (1 - _controller.value) * (index == 0 ? 0 : -1);
    final offsetY = -distance * _controller.value * (index + 1);

    return AnimatedPositioned(
      duration: AppAnimations.normal,
      curve: Curves.easeOut,
      right: offsetX,
      bottom: offsetY,
      child: ScaleTransition(
        scale: _controller,
        child: FloatingActionButton.small(
          onPressed: () {
            _toggle();
            action.onPressed();
          },
          backgroundColor: action.backgroundColor ?? theme.colorScheme.secondary,
          foregroundColor: action.foregroundColor ?? Colors.white,
          heroTag: action.label,
          tooltip: action.label,
          child: Icon(action.icon, size: AppIconSize.sm),
        ),
      ),
    );
  }
}

/// Action for Speed Dial FAB
class SpeedDialAction {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const SpeedDialAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });
}
