import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';

/// Applies the shimmer sweep to placeholder shapes underneath it.
class Shimmering extends StatelessWidget {
  const Shimmering({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Shimmer.fromColors(
      baseColor: p.shimmerBase,
      highlightColor: p.shimmerHighlight,
      period: const Duration(milliseconds: 1300),
      child: child,
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height = 14, this.radius = 8, this.circle = false});

  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: circle ? height : width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}

/// Card-shaped placeholder of a given height.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.height = 120, this.margin = const EdgeInsets.only(bottom: Gaps.m)});

  final double height;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: margin, child: SkeletonBox(height: height, radius: 18));
  }
}

/// Placeholder for an avatar/icon + two lines + trailing control row.
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key, this.leadingSize = 40, this.trailing = true});

  final double leadingSize;
  final bool trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gaps.l, vertical: Gaps.m),
      child: Row(
        children: [
          SkeletonBox(height: leadingSize, radius: 12),
          const SizedBox(width: Gaps.m),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 150, height: 13),
                SizedBox(height: 8),
                SkeletonBox(width: 90, height: 10),
              ],
            ),
          ),
          if (trailing) const SkeletonBox(height: 24, circle: true),
        ],
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 7, this.padding = const EdgeInsets.all(Gaps.l), this.header});

  final int count;
  final EdgeInsets padding;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return Shimmering(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        children: [
          ?header,
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
            child: Column(children: [for (var i = 0; i < count; i++) const SkeletonListTile()]),
          ),
        ],
      ),
    );
  }
}

class SkeletonGrid extends StatelessWidget {
  const SkeletonGrid({super.key, this.count = 6, this.aspectRatio = 0.82});

  final int count;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return Shimmering(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(Gaps.l),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 260,
          mainAxisSpacing: Gaps.m,
          crossAxisSpacing: Gaps.m,
          childAspectRatio: aspectRatio,
        ),
        itemCount: count,
        itemBuilder: (_, _) => const SkeletonBox(height: double.infinity, radius: 18),
      ),
    );
  }
}

/// Generic page placeholder: a header card followed by list rows.
class SkeletonPage extends StatelessWidget {
  const SkeletonPage({super.key, this.headerHeight = 140, this.cards = 1, this.rows = 5});

  final double headerHeight;
  final int cards;
  final int rows;

  @override
  Widget build(BuildContext context) {
    return Shimmering(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(Gaps.l),
        children: [
          for (var i = 0; i < cards; i++) SkeletonCard(height: headerHeight),
          for (var i = 0; i < rows; i++) const SkeletonListTile(),
        ],
      ),
    );
  }
}
