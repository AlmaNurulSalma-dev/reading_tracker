import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:reading_tracker/models/daily_reading_stats.dart';
import 'package:reading_tracker/services/reading_log_service.dart';
import 'package:reading_tracker/utils/app_theme.dart';

/// Custom color intensity levels for the reading heatmap.
/// Based on pages read per day.
class HeatmapColors {
  HeatmapColors._();

  /// 0 pages - No activity (transparent/light gray)
  static const Color level0 = Color(0xFFEEEEEE);

  /// 1-10 pages - Light activity (Pastel Pink)
  static const Color level1 = Color(0xFFF7CFD8);

  /// 11-25 pages - Moderate activity (Pastel Yellow/Cream)
  static const Color level2 = Color(0xFFF4F8D3);

  /// 26-50 pages - Good activity (Pastel Teal)
  static const Color level3 = Color(0xFFA6D6D6);

  /// 51+ pages - Excellent activity (Pastel Purple)
  static const Color level4 = Color(0xFF8E7DBE);

  /// Get color for activity level (0-4).
  static Color getColor(int level) {
    switch (level) {
      case 0:
        return level0;
      case 1:
        return level1;
      case 2:
        return level2;
      case 3:
        return level3;
      case 4:
        return level4;
      default:
        return level0;
    }
  }

  /// Calculate activity level from pages read.
  /// - 0 pages = level 0 (transparent)
  /// - 1-10 pages = level 1 (pastel pink)
  /// - 11-25 pages = level 2 (pastel yellow)
  /// - 26-50 pages = level 3 (pastel teal)
  /// - 51+ pages = level 4 (pastel purple)
  static int calculateLevel(int pagesRead) {
    if (pagesRead == 0) return 0;
    if (pagesRead <= 10) return 1;
    if (pagesRead <= 25) return 2;
    if (pagesRead <= 50) return 3;
    return 4;
  }

  /// Get color directly from pages read.
  static Color getColorFromPages(int pagesRead) {
    return getColor(calculateLevel(pagesRead));
  }

  /// Color set map for flutter_heatmap_calendar.
  static const Map<int, Color> colorsets = {
    1: level1,
    2: level2,
    3: level3,
    4: level4,
  };

  /// Legend items for display.
  static const List<HeatmapLegendItem> legendItems = [
    HeatmapLegendItem(label: '0', color: level0, description: 'No reading'),
    HeatmapLegendItem(label: '1-10', color: level1, description: '1-10 pages'),
    HeatmapLegendItem(label: '11-25', color: level2, description: '11-25 pages'),
    HeatmapLegendItem(label: '26-50', color: level3, description: '26-50 pages'),
    HeatmapLegendItem(label: '51+', color: level4, description: '51+ pages'),
  ];
}

/// Legend item data class.
class HeatmapLegendItem {
  final String label;
  final Color color;
  final String description;

  const HeatmapLegendItem({
    required this.label,
    required this.color,
    required this.description,
  });
}

/// A custom wrapper around flutter_heatmap_calendar for reading activity visualization.
class ReadingHeatmapWidget extends StatefulWidget {
  /// Number of days to display (default: 365 for yearly view).
  final int days;

  /// Callback when a date is tapped.
  final void Function(DateTime date, int pagesRead)? onDateTap;

  /// Whether to show the legend.
  final bool showLegend;

  /// Whether to show month labels.
  final bool showMonthLabels;

  /// Custom height for the heatmap.
  final double? height;

  /// Whether to load data automatically on init.
  final bool autoLoad;

  /// Optional pre-loaded stats data.
  final List<DailyReadingStats>? initialData;

  const ReadingHeatmapWidget({
    super.key,
    this.days = 365,
    this.onDateTap,
    this.showLegend = true,
    this.showMonthLabels = true,
    this.height,
    this.autoLoad = true,
    this.initialData,
  });

  @override
  State<ReadingHeatmapWidget> createState() => ReadingHeatmapWidgetState();
}

class ReadingHeatmapWidgetState extends State<ReadingHeatmapWidget> {
  Map<DateTime, int> _heatmapData = {};
  Map<DateTime, int> _pagesData = {}; // Store actual pages for tap callback
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _processStats(widget.initialData!);
    } else if (widget.autoLoad) {
      _loadData();
    }
  }

  /// Public method to refresh the heatmap data.
  Future<void> refresh() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dateRange = DateRange.lastDays(widget.days);
      final stats = await ReadingLogService.fetchDailyStatsRange(dateRange);
      if (mounted) {
        _processStats(stats);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load reading data';
        });
      }
    }
  }

  void _processStats(List<DailyReadingStats> stats) {
    final heatmapData = <DateTime, int>{};
    final pagesData = <DateTime, int>{};

    // Create a map for quick lookup
    final statsMap = <String, DailyReadingStats>{};
    for (final stat in stats) {
      final dateKey = _normalizeDate(stat.date);
      statsMap[dateKey.toIso8601String()] = stat;
    }

    // Generate data for each day in the range
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: widget.days - 1));

    for (var i = 0; i < widget.days; i++) {
      final date = startDate.add(Duration(days: i));
      final normalizedDate = _normalizeDate(date);
      final stat = statsMap[normalizedDate.toIso8601String()];

      final pagesRead = stat?.totalPagesRead ?? 0;
      final level = HeatmapColors.calculateLevel(pagesRead);

      heatmapData[normalizedDate] = level;
      pagesData[normalizedDate] = pagesRead;
    }

    setState(() {
      _heatmapData = heatmapData;
      _pagesData = pagesData;
      _isLoading = false;
    });
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Heatmap
        SizedBox(
          height: widget.height ?? 160,
          child: _buildHeatmapContent(),
        ),
        // Legend
        if (widget.showLegend) ...[
          const SizedBox(height: AppSpacing.md),
          _buildLegend(),
        ],
      ],
    );
  }

  Widget _buildHeatmapContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.accent,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _errorMessage!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return HeatMapCalendar(
      datasets: _heatmapData,
      colorMode: ColorMode.color,
      defaultColor: HeatmapColors.level0,
      textColor: AppColors.textSecondary,
      colorsets: HeatmapColors.colorsets,
      onClick: (date) {
        final normalizedDate = _normalizeDate(date);
        final pagesRead = _pagesData[normalizedDate] ?? 0;

        if (widget.onDateTap != null) {
          widget.onDateTap!(normalizedDate, pagesRead);
        } else {
          _showDateDetails(context, normalizedDate, pagesRead);
        }
      },
    );
  }

  void _showDateDetails(BuildContext context, DateTime date, int pagesRead) {
    final dayName = _getDayName(date);
    final dateStr = '${date.day}/${date.month}/${date.year}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: HeatmapColors.getColorFromPages(pagesRead),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                pagesRead > 0
                    ? '$dayName $dateStr: $pagesRead pages read'
                    : '$dayName $dateStr: No reading activity',
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
      ),
    );
  }

  String _getDayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Less',
          style: AppTextStyles.caption,
        ),
        const SizedBox(width: AppSpacing.sm),
        ...HeatmapColors.legendItems.map((item) => _buildLegendBox(item.color)),
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
}

/// A card wrapper for the heatmap widget with title and actions.
class ReadingHeatmapCard extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;
  final int days;
  final void Function(DateTime date, int pagesRead)? onDateTap;
  final GlobalKey<ReadingHeatmapWidgetState>? heatmapKey;

  const ReadingHeatmapCard({
    super.key,
    this.title = 'Reading Activity',
    this.onViewAll,
    this.days = 365,
    this.onDateTap,
    this.heatmapKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Card with heatmap
        Card(
          child: Padding(
            padding: AppSpacing.paddingMd,
            child: ReadingHeatmapWidget(
              key: heatmapKey,
              days: days,
              onDateTap: onDateTap,
            ),
          ),
        ),
      ],
    );
  }
}

/// Detailed legend widget showing all activity levels with descriptions.
class HeatmapDetailedLegend extends StatelessWidget {
  final Axis direction;

  const HeatmapDetailedLegend({
    super.key,
    this.direction = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    final items = HeatmapColors.legendItems;

    if (direction == Axis.horizontal) {
      return Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: items.map(_buildLegendItem).toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: _buildLegendItem(item),
        );
      }).toList(),
    );
  }

  Widget _buildLegendItem(HeatmapLegendItem item) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: item.color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: AppColors.border.withOpacity(0.3),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          item.description,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}

/// Mini heatmap widget for compact displays (e.g., profile summary).
class MiniHeatmapWidget extends StatefulWidget {
  final int days;
  final double cellSize;
  final double cellSpacing;

  const MiniHeatmapWidget({
    super.key,
    this.days = 30,
    this.cellSize = 10,
    this.cellSpacing = 2,
  });

  @override
  State<MiniHeatmapWidget> createState() => _MiniHeatmapWidgetState();
}

class _MiniHeatmapWidgetState extends State<MiniHeatmapWidget> {
  List<int> _activityLevels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final dateRange = DateRange.lastDays(widget.days);
      final stats = await ReadingLogService.fetchDailyStatsRange(dateRange);

      // Create a map for quick lookup
      final statsMap = <String, DailyReadingStats>{};
      for (final stat in stats) {
        final dateKey = DateTime(stat.date.year, stat.date.month, stat.date.day);
        statsMap[dateKey.toIso8601String()] = stat;
      }

      // Generate activity levels for each day
      final levels = <int>[];
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: widget.days - 1));

      for (var i = 0; i < widget.days; i++) {
        final date = startDate.add(Duration(days: i));
        final normalizedDate = DateTime(date.year, date.month, date.day);
        final stat = statsMap[normalizedDate.toIso8601String()];
        final pagesRead = stat?.totalPagesRead ?? 0;
        levels.add(HeatmapColors.calculateLevel(pagesRead));
      }

      if (mounted) {
        setState(() {
          _activityLevels = levels;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _activityLevels = List.filled(widget.days, 0);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: widget.cellSize,
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Wrap(
      spacing: widget.cellSpacing,
      runSpacing: widget.cellSpacing,
      children: _activityLevels.map((level) {
        return Container(
          width: widget.cellSize,
          height: widget.cellSize,
          decoration: BoxDecoration(
            color: HeatmapColors.getColor(level),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }).toList(),
    );
  }
}

/// Statistics summary widget to accompany the heatmap.
class HeatmapStatsWidget extends StatefulWidget {
  final int days;

  const HeatmapStatsWidget({
    super.key,
    this.days = 30,
  });

  @override
  State<HeatmapStatsWidget> createState() => _HeatmapStatsWidgetState();
}

class _HeatmapStatsWidgetState extends State<HeatmapStatsWidget> {
  int _totalPages = 0;
  int _activeDays = 0;
  int _currentStreak = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final dateRange = DateRange.lastDays(widget.days);
      final stats = await ReadingLogService.fetchDailyStatsRange(dateRange);
      final streak = await ReadingLogService.calculateCurrentStreak();

      if (mounted) {
        setState(() {
          _totalPages = stats.fold(0, (sum, s) => sum + s.totalPagesRead);
          _activeDays = stats.where((s) => s.totalPagesRead > 0).length;
          _currentStreak = streak;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          icon: Icons.menu_book,
          value: _totalPages.toString(),
          label: 'Pages',
          color: AppColors.tertiary,
        ),
        _buildStatItem(
          icon: Icons.calendar_today,
          value: _activeDays.toString(),
          label: 'Active Days',
          color: AppColors.accent,
        ),
        _buildStatItem(
          icon: Icons.local_fire_department,
          value: _currentStreak.toString(),
          label: 'Day Streak',
          color: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}
