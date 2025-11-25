import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:reading_tracker/utils/app_theme.dart';

/// A celebration animation widget shown when reading streak increases.
class StreakCelebrationAnimation extends StatefulWidget {
  final int newStreak;
  final VoidCallback onComplete;

  const StreakCelebrationAnimation({
    super.key,
    required this.newStreak,
    required this.onComplete,
  });

  @override
  State<StreakCelebrationAnimation> createState() =>
      _StreakCelebrationAnimationState();
}

class _StreakCelebrationAnimationState
    extends State<StreakCelebrationAnimation>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Scale animation for the flame emoji
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.elasticOut,
      ),
    );

    // Fade animation for the text
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeIn,
      ),
    );

    // Confetti animation
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Start animations
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _fadeController.forward();
    });
    _confettiController.forward();

    // Auto-dismiss after animation completes
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Stack(
        children: [
          // Confetti particles
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, child) {
              return CustomPaint(
                painter: ConfettiPainter(_confettiController.value),
                size: Size.infinite,
              );
            },
          ),

          // Main celebration content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Flame emoji with scale animation
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Text(
                      '🔥',
                      style: TextStyle(fontSize: 80),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Streak text with fade animation
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        'Streak Increased!',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.newStreak} ${widget.newStreak == 1 ? 'Day' : 'Days'}',
                        style: AppTextStyles.displaySmall.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getStreakMessage(widget.newStreak),
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStreakMessage(int streak) {
    if (streak == 1) return 'Great start! 🌟';
    if (streak == 3) return 'Building momentum! 💪';
    if (streak == 7) return 'One week strong! 🎉';
    if (streak == 14) return 'Two weeks! Amazing! ⚡';
    if (streak == 30) return 'One month! Incredible! 🏆';
    if (streak == 100) return 'Century club! Legendary! 👑';
    return 'Keep it up! 🚀';
  }
}

/// Custom painter for confetti particles.
class ConfettiPainter extends CustomPainter {
  final double progress;
  final List<ConfettiParticle> particles;

  ConfettiPainter(this.progress) : particles = _generateParticles();

  static List<ConfettiParticle> _generateParticles() {
    final random = math.Random(42); // Fixed seed for consistency
    return List.generate(50, (index) {
      return ConfettiParticle(
        color: _colors[random.nextInt(_colors.length)],
        startX: 0.5 + (random.nextDouble() - 0.5) * 0.2,
        startY: 0.4,
        endX: random.nextDouble(),
        endY: random.nextDouble() * 0.6 + 0.4,
        rotation: random.nextDouble() * math.pi * 4,
        size: random.nextDouble() * 8 + 4,
      );
    });
  }

  static const _colors = [
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFFFFE66D),
    Color(0xFF95E1D3),
    Color(0xFFF38181),
    Color(0xFFAA96DA),
    Color(0xFFFCBAD3),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(1.0 - progress)
        ..style = PaintingStyle.fill;

      final x = size.width * (particle.startX + (particle.endX - particle.startX) * progress);
      final y = size.height * (particle.startY + (particle.endY - particle.startY) * progress);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation * progress);

      // Draw confetti as small rectangles
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: particle.size,
        height: particle.size * 0.6,
      );
      canvas.drawRect(rect, paint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class ConfettiParticle {
  final Color color;
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double rotation;
  final double size;

  ConfettiParticle({
    required this.color,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.rotation,
    required this.size,
  });
}

/// A simpler streak badge widget that can be used inline.
class StreakBadge extends StatelessWidget {
  final int streak;
  final bool animate;

  const StreakBadge({
    super.key,
    required this.streak,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent,
            AppColors.accent.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🔥',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 6),
          Text(
            '$streak',
            style: AppTextStyles.titleSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    if (animate) {
      return TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 400),
        tween: Tween(begin: 0.8, end: 1.0),
        curve: Curves.elasticOut,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: badge,
      );
    }

    return badge;
  }
}

/// Widget showing streak with progress to next milestone.
class StreakProgressIndicator extends StatelessWidget {
  final int currentStreak;
  final int nextMilestone;
  final String milestoneLabel;

  const StreakProgressIndicator({
    super.key,
    required this.currentStreak,
    required this.nextMilestone,
    required this.milestoneLabel,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentStreak / nextMilestone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Next: $milestoneLabel',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${nextMilestone - currentStreak} days to go',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: AppColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
