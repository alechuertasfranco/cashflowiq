// lib/features/dashboard/data/dashboard_service.dart

import '../../../core/network/api_client.dart';
import '../../../core/utils/data_cache.dart';
import 'dashboard_summary.dart';

class DashboardService {
  Future<DashboardSummary> getSummary() async {
    const key = 'dashboard_summary';
    final cached = DataCache.instance.get<DashboardSummary>(key);
    if (cached != null) return cached;

    final json = await ApiClient.getJson('/dashboard/summary');
    final result = DashboardSummary.fromJson(json as Map<String, dynamic>);
    DataCache.instance.set(key, result);
    return result;
  }
}
