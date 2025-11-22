import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reading_tracker/utils/app_theme.dart';

/// A reusable custom app bar with pastel theme styling.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final bool centerTitle;
  final double elevation;
  final Widget? flexibleSpace;
  final PreferredSizeWidget? bottom;
  final CustomAppBarStyle style;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.onBackPressed,
    this.backgroundColor,
    this.centerTitle = false,
    this.elevation = 0,
    this.flexibleSpace,
    this.bottom,
    this.style = CustomAppBarStyle.primary,
  });

  /// Creates a simple app bar with just a title.
  factory CustomAppBar.simple({
    required String title,
    bool centerTitle = true,
  }) {
    return CustomAppBar(
      title: title,
      centerTitle: centerTitle,
    );
  }

  /// Creates an app bar with a back button.
  factory CustomAppBar.withBack({
    required String title,
    required BuildContext context,
    VoidCallback? onBackPressed,
    List<Widget>? actions,
  }) {
    return CustomAppBar(
      title: title,
      showBackButton: true,
      onBackPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      actions: actions,
    );
  }

  /// Creates an app bar for detail screens with gradient background.
  factory CustomAppBar.detail({
    required String title,
    required BuildContext context,
    List<Widget>? actions,
    VoidCallback? onBackPressed,
  }) {
    return CustomAppBar(
      title: title,
      showBackButton: true,
      onBackPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      actions: actions,
      style: CustomAppBarStyle.gradient,
    );
  }

  /// Creates a transparent app bar for screens with custom backgrounds.
  factory CustomAppBar.transparent({
    required String title,
    bool showBackButton = false,
    VoidCallback? onBackPressed,
    List<Widget>? actions,
  }) {
    return CustomAppBar(
      title: title,
      showBackButton: showBackButton,
      onBackPressed: onBackPressed,
      actions: actions,
      style: CustomAppBarStyle.transparent,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = _getBackgroundColor();
    final effectiveForegroundColor = _getForegroundColor();

    return AppBar(
      title: Text(
        title,
        style: AppTextStyles.titleLarge.copyWith(
          color: effectiveForegroundColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: centerTitle,
      backgroundColor: effectiveBackgroundColor,
      foregroundColor: effectiveForegroundColor,
      elevation: elevation,
      scrolledUnderElevation: style == CustomAppBarStyle.transparent ? 0 : 2,
      systemOverlayStyle: _getSystemOverlayStyle(),
      leading: _buildLeading(context, effectiveForegroundColor),
      actions: actions != null
          ? actions!
              .map((action) => _wrapAction(action, effectiveForegroundColor))
              .toList()
          : null,
      flexibleSpace: flexibleSpace ?? _buildFlexibleSpace(),
      bottom: bottom,
    );
  }

  Color _getBackgroundColor() {
    if (backgroundColor != null) return backgroundColor!;

    switch (style) {
      case CustomAppBarStyle.primary:
        return AppColors.primary;
      case CustomAppBarStyle.secondary:
        return AppColors.secondary;
      case CustomAppBarStyle.tertiary:
        return AppColors.tertiary;
      case CustomAppBarStyle.accent:
        return AppColors.accent;
      case CustomAppBarStyle.surface:
        return AppColors.surface;
      case CustomAppBarStyle.transparent:
        return Colors.transparent;
      case CustomAppBarStyle.gradient:
        return Colors.transparent;
    }
  }

  Color _getForegroundColor() {
    switch (style) {
      case CustomAppBarStyle.primary:
      case CustomAppBarStyle.secondary:
      case CustomAppBarStyle.tertiary:
      case CustomAppBarStyle.surface:
        return AppColors.textPrimary;
      case CustomAppBarStyle.accent:
        return AppColors.textOnAccent;
      case CustomAppBarStyle.transparent:
        return AppColors.textPrimary;
      case CustomAppBarStyle.gradient:
        return AppColors.textPrimary;
    }
  }

  SystemUiOverlayStyle _getSystemOverlayStyle() {
    switch (style) {
      case CustomAppBarStyle.accent:
        return SystemUiOverlayStyle.light;
      default:
        return SystemUiOverlayStyle.dark;
    }
  }

  Widget? _buildLeading(BuildContext context, Color foregroundColor) {
    if (leading != null) return leading;

    if (showBackButton) {
      return IconButton(
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: foregroundColor,
        ),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
        tooltip: 'Back',
      );
    }

    return null;
  }

  Widget _wrapAction(Widget action, Color foregroundColor) {
    if (action is IconButton) {
      return IconButton(
        icon: action.icon,
        onPressed: action.onPressed,
        tooltip: action.tooltip,
        color: foregroundColor,
      );
    }
    return action;
  }

  Widget? _buildFlexibleSpace() {
    if (style != CustomAppBarStyle.gradient) return null;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
            AppColors.secondaryLight,
          ],
        ),
      ),
    );
  }
}

/// Style variants for CustomAppBar.
enum CustomAppBarStyle {
  /// Pastel pink primary color.
  primary,

  /// Pastel yellow/cream secondary color.
  secondary,

  /// Pastel teal tertiary color.
  tertiary,

  /// Pastel purple accent color.
  accent,

  /// White surface color.
  surface,

  /// Transparent background.
  transparent,

  /// Gradient background.
  gradient,
}

/// A sliver app bar variant with pastel theme styling.
class CustomSliverAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final double expandedHeight;
  final Widget? flexibleContent;
  final bool pinned;
  final bool floating;
  final CustomAppBarStyle style;

  const CustomSliverAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
    this.expandedHeight = 200,
    this.flexibleContent,
    this.pinned = true,
    this.floating = false,
    this.style = CustomAppBarStyle.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: pinned,
      floating: floating,
      backgroundColor: _getBackgroundColor(),
      foregroundColor: _getForegroundColor(),
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: _getForegroundColor(),
              ),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(
            color: _getForegroundColor(),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        background: _buildBackground(),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (style) {
      case CustomAppBarStyle.primary:
        return AppColors.primary;
      case CustomAppBarStyle.secondary:
        return AppColors.secondary;
      case CustomAppBarStyle.tertiary:
        return AppColors.tertiary;
      case CustomAppBarStyle.accent:
        return AppColors.accent;
      case CustomAppBarStyle.surface:
        return AppColors.surface;
      case CustomAppBarStyle.transparent:
      case CustomAppBarStyle.gradient:
        return AppColors.primary;
    }
  }

  Color _getForegroundColor() {
    switch (style) {
      case CustomAppBarStyle.accent:
        return AppColors.textOnAccent;
      default:
        return AppColors.textPrimary;
    }
  }

  Widget _buildBackground() {
    if (flexibleContent != null) {
      return flexibleContent!;
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
            AppColors.secondaryLight,
          ],
        ),
      ),
    );
  }
}

/// Common app bar action buttons with pastel theme styling.
class AppBarActions {
  AppBarActions._();

  /// Notifications button.
  static Widget notifications({
    VoidCallback? onPressed,
    int? badgeCount,
  }) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: onPressed,
          tooltip: 'Notifications',
        ),
        if (badgeCount != null && badgeCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                badgeCount > 99 ? '99+' : badgeCount.toString(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  /// Settings button.
  static Widget settings({VoidCallback? onPressed}) {
    return IconButton(
      icon: const Icon(Icons.settings_outlined),
      onPressed: onPressed,
      tooltip: 'Settings',
    );
  }

  /// Search button.
  static Widget search({VoidCallback? onPressed}) {
    return IconButton(
      icon: const Icon(Icons.search),
      onPressed: onPressed,
      tooltip: 'Search',
    );
  }

  /// More options button (three dots).
  static Widget more({VoidCallback? onPressed}) {
    return IconButton(
      icon: const Icon(Icons.more_vert),
      onPressed: onPressed,
      tooltip: 'More options',
    );
  }

  /// Sign out button.
  static Widget signOut({VoidCallback? onPressed}) {
    return IconButton(
      icon: const Icon(Icons.logout),
      onPressed: onPressed,
      tooltip: 'Sign Out',
    );
  }

  /// Share button.
  static Widget share({VoidCallback? onPressed}) {
    return IconButton(
      icon: const Icon(Icons.share_outlined),
      onPressed: onPressed,
      tooltip: 'Share',
    );
  }

  /// Edit button.
  static Widget edit({VoidCallback? onPressed}) {
    return IconButton(
      icon: const Icon(Icons.edit_outlined),
      onPressed: onPressed,
      tooltip: 'Edit',
    );
  }

  /// Delete button.
  static Widget delete({VoidCallback? onPressed}) {
    return IconButton(
      icon: const Icon(Icons.delete_outline),
      onPressed: onPressed,
      tooltip: 'Delete',
      color: AppColors.error,
    );
  }

  /// Filter button.
  static Widget filter({VoidCallback? onPressed, bool isActive = false}) {
    return IconButton(
      icon: Icon(
        isActive ? Icons.filter_list : Icons.filter_list_outlined,
        color: isActive ? AppColors.accent : null,
      ),
      onPressed: onPressed,
      tooltip: 'Filter',
    );
  }
}
