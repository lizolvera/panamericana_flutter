import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../shared/form_validators.dart';
import '../../../theme/app_colors.dart';
import '../../shell/shell_scaffold.dart';

/// **View de recuperación de cuenta**: flujo de 3 pasos igual a la web:
/// 1) correo → 2) responder pregunta secreta → 3) nueva contraseña.
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
        const SnackBar(
          content: Text('Contraseña restablecida. Inicia sesión.'),
          backgroundColor: AppColors.vino,
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
      SnackBar(content: Text(mensaje), backgroundColor: AppColors.vinoOscuro),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ShellScaffold(
      titleText: 'Recuperar cuenta',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Indicador de paso
              Text(
                'Paso $_paso de 3',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.terracota,
                ),
              ),
              const SizedBox(height: 16),
              if (_paso == 1) ...[
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  inputFormatters: [FormValidators.noSpacesFormatter],
                  decoration: const InputDecoration(
                    labelText: 'Correo registrado *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => FormValidators.requiredEmail(v),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _trabajando ? null : _solicitarPregunta,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.vino,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: _trabajando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Continuar'),
                ),
              ] else if (_paso == 2) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.blancoCalido,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.rosaBeigeClaro),
                  ),
                  child: Text(
                    'Pregunta secreta:\n$_pregunta',
                    style: const TextStyle(height: 1.5),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _respuestaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Respuesta *',
                    border: OutlineInputBorder(),
                  ),
                  validator: FormValidators.requiredSecretAnswer,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _trabajando ? null : _verificarRespuesta,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.vino,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: _trabajando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Verificar respuesta'),
                ),
              ] else ...[
                TextFormField(
                  controller: _nuevaCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nueva contraseña *',
                    border: OutlineInputBorder(),
                  ),
                  validator: FormValidators.requiredPassword,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contraseña *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      FormValidators.confirmPassword(v, _nuevaCtrl.text),
                ),
                const SizedBox(height: 8),
                const Text(
                  'La contraseña debe tener mínimo 12 caracteres e incluir '
                  'una mayúscula, un número y un símbolo.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _trabajando ? null : _cambiarContrasena,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.vino,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: _trabajando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Restablecer contraseña'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
