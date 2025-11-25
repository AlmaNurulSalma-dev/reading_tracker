import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reading_tracker/models/models.dart';
import 'package:reading_tracker/services/reading_log_service.dart';
import 'package:reading_tracker/providers/auth_provider.dart';

/// Provider for today's daily reading stats.
final todayStatsProvider = FutureProvider<DailyReadingStats?>((ref) async {
  // Watch auth state to reload when user changes
  ref.watch(currentUserProvider);
  return await ReadingLogService.fetchTodayStats();
});

/// Provider for daily stats within a date range.
final dailyStatsRangeProvider = FutureProvider.family<List<DailyReadingStats>, DateRange>((ref, dateRange) async {
  // Watch auth state
  ref.watch(currentUserProvider);
  return await ReadingLogService.fetchDailyStatsRange(dateRange);
});

/// Provider for weekly daily stats.
final weeklyStatsProvider = FutureProvider<List<DailyReadingStats>>((ref) async {
  // Watch auth state
  ref.watch(currentUserProvider);
  return await ReadingLogService.fetchDailyStatsRange(DateRange.thisWeek());
});

/// Provider for monthly daily stats.
final monthlyStatsProvider = FutureProvider<List<DailyReadingStats>>((ref) async {
  // Watch auth state
  ref.watch(currentUserProvider);
  return await ReadingLogService.fetchDailyStatsRange(DateRange.thisMonth());
});

/// Provider for yearly daily stats.
final yearlyStatsProvider = FutureProvider<List<DailyReadingStats>>((ref) async {
  // Watch auth state
  ref.watch(currentUserProvider);
  return await ReadingLogService.fetchDailyStatsRange(DateRange.thisYear());
});

/// Provider for last N days stats.
final lastDaysStatsProvider = FutureProvider.family<List<DailyReadingStats>, int>((ref, days) async {
  // Watch auth state
  ref.watch(currentUserProvider);
  return await ReadingLogService.fetchDailyStatsRange(DateRange.lastDays(days));
});

/// Notifier for managing daily stats state with refresh capability.
class DailyStatsNotifier extends StateNotifier<AsyncValue<List<DailyReadingStats>>> {
  final DateRange dateRange;

  DailyStatsNotifier(this.dateRange) : super(const AsyncValue.loading()) {
    loadStats();
  }

  /// Load stats for the configured date range.
  Future<void> loadStats() async {
    state = const AsyncValue.loading();
    try {
      final stats = await ReadingLogService.fetchDailyStatsRange(dateRange);
      state = AsyncValue.data(stats);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Refresh stats.
  Future<void> refresh() => loadStats();

  /// Recalculate stats for the date range.
  Future<void> recalculate() async {
    try {
      await ReadingLogService.recalculateStatsForRange(dateRange);
      await loadStats();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider for daily stats with state management and refresh capability.
final dailyStatsNotifierProvider = StateNotifierProvider.family<DailyStatsNotifier, AsyncValue<List<DailyReadingStats>>, DateRange>(
  (ref, dateRange) {
    // Watch auth state to reload when user changes
    ref.watch(currentUserProvider);
    return DailyStatsNotifier(dateRange);
  },
);

/// Provider for total pages read today.
final todayTotalPagesProvider = Provider<int>((ref) {
  final todayStatsAsync = ref.watch(todayStatsProvider);
  return todayStatsAsync.when(
    data: (stats) => stats?.totalPagesRead ?? 0,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for total books read today.
final todayBooksCountProvider = Provider<int>((ref) {
  final todayStatsAsync = ref.watch(todayStatsProvider);
  return todayStatsAsync.when(
    data: (stats) => stats?.booksReadCount ?? 0,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for weekly total pages.
final weeklyTotalPagesProvider = Provider<int>((ref) {
  final weeklyStatsAsync = ref.watch(weeklyStatsProvider);
  return weeklyStatsAsync.when(
    data: (stats) => stats.fold<int>(0, (sum, stat) => sum + stat.totalPagesRead),
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for monthly total pages.
final monthlyTotalPagesProvider = Provider<int>((ref) {
  final monthlyStatsAsync = ref.watch(monthlyStatsProvider);
  return monthlyStatsAsync.when(
    data: (stats) => stats.fold<int>(0, (sum, stat) => sum + stat.totalPagesRead),
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for yearly total pages.
final yearlyTotalPagesProvider = Provider<int>((ref) {
  final yearlyStatsAsync = ref.watch(yearlyStatsProvider);
  return yearlyStatsAsync.when(
    data: (stats) => stats.fold<int>(0, (sum, stat) => sum + stat.totalPagesRead),
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for weekly average pages per day.
final weeklyAveragePagesProvider = Provider<double>((ref) {
  final weeklyStatsAsync = ref.watch(weeklyStatsProvider);
  return weeklyStatsAsync.when(
    data: (stats) {
      if (stats.isEmpty) return 0.0;
      final total = stats.fold<int>(0, (sum, stat) => sum + stat.totalPagesRead);
      return total / stats.length;
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

/// Provider for monthly average pages per day.
final monthlyAveragePagesProvider = Provider<double>((ref) {
  final monthlyStatsAsync = ref.watch(monthlyStatsProvider);
  return monthlyStatsAsync.when(
    data: (stats) {
      if (stats.isEmpty) return 0.0;
      final total = stats.fold<int>(0, (sum, stat) => sum + stat.totalPagesRead);
      return total / stats.length;
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

/// Provider for reading days this week.
final weeklyReadingDaysProvider = Provider<int>((ref) {
  final weeklyStatsAsync = ref.watch(weeklyStatsProvider);
  return weeklyStatsAsync.when(
    data: (stats) => stats.where((stat) => stat.hasActivity).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for reading days this month.
final monthlyReadingDaysProvider = Provider<int>((ref) {
  final monthlyStatsAsync = ref.watch(monthlyStatsProvider);
  return monthlyStatsAsync.when(
    data: (stats) => stats.where((stat) => stat.hasActivity).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
