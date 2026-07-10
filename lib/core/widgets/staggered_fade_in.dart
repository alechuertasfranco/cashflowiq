// lib/core/widgets/staggered_fade_in.dart

import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/app_motion.dart';

/// Wraps [child] with a fade + slight upward slide-in, delayed by
/// `index * staggerMs`. Use to give a list of cards a subtle "arriving"
/// feel on first paint instead of popping in all at once.
class StaggeredFadeIn extends StatefulWidget {
  final int index;
  final Widget child;
  final int staggerMs;

  const StaggeredFadeIn({
    super.key,
    required this.index,
    required this.child,
    this.staggerMs = 40,
  });

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: widget.index * widget.staggerMs);
    Future.delayed(delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: AppMotion.slow,
      curve: AppMotion.emphasized,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.06),
        duration: AppMotion.slow,
        curve: AppMotion.emphasized,
        child: widget.child,
      ),
    );
  }
}
