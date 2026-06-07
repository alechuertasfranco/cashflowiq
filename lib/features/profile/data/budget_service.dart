// lib/features/budget/data/budget_service.dart

import 'package:cashflowiq/core/network/api_client.dart';
import 'package:cashflowiq/core/utils/data_cache.dart';
import 'package:cashflowiq/shared/models/budget.dart';

class BudgetService {
  /// GET /budgets
  Future<List<Budget>> getBudgets() async {
    const key = 'budgets';
    final cached = DataCache.instance.get<List<Budget>>(key);
    if (cached != null) return cached;

    final response = await ApiClient.getJson("/budgets");

    if (response is! List) throw Exception("Invalid response");

    final result = response.map<Budget>((e) => Budget.fromJson(e)).toList();
    DataCache.instance.set(key, result);
    return result;
  }

  /// POST /budgets (create OR update)
  Future<Budget> upsertBudget(Budget budget) async {
    final response = await ApiClient.postJson("/budgets", body: budget.toCreateJson());
    DataCache.instance.invalidate('budgets');
    DataCache.instance.invalidatePrefix('categories');
    return Budget.fromJson(response);
  }
}
