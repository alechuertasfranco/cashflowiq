// lib/features/reports/data/reports_service.dart

import '../../../core/network/api_client.dart';
import '../../../core/utils/data_cache.dart';
import 'reports_models.dart';

class ReportsService {
  Future<List<CashflowReport>> getCashflow({
    required int year,
    required int month,
  }) async {
    final key = 'reports_cashflow_${year}_$month';
    final cached = DataCache.instance.get<List<CashflowReport>>(key);
    if (cached != null) return cached;

    final json = await ApiClient.getJson('/reports/cashflow?year=$year&month=$month');
    final rawList = json as List<dynamic>;
    final result = rawList
        .map((item) => CashflowReport.fromJson(item as Map<String, dynamic>))
        .toList();
    DataCache.instance.set(key, result);
    return result;
  }

  Future<List<CategoryReport>> getByCategory({
    required int year,
    required int month,
    String type = 'EXPENSE',
  }) async {
    final key = 'reports_by_category_${year}_${month}_$type';
    final cached = DataCache.instance.get<List<CategoryReport>>(key);
    if (cached != null) return cached;

    final json = await ApiClient.getJson(
      '/reports/by-category?year=$year&month=$month&type=$type',
    );
    final rawList = json as List<dynamic>;
    final result = rawList
        .map((item) => CategoryReport.fromJson(item as Map<String, dynamic>))
        .toList();
    DataCache.instance.set(key, result);
    return result;
  }

  Future<List<EntityReport>> getByEntity({
    required int year,
    required int month,
  }) async {
    final key = 'reports_by_entity_${year}_$month';
    final cached = DataCache.instance.get<List<EntityReport>>(key);
    if (cached != null) return cached;

    final json = await ApiClient.getJson('/reports/by-entity?year=$year&month=$month');
    final rawList = json as List<dynamic>;
    final result = rawList
        .map((item) => EntityReport.fromJson(item as Map<String, dynamic>))
        .toList();
    DataCache.instance.set(key, result);
    return result;
  }

  Future<List<MonthlyTrendPoint>> getMonthlyTrend({int months = 6}) async {
    final key = 'reports_monthly_trend_$months';
    final cached = DataCache.instance.get<List<MonthlyTrendPoint>>(key);
    if (cached != null) return cached;

    final json = await ApiClient.getJson('/reports/monthly-trend?months=$months');
    final rawList = json as List<dynamic>;
    final result = rawList
        .map((item) => MonthlyTrendPoint.fromJson(item as Map<String, dynamic>))
        .toList();
    DataCache.instance.set(key, result);
    return result;
  }

  Future<List<BudgetVsActualItem>> getBudgetVsActual({
    required int year,
    required int month,
  }) async {
    final key = 'reports_budget_vs_actual_${year}_$month';
    final cached = DataCache.instance.get<List<BudgetVsActualItem>>(key);
    if (cached != null) return cached;

    final json = await ApiClient.getJson(
      '/reports/budget-vs-actual?year=$year&month=$month',
    );
    final rawList = json as List<dynamic>;
    final result = rawList
        .map((item) => BudgetVsActualItem.fromJson(item as Map<String, dynamic>))
        .toList();
    DataCache.instance.set(key, result);
    return result;
  }
}
