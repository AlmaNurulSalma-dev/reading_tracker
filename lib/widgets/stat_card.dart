import 'package:flutter/material.dart';
import 'package:reading_tracker/utils/app_theme.dart';

/// A reusable card widget for displaying dashboard statistics/metrics.
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final LinearGradient? gradient;
  final VoidCallback? onTap;
  final StatCardSize size;
  final Widget? trailing;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    this.gradient,
    this.onTap,
    this.size = StatCardSize.medium,
    this.trailing,
  });

  /// Quick constructor for Today's Pages stat.
  factory StatCard.todayPages({
    required int pages,
    VoidCallback? onTap,
  }) {
    return StatCard(
      icon: Icons.menu_book_rounded,
      label: "Today's Pages",
      value: pages.toString(),
      color: AppColors.tertiary,
      gradient: AppGradients.tertiaryGradient,
      onTap: onTap,
    );
  }

  /// Quick constructor for Streak stat.
  factory StatCard.streak({
    required int days,
    VoidCallback? onTap,
  }) {
    return StatCard(
      icon: Icons.local_fire_department_rounded,
      label: 'Day Streak',
      value: '$days days',
      color: AppColors.accent,
      gradient: AppGradients.accentGradient,
      onTap: onTap,
    );
  }

  /// Quick constructor for Currently Reading stat.
  factory StatCard.currentlyReading({
    required int books,
    VoidCallback? onTap,
  }) {
    return StatCard(
      icon: Icons.auto_stories_rounded,
      label: 'Currently Reading',
      value: '$books ${books == 1 ? 'book' : 'books'}',
      color: AppColors.primary,
      gradient: AppGradients.primaryGradient,
      onTap: onTap,
    );
  }

  /// Quick constructor for Completed Books stat.
  factory StatCard.completed({
    required int books,
    VoidCallback? onTap,
  }) {
    return StatCard(
      icon: Icons.emoji_events_rounded,
      label: 'Completed',
      value: '$books ${books == 1 ? 'book' : 'books'}',
      color: AppColors.secondary,
      gradient: AppGradients.secondaryGradient,
      onTap: onTap,
    );
  }

  /// Quick constructor for Total Pages stat.
  factory StatCard.totalPages({
    required int pages,
    VoidCallback? onTap,
  }) {
    return StatCard(
      icon: Icons.library_books_rounded,
      label: 'Total Pages Read',
      value: _formatNumber(pages),
      color: AppColors.tertiary,
      gradient: AppGradients.tertiaryGradient,
      onTap: onTap,
    );
  }

  /// Quick constructor for Reading Time stat.
  factory StatCard.readingTime({
    required int minutes,
    VoidCallback? onTap,
  }) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    final display = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
    return StatCard(
      icon: Icons.access_time_rounded,
      label: 'Reading Time',
      value: display,
      color: AppColors.accent,
      gradient: AppGradients.accentGradient,
      onTap: onTap,
    );
  }

  static String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.tertiary;
    final effectiveGradient = gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [effectiveColor.withOpacity(0.3), effectiveColor.withOpacity(0.1)],
        );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderRadiusMd,
        child: Container(
          padding: _getPadding(),
          decoration: BoxDecoration(
            gradient: effectiveGradient,
            borderRadius: AppRadius.borderRadiusMd,
            boxShadow: [
              BoxShadow(
                color: effectiveColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _buildContent(effectiveColor),
        ),
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case StatCardSize.small:
        return AppSpacing.paddingSm;
      case StatCardSize.medium:
        return AppSpacing.paddingMd;
      case StatCardSize.large:
        return AppSpacing.paddingLg;
    }
  }

  Widget _buildContent(Color effectiveColor) {
    switch (size) {
      case StatCardSize.small:
        return _buildSmallContent(effectiveColor);
      case StatCardSize.medium:
        return _buildMediumContent(effectiveColor);
      case StatCardSize.large:
        return _buildLargeContent(effectiveColor);
    }
  }

  Widget _buildSmallContent(Color effectiveColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: AppColors.textPrimary.withOpacity(0.7),
          size: 20,
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
  }

  Widget _buildMediumContent(Color effectiveColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              icon,
              color: AppColors.textPrimary.withOpacity(0.7),
              size: 28,
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLargeContent(Color effectiveColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: AppRadius.borderRadiusSm,
              ),
              child: Icon(
                icon,
                color: AppColors.textPrimary.withOpacity(0.8),
                size: 32,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          value,
          style: AppTextStyles.displaySmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Size variants for StatCard.
enum StatCardSize {
  small,
  medium,
  large,
}

/// A grid of stat cards for dashboard display.
class StatCardGrid extends StatelessWidget {
  final List<StatCard> cards;
  final int crossAxisCount;
  final double spacing;
  final double childAspectRatio;

  const StatCardGrid({
    super.key,
    required this.cards,
    this.crossAxisCount = 2,
    this.spacing = AppSpacing.sm,
    this.childAspectRatio = 1.4,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => cards[index],
    );
  }
}

/// A horizontal row of stat cards.
class StatCardRow extends StatelessWidget {
  final List<StatCard> cards;
  final double spacing;

  const StatCardRow({
    super.key,
    required this.cards,
    this.spacing = AppSpacing.sm,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: cards
          .map((card) => Expanded(child: card))
          .toList()
          .expand((widget) => [widget, SizedBox(width: spacing)])
          .toList()
        ..removeLast(),
    );
  }
}
