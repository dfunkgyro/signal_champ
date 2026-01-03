import 'package:flutter/material.dart';
import 'theme/design_tokens.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 72,
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
        color: isDark ? null : theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.grey800 : Colors.grey[300]!,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context,
              icon: Icons.directions_railway_rounded,
              activeIcon: Icons.directions_railway,
              label: 'Simulation',
              index: 0,
              isActive: currentIndex == 0,
            ),
            _buildNavItem(
              context,
              icon: Icons.build_outlined,
              activeIcon: Icons.build,
              label: 'Builder',
              index: 1,
              isActive: currentIndex == 1,
            ),
            _buildNavItem(
              context,
              icon: Icons.analytics_outlined,
              activeIcon: Icons.analytics_rounded,
              label: 'Analytics',
              index: 2,
              isActive: currentIndex == 2,
            ),
            _buildNavItem(
              context,
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings_rounded,
              label: 'Settings',
              index: 3,
              isActive: currentIndex == 3,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isActive,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          borderRadius: AppBorderRadius.large,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.sm,
            ),
            child: AnimatedContainer(
              duration: AppAnimations.normal,
              curve: AppAnimations.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.15),
                          theme.colorScheme.primary.withOpacity(0.05),
                        ],
                      )
                    : null,
                borderRadius: AppBorderRadius.large,
                border: isActive
                    ? Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        width: 1,
                      )
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: AppAnimations.fast,
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: Icon(
                      isActive ? activeIcon : icon,
                      key: ValueKey(isActive),
                      color: isActive
                          ? theme.colorScheme.primary
                          : (isDark ? AppColors.grey500 : AppColors.grey600),
                      size: AppIconSize.lg,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  AnimatedDefaultTextStyle(
                    duration: AppAnimations.fast,
                    style: AppTypography.caption.copyWith(
                      color: isActive
                          ? theme.colorScheme.primary
                          : (isDark ? AppColors.grey500 : AppColors.grey600),
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
