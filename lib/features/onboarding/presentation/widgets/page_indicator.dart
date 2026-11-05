import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class PageIndicator extends StatelessWidget {
  final int count;
  final int current;
  const PageIndicator({super.key, required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.tertiary,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
