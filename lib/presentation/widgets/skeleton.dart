import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';

class SkeletonList extends StatelessWidget {
  final int count;
  const SkeletonList({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: AppColors.card,
        highlightColor: AppColors.card2,
        child: Column(
          children: List.generate(
            count,
            (_) => Container(
              height: 80,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      );
}
