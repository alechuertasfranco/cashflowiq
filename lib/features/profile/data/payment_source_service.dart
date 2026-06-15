// lib/features/profile/data/payment_source_service.dart

import 'package:cashflowiq/core/network/api_client.dart';

class PaymentSourceService {
  Future<List<Map<String, dynamic>>> getMostUsedSources({int limit = 5}) async {
    final List data = await ApiClient.getJson("/payment-sources/most-used?limit=$limit");
    return data.cast<Map<String, dynamic>>();
  }
}
