// lib/features/bank_entities/presentation/form_entity_screen.dart

import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/app_buttons.dart';
import 'package:cashflowiq/core/widgets/app_header_bar.dart';
import 'package:cashflowiq/core/widgets/app_text_field.dart';
import 'package:cashflowiq/core/widgets/color_selector.dart';
import 'package:cashflowiq/features/profile/data/bank_entity_service.dart';
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
      backgroundColor: context.colorBackground,
      resizeToAvoidBottomInset: true,
      appBar: AppHeaderBar(title: _isEdit ? "Editar entidad" : "Nueva entidad"),
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
                          AppTextField(
                            label: "Código",
                            controller: _codeController,
                            hintText: "Ej: BCP, IBK, BBVA",
                            validator: (value) => value == null || value.isEmpty ? "Ingresa el código del banco" : null,
                          ),
                          const SizedBox(height: 16),

                          AppTextField(
                            label: "Entidad bancaria",
                            controller: _nameController,
                            hintText: "Ej: Banco de Crédito del Perú",
                            validator: (value) => value == null || value.isEmpty ? "Ingresa el nombre del banco" : null,
                          ),
                          const SizedBox(height: 16),

                          Text(
                            "Color (opcional)",
                            style: context.textSubtitle2(color: context.colorTextSecondary),
                          ),
                          const SizedBox(height: 8),
                          ColorSelector(
                            initialColor: _selectedColor,
                            onSelected: (color) => setState(() => _selectedColor = color),
                          ),

                          const Spacer(), // Mantiene los botones pegados abajo
                          // --- Botones ---
                          PrimaryButton(
                            label: _isEdit ? "Actualizar entidad" : "Crear entidad",
                            isLoading: _isSaving,
                            onPressed: _submit,
                          ),
                          const SizedBox(height: 10),
                          SecondaryButton(
                            label: "Cancelar",
                            onPressed: () => Navigator.pop(context),
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
