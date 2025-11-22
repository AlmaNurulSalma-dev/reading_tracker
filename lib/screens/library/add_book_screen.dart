import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:reading_tracker/models/models.dart';
import 'package:reading_tracker/services/book_service.dart';
import 'package:reading_tracker/utils/app_theme.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _totalPagesController = TextEditingController();

  PlatformFile? _selectedPdfFile;
  bool _isLoading = false;
  bool _isUploadingPdf = false;
  double _uploadProgress = 0;
  String? _uploadedPdfUrl;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _totalPagesController.dispose();
    super.dispose();
  }

  Future<void> _pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: kIsWeb, // Load bytes for web
        withReadStream: !kIsWeb, // Use stream for mobile
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedPdfFile = result.files.first;
          _uploadedPdfUrl = null; // Reset if new file selected
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<String?> _uploadPdfFile() async {
    if (_selectedPdfFile == null) return null;

    setState(() {
      _isUploadingPdf = true;
      _uploadProgress = 0;
    });

    try {
      String? pdfUrl;

      if (kIsWeb) {
        // Web: Use bytes
        if (_selectedPdfFile!.bytes != null) {
          pdfUrl = await BookService.uploadPDFBytes(
            _selectedPdfFile!.bytes!,
            _selectedPdfFile!.name,
          );
        }
      } else {
        // Mobile/Desktop: Use file path
        if (_selectedPdfFile!.path != null) {
          final file = File(_selectedPdfFile!.path!);
          pdfUrl = await BookService.uploadPDF(file);
        }
      }

      setState(() {
        _uploadedPdfUrl = pdfUrl;
        _uploadProgress = 1.0;
      });

      return pdfUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return null;
    } finally {
      setState(() {
        _isUploadingPdf = false;
      });
    }
  }

  void _removePdfFile() {
    setState(() {
      _selectedPdfFile = null;
      _uploadedPdfUrl = null;
      _uploadProgress = 0;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload PDF if selected and not already uploaded
      String? pdfUrl = _uploadedPdfUrl;
      if (_selectedPdfFile != null && pdfUrl == null) {
        pdfUrl = await _uploadPdfFile();
      }

      // Create book
      final book = await BookService.addBookSimple(
        title: _titleController.text.trim(),
        author: _authorController.text.trim().isNotEmpty
            ? _authorController.text.trim()
            : null,
        totalPages: int.parse(_totalPagesController.text.trim()),
        pdfUrl: pdfUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${book.title} added successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, book);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding book: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Book'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSubmit,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Book Icon Header
              _buildHeader(),
              const SizedBox(height: AppSpacing.xl),

              // Title Field
              _buildTitleField(),
              const SizedBox(height: AppSpacing.md),

              // Author Field
              _buildAuthorField(),
              const SizedBox(height: AppSpacing.md),

              // Total Pages Field
              _buildTotalPagesField(),
              const SizedBox(height: AppSpacing.lg),

              // PDF Upload Section
              _buildPdfUploadSection(),
              const SizedBox(height: AppSpacing.xl),

              // Submit Button
              _buildSubmitButton(),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppGradients.accentGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.menu_book_rounded,
          size: 48,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Book Title',
          style: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: _titleController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'Enter book title',
            prefixIcon: Icon(Icons.book_outlined),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter the book title';
            }
            if (value.trim().length < 2) {
              return 'Title must be at least 2 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAuthorField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Author',
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(Optional)',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: _authorController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'Enter author name',
            prefixIcon: Icon(Icons.person_outlined),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalPagesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total Pages',
          style: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: _totalPagesController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: 'Enter total number of pages',
            prefixIcon: Icon(Icons.numbers_outlined),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter the total pages';
            }
            final pages = int.tryParse(value.trim());
            if (pages == null) {
              return 'Please enter a valid number';
            }
            if (pages <= 0) {
              return 'Pages must be greater than 0';
            }
            if (pages > 50000) {
              return 'Pages cannot exceed 50,000';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPdfUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'PDF File',
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(Optional)',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Upload a PDF version of your book for easy reading',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // PDF Upload Area
        if (_selectedPdfFile == null)
          _buildPdfUploadButton()
        else
          _buildSelectedPdfCard(),
      ],
    );
  }

  Widget _buildPdfUploadButton() {
    return InkWell(
      onTap: _pickPdfFile,
      borderRadius: AppRadius.borderRadiusMd,
      child: Container(
        padding: AppSpacing.paddingLg,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppRadius.borderRadiusMd,
          border: Border.all(
            color: AppColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.upload_file,
                size: 32,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap to select PDF',
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Maximum file size: 50MB',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedPdfCard() {
    final fileName = _selectedPdfFile!.name;
    final fileSize = _selectedPdfFile!.size;
    final fileSizeStr = _formatFileSize(fileSize);

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(
          color: _uploadedPdfUrl != null ? AppColors.success : AppColors.accent,
          width: 1.5,
        ),
        boxShadow: AppShadows.small,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // PDF Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: AppRadius.borderRadiusSm,
                ),
                child: const Icon(
                  Icons.picture_as_pdf,
                  color: AppColors.error,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // File Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          fileSizeStr,
                          style: AppTextStyles.caption,
                        ),
                        if (_uploadedPdfUrl != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.successLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 12,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Uploaded',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Remove Button
              IconButton(
                onPressed: _isUploadingPdf ? null : _removePdfFile,
                icon: const Icon(Icons.close),
                color: AppColors.textSecondary,
                tooltip: 'Remove file',
              ),
            ],
          ),

          // Upload Progress
          if (_isUploadingPdf) ...[
            const SizedBox(height: AppSpacing.md),
            Column(
              children: [
                LinearProgressIndicator(
                  value: _uploadProgress > 0 ? _uploadProgress : null,
                  backgroundColor: AppColors.progressBackground,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 4),
                Text(
                  'Uploading...',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ],

          // Upload Button (if not uploaded yet)
          if (_uploadedPdfUrl == null && !_isUploadingPdf) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _uploadPdfFile,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Upload Now'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderRadiusMd,
          ),
        ),
        child: _isLoading
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
                  Text(
                    _isUploadingPdf ? 'Uploading PDF...' : 'Saving...',
                    style: AppTextStyles.button,
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle_outline),
                  const SizedBox(width: 8),
                  Text(
                    'Add Book',
                    style: AppTextStyles.button,
                  ),
                ],
              ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
