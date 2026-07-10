// lib/features/splits/screens/widgets/split_step_participants.dart

import 'package:cashflowiq/core/theme/theme_extensions.dart';
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
          Text("¿Quiénes participan?", style: context.heading4()),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  "Modo de división",
                  style: context.textSubtitle2(color: context.colorTextSecondary),
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
            icon: Icon(Icons.person_add_alt_1, color: context.colorPrimary),
            label: Text(
              "Agregar participante",
              style: context.textBody1(color: context.colorPrimary),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: context.colorPrimary),
              shape: RoundedRectangleBorder(borderRadius: context.radiusMdRadius),
            ),
          ),
          if (participants.isEmpty) ...[
            const SizedBox(height: 12),
            Text(
              "Agrega al menos un participante para dividir el gasto",
              style: context.textBody2(color: context.colorMuted),
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
        duration: context.motionFast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: includeSelf ? context.colorPrimary.withAlpha(20) : context.colorSurface,
          borderRadius: context.radiusMdRadius,
          border: Border.all(
            color: includeSelf ? context.colorPrimary : context.colorBorder,
            width: includeSelf ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            AnimatedContainer(
              duration: context.motionFast,
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: includeSelf ? context.colorPrimary : context.colorSecondary,
                borderRadius: context.radiusSmRadius,
              ),
              child: Icon(
                Icons.person,
                size: 18,
                color: includeSelf ? context.colorOnPrimary : context.colorPrimary,
              ),
            ),
            const SizedBox(width: 10),

            // Label
            Expanded(
              child: Text('Yo también pago', style: context.textSubtitle2()),
            ),

            // Amount + state indicator
            if (includeSelf) ...[
              Text(
                selfShare.toStringAsFixed(2),
                style: context.textBody1(color: context.colorPrimary),
              ),
              const SizedBox(width: 8),
              Icon(Icons.check_circle, color: context.colorPrimary, size: 20),
            ] else
              Icon(Icons.add_circle_outline, color: context.colorMuted, size: 20),
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
        color: context.colorSurface,
        borderRadius: context.radiusSmRadius,
        border: Border.all(color: context.colorBorder),
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
        duration: context.motionFast,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? context.colorPrimary : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isLeft ? Radius.circular(context.radiusSm - 1) : Radius.zero,
            right: !isLeft ? Radius.circular(context.radiusSm - 1) : Radius.zero,
          ),
        ),
        child: Text(
          label,
          style: context.textCaption(
              color: active ? context.colorOnPrimary : context.colorTextSecondary),
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
          color: context.colorSurface,
          borderRadius: context.radiusMdRadius,
          border: Border.all(color: context.colorBorder),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.colorSecondary,
                borderRadius: context.radiusSmRadius,
              ),
              child: Center(
                child: Text(
                  participant.contact.name.isNotEmpty
                      ? participant.contact.name[0].toUpperCase()
                      : '?',
                  style: context.textBody2(color: context.colorPrimary),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Name
            Expanded(
              child: Text(
                participant.contact.name,
                style: context.textSubtitle2(),
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
                  hintStyle: context.textCaption(color: context.colorMuted),
                  filled: true,
                  fillColor: isCustom ? context.colorSurface : context.colorSurfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: context.radiusSmRadius,
                    borderSide: BorderSide(color: context.colorBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: context.radiusSmRadius,
                    borderSide: BorderSide(color: context.colorBorder),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: context.radiusSmRadius,
                    borderSide: BorderSide(color: context.colorBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: context.radiusSmRadius,
                    borderSide: BorderSide(color: context.colorPrimary),
                  ),
                ),
                style: context.textBody1(),
              ),
            ),
            const SizedBox(width: 4),

            // Remove
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close, size: 18, color: context.colorMuted),
            ),
          ],
        ),
      ),
    );
  }
}
