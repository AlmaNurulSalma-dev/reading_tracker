import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:spline_flutter/spline_flutter.dart';
import 'package:reading_tracker/models/book.dart';
import 'package:reading_tracker/utils/app_theme.dart';

/// A 3D book visualization widget with interactive rotation and progress-based styling.
///
/// This widget displays a book in 3D that can be rotated by dragging.
/// The book's color changes based on reading progress percentage.
///
/// ## Features
/// - Drag to rotate the book in 3D space
/// - Color transitions based on reading progress
/// - Spline 3D integration (when scene is provided)
/// - Fallback to Flutter-based 3D visualization
///
/// ## Usage
///
/// ```dart
/// Book3DModel(
///   book: myBook,
///   size: 200,
///   onTap: () => print('Book tapped'),
/// )
/// ```
class Book3DModel extends StatefulWidget {
  /// The book to display.
  final Book? book;

  /// Reading progress as decimal (0.0 - 1.0).
  /// If book is provided, this is calculated automatically.
  final double? progress;

  /// Size of the 3D model widget.
  final double size;

  /// Spline scene URL for cloud-hosted 3D model.
  final String? splineUrl;

  /// Local Spline asset path.
  final String? splineAsset;

  /// Callback when book is tapped.
  final VoidCallback? onTap;

  /// Callback when rotation changes.
  final void Function(double rotationY, double rotationX)? onRotationChanged;

  /// Whether to enable drag-to-rotate interaction.
  final bool enableRotation;

  /// Whether to auto-rotate when not being dragged.
  final bool autoRotate;

  /// Auto-rotation speed (rotations per minute).
  final double autoRotateSpeed;

  /// Initial Y-axis rotation in radians.
  final double initialRotationY;

  /// Initial X-axis rotation in radians.
  final double initialRotationX;

  /// Whether to show the book title on the spine.
  final bool showTitle;

  /// Whether to use Spline 3D (false uses Flutter 3D fallback).
  final bool useSpline;

  /// Custom book cover widget.
  final Widget? customCover;

  const Book3DModel({
    super.key,
    this.book,
    this.progress,
    this.size = 200,
    this.splineUrl,
    this.splineAsset,
    this.onTap,
    this.onRotationChanged,
    this.enableRotation = true,
    this.autoRotate = false,
    this.autoRotateSpeed = 10,
    this.initialRotationY = -0.3,
    this.initialRotationX = 0.1,
    this.showTitle = true,
    this.useSpline = false,
    this.customCover,
  });

  /// Creates a Book3DModel from a Book instance.
  factory Book3DModel.fromBook({
    required Book book,
    double size = 200,
    VoidCallback? onTap,
    bool enableRotation = true,
    bool autoRotate = false,
  }) {
    return Book3DModel(
      book: book,
      size: size,
      onTap: onTap,
      enableRotation: enableRotation,
      autoRotate: autoRotate,
    );
  }

  /// Creates a Book3DModel with Spline 3D scene.
  factory Book3DModel.withSpline({
    required String splineUrl,
    Book? book,
    double? progress,
    double size = 200,
    VoidCallback? onTap,
  }) {
    return Book3DModel(
      book: book,
      progress: progress,
      size: size,
      splineUrl: splineUrl,
      onTap: onTap,
      useSpline: true,
    );
  }

  @override
  State<Book3DModel> createState() => _Book3DModelState();
}

class _Book3DModelState extends State<Book3DModel>
    with SingleTickerProviderStateMixin {
  late double _rotationY;
  late double _rotationX;
  double _lastRotationY = 0;
  double _lastRotationX = 0;

  AnimationController? _autoRotateController;
  SplineController? _splineController;

  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _rotationY = widget.initialRotationY;
    _rotationX = widget.initialRotationX;

    if (widget.autoRotate) {
      _setupAutoRotation();
    }
  }

  void _setupAutoRotation() {
    _autoRotateController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (60000 / widget.autoRotateSpeed).round(),
      ),
    )..addListener(() {
        if (!_isDragging) {
          setState(() {
            _rotationY = widget.initialRotationY +
                (_autoRotateController!.value * 2 * math.pi);
          });
        }
      });

    _autoRotateController!.repeat();
  }

  @override
  void dispose() {
    _autoRotateController?.dispose();
    super.dispose();
  }

  double get _effectiveProgress {
    if (widget.progress != null) {
      return widget.progress!.clamp(0.0, 1.0);
    }
    if (widget.book != null) {
      return widget.book!.progressDecimal;
    }
    return 0.0;
  }

  /// Get color based on reading progress.
  Color get _progressColor {
    final progress = _effectiveProgress;

    if (progress >= 1.0) {
      return AppColors.success; // Completed - Green
    } else if (progress >= 0.75) {
      return AppColors.tertiary; // 75%+ - Teal
    } else if (progress >= 0.50) {
      return AppColors.accent; // 50%+ - Purple
    } else if (progress >= 0.25) {
      return AppColors.primary; // 25%+ - Pink
    } else {
      return AppColors.secondary; // <25% - Yellow/Cream
    }
  }

  /// Get gradient colors based on progress.
  List<Color> get _progressGradientColors {
    final baseColor = _progressColor;
    return [
      baseColor,
      Color.lerp(baseColor, Colors.white, 0.3)!,
    ];
  }

  void _onPanStart(DragStartDetails details) {
    _isDragging = true;
    _lastRotationY = _rotationY;
    _lastRotationX = _rotationX;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.enableRotation) return;

    setState(() {
      // Horizontal drag rotates around Y axis
      _rotationY = _lastRotationY + (details.localPosition.dx - details.delta.dx) * 0.01;

      // Vertical drag rotates around X axis (limited range)
      _rotationX = (_lastRotationX + details.delta.dy * 0.005)
          .clamp(-0.5, 0.5);
    });

    widget.onRotationChanged?.call(_rotationY, _rotationX);

    // Update Spline scene if connected
    _updateSplineRotation();
  }

  void _onPanEnd(DragEndDetails details) {
    _isDragging = false;
    _lastRotationY = _rotationY;
    _lastRotationX = _rotationX;
  }

  void _updateSplineRotation() {
    if (_splineController != null) {
      _splineController!.setVariable('rotationY', _rotationY);
      _splineController!.setVariable('rotationX', _rotationX);
    }
  }

  void _updateSplineProgress() {
    if (_splineController != null) {
      final progress = _effectiveProgress;
      _splineController!.setVariable('progress', progress);

      // Set color variables for Spline
      final color = _progressColor;
      _splineController!.setVariable('colorR', color.red / 255);
      _splineController!.setVariable('colorG', color.green / 255);
      _splineController!.setVariable('colorB', color.blue / 255);
    }
  }

  void _onSplineCreated(SplineController controller) {
    _splineController = controller;
    _updateSplineProgress();
    _updateSplineRotation();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onPanStart: widget.enableRotation ? _onPanStart : null,
      onPanUpdate: widget.enableRotation ? _onPanUpdate : null,
      onPanEnd: widget.enableRotation ? _onPanEnd : null,
      child: SizedBox(
        width: widget.size,
        height: widget.size * 1.4,
        child: widget.useSpline && (widget.splineUrl != null || widget.splineAsset != null)
            ? _buildSplineBook()
            : _buildFlutter3DBook(),
      ),
    );
  }

  Widget _buildSplineBook() {
    return Stack(
      children: [
        if (widget.splineUrl != null)
          SplineWidget.network(
            widget.splineUrl!,
            onSplineControllerCreated: _onSplineCreated,
          )
        else if (widget.splineAsset != null)
          SplineWidget.asset(
            widget.splineAsset!,
            onSplineControllerCreated: _onSplineCreated,
          ),

        // Progress overlay indicator
        Positioned(
          bottom: 8,
          left: 8,
          right: 8,
          child: _buildProgressIndicator(),
        ),
      ],
    );
  }

  Widget _buildFlutter3DBook() {
    final bookWidth = widget.size * 0.6;
    final bookHeight = widget.size * 1.2;
    final bookDepth = widget.size * 0.12;

    return Center(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // Perspective
          ..rotateY(_rotationY)
          ..rotateX(_rotationX),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Book shadow
            Transform.translate(
              offset: const Offset(8, 8),
              child: Container(
                width: bookWidth,
                height: bookHeight,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            // Main book body
            _buildBookBody(bookWidth, bookHeight, bookDepth),
          ],
        ),
      ),
    );
  }

  Widget _buildBookBody(double width, double height, double depth) {
    return SizedBox(
      width: width + depth,
      height: height,
      child: Stack(
        children: [
          // Book spine (left side)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Transform(
              alignment: Alignment.centerRight,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(-math.pi / 2),
              child: _buildSpine(depth, height),
            ),
          ),

          // Book pages (edge effect)
          Positioned(
            left: depth - 2,
            top: 4,
            bottom: 4,
            child: _buildPageEdges(width * 0.05, height - 8),
          ),

          // Book front cover
          Positioned(
            left: depth,
            top: 0,
            child: _buildFrontCover(width, height),
          ),

          // Book back cover (slightly visible)
          Positioned(
            left: depth - 4,
            top: 2,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..translate(0.0, 0.0, -depth),
              child: Container(
                width: width,
                height: height - 4,
                decoration: BoxDecoration(
                  color: _progressColor.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrontCover(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _progressGradientColors,
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(
            color: _progressColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: widget.customCover ?? _buildDefaultCover(width, height),
    );
  }

  Widget _buildDefaultCover(double width, double height) {
    final book = widget.book;

    return Stack(
      children: [
        // Cover texture/pattern
        Positioned.fill(
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
            child: CustomPaint(
              painter: _BookCoverPatternPainter(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
        ),

        // Book cover image if available
        if (book?.coverImageUrl != null)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
              child: Image.network(
                book!.coverImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),

        // Title and author overlay
        Positioned.fill(
          child: Container(
            padding: EdgeInsets.all(width * 0.1),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (book != null) ...[
                  Text(
                    book.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width * 0.1,
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow(color: Colors.black45, blurRadius: 4),
                      ],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (book.author != null) ...[
                    SizedBox(height: width * 0.02),
                    Text(
                      book.author!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: width * 0.07,
                        shadows: const [
                          Shadow(color: Colors.black45, blurRadius: 4),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),

        // Progress badge
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              '${(_effectiveProgress * 100).round()}%',
              style: TextStyle(
                color: _progressColor,
                fontSize: width * 0.08,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpine(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color.lerp(_progressColor, Colors.black, 0.3)!,
            _progressColor,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        ),
      ),
      child: widget.showTitle && widget.book != null
          ? RotatedBox(
              quarterTurns: 3,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    widget.book!.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width * 0.5,
                      fontWeight: FontWeight.w600,
                      shadows: const [
                        Shadow(color: Colors.black38, blurRadius: 2),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildPageEdges(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade100,
            Colors.grey.shade200,
          ],
        ),
      ),
      child: CustomPaint(
        painter: _PageEdgesPainter(),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _effectiveProgress,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation(_progressColor),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(_effectiveProgress * 100).round()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for book cover pattern.
class _BookCoverPatternPainter extends CustomPainter {
  final Color color;

  _BookCoverPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw diagonal lines pattern
    for (double i = -size.height; i < size.width + size.height; i += 20) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for page edges effect.
class _PageEdgesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw horizontal lines to simulate pages
    final pageCount = (size.height / 2).floor();
    for (int i = 0; i < pageCount; i++) {
      final y = i * 2.0;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Controller for Book3DModel interactions.
///
/// Use this to programmatically control the book's rotation and state.
class Book3DModelController {
  _Book3DModelState? _state;

  /// Attach to a Book3DModel state.
  void _attach(_Book3DModelState state) {
    _state = state;
  }

  /// Detach from the Book3DModel state.
  void _detach() {
    _state = null;
  }

  /// Reset rotation to initial position.
  void resetRotation() {
    if (_state != null && _state!.mounted) {
      _state!.setState(() {
        _state!._rotationY = _state!.widget.initialRotationY;
        _state!._rotationX = _state!.widget.initialRotationX;
      });
    }
  }

  /// Set rotation programmatically.
  void setRotation(double rotationY, double rotationX) {
    if (_state != null && _state!.mounted) {
      _state!.setState(() {
        _state!._rotationY = rotationY;
        _state!._rotationX = rotationX.clamp(-0.5, 0.5);
      });
    }
  }

  /// Animate rotation to target position.
  void animateToRotation(double targetY, double targetX, {Duration? duration}) {
    // Implementation would require additional animation controller
    // For now, just set directly
    setRotation(targetY, targetX);
  }
}

/// A showcase widget displaying multiple book 3D models in a carousel.
class Book3DCarousel extends StatelessWidget {
  final List<Book> books;
  final double itemSize;
  final void Function(Book book)? onBookTap;
  final bool enableRotation;

  const Book3DCarousel({
    super.key,
    required this.books,
    this.itemSize = 150,
    this.onBookTap,
    this.enableRotation = true,
  });

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return SizedBox(
        height: itemSize * 1.4,
        child: Center(
          child: Text(
            'No books to display',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: itemSize * 1.5,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.horizontalMd,
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Book3DModel(
              book: book,
              size: itemSize,
              enableRotation: enableRotation,
              onTap: onBookTap != null ? () => onBookTap!(book) : null,
            ),
          );
        },
      ),
    );
  }
}

/// Progress color legend widget.
class Book3DProgressLegend extends StatelessWidget {
  const Book3DProgressLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final legendItems = [
      _LegendItem('0-24%', AppColors.secondary, 'Just Started'),
      _LegendItem('25-49%', AppColors.primary, 'Getting Into It'),
      _LegendItem('50-74%', AppColors.accent, 'Halfway There'),
      _LegendItem('75-99%', AppColors.tertiary, 'Almost Done'),
      _LegendItem('100%', AppColors.success, 'Completed'),
    ];

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: legendItems.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: item.color.withOpacity(0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              item.label,
              style: AppTextStyles.caption,
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _LegendItem {
  final String label;
  final Color color;
  final String description;

  _LegendItem(this.label, this.color, this.description);
}
