// lib/features/transactions/data/recurring_transaction_service.dart

import 'package:cashflowiq/core/network/api_client.dart';
import 'package:cashflowiq/shared/models/recurring_transaction.dart';

class RecurringTransactionService {
  Future<List<RecurringTransaction>> fetchAll() async {
    final List data = await ApiClient.getJson('/recurring-transactions');
    return data.map((json) => RecurringTransaction.fromJson(json)).toList();
  }

  Future<RecurringTransaction> create(Map<String, dynamic> data) async {
    final json = await ApiClient.postJson('/recurring-transactions', body: data);
    return RecurringTransaction.fromJson(json);
  }

  Future<RecurringTransaction> update(int id, Map<String, dynamic> data) async {
    final json = await ApiClient.putJson('/recurring-transactions/$id', body: data);
    return RecurringTransaction.fromJson(json);
  }

  Future<void> delete(int id) async {
    await ApiClient.delete('/recurring-transactions/$id');
  }
}
