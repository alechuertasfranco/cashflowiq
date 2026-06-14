// lib/features/transactions/presentation/expense_transaction/widgets/sub_step_switcher.dart

import 'package:flutter/material.dart';

/// Wraps [child] in an [AnimatedSwitcher] that slides horizontally between
/// sub-views. Change [viewKey] to trigger the animation; set [goingForward]
/// to control the slide direction (true = new slides in from right).
class SubStepSwitcher extends StatelessWidget {
  final Widget child;
  final String viewKey;
  final bool goingForward;

  const SubStepSwitcher({
    super.key,
    required this.child,
    required this.viewKey,
    required this.goingForward,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        layoutBuilder: (currentChild, previousChildren) => Stack(
          alignment: Alignment.topLeft,
          children: [
            ...previousChildren,
            ?currentChild,
          ],
        ),
        transitionBuilder: (widget, animation) {
          // Flutter gives: entering child 0→1, leaving child 1→0.
          // We use the key to tell them apart and reverse the leaving tween.
          final isEntering = widget.key == ValueKey(viewKey);
          return SlideTransition(
            position: isEntering
                ? Tween<Offset>(
                    begin: Offset(goingForward ? 1.0 : -1.0, 0),
                    end: Offset.zero,
                  ).animate(animation)
                : Tween<Offset>(
                    begin: Offset.zero,
                    end: Offset(goingForward ? -1.0 : 1.0, 0),
                  ).animate(ReverseAnimation(animation)),
            child: widget,
          );
        },
        child: SizedBox(
          key: ValueKey(viewKey),
          width: double.infinity,
          child: child,
        ),
      ),
    );
  }
}
