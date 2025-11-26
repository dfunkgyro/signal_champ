import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Unified App Bar with consistent styling across all screens
/// Provides modern design with proper elevation and theming
class UnifiedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final Color? backgroundColor;
  final double? elevation;

  const UnifiedAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.onBackPressed,
    this.bottom,
    this.centerTitle = true,
    this.backgroundColor,
    this.elevation,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      title: Text(
        title,
        style: AppTypography.h3.copyWith(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: leading ??
          (showBackButton
              ? IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                  tooltip: 'Back',
                )
              : null),
      actions: actions,
      centerTitle: centerTitle,
      elevation: elevation ?? 0,
      backgroundColor: backgroundColor ??
          (isDark ? AppColors.surfaceDark : theme.colorScheme.surface),
      surfaceTintColor: Colors.transparent,
      shadowColor: isDark
          ? Colors.black.withOpacity(0.5)
          : Colors.black.withOpacity(0.1),
      bottom: bottom,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.surfaceDarkElevated,
                    AppColors.surfaceDark,
                  ],
                )
              : null,
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.grey800 : Colors.grey[300]!,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// App Bar Action Button with consistent styling
class AppBarActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color? color;

  const AppBarActionButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return IconButton(
      icon: Icon(
        icon,
        color: color ?? (isDark ? Colors.white : Colors.black87),
        size: AppIconSize.md,
      ),
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.medium,
        ),
      ),
    );
  }
}
