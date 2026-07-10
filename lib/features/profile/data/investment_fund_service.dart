// lib/features/profile/data/investment_fund_service.dart

import 'package:cashflowiq/core/network/api_client.dart';
import 'package:cashflowiq/core/utils/data_cache.dart';
import 'package:cashflowiq/shared/models/investment_fund.dart';
import 'package:cashflowiq/shared/models/investment_fund_snapshot.dart';

class InvestmentFundService {
  Future<List<InvestmentFund>> getFunds() async {
    const key = 'investment_funds';
    final cached = DataCache.instance.get<List<InvestmentFund>>(key);
    if (cached != null) return cached;

    final response = await ApiClient.getJson("/investment-funds");
    if (response is! List) throw Exception("Invalid response format: expected List");
    final result = response.map<InvestmentFund>((json) => InvestmentFund.fromJson(json)).toList();
    DataCache.instance.set(key, result);
    return result;
  }

  Future<InvestmentFund> createFund(InvestmentFund fund) async {
    final response = await ApiClient.postJson("/investment-funds", body: fund.toJson());
    DataCache.instance.invalidate('investment_funds');
    return InvestmentFund.fromJson(response);
  }

  Future<InvestmentFund> updateFund(InvestmentFund fund) async {
    final response = await ApiClient.putJson("/investment-funds/${fund.id}", body: fund.toJson());
    DataCache.instance.invalidate('investment_funds');
    return InvestmentFund.fromJson(response);
  }

  /// Re-aligns current_value with the latest snapshot on the backend.
  /// Snapshots writes already do this automatically; this covers drift from
  /// manual edits (FormInvestmentFundScreen) or pre-existing data.
  Future<InvestmentFund> syncCurrentValue(String fundId) async {
    final response = await ApiClient.postJson("/investment-funds/$fundId/sync-current-value");
    DataCache.instance.invalidate('investment_funds');
    return InvestmentFund.fromJson(response);
  }

  Future<void> deleteFund(String id) async {
    await ApiClient.delete("/investment-funds/$id");
    DataCache.instance.invalidate('investment_funds');
    DataCache.instance.invalidatePrefix('fund_snapshots_');
  }

  // ---------------------------------------------------------------------------
  // Snapshots
  // ---------------------------------------------------------------------------

  Future<List<InvestmentFundSnapshot>> getSnapshots(String fundId) async {
    final key = 'fund_snapshots_$fundId';
    final cached = DataCache.instance.get<List<InvestmentFundSnapshot>>(key);
    if (cached != null) return cached;

    final response = await ApiClient.getJson("/investment-funds/$fundId/snapshots");
    final result = (response as List)
        .map<InvestmentFundSnapshot>((j) => InvestmentFundSnapshot.fromJson(j))
        .toList();
    DataCache.instance.set(key, result);
    return result;
  }

  Future<InvestmentFundSnapshot> createSnapshot(
    String fundId,
    InvestmentFundSnapshot snapshot,
  ) async {
    final response = await ApiClient.postJson(
      "/investment-funds/$fundId/snapshots",
      body: snapshot.toJson(),
    );
    // Adding a snapshot also updates the fund's current_value on the backend,
    // so the cached funds list must be invalidated too, not just the snapshots.
    DataCache.instance.invalidate('fund_snapshots_$fundId');
    DataCache.instance.invalidate('investment_funds');
    return InvestmentFundSnapshot.fromJson(response);
  }

  Future<void> deleteSnapshot(String fundId, String snapshotId) async {
    await ApiClient.delete("/investment-funds/$fundId/snapshots/$snapshotId");
    DataCache.instance.invalidate('fund_snapshots_$fundId');
    DataCache.instance.invalidate('investment_funds');
  }
}
