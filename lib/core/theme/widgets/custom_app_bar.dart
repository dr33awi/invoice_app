import 'package:flutter/material.dart';
import 'package:wholesale_shoes_invoice/core/constants/app_colors.dart';
import 'package:wholesale_shoes_invoice/core/constants/app_spacing.dart';

/// Custom AppBar مطابق لتصميم Hoor Manager
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final bool showMenuButton;
  final List<Widget>? actions;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onBackPressed;
  final Widget? leading;
  final Color? backgroundColor;
  final bool showBottomBorder;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = true,
    this.showMenuButton = false,
    this.actions,
    this.onMenuPressed,
    this.onBackPressed,
    this.leading,
    this.backgroundColor,
    this.showBottomBorder = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceBg,
        border: showBottomBorder
            ? const Border(
                bottom: BorderSide(
                  color: AppColors.borderColor,
                  width: 1,
                ),
              )
            : null,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              // Leading (Menu or Back button)
              if (leading != null)
                leading!
              else if (showMenuButton)
                _buildMenuButton(context)
              else if (showBackButton)
                _buildBackButton(context),

              AppSpacing.gapHorizontalSm,

              // Title & Subtitle
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                  ],
                ),
              ),

              // Actions
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.screenBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: IconButton(
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
        icon: const Icon(
          Icons.arrow_back_ios_new,
          size: 16,
          color: AppColors.textSecondary,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.slate800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: onMenuPressed ?? () => Scaffold.of(context).openDrawer(),
        icon: const Icon(
          Icons.menu,
          size: 20,
          color: Colors.white,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

/// زر أيقونة للـ AppBar
class AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool showBadge;
  final String? badgeText;

  const AppBarIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.iconColor,
    this.backgroundColor,
    this.showBadge = false,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Stack(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: onPressed,
              icon: Icon(
                icon,
                size: 22,
                color: iconColor ?? AppColors.textSecondary,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
          if (showBadge)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// زر نص للـ AppBar (مثل "حفظ")
class AppBarTextButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;

  const AppBarTextButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppColors.blue600;

    return TextButton(
      onPressed: isLoading ? null : onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: buttonColor,
              ),
            )
          else if (icon != null)
            Icon(icon, size: 20, color: buttonColor),
          if (icon != null || isLoading) const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: buttonColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
