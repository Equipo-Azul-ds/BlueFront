import 'package:flutter/material.dart';

/// A shimmer effect widget for loading placeholders.
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 + _controller.value * 3, 0),
              end: Alignment(1.0 + _controller.value * 3, 0),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A skeleton placeholder for report cards in the list.
class ReportCardSkeleton extends StatelessWidget {
  const ReportCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tags row
            Row(
              children: [
                _SkeletonBox(width: 80, height: 28, borderRadius: 12),
                const SizedBox(width: 8),
                _SkeletonBox(width: 90, height: 28, borderRadius: 12),
              ],
            ),
            const SizedBox(height: 12),
            // Title
            _SkeletonBox(width: double.infinity, height: 20, borderRadius: 8),
            const SizedBox(height: 8),
            _SkeletonBox(width: 150, height: 16, borderRadius: 6),
          ],
        ),
      ),
    );
  }
}

/// A skeleton placeholder for personal result detail.
class PersonalResultSkeleton extends StatelessWidget {
  const PersonalResultSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ShimmerLoading(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _SkeletonBox(width: 100, height: 28, borderRadius: 12),
                      const SizedBox(width: 8),
                      _SkeletonBox(width: 80, height: 28, borderRadius: 12),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SkeletonBox(width: 200, height: 24, borderRadius: 8),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _SkeletonBox(height: 80, borderRadius: 12),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SkeletonBox(height: 80, borderRadius: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SkeletonBox(width: 160, height: 20, borderRadius: 8),
            const SizedBox(height: 12),
            // Question skeletons
            for (int i = 0; i < 5; i++) ...[
              _QuestionSkeleton(),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuestionSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SkeletonBox(width: 24, height: 24, borderRadius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: _SkeletonBox(height: 18, borderRadius: 6),
              ),
              const SizedBox(width: 8),
              _SkeletonBox(width: 70, height: 24, borderRadius: 8),
            ],
          ),
          const SizedBox(height: 10),
          _SkeletonBox(width: 100, height: 14, borderRadius: 4),
          const SizedBox(height: 6),
          Row(
            children: [
              _SkeletonBox(width: 80, height: 28, borderRadius: 8),
              const SizedBox(width: 6),
              _SkeletonBox(width: 60, height: 28, borderRadius: 8),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
