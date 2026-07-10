import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/app_dialog.dart';
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
      borderRadius: context.radiusLgRadius,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: context.colorErrorStrong,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
          ),
          Dismissible(
            key: ValueKey(child.hashCode),
            direction: DismissDirection.endToStart,
            background: const SizedBox(),
            confirmDismiss: showConfirmation
                ? (_) => showAppConfirmDialog(
                      context,
                      title: "Eliminar movimiento",
                      message: "¿Seguro que deseas eliminar este movimiento? Esta acción no se puede deshacer.",
                      confirmText: "Eliminar",
                      cancelText: "Cancelar",
                      isDestructive: true,
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
