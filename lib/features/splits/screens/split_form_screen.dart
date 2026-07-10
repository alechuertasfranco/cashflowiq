import 'package:cashflowiq/core/network/api_client.dart';
import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/app_bottom_sheet.dart';
import 'package:cashflowiq/core/widgets/app_header_bar.dart';
import 'package:cashflowiq/core/widgets/app_text_field.dart';
import 'package:cashflowiq/core/widgets/base_transaction_form_screen.dart';
import 'package:cashflowiq/core/widgets/form_step_amount.dart';
import 'package:cashflowiq/core/widgets/form_step_category.dart';
import 'package:cashflowiq/core/widgets/form_step_payment_source.dart';
import 'package:cashflowiq/features/splits/screens/contacts_screen.dart';
import 'package:cashflowiq/features/splits/screens/split_form_controller.dart';
import 'package:cashflowiq/features/splits/screens/widgets/split_step_participants.dart';
import 'package:cashflowiq/shared/models/category.dart';
import 'package:cashflowiq/shared/models/contact.dart';
import 'package:flutter/material.dart';

class SplitFormScreen extends StatefulWidget {
  const SplitFormScreen({super.key});

  @override
  State<SplitFormScreen> createState() => _SplitFormScreenState();
}

class _SplitFormScreenState extends State<SplitFormScreen> {
  final controller = SplitFormController();

  @override
  void initState() {
    super.initState();
    controller.loadSources();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (controller.currentStep == 0) {
      if (!controller.validateStep0()) return;
      controller.goToStep(1);
    } else if (controller.currentStep < 3) {
      controller.goToStep(controller.currentStep + 1);
    }
  }

  Future<void> _submit() async {
    if (controller.participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un participante')),
      );
      return;
    }

    final usingCard = controller.selectedCreditCard != null;
    if (!usingCard && controller.selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una cuenta o tarjeta')),
      );
      return;
    }

    for (final p in controller.participants) {
      final v = double.tryParse(p.amountController.text.trim());
      if (v == null || v <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('El monto de ${p.contact.name} es inválido')),
        );
        return;
      }
    }

    controller.setSaving(true);

    final splits = controller.participants.map((p) => {
          'contact_id': p.contact.id,
          'amount': double.parse(p.amountController.text.trim()),
        }).toList();

    final payload = <String, dynamic>{
      'amount': double.parse(controller.amountController.text.trim()),
      'description': controller.descriptionController.text.trim(),
      'type': 'EXPENSE',
      'date': controller.selectedDate.toIso8601String().split('T').first,
      if (controller.selectedCategory != null)
        'category_id': int.tryParse(controller.selectedCategory!.id),
      if (usingCard)
        'credit_card_id': int.tryParse(controller.selectedCreditCard!.id)
      else if (controller.selectedAccount != null)
        'account_id': int.tryParse(controller.selectedAccount!.id),
      'splits': splits,
    };

    try {
      await ApiClient.postJson('/transactions', body: payload);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('SplitFormScreen submit error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al registrar el gasto compartido')),
      );
    } finally {
      controller.setSaving(false);
    }
  }

  Future<void> _openContactsPicker() async {
    await showAppBottomSheet(
      context,
      builder: (ctx) => _ContactPickerSheet(
        controller: controller,
        onCreateNew: () {
          Navigator.pop(ctx);
          _goToCreateContact();
        },
        onSelected: (Contact c) {
          Navigator.pop(ctx);
          controller.addParticipant(c);
        },
      ),
    );
  }

  Future<void> _goToCreateContact() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ContactsScreen()),
    );
    await controller.reloadContacts();
    if (!mounted) return;
    if (controller.allContacts.isNotEmpty) _openContactsPicker();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorBackground,
      appBar: const AppHeaderBar(title: 'Gasto compartido'),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => BaseTransactionFormScreen(
            controller: controller,
            totalSteps: 4,
            submitLabel: "Registrar gasto compartido",
            accentColor: context.colorPrimary,
            onNextStep: _nextStep,
            onSubmit: _submit,
            steps: [
              FormStepAmount(
                title: '¿Cuánto fue en total?',
                accentColor: context.colorPrimary,
                descriptionHint: 'Ej: Cena de cumpleaños',
                descriptionRequired: true,
                amountController: controller.amountController,
                descriptionController: controller.descriptionController,
                selectedDate: controller.selectedDate,
                amountError: controller.amountError,
                descriptionError: controller.descriptionError,
                onDateTap: () => controller.pickDate(context),
                onAmountChanged: controller.clearAmountError,
                onDescriptionChanged: controller.clearDescriptionError,
              ),
              FormStepCategory(
                categories: controller.expenseCategories,
                selectedParentCategory: controller.selectedParentCategory,
                selectedCategory: controller.selectedCategory,
                viewKey: controller.categoryViewKey,
                goingForward: controller.categoryForward,
                onParentTap: controller.onParentCategoryTap,
                onChildTap: controller.onChildCategoryTap,
                onBack: controller.backFromCategoryChildren,
                onAddCategory: () => controller.navigateToCategoryForm(
                  context,
                  initialType: CategoryType.expense,
                ),
                onAddSubcategory: () => controller.navigateToCategoryForm(
                  context,
                  initialType: CategoryType.expense,
                  parent: controller.selectedParentCategory,
                ),
                emptyMessage: 'Aún no tienes categorías de gasto.',
              ),
              FormStepPaymentSource(
                entities: controller.uniqueEntities,
                selectedEntity: controller.selectedEntity,
                selectedAccount: controller.selectedAccount,
                selectedCreditCard: controller.selectedCreditCard,
                viewKey: controller.entityViewKey,
                goingForward: controller.entityForward,
                accountsFor: controller.accountsFor,
                cardsFor: controller.cardsFor,
                onEntityTap: controller.onEntityTap,
                onAccountTap: controller.onAccountTap,
                onCardTap: controller.onCardTap,
                onBack: controller.backFromEntityAccounts,
                mostUsedItems: controller.mostUsedItems,
                onAddAccount: () => controller.navigateToAccountForm(
                  context,
                  onReload: controller.loadSources,
                ),
                onAddCreditCard: () => controller.navigateToCreditCardForm(
                  context,
                  onReload: controller.loadSources,
                ),
                title: '¿Con qué pagaste?',
              ),
              SplitStepParticipants(
                participants: controller.participants,
                equalSplit: controller.equalSplit,
                includeSelf: controller.includeSelf,
                selfShare: controller.selfShare,
                onAddParticipant: _openContactsPicker,
                onRemove: controller.removeParticipant,
                onSplitModeChanged: controller.onSplitModeChanged,
                onIncludeSelfChanged: controller.onIncludeSelfChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Contact picker bottom sheet ───────────────────────────────────────────────

/// Owns search + refresh state as real State fields (not builder-local
/// closures) so keyboard-driven rebuilds of the modal don't reset the query.
class _ContactPickerSheet extends StatefulWidget {
  final SplitFormController controller;
  final VoidCallback onCreateNew;
  final void Function(Contact) onSelected;

  const _ContactPickerSheet({
    required this.controller,
    required this.onCreateNew,
    required this.onSelected,
  });

  @override
  State<_ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<_ContactPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Contact> get _available {
    final alreadyAdded =
        widget.controller.participants.map((p) => p.contact.id).toSet();
    final base =
        widget.controller.allContacts.where((c) => !alreadyAdded.contains(c.id));
    if (_query.isEmpty) return base.toList();
    final q = _query.toLowerCase();
    return base.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final available = _available;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text('Seleccionar participante',
                      style: context.heading4()),
                ),
                TextButton.icon(
                  onPressed: widget.onCreateNew,
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text('Nuevo'),
                  style:
                      TextButton.styleFrom(foregroundColor: context.colorPrimary),
                ),
              ],
            ),
          ),
          if (widget.controller.allContacts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: AppTextField(
                controller: _searchController,
                hintText: 'Buscar contacto',
                prefixIcon: Icon(Icons.search, color: context.colorMuted, size: 20),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              color: context.colorPrimary,
              onRefresh: () async {
                await widget.controller.reloadContacts();
                if (mounted) setState(() {});
              },
              child: available.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Text(
                            widget.controller.allContacts.isEmpty
                                ? 'Aún no tienes contactos'
                                : _query.isEmpty
                                    ? 'Todos los contactos ya fueron agregados'
                                    : 'Sin resultados',
                            style: context.textBody2(color: context.colorMuted),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: available.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final c = available[index];
                        final subtitle = [
                          if (c.email != null && c.email!.isNotEmpty)
                            c.email!,
                          if (c.phone != null && c.phone!.isNotEmpty)
                            c.phone!,
                        ].join(' · ');
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: context.radiusMdRadius,
                            side: BorderSide(color: context.colorBorder),
                          ),
                          tileColor: context.colorSurface,
                          leading: CircleAvatar(
                            backgroundColor: context.colorSecondary,
                            child: Text(
                              c.name.isNotEmpty
                                  ? c.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(color: context.colorPrimary),
                            ),
                          ),
                          title:
                              Text(c.name, style: context.textSubtitle1()),
                          subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
                          onTap: () => widget.onSelected(c),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
