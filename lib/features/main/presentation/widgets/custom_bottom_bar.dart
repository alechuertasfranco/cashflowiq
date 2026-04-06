import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';

class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomBar({super.key, required this.currentIndex, required this.onTap});

  static const _duration = Duration(milliseconds: 250);
  static const _curve = Curves.easeInOutCubic;

  double _t(double i, double current) => (1 - (current - i).abs()).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: currentIndex.toDouble()),
        duration: _duration,
        curve: _curve,
        builder: (context, animatedIndex, _) {
          return Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Column(
              children: [
                _TopIndicator(animatedIndex),
                Expanded(
                  child: Row(
                    children: List.generate(5, (i) {
                      if (i == 2) {
                        return _AddButton(t: _t(2, animatedIndex), onTap: () => onTap(2));
                      }

                      final icons = [
                        [Icons.home_outlined, Icons.home_rounded],
                        [Icons.show_chart_outlined, Icons.show_chart_rounded],
                        null,
                        [Icons.bar_chart_outlined, Icons.bar_chart_rounded],
                        [Icons.person_outline_rounded, Icons.person_rounded],
                      ];

                      final pair = icons[i]!;

                      return _NavItem(
                        t: _t(i.toDouble(), animatedIndex),
                        icon: pair[0],
                        activeIcon: pair[1],
                        onTap: () => onTap(i),
                      );
                    }),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TopIndicator extends StatelessWidget {
  final double index;

  const _TopIndicator(this.index);

  @override
  Widget build(BuildContext context) {
    final hide = (index - 2).abs() < 0.01;

    return LayoutBuilder(
      builder: (_, c) {
        final width = c.maxWidth / 5;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: hide ? 0 : 1,
          child: Align(
            alignment: Alignment(-1 + index * 0.5, 0),
            child: Container(
              width: width,
              height: 2.5,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final double t;
  final IconData icon;
  final IconData activeIcon;
  final VoidCallback onTap;

  const _NavItem({required this.t, required this.icon, required this.activeIcon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: SizedBox.expand(
          child: Center(
            child: Transform.translate(
              offset: Offset(0, lerpDouble(0, -4, t)!),
              child: Icon(
                t > 0.5 ? activeIcon : icon,
                color: Color.lerp(AppColors.muted, AppColors.primary, t),
                size: lerpDouble(24, 26, t),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final double t;
  final VoidCallback onTap;

  const _AddButton({required this.t, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Center(
          child: Transform.translate(
            offset: const Offset(0, -15),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.lerp(BorderRadius.circular(100), BorderRadius.circular(16), t),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withAlpha(70), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: Transform.rotate(
                angle: lerpDouble(0, 0.25, t)! * 2 * 3.1416,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
