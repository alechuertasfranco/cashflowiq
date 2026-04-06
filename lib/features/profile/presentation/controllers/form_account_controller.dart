// lib\features\bank_accounts\presentation\controllers\form_account_controller.dart

import 'package:cashflowiq/features/profile/data/bank_account_service.dart';
import 'package:cashflowiq/features/profile/data/bank_entity_service.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';
import 'package:cashflowiq/shared/models/bank_entity.dart';
import 'package:cashflowiq/shared/models/currency.dart';
import 'package:cashflowiq/shared/services/currency_service.dart';
import 'package:flutter/foundation.dart';

class FormAccountController extends ChangeNotifier {
  final BankAccountService _service;
  final BankEntityService _entityService;
  final CurrencyService _currencyService;

  FormAccountController(this._service, this._entityService, this._currencyService);

  List<Currency> currencies = [];
  List<BankEntity> entities = [];

  Currency? selectedCurrency;
  BankEntity? selectedEntity;

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

  Future<void> init(BankAccount? account) async {
    isLoading = true;
    notifyListeners();

    final results = await Future.wait([_currencyService.getCurrencies(), _entityService.getEntities()]);

    currencies = results[0] as List<Currency>;
    entities = results[1] as List<BankEntity>;

    if (account != null) {
      selectedCurrency = account.balance.currency;
      selectedEntity = entities.firstWhere((e) => e.id == account.bankEntity.id);
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> submit({required String name, required String amount, BankAccount? original}) async {
    isSaving = true;
    notifyListeners();

    final account = BankAccount(
      id: original?.id ?? '',
      name: name,
      initialAmount: double.parse(amount),
      currency: selectedCurrency!,
      bankEntity: selectedEntity!,
    );

    if (original != null) {
      await _service.updateAccount(account);
    } else {
      await _service.createAccount(account);
    }

    isSaving = false;
    notifyListeners();
  }
}
