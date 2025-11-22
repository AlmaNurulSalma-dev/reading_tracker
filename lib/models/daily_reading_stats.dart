import 'package:intl/intl.dart';

/// Model representing aggregated daily reading statistics.
class DailyReadingStats {
  final String id;
  final String userId;
  final DateTime date;
  final int totalPagesRead;
  final int booksReadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DailyReadingStats({
    required this.id,
    required this.userId,
    required this.date,
    required this.totalPagesRead,
    required this.booksReadCount,
    required this.createdAt,
    required this.updatedAt,
  });

  // Date formatters
  static final DateFormat _fullDateFormat = DateFormat('EEEE, MMMM d, yyyy');
  static final DateFormat _shortDateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _dayMonthFormat = DateFormat('MMM d');
  static final DateFormat _isoDateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _dayOfWeekFormat = DateFormat('EEE');
  static final DateFormat _dayNumberFormat = DateFormat('d');

  /// Get full formatted date (e.g., "Friday, November 22, 2024").
  String get formattedDateFull => _fullDateFormat.format(date);

  /// Get short formatted date (e.g., "Nov 22, 2024").
  String get formattedDateShort => _shortDateFormat.format(date);

  /// Get day and month only (e.g., "Nov 22").
  String get formattedDayMonth => _dayMonthFormat.format(date);

  /// Get ISO format date (e.g., "2024-11-22").
  String get formattedDateIso => _isoDateFormat.format(date);

  /// Get day of week abbreviation (e.g., "Fri").
  String get dayOfWeek => _dayOfWeekFormat.format(date);

  /// Get day number (e.g., "22").
  String get dayNumber => _dayNumberFormat.format(date);

  /// Get relative date description.
  String get relativeDateDescription {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final statsDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(statsDate).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return dayOfWeek;
    } else {
      return formattedDateShort;
    }
  }

  /// Get pages read summary text (e.g., "125 pages").
  String get pagesReadText => '$totalPagesRead ${totalPagesRead == 1 ? 'page' : 'pages'}';

  /// Get books count summary text (e.g., "3 books").
  String get booksCountText => '$booksReadCount ${booksReadCount == 1 ? 'book' : 'books'}';

  /// Get full summary (e.g., "125 pages across 3 books").
  String get fullSummary => '$pagesReadText across $booksCountText';

  /// Check if this was an active reading day.
  bool get hasActivity => totalPagesRead > 0;

  /// Get activity level for heatmap (0-4 scale).
  /// 0: No activity
  /// 1: Light (1-10 pages)
  /// 2: Moderate (11-30 pages)
  /// 3: Good (31-60 pages)
  /// 4: Excellent (60+ pages)
  int get activityLevel {
    if (totalPagesRead == 0) return 0;
    if (totalPagesRead <= 10) return 1;
    if (totalPagesRead <= 30) return 2;
    if (totalPagesRead <= 60) return 3;
    return 4;
  }

  /// Create a DailyReadingStats from JSON map (Supabase response).
  factory DailyReadingStats.fromJson(Map<String, dynamic> json) {
    return DailyReadingStats(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      totalPagesRead: json['total_pages_read'] as int? ?? 0,
      booksReadCount: json['books_read_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert DailyReadingStats to JSON map for Supabase.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': _isoDateFormat.format(date),
      'total_pages_read': totalPagesRead,
      'books_read_count': booksReadCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert DailyReadingStats to JSON map for insert.
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'date': _isoDateFormat.format(date),
      'total_pages_read': totalPagesRead,
      'books_read_count': booksReadCount,
    };
  }

  /// Create an empty stats entry for a given date.
  factory DailyReadingStats.empty({
    required String userId,
    required DateTime date,
  }) {
    return DailyReadingStats(
      id: '',
      userId: userId,
      date: date,
      totalPagesRead: 0,
      booksReadCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create a copy of DailyReadingStats with updated fields.
  DailyReadingStats copyWith({
    String? id,
    String? userId,
    DateTime? date,
    int? totalPagesRead,
    int? booksReadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyReadingStats(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      totalPagesRead: totalPagesRead ?? this.totalPagesRead,
      booksReadCount: booksReadCount ?? this.booksReadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyReadingStats && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DailyReadingStats(id: $id, date: $formattedDateShort, pages: $totalPagesRead, books: $booksReadCount)';
  }
}
