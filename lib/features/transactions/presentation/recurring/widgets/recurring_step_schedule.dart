// lib/features/transactions/presentation/recurring/widgets/recurring_step_schedule.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/decorations.dart';
import 'package:cashflowiq/shared/models/recurring_transaction.dart';
import 'package:flutter/material.dart';

class RecurringStepSchedule extends StatelessWidget {
  final RecurringFrequency frequency;
  final int? notificationDaysBefore;
  final DateTime nextExecutionDate;
  final DateTime? endDate;
  final bool isFixedAmount;
  final void Function(RecurringFrequency) onFrequencyChanged;
  final void Function(int?) onNotificationChanged;
  final VoidCallback onPickNextDate;
  final VoidCallback onPickEndDate;
  final VoidCallback onClearEndDate;

  const RecurringStepSchedule({
    super.key,
    required this.frequency,
    required this.notificationDaysBefore,
    required this.nextExecutionDate,
    this.endDate,
    required this.isFixedAmount,
    required this.onFrequencyChanged,
    required this.onNotificationChanged,
    required this.onPickNextDate,
    required this.onPickEndDate,
    required this.onClearEndDate,
  });

  String _formatDate(DateTime date) =>
      "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Frequency
          _label(context, "Frecuencia"),
          const SizedBox(height: 8),
          DropdownButtonFormField<RecurringFrequency>(
            initialValue: frequency,
            items: RecurringFrequency.values.map((f) {
              return DropdownMenuItem<RecurringFrequency>(
                value: f,
                child: Text(f.toLabel(), style: AppTextStyles.body1(context)),
              );
            }).toList(),
            onChanged: (f) {
              if (f != null) onFrequencyChanged(f);
            },
            decoration: inputDecoration(context, "Frecuencia"),
          ),
          const SizedBox(height: 20),

          // Notification reminder
          _label(context, "Recordatorio"),
          const SizedBox(height: 8),
          DropdownButtonFormField<int?>(
            initialValue: notificationDaysBefore,
            items: const [
              DropdownMenuItem<int?>(value: null, child: Text("Sin recordatorio")),
              DropdownMenuItem<int?>(value: 0, child: Text("El mismo día")),
              DropdownMenuItem<int?>(value: 1, child: Text("1 día antes")),
              DropdownMenuItem<int?>(value: 3, child: Text("3 días antes")),
              DropdownMenuItem<int?>(value: 7, child: Text("7 días antes")),
            ],
            onChanged: onNotificationChanged,
            decoration: inputDecoration(context, "Sin recordatorio"),
          ),
          const SizedBox(height: 10),
          _NotificationInfoBox(
            notificationDaysBefore: notificationDaysBefore,
            isFixedAmount: isFixedAmount,
          ),
          const SizedBox(height: 20),

          // Next execution date
          _label(context, "Primera ejecución"),
          const SizedBox(height: 8),
          _datePicker(
            context: context,
            icon: Icons.event,
            label: _formatDate(nextExecutionDate),
            onTap: onPickNextDate,
          ),
          const SizedBox(height: 20),

          // End date
          _label(context, "Fecha de fin (opcional)"),
          const SizedBox(height: 8),
          _datePicker(
            context: context,
            icon: Icons.event_busy,
            label: endDate != null ? _formatDate(endDate!) : "Sin fecha de fin",
            labelColor: endDate != null ? null : AppColors.muted,
            onTap: onPickEndDate,
            trailing: endDate != null
                ? GestureDetector(
                    onTap: onClearEndDate,
                    child: const Icon(Icons.close, size: 16, color: AppColors.muted),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) =>
      Text(text, style: AppTextStyles.subtitle2(context, color: AppColors.textSecondary));

  Widget _datePicker({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? labelColor,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.muted),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.subtitle2(context, color: labelColor ?? AppColors.textPrimary),
            ),
            const Spacer(),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

// ── Notification info box ────────────────────────────────────────────────────

class _NotificationInfoBox extends StatelessWidget {
  final int? notificationDaysBefore;
  final bool isFixedAmount;

  const _NotificationInfoBox({
    required this.notificationDaysBefore,
    required this.isFixedAmount,
  });

  String get _message {
    if (notificationDaysBefore == null) {
      return 'Sin recordatorio: la transacción se creará automáticamente en la fecha de ejecución, sin necesidad de acción.';
    }
    final when = switch (notificationDaysBefore) {
      0 => 'el mismo día de la ejecución',
      1 => '1 día antes',
      _ => '$notificationDaysBefore días antes',
    };
    if (isFixedAmount) {
      return 'Recibirás una notificación $when. Al tocarla, la transacción se registrará automáticamente.';
    } else {
      return 'Recibirás una notificación $when para ingresar el monto manualmente.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 15, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_message,
                style: AppTextStyles.caption(context, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
