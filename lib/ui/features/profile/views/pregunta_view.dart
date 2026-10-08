import 'package:flutter/material.dart';

import '../../shell/shell_scaffold.dart';
import '../view_models/profile_view_model.dart';

/// Las 5 preguntas secretas soportadas por el backend.
const Map<String, String> _preguntas = {
  'personaje-favorito': '¿Cuál es tu personaje favorito?',
  'pelicula-favorita': '¿Cuál es tu película favorita?',
  'mejor-amigo': '¿Quién es tu mejor amigo?',
  'nombre-mascota': '¿Cuál es el nombre de tu mascota?',
  'deporte-favorito': '¿Cuál es tu deporte favorito?',
};

/// **View de pregunta secreta**: configura la pregunta y respuesta de
/// recuperación de cuenta.
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
      SnackBar(content: Text(_vm.mensaje ?? (ok ? 'Listo' : 'Error'))),
    );
    if (ok) _vm.reiniciarAccion();
  }

  @override
  Widget build(BuildContext context) {
    return ShellScaffold(
      titleText: 'Pregunta secreta',
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final perfil = _vm.perfil;

          if (perfil != null && !_rellenado) {
            _rellenado = true;
            _pregunta = _preguntas.containsKey(perfil.preguntaSecreta)
                ? perfil.preguntaSecreta
                : null;
          }

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
                    'Pregunta secreta',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _pregunta,
                    items: _preguntas.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _pregunta = v),
                    decoration: const InputDecoration(
                      labelText: 'Pregunta secreta',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null ? 'Selecciona una pregunta' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _respuestaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Respuesta secreta',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'La respuesta es obligatoria'
                        : null,
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
                        : const Text('Guardar pregunta'),
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
