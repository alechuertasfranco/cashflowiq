// lib/features/credit_cards/presentation/controllers/form_credit_card_controller.dart

import 'package:cashflowiq/features/profile/data/bank_account_service.dart';
import 'package:cashflowiq/features/profile/data/credit_card_service.dart';
import 'package:cashflowiq/features/profile/data/bank_entity_service.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';
import 'package:cashflowiq/shared/models/credit_card.dart';
import 'package:cashflowiq/shared/models/bank_entity.dart';
import 'package:cashflowiq/shared/models/currency.dart';
import 'package:cashflowiq/shared/services/currency_service.dart';
import 'package:flutter/foundation.dart';

class FormCreditCardController extends ChangeNotifier {
  final CreditCardService _service;
  final BankEntityService _entityService;
  final CurrencyService _currencyService;
  final BankAccountService _accountService;

  FormCreditCardController(
    this._service,
    this._entityService,
    this._currencyService,
    this._accountService,
  );

  List<Currency> currencies = [];
  List<BankEntity> entities = [];

  Currency? selectedCurrency;
  BankEntity? selectedEntity;
  CreditCardBrand? selectedBrand;

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

  void setBrand(CreditCardBrand? brand) {
    selectedBrand = brand;
    notifyListeners();
  }

  Future<void> init(CreditCard? card) async {
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

    if (card != null) {
      selectedCurrency = card.currency;
      selectedEntity = entities.firstWhere((e) => e.id == card.bankEntity.id);
      selectedBrand = card.brand;
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
    required String creditLimit,
    required int closingDay,
    required int dueDay,
    String? interestRate,
    CreditCard? original,
  }) async {
    isSaving = true;
    notifyListeners();

    final card = CreditCard(
      id: original?.id ?? '',
      name: name,
      creditLimit: double.parse(creditLimit),
      brand: selectedBrand!,
      closingDay: closingDay,
      dueDay: dueDay,
      interestRate: interestRate != null && interestRate.isNotEmpty ? double.parse(interestRate) : null,
      currency: selectedCurrency!,
      bankEntity: selectedEntity!,
    );

    if (original != null) {
      await _service.updateCreditCard(card);
    } else {
      await _service.createCreditCard(card);
    }

    isSaving = false;
    notifyListeners();
  }
}
