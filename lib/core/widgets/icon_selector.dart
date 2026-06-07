import 'package:flutter/material.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';

typedef OnIconSelected = void Function(IconData? icon);

class IconSelector extends StatefulWidget {
  final IconData? initialIcon;
  final OnIconSelected onSelected;
  final List<IconData>? icons;

  const IconSelector({super.key, this.initialIcon, required this.onSelected, this.icons});

  @override
  State<IconSelector> createState() => _IconSelectorState();
}

class _IconSelectorState extends State<IconSelector> {
  IconData? _selected;

  late final List<IconData> _icons =
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
        Icons.health_and_safety,
        Icons.sports_soccer,
        Icons.credit_card,
        Icons.savings,
        Icons.card_giftcard,
        Icons.receipt_long,
        Icons.flight,
        Icons.casino,
        Icons.restaurant,
        Icons.local_grocery_store,
        Icons.fitness_center,
        Icons.pets,
        Icons.phone_android,
        Icons.movie,
        Icons.music_note,
        Icons.local_gas_station,
      ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initialIcon;
  }

  void _onTap(IconData icon) {
    setState(() => _selected = _selected == icon ? null : icon);
    widget.onSelected(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: _icons.length,
        itemBuilder: (_, i) {
          final icon = _icons[i];
          final isSelected = _selected == icon;
          return GestureDetector(
            onTap: () => _onTap(icon),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withAlpha(20) : AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          );
        },
      ),
    );
  }
}
