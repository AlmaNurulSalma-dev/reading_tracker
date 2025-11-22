import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:reading_tracker/models/book.dart';
import 'package:reading_tracker/utils/app_theme.dart';

/// A reusable card widget for displaying book information with progress indicator.
class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showProgress;
  final bool compact;

  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.onLongPress,
    this.showProgress = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return compact ? _buildCompactCard() : _buildFullCard();
  }

  Widget _buildFullCard() {
    return Card(
      elevation: 2,
      shadowColor: AppColors.accent.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusMd,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: AppRadius.borderRadiusMd,
        child: Padding(
          padding: AppSpacing.paddingMd,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Cover or Placeholder
              _buildCoverImage(),
              const SizedBox(width: AppSpacing.md),
              // Book Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (book.author != null && book.author!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        book.author!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    // Progress text
                    Text(
                      book.progressText,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Linear Progress Bar
                    _buildLinearProgress(),
                  ],
                ),
              ),
              // Circular Progress Indicator
              if (showProgress) ...[
                const SizedBox(width: AppSpacing.sm),
                _buildCircularProgress(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard() {
    return Card(
      elevation: 1,
      shadowColor: AppColors.accent.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusSm,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: AppRadius.borderRadiusSm,
        child: Padding(
          padding: AppSpacing.paddingSm,
          child: Row(
            children: [
              // Small Circular Progress
              if (showProgress)
                CircularPercentIndicator(
                  radius: 20,
                  lineWidth: 3,
                  percent: book.progressDecimal,
                  center: Text(
                    '${book.progressPercentage.toInt()}',
                    style: AppTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 8,
                    ),
                  ),
                  progressColor: _getProgressColor(),
                  backgroundColor: AppColors.progressBackground,
                  circularStrokeCap: CircularStrokeCap.round,
                ),
              if (showProgress) const SizedBox(width: AppSpacing.sm),
              // Book info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      book.title,
                      style: AppTextStyles.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (book.author != null && book.author!.isNotEmpty)
                      Text(
                        book.author!,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Arrow icon
              Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage() {
    return Container(
      width: 70,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: AppRadius.borderRadiusSm,
        color: AppColors.primaryLight,
        boxShadow: AppShadows.small,
      ),
      clipBehavior: Clip.antiAlias,
      child: book.coverImageUrl != null && book.coverImageUrl!.isNotEmpty
          ? Image.network(
              book.coverImageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildCoverPlaceholder(),
            )
          : _buildCoverPlaceholder(),
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight,
            AppColors.primary,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_rounded,
              color: AppColors.accent.withOpacity(0.6),
              size: 28,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                book.title,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 8,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinearProgress() {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        borderRadius: AppRadius.borderRadiusRound,
        color: AppColors.progressBackground,
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: book.progressDecimal,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderRadiusRound,
            gradient: book.isCompleted
                ? AppGradients.progressCompleteGradient
                : AppGradients.progressGradient,
          ),
        ),
      ),
    );
  }

  Widget _buildCircularProgress() {
    return CircularPercentIndicator(
      radius: 32,
      lineWidth: 5,
      percent: book.progressDecimal,
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${book.progressPercentage.toInt()}%',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: _getProgressColor(),
            ),
          ),
          if (book.isCompleted)
            Icon(
              Icons.check,
              size: 12,
              color: AppColors.success,
            ),
        ],
      ),
      progressColor: _getProgressColor(),
      backgroundColor: AppColors.progressBackground,
      circularStrokeCap: CircularStrokeCap.round,
      animation: true,
      animationDuration: 800,
    );
  }

  Color _getProgressColor() {
    if (book.isCompleted) {
      return AppColors.success;
    }
    if (book.progressPercentage >= 75) {
      return AppColors.tertiaryDark;
    }
    if (book.progressPercentage >= 50) {
      return AppColors.tertiary;
    }
    if (book.progressPercentage >= 25) {
      return AppColors.accent;
    }
    return AppColors.accentLight;
  }
}

/// A horizontal scrollable list of book cards.
class BookCardList extends StatelessWidget {
  final List<Book> books;
  final void Function(Book book)? onBookTap;
  final bool compact;
  final double height;

  const BookCardList({
    super.key,
    required this.books,
    this.onBookTap,
    this.compact = true,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No books yet',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.horizontalMd,
        itemCount: books.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final book = books[index];
          return SizedBox(
            width: compact ? 200 : 300,
            child: BookCard(
              book: book,
              compact: compact,
              onTap: onBookTap != null ? () => onBookTap!(book) : null,
            ),
          );
        },
      ),
    );
  }
}
