import 'package:intl/intl.dart';

/// Model representing a book in the reading tracker.
class Book {
  final String id;
  final String userId;
  final String title;
  final String? author;
  final int totalPages;
  final int currentPage;
  final String? pdfUrl;
  final String? coverImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Book({
    required this.id,
    required this.userId,
    required this.title,
    this.author,
    required this.totalPages,
    required this.currentPage,
    this.pdfUrl,
    this.coverImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate reading progress as a percentage (0-100).
  double get progressPercentage {
    if (totalPages <= 0) return 0.0;
    return (currentPage / totalPages * 100).clamp(0.0, 100.0);
  }

  /// Get progress as a decimal (0.0-1.0) for progress indicators.
  double get progressDecimal {
    if (totalPages <= 0) return 0.0;
    return (currentPage / totalPages).clamp(0.0, 1.0);
  }

  /// Check if the book has been completed.
  bool get isCompleted => currentPage >= totalPages && totalPages > 0;

  /// Get remaining pages to read.
  int get remainingPages => (totalPages - currentPage).clamp(0, totalPages);

  /// Get formatted progress string (e.g., "150/300 pages").
  String get progressText => '$currentPage/$totalPages pages';

  /// Get formatted percentage string (e.g., "50.0%").
  String get progressPercentageText => '${progressPercentage.toStringAsFixed(1)}%';

  /// Get formatted created date.
  String get formattedCreatedAt => DateFormat('MMM d, yyyy').format(createdAt);

  /// Get formatted updated date.
  String get formattedUpdatedAt => DateFormat('MMM d, yyyy').format(updatedAt);

  /// Create a Book from JSON map (Supabase response).
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      author: json['author'] as String?,
      totalPages: json['total_pages'] as int? ?? 0,
      currentPage: json['current_page'] as int? ?? 0,
      pdfUrl: json['pdf_url'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert Book to JSON map for Supabase insert/update.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'author': author,
      'total_pages': totalPages,
      'current_page': currentPage,
      'pdf_url': pdfUrl,
      'cover_image_url': coverImageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert Book to JSON map for insert (without id, timestamps auto-generated).
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'title': title,
      'author': author,
      'total_pages': totalPages,
      'current_page': currentPage,
      'pdf_url': pdfUrl,
      'cover_image_url': coverImageUrl,
    };
  }

  /// Convert Book to JSON map for update (only updatable fields).
  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title,
      'author': author,
      'total_pages': totalPages,
      'current_page': currentPage,
      'pdf_url': pdfUrl,
      'cover_image_url': coverImageUrl,
    };
  }

  /// Create a copy of Book with updated fields.
  Book copyWith({
    String? id,
    String? userId,
    String? title,
    String? author,
    int? totalPages,
    int? currentPage,
    String? pdfUrl,
    String? coverImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Book(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      author: author ?? this.author,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Book && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Book(id: $id, title: $title, author: $author, progress: $progressPercentageText)';
  }
}
