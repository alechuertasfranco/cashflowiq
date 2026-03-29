// lib/features/bank_entities/presentation/form_entity_screen.dart

import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/color_selector.dart';
import 'package:cashflowiq/features/bank_entities/data/bank_entity_service.dart';
import 'package:cashflowiq/shared/models/bank_entity.dart';
import 'package:flutter/material.dart';

class FormEntityScreen extends StatefulWidget {
  final BankEntity? entity;

  const FormEntityScreen({super.key, this.entity});

  @override
  State<FormEntityScreen> createState() => _FormEntityScreenState();
}

class _FormEntityScreenState extends State<FormEntityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = BankEntityService();

  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  Color? _selectedColor;

  bool _isSaving = false;
  bool get _isEdit => widget.entity != null;

  @override
  void initState() {
    super.initState();

    if (_isEdit) {
      _nameController.text = widget.entity!.name;
      _codeController.text = widget.entity!.code;
      if (widget.entity!.colorHex != null) {
        _selectedColor = Color(int.parse('FF${widget.entity!.colorHex!}', radix: 16));
      }
    }
  }

  String? _colorToHex(Color? color) {
    if (color == null) return null;
    return color.toARGB32().toRadixString(16).substring(2).toUpperCase();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final entity = BankEntity(
        id: widget.entity?.id ?? '',
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        colorHex: _colorToHex(_selectedColor),
      );

      if (_isEdit) {
        await _service.updateEntity(entity);
      } else {
        await _service.createEntity(entity);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error guardando entidad")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(_isEdit ? "Editar entidad" : "Nueva entidad", style: AppTextStyles.h400(context)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    // hace que Spacer funcione correctamente
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Campos ---
                          Text("Código", style: AppTextStyles.subtitle2(context, color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _codeController,
                            decoration: InputDecoration(
                              hintText: "Ej: BCP, IBK, BBVA",
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty ? "Ingresa el código del banco" : null,
                          ),
                          const SizedBox(height: 16),

                          Text(
                            "Entidad bancaria",
                            style: AppTextStyles.subtitle2(context, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: "Ej: Banco de Crédito del Perú",
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty ? "Ingresa el nombre del banco" : null,
                          ),
                          const SizedBox(height: 16),

                          Text(
                            "Color (opcional)",
                            style: AppTextStyles.subtitle2(context, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          ColorSelector(
                            initialColor: _selectedColor,
                            onSelected: (color) => setState(() => _selectedColor = color),
                          ),

                          const Spacer(), // Mantiene los botones pegados abajo
                          // --- Botones ---
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
                                      _isEdit ? "Actualizar entidad" : "Crear entidad",
                                      style: AppTextStyles.subtitle2(context, color: Colors.white),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
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
                              child: Text(
                                "Cancelar",
                                style: AppTextStyles.subtitle2(context, color: AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
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
