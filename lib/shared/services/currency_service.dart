// lib\shared\services\currency_service.dart

import 'package:cashflowiq/core/network/api_client.dart';
import 'package:cashflowiq/core/utils/data_cache.dart';
import 'package:cashflowiq/shared/models/currency.dart';

class CurrencyService {
  /// 🌎 GET ALL CURRENCIES
  Future<List<Currency>> getCurrencies({bool forceRefresh = false}) async {
    try {
      const key = 'currencies';
      if (!forceRefresh) {
        final cached = DataCache.instance.get<List<Currency>>(key);
        if (cached != null) return cached;
      }

      final List data = await ApiClient.getJson("/currencies");

      final currencies = data.map((json) {
        return Currency.fromMap(json);
      }).toList();

      DataCache.instance.set(key, currencies);

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
    final cached = DataCache.instance.get<List<Currency>>('currencies');
    if (cached == null) return null;

    try {
      return cached.firstWhere((c) => c.code == code);
    } catch (_) {
      return null;
    }
  }

  /// 🔄 REFRESH CACHE
  Future<void> refresh() async {
    DataCache.instance.invalidate('currencies');
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
