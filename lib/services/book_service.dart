import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:reading_tracker/models/models.dart';
import 'package:reading_tracker/services/supabase_service.dart';

/// Service for managing book-related operations with Supabase.
class BookService {
  static const String _tableName = 'books';
  static const String _storageBucket = 'book-pdfs';
  static const String _coversBucket = 'book-covers';

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

  // ============ READ Operations ============

  /// Fetch all books for the current user.
  /// Returns books sorted by updated_at descending (most recent first).
  static Future<List<Book>> fetchUserBooks() async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('user_id', _userId)
        .order('updated_at', ascending: false);

    return (response as List)
        .map((json) => Book.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single book by ID.
  static Future<Book?> fetchBookById(String bookId) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('id', bookId)
        .eq('user_id', _userId)
        .maybeSingle();

    if (response == null) return null;
    return Book.fromJson(response);
  }

  /// Fetch books with pagination.
  /// [limit] - Number of books per page.
  /// [offset] - Number of books to skip.
  static Future<List<Book>> fetchUserBooksPaginated({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('user_id', _userId)
        .order('updated_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => Book.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch books currently being read (not completed).
  static Future<List<Book>> fetchBooksInProgress() async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('user_id', _userId)
        .gt('total_pages', 0)
        .lt('current_page', _client.rpc('get_total_pages'))
        .order('updated_at', ascending: false);

    // Filter in Dart since complex column comparison isn't straightforward
    final books = (response as List)
        .map((json) => Book.fromJson(json as Map<String, dynamic>))
        .where((book) => !book.isCompleted && book.totalPages > 0)
        .toList();

    return books;
  }

  /// Fetch completed books.
  static Future<List<Book>> fetchCompletedBooks() async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('user_id', _userId)
        .order('updated_at', ascending: false);

    return (response as List)
        .map((json) => Book.fromJson(json as Map<String, dynamic>))
        .where((book) => book.isCompleted)
        .toList();
  }

  /// Search books by title or author.
  static Future<List<Book>> searchBooks(String query) async {
    final searchTerm = '%$query%';

    final response = await _client
        .from(_tableName)
        .select()
        .eq('user_id', _userId)
        .or('title.ilike.$searchTerm,author.ilike.$searchTerm')
        .order('updated_at', ascending: false);

    return (response as List)
        .map((json) => Book.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ============ CREATE Operations ============

  /// Add a new book for the current user.
  /// Returns the created book with generated ID and timestamps.
  static Future<Book> addBook(Book book) async {
    final bookData = {
      'user_id': _userId,
      'title': book.title,
      'author': book.author,
      'total_pages': book.totalPages,
      'current_page': book.currentPage,
      'pdf_url': book.pdfUrl,
      'cover_image_url': book.coverImageUrl,
    };

    final response = await _client
        .from(_tableName)
        .insert(bookData)
        .select()
        .single();

    return Book.fromJson(response);
  }

  /// Add a new book with minimal information.
  static Future<Book> addBookSimple({
    required String title,
    String? author,
    required int totalPages,
    String? pdfUrl,
    String? coverImageUrl,
  }) async {
    final bookData = {
      'user_id': _userId,
      'title': title,
      'author': author,
      'total_pages': totalPages,
      'current_page': 0,
      'pdf_url': pdfUrl,
      'cover_image_url': coverImageUrl,
    };

    final response = await _client
        .from(_tableName)
        .insert(bookData)
        .select()
        .single();

    return Book.fromJson(response);
  }

  // ============ UPDATE Operations ============

  /// Update reading progress for a book.
  /// Returns the updated book.
  static Future<Book> updateBookProgress(String bookId, int currentPage) async {
    final response = await _client
        .from(_tableName)
        .update({'current_page': currentPage})
        .eq('id', bookId)
        .eq('user_id', _userId)
        .select()
        .single();

    return Book.fromJson(response);
  }

  /// Update a book's details.
  /// Returns the updated book.
  static Future<Book> updateBook(Book book) async {
    final response = await _client
        .from(_tableName)
        .update(book.toUpdateJson())
        .eq('id', book.id)
        .eq('user_id', _userId)
        .select()
        .single();

    return Book.fromJson(response);
  }

  /// Update specific fields of a book.
  static Future<Book> updateBookFields(
    String bookId, {
    String? title,
    String? author,
    int? totalPages,
    int? currentPage,
    String? pdfUrl,
    String? coverImageUrl,
  }) async {
    final updates = <String, dynamic>{};

    if (title != null) updates['title'] = title;
    if (author != null) updates['author'] = author;
    if (totalPages != null) updates['total_pages'] = totalPages;
    if (currentPage != null) updates['current_page'] = currentPage;
    if (pdfUrl != null) updates['pdf_url'] = pdfUrl;
    if (coverImageUrl != null) updates['cover_image_url'] = coverImageUrl;

    if (updates.isEmpty) {
      throw ArgumentError('At least one field must be provided for update');
    }

    final response = await _client
        .from(_tableName)
        .update(updates)
        .eq('id', bookId)
        .eq('user_id', _userId)
        .select()
        .single();

    return Book.fromJson(response);
  }

  // ============ DELETE Operations ============

  /// Delete a book by ID.
  /// Also deletes associated PDF and cover image from storage.
  static Future<void> deleteBook(String bookId) async {
    // First, fetch the book to get file URLs for cleanup
    final book = await fetchBookById(bookId);

    // Delete the book record
    await _client
        .from(_tableName)
        .delete()
        .eq('id', bookId)
        .eq('user_id', _userId);

    // Clean up storage files if they exist
    if (book != null) {
      if (book.pdfUrl != null) {
        await _deleteFileFromUrl(book.pdfUrl!, _storageBucket);
      }
      if (book.coverImageUrl != null) {
        await _deleteFileFromUrl(book.coverImageUrl!, _coversBucket);
      }
    }
  }

  /// Delete multiple books by IDs.
  static Future<void> deleteBooks(List<String> bookIds) async {
    for (final bookId in bookIds) {
      await deleteBook(bookId);
    }
  }

  // ============ FILE UPLOAD Operations ============

  /// Upload a PDF file to Supabase Storage.
  /// Returns the public URL of the uploaded file.
  static Future<String> uploadPDF(File file) async {
    final fileName = _generateFileName(file.path, 'pdf');
    final filePath = '$_userId/$fileName';

    await _client.storage
        .from(_storageBucket)
        .upload(
          filePath,
          file,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: false,
          ),
        );

    final publicUrl = _client.storage
        .from(_storageBucket)
        .getPublicUrl(filePath);

    return publicUrl;
  }

  /// Upload a PDF from bytes (useful for web).
  static Future<String> uploadPDFBytes(List<int> bytes, String originalFileName) async {
    final fileName = _generateFileName(originalFileName, 'pdf');
    final filePath = '$_userId/$fileName';

    await _client.storage
        .from(_storageBucket)
        .uploadBinary(
          filePath,
          bytes as dynamic,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: false,
            contentType: 'application/pdf',
          ),
        );

    final publicUrl = _client.storage
        .from(_storageBucket)
        .getPublicUrl(filePath);

    return publicUrl;
  }

  /// Upload a cover image to Supabase Storage.
  /// Returns the public URL of the uploaded image.
  static Future<String> uploadCoverImage(File file) async {
    final extension = file.path.split('.').last.toLowerCase();
    final fileName = _generateFileName(file.path, extension);
    final filePath = '$_userId/$fileName';

    await _client.storage
        .from(_coversBucket)
        .upload(
          filePath,
          file,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: false,
          ),
        );

    final publicUrl = _client.storage
        .from(_coversBucket)
        .getPublicUrl(filePath);

    return publicUrl;
  }

  /// Upload a cover image from bytes.
  static Future<String> uploadCoverImageBytes(
    List<int> bytes,
    String originalFileName,
    String contentType,
  ) async {
    final extension = originalFileName.split('.').last.toLowerCase();
    final fileName = _generateFileName(originalFileName, extension);
    final filePath = '$_userId/$fileName';

    await _client.storage
        .from(_coversBucket)
        .uploadBinary(
          filePath,
          bytes as dynamic,
          fileOptions: FileOptions(
            cacheControl: '3600',
            upsert: false,
            contentType: contentType,
          ),
        );

    final publicUrl = _client.storage
        .from(_coversBucket)
        .getPublicUrl(filePath);

    return publicUrl;
  }

  // ============ Helper Methods ============

  /// Generate a unique file name with timestamp.
  static String _generateFileName(String originalPath, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final originalName = originalPath.split('/').last.split('\\').last;
    final nameWithoutExt = originalName.contains('.')
        ? originalName.substring(0, originalName.lastIndexOf('.'))
        : originalName;
    final sanitizedName = nameWithoutExt
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
        .toLowerCase();
    return '${sanitizedName}_$timestamp.$extension';
  }

  /// Delete a file from storage given its public URL.
  static Future<void> _deleteFileFromUrl(String url, String bucket) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // Find the bucket name in the path and get everything after it
      final bucketIndex = pathSegments.indexOf(bucket);
      if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) return;

      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

      await _client.storage.from(bucket).remove([filePath]);
    } catch (e) {
      // Silently fail - file might not exist or URL format changed
    }
  }

  /// Get book count for the current user.
  static Future<int> getBookCount() async {
    final response = await _client
        .from(_tableName)
        .select('id')
        .eq('user_id', _userId);

    return (response as List).length;
  }

  /// Get total pages read across all books.
  static Future<int> getTotalPagesRead() async {
    final books = await fetchUserBooks();
    return books.fold<int>(0, (sum, book) => sum + book.currentPage);
  }
}
