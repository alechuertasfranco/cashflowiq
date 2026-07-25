// lib/shared/models/statement_import.dart

import 'package:cashflowiq/core/utils/format.dart';
import 'package:cashflowiq/shared/models/transaction.dart';

/// A persisted bank-statement import batch (one imported "estado de cuenta").
class StatementImportBatch {
  final String id;
  final String accountId;
  final int year;
  final int month;
  final String filename;
  final String? bank;
  final int importedCount;
  final DateTime createdAt;

  /// Populated only on detail responses (GET /{id} and create).
  final List<Transaction> transactions;

  StatementImportBatch({
    required this.id,
    required this.accountId,
    required this.year,
    required this.month,
    required this.filename,
    required this.importedCount,
    required this.createdAt,
    this.bank,
    this.transactions = const [],
  });

  factory StatementImportBatch.fromJson(Map<String, dynamic> json) {
    return StatementImportBatch(
      id: json['id'].toString(),
      accountId: json['account_id'].toString(),
      year: parseToDouble(json['year']).toInt(),
      month: parseToDouble(json['month']).toInt(),
      filename: json['filename'] ?? '',
      bank: json['bank'],
      importedCount: parseToDouble(json['imported_count']).toInt(),
      createdAt: DateTime.parse(json['created_at']),
      transactions: json['transactions'] != null
          ? (json['transactions'] as List)
              .map((e) => Transaction.fromJson(e))
              .toList()
          : const [],
    );
  }
}
