// lib/features/splits/screens/form_contact_screen.dart

import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/app_buttons.dart';
import 'package:cashflowiq/core/widgets/app_header_bar.dart';
import 'package:cashflowiq/core/widgets/app_text_field.dart';
import 'package:cashflowiq/features/splits/data/contact_service.dart';
import 'package:cashflowiq/shared/models/contact.dart';
import 'package:flutter/material.dart';

class FormContactScreen extends StatefulWidget {
  final Contact? existing;

  const FormContactScreen({super.key, this.existing});

  @override
  State<FormContactScreen> createState() => _FormContactScreenState();
}

class _FormContactScreenState extends State<FormContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _service = ContactService();

  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.existing!.name;
      _emailController.text = widget.existing!.email ?? '';
      _phoneController.text = widget.existing!.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      if (_emailController.text.trim().isNotEmpty)
        'email': _emailController.text.trim(),
      if (_phoneController.text.trim().isNotEmpty)
        'phone': _phoneController.text.trim(),
    };

    try {
      if (_isEditing) {
        await _service.update(widget.existing!.id, payload);
      } else {
        await _service.create(payload);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('contact form submit error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar el contacto')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorBackground,
      appBar: AppHeaderBar(
        title: _isEditing ? 'Editar contacto' : 'Nuevo contacto',
      ),
      body: SafeArea(
        child: Column(
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

                      AppTextField(
                        label: 'Nombre',
                        controller: _nameController,
                        hintText: 'Ej: Juan García',
                        textCapitalization: TextCapitalization.words,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'El nombre es requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      AppTextField(
                        label: 'Email (opcional)',
                        controller: _emailController,
                        hintText: 'juan@ejemplo.com',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v != null && v.trim().isNotEmpty) {
                            final emailRegex = RegExp(
                                r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
                            if (!emailRegex.hasMatch(v.trim())) {
                              return 'Email inválido';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      AppTextField(
                        label: 'Teléfono (opcional)',
                        controller: _phoneController,
                        hintText: '+51 999 999 999',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Submit button
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 16,
            ),
            decoration: BoxDecoration(
              color: context.colorBackground,
              boxShadow: context.shadowCard,
            ),
            child: PrimaryButton(
              label: _isEditing ? 'Guardar cambios' : 'Crear contacto',
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _submit,
            ),
          ),
        ],
      ),
      ),
    );
  }
}
