import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class PageDots extends StatelessWidget {
  final int count;
  final int current;

  const PageDots({super.key, required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        return AnimatedContainer(
          duration: context.motionBase,
          curve: context.motionStandard,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: i == current ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: i == current ? context.colorPrimary : context.colorBorder,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
