// lib/features/profile/presentation/investment_fund/form_snapshot_screen.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/features/profile/data/investment_fund_service.dart';
import 'package:cashflowiq/shared/models/investment_fund.dart';
import 'package:cashflowiq/shared/models/investment_fund_snapshot.dart';
import 'package:flutter/material.dart';

class FormSnapshotScreen extends StatefulWidget {
  final InvestmentFund fund;

  const FormSnapshotScreen({super.key, required this.fund});

  @override
  State<FormSnapshotScreen> createState() => _FormSnapshotScreenState();
}

class _FormSnapshotScreenState extends State<FormSnapshotScreen> {
  final _service = InvestmentFundService();
  final _valueController = TextEditingController();
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  bool _isSaving = false;

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    final raw = _valueController.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null || value < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa un valor válido")),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final snapshot = InvestmentFundSnapshot(
        id: '',
        fundId: widget.fund.id,
        snapshotDate: _selectedDate,
        value: value,
      );
      await _service.createSnapshot(widget.fund.id, snapshot);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al guardar el balance")),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _fmtDate(DateTime d) =>
      "${_monthName(d.month)} ${d.year}";

  String _monthName(int month) {
    const names = [
      '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    return names[month];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Registrar balance", style: AppTextStyles.h400(context)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.fund.name, style: AppTextStyles.subtitle1(context)),
              const SizedBox(height: 4),
              Text(
                widget.fund.bankEntity.name,
                style: AppTextStyles.body2(context, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 28),

              // Date picker
              Text("Mes", style: AppTextStyles.caption(context, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(_fmtDate(_selectedDate), style: AppTextStyles.body1(context)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Value input
              Text(
                "Valor actual (${widget.fund.currency.symbol})",
                style: AppTextStyles.caption(context, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _valueController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTextStyles.body1(context),
                decoration: InputDecoration(
                  prefixText: "${widget.fund.currency.symbol} ",
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          "Guardar balance",
                          style: AppTextStyles.subtitle2(context, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
