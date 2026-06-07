// lib/features/reports/data/reports_service.dart

import '../../../core/network/api_client.dart';
import 'reports_models.dart';

class ReportsService {
  Future<CashflowReport> getCashflow({
    required int year,
    required int month,
  }) async {
    final json = await ApiClient.getJson('/reports/cashflow?year=$year&month=$month');
    return CashflowReport.fromJson(json as Map<String, dynamic>);
  }

  Future<List<CategoryReport>> getByCategory({
    required int year,
    required int month,
    String type = 'EXPENSE',
  }) async {
    final json = await ApiClient.getJson(
      '/reports/by-category?year=$year&month=$month&type=$type',
    );
    final rawList = json as List<dynamic>;
    return rawList
        .map((item) => CategoryReport.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<EntityReport>> getByEntity({
    required int year,
    required int month,
  }) async {
    final json = await ApiClient.getJson('/reports/by-entity?year=$year&month=$month');
    final rawList = json as List<dynamic>;
    return rawList
        .map((item) => EntityReport.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
