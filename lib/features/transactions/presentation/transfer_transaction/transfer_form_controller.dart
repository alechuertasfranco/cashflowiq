import 'package:cashflowiq/core/controllers/base_transaction_form_controller.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';
import 'package:cashflowiq/shared/models/bank_entity.dart';
import 'package:cashflowiq/shared/models/credit_card.dart';
import 'package:cashflowiq/shared/models/payment_source_item.dart';
import 'package:flutter/material.dart';

/// Extends [BaseTransactionFormController] with transfer-specific state:
/// - Base fields (selectedEntity, selectedAccount, entityViewKey, entityForward)
///   represent the FROM account selection.
/// - New "to" fields handle the TO destination (account or credit card).
class TransferFormController extends BaseTransactionFormController {
  String destinationType = 'account'; // 'account' | 'card'
  BankEntity? toEntity;
  BankAccount? toAccount;
  CreditCard? toCreditCard;
  String toEntityViewKey = 'entities';
  bool toEntityForward = true;

  // ── Derived getters ─────────────────────────────────────────────────────────

  List<BankEntity> get accountOnlyEntities {
    final seen = <String>{};
    final result = <BankEntity>[];
    for (final a in accounts) {
      if (seen.add(a.bankEntity.id)) result.add(a.bankEntity);
    }
    return result;
  }

  List<BankEntity> get cardOnlyEntities {
    final seen = <String>{};
    final result = <BankEntity>[];
    for (final c in creditCards) {
      if (seen.add(c.bankEntity.id)) result.add(c.bankEntity);
    }
    return result;
  }

  // ── Most-used items for the TO destination ──────────────────────────────────

  List<PaymentSourceItem> get mostUsedItemsTo {
    return mostUsedItems.map((item) {
      if (item.isAccount) {
        final account = accounts.where((a) => a.id == item.id).firstOrNull;
        if (account == null) return item;
        return PaymentSourceItem(
          icon: item.icon,
          id: item.id,
          name: item.name,
          entityCode: item.entityCode,
          isAccount: true,
          onTap: () => onToAccountTap(account),
        );
      } else {
        final card = creditCards.where((c) => c.id == item.id).firstOrNull;
        if (card == null) return item;
        return PaymentSourceItem(
          icon: item.icon,
          id: item.id,
          name: item.name,
          entityCode: item.entityCode,
          isAccount: false,
          onTap: () => onToCardTap(card),
        );
      }
    }).toList();
  }

  // ── TO navigation ────────────────────────────────────────────────────────────

  void onDestinationTypeChanged(String type) {
    destinationType = type;
    toEntity = null;
    toAccount = null;
    toCreditCard = null;
    toEntityViewKey = 'entities';
    notifyListeners();
  }

  void onToEntityTap(BankEntity entity) {
    if (toEntity?.id != entity.id) {
      toAccount = null;
      toCreditCard = null;
    }
    toEntity = entity;
    toEntityForward = true;
    toEntityViewKey = 'accounts_${entity.id}';
    notifyListeners();
  }

  void onToAccountTap(BankAccount account) {
    toAccount = account;
    toCreditCard = null;
    notifyListeners();
  }

  void onToCardTap(CreditCard card) {
    toCreditCard = card;
    toAccount = null;
    notifyListeners();
  }

  void backFromToAccounts() {
    toEntity = null;
    toEntityForward = false;
    toEntityViewKey = 'entities';
    notifyListeners();
  }

  // ── Navigation override ──────────────────────────────────────────────────────

  @override
  void prevStep(BuildContext context) {
    if (currentStep == 1 && selectedEntity != null) {
      backFromEntityAccounts();
      return;
    }
    if (currentStep == 2 && toEntity != null) {
      backFromToAccounts();
      return;
    }
    if (currentStep > 0) {
      goToStep(currentStep - 1);
    } else {
      Navigator.pop(context);
    }
  }

  // ── Prefill ──────────────────────────────────────────────────────────────────

  void applyTransferPrefill({
    required List<BankAccount> loadedAccounts,
    required List<CreditCard> loadedCards,
    String? fromAccountId,
    String? toAccountId,
    String? toCreditCardId,
  }) {
    if (fromAccountId != null) {
      selectedAccount = loadedAccounts.where((a) => a.id == fromAccountId).firstOrNull;
      selectedEntity = selectedAccount?.bankEntity;
      if (selectedEntity != null) entityViewKey = 'accounts_${selectedEntity!.id}';
    }
    if (toAccountId != null) {
      toAccount = loadedAccounts.where((a) => a.id == toAccountId).firstOrNull;
      toEntity = toAccount?.bankEntity;
      destinationType = 'account';
      if (toEntity != null) toEntityViewKey = 'accounts_${toEntity!.id}';
    } else if (toCreditCardId != null) {
      toCreditCard = loadedCards.where((c) => c.id == toCreditCardId).firstOrNull;
      toEntity = toCreditCard?.bankEntity;
      destinationType = 'card';
      if (toEntity != null) toEntityViewKey = 'accounts_${toEntity!.id}';
    }
    notifyListeners();
  }
}
