// lib/features/profile/presentation/investment_fund/form_snapshot_screen.dart

import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/app_buttons.dart';
import 'package:cashflowiq/core/widgets/app_header_bar.dart';
import 'package:cashflowiq/core/widgets/app_text_field.dart';
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
      backgroundColor: context.colorBackground,
      appBar: const AppHeaderBar(title: "Registrar balance"),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.fund.name, style: context.textSubtitle1()),
              const SizedBox(height: 4),
              Text(
                widget.fund.bankEntity.name,
                style: context.textBody2(color: context.colorTextSecondary),
              ),
              const SizedBox(height: 28),

              // Date picker
              Text("Mes", style: context.textCaption(color: context.colorTextSecondary)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: context.colorSurface,
                    borderRadius: context.radiusMdRadius,
                    border: Border.all(color: context.colorBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: context.colorPrimary),
                      const SizedBox(width: 12),
                      Text(_fmtDate(_selectedDate), style: context.textBody1()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Value input
              AppTextField(
                label: "Valor actual (${widget.fund.currency.symbol})",
                controller: _valueController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixText: "${widget.fund.currency.symbol} ",
              ),

              const Spacer(),

              PrimaryButton(
                label: "Guardar balance",
                isLoading: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
