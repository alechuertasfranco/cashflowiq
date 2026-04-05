// lib/features/investment_fund/data/investment_fund_service.dart

import 'package:cashflowiq/core/network/api_client.dart';
import 'package:cashflowiq/shared/models/investment_fund.dart';

class InvestmentFundService {
  /// 📥 GET FUNDS
  Future<List<InvestmentFund>> getFunds() async {
    try {
      final response = await ApiClient.getJson("/investment-funds");
      if (response is! List) throw Exception("Invalid response format: expected List");
      return response.map<InvestmentFund>((json) => InvestmentFund.fromJson(json)).toList();
    } catch (e) {
      // Aquí luego puedes conectar logging/analytics
      rethrow;
    }
  }

  /// ➕ CREATE FUND
  Future<InvestmentFund> createFund(InvestmentFund fund) async {
    final response = await ApiClient.postJson("/investment-funds", body: fund.toJson());
    return InvestmentFund.fromJson(response);
  }

  /// ✏️ UPDATE FUND
  Future<InvestmentFund> updateFund(InvestmentFund fund) async {
    final response = await ApiClient.putJson("/investment-funds/${fund.id}", body: fund.toJson());
    return InvestmentFund.fromJson(response);
  }

  /// ❌ DELETE FUND
  Future<void> deleteFund(String id) async {
    await ApiClient.delete("/investment-funds/$id");
  }
}
