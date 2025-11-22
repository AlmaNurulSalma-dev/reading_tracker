import 'package:flutter/material.dart';
import 'package:spline_flutter/spline_flutter.dart';
import 'package:reading_tracker/utils/app_theme.dart';

/// A widget that displays a 3D bookshelf using Spline.
///
/// This widget wraps the Spline runtime viewer and provides fallback
/// UI when the 3D scene is loading or unavailable.
///
/// ## Usage
///
/// ```dart
/// SplineBookshelf(
///   height: 200,
///   onBookTap: (bookIndex) {
///     print('Tapped book $bookIndex');
///   },
/// )
/// ```
///
/// ## Spline Scene Setup
///
/// To use this widget with your own Spline scene:
///
/// 1. Create your 3D bookshelf scene at https://spline.design
/// 2. Export as "Code Export" (.splinecode file)
/// 3. Place the file in `assets/spline/` directory
/// 4. Update the `splineUrl` or `splineAsset` parameter
///
/// See [SPLINE_INTEGRATION.md] for detailed setup instructions.
class SplineBookshelf extends StatefulWidget {
  /// Height of the bookshelf widget.
  final double height;

  /// URL to load the Spline scene from (cloud hosted).
  /// Use this for scenes hosted on Spline's CDN.
  final String? splineUrl;

  /// Local asset path to the .splinecode file.
  /// Example: 'assets/spline/bookshelf.splinecode'
  final String? splineAsset;

  /// Callback when a book in the 3D scene is tapped.
  /// The book index is passed as parameter (if scene supports it).
  final void Function(int bookIndex)? onBookTap;

  /// Callback when the scene has finished loading.
  final VoidCallback? onSceneLoaded;

  /// Callback when scene loading fails.
  final void Function(dynamic error)? onError;

  /// Whether to show loading indicator while scene loads.
  final bool showLoadingIndicator;

  /// Whether to show the fallback placeholder instead of Spline.
  /// Useful for development or when Spline scene is not ready.
  final bool usePlaceholder;

  /// Custom placeholder widget to show instead of default.
  final Widget? customPlaceholder;

  /// Background gradient for the widget.
  final Gradient? backgroundGradient;

  const SplineBookshelf({
    super.key,
    this.height = 200,
    this.splineUrl,
    this.splineAsset,
    this.onBookTap,
    this.onSceneLoaded,
    this.onError,
    this.showLoadingIndicator = true,
    this.usePlaceholder = true, // Default to placeholder until Spline scene is ready
    this.customPlaceholder,
    this.backgroundGradient,
  });

  /// Creates a SplineBookshelf with a cloud-hosted scene URL.
  factory SplineBookshelf.fromUrl({
    required String url,
    double height = 200,
    void Function(int)? onBookTap,
    VoidCallback? onSceneLoaded,
  }) {
    return SplineBookshelf(
      splineUrl: url,
      height: height,
      onBookTap: onBookTap,
      onSceneLoaded: onSceneLoaded,
      usePlaceholder: false,
    );
  }

  /// Creates a SplineBookshelf with a local asset.
  factory SplineBookshelf.fromAsset({
    required String assetPath,
    double height = 200,
    void Function(int)? onBookTap,
    VoidCallback? onSceneLoaded,
  }) {
    return SplineBookshelf(
      splineAsset: assetPath,
      height: height,
      onBookTap: onBookTap,
      onSceneLoaded: onSceneLoaded,
      usePlaceholder: false,
    );
  }

  @override
  State<SplineBookshelf> createState() => _SplineBookshelfState();
}

class _SplineBookshelfState extends State<SplineBookshelf>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  SplineController? _splineController;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (!widget.usePlaceholder) {
      _initializeSpline();
    } else {
      _isLoading = false;
      _animationController.forward();
    }
  }

  void _initializeSpline() {
    // Spline initialization will happen when the widget builds
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
  }

  void _onSplineCreated(SplineController controller) {
    _splineController = controller;
    setState(() {
      _isLoading = false;
    });
    _animationController.forward();
    widget.onSceneLoaded?.call();
  }

  void _onSplineError(dynamic error) {
    setState(() {
      _isLoading = false;
      _hasError = true;
      _errorMessage = error.toString();
    });
    _animationController.forward();
    widget.onError?.call(error);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _splineController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: widget.backgroundGradient ?? _defaultGradient,
      ),
      child: widget.usePlaceholder
          ? _buildPlaceholder()
          : _buildSplineContent(),
    );
  }

  LinearGradient get _defaultGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primary,
          AppColors.primaryLight,
          AppColors.secondaryLight,
        ],
      );

  Widget _buildSplineContent() {
    if (_hasError) {
      return _buildErrorState();
    }

    return Stack(
      children: [
        // Spline 3D Scene
        if (widget.splineUrl != null)
          SplineWidget.network(
            widget.splineUrl!,
            onSplineControllerCreated: _onSplineCreated,
          )
        else if (widget.splineAsset != null)
          SplineWidget.asset(
            widget.splineAsset!,
            onSplineControllerCreated: _onSplineCreated,
          )
        else
          _buildPlaceholder(),

        // Loading Overlay
        if (_isLoading && widget.showLoadingIndicator)
          _buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: AppColors.primary.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 3,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Loading 3D Scene...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: AppSpacing.paddingMd,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 40,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Unable to load 3D scene',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _errorMessage!,
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              TextButton.icon(
                onPressed: _initializeSpline,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    if (widget.customPlaceholder != null) {
      return widget.customPlaceholder!;
    }
    return const _BookshelfPlaceholder();
  }
}

/// Default placeholder widget showing a stylized 2D bookshelf.
class _BookshelfPlaceholder extends StatelessWidget {
  const _BookshelfPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background pattern
        Positioned.fill(
          child: CustomPaint(
            painter: _BookshelfPatternPainter(),
          ),
        ),

        // Center content
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: AppRadius.borderRadiusMd,
                  boxShadow: AppShadows.medium,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.view_in_ar,
                      size: 48,
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '3D Bookshelf',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                    Text(
                      'Spline Integration',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Decorative books
        Positioned(
          left: 20,
          bottom: 20,
          child: _DecorativeBook(
            color: AppColors.accent,
            width: 40,
            height: 60,
          ),
        ),
        Positioned(
          left: 70,
          bottom: 20,
          child: _DecorativeBook(
            color: AppColors.tertiary,
            width: 35,
            height: 55,
          ),
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: _DecorativeBook(
            color: AppColors.primary,
            width: 38,
            height: 58,
          ),
        ),
        Positioned(
          right: 65,
          bottom: 20,
          child: _DecorativeBook(
            color: AppColors.secondary,
            width: 42,
            height: 62,
          ),
        ),
      ],
    );
  }
}

/// A decorative 2D book widget.
class _DecorativeBook extends StatelessWidget {
  final Color color;
  final double width;
  final double height;

  const _DecorativeBook({
    required this.color,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: width * 0.6,
            height: 3,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 4),
          Container(
            width: width * 0.4,
            height: 2,
            color: Colors.white.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for bookshelf pattern background.
class _BookshelfPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw horizontal shelf lines
    for (double y = 50; y < size.height; y += 50) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Draw some vertical book dividers
    final bookPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    for (double x = 30; x < size.width; x += 60) {
      final bookHeight = 30.0 + (x % 20);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - bookHeight - 20, 15, bookHeight),
          const Radius.circular(2),
        ),
        bookPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Controller wrapper for Spline interactions.
///
/// Provides methods to interact with the 3D scene programmatically.
class SplineBookshelfController {
  SplineController? _splineController;

  /// Attach the Spline controller.
  void attach(SplineController controller) {
    _splineController = controller;
  }

  /// Detach the Spline controller.
  void detach() {
    _splineController = null;
  }

  /// Trigger an event in the Spline scene.
  ///
  /// Events must be configured in your Spline scene.
  /// Common events: 'mouseDown', 'mouseUp', 'mouseHover'
  void triggerEvent(String eventName, String objectName) {
    _splineController?.emitEvent(eventName, objectName);
  }

  /// Set a variable value in the Spline scene.
  ///
  /// Variables must be defined in your Spline scene.
  void setVariable(String name, dynamic value) {
    _splineController?.setVariable(name, value);
  }

  /// Get the current value of a variable in the Spline scene.
  dynamic getVariable(String name) {
    return _splineController?.getVariable(name);
  }
}

/// Interactive 3D book widget that can be placed individually.
///
/// Use this for displaying a single interactive 3D book.
class SplineBook extends StatelessWidget {
  /// URL to the Spline scene for a single book.
  final String? splineUrl;

  /// Local asset path.
  final String? splineAsset;

  /// Size of the book widget.
  final double size;

  /// Callback when book is tapped.
  final VoidCallback? onTap;

  const SplineBook({
    super.key,
    this.splineUrl,
    this.splineAsset,
    this.size = 120,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size * 1.4,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: AppRadius.borderRadiusMd,
          boxShadow: AppShadows.medium,
        ),
        child: splineUrl != null
            ? SplineWidget.network(splineUrl!)
            : splineAsset != null
                ? SplineWidget.asset(splineAsset!)
                : _buildPlaceholderBook(),
      ),
    );
  }

  Widget _buildPlaceholderBook() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, AppColors.accentDark],
        ),
        borderRadius: AppRadius.borderRadiusMd,
      ),
      child: Center(
        child: Icon(
          Icons.menu_book,
          size: size * 0.4,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }
}
