// lib/features/credit_cards/presentation/controllers/form_credit_card_controller.dart

import 'package:cashflowiq/features/profile/data/credit_card_service.dart';
import 'package:cashflowiq/features/profile/data/bank_entity_service.dart';
import 'package:cashflowiq/shared/models/credit_card.dart';
import 'package:cashflowiq/shared/models/bank_entity.dart';
import 'package:cashflowiq/shared/models/currency.dart';
import 'package:cashflowiq/shared/services/currency_service.dart';
import 'package:flutter/foundation.dart';

class FormCreditCardController extends ChangeNotifier {
  final CreditCardService _service;
  final BankEntityService _entityService;
  final CurrencyService _currencyService;

  FormCreditCardController(this._service, this._entityService, this._currencyService);

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

    final results = await Future.wait([_currencyService.getCurrencies(), _entityService.getEntities()]);

    currencies = results[0] as List<Currency>;
    entities = results[1] as List<BankEntity>;

    if (card != null) {
      selectedCurrency = card.currency;
      selectedEntity = entities.firstWhere((e) => e.id == card.bankEntity.id);
      selectedBrand = card.brand;
    }

    isLoading = false;
    notifyListeners();
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
