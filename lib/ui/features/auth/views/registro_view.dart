import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../shared/form_validators.dart';
import '../../../shared/preguntas_secretas.dart';
import '../../../theme/app_colors.dart';
import '../../shell/shell_scaffold.dart';

/// **View de registro**: crea una cuenta nueva (POST /api/usuarios/register)
/// con validaciones iguales a la web (letras, correo, teléfono, contraseña
/// fuerte y pregunta secreta).
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
        const SnackBar(
          content: Text('Cuenta creada con éxito. Inicia sesión.'),
          backgroundColor: AppColors.vino,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreCtrl,
                inputFormatters: [FormValidators.lettersOnlyFormatter],
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => FormValidators.requiredLetters(v, 'El nombre'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _apCtrl,
                      inputFormatters: [FormValidators.lettersOnlyFormatter],
                      decoration: const InputDecoration(
                        labelText: 'Apellido paterno',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          FormValidators.optionalLetters(v, 'El apellido paterno'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _amCtrl,
                      inputFormatters: [FormValidators.lettersOnlyFormatter],
                      decoration: const InputDecoration(
                        labelText: 'Apellido materno',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          FormValidators.optionalLetters(v, 'El apellido materno'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => FormValidators.requiredEmail(v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefonoCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [FormValidators.digitsOnlyFormatter],
                decoration: const InputDecoration(
                  labelText: 'Teléfono (10 dígitos) *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => FormValidators.requiredPhone(v),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _elegirFecha,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de nacimiento *',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _fechaNacimiento == null
                        ? 'Selecciona tu fecha'
                        : '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                  if (!_passwordRegex.hasMatch(v)) {
                    return 'Mínimo 12 caracteres, una mayúscula, un número y un símbolo';
                  }
                  return null;
                },
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
                    (v != _passwordCtrl.text) ? 'Las contraseñas no coinciden' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _preguntaSecreta,
                items: kPreguntasSecretas.entries
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _preguntaSecreta = v),
                decoration: const InputDecoration(
                  labelText: 'Pregunta secreta *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null ? 'Selecciona una pregunta' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _respuestaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Respuesta secreta *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    FormValidators.requiredText(v, 'La respuesta', min: 2, max: 60),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _guardando ? null : _registrar,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.vino,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _guardando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Crear cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
