// lib\shared\repositories\bank_entity_repository.dart

import 'package:cashflowiq/features/bank_entities/data/bank_entity_service.dart';
import 'package:cashflowiq/shared/models/bank_entity.dart';

class BankEntityRepository {
  final BankEntityService _service;

  List<BankEntity>? _cache;

  BankEntityRepository(this._service);

  Future<List<BankEntity>> getEntities({bool forceRefresh = false}) async {
    if (_cache != null && !forceRefresh) {
      return _cache!;
    }

    final data = await _service.getEntities();
    _cache = data;
    return data;
  }

  void invalidate() {
    _cache = null;
  }
}
