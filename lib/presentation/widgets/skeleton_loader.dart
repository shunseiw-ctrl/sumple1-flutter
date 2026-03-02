import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_spacing.dart';

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
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
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
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
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: const [
                Color(0xFFEEEFF1),
                Color(0xFFF8F8FA),
                Color(0xFFEEEFF1),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SkeletonJobCard extends StatelessWidget {
  const SkeletonJobCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(height: 160, borderRadius: 16),
          Padding(
            padding: EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SkeletonLoader(width: 60, height: 24, borderRadius: 12),
                    SizedBox(width: 8),
                    SkeletonLoader(width: 60, height: 24, borderRadius: 12),
                  ],
                ),
                SizedBox(height: 12),
                SkeletonLoader(height: 20, borderRadius: 6),
                SizedBox(height: 8),
                SkeletonLoader(width: 200, height: 16, borderRadius: 6),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonLoader(width: 100, height: 28, borderRadius: 8),
                    SkeletonLoader(width: 80, height: 16, borderRadius: 6),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonMessageCard extends StatelessWidget {
  const SkeletonMessageCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: const Row(
        children: [
          SkeletonLoader(width: 48, height: 48, borderRadius: 14),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(height: 16, borderRadius: 6),
                SizedBox(height: 8),
                SkeletonLoader(width: 180, height: 12, borderRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonNotificationCard extends StatelessWidget {
  const SkeletonNotificationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(width: 44, height: 44, borderRadius: 14),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(height: 16, borderRadius: 6),
                SizedBox(height: 8),
                SkeletonLoader(height: 12, borderRadius: 6),
                SizedBox(height: 6),
                SkeletonLoader(width: 80, height: 10, borderRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonWorkCard extends StatelessWidget {
  const SkeletonWorkCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(height: 18, borderRadius: 6),
          SizedBox(height: 8),
          SkeletonLoader(width: 100, height: 24, borderRadius: 12),
        ],
      ),
    );
  }
}

class SkeletonSalesCard extends StatelessWidget {
  const SkeletonSalesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusLg),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SkeletonLoader(width: 100, height: 16, borderRadius: 6),
          SizedBox(height: 12),
          SkeletonLoader(width: 160, height: 32, borderRadius: 8),
          SizedBox(height: 12),
          SkeletonLoader(width: 140, height: 14, borderRadius: 6),
        ],
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context)? itemBuilder;
  const SkeletonList({super.key, this.itemCount = 3, this.itemBuilder});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: AppSpacing.listInsets,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.base),
      itemBuilder: (ctx, __) => itemBuilder?.call(ctx) ?? const SkeletonJobCard(),
    );
  }
}
