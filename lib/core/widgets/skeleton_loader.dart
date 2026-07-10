// lib/core/widgets/skeleton_loader.dart

import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/theme_extensions.dart';

/// A single shimmering placeholder block, for loading states that have a
/// known shape (a list row, a card) — replaces a bare `CircularProgressIndicator`.
class SkeletonBox extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const SkeletonBox({super.key, required this.height, this.width, this.borderRadius});

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.colorSurfaceVariant;
    final highlight = context.colorBorder;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? context.radiusMdRadius,
            gradient: LinearGradient(
              begin: Alignment(-1 + 3 * t, 0),
              end: Alignment(0 + 3 * t, 0),
              colors: [base, highlight, base],
            ),
          ),
        );
      },
    );
  }
}

/// A stack of skeleton rows shaped like a list of cards — drop-in
/// replacement for `Center(child: CircularProgressIndicator())` on
/// list/dashboard screens.
class SkeletonListLoader extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry padding;

  const SkeletonListLoader({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 72,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: List.generate(itemCount, (i) {
          return Padding(
            padding: EdgeInsets.only(bottom: i == itemCount - 1 ? 0 : 12),
            child: SkeletonBox(height: itemHeight, borderRadius: context.radiusLgRadius),
          );
        }),
      ),
    );
  }
}
