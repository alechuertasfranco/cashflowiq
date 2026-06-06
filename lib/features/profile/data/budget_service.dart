// lib/features/budget/data/budget_service.dart

import 'package:cashflowiq/core/network/api_client.dart';
import 'package:cashflowiq/shared/models/budget.dart';

class BudgetService {
  /// GET /budgets
  Future<List<Budget>> getBudgets() async {
    final response = await ApiClient.getJson("/budgets");

    if (response is! List) throw Exception("Invalid response");

    return response.map<Budget>((e) => Budget.fromJson(e)).toList();
  }

  /// POST /budgets (create OR update)
  Future<Budget> upsertBudget(Budget budget) async {
    final response = await ApiClient.postJson("/budgets", body: budget.toCreateJson());

    return Budget.fromJson(response);
  }
}
