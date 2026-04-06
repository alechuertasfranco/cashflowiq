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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Controla tu dinero", style: TextStyle(fontSize: 24)),

            const SizedBox(height: 24),

            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: loading ? null : login,
              child: loading ? const CircularProgressIndicator() : const Text("Iniciar sesión"),
            ),

            const SizedBox(height: 16),

            OutlinedButton(onPressed: loginGoogle, child: const Text("Continuar con Google")),

            const SizedBox(height: 16),

            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
              },
              child: const Text("Crear cuenta"),
            ),
          ],
        ),
      ),
    );
  }
}
