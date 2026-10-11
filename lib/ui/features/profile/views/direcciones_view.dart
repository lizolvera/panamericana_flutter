import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/models/direccion.dart';
import '../../../shared/form_validators.dart';
import '../../../theme/app_colors.dart';
import '../../shell/shell_scaffold.dart';
import '../view_models/direcciones_view_model.dart';

/// **View de direcciones**: lista, alta, edición, eliminación y marcado de
/// dirección predeterminada (CRUD contra /api/usuarios/direcciones).
class DireccionesView extends StatelessWidget {
  const DireccionesView({super.key, required this.direccionesVm});

  final DireccionesViewModel direccionesVm;

  Future<void> _abrirDialog(
    BuildContext context,
    DireccionesViewModel vm, {
    Direccion? existente,
  }) async {
    final datos = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _DialogDireccion(existente: existente),
    );
    if (datos == null) return;

    final ok = existente?.id != null
        ? await vm.actualizar(existente!.id!, datos)
        : await vm.crear(datos);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(vm.error ?? (ok ? 'Dirección guardada' : 'Error'))),
    );
  }

  Future<void> _confirmarEliminar(
    BuildContext context,
    DireccionesViewModel vm,
    Direccion direccion,
  ) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar dirección'),
        content: Text('¿Eliminar "${direccion.alias}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    final ok = await vm.eliminar(direccion.id!);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(vm.error ?? (ok ? 'Dirección eliminada' : 'Error'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ShellScaffold(
      titleText: 'Mis direcciones',
      fab: FloatingActionButton(
        onPressed: () => _abrirDialog(context, direccionesVm),
        tooltip: 'Agregar dirección',
        child: const Icon(Icons.add),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Mis direcciones',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: direccionesVm,
                  builder: (context, _) => _cuerpo(context, direccionesVm),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cuerpo(BuildContext context, DireccionesViewModel vm) {
    switch (vm.status) {
      case DireccionesStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case DireccionesStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off,
                size: 48,
                color: AppColors.terracota,
              ),
              const SizedBox(height: 8),
              Text(vm.error ?? 'Error al cargar direcciones'),
              const SizedBox(height: 12),
              FilledButton(onPressed: vm.load, child: const Text('Reintentar')),
            ],
          ),
        );
      case DireccionesStatus.initial:
      case DireccionesStatus.loaded:
        if (vm.direcciones.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Aún no tienes direcciones.\nToca + para agregar una.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 88),
          itemCount: vm.direcciones.length,
          itemBuilder: (context, i) {
            final d = vm.direcciones[i];
            return _DireccionCard(
              direccion: d,
              onEditar: () => _abrirDialog(context, vm, existente: d),
              onEliminar: () => _confirmarEliminar(context, vm, d),
              onPredeterminada: () async {
                final ok = await vm.marcarPredeterminada(d.id!);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      vm.error ?? (ok ? 'Dirección predeterminada' : 'Error'),
                    ),
                  ),
                );
              },
            );
          },
        );
    }
  }
}

class _DireccionCard extends StatelessWidget {
  const _DireccionCard({
    required this.direccion,
    required this.onEditar,
    required this.onEliminar,
    required this.onPredeterminada,
  });

  final Direccion direccion;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  final VoidCallback onPredeterminada;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        direccion.alias,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (direccion.predeterminada) ...[
                        const SizedBox(width: 8),
                        Chip(
                          label: const Text('Predeterminada'),
                          visualDensity: VisualDensity.compact,
                          backgroundColor:
                              theme.colorScheme.primaryContainer,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (opcion) {
                    switch (opcion) {
                      case 'editar':
                        onEditar();
                      case 'predeterminada':
                        onPredeterminada();
                      case 'eliminar':
                        onEliminar();
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'editar',
                      child: Text('Editar'),
                    ),
                    const PopupMenuItem(
                      value: 'predeterminada',
                      child: Text('Marcar predeterminada'),
                    ),
                    const PopupMenuItem(
                      value: 'eliminar',
                      child: Text('Eliminar'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${direccion.calle}${direccion.colonia != null && direccion.colonia!.isNotEmpty ? ', ${direccion.colonia}' : ''}'),
            Text('${direccion.ciudad}, ${direccion.estado} · CP ${direccion.cp}'),
            Text('Tel: ${direccion.telefono}'),
          ],
        ),
      ),
    );
  }
}

/// Diálogo de alta/edición de una dirección.
class _DialogDireccion extends StatefulWidget {
  const _DialogDireccion({this.existente});

  final Direccion? existente;

  @override
  State<_DialogDireccion> createState() => _DialogDireccionState();
}

class _DialogDireccionState extends State<_DialogDireccion> {
  final _formKey = GlobalKey<FormState>();
  late final _aliasCtrl = TextEditingController(text: widget.existente?.alias ?? '');
  late final _calleCtrl = TextEditingController(text: widget.existente?.calle ?? '');
  late final _coloniaCtrl = TextEditingController(text: widget.existente?.colonia ?? '');
  late final _ciudadCtrl = TextEditingController(text: widget.existente?.ciudad ?? '');
  late final _estadoCtrl = TextEditingController(text: widget.existente?.estado ?? '');
  late final _cpCtrl = TextEditingController(text: widget.existente?.cp ?? '');
  late final _telefonoCtrl = TextEditingController(text: widget.existente?.telefono ?? '');
  late final _refsCtrl = TextEditingController(text: widget.existente?.referencias ?? '');
  late bool _predeterminada = widget.existente?.predeterminada ?? false;

  @override
  void dispose() {
    _aliasCtrl.dispose();
    _calleCtrl.dispose();
    _coloniaCtrl.dispose();
    _ciudadCtrl.dispose();
    _estadoCtrl.dispose();
    _cpCtrl.dispose();
    _telefonoCtrl.dispose();
    _refsCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop({
      'alias': _aliasCtrl.text.trim(),
      'calle': _calleCtrl.text.trim(),
      'colonia': _coloniaCtrl.text.trim(),
      'ciudad': _ciudadCtrl.text.trim(),
      'estado': _estadoCtrl.text.trim(),
      'cp': _cpCtrl.text.trim(),
      'telefono': _telefonoCtrl.text.trim(),
      'referencias': _refsCtrl.text.trim(),
      'predeterminada': _predeterminada,
    });
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.blancoCalido,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 6),
      contentPadding: const EdgeInsets.fromLTRB(24, 10, 24, 4),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Text(
        widget.existente == null ? 'Nueva dirección' : 'Editar dirección',
        style: const TextStyle(
          color: AppColors.cafeOscuro,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _aliasCtrl,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [
                  FormValidators.addressFormatter,
                  LengthLimitingTextInputFormatter(40),
                ],
                decoration: _fieldDecoration('Alias (ej. Casa)'),
                validator: (v) =>
                    FormValidators.requiredAddressText(v, 'El alias'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _calleCtrl,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [
                  FormValidators.addressFormatter,
                  LengthLimitingTextInputFormatter(100),
                ],
                decoration: _fieldDecoration('Calle'),
                validator: (v) =>
                    FormValidators.requiredAddressText(v, 'La calle'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _coloniaCtrl,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [
                  FormValidators.addressFormatter,
                  LengthLimitingTextInputFormatter(80),
                ],
                decoration: _fieldDecoration('Colonia'),
                validator: (v) =>
                    FormValidators.optionalAddressText(v, 'La colonia'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ciudadCtrl,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [
                        FormValidators.lettersOnlyFormatter,
                        LengthLimitingTextInputFormatter(60),
                      ],
                      decoration: _fieldDecoration('Ciudad'),
                      validator: (v) =>
                          FormValidators.requiredLetters(v, 'La ciudad'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _estadoCtrl,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [
                        FormValidators.lettersOnlyFormatter,
                        LengthLimitingTextInputFormatter(60),
                      ],
                      decoration: _fieldDecoration('Estado'),
                      validator: (v) =>
                          FormValidators.requiredLetters(v, 'El estado'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cpCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FormValidators.digitsOnlyFormatter,
                        LengthLimitingTextInputFormatter(5),
                      ],
                      decoration: _fieldDecoration('CP'),
                      validator: FormValidators.requiredPostalCode,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _telefonoCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FormValidators.digitsOnlyFormatter,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: _fieldDecoration('Teléfono'),
                      validator: FormValidators.requiredPhone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _refsCtrl,
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: [
                  FormValidators.addressFormatter,
                  LengthLimitingTextInputFormatter(120),
                ],
                decoration: _fieldDecoration('Referencias'),
                validator: (v) =>
                    FormValidators.optionalAddressText(v, 'Las referencias'),
              ),
              const SizedBox(height: 6),
              CheckboxListTile(
                value: _predeterminada,
                onChanged: (v) => setState(() => _predeterminada = v ?? false),
                title: const Text('Predeterminada'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardar,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
