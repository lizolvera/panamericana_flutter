import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../shared/form_validators.dart';
import '../../../shared/widgets/widgets.dart';
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
            padding: AppTheme.padding24.copyWith(bottom: 96, top: 36),
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
                    AppTheme.spacer24,

                    // ── Título principal ──────────────────────────────────────
                    const AppTitle(
                      'Distribuidora Panamericana',
                      textAlign: TextAlign.center,
                    ),
                    AppTheme.spacer8,
                    AppSubtitle(
                      paso2 ? 'Verificación 2FA' : 'Crear una cuenta',
                      textAlign: TextAlign.center,
                    ),
                    AppTheme.spacer8,
                    AppCaption(
                      paso2
                          ? 'Ingresa el código de 6 dígitos enviado a tu correo'
                          : 'Introduce tu correo electrónico para registrarte en ésta aplicación o inicia sesión',
                      textAlign: TextAlign.center,
                    ),
                    AppTheme.spacer24,

                    // ── Tarjeta del formulario ────────────────────────────────
                    AppFormCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                    // ── Formulario paso 1 ─────────────────────────────────────
                    if (!paso2) ...[
                      // Campo correo
                      Semantics(
                        identifier: 'login_email',
                        child: AppInputField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          hintText: 'Email @ Panamericana.com',
                          prefixIcon: const Icon(Icons.email_outlined),
                          validator: FormValidators.requiredEmail,
                        ),
                      ),
                      AppTheme.spacer16,
                      // Campo contraseña
                      AppInputField(
                        controller: _passwordCtrl,
                        obscureText: !_passwordVisible,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        hintText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _passwordVisible = !_passwordVisible),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Ingresa tu contraseña'
                            : null,
                      ),
                      AppTheme.spacer20,
                      // Botón "Continuar"
                      AppPrimaryButton(
                        onPressed: cargando ? null : () => _enviarCredenciales(vm),
                        text: 'Continuar',
                      ),
                      AppTheme.spacer16,
                      // Divisor "o"
                      const AppOrDivider(),
                      AppTheme.spacer16,
                      // Botón "Continuar con Google"
                      Center(
                        child: googleSignInButton(
                          context,
                          () => _iniciarConGoogle(vm),
                        ),
                      ),
                      AppTheme.spacer24,
                      // Términos y privacidad
                      Text.rich(
                        TextSpan(
                          text: 'Al hacer clic en continuar, aceptas nuestros ',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.cafeOscuro.withValues(alpha: 0.5),
                                letterSpacing: 0.2,
                              ),
                          children: [
                            TextSpan(
                              text: 'Términos de Servicio',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.vino,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                            ),
                            const TextSpan(text: ' y nuestra '),
                            TextSpan(
                              text: 'Política de privacidad',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.vino,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      AppTheme.spacer16,
                      // Accesos: registro y recuperación de cuenta
                      AppTextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/registro');
                        },
                        text: '¿No tienes cuenta? Regístrate',
                        color: AppColors.vino,
                      ),
                      AppTextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/recuperacion');
                        },
                        text: '¿Olvidaste tu contraseña?',
                        color: AppColors.terracota,
                      ),
                    ]
                    // ── Formulario paso 2 (2FA) ─────────────────────────────
                    else ...[
                      // Correo indicado
                      AppOutlineCard(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.mark_email_read_outlined,
                              size: 22,
                              color: AppColors.terracota,
                            ),
                            AppTheme.widthSpacer16,
                            Expanded(
                              child: Text(
                                _emailCtrl.text.trim(),
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.cafeOscuro,
                                      letterSpacing: 0.2,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppTheme.spacer12,
                      // Campo código 2FA
                      AppCodeInputField(
                        controller: _codeCtrl,
                        length: 6,
                      ),
                      AppTheme.spacer16,
                      // Botón verificar
                      AppPrimaryButton(
                        onPressed: cargando ? null : () => _verificarCodigo(vm),
                        text: 'Verificar y entrar',
                      ),
                      AppTheme.spacer8,
                      TextButton.icon(
                        onPressed: cargando
                            ? null
                            : () {
                                _codeCtrl.clear();
                                vm.resetState();
                              },
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('Cambiar correo o contraseña'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.terracota,
                          textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                        ),
                      ),
                    ],
                        ],
                      ),
                    ),

                    // ── Indicador de carga ────────────────────────────────────
                    if (cargando)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.vino,
                          ),
                        ),
                      ),

                    // ── Opción de invitado ────────────────────────────────────
                    if (Navigator.of(context).canPop() && !cargando) ...[
                      AppTheme.spacer12,
                      AppTextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        text: 'Continuar como invitado',
                        color: AppColors.cafeOscuro,
                        textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.cafeOscuro.withValues(alpha: 0.5),
                              letterSpacing: 0.2,
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
