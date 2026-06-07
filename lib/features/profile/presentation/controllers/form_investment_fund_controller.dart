// lib/features/investment_fund/presentation/controllers/form_investment_fund_controller.dart

import 'package:flutter/foundation.dart';
import 'package:cashflowiq/features/profile/data/bank_account_service.dart';
import 'package:cashflowiq/features/profile/data/investment_fund_service.dart';
import 'package:cashflowiq/features/profile/data/bank_entity_service.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';
import 'package:cashflowiq/shared/models/investment_fund.dart';
import 'package:cashflowiq/shared/models/bank_entity.dart';
import 'package:cashflowiq/shared/models/currency.dart';
import 'package:cashflowiq/shared/services/currency_service.dart';

class FormInvestmentFundController extends ChangeNotifier {
  final InvestmentFundService _service;
  final BankEntityService _entityService;
  final CurrencyService _currencyService;
  final BankAccountService _accountService;

  FormInvestmentFundController(
    this._service,
    this._entityService,
    this._currencyService,
    this._accountService,
  );

  List<Currency> currencies = [];
  List<BankEntity> entities = [];

  Currency? selectedCurrency;
  BankEntity? selectedEntity;
  InvestmentFundType? selectedType;

  bool isLoading = true;
  bool isSaving = false;

  void setCurrency(Currency? currency) {
    selectedCurrency = currency;
    notifyListeners();
  }

  void setEntity(BankEntity? entity) {
    selectedEntity = entity;
    notifyListeners();
  }

  void setType(InvestmentFundType? type) {
    if (type == null) return;
    selectedType = type;
    notifyListeners();
  }

  Future<void> init(InvestmentFund? fund) async {
    isLoading = true;
    notifyListeners();

    final results = await Future.wait([
      _currencyService.getCurrencies(),
      _entityService.getEntities(),
      _accountService.getAccounts(),
    ]);

    currencies = results[0] as List<Currency>;
    entities = results[1] as List<BankEntity>;
    final existingAccounts = results[2] as List<BankAccount>;

    if (fund != null) {
      selectedCurrency = fund.currency;
      selectedEntity = entities.firstWhere((e) => e.id == fund.bankEntity.id);
      selectedType = fund.fundType;
    } else {
      selectedCurrency = _mostUsedCurrency(currencies, existingAccounts);
    }

    isLoading = false;
    notifyListeners();
  }

  /// Returns the currency used most often across [accounts], falling back to
  /// the first entry of [currencies] when there is no data or a tie cannot
  /// be broken (first-encountered wins on tie).
  Currency? _mostUsedCurrency(List<Currency> currencies, List<BankAccount> accounts) {
    if (currencies.isEmpty) return null;
    if (accounts.isEmpty) return currencies.first;

    final counts = <String, int>{};
    for (final a in accounts) {
      counts[a.currency.code] = (counts[a.currency.code] ?? 0) + 1;
    }

    String? topCode;
    int topCount = 0;
    for (final entry in counts.entries) {
      if (entry.value > topCount) {
        topCount = entry.value;
        topCode = entry.key;
      }
    }

    if (topCode == null) return currencies.first;
    return currencies.firstWhere(
      (c) => c.code == topCode,
      orElse: () => currencies.first,
    );
  }

  Future<void> submit({
    required String name,
    required String investedAmount,
    String? currentValue,
    InvestmentFund? original,
  }) async {
    isSaving = true;
    notifyListeners();

    final fund = InvestmentFund(
      id: original?.id ?? '',
      name: name,
      investedAmount: double.parse(investedAmount),
      currentValue: currentValue != null && currentValue.isNotEmpty ? double.parse(currentValue) : null,
      fundType: selectedType!,
      currency: selectedCurrency!,
      bankEntity: selectedEntity!,
    );

    if (original != null) {
      await _service.updateFund(fund);
    } else {
      await _service.createFund(fund);
    }

    isSaving = false;
    notifyListeners();
  }
}
