import 'package:reading_tracker/models/models.dart';

/// Utility class for calculating reading streaks from daily stats.
class StreakCalculator {
  StreakCalculator._();

  /// Calculate the current reading streak (consecutive days up to today).
  ///
  /// Returns the number of consecutive days the user has read, counting backwards
  /// from today. Returns 0 if the user hasn't read today or yesterday.
  static int calculateCurrentStreak(List<DailyReadingStats> stats) {
    if (stats.isEmpty) return 0;

    // Sort stats by date in descending order (most recent first)
    final sortedStats = List<DailyReadingStats>.from(stats)
      ..sort((a, b) => b.date.compareTo(a.date));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Check if user read today or yesterday (to allow for some flexibility)
    final mostRecentStat = sortedStats.first;
    final mostRecentDate = DateTime(
      mostRecentStat.date.year,
      mostRecentStat.date.month,
      mostRecentStat.date.day,
    );

    // If most recent reading is more than 1 day ago, streak is broken
    if (!mostRecentDate.isAtSameMomentAs(today) &&
        !mostRecentDate.isAtSameMomentAs(yesterday)) {
      return 0;
    }

    // Count consecutive days with activity
    int streak = 0;
    DateTime? previousDate;

    for (final stat in sortedStats) {
      // Skip days with no activity
      if (!stat.hasActivity) continue;

      final statDate = DateTime(
        stat.date.year,
        stat.date.month,
        stat.date.day,
      );

      if (previousDate == null) {
        // First stat with activity
        streak = 1;
        previousDate = statDate;
      } else {
        // Check if this stat is exactly one day before the previous
        final expectedDate = previousDate.subtract(const Duration(days: 1));

        if (statDate.isAtSameMomentAs(expectedDate)) {
          streak++;
          previousDate = statDate;
        } else {
          // Gap found, stop counting
          break;
        }
      }
    }

    return streak;
  }

  /// Calculate the longest reading streak from all stats.
  ///
  /// Returns the maximum number of consecutive days the user has ever read.
  static int calculateLongestStreak(List<DailyReadingStats> stats) {
    if (stats.isEmpty) return 0;

    // Sort stats by date in ascending order (oldest first)
    final sortedStats = List<DailyReadingStats>.from(stats)
      ..sort((a, b) => a.date.compareTo(b.date));

    int longestStreak = 0;
    int currentStreak = 0;
    DateTime? previousDate;

    for (final stat in sortedStats) {
      // Skip days with no activity
      if (!stat.hasActivity) {
        currentStreak = 0;
        previousDate = null;
        continue;
      }

      final statDate = DateTime(
        stat.date.year,
        stat.date.month,
        stat.date.day,
      );

      if (previousDate == null) {
        // First stat with activity
        currentStreak = 1;
        previousDate = statDate;
      } else {
        // Check if this stat is exactly one day after the previous
        final expectedDate = previousDate.add(const Duration(days: 1));

        if (statDate.isAtSameMomentAs(expectedDate)) {
          currentStreak++;
          previousDate = statDate;
        } else {
          // Gap found, reset streak
          currentStreak = 1;
          previousDate = statDate;
        }
      }

      // Update longest streak if current is longer
      if (currentStreak > longestStreak) {
        longestStreak = currentStreak;
      }
    }

    return longestStreak;
  }

  /// Get streak level based on streak count.
  ///
  /// Returns a string describing the streak level:
  /// - "🔥 On Fire!" for 30+ days
  /// - "⚡ Blazing!" for 14-29 days
  /// - "💪 Strong!" for 7-13 days
  /// - "✨ Going!" for 3-6 days
  /// - "🌱 Starting!" for 1-2 days
  static String getStreakLevel(int streak) {
    if (streak >= 30) return '🔥 On Fire!';
    if (streak >= 14) return '⚡ Blazing!';
    if (streak >= 7) return '💪 Strong!';
    if (streak >= 3) return '✨ Going!';
    if (streak >= 1) return '🌱 Starting!';
    return '';
  }

  /// Get encouragement message based on streak.
  static String getStreakMessage(int streak) {
    if (streak == 0) return 'Start your reading streak today!';
    if (streak == 1) return 'Great start! Keep it up!';
    if (streak < 7) return 'You\'re building momentum!';
    if (streak < 14) return 'One week down! Keep going!';
    if (streak < 30) return 'You\'re on a roll! Don\'t break the chain!';
    if (streak < 100) return 'Amazing dedication! You\'re unstoppable!';
    return 'Legendary streak! You\'re an inspiration!';
  }

  /// Calculate streak statistics.
  static StreakStats calculateStreakStats(List<DailyReadingStats> stats) {
    final currentStreak = calculateCurrentStreak(stats);
    final longestStreak = calculateLongestStreak(stats);
    final level = getStreakLevel(currentStreak);
    final message = getStreakMessage(currentStreak);

    // Calculate days until next milestone
    int? daysToNextMilestone;
    String? nextMilestone;

    if (currentStreak < 3) {
      daysToNextMilestone = 3 - currentStreak;
      nextMilestone = '3-day streak';
    } else if (currentStreak < 7) {
      daysToNextMilestone = 7 - currentStreak;
      nextMilestone = '1-week streak';
    } else if (currentStreak < 14) {
      daysToNextMilestone = 14 - currentStreak;
      nextMilestone = '2-week streak';
    } else if (currentStreak < 30) {
      daysToNextMilestone = 30 - currentStreak;
      nextMilestone = '30-day streak';
    } else if (currentStreak < 100) {
      daysToNextMilestone = 100 - currentStreak;
      nextMilestone = '100-day streak';
    }

    return StreakStats(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      level: level,
      message: message,
      daysToNextMilestone: daysToNextMilestone,
      nextMilestone: nextMilestone,
    );
  }

  /// Check if today has reading activity.
  static bool hasTodayActivity(List<DailyReadingStats> stats) {
    if (stats.isEmpty) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return stats.any((stat) {
      final statDate = DateTime(
        stat.date.year,
        stat.date.month,
        stat.date.day,
      );
      return statDate.isAtSameMomentAs(today) && stat.hasActivity;
    });
  }

  /// Get days with activity from stats.
  static List<DateTime> getActiveDays(List<DailyReadingStats> stats) {
    return stats
        .where((stat) => stat.hasActivity)
        .map((stat) => DateTime(
              stat.date.year,
              stat.date.month,
              stat.date.day,
            ))
        .toList();
  }

  /// Calculate the percentage of days with reading activity.
  static double calculateActivityRate(List<DailyReadingStats> stats) {
    if (stats.isEmpty) return 0.0;

    final activeDays = stats.where((stat) => stat.hasActivity).length;
    return (activeDays / stats.length) * 100;
  }
}

/// Data class for streak statistics.
class StreakStats {
  final int currentStreak;
  final int longestStreak;
  final String level;
  final String message;
  final int? daysToNextMilestone;
  final String? nextMilestone;

  const StreakStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.level,
    required this.message,
    this.daysToNextMilestone,
    this.nextMilestone,
  });

  bool get hasMilestone => daysToNextMilestone != null && nextMilestone != null;

  @override
  String toString() {
    return 'StreakStats(current: $currentStreak, longest: $longestStreak, level: $level)';
  }
}
