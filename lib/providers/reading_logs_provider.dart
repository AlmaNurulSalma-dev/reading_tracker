import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reading_tracker/models/models.dart';
import 'package:reading_tracker/services/reading_log_service.dart';
import 'package:reading_tracker/providers/auth_provider.dart';

/// Notifier for managing reading logs state.
class ReadingLogsNotifier extends StateNotifier<AsyncValue<List<ReadingLog>>> {
  ReadingLogsNotifier() : super(const AsyncValue.loading()) {
    loadRecentLogs();
  }

  /// Load recent reading logs.
  Future<void> loadRecentLogs({int limit = 50}) async {
    state = const AsyncValue.loading();
    try {
      final logs = await ReadingLogService.fetchRecentLogs(limit: limit);
      state = AsyncValue.data(logs);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Load reading logs for a specific book.
  Future<void> loadBookLogs(String bookId) async {
    state = const AsyncValue.loading();
    try {
      final logs = await ReadingLogService.fetchBookReadingLogs(bookId);
      state = AsyncValue.data(logs);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Load today's reading logs.
  Future<void> loadTodayLogs() async {
    state = const AsyncValue.loading();
    try {
      final logs = await ReadingLogService.fetchTodayLogs();
      state = AsyncValue.data(logs);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Refresh logs.
  Future<void> refresh() => loadRecentLogs();

  /// Add a new reading log.
  Future<ReadingLog?> addLog({
    required String bookId,
    required int pagesRead,
    DateTime? readingDate,
    String? notes,
  }) async {
    try {
      final newLog = await ReadingLogService.logReadingSimple(
        bookId: bookId,
        pagesRead: pagesRead,
        readingDate: readingDate,
        notes: notes,
      );

      // Update state with new log
      state.whenData((logs) {
        state = AsyncValue.data([newLog, ...logs]);
      });

      return newLog;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  /// Delete a reading log.
  Future<bool> deleteLog(String logId) async {
    try {
      await ReadingLogService.deleteReadingLog(logId);

      // Remove log from state
      state.whenData((logs) {
        final updatedList = logs.where((log) => log.id != logId).toList();
        state = AsyncValue.data(updatedList);
      });

      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }
}

/// Provider for reading logs with state management.
final readingLogsProvider = StateNotifierProvider<ReadingLogsNotifier, AsyncValue<List<ReadingLog>>>((ref) {
  // Watch auth state to reload logs when user changes
  ref.watch(currentUserProvider);
  return ReadingLogsNotifier();
});

/// Provider for reading logs for a specific book.
final bookReadingLogsProvider = FutureProvider.family<List<ReadingLog>, String>((ref, bookId) async {
  return await ReadingLogService.fetchBookReadingLogs(bookId);
});

/// Provider for today's reading logs.
final todayLogsProvider = FutureProvider<List<ReadingLog>>((ref) async {
  // Watch auth state
  ref.watch(currentUserProvider);
  return await ReadingLogService.fetchTodayLogs();
});

/// Provider for today's pages read count.
final todayPagesReadProvider = Provider<int>((ref) {
  final todayLogsAsync = ref.watch(todayLogsProvider);
  return todayLogsAsync.when(
    data: (logs) => logs.fold<int>(0, (sum, log) => sum + log.pagesRead),
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for current reading streak.
final currentStreakProvider = FutureProvider<int>((ref) async {
  // Watch auth state
  ref.watch(currentUserProvider);
  return await ReadingLogService.calculateCurrentStreak();
});

/// Provider for longest reading streak.
final longestStreakProvider = FutureProvider<int>((ref) async {
  // Watch auth state
  ref.watch(currentUserProvider);
  return await ReadingLogService.calculateLongestStreak();
});

/// Provider for heatmap data.
final heatmapDataProvider = FutureProvider.family<Map<DateTime, int>, int>((ref, days) async {
  // Watch auth state
  ref.watch(currentUserProvider);
  return await ReadingLogService.calculateHeatmapMap(days: days);
});

/// Provider for reading summary by period.
final weeklySummaryProvider = FutureProvider<ReadingSummary>((ref) async {
  // Watch auth state
  ref.watch(currentUserProvider);
  return await ReadingLogService.getWeeklySummary();
});

final monthlySummaryProvider = FutureProvider<ReadingSummary>((ref) async {
  // Watch auth state
  ref.watch(currentUserProvider);
  return await ReadingLogService.getMonthlySummary();
});

final yearlySummaryProvider = FutureProvider<ReadingSummary>((ref) async {
  // Watch auth state
  ref.watch(currentUserProvider);
  return await ReadingLogService.getYearlySummary();
});

final allTimeSummaryProvider = FutureProvider<ReadingSummary>((ref) async {
  // Watch auth state
  ref.watch(currentUserProvider);
  return await ReadingLogService.getAllTimeSummary();
});
