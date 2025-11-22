import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:reading_tracker/models/models.dart';
import 'package:reading_tracker/services/supabase_service.dart';

/// Data class for date range queries.
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({required this.start, required this.end});

  /// Create a date range for the current week.
  factory DateRange.thisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return DateRange(
      start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  /// Create a date range for the current month.
  factory DateRange.thisMonth() {
    final now = DateTime.now();
    return DateRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    );
  }

  /// Create a date range for a specific month.
  factory DateRange.forMonth(int year, int month) {
    return DateRange(
      start: DateTime(year, month, 1),
      end: DateTime(year, month + 1, 0, 23, 59, 59),
    );
  }

  /// Create a date range for the last N days.
  factory DateRange.lastDays(int days) {
    final now = DateTime.now();
    return DateRange(
      start: DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1)),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  /// Create a date range for the current year.
  factory DateRange.thisYear() {
    final now = DateTime.now();
    return DateRange(
      start: DateTime(now.year, 1, 1),
      end: DateTime(now.year, 12, 31, 23, 59, 59),
    );
  }
}

/// Data class for heatmap visualization.
class HeatmapData {
  final DateTime date;
  final int pagesRead;
  final int activityLevel; // 0-4 scale

  const HeatmapData({
    required this.date,
    required this.pagesRead,
    required this.activityLevel,
  });

  /// Convert to map format for flutter_heatmap_calendar.
  Map<DateTime, int> toHeatmapEntry() {
    return {date: activityLevel};
  }
}

/// Service for managing reading logs and daily statistics.
class ReadingLogService {
  static const String _logsTable = 'reading_logs';
  static const String _statsTable = 'daily_reading_stats';
  static final DateFormat _isoDateFormat = DateFormat('yyyy-MM-dd');

  /// Get the Supabase client instance.
  static SupabaseClient get _client => SupabaseService.client;

  /// Get the current user's ID.
  static String get _userId {
    final user = SupabaseService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.id;
  }

  // ============ LOGGING Operations ============

  /// Log a reading session.
  /// [bookId] - The book being read.
  /// [startPage] - Starting page of the session.
  /// [endPage] - Ending page of the session.
  /// [date] - Date of the reading session (defaults to today).
  /// Returns the created reading log.
  static Future<ReadingLog> logReading({
    required String bookId,
    required int startPage,
    required int endPage,
    DateTime? date,
  }) async {
    final readingDate = date ?? DateTime.now();
    final pagesRead = endPage - startPage;

    if (pagesRead < 0) {
      throw ArgumentError('End page must be greater than or equal to start page');
    }

    final logData = {
      'book_id': bookId,
      'user_id': _userId,
      'date': _isoDateFormat.format(readingDate),
      'pages_read': pagesRead,
      'start_page': startPage,
      'end_page': endPage,
    };

    final response = await _client
        .from(_logsTable)
        .insert(logData)
        .select()
        .single();

    // Note: Daily stats are automatically updated via database trigger

    return ReadingLog.fromJson(response);
  }

  /// Log reading by specifying pages read instead of page range.
  /// Automatically calculates end page from book's current page.
  static Future<ReadingLog> logReadingSimple({
    required String bookId,
    required int pagesRead,
    required int currentBookPage,
    DateTime? date,
  }) async {
    final startPage = currentBookPage;
    final endPage = currentBookPage + pagesRead;

    return logReading(
      bookId: bookId,
      startPage: startPage,
      endPage: endPage,
      date: date,
    );
  }

  // ============ FETCH Reading Logs ============

  /// Fetch reading logs for a date range.
  static Future<List<ReadingLog>> fetchReadingLogs({
    DateRange? dateRange,
    String? bookId,
  }) async {
    var query = _client
        .from(_logsTable)
        .select()
        .eq('user_id', _userId);

    if (dateRange != null) {
      query = query
          .gte('date', _isoDateFormat.format(dateRange.start))
          .lte('date', _isoDateFormat.format(dateRange.end));
    }

    if (bookId != null) {
      query = query.eq('book_id', bookId);
    }

    final response = await query.order('date', ascending: false);

    return (response as List)
        .map((json) => ReadingLog.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch reading logs for a specific book.
  static Future<List<ReadingLog>> fetchBookReadingLogs(String bookId) async {
    return fetchReadingLogs(bookId: bookId);
  }

  /// Fetch reading logs for today.
  static Future<List<ReadingLog>> fetchTodayLogs() async {
    final today = DateTime.now();
    return fetchReadingLogs(
      dateRange: DateRange(
        start: DateTime(today.year, today.month, today.day),
        end: DateTime(today.year, today.month, today.day, 23, 59, 59),
      ),
    );
  }

  /// Fetch the most recent reading logs.
  static Future<List<ReadingLog>> fetchRecentLogs({int limit = 10}) async {
    final response = await _client
        .from(_logsTable)
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => ReadingLog.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ============ DAILY STATS Operations ============

  /// Fetch daily statistics for a specific month.
  static Future<List<DailyReadingStats>> fetchDailyStats({
    int? year,
    int? month,
  }) async {
    final now = DateTime.now();
    final targetYear = year ?? now.year;
    final targetMonth = month ?? now.month;

    final dateRange = DateRange.forMonth(targetYear, targetMonth);

    final response = await _client
        .from(_statsTable)
        .select()
        .eq('user_id', _userId)
        .gte('date', _isoDateFormat.format(dateRange.start))
        .lte('date', _isoDateFormat.format(dateRange.end))
        .order('date', ascending: true);

    return (response as List)
        .map((json) => DailyReadingStats.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch daily statistics for a date range.
  static Future<List<DailyReadingStats>> fetchDailyStatsRange(DateRange dateRange) async {
    final response = await _client
        .from(_statsTable)
        .select()
        .eq('user_id', _userId)
        .gte('date', _isoDateFormat.format(dateRange.start))
        .lte('date', _isoDateFormat.format(dateRange.end))
        .order('date', ascending: true);

    return (response as List)
        .map((json) => DailyReadingStats.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch today's statistics.
  static Future<DailyReadingStats?> fetchTodayStats() async {
    final today = _isoDateFormat.format(DateTime.now());

    final response = await _client
        .from(_statsTable)
        .select()
        .eq('user_id', _userId)
        .eq('date', today)
        .maybeSingle();

    if (response == null) return null;
    return DailyReadingStats.fromJson(response);
  }

  // ============ HEATMAP Data ============

  /// Calculate heatmap data for visualization.
  /// Returns data for the last [days] days (default: 365 for yearly view).
  static Future<List<HeatmapData>> calculateHeatmapData({int days = 365}) async {
    final dateRange = DateRange.lastDays(days);
    final stats = await fetchDailyStatsRange(dateRange);

    // Create a map for quick lookup
    final statsMap = <String, DailyReadingStats>{};
    for (final stat in stats) {
      statsMap[_isoDateFormat.format(stat.date)] = stat;
    }

    // Generate heatmap data for each day
    final heatmapData = <HeatmapData>[];
    var currentDate = dateRange.start;

    while (!currentDate.isAfter(dateRange.end)) {
      final dateKey = _isoDateFormat.format(currentDate);
      final stat = statsMap[dateKey];

      final pagesRead = stat?.totalPagesRead ?? 0;
      final activityLevel = _calculateActivityLevel(pagesRead);

      heatmapData.add(HeatmapData(
        date: currentDate,
        pagesRead: pagesRead,
        activityLevel: activityLevel,
      ));

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return heatmapData;
  }

  /// Calculate heatmap data as a map (for flutter_heatmap_calendar).
  static Future<Map<DateTime, int>> calculateHeatmapMap({int days = 365}) async {
    final heatmapData = await calculateHeatmapData(days: days);
    final map = <DateTime, int>{};

    for (final data in heatmapData) {
      // Normalize date to remove time component
      final normalizedDate = DateTime(data.date.year, data.date.month, data.date.day);
      map[normalizedDate] = data.activityLevel;
    }

    return map;
  }

  /// Calculate activity level (0-4) based on pages read.
  static int _calculateActivityLevel(int pagesRead) {
    if (pagesRead == 0) return 0;
    if (pagesRead <= 10) return 1;
    if (pagesRead <= 30) return 2;
    if (pagesRead <= 60) return 3;
    return 4;
  }

  // ============ AGGREGATION Operations ============

  /// Manually aggregate daily stats for a specific date.
  /// Useful for recalculating stats if needed.
  static Future<DailyReadingStats> aggregateDailyStats(DateTime date) async {
    final dateStr = _isoDateFormat.format(date);

    // Fetch all logs for the date
    final logsResponse = await _client
        .from(_logsTable)
        .select()
        .eq('user_id', _userId)
        .eq('date', dateStr);

    final logs = (logsResponse as List)
        .map((json) => ReadingLog.fromJson(json as Map<String, dynamic>))
        .toList();

    // Calculate totals
    final totalPagesRead = logs.fold<int>(0, (sum, log) => sum + log.pagesRead);
    final uniqueBooks = logs.map((log) => log.bookId).toSet();
    final booksReadCount = uniqueBooks.length;

    // Upsert daily stats
    final statsData = {
      'user_id': _userId,
      'date': dateStr,
      'total_pages_read': totalPagesRead,
      'books_read_count': booksReadCount,
    };

    final response = await _client
        .from(_statsTable)
        .upsert(statsData, onConflict: 'user_id,date')
        .select()
        .single();

    return DailyReadingStats.fromJson(response);
  }

  /// Recalculate all daily stats for a date range.
  static Future<void> recalculateStatsForRange(DateRange dateRange) async {
    var currentDate = dateRange.start;

    while (!currentDate.isAfter(dateRange.end)) {
      await aggregateDailyStats(currentDate);
      currentDate = currentDate.add(const Duration(days: 1));
    }
  }

  // ============ SUMMARY Statistics ============

  /// Get reading summary for the current week.
  static Future<ReadingSummary> getWeeklySummary() async {
    return _getSummaryForRange(DateRange.thisWeek());
  }

  /// Get reading summary for the current month.
  static Future<ReadingSummary> getMonthlySummary() async {
    return _getSummaryForRange(DateRange.thisMonth());
  }

  /// Get reading summary for the current year.
  static Future<ReadingSummary> getYearlySummary() async {
    return _getSummaryForRange(DateRange.thisYear());
  }

  /// Get reading summary for all time.
  static Future<ReadingSummary> getAllTimeSummary() async {
    final stats = await _client
        .from(_statsTable)
        .select()
        .eq('user_id', _userId);

    final statsList = (stats as List)
        .map((json) => DailyReadingStats.fromJson(json as Map<String, dynamic>))
        .toList();

    return ReadingSummary.fromStats(statsList);
  }

  static Future<ReadingSummary> _getSummaryForRange(DateRange dateRange) async {
    final stats = await fetchDailyStatsRange(dateRange);
    return ReadingSummary.fromStats(stats);
  }

  // ============ STREAK Calculation ============

  /// Calculate current reading streak (consecutive days with reading activity).
  static Future<int> calculateCurrentStreak() async {
    final stats = await fetchDailyStatsRange(DateRange.lastDays(365));

    if (stats.isEmpty) return 0;

    // Sort by date descending
    stats.sort((a, b) => b.date.compareTo(a.date));

    // Create a set of dates with activity
    final activeDates = stats
        .where((s) => s.hasActivity)
        .map((s) => _isoDateFormat.format(s.date))
        .toSet();

    // Check if today or yesterday has activity (streak can continue from yesterday)
    final today = DateTime.now();
    final todayStr = _isoDateFormat.format(today);
    final yesterdayStr = _isoDateFormat.format(today.subtract(const Duration(days: 1)));

    if (!activeDates.contains(todayStr) && !activeDates.contains(yesterdayStr)) {
      return 0;
    }

    // Count consecutive days
    var streak = 0;
    var checkDate = activeDates.contains(todayStr) ? today : today.subtract(const Duration(days: 1));

    while (true) {
      final dateStr = _isoDateFormat.format(checkDate);
      if (activeDates.contains(dateStr)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  /// Calculate longest reading streak ever.
  static Future<int> calculateLongestStreak() async {
    final stats = await _client
        .from(_statsTable)
        .select()
        .eq('user_id', _userId)
        .gt('total_pages_read', 0)
        .order('date', ascending: true);

    final statsList = (stats as List)
        .map((json) => DailyReadingStats.fromJson(json as Map<String, dynamic>))
        .toList();

    if (statsList.isEmpty) return 0;

    var longestStreak = 1;
    var currentStreak = 1;

    for (var i = 1; i < statsList.length; i++) {
      final prevDate = statsList[i - 1].date;
      final currDate = statsList[i].date;
      final difference = currDate.difference(prevDate).inDays;

      if (difference == 1) {
        currentStreak++;
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
      } else {
        currentStreak = 1;
      }
    }

    return longestStreak;
  }

  // ============ DELETE Operations ============

  /// Delete a reading log by ID.
  static Future<void> deleteReadingLog(String logId) async {
    await _client
        .from(_logsTable)
        .delete()
        .eq('id', logId)
        .eq('user_id', _userId);
  }

  /// Delete all reading logs for a book.
  static Future<void> deleteBookReadingLogs(String bookId) async {
    await _client
        .from(_logsTable)
        .delete()
        .eq('book_id', bookId)
        .eq('user_id', _userId);
  }
}

/// Summary statistics for a period.
class ReadingSummary {
  final int totalPagesRead;
  final int totalDaysRead;
  final int uniqueBooksRead;
  final double averagePagesPerDay;
  final int maxPagesInDay;
  final DateTime? mostActiveDate;

  const ReadingSummary({
    required this.totalPagesRead,
    required this.totalDaysRead,
    required this.uniqueBooksRead,
    required this.averagePagesPerDay,
    required this.maxPagesInDay,
    this.mostActiveDate,
  });

  factory ReadingSummary.fromStats(List<DailyReadingStats> stats) {
    if (stats.isEmpty) {
      return const ReadingSummary(
        totalPagesRead: 0,
        totalDaysRead: 0,
        uniqueBooksRead: 0,
        averagePagesPerDay: 0,
        maxPagesInDay: 0,
      );
    }

    final activeDays = stats.where((s) => s.hasActivity).toList();
    final totalPages = activeDays.fold<int>(0, (sum, s) => sum + s.totalPagesRead);
    final totalBooks = activeDays.fold<int>(0, (sum, s) => sum + s.booksReadCount);
    final maxPages = activeDays.isEmpty
        ? 0
        : activeDays.map((s) => s.totalPagesRead).reduce((a, b) => a > b ? a : b);

    DailyReadingStats? mostActive;
    if (activeDays.isNotEmpty) {
      mostActive = activeDays.reduce((a, b) => a.totalPagesRead > b.totalPagesRead ? a : b);
    }

    return ReadingSummary(
      totalPagesRead: totalPages,
      totalDaysRead: activeDays.length,
      uniqueBooksRead: totalBooks,
      averagePagesPerDay: activeDays.isEmpty ? 0 : totalPages / activeDays.length,
      maxPagesInDay: maxPages,
      mostActiveDate: mostActive?.date,
    );
  }

  @override
  String toString() {
    return 'ReadingSummary(pages: $totalPagesRead, days: $totalDaysRead, avg: ${averagePagesPerDay.toStringAsFixed(1)}/day)';
  }
}
