import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/base_transaction_form_screen.dart';
import 'package:cashflowiq/core/widgets/form_step_amount.dart';
import 'package:cashflowiq/core/widgets/form_step_payment_source.dart';
import 'package:cashflowiq/features/transactions/data/transaction_service.dart';
import 'package:cashflowiq/features/transactions/presentation/transfer_transaction/transfer_form_controller.dart';
import 'package:cashflowiq/shared/models/transaction.dart';
import 'package:flutter/material.dart';

class TransferFormScreen extends StatefulWidget {
  final Transaction? prefill;
  final bool editMode;

  const TransferFormScreen({super.key, this.prefill, this.editMode = false});

  @override
  State<TransferFormScreen> createState() => _TransferFormScreenState();
}

class _TransferFormScreenState extends State<TransferFormScreen> {
  final controller = TransferFormController();
  final _transactionService = TransactionService();

  @override
  void initState() {
    super.initState();
    if (widget.prefill != null) {
      final p = widget.prefill!;
      controller.applyPrefill(
        amount: p.amount,
        description: p.description,
        date: p.date,
      );
    }
    controller.loadSources().then((_) {
      if (widget.prefill != null && mounted) {
        final p = widget.prefill!;
        controller.applyTransferPrefill(
          loadedAccounts: controller.accounts,
          loadedCards: controller.creditCards,
          fromAccountId: p.accountId,
          toAccountId: p.toAccountId,
          toCreditCardId: p.toCreditCardId,
        );
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (controller.currentStep == 0) {
      if (!controller.validateAmount()) return;
      controller.goToStep(1);
    } else if (controller.currentStep == 1) {
      if (controller.selectedAccount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Selecciona la cuenta de origen")),
        );
        return;
      }
      controller.goToStep(2);
    }
  }

  Future<void> _submit() async {
    if (controller.selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona la cuenta de origen")),
      );
      return;
    }

    if (controller.destinationType == 'account') {
      if (controller.toAccount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Selecciona la cuenta de destino")),
        );
        return;
      }
      if (controller.selectedAccount!.id == controller.toAccount!.id) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Las cuentas de origen y destino deben ser diferentes")),
        );
        return;
      }
    } else {
      if (controller.toCreditCard == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Selecciona una tarjeta de crédito de destino")),
        );
        return;
      }
    }

    controller.setSaving(true);

    final tx = Transaction(
      id: widget.editMode ? widget.prefill!.id : '',
      type: TransactionType.transfer,
      amount: double.parse(controller.amountController.text.trim()),
      date: controller.selectedDate,
      accountId: controller.selectedAccount!.id,
      toAccountId: controller.destinationType == 'account' ? controller.toAccount!.id : null,
      toCreditCardId: controller.destinationType == 'card' ? controller.toCreditCard!.id : null,
      description: controller.descriptionController.text.trim().isNotEmpty
          ? controller.descriptionController.text.trim()
          : null,
    );

    try {
      if (widget.editMode) {
        await _transactionService.updateTransaction(widget.prefill!.id, tx);
      } else {
        await _transactionService.createTransaction(tx);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("transferTransaction error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.editMode
              ? "Error al actualizar la transferencia"
              : "Error al registrar la transferencia"),
        ),
      );
    } finally {
      controller.setSaving(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => BaseTransactionFormScreen(
        controller: controller,
        totalSteps: 3,
        submitLabel: widget.editMode ? "Guardar cambios" : "Guardar transferencia",
        accentColor: context.colorPrimary,
        onNextStep: _nextStep,
        onSubmit: _submit,
        steps: [
          FormStepAmount(
            title: '¿Cuánto transferiste?',
            dateAccentColor: context.colorPrimary,
            descriptionHint: 'Ej: Pago de tarjeta',
            amountController: controller.amountController,
            descriptionController: controller.descriptionController,
            selectedDate: controller.selectedDate,
            amountError: controller.amountError,
            onDateTap: () => controller.pickDate(context),
            onAmountChanged: controller.clearAmountError,
          ),
          FormStepPaymentSource(
            title: '¿Desde dónde?',
            entities: controller.accountOnlyEntities,
            selectedEntity: controller.selectedEntity,
            selectedAccount: controller.selectedAccount,
            viewKey: controller.entityViewKey,
            goingForward: controller.entityForward,
            accountsFor: controller.accountsFor,
            onEntityTap: controller.onEntityTap,
            onAccountTap: controller.onAccountTap,
            onBack: controller.backFromEntityAccounts,
            mostUsedItems: controller.mostUsedItems.where((i) => i.isAccount).toList(),
            onAddAccount: () => controller.navigateToAccountForm(context),
          ),
          FormStepPaymentSource(
            title: '¿A dónde?',
            entities: controller.destinationType == 'account'
                ? controller.accountOnlyEntities
                : controller.cardOnlyEntities,
            selectedEntity: controller.toEntity,
            selectedAccount: controller.toAccount,
            selectedCreditCard: controller.toCreditCard,
            viewKey: controller.toEntityViewKey,
            goingForward: controller.toEntityForward,
            accountsFor: controller.accountsFor,
            cardsFor: controller.cardsFor,
            onEntityTap: controller.onToEntityTap,
            onAccountTap: controller.onToAccountTap,
            onCardTap: controller.onToCardTap,
            onBack: controller.backFromToAccounts,
            mostUsedItems: controller.destinationType == 'account'
                ? controller.mostUsedItemsTo.where((i) => i.isAccount).toList()
                : controller.mostUsedItemsTo.where((i) => !i.isAccount).toList(),
            onAddAccount: () => controller.navigateToAccountForm(context),
            onAddCreditCard: () => controller.navigateToCreditCardForm(context),
            sourceType: controller.destinationType,
            onSourceTypeChanged: controller.onDestinationTypeChanged,
          ),
        ],
      ),
    );
  }
}
