import 'package:cashflowiq/core/utils/data_cache.dart';
import 'package:cashflowiq/features/reports/data/reports_models.dart';
import 'package:cashflowiq/features/reports/data/reports_service.dart';
import 'package:flutter/foundation.dart';

class ReportDataLoader extends ChangeNotifier {
  final ReportsService _service = ReportsService();
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  late int year;
  late int month;

  List<CashflowReport> cashflows = [];
  List<CategoryReport> expenses = [];
  List<CategoryReport> incomes = [];
  List<EntityReport> entities = [];
  List<MonthlyTrendPoint> trend = [];
  List<BudgetVsActualItem> budgetVsActual = [];

  bool isLoading = true;
  String? errorMessage;

  String categoryType = 'EXPENSE';

  static const List<String> monthNames = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  static const List<String> monthShort = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  ReportDataLoader() {
    final now = DateTime.now();
    year = now.year;
    month = now.month;
  }

  bool get canGoNext {
    final now = DateTime.now();
    return !(year > now.year || (year == now.year && month >= now.month));
  }

  List<String> get currencyCodes {
    final codes = <String>{
      for (final r in cashflows) r.currencyCode,
      for (final r in expenses) r.currencyCode,
      for (final r in incomes) r.currencyCode,
      for (final r in entities) r.currencyCode,
      for (final r in budgetVsActual) r.currencyCode,
    };
    return (codes.toList()..sort());
  }

  List<String> get trendCurrencyCodes {
    final codes = <String>{for (final p in trend) p.currencyCode};
    return (codes.toList()..sort());
  }

  Future<void> loadAll({bool invalidateCache = false}) async {
    if (invalidateCache) DataCache.instance.invalidatePrefix('reports');

    isLoading = true;
    errorMessage = null;
    _notify();

    try {
      final results = await Future.wait([
        _service.getCashflow(year: year, month: month),
        _service.getByCategory(year: year, month: month, type: 'EXPENSE'),
        _service.getByCategory(year: year, month: month, type: 'INCOME'),
        _service.getByEntity(year: year, month: month),
        _service.getMonthlyTrend(months: 6),
        _service.getBudgetVsActual(year: year, month: month),
      ]);

      cashflows = results[0] as List<CashflowReport>;
      expenses = results[1] as List<CategoryReport>;
      incomes = results[2] as List<CategoryReport>;
      entities = results[3] as List<EntityReport>;
      trend = results[4] as List<MonthlyTrendPoint>;
      budgetVsActual = results[5] as List<BudgetVsActualItem>;
      isLoading = false;
    } catch (e) {
      debugPrint('ReportDataLoader error: $e');
      isLoading = false;
      errorMessage = 'Error al cargar los reportes';
    }

    _notify();
  }

  void previousMonth() {
    if (month == 1) {
      month = 12;
      year -= 1;
    } else {
      month -= 1;
    }
    loadAll();
  }

  void nextMonth() {
    if (!canGoNext) return;
    if (month == 12) {
      month = 1;
      year += 1;
    } else {
      month += 1;
    }
    loadAll();
  }

  void setCategoryType(String type) {
    categoryType = type;
    _notify();
  }
}
