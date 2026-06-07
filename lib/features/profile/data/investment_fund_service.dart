// lib/features/investment_fund/data/investment_fund_service.dart

import 'package:cashflowiq/core/network/api_client.dart';
import 'package:cashflowiq/core/utils/data_cache.dart';
import 'package:cashflowiq/shared/models/investment_fund.dart';

class InvestmentFundService {
  /// 📥 GET FUNDS
  Future<List<InvestmentFund>> getFunds() async {
    try {
      const key = 'investment_funds';
      final cached = DataCache.instance.get<List<InvestmentFund>>(key);
      if (cached != null) return cached;

      final response = await ApiClient.getJson("/investment-funds");
      if (response is! List) throw Exception("Invalid response format: expected List");
      final result = response.map<InvestmentFund>((json) => InvestmentFund.fromJson(json)).toList();
      DataCache.instance.set(key, result);
      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// ➕ CREATE FUND
  Future<InvestmentFund> createFund(InvestmentFund fund) async {
    final response = await ApiClient.postJson("/investment-funds", body: fund.toJson());
    DataCache.instance.invalidate('investment_funds');
    return InvestmentFund.fromJson(response);
  }

  /// ✏️ UPDATE FUND
  Future<InvestmentFund> updateFund(InvestmentFund fund) async {
    final response = await ApiClient.putJson("/investment-funds/${fund.id}", body: fund.toJson());
    DataCache.instance.invalidate('investment_funds');
    return InvestmentFund.fromJson(response);
  }

  /// ❌ DELETE FUND
  Future<void> deleteFund(String id) async {
    await ApiClient.delete("/investment-funds/$id");
    DataCache.instance.invalidate('investment_funds');
  }
}
