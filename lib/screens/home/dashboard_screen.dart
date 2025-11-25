import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:reading_tracker/utils/app_theme.dart';
import 'package:reading_tracker/utils/routes.dart';
import 'package:reading_tracker/utils/streak_calculator.dart';
import 'package:reading_tracker/providers/providers.dart';
import 'package:reading_tracker/widgets/widgets.dart';
import 'package:reading_tracker/services/auth_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _showCelebration = false;
  int? _celebrationStreak;

  @override
  void initState() {
    super.initState();
    // Listen for streak changes after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStreakIncrease();
    });
  }

  void _checkStreakIncrease() {
    // Watch for streak celebration trigger
    ref.listen<int?>(streakCelebrationTriggerProvider, (previous, next) {
      if (next != null && mounted) {
        setState(() {
          _showCelebration = true;
          _celebrationStreak = next;
        });
      }
    });
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final result = await AuthService.instance.signOut();
    if (!result.success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Failed to sign out'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers for reactive updates
    final displayName = ref.watch(userDisplayNameProvider) ?? 'Reader';
    final todayPages = ref.watch(todayPagesReadProvider);
    final streakStatsAsync = ref.watch(streakStatsProvider);
    final readingBooksCount = ref.watch(readingBooksCountProvider);
    final completedBooksCount = ref.watch(completedBooksCountProvider);
    final heatmapDataAsync = ref.watch(heatmapDataProvider(365));

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Reading Tracker'),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // TODO: Implement notifications
                },
                tooltip: 'Notifications',
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _handleSignOut(context),
                tooltip: 'Sign Out',
              ),
            ],
          ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh all providers
          ref.invalidate(todayPagesReadProvider);
          ref.invalidate(streakStatsProvider);
          ref.invalidate(heatmapDataProvider(365));
          ref.invalidate(lastDaysStatsProvider(365));
          ref.read(booksProvider.notifier).refresh();
          ref.read(readingLogsProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Spline 3D Bookshelf Header Placeholder
              _buildSplineHeaderPlaceholder(),

              // Welcome Section
              _buildWelcomeSection(displayName),

              // Quick Stats Cards
              _buildQuickStatsSection(
                todayPages: todayPages,
                streakStatsAsync: streakStatsAsync,
                totalBooksReading: readingBooksCount,
                completedBooks: completedBooksCount,
              ),

              // Reading Heatmap Calendar
              _buildHeatmapSection(heatmapDataAsync),

              // Recent Activity (placeholder)
              _buildRecentActivitySection(),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.goToLogReading(),
            icon: const Icon(Icons.add),
            label: const Text('Log Reading'),
          ),
        ),

        // Celebration animation overlay
        if (_showCelebration && _celebrationStreak != null)
          StreakCelebrationAnimation(
            newStreak: _celebrationStreak!,
            onComplete: () {
              setState(() {
                _showCelebration = false;
                _celebrationStreak = null;
              });
            },
          ),
      ],
    );
  }

  /// Placeholder for Spline 3D bookshelf header.
  Widget _buildSplineHeaderPlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
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
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _BookshelfPatternPainter(),
            ),
          ),
          // Placeholder content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: AppRadius.borderRadiusMd,
                    boxShadow: AppShadows.medium,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.view_in_ar,
                        size: 48,
                        color: AppColors.accent,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '3D Bookshelf',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                      Text(
                        'Spline Integration',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Decorative books
          Positioned(
            left: 20,
            bottom: 20,
            child: _buildDecorativeBook(AppColors.accent, 40, 60),
          ),
          Positioned(
            left: 70,
            bottom: 20,
            child: _buildDecorativeBook(AppColors.tertiary, 35, 55),
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: _buildDecorativeBook(AppColors.primary, 38, 58),
          ),
          Positioned(
            right: 65,
            bottom: 20,
            child: _buildDecorativeBook(AppColors.secondary, 42, 62),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeBook(Color color, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: width * 0.6,
            height: 3,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 4),
          Container(
            width: width * 0.4,
            height: 2,
            color: Colors.white.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(String displayName) {
    return Padding(
      padding: AppSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            displayName,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsSection({
    required int todayPages,
    required AsyncValue<StreakStats> streakStatsAsync,
    required int totalBooksReading,
    required int completedBooks,
  }) {
    return Padding(
      padding: AppSpacing.horizontalMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Stats',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.menu_book_rounded,
                  label: "Today's Pages",
                  value: todayPages.toString(),
                  color: AppColors.tertiary,
                  gradient: AppGradients.tertiaryGradient,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: streakStatsAsync.when(
                  data: (streakStats) => _buildStreakCard(streakStats),
                  loading: () => _buildStatCard(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Day Streak',
                    value: '...',
                    color: AppColors.accent,
                    gradient: AppGradients.accentGradient,
                  ),
                  error: (_, __) => _buildStatCard(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Day Streak',
                    value: '0',
                    color: AppColors.accent,
                    gradient: AppGradients.accentGradient,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.auto_stories_rounded,
                  label: 'Currently Reading',
                  value: '$totalBooksReading ${totalBooksReading == 1 ? 'book' : 'books'}',
                  color: AppColors.primary,
                  gradient: AppGradients.primaryGradient,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.emoji_events_rounded,
                  label: 'Completed',
                  value: '$completedBooks ${completedBooks == 1 ? 'book' : 'books'}',
                  color: AppColors.secondary,
                  gradient: AppGradients.secondaryGradient,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(StreakStats streakStats) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        gradient: AppGradients.accentGradient,
        borderRadius: AppRadius.borderRadiusMd,
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '🔥',
                style: TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 8),
              if (streakStats.level.isNotEmpty)
                Expanded(
                  child: Text(
                    streakStats.level,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary.withOpacity(0.8),
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${streakStats.currentStreak}',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            '${streakStats.currentStreak == 1 ? 'Day' : 'Days'} Streak',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (streakStats.hasMilestone) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${streakStats.daysToNextMilestone} to ${streakStats.nextMilestone}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required LinearGradient gradient,
  }) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppRadius.borderRadiusMd,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.textPrimary.withOpacity(0.7),
            size: 28,
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
      ),
    );
  }

  Widget _buildHeatmapSection(AsyncValue<Map<DateTime, int>> heatmapDataAsync) {
    return Padding(
      padding: AppSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reading Activity',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to detailed stats
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          heatmapDataAsync.when(
            data: (heatmapData) => Card(
              child: Padding(
                padding: AppSpacing.paddingMd,
                child: Column(
                  children: [
                    // Heatmap Calendar
                    SizedBox(
                      height: 160,
                      child: HeatMapCalendar(
                        datasets: heatmapData,
                        colorMode: ColorMode.color,
                        defaultColor: AppColors.heatmapLevel0,
                        textColor: AppColors.textSecondary,
                        colorsets: const {
                          1: AppColors.heatmapLevel1,
                          2: AppColors.heatmapLevel2,
                          3: AppColors.heatmapLevel3,
                          4: AppColors.heatmapLevel4,
                        },
                        onClick: (date) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Activity on ${date.day}/${date.month}/${date.year}',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Legend
                    _buildHeatmapLegend(),
                  ],
                ),
              ),
            ),
            loading: () => Card(
              child: Padding(
                padding: AppSpacing.paddingMd,
                child: const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
            error: (error, _) => Card(
              child: Padding(
                padding: AppSpacing.paddingMd,
                child: SizedBox(
                  height: 160,
                  child: ErrorDisplay(
                    error: 'Failed to load heatmap data',
                    onRetry: null,
                    fullScreen: false,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Less',
          style: AppTextStyles.caption,
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildLegendBox(AppColors.heatmapLevel0),
        _buildLegendBox(AppColors.heatmapLevel1),
        _buildLegendBox(AppColors.heatmapLevel2),
        _buildLegendBox(AppColors.heatmapLevel3),
        _buildLegendBox(AppColors.heatmapLevel4),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'More',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  Widget _buildLegendBox(Color color) {
    return Container(
      width: 16,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: AppColors.border.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Padding(
      padding: AppSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to all activity
                },
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Dummy recent activity items
          _buildActivityItem(
            title: 'The Great Gatsby',
            subtitle: 'Read 25 pages',
            time: '2 hours ago',
            icon: Icons.menu_book,
            color: AppColors.tertiary,
          ),
          _buildActivityItem(
            title: 'Atomic Habits',
            subtitle: 'Read 15 pages',
            time: 'Yesterday',
            icon: Icons.menu_book,
            color: AppColors.accent,
          ),
          _buildActivityItem(
            title: '1984',
            subtitle: 'Completed!',
            time: '2 days ago',
            icon: Icons.emoji_events,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: AppRadius.borderRadiusSm,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: AppTextStyles.titleSmall,
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodySmall,
        ),
        trailing: Text(
          time,
          style: AppTextStyles.caption,
        ),
      ),
    );
  }
}

/// Custom painter for bookshelf pattern background.
class _BookshelfPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw horizontal shelf lines
    for (double y = 50; y < size.height; y += 50) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Draw some vertical book dividers
    final bookPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    for (double x = 30; x < size.width; x += 60) {
      final bookHeight = 30.0 + (x % 20);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - bookHeight - 20, 15, bookHeight),
          const Radius.circular(2),
        ),
        bookPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
