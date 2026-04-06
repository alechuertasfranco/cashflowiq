// lib\core\widgets\color_selector.dart

import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';

typedef OnColorSelected = void Function(Color? color);

class ColorSelector extends StatefulWidget {
  final Color? initialColor;
  final OnColorSelected onSelected;
  final double size;
  final List<Color>? palette;

  const ColorSelector({super.key, this.initialColor, required this.onSelected, this.size = 36, this.palette});

  @override
  State<ColorSelector> createState() => _ColorSelectorState();
}

class _ColorSelectorState extends State<ColorSelector> {
  Color? _selectedColor;
  bool _isOpen = false;

  /// 🎯 Paleta curada (colores realmente distintos)
  late final List<Color> _defaultPalette =
      widget.palette ??
      [
        const Color(0xFF00C853),
        const Color(0xFF2962FF),
        const Color(0xFFD50000),
        const Color(0xFFFF6D00),
        const Color(0xFFAA00FF),
        const Color(0xFF00BFA5),
        const Color(0xFF0091EA),
        const Color(0xFF64DD17),
        const Color(0xFFFF1744),
        const Color(0xFFF50057),
        const Color(0xFF455A64),
        const Color(0xFFFFAB00),
        const Color(0xFF3DC3A2),
        const Color(0xFF2989C7),
        const Color(0xFFE57373),
        const Color(0xFFFFB74D),
        const Color(0xFF9575CD),
        const Color(0xFF4DB6AC),
        const Color(0xFF64B5F6),
        const Color(0xFFAED581),
        const Color(0xFFFF8A65),
        const Color(0xFFF06292),
        const Color(0xFF90A4AE),
        const Color(0xFFFFD54F),
      ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  void _onTap(Color color) {
    setState(() {
      if (_selectedColor == color) {
        _selectedColor = null;
      } else {
        _selectedColor = color;
      }
      _isOpen = false;
    });

    widget.onSelected(_selectedColor);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// 🔽 Trigger (dropdown)
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
                if (_selectedColor != null)
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(color: _selectedColor, borderRadius: BorderRadius.circular(4)),
                  ),
                if (_selectedColor != null) const SizedBox(width: 8),

                Text(
                  _selectedColor != null ? "Color seleccionado" : "Seleccionar color",
                  style: AppTextStyles.subtitle2(context),
                ),

                const Spacer(),
                Icon(_isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),

        /// 🎨 Dropdown content
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
              children: _defaultPalette.map((color) {
                final isSelected = _selectedColor == color;

                return GestureDetector(
                  onTap: () => _onTap(color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
