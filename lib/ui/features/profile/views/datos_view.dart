import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/form_validators.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../shell/shell_scaffold.dart';
import '../view_models/profile_view_model.dart';

/// **View de datos personales**: formulario de nombre, apellidos, fecha de
/// nacimiento y teléfono (el correo es solo lectura).
///
/// Diseño boutique: tarjeta con encabezado, campos con iconos y selector de
/// fecha estilizado.
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
  final _emailCtrl = TextEditingController();
  DateTime? _fechaNacimiento;
  bool _rellenado = false;

  ProfileViewModel get _vm => widget.profileVm;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apCtrl.dispose();
    _amCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(hoy.year - 18),
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
                dialogTheme: DialogThemeData(
                  backgroundColor: AppColors.blancoCalido,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.radius20,
                  ),
                ),
              ),
          child: child!,
        );
      },
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
      SnackBar(
        content: Text(_vm.mensaje ?? (ok ? 'Listo' : 'Error')),
        backgroundColor: ok ? AppColors.vino : AppColors.vinoOscuro,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radius12),
      ),
    );
    if (ok) _vm.reiniciarAccion();
  }

  @override
  Widget build(BuildContext context) {
    return ShellScaffold(
      titleText: 'Datos personales',
      body: Container(
        color: AppColors.fondoGeneral,
        child: ListenableBuilder(
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
              _emailCtrl.text = perfil.email ?? '';
              _fechaNacimiento = perfil.fechaNacimiento;
            }

            final cargando = _vm.status == ProfileStatus.loading;
            final guardando = _vm.accion == AccionStatus.working;

            if (cargando) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 96), // bottom deja espacio al NavigationBar (extendBody)
              child: Form(
                key: _formKey,
                child: AppFormCard(
                  maxWidth: 580,
                  header: const AppFormHeader(
                    icon: Icons.badge_outlined,
                    title: 'Datos personales',
                    caption:
                        'Actualiza la información básica de tu cuenta. El correo no se puede modificar.',
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppFormSectionLabel('Información personal'),
                      AppFormField(
                        controller: _nombreCtrl,
                        labelText: 'Nombre',
                        prefixIcon: const Icon(Icons.person_outline),
                        textCapitalization: TextCapitalization.words,
                        inputFormatters: [
                          FormValidators.lettersOnlyFormatter,
                          LengthLimitingTextInputFormatter(60),
                        ],
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
                              textCapitalization: TextCapitalization.words,
                              inputFormatters: [
                                FormValidators.lettersOnlyFormatter,
                                LengthLimitingTextInputFormatter(60),
                              ],
                              validator: (v) =>
                                  FormValidators.optionalLetters(
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
                              textCapitalization: TextCapitalization.words,
                              inputFormatters: [
                                FormValidators.lettersOnlyFormatter,
                                LengthLimitingTextInputFormatter(60),
                              ],
                              validator: (v) =>
                                  FormValidators.optionalLetters(
                                    v,
                                    'El apellido materno',
                                  ),
                            ),
                          ),
                        ],
                      ),
                      AppTheme.spacer20,
                      AppFormSectionLabel('Contacto'),
                      AppFormField(
                        controller: _telefonoCtrl,
                        labelText: 'Teléfono',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FormValidators.digitsOnlyFormatter,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: FormValidators.requiredPhone,
                      ),
                      AppTheme.spacer12,
                      AppFormField(
                        controller: _emailCtrl,
                        labelText: 'Correo (no editable)',
                        prefixIcon: const Icon(Icons.email_outlined),
                        enabled: false,
                      ),
                      AppTheme.spacer12,
                      AppDateField(
                        labelText: 'Fecha de nacimiento',
                        date: _fechaNacimiento,
                        hintText: 'Selecciona tu fecha',
                        onTap: _elegirFecha,
                      ),
                      AppTheme.spacer24,
                      AppPrimaryButton(
                        onPressed: guardando ? null : _guardar,
                        text: 'Guardar cambios',
                        child: guardando
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
            );
          },
        ),
      ),
    );
  }
}
