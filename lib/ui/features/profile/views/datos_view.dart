import 'package:flutter/material.dart';

import '../../shell/shell_scaffold.dart';
import '../view_models/profile_view_model.dart';

/// **View de datos personales**: formulario de nombre, apellidos, fecha de
/// nacimiento y teléfono (el correo es solo lectura).
class DatosView extends StatefulWidget {
  const DatosView({super.key, required this.profileVm});

  final ProfileViewModel profileVm;

  @override
  State<DatosView> createState() => _DatosViewState();
}

class _DatosViewState extends State<DatosView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apCtrl = TextEditingController();
  final _amCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  DateTime? _fechaNacimiento;
  bool _rellenado = false;

  ProfileViewModel get _vm => widget.profileVm;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apCtrl.dispose();
    _amCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(hoy.year - 18),
      firstDate: DateTime(1950),
      lastDate: hoy,
    );
    if (fecha != null) setState(() => _fechaNacimiento = fecha);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _vm.actualizarDatos({
      'nombre': _nombreCtrl.text.trim(),
      'ap': _apCtrl.text.trim(),
      'am': _amCtrl.text.trim(),
      'telefono': _telefonoCtrl.text.trim(),
      if (_fechaNacimiento != null)
        'fechaNacimiento':
            '${_fechaNacimiento!.year}-${_fechaNacimiento!.month.toString().padLeft(2, '0')}-${_fechaNacimiento!.day.toString().padLeft(2, '0')}',
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_vm.mensaje ?? (ok ? 'Listo' : 'Error'))),
    );
    if (ok) _vm.reiniciarAccion();
  }

  @override
  Widget build(BuildContext context) {
    return ShellScaffold(
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final perfil = _vm.perfil;

          // Rellenar el formulario una sola vez cuando llegan los datos.
          if (perfil != null && !_rellenado) {
            _rellenado = true;
            _nombreCtrl.text = perfil.nombre;
            _apCtrl.text = perfil.ap ?? '';
            _amCtrl.text = perfil.am ?? '';
            _telefonoCtrl.text = perfil.telefono ?? '';
            _fechaNacimiento = perfil.fechaNacimiento;
          }

          final cargando = _vm.status == ProfileStatus.loading;
          final guardando = _vm.accion == AccionStatus.working;

          if (cargando) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Datos personales',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'El nombre es obligatorio'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _apCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Apellido paterno',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _amCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Apellido materno',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _telefonoCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'El teléfono es obligatorio'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: perfil?.email ?? '',
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Correo (no editable)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _elegirFecha,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de nacimiento',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _fechaNacimiento == null
                            ? 'Selecciona tu fecha'
                            : '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: guardando ? null : _guardar,
                    child: guardando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar cambios'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
        },
      ),
    );
  }
}
