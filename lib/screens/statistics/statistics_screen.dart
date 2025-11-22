import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:reading_tracker/models/models.dart';
import 'package:reading_tracker/services/book_service.dart';
import 'package:reading_tracker/services/reading_log_service.dart';
import 'package:reading_tracker/utils/app_theme.dart';
import 'package:reading_tracker/widgets/widgets.dart';

/// Statistics screen with fl_chart visualizations for reading data.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  // Date range selection
  DateRangeOption _selectedRange = DateRangeOption.thisMonth;
  DateTimeRange? _customRange;

  // Data
  List<DailyReadingStats> _dailyStats = [];
  List<Book> _books = [];
  List<ReadingLog> _readingLogs = [];
  ReadingSummary? _summary;

  // Loading states
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dateRange = _getDateRange();

      // Load all data in parallel
      final results = await Future.wait([
        ReadingLogService.fetchDailyStatsRange(dateRange),
        BookService.fetchUserBooks(),
        ReadingLogService.fetchReadingLogs(dateRange: dateRange),
      ]);

      final stats = results[0] as List<DailyReadingStats>;
      final books = results[1] as List<Book>;
      final logs = results[2] as List<ReadingLog>;

      if (mounted) {
        setState(() {
          _dailyStats = stats;
          _books = books;
          _readingLogs = logs;
          _summary = ReadingSummary.fromStats(stats);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load statistics: $e';
        });
      }
    }
  }

  DateRange _getDateRange() {
    switch (_selectedRange) {
      case DateRangeOption.thisWeek:
        return DateRange.thisWeek();
      case DateRangeOption.thisMonth:
        return DateRange.thisMonth();
      case DateRangeOption.last30Days:
        return DateRange.lastDays(30);
      case DateRangeOption.last90Days:
        return DateRange.lastDays(90);
      case DateRangeOption.thisYear:
        return DateRange.thisYear();
      case DateRangeOption.custom:
        if (_customRange != null) {
          return DateRange(
            start: _customRange!.start,
            end: _customRange!.end,
          );
        }
        return DateRange.thisMonth();
    }
  }

  Future<void> _selectCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accent,
              onPrimary: AppColors.textOnAccent,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customRange = picked;
        _selectedRange = DateRangeOption.custom;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Statistics',
        actions: [
          AppBarActions.filter(
            onPressed: _showFilterOptions,
            isActive: _selectedRange != DateRangeOption.thisMonth,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: AppSpacing.paddingMd,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Range Selector
                          _buildDateRangeSelector(),
                          const SizedBox(height: AppSpacing.lg),

                          // Summary Stats
                          _buildSummaryStats(),
                          const SizedBox(height: AppSpacing.lg),

                          // Weekly Bar Chart
                          _buildWeeklyBarChart(),
                          const SizedBox(height: AppSpacing.lg),

                          // Monthly Line Chart
                          _buildMonthlyLineChart(),
                          const SizedBox(height: AppSpacing.lg),

                          // Book Distribution Pie Chart
                          _buildBookDistributionPieChart(),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Unable to load statistics',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _errorMessage ?? 'An unexpected error occurred',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterBottomSheet(),
    );
  }

  Widget _buildFilterBottomSheet() {
    return Container(
      padding: AppSpacing.paddingLg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Date Range',
            style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          ...DateRangeOption.values.map((option) {
            return ListTile(
              leading: Icon(
                option == _selectedRange
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: option == _selectedRange
                    ? AppColors.accent
                    : AppColors.textSecondary,
              ),
              title: Text(option.label),
              onTap: () {
                Navigator.pop(context);
                if (option == DateRangeOption.custom) {
                  _selectCustomDateRange();
                } else {
                  setState(() => _selectedRange = option);
                  _loadData();
                }
              },
            );
          }),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: DateRangeOption.values
            .where((o) => o != DateRangeOption.custom)
            .map((option) {
          final isSelected = _selectedRange == option;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ChoiceChip(
              label: Text(option.shortLabel),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedRange = option);
                  _loadData();
                }
              },
              selectedColor: AppColors.accent.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList()
          ..add(
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ActionChip(
                avatar: const Icon(Icons.date_range, size: 18),
                label: Text(
                  _selectedRange == DateRangeOption.custom
                      ? _formatCustomRange()
                      : 'Custom',
                ),
                onPressed: _selectCustomDateRange,
                backgroundColor: _selectedRange == DateRangeOption.custom
                    ? AppColors.accent.withOpacity(0.2)
                    : null,
              ),
            ),
          ),
      ),
    );
  }

  String _formatCustomRange() {
    if (_customRange == null) return 'Custom';
    final dateFormat = DateFormat('MMM d');
    return '${dateFormat.format(_customRange!.start)} - ${dateFormat.format(_customRange!.end)}';
  }

  Widget _buildSummaryStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        StatCardGrid(
          cards: [
            StatCard(
              icon: Icons.menu_book_rounded,
              label: 'Total Pages',
              value: '${_summary?.totalPagesRead ?? 0}',
              color: AppColors.tertiary,
              gradient: AppGradients.tertiaryGradient,
            ),
            StatCard(
              icon: Icons.calendar_today_rounded,
              label: 'Active Days',
              value: '${_summary?.totalDaysRead ?? 0}',
              color: AppColors.accent,
              gradient: AppGradients.accentGradient,
            ),
            StatCard(
              icon: Icons.speed_rounded,
              label: 'Avg/Day',
              value: '${_summary?.averagePagesPerDay.round() ?? 0}',
              color: AppColors.primary,
              gradient: AppGradients.primaryGradient,
            ),
            StatCard(
              icon: Icons.emoji_events_rounded,
              label: 'Best Day',
              value: '${_summary?.maxPagesInDay ?? 0}',
              color: AppColors.secondary,
              gradient: AppGradients.secondaryGradient,
            ),
          ],
          childAspectRatio: 1.3,
        ),
      ],
    );
  }

  Widget _buildWeeklyBarChart() {
    return _buildChartCard(
      title: 'Weekly Reading',
      subtitle: 'Pages read per day this week',
      child: SizedBox(
        height: 220,
        child: _dailyStats.isEmpty ? _buildEmptyChart() : _buildBarChart(),
      ),
    );
  }

  Widget _buildBarChart() {
    // Get last 7 days of data
    final now = DateTime.now();
    final weekData = <String, int>{};
    final dayLabels = <String>[];

    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      weekData[dateKey] = 0;
      dayLabels.add(DateFormat('E').format(date));
    }

    // Fill in actual data
    for (final stat in _dailyStats) {
      final dateKey = DateFormat('yyyy-MM-dd').format(stat.date);
      if (weekData.containsKey(dateKey)) {
        weekData[dateKey] = stat.totalPagesRead;
      }
    }

    final values = weekData.values.toList();
    final maxY = values.isEmpty ? 10.0 : (values.reduce((a, b) => a > b ? a : b) * 1.2).clamp(10.0, double.infinity);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.textPrimary,
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.round()} pages\n${dayLabels[group.x.toInt()]}',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= dayLabels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      dayLabels[index],
                      style: AppTextStyles.caption,
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: maxY / 4,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: AppTextStyles.caption,
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.border.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
          ),
          barGroups: List.generate(values.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: values[index].toDouble(),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.tertiary,
                      AppColors.tertiaryDark,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 28,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMonthlyLineChart() {
    return _buildChartCard(
      title: 'Monthly Trend',
      subtitle: 'Reading progress over time',
      child: SizedBox(
        height: 220,
        child: _dailyStats.isEmpty ? _buildEmptyChart() : _buildLineChart(),
      ),
    );
  }

  Widget _buildLineChart() {
    // Group by date and prepare spots
    final sortedStats = List<DailyReadingStats>.from(_dailyStats)
      ..sort((a, b) => a.date.compareTo(b.date));

    if (sortedStats.isEmpty) return _buildEmptyChart();

    final spots = <FlSpot>[];
    final dateLabels = <DateTime>[];

    for (int i = 0; i < sortedStats.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedStats[i].totalPagesRead.toDouble()));
      dateLabels.add(sortedStats[i].date);
    }

    final maxY = spots.isEmpty
        ? 10.0
        : (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2).clamp(10.0, double.infinity);

    final interval = (spots.length / 5).ceil().clamp(1, spots.length);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, right: AppSpacing.sm),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.border.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: maxY / 4,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: AppTextStyles.caption,
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: interval.toDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= dateLabels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('d/M').format(dateLabels[index]),
                      style: AppTextStyles.caption.copyWith(fontSize: 9),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (spots.length - 1).toDouble().clamp(0, double.infinity),
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              gradient: LinearGradient(
                colors: [AppColors.accent, AppColors.accentLight],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: spot.y > 0 ? 4 : 0,
                    color: AppColors.accent,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.accent.withOpacity(0.3),
                    AppColors.accent.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.textPrimary,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  final date = index < dateLabels.length
                      ? DateFormat('MMM d').format(dateLabels[index])
                      : '';
                  return LineTooltipItem(
                    '$date\n${spot.y.toInt()} pages',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookDistributionPieChart() {
    return _buildChartCard(
      title: 'Reading Distribution',
      subtitle: 'Pages read per book',
      child: SizedBox(
        height: 280,
        child: _readingLogs.isEmpty ? _buildEmptyChart() : _buildPieChart(),
      ),
    );
  }

  Widget _buildPieChart() {
    // Group reading logs by book
    final bookPages = <String, int>{};
    final bookTitles = <String, String>{};

    for (final log in _readingLogs) {
      bookPages[log.bookId] = (bookPages[log.bookId] ?? 0) + log.pagesRead;
    }

    // Get book titles
    for (final book in _books) {
      if (bookPages.containsKey(book.id)) {
        bookTitles[book.id] = book.title;
      }
    }

    if (bookPages.isEmpty) return _buildEmptyChart();

    // Sort by pages and take top 5
    final sortedEntries = bookPages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topEntries = sortedEntries.take(5).toList();
    final otherPages = sortedEntries.skip(5).fold(0, (sum, e) => sum + e.value);

    if (otherPages > 0) {
      topEntries.add(MapEntry('other', otherPages));
      bookTitles['other'] = 'Others';
    }

    final totalPages = topEntries.fold(0, (sum, e) => sum + e.value);

    // Pastel colors for pie chart
    final pieColors = [
      AppColors.tertiary,     // Pastel Teal
      AppColors.accent,       // Pastel Purple
      AppColors.primary,      // Pastel Pink
      AppColors.secondary,    // Pastel Yellow
      const Color(0xFFFFB74D), // Pastel Orange
      AppColors.tertiaryLight, // Light Teal
    ];

    return Row(
      children: [
        // Pie Chart
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: List.generate(topEntries.length, (index) {
                final entry = topEntries[index];
                final percentage = totalPages > 0
                    ? (entry.value / totalPages * 100)
                    : 0.0;

                return PieChartSectionData(
                  color: pieColors[index % pieColors.length],
                  value: entry.value.toDouble(),
                  title: '${percentage.round()}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
                  ),
                );
              }),
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  // Handle touch if needed
                },
              ),
            ),
          ),
        ),

        // Legend
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(topEntries.length, (index) {
                final entry = topEntries[index];
                final title = bookTitles[entry.key] ?? 'Unknown';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: pieColors[index % pieColors.length],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${entry.value} pages',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: AppSpacing.paddingMd,
            child: child,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyChart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No data available',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            'Start reading to see your statistics!',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

/// Date range options for statistics filtering.
enum DateRangeOption {
  thisWeek('This Week', 'Week'),
  thisMonth('This Month', 'Month'),
  last30Days('Last 30 Days', '30 Days'),
  last90Days('Last 90 Days', '90 Days'),
  thisYear('This Year', 'Year'),
  custom('Custom Range', 'Custom');

  final String label;
  final String shortLabel;

  const DateRangeOption(this.label, this.shortLabel);
}
