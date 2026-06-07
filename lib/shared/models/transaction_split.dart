// lib/shared/models/transaction_split.dart

import 'package:cashflowiq/core/utils/format.dart';
import 'package:cashflowiq/shared/models/contact.dart';

class TransactionSplit {
  final int id;
  final int transactionId;
  final Contact contact;
  final double amount;
  final bool isSettled;
  final DateTime createdAt;

  TransactionSplit({
    required this.id,
    required this.transactionId,
    required this.contact,
    required this.amount,
    required this.isSettled,
    required this.createdAt,
  });

  factory TransactionSplit.fromJson(Map<String, dynamic> json) {
    return TransactionSplit(
      id: parseToInt(json['id']),
      transactionId: parseToInt(json['transaction_id']),
      contact: Contact.fromJson(json['contact'] as Map<String, dynamic>),
      amount: parseToDouble(json['amount']),
      isSettled: json['is_settled'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
