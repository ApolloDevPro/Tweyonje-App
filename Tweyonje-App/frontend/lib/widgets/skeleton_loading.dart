import 'package:flutter/material.dart';
import '../core/theme/theme.dart';

class SkeletonLoader extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.sm),
      ),
      child: _ShimmerAnimation(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.background,
                AppColors.background.withAlpha(128),
                AppColors.background,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
    );
  }
}

class _ShimmerAnimation extends StatefulWidget {
  final Widget child;

  const _ShimmerAnimation({required this.child});

  @override
  State<_ShimmerAnimation> createState() => _ShimmerAnimationState();
}

class _ShimmerAnimationState extends State<_ShimmerAnimation>
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

    _animation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
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
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                Colors.white.withAlpha(51),
                Colors.transparent,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonLoader(
                height: 48,
                width: 48,
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonLoader(height: 16, width: 120),
                    const SizedBox(height: 8),
                    const SkeletonLoader(height: 14, width: 80),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const SkeletonLoader(height: 14, width: double.infinity),
          const SizedBox(height: 8),
          const SkeletonLoader(height: 14, width: double.infinity),
          const SizedBox(height: 8),
          const SkeletonLoader(height: 14, width: 150),
        ],
      ),
    );
  }
}

class ListSkeleton extends StatelessWidget {
  final int itemCount;

  const ListSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: const CardSkeleton(),
        );
      },
    );
  }
}

class MetricTileSkeleton extends StatelessWidget {
  const MetricTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(height: 24, width: 24),
          const SizedBox(height: AppSpacing.md),
          const SkeletonLoader(height: 28, width: 80),
          const SizedBox(height: 4),
          const SkeletonLoader(height: 14, width: 60),
        ],
      ),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero section skeleton
        Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        
        // Stats grid skeleton
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.5,
          children: const [
            MetricTileSkeleton(),
            MetricTileSkeleton(),
            MetricTileSkeleton(),
            MetricTileSkeleton(),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        
        // List skeleton
        const ListSkeleton(itemCount: 3),
      ],
    );
  }
}

class UserTileSkeleton extends StatelessWidget {
  const UserTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SkeletonLoader(
            height: 44,
            width: 44,
            borderRadius: BorderRadius.all(Radius.circular(22)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoader(height: 16, width: 100),
                const SizedBox(height: 6),
                const SkeletonLoader(height: 14, width: 140),
              ],
            ),
          ),
          const SkeletonLoader(height: 24, width: 60),
        ],
      ),
    );
  }
}

class FormSkeleton extends StatelessWidget {
  const FormSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonLoader(height: 16, width: 80),
        const SizedBox(height: AppSpacing.sm),
        const SkeletonLoader(height: 48, width: double.infinity),
        const SizedBox(height: AppSpacing.lg),
        const SkeletonLoader(height: 16, width: 80),
        const SizedBox(height: AppSpacing.sm),
        const SkeletonLoader(height: 48, width: double.infinity),
        const SizedBox(height: AppSpacing.lg),
        const SkeletonLoader(height: 16, width: 80),
        const SizedBox(height: AppSpacing.sm),
        const SkeletonLoader(height: 48, width: double.infinity),
        const SizedBox(height: AppSpacing.xl),
        const SkeletonLoader(height: 48, width: double.infinity),
      ],
    );
  }
}
