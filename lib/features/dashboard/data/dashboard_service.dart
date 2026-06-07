// lib/features/dashboard/data/dashboard_service.dart

import '../../../core/network/api_client.dart';
import 'dashboard_summary.dart';

class DashboardService {
  Future<DashboardSummary> getSummary() async {
    final json = await ApiClient.getJson('/dashboard/summary');
    return DashboardSummary.fromJson(json as Map<String, dynamic>);
  }
}
