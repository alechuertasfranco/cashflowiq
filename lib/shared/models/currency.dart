// lib/shared/models/currency.dart

class Currency {
  final String code; // ISO: USD, PEN, EUR
  final String symbol; // $, S/, €
  final String name; // Dólar, Sol, Euro
  final String flag; // 🇵🇪 🇺🇸 🇪🇺
  final int decimals; // 2 normalmente
  final double? exchangeRateToBase;

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
    required this.flag,
    this.decimals = 2,
    this.exchangeRateToBase,
  });

  // 🌎 Definiciones base
  static const pen = Currency(code: "PEN", symbol: "S/", name: "Sol peruano", flag: "🇵🇪");
  static const usd = Currency(code: "USD", symbol: "\$", name: "Dólar estadounidense", flag: "🇺🇸");
  static const eur = Currency(code: "EUR", symbol: "€", name: "Euro", flag: "🇪🇺");

  // 📦 Lista tipo enum
  static const List<Currency> values = [pen, usd, eur];

  // 🔍 Buscar por código (backend → app)
  static Currency fromCode(String code) {
    return values.firstWhere((c) => c.code == code, orElse: () => pen);
  }

  // 🔄 JSON (para Money)
  factory Currency.fromJson(String code) {
    return fromCode(code);
  }

  String toJson() => code;

  // ⚖️ Necesario para Map<Currency, Money>
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Currency && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;
}
