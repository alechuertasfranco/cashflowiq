import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class SwipeToDelete extends StatelessWidget {
  final Widget child;
  final VoidCallback onDelete;

  const SwipeToDelete({super.key, required this.child, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          /// 🔴 Fondo SIEMPRE presente (debajo)
          Positioned.fill(
            child: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: AppColors.errorStrong,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
          ),

          /// 👆 Item que se desliza
          Dismissible(
            key: ValueKey(child.hashCode),
            direction: DismissDirection.endToStart,
            background: const SizedBox(),
            onDismissed: (_) => onDelete(),
            child: child,
          ),
        ],
      ),
    );
  }
}
