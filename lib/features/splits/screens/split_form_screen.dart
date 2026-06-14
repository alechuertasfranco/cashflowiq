// lib/features/splits/screens/split_form_screen.dart

import 'package:cashflowiq/core/network/api_client.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/step_indicator.dart';
import 'package:cashflowiq/features/profile/data/bank_account_service.dart';
import 'package:cashflowiq/features/profile/data/category_service.dart';
import 'package:cashflowiq/features/profile/presentation/bank_accounts/form_account_screen.dart';
import 'package:cashflowiq/features/profile/presentation/categories/form_categories_screen.dart';
import 'package:cashflowiq/features/splits/data/contact_service.dart';
import 'package:cashflowiq/features/splits/screens/contacts_screen.dart';
import 'package:cashflowiq/features/splits/screens/widgets/split_step_account.dart';
import 'package:cashflowiq/features/splits/screens/widgets/split_step_amount.dart';
import 'package:cashflowiq/features/splits/screens/widgets/split_step_categories.dart';
import 'package:cashflowiq/features/splits/screens/widgets/split_step_participants.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';
import 'package:cashflowiq/shared/models/bank_entity.dart';
import 'package:cashflowiq/shared/models/category.dart';
import 'package:cashflowiq/shared/models/contact.dart';
import 'package:flutter/material.dart';

class SplitFormScreen extends StatefulWidget {
  const SplitFormScreen({super.key});

  @override
  State<SplitFormScreen> createState() => _SplitFormScreenState();
}

class _SplitFormScreenState extends State<SplitFormScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pageController = PageController();

  final _categoryService = CategoryService();
  final _accountService = BankAccountService();
  final _contactService = ContactService();

  List<Category> _expenseCategories = [];
  List<BankAccount> _accounts = [];
  List<Contact> _allContacts = [];
  bool _isLoading = true;
  bool _isSaving = false;

  // ── Step 2: category (two-level) ─────────────────────────────────────────
  Category? _selectedParentCategory;
  Category? _selectedCategory;
  String _categoryViewKey = 'parents';
  bool _categoryForward = true;

  // ── Step 3: account (two-level, entity→account) ──────────────────────────
  BankEntity? _selectedEntity;
  BankAccount? _selectedAccount;
  String _entityViewKey = 'entities';
  bool _entityForward = true;

  // ── Step 4: participants ─────────────────────────────────────────────────
  final List<SplitParticipant> _participants = [];
  bool _equalSplit = true;

  DateTime _date = DateTime.now();
  int _currentStep = 0;
  String? _amountError;
  String? _descriptionError;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
    _loadData();
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _descriptionController.dispose();
    _pageController.dispose();
    for (final p in _participants) {
      p.dispose();
    }
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _categoryService.getCategoriesWithChildren(type: CategoryType.expense),
        _accountService.getAccounts(),
        _contactService.fetchAll(),
      ]);
      if (!mounted) return;
      setState(() {
        _expenseCategories = results[0] as List<Category>;
        _accounts = results[1] as List<BankAccount>;
        _allContacts = results[2] as List<Contact>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('SplitFormScreen load error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _onAmountChanged() {
    if (_equalSplit) _distributeEqually();
    if (_amountError != null) setState(() => _amountError = null);
  }

  void _distributeEqually() {
    if (_participants.isEmpty) return;
    final total = double.tryParse(_amountController.text.trim()) ?? 0;
    final share = _participants.isNotEmpty ? total / _participants.length : 0;
    for (final p in _participants) {
      p.amountController.text = share > 0 ? share.toStringAsFixed(2) : '';
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  List<BankEntity> get _entities {
    final seen = <String>{};
    return [
      for (final a in _accounts)
        if (seen.add(a.bankEntity.id)) a.bankEntity,
    ];
  }

  List<BankAccount> _accountsFor(BankEntity e) =>
      _accounts.where((a) => a.bankEntity.id == e.id).toList();

  // ── Navigation ────────────────────────────────────────────────────────────

  bool _validateStep1() {
    final text = _amountController.text.trim();
    final desc = _descriptionController.text.trim();

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

    if (desc.isEmpty) {
      descErr = "Ingresa una descripción";
    }

    setState(() {
      _amountError = amountErr;
      _descriptionError = descErr;
    });

    return amountErr == null && descErr == null;
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_validateStep1()) _goToStep(1);
    } else if (_currentStep < 3) {
      _goToStep(_currentStep + 1);
    }
  }

  void _prevStep() {
    if (_currentStep == 1 &&
        _selectedParentCategory != null &&
        _selectedParentCategory!.children.isNotEmpty) {
      _backFromCategoryChildren();
      return;
    }
    if (_currentStep == 2 && _selectedEntity != null) {
      _backFromEntityAccounts();
      return;
    }
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    } else {
      Navigator.pop(context);
    }
  }

  // ── Step 2 callbacks ──────────────────────────────────────────────────────

  void _onParentCategoryTap(Category category) {
    if (category.children.isNotEmpty) {
      setState(() {
        _selectedParentCategory = category;
        _selectedCategory = null;
        _categoryForward = true;
        _categoryViewKey = 'children_${category.id}';
      });
    } else {
      setState(() {
        _selectedParentCategory = category;
        _selectedCategory = category;
      });
    }
  }

  void _onChildCategoryTap(Category category) {
    setState(() => _selectedCategory = category);
  }

  void _backFromCategoryChildren() {
    setState(() {
      _selectedParentCategory = null;
      _selectedCategory = null;
      _categoryForward = false;
      _categoryViewKey = 'parents';
    });
  }

  // ── Step 3 callbacks ──────────────────────────────────────────────────────

  void _onEntityTap(BankEntity entity) {
    setState(() {
      if (_selectedEntity?.id != entity.id) _selectedAccount = null;
      _selectedEntity = entity;
      _entityForward = true;
      _entityViewKey = 'accounts_${entity.id}';
    });
  }

  void _onAccountTap(BankAccount account) {
    setState(() => _selectedAccount = account);
  }

  void _backFromEntityAccounts() {
    setState(() {
      _selectedEntity = null;
      _entityForward = false;
      _entityViewKey = 'entities';
    });
  }

  // ── Navigation to creation forms ──────────────────────────────────────────

  Future<void> _navigateToCategoryForm({Category? parent}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FormCategoriesScreen(
          initialType: CategoryType.expense,
          parent: parent,
        ),
      ),
    );
    if (result == true && mounted) {
      final cats = await _categoryService.getCategoriesWithChildren(
          type: CategoryType.expense);
      if (!mounted) return;
      setState(() => _expenseCategories = cats);
    }
  }

  Future<void> _navigateToAccountForm() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const FormAccountScreen()),
    );
    if (result == true && mounted) {
      final accounts = await _accountService.getAccounts();
      if (!mounted) return;
      setState(() => _accounts = accounts);
    }
  }

  // ── Participant management ────────────────────────────────────────────────

  Future<void> _openContactsPicker() async {
    final alreadyAdded = _participants.map((p) => p.contact.id).toSet();
    final available =
        _allContacts.where((c) => !alreadyAdded.contains(c.id)).toList();

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
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Column(
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
                  child: Text('Seleccionar participante',
                      style: AppTextStyles.h400(ctx)),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: available.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final c = available[index];
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
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                        title: Text(c.name, style: AppTextStyles.subtitle1(ctx)),
                        subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _participants.add(SplitParticipant(contact: c));
                            if (_equalSplit) _distributeEqually();
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _goToCreateContact() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ContactsScreen()),
    );
    final contacts = await _contactService.fetchAll();
    if (!mounted) return;
    setState(() => _allContacts = contacts);
    if (_allContacts.isNotEmpty) _openContactsPicker();
  }

  void _removeParticipant(int index) {
    setState(() {
      _participants[index].dispose();
      _participants.removeAt(index);
      if (_equalSplit) _distributeEqually();
    });
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un participante')),
      );
      return;
    }

    for (final p in _participants) {
      final v = double.tryParse(p.amountController.text.trim());
      if (v == null || v <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('El monto de ${p.contact.name} es inválido')),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    final splits = _participants.map((p) {
      return {
        'contact_id': p.contact.id,
        'amount': double.parse(p.amountController.text.trim()),
      };
    }).toList();

    final payload = <String, dynamic>{
      'amount': double.parse(_amountController.text.trim()),
      'description': _descriptionController.text.trim(),
      'type': 'EXPENSE',
      'date': _date.toIso8601String().split('T').first,
      if (_selectedCategory != null)
        'category_id': int.tryParse(_selectedCategory!.id),
      if (_selectedAccount != null)
        'account_id': int.tryParse(_selectedAccount!.id),
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
        const SnackBar(
            content: Text('Error al registrar el gasto compartido')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : PopScope(
                canPop: _currentStep == 0,
                onPopInvokedWithResult: (didPop, _) {
                  if (!didPop) _prevStep();
                },
                child: Column(
                  children: [
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          SplitStepAmount(
                            amountController: _amountController,
                            descriptionController: _descriptionController,
                            selectedDate: _date,
                            amountError: _amountError,
                            descriptionError: _descriptionError,
                            onDateTap: _pickDate,
                            onAmountChanged: _onAmountChanged,
                            onDescriptionChanged: () {
                              if (_descriptionError != null) {
                                setState(() => _descriptionError = null);
                              }
                            },
                          ),
                          SplitStepCategories(
                            categories: _expenseCategories,
                            selectedParentCategory: _selectedParentCategory,
                            selectedCategory: _selectedCategory,
                            viewKey: _categoryViewKey,
                            goingForward: _categoryForward,
                            onParentTap: _onParentCategoryTap,
                            onChildTap: _onChildCategoryTap,
                            onBack: _backFromCategoryChildren,
                            onAddCategory: () => _navigateToCategoryForm(),
                            onAddSubcategory: () => _navigateToCategoryForm(
                              parent: _selectedParentCategory,
                            ),
                          ),
                          SplitStepAccount(
                            entities: _entities,
                            selectedEntity: _selectedEntity,
                            selectedAccount: _selectedAccount,
                            viewKey: _entityViewKey,
                            goingForward: _entityForward,
                            accountsFor: _accountsFor,
                            onEntityTap: _onEntityTap,
                            onAccountTap: _onAccountTap,
                            onBack: _backFromEntityAccounts,
                            onAddAccount: _navigateToAccountForm,
                          ),
                          SplitStepParticipants(
                            participants: _participants,
                            equalSplit: _equalSplit,
                            onAddParticipant: _allContacts.isEmpty
                                ? _goToCreateContact
                                : _openContactsPicker,
                            onRemove: _removeParticipant,
                            onSplitModeChanged: (v) {
                              setState(() {
                                _equalSplit = v;
                                if (v) _distributeEqually();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    StepIndicator(
                      currentStep: _currentStep,
                      totalSteps: 4,
                      activeColor: AppColors.primary,
                    ),
                    _bottomBar(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _bottomBar() {
    final isLastStep = _currentStep == 3;
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _prevStep,
              child: Text("Atrás",
                  style: AppTextStyles.subtitle2(context,
                      color: AppColors.primary)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSaving ? null : (isLastStep ? _submit : _nextStep),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      isLastStep ? "Registrar gasto compartido" : "Siguiente",
                      style: AppTextStyles.subtitle2(context,
                          color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
