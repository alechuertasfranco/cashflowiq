import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

Color parseHexColor(String? hex) {
  if (hex == null || hex.isEmpty) return AppColors.secondary;

  final buffer = StringBuffer();
  if (hex.length == 6 || hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}
