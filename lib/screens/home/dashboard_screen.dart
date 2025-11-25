import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:reading_tracker/utils/app_theme.dart';
import 'package:reading_tracker/services/auth_service.dart';
import 'package:reading_tracker/utils/routes.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Dummy data for demonstration
  final int _todayPages = 42;
  final int _currentStreak = 7;
  final int _totalBooksReading = 3;
  final int _completedBooks = 12;

  // Generate dummy heatmap data for the last 365 days
  Map<DateTime, int> _generateDummyHeatmapData() {
    final Map<DateTime, int> data = {};
    final now = DateTime.now();

    for (int i = 0; i < 365; i++) {
      final date = now.subtract(Duration(days: i));
      final normalizedDate = DateTime(date.year, date.month, date.day);

      // Generate random activity levels (0-4)
      // More likely to have activity on recent days
      final random = (date.day + date.month + i) % 10;
      int level;
      if (random < 2) {
        level = 0; // No activity
      } else if (random < 4) {
        level = 1; // Light
      } else if (random < 6) {
        level = 2; // Moderate
      } else if (random < 8) {
        level = 3; // Good
      } else {
        level = 4; // Excellent
      }

      data[normalizedDate] = level;
    }

    return data;
  }

  Future<void> _handleSignOut() async {
    final result = await AuthService.instance.signOut();
    if (!result.success && mounted) {
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
    final user = AuthService.instance.currentUser;
    final displayName = AuthService.instance.displayName ??
        user?.email?.split('@').first ?? 'Reader';

    return Scaffold(
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
            onPressed: _handleSignOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Refresh data
          await Future.delayed(const Duration(seconds: 1));
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
              _buildQuickStatsSection(),

              // Reading Heatmap Calendar
              _buildHeatmapSection(),

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

  Widget _buildQuickStatsSection() {
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
                  value: _todayPages.toString(),
                  color: AppColors.tertiary,
                  gradient: AppGradients.tertiaryGradient,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Day Streak',
                  value: '$_currentStreak days',
                  color: AppColors.accent,
                  gradient: AppGradients.accentGradient,
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
                  value: '$_totalBooksReading books',
                  color: AppColors.primary,
                  gradient: AppGradients.primaryGradient,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.emoji_events_rounded,
                  label: 'Completed',
                  value: '$_completedBooks books',
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

  Widget _buildHeatmapSection() {
    final heatmapData = _generateDummyHeatmapData();

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
          Card(
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
