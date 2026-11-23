import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../shared/form_validators.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../../shell/shell_scaffold.dart';

/// **View de recuperación de cuenta**: flujo de 3 pasos igual a la web:
/// 1) correo → 2) responder pregunta secreta → 3) nueva contraseña.
///
/// Diseño boutique: indicador de pasos visual y tarjeta por paso con
/// encabezado, campos estilizados y botón primario con carga.
class RecuperacionView extends StatefulWidget {
  const RecuperacionView({super.key});

  @override
  State<RecuperacionView> createState() => _RecuperacionViewState();
}

class _RecuperacionViewState extends State<RecuperacionView> {
  int _paso = 1;
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _respuestaCtrl = TextEditingController();
  final _nuevaCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _pregunta;
  bool _trabajando = false;

  static final RegExp _passwordRegex =
      RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z0-9]).{12,}$');

  @override
  void dispose() {
    _emailCtrl.dispose();
    _respuestaCtrl.dispose();
    _nuevaCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _solicitarPregunta() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _trabajando = true);
    final repo = context.read<AuthRepository>();
    try {
      // Verificar correo (respuesta genérica por seguridad).
      await repo.verificarCorreo(_emailCtrl.text.trim());
      final pregunta = await repo.obtenerPregunta(_emailCtrl.text.trim());
      if (!mounted) return;
      setState(() {
        _pregunta = pregunta;
        _paso = 2;
      });
    } catch (e) {
      _mostrarError(e);
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  Future<void> _verificarRespuesta() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _trabajando = true);
    final repo = context.read<AuthRepository>();
    try {
      await repo.verificarRespuesta(
        _emailCtrl.text.trim(),
        _respuestaCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() => _paso = 3);
    } catch (e) {
      _mostrarError(e);
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  Future<void> _cambiarContrasena() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _trabajando = true);
    final repo = context.read<AuthRepository>();
    try {
      await repo.cambiarContrasenaRecuperacion(
        _emailCtrl.text.trim(),
        _nuevaCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Contraseña restablecida. Inicia sesión.'),
          backgroundColor: AppColors.vino,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      _mostrarError(e);
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  void _mostrarError(Object error) {
    if (!mounted) return;
    String mensaje = 'Ocurrió un error. Intenta de nuevo.';
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic> && data['error'] != null) {
        mensaje = data['error'].toString();
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: AppColors.vinoOscuro,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _botonAccion(String texto, VoidCallback? onPressed) {
    return AppPrimaryButton(
      onPressed: onPressed,
      text: texto,
      child: _trabajando
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.blancoCalido,
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ShellScaffold(
      titleText: 'Recuperar cuenta',
      body: Container(
        color: AppColors.fondoGeneral,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 96), // bottom deja espacio al NavigationBar (extendBody)
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Indicador de pasos ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: AppStepIndicator(
                    currentStep: _paso,
                    totalSteps: 3,
                    labels: const ['Correo', 'Pregunta', 'Contraseña'],
                  ),
                ),
                AppTheme.spacer16,

                // ── Paso 1: correo ────────────────────────────────────────
                if (_paso == 1) ...[
                  AppFormCard(
                    maxWidth: 580,
                    header: const AppFormHeader(
                      icon: Icons.mail_outline,
                      title: 'Recuperar cuenta',
                      caption:
                          'Ingresa el correo asociado a tu cuenta para continuar.',
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          hintText: 'Correo registrado',
                          labelText: 'Correo registrado',
                          prefixIcon: const Icon(Icons.email_outlined),
                          textInputAction: TextInputAction.done,
                          validator: FormValidators.requiredEmail,
                        ),
                        AppTheme.spacer24,
                        _botonAccion(
                          'Continuar',
                          _trabajando ? null : _solicitarPregunta,
                        ),
                      ],
                    ),
                  ),
                ]

                // ── Paso 2: pregunta secreta ──────────────────────────────
                else if (_paso == 2) ...[
                  AppFormCard(
                    maxWidth: 580,
                    header: const AppFormHeader(
                      icon: Icons.help_outline,
                      title: 'Pregunta secreta',
                      caption: 'Responde la pregunta de seguridad de tu cuenta.',
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.fondoGeneral,
                            borderRadius: AppTheme.radius12,
                            border: Border.all(
                              color: AppColors.rosaBeigeClaro.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.security_outlined,
                                size: 20,
                                color: AppColors.terracota,
                              ),
                              AppTheme.widthSpacer10,
                              Expanded(
                                child: Text(
                                  _pregunta ?? '',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.cafeOscuro,
                                        height: 1.4,
                                        letterSpacing: 0.2,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppTheme.spacer16,
                        AppFormField(
                          controller: _respuestaCtrl,
                          hintText: 'Respuesta',
                          labelText: 'Respuesta',
                          prefixIcon: const Icon(Icons.edit_note_outlined),
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.done,
                          validator: (v) => FormValidators.requiredText(
                            v,
                            'La respuesta',
                            min: 2,
                            max: 60,
                          ),
                        ),
                        AppTheme.spacer24,
                        _botonAccion(
                          'Verificar respuesta',
                          _trabajando ? null : _verificarRespuesta,
                        ),
                      ],
                    ),
                  ),
                ]

                // ── Paso 3: nueva contraseña ──────────────────────────────
                else ...[
                  AppFormCard(
                    maxWidth: 580,
                    header: const AppFormHeader(
                      icon: Icons.lock_reset_outlined,
                      title: 'Nueva contraseña',
                      caption: 'Crea una contraseña segura para tu cuenta.',
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppFormField(
                          controller: _nuevaCtrl,
                          obscureText: true,
                          hintText: 'Nueva contraseña',
                          labelText: 'Nueva contraseña',
                          prefixIcon: const Icon(Icons.vpn_key_outlined),
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Ingresa una contraseña';
                            }
                            if (!_passwordRegex.hasMatch(v)) {
                              return 'Mínimo 12 caracteres, una mayúscula, un número y un símbolo';
                            }
                            return null;
                          },
                        ),
                        AppTheme.spacer12,
                        AppPasswordRequirements(password: _nuevaCtrl.text),
                        AppTheme.spacer12,
                        AppFormField(
                          controller: _confirmCtrl,
                          obscureText: true,
                          hintText: 'Confirmar contraseña',
                          labelText: 'Confirmar contraseña',
                          prefixIcon: const Icon(Icons.check_circle_outline),
                          textInputAction: TextInputAction.done,
                          validator: (v) => (v != _nuevaCtrl.text)
                              ? 'Las contraseñas no coinciden'
                              : null,
                        ),
                        AppTheme.spacer24,
                        _botonAccion(
                          'Restablecer contraseña',
                          _trabajando ? null : _cambiarContrasena,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
