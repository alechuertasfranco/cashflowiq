// lib/features/transactions/data/transaction_service.dart

import 'package:cashflowiq/core/network/api_client.dart';
import 'package:cashflowiq/shared/models/transaction.dart';

class TransactionService {
  Future<Transaction> createTransaction(Transaction tx) async {
    final data = await ApiClient.postJson("/transactions", body: tx.toJson());
    return Transaction.fromJson(data);
  }

  Future<List<Transaction>> getTransactions({
    String? type,
    String? fromDate,
    String? toDate,
    String? categoryId,
    String? accountId,
  }) async {
    final params = <String, String>{};
    if (type != null) params['type'] = type;
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    if (categoryId != null) params['category_id'] = categoryId;
    if (accountId != null) params['account_id'] = accountId;

    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final path = query.isEmpty ? '/transactions' : '/transactions?$query';

    final List data = await ApiClient.getJson(path);
    return data.map((json) => Transaction.fromJson(json)).toList();
  }
}
