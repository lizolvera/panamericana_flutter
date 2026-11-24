import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../shared/form_validators.dart';
import '../../../shared/preguntas_secretas.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../../shell/shell_scaffold.dart';

/// **View de registro**: crea una cuenta nueva (POST /api/usuarios/register)
/// con validaciones iguales a la web (letras, correo, teléfono, contraseña
/// fuerte y pregunta secreta).
///
/// Diseño boutique: formulario en tarjeta con secciones (datos personales,
/// contacto, seguridad), campos con iconos y botón primario con carga.
class RegistroView extends StatefulWidget {
  const RegistroView({super.key});

  @override
  State<RegistroView> createState() => _RegistroViewState();
}

class _RegistroViewState extends State<RegistroView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apCtrl = TextEditingController();
  final _amCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _respuestaCtrl = TextEditingController();
  DateTime? _fechaNacimiento;
  String? _preguntaSecreta;
  bool _guardando = false;

  static final RegExp _passwordRegex =
      RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z0-9]).{12,}$');

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apCtrl.dispose();
    _amCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _respuestaCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime(hoy.year - 18),
      firstDate: DateTime(1950),
      lastDate: hoy,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: AppColors.vino,
                      onPrimary: AppColors.blancoCalido,
                      surface: AppColors.blancoCalido,
                      onSurface: AppColors.cafeOscuro,
                    ),
              ),
          child: child!,
        );
      },
    );
    if (fecha != null) setState(() => _fechaNacimiento = fecha);
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final repo = context.read<AuthRepository>();
    try {
      await repo.register({
        'nombre': _nombreCtrl.text.trim(),
        'ap': _apCtrl.text.trim(),
        'am': _amCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'telefono': _telefonoCtrl.text.trim(),
        'password': _passwordCtrl.text,
        'preguntaSecreta': _preguntaSecreta,
        'respuestaSecreta': _respuestaCtrl.text.trim(),
        if (_fechaNacimiento != null)
          'fechaNacimiento':
              '${_fechaNacimiento!.year}-${_fechaNacimiento!.month.toString().padLeft(2, '0')}-${_fechaNacimiento!.day.toString().padLeft(2, '0')}',
      });

      if (!mounted) return;
      // El mensaje lo muestra el messenger raíz, sobrevive a la navegación.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cuenta creada con éxito. Inicia sesión.'),
          backgroundColor: AppColors.vino,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final mensaje = _extractError(e);
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
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  String _extractError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic> && data['error'] != null) {
        return data['error'].toString();
      }
    }
    return 'No se pudo crear la cuenta. Intenta de nuevo.';
  }

  @override
  Widget build(BuildContext context) {
    return ShellScaffold(
      titleText: 'Crear cuenta',
      body: Container(
        color: AppColors.fondoGeneral,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 96), // bottom deja espacio al NavigationBar (extendBody)
          child: Form(
            key: _formKey,
            child: AppFormCard(
              maxWidth: 580,
              header: const AppFormHeader(
                icon: Icons.person_add_alt_1_outlined,
                title: 'Crear cuenta',
                caption: 'Completa tus datos para registrarte en Panamericana.',
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Datos personales ──────────────────────────────────────
                  const AppFormSectionLabel('Datos personales'),
                  AppFormField(
                    controller: _nombreCtrl,
                    labelText: 'Nombre *',
                    hintText: 'Nombre *',
                    prefixIcon: const Icon(Icons.person_outline),
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [FormValidators.lettersOnlyFormatter],
                    validator: (v) =>
                        FormValidators.requiredLetters(v, 'El nombre'),
                  ),
                  AppTheme.spacer12,
                  Row(
                    children: [
                      Expanded(
                        child: AppFormField(
                          controller: _apCtrl,
                          labelText: 'Apellido paterno',
                          hintText: 'Apellido paterno',
                          textCapitalization: TextCapitalization.words,
                          inputFormatters: [
                            FormValidators.lettersOnlyFormatter
                          ],
                          validator: (v) => FormValidators.optionalLetters(
                            v,
                            'El apellido paterno',
                          ),
                        ),
                      ),
                      AppTheme.widthSpacer12,
                      Expanded(
                        child: AppFormField(
                          controller: _amCtrl,
                          labelText: 'Apellido materno',
                          hintText: 'Apellido materno',
                          textCapitalization: TextCapitalization.words,
                          inputFormatters: [
                            FormValidators.lettersOnlyFormatter
                          ],
                          validator: (v) => FormValidators.optionalLetters(
                            v,
                            'El apellido materno',
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppTheme.spacer12,
                  AppDateField(
                    labelText: 'Fecha de nacimiento *',
                    date: _fechaNacimiento,
                    onTap: _elegirFecha,
                  ),
                  AppTheme.spacer20,

                  // ── Contacto ──────────────────────────────────────────────
                  const AppFormSectionLabel('Contacto'),
                  AppFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    labelText: 'Correo *',
                    hintText: 'Correo *',
                    prefixIcon: const Icon(Icons.email_outlined),
                    validator: (v) => FormValidators.requiredEmail(v),
                  ),
                  AppTheme.spacer12,
                  AppFormField(
                    controller: _telefonoCtrl,
                    keyboardType: TextInputType.phone,
                    labelText: 'Teléfono (10 dígitos) *',
                    hintText: 'Teléfono (10 dígitos) *',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    inputFormatters: [FormValidators.digitsOnlyFormatter],
                    validator: (v) => FormValidators.requiredPhone(v),
                  ),
                  AppTheme.spacer20,

                  // ── Seguridad ─────────────────────────────────────────────
                  const AppFormSectionLabel('Seguridad'),
                  AppFormField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    labelText: 'Contraseña *',
                    hintText: 'Contraseña *',
                    prefixIcon: const Icon(Icons.lock_outline),
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
                  AppPasswordRequirements(password: _passwordCtrl.text),
                  AppTheme.spacer12,
                  AppFormField(
                    controller: _confirmCtrl,
                    obscureText: true,
                    labelText: 'Confirmar contraseña *',
                    hintText: 'Confirmar contraseña *',
                    prefixIcon: const Icon(Icons.check_circle_outline),
                    validator: (v) => (v != _passwordCtrl.text)
                        ? 'Las contraseñas no coinciden'
                        : null,
                  ),
                  AppTheme.spacer12,
                  AppDropdownField<String>(
                    value: _preguntaSecreta,
                    labelText: 'Pregunta secreta *',
                    hintText: 'Selecciona una pregunta',
                    prefixIcon: const Icon(Icons.help_outline),
                    items: kPreguntasSecretas.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(
                              e.value,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(letterSpacing: 0.2),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _preguntaSecreta = v),
                    validator: (v) =>
                        v == null ? 'Selecciona una pregunta' : null,
                  ),
                  AppTheme.spacer12,
                  AppFormField(
                    controller: _respuestaCtrl,
                    labelText: 'Respuesta secreta *',
                    hintText: 'Respuesta secreta *',
                    prefixIcon: const Icon(Icons.edit_note_outlined),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) => FormValidators.requiredText(
                      v,
                      'La respuesta',
                      min: 2,
                      max: 60,
                    ),
                  ),
                  AppTheme.spacer24,
                  AppPrimaryButton(
                    onPressed: _guardando ? null : _registrar,
                    text: 'Crear cuenta',
                    child: _guardando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.blancoCalido,
                            ),
                          )
                        : null,
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
