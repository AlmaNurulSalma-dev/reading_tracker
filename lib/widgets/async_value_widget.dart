import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reading_tracker/utils/app_theme.dart';

/// A widget that handles AsyncValue states with consistent loading and error UI.
class AsyncValueWidget<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget Function(Object error, StackTrace stackTrace)? error;
  final Widget? loading;

  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.error,
    this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      error: error ?? _defaultError,
      loading: () => loading ?? _defaultLoading(),
    );
  }

  Widget _defaultError(Object error, StackTrace stackTrace) {
    return ErrorDisplay(
      error: error.toString(),
      onRetry: null,
    );
  }

  Widget _defaultLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

/// Error display widget with retry option.
class ErrorDisplay extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;
  final bool fullScreen;

  const ErrorDisplay({
    super.key,
    required this.error,
    this.onRetry,
    this.fullScreen = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: fullScreen ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          size: fullScreen ? 64 : 48,
          color: AppColors.error,
        ),
        SizedBox(height: fullScreen ? 24 : 16),
        Text(
          'Oops! Something went wrong',
          style: fullScreen
              ? AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                )
              : AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: fullScreen ? 12 : 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            error,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onRetry != null) ...[
          SizedBox(height: fullScreen ? 24 : 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ],
    );

    if (fullScreen) {
      return Center(child: content);
    }
    return content;
  }
}

/// Loading display widget.
class LoadingDisplay extends StatelessWidget {
  final String? message;
  final bool fullScreen;

  const LoadingDisplay({
    super.key,
    this.message,
    this.fullScreen = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: fullScreen ? MainAxisSize.max : MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (fullScreen) {
      return Center(child: content);
    }
    return content;
  }
}

/// Empty state display widget.
class EmptyDisplay extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final bool fullScreen;

  const EmptyDisplay({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.fullScreen = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: fullScreen ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: fullScreen ? 80 : 64,
          color: AppColors.textSecondary.withOpacity(0.5),
        ),
        SizedBox(height: fullScreen ? 24 : 16),
        Text(
          title,
          style: fullScreen
              ? AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                )
              : AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (action != null) ...[
          SizedBox(height: fullScreen ? 24 : 16),
          action!,
        ],
      ],
    );

    if (fullScreen) {
      return Center(child: content);
    }
    return content;
  }
}

/// Shimmer loading placeholder.
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.surface,
                AppColors.surfaceLight,
                AppColors.surface,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// Sliver version of AsyncValueWidget for use in CustomScrollView.
class SliverAsyncValueWidget<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget Function(Object error, StackTrace stackTrace)? error;
  final Widget? loading;

  const SliverAsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.error,
    this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      error: error ??
          (err, stack) => SliverFillRemaining(
                child: ErrorDisplay(
                  error: err.toString(),
                  onRetry: null,
                ),
              ),
      loading: () =>
          loading ??
          const SliverFillRemaining(
            child: LoadingDisplay(),
          ),
    );
  }
}
