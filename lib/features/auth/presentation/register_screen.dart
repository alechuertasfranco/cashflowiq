import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/app_buttons.dart';
import 'package:cashflowiq/core/widgets/app_header_bar.dart';
import 'package:cashflowiq/core/widgets/app_text_field.dart';
import 'package:cashflowiq/features/auth/data/auth_service.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();

  bool loading = false;

  Future<void> register() async {
    setState(() => loading = true);

    try {
      await _auth.register(_email.text.trim(), _password.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cuenta creada correctamente")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorBackground,
      appBar: const AppHeaderBar(title: ''),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Crear cuenta', style: context.heading2(), textAlign: TextAlign.center),
              const SizedBox(height: 32),

              AppTextField(label: 'Email', controller: _email, hintText: 'tu@correo.com'),
              const SizedBox(height: 16),
              AppTextField(label: 'Contraseña', controller: _password, obscureText: true, hintText: '••••••••'),
              const SizedBox(height: 24),

              PrimaryButton(label: 'Crear cuenta', isLoading: loading, onPressed: register),
            ],
          ),
        ),
      ),
    );
  }
}
