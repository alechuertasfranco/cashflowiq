import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/app_buttons.dart';
import 'package:cashflowiq/core/widgets/app_text_field.dart';
import 'package:cashflowiq/core/widgets/staggered_fade_in.dart';
import 'package:cashflowiq/features/auth/data/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();

  bool loading = false;

  Future<void> login() async {
    setState(() => loading = true);

    try {
      await _auth.login(_email.text.trim(), _password.text.trim());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al iniciar sesión')));
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  Future<void> loginGoogle() async {
    try {
      await _auth.loginWithGoogle();
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code}');

      String message = 'Error desconocido';

      if (e.code == 'account-exists-with-different-credential') {
        message = 'Ya existe una cuenta con ese correo';
      } else if (e.code == 'network-request-failed') {
        message = 'Error de conexión';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      debugPrint('Error inesperado: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: StaggeredFadeIn(
              index: 0,
              staggerMs: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('CashFlowIQ', style: context.textCaption(), textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text('Controla tu dinero', style: context.heading2(), textAlign: TextAlign.center),
                  const SizedBox(height: 32),

                  AppTextField(label: 'Email', controller: _email, hintText: 'tu@correo.com'),
                  const SizedBox(height: 16),
                  AppTextField(label: 'Contraseña', controller: _password, obscureText: true, hintText: '••••••••'),
                  const SizedBox(height: 24),

                  PrimaryButton(label: 'Iniciar sesión', isLoading: loading, onPressed: login),
                  const SizedBox(height: 12),
                  SecondaryButton(label: 'Continuar con Google', onPressed: loginGoogle),
                  const SizedBox(height: 12),

                  GhostButton(
                    label: 'Crear cuenta',
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
