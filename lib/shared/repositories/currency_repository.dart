// lib\shared\repositories\currency_repository.dart

import 'package:cashflowiq/shared/models/currency.dart';
import 'package:cashflowiq/shared/services/currency_service.dart';

class CurrencyRepository {
  final CurrencyService _service;

  List<Currency>? _cache;

  CurrencyRepository(this._service);

  Future<List<Currency>> getCurrencies({bool forceRefresh = false}) async {
    if (_cache != null && !forceRefresh) {
      return _cache!;
    }

    final data = await _service.getCurrencies();
    _cache = data;
    return data;
  }
}
