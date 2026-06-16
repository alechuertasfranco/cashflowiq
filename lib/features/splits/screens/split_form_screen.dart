import 'package:cashflowiq/core/network/api_client.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/base_transaction_form_screen.dart';
import 'package:cashflowiq/core/widgets/form_step_amount.dart';
import 'package:cashflowiq/features/splits/screens/contacts_screen.dart';
import 'package:cashflowiq/features/splits/screens/split_form_controller.dart';
import 'package:cashflowiq/features/splits/screens/widgets/split_step_account.dart';
import 'package:cashflowiq/features/splits/screens/widgets/split_step_categories.dart';
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
      if (controller.selectedAccount != null)
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
    final alreadyAdded = controller.participants.map((p) => p.contact.id).toSet();
    final available =
        controller.allContacts.where((c) => !alreadyAdded.contains(c.id)).toList();

    if (available.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos los contactos ya fueron agregados')),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Seleccionar participante', style: AppTextStyles.h400(ctx)),
            ),
            Expanded(
              child: _ContactPickerList(
                contacts: available,
                scrollController: scrollController,
                onSelected: (Contact c) {
                  Navigator.pop(ctx);
                  controller.addParticipant(c);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _goToCreateContact() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ContactsScreen()),
    );
    await controller.reloadContacts();
    if (controller.allContacts.isNotEmpty) _openContactsPicker();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Gasto compartido', style: AppTextStyles.h400(context)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => BaseTransactionFormScreen(
            controller: controller,
            totalSteps: 4,
            submitLabel: "Registrar gasto compartido",
            accentColor: AppColors.primary,
            onNextStep: _nextStep,
            onSubmit: _submit,
            steps: [
              FormStepAmount(
                title: '¿Cuánto fue en total?',
                dateAccentColor: AppColors.primary,
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
              SplitStepCategories(
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
              ),
              SplitStepAccount(
                entities: controller.accountOnlyEntities,
                selectedEntity: controller.selectedEntity,
                selectedAccount: controller.selectedAccount,
                viewKey: controller.entityViewKey,
                goingForward: controller.entityForward,
                accountsFor: controller.accountsFor,
                onEntityTap: controller.onEntityTap,
                onAccountTap: controller.onAccountTap,
                onBack: controller.backFromEntityAccounts,
                onAddAccount: () => controller.navigateToAccountForm(
                  context,
                  onReload: controller.loadSources,
                ),
              ),
              SplitStepParticipants(
                participants: controller.participants,
                equalSplit: controller.equalSplit,
                onAddParticipant: controller.allContacts.isEmpty
                    ? _goToCreateContact
                    : _openContactsPicker,
                onRemove: controller.removeParticipant,
                onSplitModeChanged: controller.onSplitModeChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Contact picker list (extracted to avoid rebuilding the bottom sheet) ─────

class _ContactPickerList extends StatelessWidget {
  final List<Contact> contacts;
  final ScrollController scrollController;
  final void Function(Contact) onSelected;

  const _ContactPickerList({
    required this.contacts,
    required this.scrollController,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: contacts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final c = contacts[index];
        final subtitle = [
          if (c.email != null && c.email!.isNotEmpty) c.email!,
          if (c.phone != null && c.phone!.isNotEmpty) c.phone!,
        ].join(' · ');
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          tileColor: AppColors.surface,
          leading: CircleAvatar(
            backgroundColor: AppColors.secondary,
            child: Text(
              c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
          title: Text(c.name, style: AppTextStyles.subtitle1(context)),
          subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
          onTap: () => onSelected(c),
        );
      },
    );
  }
}
