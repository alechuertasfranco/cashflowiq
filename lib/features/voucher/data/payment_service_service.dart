// lib/features/voucher/data/payment_service_service.dart

import 'package:cashflowiq/core/network/api_client.dart';
import 'package:cashflowiq/shared/models/payment_service.dart';

class PaymentServiceService {
  Future<List<PaymentService>> getPaymentServices() async {
    final List data = await ApiClient.getJson('/payment-services');
    return data.map((json) => PaymentService.fromJson(json)).toList();
  }

  Future<PaymentService> createPaymentService({
    required String name,
    required String serviceType,
    int? accountId,
    int? creditCardId,
  }) async {
    final data = await ApiClient.postJson('/payment-services', body: {
      'name': name,
      'service_type': serviceType,
      'account_id': accountId,
      'credit_card_id': creditCardId,
    });
    return PaymentService.fromJson(data);
  }

  Future<PaymentService> updatePaymentService(
    int id, {
    String? name,
    String? serviceType,
    int? accountId,
    int? creditCardId,
  }) async {
    final data = await ApiClient.putJson('/payment-services/$id', body: {
      'name': ?name,
      'service_type': ?serviceType,
      'account_id': accountId,
      'credit_card_id': creditCardId,
    });
    return PaymentService.fromJson(data);
  }

  Future<void> deletePaymentService(int id) async {
    await ApiClient.delete('/payment-services/$id');
  }
}
