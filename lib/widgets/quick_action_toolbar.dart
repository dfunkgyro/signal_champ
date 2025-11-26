import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Quick Action Toolbar for frequently used controls
/// Can be positioned at top or bottom of screen
class QuickActionToolbar extends StatelessWidget {
  final List<QuickAction> actions;
  final ToolbarPosition position;
  final Color? backgroundColor;
  final bool showLabels;
  final EdgeInsets? padding;

  const QuickActionToolbar({
    Key? key,
    required this.actions,
    this.position = ToolbarPosition.top,
    this.backgroundColor,
    this.showLabels = true,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.grey900,
                  AppColors.grey850,
                ],
              )
            : null,
        color: backgroundColor ??
            (isDark ? null : theme.colorScheme.surface.withOpacity(0.95)),
        border: Border(
          top: position == ToolbarPosition.bottom
              ? BorderSide(
                  color: isDark ? AppColors.grey800 : Colors.grey[300]!,
                  width: 1,
                )
              : BorderSide.none,
          bottom: position == ToolbarPosition.top
              ? BorderSide(
                  color: isDark ? AppColors.grey800 : Colors.grey[300]!,
                  width: 1,
                )
              : BorderSide.none,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: Offset(0, position == ToolbarPosition.top ? 2 : -2),
          ),
        ],
      ),
      child: SafeArea(
        top: position == ToolbarPosition.top,
        bottom: position == ToolbarPosition.bottom,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: actions
              .map((action) => _buildAction(context, action, theme, isDark))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildAction(
    BuildContext context,
    QuickAction action,
    ThemeData theme,
    bool isDark,
  ) {
    final isActive = action.isActive ?? false;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: action.enabled ? action.onPressed : null,
          borderRadius: AppBorderRadius.medium,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.colorScheme.primary.withOpacity(0.15)
                        : (action.enabled
                            ? (isDark
                                ? AppColors.grey800
                                : Colors.grey[200])
                            : Colors.transparent),
                    borderRadius: AppBorderRadius.medium,
                    border: isActive
                        ? Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.5),
                            width: 1.5,
                          )
                        : null,
                  ),
                  child: Icon(
                    action.icon,
                    size: AppIconSize.md,
                    color: !action.enabled
                        ? (isDark ? AppColors.grey700 : AppColors.grey400)
                        : (isActive
                            ? theme.colorScheme.primary
                            : (isDark ? AppColors.grey400 : AppColors.grey700)),
                  ),
                ),
                if (showLabels) ...[
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    action.label,
                    style: AppTypography.captionSmall.copyWith(
                      color: !action.enabled
                          ? (isDark ? AppColors.grey700 : AppColors.grey400)
                          : (isActive
                              ? theme.colorScheme.primary
                              : (isDark
                                  ? AppColors.grey400
                                  : AppColors.grey700)),
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Position for the toolbar
enum ToolbarPosition {
  top,
  bottom,
}

/// Quick Action item
class QuickAction {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;
  final bool? isActive;
  final String? tooltip;

  const QuickAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
    this.isActive,
    this.tooltip,
  });
}

/// Compact Quick Action Toolbar (icon only, no labels)
class CompactQuickActionToolbar extends StatelessWidget {
  final List<QuickAction> actions;
  final Color? backgroundColor;

  const CompactQuickActionToolbar({
    Key? key,
    required this.actions,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isDark ? AppColors.grey850 : theme.colorScheme.surface),
        borderRadius: AppBorderRadius.large,
        boxShadow: AppElevation.getShadow(AppElevation.level3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: actions.asMap().entries.map((entry) {
          final index = entry.key;
          final action = entry.value;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (index > 0)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Container(
                    width: 1,
                    height: AppIconSize.md,
                    color: isDark ? AppColors.grey700 : Colors.grey[300],
                  ),
                ),
              IconButton(
                icon: Icon(
                  action.icon,
                  size: AppIconSize.sm,
                ),
                onPressed: action.enabled ? action.onPressed : null,
                tooltip: action.tooltip ?? action.label,
                color: (action.isActive ?? false)
                    ? theme.colorScheme.primary
                    : (isDark ? AppColors.grey400 : AppColors.grey700),
                style: IconButton.styleFrom(
                  backgroundColor: (action.isActive ?? false)
                      ? theme.colorScheme.primary.withOpacity(0.15)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppBorderRadius.small,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
