import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';

typedef OnColorSelected = void Function(Color? color);

class ColorSelector extends StatefulWidget {
  final Color? initialColor;
  final OnColorSelected onSelected;
  final List<Color>? palette;

  const ColorSelector({super.key, this.initialColor, required this.onSelected, this.palette});

  @override
  State<ColorSelector> createState() => _ColorSelectorState();
}

class _ColorSelectorState extends State<ColorSelector> {
  Color? _selected;

  late final List<Color> _palette =
      widget.palette ??
      [
        const Color(0xFF1A6982),
        const Color(0xFF2989C7),
        const Color(0xFF3DC3A2),
        const Color(0xFF22C55E),
        const Color(0xFF00C853),
        const Color(0xFF64DD17),
        const Color(0xFFFFAB00),
        const Color(0xFFFF6D00),
        const Color(0xFFEF4444),
        const Color(0xFFD50000),
        const Color(0xFFF50057),
        const Color(0xFFAA00FF),
        const Color(0xFF9575CD),
        const Color(0xFF455A64),
        const Color(0xFF90A4AE),
        const Color(0xFF4DB6AC),
        const Color(0xFF64B5F6),
        const Color(0xFFFFD54F),
        const Color(0xFFFF8A65),
        const Color(0xFFF06292),
      ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initialColor;
  }

  void _onTap(Color color) {
    setState(() => _selected = _selected == color ? null : color);
    widget.onSelected(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _palette.map((color) {
        final isSelected = _selected == color;
        return GestureDetector(
          onTap: () => _onTap(color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.textPrimary : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: color.withAlpha(100), blurRadius: 6, spreadRadius: 1)]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
