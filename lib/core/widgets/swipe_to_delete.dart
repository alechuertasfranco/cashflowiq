import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class SwipeToDelete extends StatelessWidget {
  final Widget child;
  final VoidCallback onDelete;
  final bool showConfirmation;

  const SwipeToDelete({
    super.key,
    required this.child,
    required this.onDelete,
    this.showConfirmation = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: AppColors.errorStrong,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
          ),
          Dismissible(
            key: ValueKey(child.hashCode),
            direction: DismissDirection.endToStart,
            background: const SizedBox(),
            confirmDismiss: showConfirmation
                ? (_) => showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: Text("Eliminar movimiento", style: AppTextStyles.h500(ctx)),
                        content: Text(
                          "¿Seguro que deseas eliminar este movimiento? Esta acción no se puede deshacer.",
                          style: AppTextStyles.body1(ctx),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text("Cancelar", style: AppTextStyles.body1(ctx, color: AppColors.muted)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text("Eliminar", style: AppTextStyles.body1(ctx, color: AppColors.error)),
                          ),
                        ],
                      ),
                    )
                : null,
            onDismissed: (_) => onDelete(),
            child: child,
          ),
        ],
      ),
    );
  }
}
