import 'package:flutter/material.dart';

import '../../../shared/widgets/widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../shell/shell_scaffold.dart';
import '../view_models/profile_view_model.dart';

/// **View de contraseña**: cambiar la contraseña actual (misma validación
/// que la web: mínimo 12 caracteres, mayúscula, número y símbolo).
///
/// Diseño boutique: tarjeta con encabezado, campos con iconos, indicador
/// visual de requisitos que se ilumina al escribir y botón primario.
class PasswordView extends StatefulWidget {
  const PasswordView({super.key, required this.profileVm});

  final ProfileViewModel profileVm;

  @override
  State<PasswordView> createState() => _PasswordViewState();
}

class _PasswordViewState extends State<PasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _ocultar = true;

  static final RegExp _patron = RegExp(
    r'^(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z0-9]).{12,}$',
  );

  ProfileViewModel get _vm => widget.profileVm;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _vm.cambiarContrasena(
      currentPassword: _currentCtrl.text,
      newPassword: _newCtrl.text,
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
    if (ok) {
      _vm.reiniciarAccion();
      _currentCtrl.clear();
      _newCtrl.clear();
      _confirmCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShellScaffold(
      titleText: 'Contraseña',
      body: Container(
        color: AppColors.fondoGeneral,
        child: ListenableBuilder(
          listenable: _vm,
          builder: (context, _) {
            final guardando = _vm.accion == AccionStatus.working;

            return SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 96), // bottom deja espacio al NavigationBar (extendBody)
              child: Form(
                key: _formKey,
                child: AppFormCard(
                  maxWidth: 580,
                  header: const AppFormHeader(
                    icon: Icons.lock_outline,
                    title: 'Cambiar contraseña',
                    caption:
                        'Elige una contraseña segura que no hayas usado antes.',
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppFormField(
                        controller: _currentCtrl,
                        obscureText: _ocultar,
                        labelText: 'Contraseña actual',
                        hintText: 'Tu contraseña actual',
                        prefixIcon: const Icon(Icons.lock_outline),
                        textInputAction: TextInputAction.next,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _ocultar
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _ocultar = !_ocultar),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Ingresa tu contraseña actual'
                            : null,
                      ),
                      AppTheme.spacer16,
                      AppFormField(
                        controller: _newCtrl,
                        obscureText: _ocultar,
                        labelText: 'Nueva contraseña',
                        hintText: 'Mínimo 12 caracteres',
                        prefixIcon: const Icon(Icons.vpn_key_outlined),
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Ingresa una contraseña';
                          }
                          if (!_patron.hasMatch(v)) {
                            return 'Mínimo 12 caracteres, una mayúscula, un número y un símbolo';
                          }
                          return null;
                        },
                      ),
                      AppTheme.spacer16,
                      AppFormField(
                        controller: _confirmCtrl,
                        obscureText: _ocultar,
                        labelText: 'Confirmar nueva contraseña',
                        hintText: 'Repite la nueva contraseña',
                        prefixIcon: const Icon(Icons.check_circle_outline),
                        textInputAction: TextInputAction.done,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Confirma tu nueva contraseña';
                          }
                          return v != _newCtrl.text
                              ? 'Las contraseñas no coinciden'
                              : null;
                        },
                      ),
                      AppTheme.spacer16,
                      AppPasswordRequirements(password: _newCtrl.text),
                      AppTheme.spacer24,
                      AppPrimaryButton(
                        onPressed: guardando ? null : _guardar,
                        text: 'Cambiar contraseña',
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
