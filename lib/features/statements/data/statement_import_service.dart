// lib/features/statements/data/statement_import_service.dart

import 'package:cashflowiq/core/network/api_client.dart';
import 'package:cashflowiq/core/utils/data_cache.dart';
import 'package:cashflowiq/core/utils/format.dart';
import 'package:cashflowiq/shared/models/statement_import.dart';

/// The app's monthly-balance snapshot for an account+month, used to reconcile
/// against the statement's closing balance.
class MonthlyBalanceInfo {
  final bool closed;
  final double? initialBalance;
  final double? finalBalance;

  const MonthlyBalanceInfo({
    required this.closed,
    this.initialBalance,
    this.finalBalance,
  });

  factory MonthlyBalanceInfo.fromJson(Map<String, dynamic> json) {
    return MonthlyBalanceInfo(
      closed: json['closed'] == true,
      initialBalance:
          json['initial_balance'] != null ? parseToDouble(json['initial_balance']) : null,
      finalBalance:
          json['final_balance'] != null ? parseToDouble(json['final_balance']) : null,
    );
  }
}

class StatementImportService {
  static const _base = '/statement-imports';

  /// Fetch the closed-month snapshot for an account (for balance reconciliation).
  Future<MonthlyBalanceInfo> getMonthlyBalance({
    required String accountId,
    required int year,
    required int month,
  }) async {
    final data = await ApiClient.getJson(
        '/bank-accounts/$accountId/monthly-balance?year=$year&month=$month');
    return MonthlyBalanceInfo.fromJson(data);
  }

  /// Bulk-create the reconciled "new" movements as one import batch.
  /// [items] entries: { date (ISO), amount (num), type (INCOME|EXPENSE),
  /// description?, category_id? }.
  Future<StatementImportBatch> create({
    required String accountId,
    required int year,
    required int month,
    required String filename,
    String? bank,
    required List<Map<String, dynamic>> items,
  }) async {
    final data = await ApiClient.postJson(_base, body: {
      'account_id': int.parse(accountId),
      'year': year,
      'month': month,
      'filename': filename,
      'bank': bank,
      'items': items,
    });
    DataCache.instance.invalidatePrefix('transactions');
    DataCache.instance.invalidate('dashboard_summary');
    DataCache.instance.invalidatePrefix('statement_imports');
    return StatementImportBatch.fromJson(data);
  }

  Future<List<StatementImportBatch>> list() async {
    const key = 'statement_imports_list';
    final cached = DataCache.instance.get<List<StatementImportBatch>>(key);
    if (cached != null) return cached;

    final List data = await ApiClient.getJson(_base);
    final result =
        data.map((json) => StatementImportBatch.fromJson(json)).toList();
    DataCache.instance.set(key, result);
    return result;
  }

  Future<StatementImportBatch> getById(String id) async {
    final data = await ApiClient.getJson('$_base/$id');
    return StatementImportBatch.fromJson(data);
  }

  Future<void> delete(String id) async {
    await ApiClient.delete('$_base/$id');
    DataCache.instance.invalidatePrefix('transactions');
    DataCache.instance.invalidate('dashboard_summary');
    DataCache.instance.invalidatePrefix('statement_imports');
  }
}
