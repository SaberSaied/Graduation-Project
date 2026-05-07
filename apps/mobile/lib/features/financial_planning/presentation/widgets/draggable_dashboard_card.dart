import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class DraggableDashboardCard extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onToggleCollapse;
  final bool isCollapsed;
  final Color? accentColor;
  final Widget? trailing;
  final VoidCallback? onActionTap;
  final String? actionLabel;

  const DraggableDashboardCard({
    super.key,
    required this.title,
    required this.child,
    this.onToggleCollapse,
    this.isCollapsed = false,
    this.accentColor,
    this.trailing,
    this.onActionTap,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (accentColor ?? (isDark ? AppColors.dividerDark : AppColors.dividerLight)).withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: isDark 
              ? AppColors.surfaceDark.withValues(alpha: 0.8) 
              : AppColors.surfaceLight.withValues(alpha: 0.8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                InkWell(
                  onTap: onToggleCollapse,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: accentColor ?? AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (onActionTap != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: TextButton(
                              onPressed: onActionTap,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: (accentColor ?? AppColors.primary).withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                actionLabel ?? 'See All',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: accentColor ?? AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        if (trailing != null) trailing!,
                        Icon(
                          isCollapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Content
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: child,
                  crossFadeState: isCollapsed ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
