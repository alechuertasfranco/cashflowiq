// lib/features/bank_entities/data/bank_entity_service.dart

import 'package:cashflowiq/core/network/api_client.dart';
import 'package:cashflowiq/shared/models/bank_entity.dart';

class BankEntityService {
  // 📥 GET ENTITIES
  Future<List<BankEntity>> getEntities() async {
    try {
      final List data = await ApiClient.getJson("/bank-entities");
      final entities = data.map((json) {
        return BankEntity.fromJson(json);
      }).toList();

      return entities;
    } catch (e) {
      rethrow;
    }
  }

  // ➕ CREATE ENTITY
  Future<BankEntity> createEntity(BankEntity entity) async {
    final data = await ApiClient.postJson("/bank-entities", body: entity.toJson());
    return BankEntity.fromJson(data);
  }

  // ✏️ UPDATE ENTITY
  Future<BankEntity> updateEntity(BankEntity entity) async {
    final data = await ApiClient.putJson("/bank-entities/${entity.id}", body: entity.toJson());
    return BankEntity.fromJson(data);
  }

  // ❌ DELETE ENTITY
  Future<void> deleteEntity(String id) async {
    await ApiClient.delete("/bank-entities/$id");
  }
}
