import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class ShimmerLoading extends StatefulWidget {
  final Widget child;

  const ShimmerLoading({super.key, required this.child});

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
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFE4E4E7),
                Color(0xFFF4F4F5),
                Color(0xFFE4E4E7),
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((s) => s.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.zinc200,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Shimmer placeholder for dashboard
class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance card shimmer
            const ShimmerBox(width: double.infinity, height: 140, radius: 8),
            const SizedBox(height: 12),
            // Stat cards row
            Row(
              children: const [
                Expanded(child: ShimmerBox(width: double.infinity, height: 64, radius: 8)),
                SizedBox(width: 8),
                Expanded(child: ShimmerBox(width: double.infinity, height: 64, radius: 8)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: const [
                Expanded(child: ShimmerBox(width: double.infinity, height: 64, radius: 8)),
                SizedBox(width: 8),
                Expanded(child: ShimmerBox(width: double.infinity, height: 64, radius: 8)),
              ],
            ),
            const SizedBox(height: 20),
            // Chart shimmer
            const ShimmerBox(width: double.infinity, height: 180, radius: 8),
            const SizedBox(height: 20),
            // Transaction list shimmer
            const ShimmerBox(width: 140, height: 16),
            const SizedBox(height: 12),
            ...List.generate(5, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: const [
                  ShimmerBox(width: 36, height: 36),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 120, height: 12),
                        SizedBox(height: 4),
                        ShimmerBox(width: 80, height: 10),
                      ],
                    ),
                  ),
                  ShimmerBox(width: 60, height: 14),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholder for list screens
class ListShimmer extends StatelessWidget {
  final int itemCount;
  const ListShimmer({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(itemCount, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: const [
                ShimmerBox(width: 40, height: 40, radius: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 140, height: 13),
                      SizedBox(height: 6),
                      ShimmerBox(width: 90, height: 10),
                    ],
                  ),
                ),
                ShimmerBox(width: 50, height: 14),
              ],
            ),
          )),
        ),
      ),
    );
  }
}
