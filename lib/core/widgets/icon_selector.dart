import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';

typedef OnIconSelected = void Function(IconData? icon);

class IconSelector extends StatefulWidget {
  final IconData? initialIcon;
  final OnIconSelected onSelected;
  final double size;
  final List<IconData>? icons;

  const IconSelector({super.key, this.initialIcon, required this.onSelected, this.size = 36, this.icons});

  @override
  State<IconSelector> createState() => _IconSelectorState();
}

class _IconSelectorState extends State<IconSelector> {
  IconData? _selectedIcon;
  bool _isOpen = false;

  /// 🎯 Íconos curados (finanzas + uso común)
  late final List<IconData> _defaultIcons =
      widget.icons ??
      [
        Icons.attach_money,
        Icons.work,
        Icons.shopping_cart,
        Icons.fastfood,
        Icons.sports_bar,
        Icons.directions_car,
        Icons.home,
        Icons.school,
        Icons.sports_soccer,
        Icons.credit_card,
        Icons.casino,
        Icons.savings,
        Icons.card_giftcard,
        Icons.receipt_long,
        Icons.health_and_safety,
        Icons.flight,
      ];

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.initialIcon;
  }

  void _onTap(IconData icon) {
    setState(() {
      if (_selectedIcon == icon) {
        _selectedIcon = null;
      } else {
        _selectedIcon = icon;
      }
      _isOpen = false;
    });

    widget.onSelected(_selectedIcon);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// 🔽 Trigger
        GestureDetector(
          onTap: () => setState(() => _isOpen = !_isOpen),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                if (_selectedIcon != null) Icon(_selectedIcon, size: 18, color: AppColors.textPrimary),

                if (_selectedIcon != null) const SizedBox(width: 8),

                Text(
                  _selectedIcon != null ? "Ícono seleccionado" : "Seleccionar ícono",
                  style: _selectedIcon != null ? AppTextStyles.body1(context) : AppTextStyles.subtitle2(context),
                ),

                const Spacer(),
                Icon(_isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),

        /// 📦 Dropdown
        if (_isOpen)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _defaultIcons.map((icon) {
                final isSelected = _selectedIcon == icon;

                return GestureDetector(
                  onTap: () => _onTap(icon),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withAlpha(15) : AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Icon(icon, size: 18, color: isSelected ? AppColors.primary : AppColors.textPrimary),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
