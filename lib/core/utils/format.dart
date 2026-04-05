import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

Color parseHexColor(String? hex) {
  if (hex == null || hex.isEmpty) return AppColors.secondary;

  final buffer = StringBuffer();
  if (hex.length == 6 || hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

double parseToDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  throw Exception("Invalid double: $value");
}

int parseToInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  throw Exception("Invalid int: $value");
}
