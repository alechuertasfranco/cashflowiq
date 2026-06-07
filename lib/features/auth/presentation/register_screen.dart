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
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Crear cuenta", style: TextStyle(fontSize: 24)),

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

              ElevatedButton(onPressed: loading ? null : register, child: loading ? const CircularProgressIndicator() : const Text("Crear cuenta")),
            ],
          ),
        ),
      ),
    );
  }
}
