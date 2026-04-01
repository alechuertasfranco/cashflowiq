// lib\shared\services\currency_service.dart

import 'package:cashflowiq/core/network/api_client.dart';
import 'package:cashflowiq/shared/models/currency.dart';

class CurrencyService {
  /// 🧠 Cache en memoria
  List<Currency>? _cache;

  /// 🌎 GET ALL CURRENCIES
  Future<List<Currency>> getCurrencies({bool forceRefresh = false}) async {
    try {
      if (_cache != null && !forceRefresh) {
        return _cache!;
      }

      final List data = await ApiClient.getJson("/currencies");

      final currencies = data.map((json) {
        return Currency.fromMap(json);
      }).toList();

      _cache = currencies;

      return currencies;
    } catch (e) {
      rethrow;
    }
  }

  /// 🔍 GET BY CODE (async)
  Future<Currency> getByCode(String code) async {
    final currencies = await getCurrencies();
    return currencies.firstWhere((c) => c.code == code, orElse: () => throw Exception("Currency not found: $code"));
  }

  /// ⚡ GET FROM CACHE (sync)
  Currency? getCachedByCode(String code) {
    if (_cache == null) return null;

    try {
      return _cache!.firstWhere((c) => c.code == code);
    } catch (_) {
      return null;
    }
  }

  /// 🔄 REFRESH CACHE
  Future<void> refresh() async {
    _cache = null;
    await getCurrencies(forceRefresh: true);
  }

  /// 💱 GET EXCHANGE RATE
  Future<double> getExchangeRate({required String from, required String to}) async {
    try {
      final data = await ApiClient.getJson("/currencies/exchange-rate?from=$from&to=$to");
      return (data["rate"] as num).toDouble();
    } catch (e) {
      rethrow;
    }
  }
}
