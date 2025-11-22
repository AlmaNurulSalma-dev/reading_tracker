import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:reading_tracker/models/models.dart';
import 'package:reading_tracker/services/book_service.dart';
import 'package:reading_tracker/services/reading_log_service.dart';
import 'package:reading_tracker/screens/reading/log_reading_screen.dart';
import 'package:reading_tracker/utils/app_theme.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({
    super.key,
    required this.book,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late Book _book;
  List<ReadingLog> _readingLogs = [];
  bool _isLoadingLogs = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _loadReadingLogs();
  }

  Future<void> _loadReadingLogs() async {
    setState(() {
      _isLoadingLogs = true;
    });

    try {
      final logs = await ReadingLogService.fetchReadingLogs(
        bookId: _book.id,
        dateRange: DateRange.lastDays(30),
      );

      if (mounted) {
        setState(() {
          _readingLogs = logs;
          _isLoadingLogs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLogs = false;
        });
      }
    }
  }

  Future<void> _refreshBook() async {
    try {
      final updatedBook = await BookService.fetchBookById(_book.id);
      if (updatedBook != null && mounted) {
        setState(() {
          _book = updatedBook;
        });
      }
      await _loadReadingLogs();
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _openPdf() async {
    if (_book.pdfUrl == null || _book.pdfUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No PDF available for this book'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final uri = Uri.parse(_book.pdfUrl!);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open PDF'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteBook() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text(
          'Are you sure you want to delete "${_book.title}"?\n\n'
          'This will also delete all reading history for this book. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await BookService.deleteBook(_book.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${_book.title}" deleted'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate deletion
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting book: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _navigateToLogReading() {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LogReadingScreen(initialBook: _book),
      ),
    ).then((result) {
      if (result == true) {
        _refreshBook();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Book Cover
          _buildSliverAppBar(),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.paddingMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Section
                  _buildProgressSection(),
                  const SizedBox(height: AppSpacing.lg),

                  // Stats Cards
                  _buildStatsCards(),
                  const SizedBox(height: AppSpacing.lg),

                  // Reading History Chart
                  _buildReadingHistorySection(),
                  const SizedBox(height: AppSpacing.lg),

                  // Action Buttons
                  _buildActionButtons(),
                  const SizedBox(height: AppSpacing.lg),

                  // Danger Zone
                  _buildDangerZone(),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: !_book.isCompleted
          ? FloatingActionButton.extended(
              onPressed: _navigateToLogReading,
              icon: const Icon(Icons.add),
              label: const Text('Log Reading'),
            )
          : null,
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _book.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: Colors.black26, blurRadius: 4),
            ],
          ),
        ),
        background: _buildHeaderBackground(),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                // TODO: Navigate to edit screen
                break;
              case 'delete':
                _deleteBook();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit Book'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Delete Book', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderBackground() {
    // Generate gradient colors based on book title
    final colorIndex = _book.title.hashCode.abs() % 4;
    final gradientColors = [
      [AppColors.primary, AppColors.primaryDark],
      [AppColors.tertiary, AppColors.tertiaryDark],
      [AppColors.accent, AppColors.accentDark],
      [AppColors.secondary, AppColors.primary],
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors[colorIndex],
        ),
      ),
      child: Stack(
        children: [
          // Pattern overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(
                painter: _BookPatternPainter(),
              ),
            ),
          ),
          // Book info
          Positioned(
            left: 16,
            bottom: 60,
            child: Row(
              children: [
                if (_book.coverImageUrl != null)
                  Container(
                    width: 60,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: AppShadows.medium,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        _book.coverImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.white24,
                          child: const Icon(Icons.book, color: Colors.white),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 60,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.menu_book, color: Colors.white, size: 32),
                  ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_book.author != null)
                      Text(
                        _book.author!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _book.isCompleted ? AppColors.success : Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _book.isCompleted ? 'Completed' : 'Reading',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Row(
          children: [
            // Large Circular Progress
            CircularPercentIndicator(
              radius: 70,
              lineWidth: 12,
              percent: _book.progressDecimal,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_book.progressPercentage.round()}%',
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                  Text(
                    'Complete',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              progressColor: _book.isCompleted ? AppColors.success : AppColors.accent,
              backgroundColor: AppColors.progressBackground,
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
              animationDuration: 1000,
            ),
            const SizedBox(width: AppSpacing.lg),

            // Progress Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgressDetailRow(
                    icon: Icons.bookmark,
                    label: 'Current Page',
                    value: '${_book.currentPage}',
                  ),
                  const SizedBox(height: 12),
                  _buildProgressDetailRow(
                    icon: Icons.menu_book,
                    label: 'Total Pages',
                    value: '${_book.totalPages}',
                  ),
                  const SizedBox(height: 12),
                  _buildProgressDetailRow(
                    icon: Icons.hourglass_empty,
                    label: 'Remaining',
                    value: '${_book.remainingPages} pages',
                    highlight: !_book.isCompleted,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: highlight ? AppColors.accent : AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: highlight ? AppColors.accent : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    final totalPagesRead = _readingLogs.fold<int>(0, (sum, log) => sum + log.pagesRead);
    final readingSessions = _readingLogs.length;
    final avgPagesPerSession = readingSessions > 0 ? (totalPagesRead / readingSessions).round() : 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.auto_stories,
            label: 'Pages Read',
            value: '$totalPagesRead',
            color: AppColors.tertiary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            icon: Icons.calendar_today,
            label: 'Sessions',
            value: '$readingSessions',
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            icon: Icons.speed,
            label: 'Avg/Session',
            value: '$avgPagesPerSession',
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: AppRadius.borderRadiusMd,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReadingHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reading History',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Last 30 days',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: AppSpacing.paddingMd,
            child: _isLoadingLogs
                ? const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    ),
                  )
                : _readingLogs.isEmpty
                    ? _buildEmptyChartState()
                    : _buildReadingChart(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyChartState() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 8),
            Text(
              'No reading activity yet',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start reading to see your progress!',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingChart() {
    // Group logs by date and sum pages
    final Map<DateTime, int> dailyPages = {};
    for (final log in _readingLogs) {
      final date = DateTime(log.date.year, log.date.month, log.date.day);
      dailyPages[date] = (dailyPages[date] ?? 0) + log.pagesRead;
    }

    // Create spots for the chart (last 14 days for better visibility)
    final now = DateTime.now();
    final spots = <FlSpot>[];
    final dates = <DateTime>[];

    for (int i = 13; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      dates.add(date);
      final pages = dailyPages[date] ?? 0;
      spots.add(FlSpot((13 - i).toDouble(), pages.toDouble()));
    }

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final adjustedMaxY = maxY > 0 ? maxY * 1.2 : 10;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: adjustedMaxY / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.border.withOpacity(0.5),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: adjustedMaxY / 4,
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
                interval: 2,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= dates.length) return const Text('');
                  final date = dates[index];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${date.day}/${date.month}',
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
          maxX: 13,
          minY: 0,
          maxY: adjustedMaxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: AppColors.accent,
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
                  final date = index < dates.length ? dates[index] : null;
                  return LineTooltipItem(
                    date != null
                        ? '${date.day}/${date.month}\n${spot.y.toInt()} pages'
                        : '${spot.y.toInt()} pages',
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

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Open PDF Button
        if (_book.pdfUrl != null && _book.pdfUrl!.isNotEmpty)
          ElevatedButton.icon(
            onPressed: _openPdf,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Open PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tertiary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),

        if (_book.pdfUrl != null && _book.pdfUrl!.isNotEmpty)
          const SizedBox(height: AppSpacing.sm),

        // Update Progress Button
        OutlinedButton.icon(
          onPressed: _navigateToLogReading,
          icon: const Icon(Icons.edit),
          label: const Text('Update Progress'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danger Zone',
          style: AppTextStyles.titleSmall.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.error.withOpacity(0.3)),
            borderRadius: AppRadius.borderRadiusMd,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delete this book',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Permanently remove this book and all reading history',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _isDeleting ? null : _deleteBook,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
                child: _isDeleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.error,
                        ),
                      )
                    : const Text('Delete'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom painter for book pattern background.
class _BookPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw book-like shapes
    for (double x = 0; x < size.width; x += 40) {
      for (double y = 0; y < size.height; y += 50) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, 20, 30),
            const Radius.circular(2),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
