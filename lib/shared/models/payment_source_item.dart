import 'package:flutter/material.dart';

class PaymentSourceItem {
  final IconData icon;
  final String id;
  final String name;
  final String entityCode;
  final bool isAccount;
  final VoidCallback onTap;

  const PaymentSourceItem({
    required this.icon,
    required this.id,
    required this.name,
    required this.entityCode,
    required this.isAccount,
    required this.onTap,
  });
}
