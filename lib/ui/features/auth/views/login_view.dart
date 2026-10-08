import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_colors.dart';
import '../../shell/shell_scaffold.dart';
import 'google/google_button.dart';
import '../view_models/auth_view_model.dart';

/// **View de login / creación de cuenta** (Boceto 3):
/// 1) Título "Distribuidora Panamericana", subtítulo "Crear una cuenta".
/// 2) Correo + contraseña → envía código 2FA.
/// 3) Código → verifica y entra (solo clientes).
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
  bool _passwordVisible = false;
  late final AuthViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = context.read<AuthViewModel>();
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
    if (!ok && mounted) _mostrarError(vm);
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
    if (mensaje == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: AppColors.vino,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final paso2 = vm.status == AuthStatus.codeSent;
    final cargando = vm.status == AuthStatus.loading;

    return ShellScaffold(
      titleText: 'Iniciar sesión',
      body: Container(
        color: AppColors.fondoGeneral,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Logo / icono ──────────────────────────────────────────
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.vino,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.vino.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.content_cut,
                          color: AppColors.blancoCalido,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Título principal ──────────────────────────────────────
                    const Text(
                      'Distribuidora Panamericana',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cafeOscuro,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      paso2 ? 'Verificación 2FA' : 'Crear una cuenta',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.terracota,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      paso2
                          ? 'Ingresa el código de 6 dígitos enviado a tu correo'
                          : 'Introduce tu correo electrónico para registrarte en ésta aplicación o inicia sesión',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.cafeOscuro.withValues(alpha: 0.6),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Formulario paso 1 ─────────────────────────────────────
                    if (!paso2) ...[
                      // Campo correo
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Email @ Panamericana.com',
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: AppColors.terracota,
                          ),
                          filled: true,
                          fillColor: AppColors.blancoCalido,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.rosaBeigeClaro),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.rosaBeigeClaro),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.vino, width: 1.5),
                          ),
                        ),
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'Correo inválido'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      // Campo contraseña / 2FA
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: !_passwordVisible,
                        decoration: InputDecoration(
                          hintText: 'Contraseña',
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: AppColors.terracota,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.terracota,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _passwordVisible = !_passwordVisible),
                          ),
                          filled: true,
                          fillColor: AppColors.blancoCalido,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.rosaBeigeClaro),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.rosaBeigeClaro),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.vino, width: 1.5),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Ingresa tu contraseña'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      // Botón "Continuar"
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            backgroundColor: AppColors.vino,
                            foregroundColor: AppColors.blancoCalido,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          onPressed:
                              cargando ? null : () => _enviarCredenciales(vm),
                          child: const Text('Continuar'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Divisor "o"
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: AppColors.rosaBeigeClaro
                                  .withValues(alpha: 0.8),
                              thickness: 1.2,
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'o',
                              style: TextStyle(
                                color: AppColors.cafeOscuro
                                    .withValues(alpha: 0.4),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: AppColors.rosaBeigeClaro
                                  .withValues(alpha: 0.8),
                              thickness: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Botón "Continuar con Google"
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.rosaBeigeClaro),
                        ),
                        child:
                            googleSignInButton(context, () => _iniciarConGoogle(vm)),
                      ),
                      const SizedBox(height: 24),
                      // Términos y privacidad
                      Text.rich(
                        TextSpan(
                          text:
                              'Al hacer clic en continuar, aceptas nuestros ',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.cafeOscuro.withValues(alpha: 0.5),
                          ),
                          children: [
                            TextSpan(
                              text: 'Términos de Servicio',
                              style: const TextStyle(
                                color: AppColors.vino,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: ' y nuestra '),
                            TextSpan(
                              text: 'Política de privacidad',
                              style: const TextStyle(
                                color: AppColors.vino,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ]
                    // ── Formulario paso 2 (2FA) ─────────────────────────────
                    else ...[
                      // Correo indicado
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.rosaBeigeClaro.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.rosaBeigeClaro),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.mark_email_read_outlined,
                              size: 22,
                              color: AppColors.terracota,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _emailCtrl.text.trim(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.cafeOscuro,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Campo código 2FA
                      TextFormField(
                        controller: _codeCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          letterSpacing: 10,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.vinoOscuro,
                        ),
                        decoration: InputDecoration(
                          hintText: '------',
                          hintStyle: TextStyle(
                            color: AppColors.cafeOscuro.withValues(alpha: 0.3),
                            letterSpacing: 8,
                          ),
                          counterText: '',
                          filled: true,
                          fillColor: AppColors.blancoCalido,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.rosaBeigeClaro),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.vino, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Botón verificar
                      FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: AppColors.vino,
                          foregroundColor: AppColors.blancoCalido,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed:
                            cargando ? null : () => _verificarCodigo(vm),
                        child: const Text('Verificar y entrar'),
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: cargando
                            ? null
                            : () {
                                _codeCtrl.clear();
                                vm.resetState();
                              },
                        icon: const Icon(Icons.arrow_back, size: 16,
                            color: AppColors.terracota),
                        label: const Text(
                          'Cambiar correo o contraseña',
                          style: TextStyle(color: AppColors.terracota),
                        ),
                      ),
                    ],

                    // ── Indicador de carga ────────────────────────────────────
                    if (cargando)
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.vino,
                          ),
                        ),
                      ),

                    // ── Opción de invitado ────────────────────────────────────
                    if (Navigator.of(context).canPop() && !cargando) ...[
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Continuar como invitado',
                          style: TextStyle(
                            color: AppColors.cafeOscuro.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
