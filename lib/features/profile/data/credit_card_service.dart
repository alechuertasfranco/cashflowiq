// lib/features/credit_cards/data/credit_card_service.dart

import 'package:cashflowiq/core/network/api_client.dart';
import 'package:cashflowiq/shared/models/credit_card.dart';

class CreditCardService {
  /// 📥 GET CREDIT CARDS
  Future<List<CreditCard>> getCreditCards() async {
    try {
      final response = await ApiClient.getJson("/credit-cards");
      if (response is! List) throw Exception("Invalid response format: expected List");
      return response.map<CreditCard>((json) => CreditCard.fromJson(json)).toList();
    } catch (e) {
      // Aquí luego puedes conectar logging/analytics
      rethrow;
    }
  }

  /// ➕ CREATE CREDIT CARD
  Future<CreditCard> createCreditCard(CreditCard card) async {
    final response = await ApiClient.postJson("/credit-cards", body: card.toJson());
    return CreditCard.fromJson(response);
  }

  /// ✏️ UPDATE CREDIT CARD
  Future<CreditCard> updateCreditCard(CreditCard card) async {
    final response = await ApiClient.putJson("/credit-cards/${card.id}", body: card.toJson());
    return CreditCard.fromJson(response);
  }

  /// ❌ DELETE CREDIT CARD
  Future<void> deleteCreditCard(String id) async {
    await ApiClient.delete("/credit-cards/$id");
  }
}
