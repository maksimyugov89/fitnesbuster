import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingShimmer extends StatelessWidget {
  final double height;
  final double width;
  final double borderRadius;

  const LoadingShimmer({
    super.key,
    this.height = 20,
    this.width = double.infinity,
    this.borderRadius = 8,
  });

  factory LoadingShimmer.listTile({Key? key}) =>
      LoadingShimmer(key: key, height: 64, borderRadius: 12);

  factory LoadingShimmer.card({Key? key}) =>
      LoadingShimmer(key: key, height: 120, borderRadius: 16);

  factory LoadingShimmer.grid({Key? key}) =>
      LoadingShimmer(key: key, height: 100, borderRadius: 12);

  factory LoadingShimmer.graph({Key? key}) =>
      LoadingShimmer(key: key, height: 200, borderRadius: 16);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: 0.06),
      highlightColor: Colors.white.withValues(alpha: 0.12),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  static Widget listView(int count) => ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: count,
    separatorBuilder: (_, _) => const SizedBox(height: 8),
    itemBuilder: (_, _) => LoadingShimmer.listTile(),
  );

  static Widget gridView(int count, {int crossAxisCount = 2}) =>
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.0,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: count,
        itemBuilder: (_, _) => LoadingShimmer.grid(),
      );

  static Widget cards(int count) => Column(
    children: [
      for (int i = 0; i < count; i++) ...[
        LoadingShimmer.card(),
        if (i < count - 1) const SizedBox(height: 12),
      ],
    ],
  );
}
