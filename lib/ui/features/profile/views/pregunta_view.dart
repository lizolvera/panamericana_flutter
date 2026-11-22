import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/form_validators.dart';
import '../../../shared/preguntas_secretas.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../shell/shell_scaffold.dart';
import '../view_models/profile_view_model.dart';

/// **View de pregunta secreta**: configura la pregunta y respuesta de
/// recuperación de cuenta.
///
/// Diseño boutique: formulario dentro de una tarjeta blanca con encabezado
/// de icono, campos estilizados y botón primario con indicador de carga.
class PreguntaView extends StatefulWidget {
  const PreguntaView({super.key, required this.profileVm});

  final ProfileViewModel profileVm;

  @override
  State<PreguntaView> createState() => _PreguntaViewState();
}

class _PreguntaViewState extends State<PreguntaView> {
  final _formKey = GlobalKey<FormState>();
  final _respuestaCtrl = TextEditingController();
  String? _pregunta;
  bool _rellenado = false;

  ProfileViewModel get _vm => widget.profileVm;

  @override
  void dispose() {
    _respuestaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _vm.actualizarPregunta(
      preguntaSecreta: _pregunta!,
      respuestaSecreta: _respuestaCtrl.text.trim(),
    );
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
      titleText: 'Pregunta secreta',
      body: Container(
        color: AppColors.fondoGeneral,
        child: ListenableBuilder(
          listenable: _vm,
          builder: (context, _) {
            final perfil = _vm.perfil;

            if (perfil != null && !_rellenado) {
              _rellenado = true;
              _pregunta =
                  kPreguntasSecretas.containsKey(perfil.preguntaSecreta)
                      ? perfil.preguntaSecreta
                      : null;
            }

            final guardando = _vm.accion == AccionStatus.working;

            return SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 96), // bottom deja espacio al NavigationBar (extendBody)
              child: Form(
                    key: _formKey,
                    child: AppFormCard(
                      maxWidth: 580,
                      header: const AppFormHeader(
                        icon: Icons.security_outlined,
                        title: 'Pregunta secreta',
                        caption:
                            'Configura una pregunta de recuperación para proteger tu cuenta.',
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppDropdownField<String>(
                            value: _pregunta,
                            labelText: 'Pregunta secreta',
                            prefixIcon: const Icon(Icons.help_outline),
                            items: kPreguntasSecretas.entries
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _pregunta = v),
                            validator: (v) =>
                                v == null ? 'Selecciona una pregunta' : null,
                          ),
                          AppTheme.spacer16,
                          AppFormField(
                            controller: _respuestaCtrl,
                            labelText: 'Respuesta secreta',
                            hintText: 'Escribe tu respuesta',
                            prefixIcon: const Icon(Icons.edit_note_outlined),
                            textCapitalization: TextCapitalization.sentences,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(80),
                            ],
                            validator: (v) => FormValidators.requiredText(
                              v,
                              'La respuesta',
                              min: 3,
                              max: 80,
                            ),
                          ),
                          AppTheme.spacer24,
                          AppPrimaryButton(
                            onPressed: guardando ? null : _guardar,
                            text: 'Guardar pregunta',
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
