import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';

/// **View de login** (2 pasos, igual que la web):
/// 1) correo + contraseña → el backend manda el código 2FA;
/// 2) código → verifica y entra (solo clientes).
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviarCredenciales(AuthViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await vm.sendLoginCode(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (!ok && mounted) {
      _mostrarError(vm);
    }
  }

  Future<void> _verificarCodigo(AuthViewModel vm) async {
    final ok = await vm.verifyCode(_codeCtrl.text);
    if (!ok && mounted) {
      _mostrarError(vm);
    }
  }

  void _mostrarError(AuthViewModel vm) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(vm.errorMessage ?? 'Ocurrió un error')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final paso2 = vm.status == AuthStatus.codeSent;
    final cargando = vm.status == AuthStatus.loading;

    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Distribuidora Panamericana',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                if (!paso2) ...[
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo'),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Correo inválido'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Ingresa tu contraseña'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: cargando ? null : () => _enviarCredenciales(vm),
                    child: const Text('Enviar código de seguridad'),
                  ),
                ] else ...[
                  const Text(
                    'Te enviamos un código de 6 dígitos a tu correo.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _codeCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Código 2FA',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: cargando ? null : () => _verificarCodigo(vm),
                    child: const Text('Verificar código'),
                  ),
                ],
                if (cargando)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
