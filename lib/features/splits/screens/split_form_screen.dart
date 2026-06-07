// lib/features/splits/screens/split_form_screen.dart

import 'package:cashflowiq/core/network/api_client.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/decorations.dart';
import 'package:cashflowiq/features/profile/data/bank_account_service.dart';
import 'package:cashflowiq/features/profile/data/category_service.dart';
import 'package:cashflowiq/features/splits/data/contact_service.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';
import 'package:cashflowiq/shared/models/category.dart';
import 'package:cashflowiq/shared/models/contact.dart';
import 'package:flutter/material.dart';

/// A participant entry: a contact + an amount controller.
class _Participant {
  final Contact contact;
  final TextEditingController amountController;

  _Participant({required this.contact})
      : amountController = TextEditingController();

  void dispose() => amountController.dispose();
}

class SplitFormScreen extends StatefulWidget {
  const SplitFormScreen({super.key});

  @override
  State<SplitFormScreen> createState() => _SplitFormScreenState();
}

class _SplitFormScreenState extends State<SplitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _categoryService = CategoryService();
  final _accountService = BankAccountService();
  final _contactService = ContactService();

  List<Category> _expenseCategories = [];
  List<BankAccount> _accounts = [];
  List<Contact> _allContacts = [];

  Category? _selectedCategory;
  BankAccount? _selectedAccount;
  DateTime _date = DateTime.now();

  /// Split mode: true = equal, false = custom
  bool _equalSplit = true;

  final List<_Participant> _participants = [];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _descriptionController.dispose();
    for (final p in _participants) {
      p.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _categoryService.getCategories(type: CategoryType.expense),
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

  void _onAmountChanged() {
    if (_equalSplit) _distributeEqually();
  }

  void _distributeEqually() {
    if (_participants.isEmpty) return;
    final total = double.tryParse(_amountController.text.trim()) ?? 0;
    final share = _participants.isNotEmpty ? total / _participants.length : 0;
    for (final p in _participants) {
      p.amountController.text =
          share > 0 ? share.toStringAsFixed(2) : '';
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

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _openContactsPicker() async {
    // Show a bottom sheet with all contacts not yet added
    final alreadyAdded = _participants.map((p) => p.contact.id).toSet();
    final available =
        _allContacts.where((c) => !alreadyAdded.contains(c.id)).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Todos los contactos ya fueron agregados')),
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
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
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
                            _participants.add(_Participant(contact: c));
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

  void _removeParticipant(int index) {
    setState(() {
      _participants[index].dispose();
      _participants.removeAt(index);
      if (_equalSplit) _distributeEqually();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Agrega al menos un participante')),
      );
      return;
    }

    // Validate split amounts
    for (final p in _participants) {
      final v = double.tryParse(p.amountController.text.trim());
      if (v == null || v <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'El monto de ${p.contact.name} es inválido')),
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
        const SnackBar(content: Text('Error al registrar el gasto compartido')),
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
        title: Text('Gasto compartido', style: AppTextStyles.h400(context)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: _isLoading
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

                            // Amount
                            _label('Monto total'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: inputDecoration(context, '0.00'),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Ingresa el monto total';
                                }
                                final parsed = double.tryParse(v);
                                if (parsed == null) return 'Monto inválido';
                                if (parsed <= 0) {
                                  return 'El monto debe ser mayor a 0';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Description
                            _label('Descripción'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _descriptionController,
                              decoration:
                                  inputDecoration(context, 'Ej: Cena de cumpleaños'),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Ingresa una descripción';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Category
                            _label('Categoría'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<Category>(
                              key: const ValueKey('split_category'),
                              initialValue: _selectedCategory,
                              items: _expenseCategories.map((cat) {
                                return DropdownMenuItem<Category>(
                                  value: cat,
                                  child: Text(cat.name,
                                      style: AppTextStyles.body1(context)),
                                );
                              }).toList(),
                              onChanged: (cat) =>
                                  setState(() => _selectedCategory = cat),
                              decoration:
                                  inputDecoration(context, 'Selecciona una categoría'),
                            ),
                            const SizedBox(height: 16),

                            // Account
                            _label('Cuenta (opcional)'),
                            const SizedBox(height: 8),
                            _accounts.isEmpty
                                ? Text(
                                    'No tienes cuentas registradas',
                                    style: AppTextStyles.body2(context,
                                        color: AppColors.muted),
                                  )
                                : DropdownButtonFormField<BankAccount>(
                                    initialValue: _selectedAccount,
                                    items: _accounts.map((acc) {
                                      return DropdownMenuItem<BankAccount>(
                                        value: acc,
                                        child: Text(acc.name,
                                            style:
                                                AppTextStyles.body1(context)),
                                      );
                                    }).toList(),
                                    onChanged: (acc) =>
                                        setState(() => _selectedAccount = acc),
                                    decoration: inputDecoration(
                                        context, 'Selecciona una cuenta'),
                                  ),
                            const SizedBox(height: 16),

                            // Date
                            _label('Fecha'),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _pickDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.event,
                                        size: 18, color: AppColors.muted),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDate(_date),
                                      style: AppTextStyles.subtitle2(context),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Participants header + mode toggle
                            Row(
                              children: [
                                Text('Participantes',
                                    style: AppTextStyles.h600(context)),
                                const Spacer(),
                                _SplitModeToggle(
                                  isEqual: _equalSplit,
                                  onChanged: (v) {
                                    setState(() {
                                      _equalSplit = v;
                                      if (_equalSplit) _distributeEqually();
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Participant list
                            ..._participants.asMap().entries.map((entry) {
                              final index = entry.key;
                              final p = entry.value;
                              return _ParticipantRow(
                                participant: p,
                                isCustom: !_equalSplit,
                                onRemove: () => _removeParticipant(index),
                              );
                            }),

                            // Add participant button
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _allContacts.isEmpty
                                  ? null
                                  : _openContactsPicker,
                              icon: const Icon(Icons.person_add_alt_1,
                                  color: AppColors.primary),
                              label: Text(
                                'Agregar participante',
                                style: AppTextStyles.body1(context,
                                    color: AppColors.primary),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Submit
                Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom:
                        MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha(10), blurRadius: 10),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                              'Registrar gasto compartido',
                              style: AppTextStyles.subtitle2(context,
                                  color: Colors.white),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style:
            AppTextStyles.subtitle2(context, color: AppColors.textSecondary),
      );
}

// ── Split mode toggle ─────────────────────────────────────────────────────────

class _SplitModeToggle extends StatelessWidget {
  final bool isEqual;
  final ValueChanged<bool> onChanged;

  const _SplitModeToggle({required this.isEqual, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleChip(
            label: 'Igual',
            active: isEqual,
            isLeft: true,
            onTap: () => onChanged(true),
          ),
          _ToggleChip(
            label: 'Personalizado',
            active: !isEqual,
            isLeft: false,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool active;
  final bool isLeft;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.active,
    required this.isLeft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isLeft ? const Radius.circular(7) : Radius.zero,
            right: !isLeft ? const Radius.circular(7) : Radius.zero,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption(context,
              color: active ? Colors.white : AppColors.textSecondary),
        ),
      ),
    );
  }
}

// ── Participant row ───────────────────────────────────────────────────────────

class _ParticipantRow extends StatelessWidget {
  final _Participant participant;
  final bool isCustom;
  final VoidCallback onRemove;

  const _ParticipantRow({
    required this.participant,
    required this.isCustom,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  participant.contact.name.isNotEmpty
                      ? participant.contact.name[0].toUpperCase()
                      : '?',
                  style: AppTextStyles.body2(context,
                      color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Name
            Expanded(
              child: Text(
                participant.contact.name,
                style: AppTextStyles.subtitle2(context),
              ),
            ),

            // Amount field (always shown, readonly when equal mode)
            SizedBox(
              width: 90,
              child: TextFormField(
                controller: participant.amountController,
                enabled: isCustom,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                  hintText: '0.00',
                  hintStyle: AppTextStyles.caption(context,
                      color: AppColors.muted),
                  filled: true,
                  fillColor: isCustom
                      ? AppColors.surface
                      : AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.border),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.primary),
                  ),
                ),
                style: AppTextStyles.body1(context),
              ),
            ),
            const SizedBox(width: 4),

            // Remove
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close,
                  size: 18, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
