// lib/features/credit_cards/data/credit_card_service.dart

import 'package:cashflowiq/core/network/api_client.dart';
import 'package:cashflowiq/core/utils/data_cache.dart';
import 'package:cashflowiq/shared/models/credit_card.dart';

class CreditCardService {
  /// 🏆 GET MOST-USED CREDIT CARDS
  Future<List<CreditCard>> getMostUsedCreditCards({int limit = 3}) async {
    final response = await ApiClient.getJson("/credit-cards/most-used?limit=$limit");
    if (response is! List) throw Exception("Invalid response format: expected List");
    return response.map<CreditCard>((json) => CreditCard.fromJson(json)).toList();
  }

  /// 📥 GET CREDIT CARDS
  Future<List<CreditCard>> getCreditCards() async {
    try {
      const key = 'credit_cards';
      final cached = DataCache.instance.get<List<CreditCard>>(key);
      if (cached != null) return cached;

      final response = await ApiClient.getJson("/credit-cards");
      if (response is! List) throw Exception("Invalid response format: expected List");
      final result = response.map<CreditCard>((json) => CreditCard.fromJson(json)).toList();
      DataCache.instance.set(key, result);
      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// ➕ CREATE CREDIT CARD
  Future<CreditCard> createCreditCard(CreditCard card) async {
    final response = await ApiClient.postJson("/credit-cards", body: card.toJson());
    DataCache.instance.invalidate('credit_cards');
    return CreditCard.fromJson(response);
  }

  /// ✏️ UPDATE CREDIT CARD
  Future<CreditCard> updateCreditCard(CreditCard card) async {
    final response = await ApiClient.putJson("/credit-cards/${card.id}", body: card.toJson());
    DataCache.instance.invalidate('credit_cards');
    return CreditCard.fromJson(response);
  }

  /// ❌ DELETE CREDIT CARD
  Future<void> deleteCreditCard(String id) async {
    await ApiClient.delete("/credit-cards/$id");
    DataCache.instance.invalidate('credit_cards');
  }
}
