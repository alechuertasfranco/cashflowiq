// lib/features/bank_accounts/presentation/form_account_screen.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/features/bank_accounts/data/bank_account_service.dart';
import 'package:cashflowiq/features/bank_entities/data/bank_entity_service.dart';
import 'package:cashflowiq/features/bank_entities/presentation/bank_entities_screen.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';
import 'package:cashflowiq/shared/models/bank_entity.dart';
import 'package:cashflowiq/shared/models/currency.dart';
import 'package:flutter/material.dart';

class FormAccountScreen extends StatefulWidget {
  final BankAccount? account;

  const FormAccountScreen({super.key, this.account});

  @override
  State<FormAccountScreen> createState() => _FormAccountScreenState();
}

class _FormAccountScreenState extends State<FormAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = BankAccountService();
  final _entityService = BankEntityService();

  final _nameController = TextEditingController();
  final _initialAmountController = TextEditingController();

  Currency _selectedCurrency = Currency.pen;
  bool _isSaving = false;

  BankEntity? _selectedBankEntity;
  List<BankEntity> _entities = [];
  bool _isLoadingEntities = true;

  bool get _isEdit => widget.account != null;

  @override
  void initState() {
    super.initState();

    if (_isEdit) {
      final acc = widget.account!;
      _nameController.text = acc.name;
      _initialAmountController.text = acc.balance.amount.toString();
      _selectedCurrency = acc.balance.currency;
    }

    _loadEntities();
  }

  Future<void> _loadEntities() async {
    setState(() => _isLoadingEntities = true);

    try {
      final entities = await _entityService.getEntities();

      if (!mounted) return;

      BankEntity? selected;

      if (_isEdit) {
        final accEntityId = widget.account!.bankEntity.id;

        selected = entities.firstWhere(
          (e) => e.id == accEntityId,
          orElse: () => entities.isNotEmpty ? entities.first : throw Exception(),
        );
      }

      setState(() {
        _entities = entities;
        _selectedBankEntity = selected;
        _isLoadingEntities = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoadingEntities = false);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error cargando entidades bancarias")));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    if (_selectedBankEntity == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecciona una entidad bancaria")));
      return;
    }

    try {
      final account = BankAccount(
        id: widget.account?.id ?? '',
        name: _nameController.text.trim(),
        initialAmount: double.parse(_initialAmountController.text),
        currency: _selectedCurrency,
        bankEntity: _selectedBankEntity!,
      );
      if (_isEdit) {
        await _service.updateAccount(account);
      } else {
        await _service.createAccount(account);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error guardando cuenta")));
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? "Editar cuenta" : "Nueva cuenta", style: AppTextStyles.h400(context)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🏦 Nombre
                Text("Nombre de la cuenta", style: AppTextStyles.subtitle2(context, color: AppColors.textSecondary)),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: "Ej: BCP Ahorros",
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty ? "Ingresa un nombre" : null,
                ),

                const SizedBox(height: 16),

                /// 💰 Balance
                Text("Balance inicial", style: AppTextStyles.subtitle2(context, color: AppColors.textSecondary)),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _initialAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "0.00",
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Ingresa un monto";
                    if (double.tryParse(value) == null) return "Monto inválido";
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                /// 🌍 Moneda
                Text("Moneda", style: AppTextStyles.subtitle2(context, color: AppColors.textSecondary)),
                const SizedBox(height: 8),

                DropdownButtonFormField<Currency>(
                  initialValue: _selectedCurrency,
                  dropdownColor: AppColors.surface,
                  items: Currency.values.map((currency) {
                    return DropdownMenuItem(
                      value: currency,
                      child: Text("${currency.flag} ${currency.code}", style: AppTextStyles.body1(context)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCurrency = value);
                    }
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                /// 🏦 Entidad bancaria
                Text("Entidad bancaria", style: AppTextStyles.subtitle2(context, color: AppColors.textSecondary)),
                const SizedBox(height: 8),

                _isLoadingEntities
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          DropdownButtonFormField<BankEntity>(
                            initialValue: _selectedBankEntity,
                            dropdownColor: AppColors.surface,
                            items: _entities.map((entity) {
                              return DropdownMenuItem(
                                value: entity,
                                child: Text(entity.name, style: AppTextStyles.body1(context)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedBankEntity = value);
                            },
                            decoration: InputDecoration(
                              hintText: "Selecciona un banco",
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          /// ➕ Crear nueva entidad
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () async {
                                final created = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const BankEntitiesScreen()),
                                );

                                if (created == true) _loadEntities();
                              },
                              child: Text(
                                "Crear nueva entidad",
                                style: AppTextStyles.caption(context, color: AppColors.primary),
                              ),
                            ),
                          ),
                        ],
                      ),

                const Spacer(),

                /// 🚀 CTA PRINCIPAL
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSaving ? null : _submit,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _isEdit ? "Actualizar cuenta" : "Crear cuenta",
                            style: AppTextStyles.subtitle2(
                              context,
                              color: Colors.white, // 👈 correcto sobre primary
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 10),

                /// ✨ CTA SECUNDARIO (opcional UX pro)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancelar", style: AppTextStyles.subtitle2(context, color: AppColors.primary)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
