import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reading_tracker/models/models.dart';
import 'package:reading_tracker/services/book_service.dart';
import 'package:reading_tracker/providers/auth_provider.dart';

/// Notifier for managing books state with CRUD operations.
class BooksNotifier extends StateNotifier<AsyncValue<List<Book>>> {
  BooksNotifier() : super(const AsyncValue.loading()) {
    loadBooks();
  }

  /// Load all books for the current user.
  Future<void> loadBooks() async {
    state = const AsyncValue.loading();
    try {
      final books = await BookService.fetchUserBooks();
      state = AsyncValue.data(books);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Refresh books list.
  Future<void> refresh() => loadBooks();

  /// Add a new book.
  Future<Book?> addBook(Book book) async {
    try {
      final newBook = await BookService.createBook(book);

      // Update state with new book
      state.whenData((books) {
        state = AsyncValue.data([newBook, ...books]);
      });

      return newBook;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  /// Update an existing book.
  Future<Book?> updateBook(Book book) async {
    try {
      final updatedBook = await BookService.updateBook(book);

      // Update state with modified book
      state.whenData((books) {
        final updatedList = books.map((b) {
          return b.id == updatedBook.id ? updatedBook : b;
        }).toList();
        state = AsyncValue.data(updatedList);
      });

      return updatedBook;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  /// Delete a book.
  Future<bool> deleteBook(String bookId) async {
    try {
      await BookService.deleteBook(bookId);

      // Remove book from state
      state.whenData((books) {
        final updatedList = books.where((b) => b.id != bookId).toList();
        state = AsyncValue.data(updatedList);
      });

      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  /// Get a specific book by ID.
  Book? getBookById(String bookId) {
    return state.whenData((books) {
      try {
        return books.firstWhere((b) => b.id == bookId);
      } catch (e) {
        return null;
      }
    }).value;
  }
}

/// Provider for books list with state management.
final booksProvider = StateNotifierProvider<BooksNotifier, AsyncValue<List<Book>>>((ref) {
  // Watch auth state to reload books when user changes
  ref.watch(currentUserProvider);
  return BooksNotifier();
});

/// Provider for filtered books by status.
final filteredBooksProvider = Provider.family<AsyncValue<List<Book>>, BookFilter>((ref, filter) {
  final booksAsync = ref.watch(booksProvider);

  return booksAsync.when(
    data: (books) {
      List<Book> filtered;
      switch (filter) {
        case BookFilter.all:
          filtered = books;
          break;
        case BookFilter.reading:
          filtered = books.where((book) => !book.isCompleted && book.currentPage > 0).toList();
          break;
        case BookFilter.notStarted:
          filtered = books.where((book) => book.currentPage == 0).toList();
          break;
        case BookFilter.completed:
          filtered = books.where((book) => book.isCompleted).toList();
          break;
      }
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// Provider for currently reading books.
final currentlyReadingBooksProvider = Provider<AsyncValue<List<Book>>>((ref) {
  return ref.watch(filteredBooksProvider(BookFilter.reading));
});

/// Provider for completed books.
final completedBooksProvider = Provider<AsyncValue<List<Book>>>((ref) {
  return ref.watch(filteredBooksProvider(BookFilter.completed));
});

/// Provider for books count.
final booksCountProvider = Provider<int>((ref) {
  final booksAsync = ref.watch(booksProvider);
  return booksAsync.when(
    data: (books) => books.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for currently reading books count.
final readingBooksCountProvider = Provider<int>((ref) {
  final booksAsync = ref.watch(currentlyReadingBooksProvider);
  return booksAsync.when(
    data: (books) => books.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for completed books count.
final completedBooksCountProvider = Provider<int>((ref) {
  final booksAsync = ref.watch(completedBooksProvider);
  return booksAsync.when(
    data: (books) => books.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for a specific book by ID.
final bookByIdProvider = Provider.family<AsyncValue<Book?>, String>((ref, bookId) {
  final booksAsync = ref.watch(booksProvider);

  return booksAsync.when(
    data: (books) {
      try {
        final book = books.firstWhere((b) => b.id == bookId);
        return AsyncValue.data(book);
      } catch (e) {
        return const AsyncValue.data(null);
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});
