// lib/features/voucher/presentation/payment_services_screen.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/insight_empty_state.dart';
import 'package:cashflowiq/core/widgets/swipe_to_delete.dart';
import 'package:cashflowiq/features/voucher/data/payment_service_service.dart';
import 'package:cashflowiq/features/voucher/presentation/form_payment_service_screen.dart';
import 'package:cashflowiq/shared/models/payment_service.dart';
import 'package:flutter/material.dart';

class PaymentServicesScreen extends StatefulWidget {
  const PaymentServicesScreen({super.key});

  @override
  State<PaymentServicesScreen> createState() => _PaymentServicesScreenState();
}

class _PaymentServicesScreenState extends State<PaymentServicesScreen> {
  final PaymentServiceService _service = PaymentServiceService();

  List<PaymentService> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getPaymentServices();
      if (!mounted) return;
      setState(() {
        _services = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error cargando servicios de pago")),
      );
    }
  }

  Future<void> _goToCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FormPaymentServiceScreen()),
    );
    if (result == true) _load();
  }

  Future<void> _goToEdit(PaymentService service) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FormPaymentServiceScreen(service: service)),
    );
    if (result == true) _load();
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'yape':
        return 'Yape';
      case 'plin':
        return 'Plin';
      default:
        return 'Genérico';
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'yape':
        return Icons.payment;
      case 'plin':
        return Icons.mobile_friendly;
      default:
        return Icons.receipt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Servicios de pago", style: AppTextStyles.h400(context)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _goToCreate,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _services.isEmpty
              ? InsightEmptyState(
                  icon: Icons.receipt_long,
                  title: "No tienes servicios de pago",
                  description: "Agrega Yape, Plin u otros servicios para escanear tus vouchers",
                  actionText: "Agregar servicio",
                  onAction: _goToCreate,
                )
              : ListView.separated(
                  itemCount: _services.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final s = _services[index];
                    return SwipeToDelete(
                      onDelete: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await _service.deletePaymentService(s.id);
                        await _load();
                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(content: Text("Servicio eliminado")),
                        );
                      },
                      child: Card(
                        child: ListTile(
                          leading: Icon(_typeIcon(s.serviceType), color: AppColors.primary),
                          title: Text(s.name, style: AppTextStyles.body1(context)),
                          subtitle: Text(_typeLabel(s.serviceType), style: AppTextStyles.caption(context)),
                          trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                          onTap: () => _goToEdit(s),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
