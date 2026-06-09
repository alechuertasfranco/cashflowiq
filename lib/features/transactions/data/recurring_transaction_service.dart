// lib/features/transactions/data/recurring_transaction_service.dart

import 'package:cashflowiq/core/network/api_client.dart';
import 'package:cashflowiq/core/utils/data_cache.dart';
import 'package:cashflowiq/shared/models/recurring_transaction.dart';

class RecurringTransactionService {
  Future<List<RecurringTransaction>> fetchAll() async {
    const key = 'recurring_transactions';
    final cached = DataCache.instance.get<List<RecurringTransaction>>(key);
    if (cached != null) return cached;

    final List data = await ApiClient.getJson('/recurring-transactions');
    final result = data.map((json) => RecurringTransaction.fromJson(json)).toList();
    DataCache.instance.set(key, result);
    return result;
  }

  Future<RecurringTransaction> create(Map<String, dynamic> data) async {
    final json = await ApiClient.postJson('/recurring-transactions', body: data);
    DataCache.instance.invalidate('recurring_transactions');
    return RecurringTransaction.fromJson(json);
  }

  Future<RecurringTransaction> update(int id, Map<String, dynamic> data) async {
    final json = await ApiClient.putJson('/recurring-transactions/$id', body: data);
    DataCache.instance.invalidate('recurring_transactions');
    return RecurringTransaction.fromJson(json);
  }

  Future<void> delete(int id) async {
    await ApiClient.delete('/recurring-transactions/$id');
    DataCache.instance.invalidate('recurring_transactions');
  }

  Future<RecurringTransaction> advance(int id) async {
    DataCache.instance.invalidate('recurring_transactions');
    final json = await ApiClient.postJson('/recurring-transactions/$id/advance');
    return RecurringTransaction.fromJson(json as Map<String, dynamic>);
  }
}
