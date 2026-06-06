import 'package:flutter/foundation.dart';
import 'package:cashflowiq/shared/models/budget.dart';
import 'package:cashflowiq/shared/models/currency.dart';
import 'package:cashflowiq/shared/services/currency_service.dart';
import 'package:cashflowiq/features/profile/data/budget_service.dart';

class FormBudgetController extends ChangeNotifier {
  final BudgetService _service;
  final CurrencyService _currencyService;

  FormBudgetController(this._service, this._currencyService);

  List<Currency> currencies = [];
  Currency? selectedCurrency;

  bool isLoading = true;
  bool isSaving = false;

  void setCurrency(Currency? currency) {
    selectedCurrency = currency;
    notifyListeners();
  }

  Future<void> init(Budget? budget) async {
    isLoading = true;
    notifyListeners();

    currencies = await _currencyService.getCurrencies();

    if (budget != null) {
      selectedCurrency = budget.currency;
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> submit({required double amount, required String categoryId, Budget? original}) async {
    if (selectedCurrency == null) return;

    isSaving = true;
    notifyListeners();

    final budget = Budget(
      id: original?.id ?? '',
      amount: amount,
      spent: original?.spent ?? 0,
      categoryId: categoryId,
      currencyId: selectedCurrency!.id,
    );

    await _service.upsertBudget(budget);

    isSaving = false;
    notifyListeners();
  }
}
