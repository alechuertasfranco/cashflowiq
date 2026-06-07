// lib/features/splits/data/split_service.dart

import 'package:cashflowiq/core/network/api_client.dart';
import 'package:cashflowiq/shared/models/transaction_split.dart';

class SplitService {
  Future<List<TransactionSplit>> fetchSplits({
    required bool settled,
    int limit = 50,
    int offset = 0,
  }) async {
    final List data = await ApiClient.getJson(
      '/transaction-splits?settled=$settled&limit=$limit&offset=$offset',
    );
    return data.map((json) => TransactionSplit.fromJson(json)).toList();
  }

  Future<TransactionSplit> settle(int splitId, double amount) async {
    final json = await ApiClient.postJson(
      '/split-settlements/$splitId',
      body: {'amount': amount},
    );
    return TransactionSplit.fromJson(json);
  }
}
