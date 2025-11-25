import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reading_tracker/models/models.dart';
import 'package:reading_tracker/utils/streak_calculator.dart';
import 'package:reading_tracker/providers/daily_stats_provider.dart';
import 'package:reading_tracker/providers/auth_provider.dart';

/// Provider for calculating current streak from daily stats.
final currentStreakFromStatsProvider = Provider<AsyncValue<int>>((ref) {
  // Get last 365 days of stats
  final statsAsync = ref.watch(lastDaysStatsProvider(365));

  return statsAsync.when(
    data: (stats) {
      final streak = StreakCalculator.calculateCurrentStreak(stats);
      return AsyncValue.data(streak);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// Provider for calculating longest streak from daily stats.
final longestStreakFromStatsProvider = Provider<AsyncValue<int>>((ref) {
  // Get all-time stats (last 3 years should be enough)
  final statsAsync = ref.watch(lastDaysStatsProvider(1095));

  return statsAsync.when(
    data: (stats) {
      final streak = StreakCalculator.calculateLongestStreak(stats);
      return AsyncValue.data(streak);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// Provider for full streak statistics.
final streakStatsProvider = Provider<AsyncValue<StreakStats>>((ref) {
  // Watch auth state to reload when user changes
  ref.watch(currentUserProvider);

  // Get last 365 days of stats
  final statsAsync = ref.watch(lastDaysStatsProvider(365));

  return statsAsync.when(
    data: (stats) {
      final streakStats = StreakCalculator.calculateStreakStats(stats);
      return AsyncValue.data(streakStats);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// Provider for checking if today has activity.
final hasTodayActivityProvider = Provider<bool>((ref) {
  final todayStatsAsync = ref.watch(todayStatsProvider);
  return todayStatsAsync.when(
    data: (stats) => stats?.hasActivity ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider for activity rate (percentage of days with activity).
final activityRateProvider = Provider<AsyncValue<double>>((ref) {
  final statsAsync = ref.watch(lastDaysStatsProvider(30));

  return statsAsync.when(
    data: (stats) {
      final rate = StreakCalculator.calculateActivityRate(stats);
      return AsyncValue.data(rate);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// State notifier for tracking streak changes and triggering celebrations.
class StreakChangeNotifier extends StateNotifier<int?> {
  StreakChangeNotifier() : super(null);

  /// Update the streak and return true if it increased.
  bool updateStreak(int newStreak) {
    final oldStreak = state;
    state = newStreak;

    // Return true if streak increased from a non-null value
    if (oldStreak != null && newStreak > oldStreak) {
      return true;
    }

    return false;
  }

  /// Reset the tracked streak.
  void reset() {
    state = null;
  }

  /// Get the previous streak value.
  int? get previousStreak => state;
}

/// Provider for tracking streak changes.
final streakChangeNotifierProvider =
    StateNotifierProvider<StreakChangeNotifier, int?>((ref) {
  return StreakChangeNotifier();
});

/// Provider that triggers when streak should be celebrated.
/// Returns the new streak value when it increases, null otherwise.
final streakCelebrationTriggerProvider = Provider<int?>((ref) {
  final streakAsync = ref.watch(currentStreakFromStatsProvider);
  final streakNotifier = ref.watch(streakChangeNotifierProvider.notifier);

  return streakAsync.when(
    data: (currentStreak) {
      final shouldCelebrate = streakNotifier.updateStreak(currentStreak);
      return shouldCelebrate ? currentStreak : null;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});
