import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:reading_tracker/models/models.dart';
import 'package:reading_tracker/services/book_service.dart';
import 'package:reading_tracker/services/reading_log_service.dart';
import 'package:reading_tracker/utils/app_theme.dart';

class LogReadingScreen extends StatefulWidget {
  /// Optional pre-selected book
  final Book? initialBook;

  const LogReadingScreen({
    super.key,
    this.initialBook,
  });

  @override
  State<LogReadingScreen> createState() => _LogReadingScreenState();
}

class _LogReadingScreenState extends State<LogReadingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pagesReadController = TextEditingController();

  List<Book> _books = [];
  Book? _selectedBook;
  DateTime _selectedDate = DateTime.now();
  bool _isLoadingBooks = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Calculated values
  int _newCurrentPage = 0;
  int _pagesRead = 0;

  @override
  void initState() {
    super.initState();
    _loadBooks();
    _pagesReadController.addListener(_updateCalculations);
  }

  @override
  void dispose() {
    _pagesReadController.removeListener(_updateCalculations);
    _pagesReadController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoadingBooks = true;
      _errorMessage = null;
    });

    try {
      final books = await BookService.fetchUserBooks();

      // Filter out completed books
      final availableBooks = books.where((b) => !b.isCompleted).toList();

      if (mounted) {
        setState(() {
          _books = availableBooks;
          _isLoadingBooks = false;

          // Set initial book if provided
          if (widget.initialBook != null) {
            _selectedBook = availableBooks.firstWhere(
              (b) => b.id == widget.initialBook!.id,
              orElse: () => availableBooks.isNotEmpty ? availableBooks.first : widget.initialBook!,
            );
          } else if (availableBooks.isNotEmpty) {
            _selectedBook = availableBooks.first;
          }

          _updateCalculations();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load books: $e';
          _isLoadingBooks = false;
        });
      }
    }
  }

  void _updateCalculations() {
    if (_selectedBook == null) {
      setState(() {
        _pagesRead = 0;
        _newCurrentPage = 0;
      });
      return;
    }

    final pagesRead = int.tryParse(_pagesReadController.text) ?? 0;
    final currentPage = _selectedBook!.currentPage;
    final totalPages = _selectedBook!.totalPages;
    final newCurrentPage = (currentPage + pagesRead).clamp(0, totalPages);

    setState(() {
      _pagesRead = pagesRead;
      _newCurrentPage = newCurrentPage;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accent,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBook == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a book'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final startPage = _selectedBook!.currentPage;
      final endPage = _newCurrentPage;

      // Log reading session
      await ReadingLogService.logReading(
        bookId: _selectedBook!.id,
        startPage: startPage,
        endPage: endPage,
        date: _selectedDate,
      );

      // Update book progress
      await BookService.updateBookProgress(
        _selectedBook!.id,
        endPage,
      );

      if (mounted) {
        final isCompleted = endPage >= _selectedBook!.totalPages;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCompleted
                  ? 'Congratulations! You finished "${_selectedBook!.title}"!'
                  : 'Logged $_pagesRead pages for "${_selectedBook!.title}"',
            ),
            backgroundColor: isCompleted ? AppColors.success : AppColors.tertiary,
            duration: const Duration(seconds: 3),
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging reading: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _setQuickPages(int pages) {
    final maxPages = _selectedBook != null
        ? _selectedBook!.totalPages - _selectedBook!.currentPage
        : 0;
    final actualPages = pages.clamp(0, maxPages);
    _pagesReadController.text = actualPages.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Reading'),
      ),
      body: _isLoadingBooks
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : _books.isEmpty
                  ? _buildEmptyState()
                  : _buildForm(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Something went wrong',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _loadBooks,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No books to log',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add a book to your library first,\nor all your books are completed!',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLg,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Book Selector
            _buildBookSelector(),
            const SizedBox(height: AppSpacing.lg),

            // Selected Book Preview
            if (_selectedBook != null) ...[
              _buildBookPreview(),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Date Picker
            _buildDatePicker(),
            const SizedBox(height: AppSpacing.lg),

            // Pages Read Input
            _buildPagesInput(),
            const SizedBox(height: AppSpacing.md),

            // Quick Select Buttons
            _buildQuickSelectButtons(),
            const SizedBox(height: AppSpacing.lg),

            // Progress Preview
            if (_selectedBook != null && _pagesRead > 0)
              _buildProgressPreview(),
            const SizedBox(height: AppSpacing.xl),

            // Submit Button
            _buildSubmitButton(),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildBookSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Book',
          style: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<Book>(
          value: _selectedBook,
          isExpanded: true,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.book_outlined),
            hintText: 'Choose a book',
          ),
          items: _books.map((book) {
            return DropdownMenuItem<Book>(
              value: book,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium,
                        ),
                        Text(
                          '${book.currentPage}/${book.totalPages} pages',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${book.progressPercentage.round()}%',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (book) {
            setState(() {
              _selectedBook = book;
              _pagesReadController.clear();
            });
            _updateCalculations();
          },
          validator: (value) {
            if (value == null) {
              return 'Please select a book';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBookPreview() {
    final book = _selectedBook!;
    final remainingPages = book.totalPages - book.currentPage;

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.3),
            AppColors.secondary.withOpacity(0.3),
          ],
        ),
        borderRadius: AppRadius.borderRadiusMd,
      ),
      child: Row(
        children: [
          // Book Cover Placeholder
          Container(
            width: 50,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: AppRadius.borderRadiusSm,
            ),
            child: const Icon(
              Icons.menu_book,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Book Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (book.author != null)
                  Text(
                    book.author!,
                    style: AppTextStyles.caption,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.bookmark,
                      size: 14,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Page ${book.currentPage} of ${book.totalPages}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
                Text(
                  '$remainingPages pages remaining',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          // Progress Circle
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${book.progressPercentage.round()}%',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reading Date',
          style: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: _selectDate,
          borderRadius: AppRadius.borderRadiusSm,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.borderRadiusSm,
              border: Border.all(color: AppColors.border.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFormat.format(_selectedDate),
                        style: AppTextStyles.bodyMedium,
                      ),
                      if (isToday)
                        Text(
                          'Today',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPagesInput() {
    final maxPages = _selectedBook != null
        ? _selectedBook!.totalPages - _selectedBook!.currentPage
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Pages Read',
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (_selectedBook != null)
              Text(
                'Max: $maxPages pages',
                style: AppTextStyles.caption,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: _pagesReadController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: '0',
            prefixIcon: IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                final current = int.tryParse(_pagesReadController.text) ?? 0;
                if (current > 0) {
                  _pagesReadController.text = (current - 1).toString();
                }
              },
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                final current = int.tryParse(_pagesReadController.text) ?? 0;
                if (current < maxPages) {
                  _pagesReadController.text = (current + 1).toString();
                }
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter pages read';
            }
            final pages = int.tryParse(value.trim());
            if (pages == null) {
              return 'Please enter a valid number';
            }
            if (pages <= 0) {
              return 'Pages must be greater than 0';
            }
            if (pages > maxPages) {
              return 'Cannot exceed remaining pages ($maxPages)';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildQuickSelectButtons() {
    final maxPages = _selectedBook != null
        ? _selectedBook!.totalPages - _selectedBook!.currentPage
        : 0;

    final quickOptions = [5, 10, 25, 50].where((p) => p <= maxPages).toList();

    if (quickOptions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Select',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...quickOptions.map((pages) => _buildQuickButton(pages)),
            if (maxPages > 0)
              _buildQuickButton(maxPages, label: 'Finish'),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickButton(int pages, {String? label}) {
    final isSelected = _pagesRead == pages;

    return Material(
      color: isSelected ? AppColors.accent : AppColors.surfaceVariant,
      borderRadius: AppRadius.borderRadiusSm,
      child: InkWell(
        onTap: () => _setQuickPages(pages),
        borderRadius: AppRadius.borderRadiusSm,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label ?? '$pages pages',
            style: AppTextStyles.labelMedium.copyWith(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressPreview() {
    final book = _selectedBook!;
    final currentProgress = book.progressPercentage;
    final newProgress = ((_newCurrentPage / book.totalPages) * 100).clamp(0.0, 100.0);
    final isCompleting = _newCurrentPage >= book.totalPages;

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: isCompleting ? AppColors.successLight : AppColors.tertiaryLight,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(
          color: isCompleting ? AppColors.success : AppColors.tertiary,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isCompleting ? Icons.emoji_events : Icons.trending_up,
                color: isCompleting ? AppColors.success : AppColors.tertiary,
              ),
              const SizedBox(width: 8),
              Text(
                isCompleting ? 'You will finish this book!' : 'Progress Preview',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isCompleting ? AppColors.success : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildProgressColumn(
                'Current',
                '${currentProgress.round()}%',
                'Page ${book.currentPage}',
              ),
              Icon(
                Icons.arrow_forward,
                color: AppColors.textSecondary,
              ),
              _buildProgressColumn(
                'After',
                '${newProgress.round()}%',
                'Page $_newCurrentPage',
                highlight: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: newProgress / 100,
              backgroundColor: AppColors.progressBackground,
              color: isCompleting ? AppColors.success : AppColors.accent,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressColumn(String label, String value, String subtitle, {bool highlight = false}) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.caption,
        ),
        Text(
          value,
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: highlight ? AppColors.accent : AppColors.textPrimary,
          ),
        ),
        Text(
          subtitle,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _isSubmitting || _pagesRead <= 0 ? null : _handleSubmit,
        child: _isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Saving...', style: AppTextStyles.button),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline),
                  const SizedBox(width: 8),
                  Text(
                    _pagesRead > 0 ? 'Log $_pagesRead Pages' : 'Log Reading',
                    style: AppTextStyles.button,
                  ),
                ],
              ),
      ),
    );
  }
}
