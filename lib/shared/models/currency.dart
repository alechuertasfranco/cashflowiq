// lib/shared/models/currency.dart

class Currency {
  final String id; // Unique identifier
  final String code; // ISO: USD, PEN, EUR
  final String symbol; // $, S/, €
  final String name; // Dólar, Sol, Euro
  final String? flag; // 🇵🇪 🇺🇸 🇪🇺
  final int decimals; // 2 normalmente
  final double? exchangeRateToBase;

  const Currency({
    required this.id,
    required this.code,
    required this.symbol,
    required this.name,
    this.flag,
    this.decimals = 2,
    this.exchangeRateToBase,
  });

  // ✅ Desde API
  factory Currency.fromMap(Map<String, dynamic> json) {
    double? toDoubleSafe(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    int toIntSafe(dynamic value, {int fallback = 2}) {
      if (value == null) return fallback;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? fallback;
    }

    return Currency(
      id: json["id"].toString(),
      code: json["code"] ?? '',
      symbol: json["symbol"] ?? '',
      name: json["name"] ?? '',
      flag: json["flag"],
      decimals: toIntSafe(json["decimals"]),
      exchangeRateToBase: toDoubleSafe(json["exchange_rate_to_base"]),
    );
  }

  // ✅ Para enviar al backend (solo code)
  String toJson() => code;

  // ⚖️ Necesario para Map<Currency, Money>
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Currency && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;
}
