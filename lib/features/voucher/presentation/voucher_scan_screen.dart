// lib/features/voucher/presentation/voucher_scan_screen.dart

import 'dart:io';
import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/app_buttons.dart';
import 'package:cashflowiq/core/widgets/app_dropdown_field.dart';
import 'package:cashflowiq/core/widgets/app_header_bar.dart';
import 'package:cashflowiq/core/widgets/app_text_field.dart';
import 'package:cashflowiq/core/widgets/skeleton_loader.dart';
import 'package:cashflowiq/features/transactions/presentation/expense_transaction/expense_screen.dart';
import 'package:cashflowiq/features/voucher/data/payment_service_service.dart';
import 'package:cashflowiq/features/voucher/data/voucher_service.dart';
import 'package:cashflowiq/shared/models/payment_service.dart';
import 'package:cashflowiq/shared/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class VoucherScanScreen extends StatefulWidget {
  final File? initialImage;

  const VoucherScanScreen({super.key, this.initialImage});

  @override
  State<VoucherScanScreen> createState() => _VoucherScanScreenState();
}

class _VoucherScanScreenState extends State<VoucherScanScreen> {
  final PaymentServiceService _psService = PaymentServiceService();
  final VoucherService _voucherService = VoucherService();
  final ImagePicker _picker = ImagePicker();

  List<PaymentService> _services = [];
  bool _isLoadingServices = true;

  File? _image;
  PaymentService? _selectedService;
  bool _isAnalyzing = false;
  VoucherResult? _result;

  final _amountCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _recipientCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadServices();
    if (widget.initialImage != null) {
      _image = widget.initialImage;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    _dateCtrl.dispose();
    _recipientCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    try {
      final data = await _psService.getPaymentServices();
      if (!mounted) return;
      setState(() {
        _services = data;
        _isLoadingServices = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingServices = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final xFile = await _picker.pickImage(source: source, imageQuality: 80);
    if (xFile != null) {
      setState(() {
        _image = File(xFile.path);
        _result = null;
        _amountCtrl.clear();
        _descriptionCtrl.clear();
        _dateCtrl.clear();
        _recipientCtrl.clear();
      });
    }
  }

  Future<void> _analyze() async {
    if (_image == null) return;
    setState(() => _isAnalyzing = true);
    try {
      final serviceType = _selectedService?.serviceType ?? 'generic';
      final result = await _voucherService.parseVoucher(
        imageFile: _image!,
        serviceType: serviceType,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _amountCtrl.text = result.amount?.toString() ?? '';
        _descriptionCtrl.text = result.description ?? '';
        _dateCtrl.text = result.date ?? '';
        _recipientCtrl.text = result.recipient ?? '';
        _isAnalyzing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al analizar el voucher")),
      );
    }
  }

  void _registerAsExpense() {
    final amount = double.tryParse(_amountCtrl.text) ?? 0.0;
    final description = _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim();
    final currencyCode = _result?.currencyCode ?? 'PEN';
    final currencySymbol = currencyCode == 'PEN' ? 'S/' : currencyCode;

    DateTime date;
    try {
      date = _dateCtrl.text.isNotEmpty ? DateTime.parse(_dateCtrl.text) : DateTime.now();
    } catch (_) {
      date = DateTime.now();
    }

    final transaction = Transaction(
      id: '',
      type: TransactionType.expense,
      amount: amount,
      date: date,
      description: description,
      accountId: _selectedService?.accountId?.toString(),
      creditCardId: _selectedService?.creditCardId?.toString(),
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExpenseScreen(prefill: transaction)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorBackground,
      appBar: const AppHeaderBar(title: "Escanear voucher"),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label("Imagen del voucher"),
              const SizedBox(height: 12),
              _imagePicker(),

              const SizedBox(height: 20),

              _label("Servicio de pago"),
              const SizedBox(height: 8),
              _isLoadingServices
                  ? const SkeletonListLoader(itemCount: 1, itemHeight: 56)
                  : _servicePicker(),

              const SizedBox(height: 20),

              PrimaryButton(
                label: _isAnalyzing ? "Analizando..." : "Analizar",
                icon: _isAnalyzing ? null : Icons.document_scanner,
                isLoading: _isAnalyzing,
                onPressed: (_image == null || _isAnalyzing) ? null : _analyze,
              ),

              if (_result != null) ...[
                const SizedBox(height: 24),
                _label("Datos extraídos"),
                const SizedBox(height: 12),
                _resultField("Monto", _amountCtrl, keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _resultField("Descripción", _descriptionCtrl),
                const SizedBox(height: 12),
                _resultField("Fecha", _dateCtrl),
                const SizedBox(height: 12),
                _resultField("Destinatario", _recipientCtrl),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: "Registrar como gasto",
                  color: context.colorError,
                  onPressed: _registerAsExpense,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePicker() {
    if (_image != null) {
      return Column(
        children: [
          ClipRRect(
            borderRadius: context.radiusMdRadius,
            child: Image.file(_image!, height: 200, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: "Galería",
                  icon: Icons.photo_library,
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SecondaryButton(
                  label: "Cámara",
                  icon: Icons.camera_alt,
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _PickButton(
            icon: Icons.photo_library,
            label: "Galería",
            onTap: () => _pickImage(ImageSource.gallery),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PickButton(
            icon: Icons.camera_alt,
            label: "Cámara",
            onTap: () => _pickImage(ImageSource.camera),
          ),
        ),
      ],
    );
  }

  Widget _servicePicker() {
    final items = <DropdownMenuItem<PaymentService?>>[
      DropdownMenuItem(
        value: null,
        child: Text("Genérico", style: context.textBody1()),
      ),
      ..._services.map((s) {
        return DropdownMenuItem(
          value: s,
          child: Text(s.name, style: context.textBody1()),
        );
      }),
    ];

    return AppDropdownField<PaymentService?>(
      value: _selectedService,
      items: items,
      onChanged: (v) => setState(() => _selectedService = v),
      hintText: "Selecciona un servicio",
    );
  }

  Widget _resultField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return AppTextField(
      label: label,
      controller: controller,
      hintText: label,
      keyboardType: keyboardType,
    );
  }

  Widget _label(String text) =>
      Text(text, style: context.textSubtitle2(color: context.colorTextSecondary));
}

class _PickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colorSurface,
      borderRadius: context.radiusMdRadius,
      child: InkWell(
        borderRadius: context.radiusMdRadius,
        onTap: onTap,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: context.radiusMdRadius,
            border: Border.all(color: context.colorBorder),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: context.colorPrimary, size: 32),
              const SizedBox(height: 8),
              Text(label, style: context.textBody1(color: context.colorPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}
