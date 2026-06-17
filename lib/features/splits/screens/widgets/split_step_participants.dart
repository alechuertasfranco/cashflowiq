// lib/features/splits/screens/widgets/split_step_participants.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/shared/models/contact.dart';
import 'package:flutter/material.dart';

/// A participant entry: a contact + an amount controller.
class SplitParticipant {
  final Contact contact;
  final TextEditingController amountController;

  SplitParticipant({required this.contact})
      : amountController = TextEditingController();

  void dispose() => amountController.dispose();
}

class SplitStepParticipants extends StatelessWidget {
  final List<SplitParticipant> participants;
  final bool equalSplit;
  final VoidCallback onAddParticipant;
  final void Function(int index) onRemove;
  final void Function(bool) onSplitModeChanged;

  /// Lets the payer count as one more share of the cost. It never produces
  /// a split of its own — it only affects how the total is divided.
  final bool includeSelf;
  final double selfShare;
  final void Function(bool) onIncludeSelfChanged;

  const SplitStepParticipants({
    super.key,
    required this.participants,
    required this.equalSplit,
    required this.onAddParticipant,
    required this.onRemove,
    required this.onSplitModeChanged,
    required this.includeSelf,
    required this.selfShare,
    required this.onIncludeSelfChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("¿Quiénes participan?", style: AppTextStyles.h400(context)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  "Modo de división",
                  style: AppTextStyles.subtitle2(context, color: AppColors.textSecondary),
                ),
              ),
              _SplitModeToggle(
                isEqual: equalSplit,
                onChanged: onSplitModeChanged,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _IncludeSelfRow(
            includeSelf: includeSelf,
            selfShare: selfShare,
            onChanged: onIncludeSelfChanged,
          ),
          const SizedBox(height: 12),
          ...participants.asMap().entries.map((entry) {
            final index = entry.key;
            final p = entry.value;
            return _SplitParticipantRow(
              participant: p,
              isCustom: !equalSplit,
              onRemove: () => onRemove(index),
            );
          }),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onAddParticipant,
            icon: const Icon(Icons.person_add_alt_1, color: AppColors.primary),
            label: Text(
              "Agregar participante",
              style: AppTextStyles.body1(context, color: AppColors.primary),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (participants.isEmpty) ...[
            const SizedBox(height: 12),
            Text(
              "Agrega al menos un participante para dividir el gasto",
              style: AppTextStyles.body2(context, color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Include self row ──────────────────────────────────────────────────────────

class _IncludeSelfRow extends StatelessWidget {
  final bool includeSelf;
  final double selfShare;
  final void Function(bool) onChanged;

  const _IncludeSelfRow({
    required this.includeSelf,
    required this.selfShare,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!includeSelf),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: includeSelf ? AppColors.primary.withAlpha(20) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: includeSelf ? AppColors.primary : AppColors.border,
            width: includeSelf ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: includeSelf ? AppColors.primary : AppColors.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.person,
                size: 18,
                color: includeSelf ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),

            // Label
            Expanded(
              child: Text('Yo también pago', style: AppTextStyles.subtitle2(context)),
            ),

            // Amount + state indicator
            if (includeSelf) ...[
              Text(
                selfShare.toStringAsFixed(2),
                style: AppTextStyles.body1(context, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
            ] else
              const Icon(Icons.add_circle_outline, color: AppColors.muted, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Split mode toggle ─────────────────────────────────────────────────────────

class _SplitModeToggle extends StatelessWidget {
  final bool isEqual;
  final ValueChanged<bool> onChanged;

  const _SplitModeToggle({required this.isEqual, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleChip(
            label: 'Igual',
            active: isEqual,
            isLeft: true,
            onTap: () => onChanged(true),
          ),
          _ToggleChip(
            label: 'Personalizado',
            active: !isEqual,
            isLeft: false,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool active;
  final bool isLeft;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.active,
    required this.isLeft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isLeft ? const Radius.circular(7) : Radius.zero,
            right: !isLeft ? const Radius.circular(7) : Radius.zero,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption(context,
              color: active ? Colors.white : AppColors.textSecondary),
        ),
      ),
    );
  }
}

// ── Participant row ───────────────────────────────────────────────────────────

class _SplitParticipantRow extends StatelessWidget {
  final SplitParticipant participant;
  final bool isCustom;
  final VoidCallback onRemove;

  const _SplitParticipantRow({
    required this.participant,
    required this.isCustom,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  participant.contact.name.isNotEmpty
                      ? participant.contact.name[0].toUpperCase()
                      : '?',
                  style: AppTextStyles.body2(context, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Name
            Expanded(
              child: Text(
                participant.contact.name,
                style: AppTextStyles.subtitle2(context),
              ),
            ),

            // Amount field (always shown, readonly when equal mode)
            SizedBox(
              width: 90,
              child: TextFormField(
                controller: participant.amountController,
                enabled: isCustom,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                  hintText: '0.00',
                  hintStyle: AppTextStyles.caption(context, color: AppColors.muted),
                  filled: true,
                  fillColor: isCustom ? AppColors.surface : AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
                style: AppTextStyles.body1(context),
              ),
            ),
            const SizedBox(width: 4),

            // Remove
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close, size: 18, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
