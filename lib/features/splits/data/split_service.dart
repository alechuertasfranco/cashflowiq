// lib/features/splits/data/split_service.dart

import 'package:cashflowiq/core/network/api_client.dart';
import 'package:cashflowiq/core/utils/data_cache.dart';
import 'package:cashflowiq/shared/models/transaction_split.dart';

class SplitService {
  Future<List<TransactionSplit>> fetchSplits({
    required bool settled,
    int limit = 50,
    int offset = 0,
  }) async {
    // Only cache the default-page requests (offset == 0) to keep key cardinality low.
    final key = offset == 0
        ? (settled ? 'splits_settled' : 'splits_pending')
        : null;

    if (key != null) {
      final cached = DataCache.instance.get<List<TransactionSplit>>(key);
      if (cached != null) return cached;
    }

    final List data = await ApiClient.getJson(
      '/transaction-splits?settled=$settled&limit=$limit&offset=$offset',
    );
    final result = data.map((json) => TransactionSplit.fromJson(json)).toList();

    if (key != null) DataCache.instance.set(key, result);
    return result;
  }

  Future<TransactionSplit> settle(int splitId, double amount, String toAccountId) async {
    final json = await ApiClient.postJson(
      '/split-settlements/$splitId',
      body: {'amount': amount, 'to_account_id': int.parse(toAccountId)},
    );
    DataCache.instance.invalidatePrefix('splits');
    DataCache.instance.invalidate('accounts');
    return TransactionSplit.fromJson(json);
  }
}
