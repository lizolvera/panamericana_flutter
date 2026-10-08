import 'package:flutter/material.dart';

import '../../shell/shell_scaffold.dart';
import '../view_models/profile_view_model.dart';

/// **View de contraseña**: cambiar la contraseña actual (misma validación
/// que la web: mínimo 12 caracteres, mayúscula, número y símbolo).
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
      SnackBar(content: Text(_vm.mensaje ?? (ok ? 'Listo' : 'Error'))),
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
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final guardando = _vm.accion == AccionStatus.working;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Cambiar contraseña',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _currentCtrl,
                        obscureText: _ocultar,
                        decoration: InputDecoration(
                          labelText: 'Contraseña actual',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _ocultar ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () =>
                                setState(() => _ocultar = !_ocultar),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Ingresa tu contraseña actual'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _newCtrl,
                        obscureText: _ocultar,
                        decoration: const InputDecoration(
                          labelText: 'Nueva contraseña',
                          border: OutlineInputBorder(),
                        ),
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
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: _ocultar,
                        decoration: const InputDecoration(
                          labelText: 'Confirmar nueva contraseña',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v != _newCtrl.text)
                            ? 'Las contraseñas no coinciden'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'La contraseña debe tener mínimo 12 caracteres e incluir '
                        'una mayúscula, un número y un símbolo.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
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
                            : const Text('Cambiar contraseña'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
