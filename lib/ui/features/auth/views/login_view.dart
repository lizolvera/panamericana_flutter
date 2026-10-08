import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shell/shell_scaffold.dart';
import 'google/google_button.dart';
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
  late final AuthViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = context.read<AuthViewModel>();
    // Cierra el login automáticamente cuando la sesión queda autenticada
    // (aplica a 2FA, Google en móvil y al botón GSI en web).
    _vm.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _vm.removeListener(_onAuthChanged);
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    if (_vm.isAuthenticated && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
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
    if (!mounted) return;
    if (!ok) _mostrarError(vm);
  }

  Future<bool> _iniciarConGoogle(AuthViewModel vm) async {
    final ok = await vm.loginWithGoogle();
    if (!mounted) return false;
    if (!ok) _mostrarError(vm);
    return ok;
  }

  void _mostrarError(AuthViewModel vm) {
    final mensaje = vm.errorMessage;
    if (mensaje == null) return; // p. ej. el usuario canceló Google
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final paso2 = vm.status == AuthStatus.codeSent;
    final cargando = vm.status == AuthStatus.loading;

    return ShellScaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Inicia sesión',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Accede con tu correo o con Google',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
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
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('o', style: TextStyle(color: Colors.grey)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  googleSignInButton(context, () => _iniciarConGoogle(vm)),
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
