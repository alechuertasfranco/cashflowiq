// lib\core\widgets\color_selector.dart

import 'package:flutter/material.dart';

typedef OnColorSelected = void Function(Color? color);

class ColorSelector extends StatefulWidget {
  final Color? initialColor;
  final OnColorSelected onSelected;
  final double size; // tamaño de cada opción
  final List<Color>? palette; // paleta personalizada

  const ColorSelector({super.key, this.initialColor, required this.onSelected, this.size = 40, this.palette});

  @override
  State<ColorSelector> createState() => _ColorSelectorState();
}

class _ColorSelectorState extends State<ColorSelector> {
  Color? _selectedColor;

  /// 🎨 Paleta por defecto de 32 colores
  late final List<Color> _defaultPalette = List<Color>.generate(32, (index) {
    final hue = (index * 360 / 32) % 360;
    return HSLColor.fromAHSL(1, hue, 0.6, 0.5).toColor();
  });

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  void _onTap(Color color) {
    setState(() {
      // Si el color ya estaba seleccionado, quitar la selección
      if (_selectedColor == color) {
        _selectedColor = null;
      } else {
        _selectedColor = color;
      }
    });

    widget.onSelected(_selectedColor);
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette ?? _defaultPalette;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: palette.map((color) {
        final isSelected = _selectedColor == color;

        return GestureDetector(
          onTap: () => _onTap(color),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isSelected ? Colors.black : Colors.grey.shade300, width: isSelected ? 2 : 1),
            ),
            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
          ),
        );
      }).toList(),
    );
  }
}
