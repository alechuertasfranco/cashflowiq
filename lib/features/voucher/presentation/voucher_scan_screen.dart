// lib/features/voucher/presentation/voucher_scan_screen.dart

import 'dart:io';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/decorations.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Escanear voucher", style: AppTextStyles.h400(context)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
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
                  ? const Center(child: CircularProgressIndicator())
                  : _servicePicker(),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: (_image == null || _isAnalyzing) ? null : _analyze,
                  icon: _isAnalyzing
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.document_scanner, color: Colors.white),
                  label: Text(
                    _isAnalyzing ? "Analizando..." : "Analizar",
                    style: AppTextStyles.subtitle2(context, color: Colors.white),
                  ),
                ),
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _registerAsExpense,
                    child: Text(
                      "Registrar como gasto",
                      style: AppTextStyles.subtitle2(context, color: Colors.white),
                    ),
                  ),
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
            borderRadius: BorderRadius.circular(12),
            child: Image.file(_image!, height: 200, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: Text("Galería", style: AppTextStyles.caption(context, color: AppColors.primary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: Text("Cámara", style: AppTextStyles.caption(context, color: AppColors.primary)),
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
        child: Text("Genérico", style: AppTextStyles.body1(context)),
      ),
      ..._services.map((s) {
        return DropdownMenuItem(
          value: s,
          child: Text(s.name, style: AppTextStyles.body1(context)),
        );
      }),
    ];

    return DropdownButtonFormField<PaymentService?>(
      initialValue: _selectedService,
      items: items,
      onChanged: (v) => setState(() => _selectedService = v),
      decoration: inputDecoration(context, "Selecciona un servicio"),
    );
  }

  Widget _resultField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: inputDecoration(context, label),
        ),
      ],
    );
  }

  Widget _label(String text) =>
      Text(text, style: AppTextStyles.subtitle2(context, color: AppColors.textSecondary));
}

class _PickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 32),
              const SizedBox(height: 8),
              Text(label, style: AppTextStyles.body1(context, color: AppColors.primary)),
            ],
          ),
        ),
      ),
    );
  }
}
