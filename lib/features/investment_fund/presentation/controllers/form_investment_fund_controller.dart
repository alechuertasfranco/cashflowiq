// lib/features/investment_fund/presentation/controllers/form_investment_fund_controller.dart

import 'package:flutter/foundation.dart';
import 'package:cashflowiq/features/investment_fund/data/investment_fund_service.dart';
import 'package:cashflowiq/features/bank_entities/data/bank_entity_service.dart';
import 'package:cashflowiq/shared/models/investment_fund.dart';
import 'package:cashflowiq/shared/models/bank_entity.dart';
import 'package:cashflowiq/shared/models/currency.dart';
import 'package:cashflowiq/shared/services/currency_service.dart';

class FormInvestmentFundController extends ChangeNotifier {
  final InvestmentFundService _service;
  final BankEntityService _entityService;
  final CurrencyService _currencyService;

  FormInvestmentFundController(this._service, this._entityService, this._currencyService);

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

    final results = await Future.wait([_currencyService.getCurrencies(), _entityService.getEntities()]);

    currencies = results[0] as List<Currency>;
    entities = results[1] as List<BankEntity>;

    if (fund != null) {
      selectedCurrency = fund.currency;
      selectedEntity = entities.firstWhere((e) => e.id == fund.bankEntity.id);
      selectedType = fund.fundType;
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> submit({required String name, required String investedAmount, InvestmentFund? original}) async {
    isSaving = true;
    notifyListeners();

    final fund = InvestmentFund(
      id: original?.id ?? '',
      name: name,
      investedAmount: double.parse(investedAmount),
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
