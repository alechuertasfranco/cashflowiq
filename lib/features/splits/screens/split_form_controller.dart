import 'package:cashflowiq/core/controllers/base_transaction_form_controller.dart';
import 'package:cashflowiq/features/profile/data/category_service.dart';
import 'package:cashflowiq/features/splits/data/contact_service.dart';
import 'package:cashflowiq/features/splits/screens/widgets/split_step_participants.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';
import 'package:cashflowiq/shared/models/bank_entity.dart';
import 'package:cashflowiq/shared/models/category.dart';
import 'package:cashflowiq/shared/models/contact.dart';
import 'package:flutter/material.dart';

/// Extends [BaseTransactionFormController] with split-expense-specific state.
///
/// Step layout:
///   0 — FormStepAmount        (amount + required description + date)
///   1 — SplitStepCategories   (expense categories)
///   2 — SplitStepAccount      (from account)
///   3 — SplitStepParticipants (contacts + per-person amounts)
class SplitFormController extends BaseTransactionFormController {
  final _categoryService = CategoryService();
  final _contactService = ContactService();

  // ── Extra data ────────────────────────────────────────────────────────────────
  List<Category> expenseCategories = [];
  List<Contact> allContacts = [];

  // ── Step 0 extra field ────────────────────────────────────────────────────────
  String? descriptionError;

  // ── Step 3 fields ─────────────────────────────────────────────────────────────
  final List<SplitParticipant> participants = [];
  bool equalSplit = true;

  SplitFormController() {
    amountController.addListener(_onAmountChanged);
  }

  // ── Derived ───────────────────────────────────────────────────────────────────

  List<BankEntity> get accountOnlyEntities {
    final seen = <String>{};
    final result = <BankEntity>[];
    for (final a in accounts) {
      if (seen.add(a.bankEntity.id)) result.add(a.bankEntity);
    }
    return result;
  }

  // ── Data loading override ─────────────────────────────────────────────────────

  @override
  Future<void> loadSources() async {
    try {
      final results = await Future.wait([
        _categoryService.getCategoriesWithChildren(type: CategoryType.expense),
        accountService.getAccounts(),
        _contactService.fetchAll(),
      ]);
      expenseCategories = results[0] as List<Category>;
      accounts = results[1] as List<BankAccount>;
      allContacts = results[2] as List<Contact>;
      isLoadingSources = false;
      notifyListeners();
    } catch (_) {
      isLoadingSources = false;
      notifyListeners();
    }
  }

  // ── Amount listener ───────────────────────────────────────────────────────────

  void _onAmountChanged() {
    if (equalSplit) _distributeEqually();
    if (amountError != null) clearAmountError();
  }

  void _distributeEqually() {
    if (participants.isEmpty) return;
    final total = double.tryParse(amountController.text.trim()) ?? 0;
    final share = total / participants.length;
    for (final p in participants) {
      p.amountController.text = share > 0 ? share.toStringAsFixed(2) : '';
    }
  }

  // ── Step 0 validation ─────────────────────────────────────────────────────────

  bool validateStep0() {
    final text = amountController.text.trim();
    final desc = descriptionController.text.trim();
    String? amountErr;
    String? descErr;

    if (text.isEmpty) {
      amountErr = "Ingresa un monto";
    } else {
      final parsed = double.tryParse(text);
      if (parsed == null) {
        amountErr = "Monto inválido";
      } else if (parsed <= 0) {
        amountErr = "El monto debe ser mayor a 0";
      }
    }

    if (desc.isEmpty) descErr = "Ingresa una descripción";

    amountError = amountErr;
    descriptionError = descErr;
    notifyListeners();
    return amountErr == null && descErr == null;
  }

  void clearDescriptionError() {
    if (descriptionError != null) {
      descriptionError = null;
      notifyListeners();
    }
  }

  // ── Participant management ────────────────────────────────────────────────────

  void addParticipant(Contact contact) {
    participants.add(SplitParticipant(contact: contact));
    if (equalSplit) _distributeEqually();
    notifyListeners();
  }

  void removeParticipant(int index) {
    participants[index].dispose();
    participants.removeAt(index);
    if (equalSplit) _distributeEqually();
    notifyListeners();
  }

  void onSplitModeChanged(bool equal) {
    equalSplit = equal;
    if (equal) _distributeEqually();
    notifyListeners();
  }

  Future<void> reloadContacts() async {
    try {
      allContacts = await _contactService.fetchAll();
      notifyListeners();
    } catch (_) {}
  }

  // ── prevStep override ─────────────────────────────────────────────────────────

  @override
  void prevStep(BuildContext context) {
    if (currentStep == 1 &&
        selectedParentCategory != null &&
        selectedParentCategory!.children.isNotEmpty) {
      backFromCategoryChildren();
      return;
    }
    // Use == 2 so step 3 back goes directly to step 2 (not entity list)
    if (currentStep == 2 && selectedEntity != null) {
      backFromEntityAccounts();
      return;
    }
    if (currentStep > 0) {
      goToStep(currentStep - 1);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    amountController.removeListener(_onAmountChanged);
    for (final p in participants) {
      p.dispose();
    }
    super.dispose();
  }
}
