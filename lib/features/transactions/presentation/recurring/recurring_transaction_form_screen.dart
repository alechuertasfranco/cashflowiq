// lib/features/transactions/presentation/recurring/recurring_transaction_form_screen.dart

import 'package:cashflowiq/core/services/notification_service.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/currency_dropdown.dart';
import 'package:cashflowiq/core/widgets/decorations.dart';
import 'package:cashflowiq/features/profile/data/bank_account_service.dart';
import 'package:cashflowiq/features/profile/data/category_service.dart';
import 'package:cashflowiq/features/transactions/data/recurring_transaction_service.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';
import 'package:cashflowiq/shared/models/category.dart';
import 'package:cashflowiq/shared/models/currency.dart';
import 'package:cashflowiq/shared/models/recurring_transaction.dart';
import 'package:cashflowiq/shared/services/currency_service.dart';
import 'package:flutter/material.dart';

class RecurringTransactionFormScreen extends StatefulWidget {
  /// If non-null, the form is in edit mode.
  final RecurringTransaction? existing;

  const RecurringTransactionFormScreen({super.key, this.existing});

  @override
  State<RecurringTransactionFormScreen> createState() =>
      _RecurringTransactionFormScreenState();
}

class _RecurringTransactionFormScreenState
    extends State<RecurringTransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  final _categoryService = CategoryService();
  final _accountService = BankAccountService();
  final _currencyService = CurrencyService();
  final _recurringService = RecurringTransactionService();

  List<Category> _categories = [];
  List<BankAccount> _accounts = [];
  List<Currency> _currencies = [];
  bool _isLoading = true;
  bool _isSaving = false;

  String _type = 'INCOME'; // INCOME | EXPENSE
  bool _isFixedAmount = true;
  RecurringFrequency _frequency = RecurringFrequency.monthly;
  int? _notificationDaysBefore;
  Category? _selectedCategory;
  BankAccount? _selectedAccount;
  Currency? _selectedCurrency; // only used when no account is selected
  DateTime _nextExecutionDate = DateTime.now();
  DateTime? _endDate;

  List<Category> get _filteredCategories {
    final wanted = _type == 'INCOME' ? CategoryType.income : CategoryType.expense;
    return _categories.where((c) => c.type == wanted).toList();
  }

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _categoryService.getCategories(),
        _accountService.getAccounts(),
        _currencyService.getCurrencies(),
      ]);
      final categories = results[0] as List<Category>;
      final accounts = results[1] as List<BankAccount>;
      final currencies = results[2] as List<Currency>;

      setState(() {
        _categories = categories;
        _accounts = accounts;
        _currencies = currencies;
        _isLoading = false;
      });

      // Pre-populate from existing rule
      if (_isEditing) {
        final e = widget.existing!;
        _nameController.text = e.name;
        _isFixedAmount = e.amount != null;
        if (_isFixedAmount && e.amount != null) {
          _amountController.text = e.amount.toString();
        }
        _type = e.type;
        _frequency = e.frequency;
        _nextExecutionDate = e.nextExecutionDate;
        _endDate = e.endDate;
        _notificationDaysBefore = e.notificationDaysBefore;

        if (e.categoryId != null) {
          try {
            _selectedCategory = _categories.firstWhere(
              (c) => c.id == e.categoryId.toString(),
            );
          } catch (_) {}
        }
        if (e.accountId != null) {
          try {
            _selectedAccount = _accounts.firstWhere(
              (a) => a.id == e.accountId.toString(),
            );
          } catch (_) {}
        }
        setState(() {});
      }
    } catch (e) {
      debugPrint("Error loading form data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickNextExecutionDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextExecutionDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _nextExecutionDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _nextExecutionDate.add(const Duration(days: 30)),
      firstDate: _nextExecutionDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  String _formatDate(DateTime date) =>
      "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    // Cancel the old notification when editing before saving
    if (_isEditing) {
      NotificationService.instance
          .cancelRecurringNotification(widget.existing!.id);
    }

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'amount': _isFixedAmount ? double.parse(_amountController.text.trim()) : null,
      'type': _type,
      'frequency': _frequency.toApi(),
      'next_execution_date': _nextExecutionDate.toIso8601String(),
      if (_endDate != null) 'end_date': _endDate!.toIso8601String().split('T').first,
      if (_selectedCategory != null) 'category_id': int.tryParse(_selectedCategory!.id),
      if (_selectedAccount != null) 'account_id': int.tryParse(_selectedAccount!.id),
      if (_selectedAccount == null && _selectedCurrency != null)
        'currency_id': _selectedCurrency!.id,
      'notification_days_before': _notificationDaysBefore,
    };

    try {
      RecurringTransaction result;
      if (_isEditing) {
        result = await _recurringService.update(widget.existing!.id, payload);
      } else {
        result = await _recurringService.create(payload);
      }

      // Schedule the notification for the saved rule
      await NotificationService.instance.scheduleRecurringNotification(result);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("recurring form submit error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al guardar la regla recurrente")),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? "Editar recurrente" : "Nueva regla recurrente",
          style: AppTextStyles.h400(context),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SafeArea(
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),

                            // Type toggle
                            _label("Tipo"),
                            const SizedBox(height: 8),
                            _typeToggle(),
                            const SizedBox(height: 16),

                            // Name
                            _label("Nombre"),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              decoration: inputDecoration(context, "Ej: Alquiler mensual"),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return "Ingresa un nombre";
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Amount type toggle
                            _label("Tipo de monto"),
                            const SizedBox(height: 8),
                            _amountTypeToggle(),
                            const SizedBox(height: 16),

                            // Amount (only when fixed)
                            if (_isFixedAmount) ...[
                              _label("Monto"),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _amountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(decimal: true),
                                decoration: inputDecoration(context, "0.00"),
                                validator: (v) {
                                  if (!_isFixedAmount) return null;
                                  if (v == null || v.isEmpty) return "Ingresa un monto";
                                  final parsed = double.tryParse(v);
                                  if (parsed == null) return "Monto inválido";
                                  if (parsed <= 0) return "El monto debe ser mayor a 0";
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Category (filtered by type)
                            _label("Categoría"),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<Category>(
                              key: ValueKey(_type),
                              initialValue: _selectedCategory,
                              items: _filteredCategories.map((cat) {
                                return DropdownMenuItem<Category>(
                                  value: cat,
                                  child: Text(cat.name, style: AppTextStyles.body1(context)),
                                );
                              }).toList(),
                              onChanged: (cat) => setState(() => _selectedCategory = cat),
                              decoration: inputDecoration(context, "Selecciona una categoría"),
                            ),
                            const SizedBox(height: 16),

                            // Account
                            _label("Cuenta bancaria (opcional)"),
                            const SizedBox(height: 8),
                            _accounts.isEmpty
                                ? Text(
                                    "No tienes cuentas registradas",
                                    style: AppTextStyles.body2(context, color: AppColors.muted),
                                  )
                                : DropdownButtonFormField<BankAccount>(
                                    initialValue: _selectedAccount,
                                    items: _accounts.map((acc) {
                                      return DropdownMenuItem<BankAccount>(
                                        value: acc,
                                        child: Text("${acc.bankEntity.code} · ${acc.name}", style: AppTextStyles.body1(context)),
                                      );
                                    }).toList(),
                                    onChanged: (acc) => setState(() {
                                      _selectedAccount = acc;
                                      _selectedCurrency = null;
                                    }),
                                    decoration: inputDecoration(context, "Selecciona una cuenta"),
                                  ),
                            const SizedBox(height: 16),

                            // Currency
                            _label("Moneda"),
                            const SizedBox(height: 8),
                            if (_selectedAccount != null)
                              // Derived from account — show read-only chip
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      "${_selectedAccount!.currency.flag} ${_selectedAccount!.currency.code}",
                                      style: AppTextStyles.body1(context),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "(desde la cuenta)",
                                      style: AppTextStyles.caption(context, color: AppColors.muted),
                                    ),
                                  ],
                                ),
                              )
                            else
                              CurrencyDropdown(
                                currencies: _currencies,
                                value: _selectedCurrency,
                                onChanged: (c) => setState(() => _selectedCurrency = c),
                              ),
                            const SizedBox(height: 16),

                            // Frequency
                            _label("Frecuencia"),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<RecurringFrequency>(
                              initialValue: _frequency,
                              items: RecurringFrequency.values.map((f) {
                                return DropdownMenuItem<RecurringFrequency>(
                                  value: f,
                                  child: Text(f.toLabel(), style: AppTextStyles.body1(context)),
                                );
                              }).toList(),
                              onChanged: (f) {
                                if (f != null) setState(() => _frequency = f);
                              },
                              decoration: inputDecoration(context, "Frecuencia"),
                            ),
                            const SizedBox(height: 16),

                            // Notification reminder
                            _label("Recordatorio"),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int?>(
                              value: _notificationDaysBefore,
                              items: const [
                                DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text("Sin recordatorio"),
                                ),
                                DropdownMenuItem<int?>(
                                  value: 0,
                                  child: Text("El mismo día"),
                                ),
                                DropdownMenuItem<int?>(
                                  value: 1,
                                  child: Text("1 día antes"),
                                ),
                                DropdownMenuItem<int?>(
                                  value: 3,
                                  child: Text("3 días antes"),
                                ),
                                DropdownMenuItem<int?>(
                                  value: 7,
                                  child: Text("7 días antes"),
                                ),
                              ],
                              onChanged: (v) => setState(() => _notificationDaysBefore = v),
                              decoration: inputDecoration(context, "Sin recordatorio"),
                            ),
                            const SizedBox(height: 10),
                            _NotificationInfoBox(
                              notificationDaysBefore: _notificationDaysBefore,
                              isFixedAmount: _isFixedAmount,
                            ),
                            const SizedBox(height: 16),

                            // Next execution date
                            _label("Primera ejecución"),
                            const SizedBox(height: 8),
                            _datePicker(
                              icon: Icons.event,
                              label: _formatDate(_nextExecutionDate),
                              onTap: _pickNextExecutionDate,
                            ),
                            const SizedBox(height: 16),

                            // End date
                            _label("Fecha de fin (opcional)"),
                            const SizedBox(height: 8),
                            _datePicker(
                              icon: Icons.event_busy,
                              label: _endDate != null
                                  ? _formatDate(_endDate!)
                                  : "Sin fecha de fin",
                              labelColor: _endDate != null ? null : AppColors.muted,
                              onTap: _pickEndDate,
                              trailing: _endDate != null
                                  ? GestureDetector(
                                      onTap: () => setState(() => _endDate = null),
                                      child: const Icon(Icons.close,
                                          size: 16, color: AppColors.muted),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Action buttons
                Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10)
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _isEditing ? "Guardar cambios" : "Crear regla",
                              style:
                                  AppTextStyles.subtitle2(context, color: Colors.white),
                            ),
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _label(String text) =>
      Text(text, style: AppTextStyles.subtitle2(context, color: AppColors.textSecondary));

  Widget _typeToggle() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() { _type = 'INCOME'; _selectedCategory = null; }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _type == 'INCOME' ? AppColors.success : AppColors.surface,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(
                  "Ingreso",
                  style: AppTextStyles.body2(
                    context,
                    color: _type == 'INCOME' ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() { _type = 'EXPENSE'; _selectedCategory = null; }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _type == 'EXPENSE' ? AppColors.error : AppColors.surface,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(
                  "Gasto",
                  style: AppTextStyles.body2(
                    context,
                    color: _type == 'EXPENSE' ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _amountTypeToggle() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isFixedAmount = true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _isFixedAmount ? AppColors.primary : AppColors.surface,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(
                  "Monto fijo",
                  style: AppTextStyles.body2(
                    context,
                    color: _isFixedAmount ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _isFixedAmount = false;
              _amountController.clear();
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: !_isFixedAmount ? AppColors.primary : AppColors.surface,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(
                  "Monto variable",
                  style: AppTextStyles.body2(
                    context,
                    color: !_isFixedAmount ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _datePicker({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? labelColor,
    Widget? trailing,
  }) {

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.muted),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.subtitle2(
                context,
                color: labelColor ?? AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}

class _NotificationInfoBox extends StatelessWidget {
  final int? notificationDaysBefore;
  final bool isFixedAmount;

  const _NotificationInfoBox({
    required this.notificationDaysBefore,
    required this.isFixedAmount,
  });

  String get _message {
    if (notificationDaysBefore == null) {
      return 'Sin recordatorio: la transacción se creará automáticamente en la fecha de ejecución, sin necesidad de acción.';
    }
    final when = switch (notificationDaysBefore) {
      0 => 'el mismo día de la ejecución',
      1 => '1 día antes',
      _ => '$notificationDaysBefore días antes',
    };
    if (isFixedAmount) {
      return 'Recibirás una notificación $when. Al tocarla, la transacción se registrará automáticamente.';
    } else {
      return 'Recibirás una notificación $when para ingresar el monto manualmente.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 15, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _message,
              style: AppTextStyles.caption(context, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
