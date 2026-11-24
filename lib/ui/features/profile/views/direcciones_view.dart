import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/models/direccion.dart';
import '../../../shared/form_validators.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../shell/shell_scaffold.dart';
import '../view_models/direcciones_view_model.dart';

/// **View de direcciones**: lista, alta, edición, eliminación y marcado de
/// dirección predeterminada (CRUD contra /api/usuarios/direcciones).
///
/// Diseño boutique: tarjetas con icono y chip, y diálogo de alta/edición con
/// encabezado, secciones y botones Cancelar/Guardar en fila horizontal.
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
      SnackBar(
        content: Text(vm.error ?? (ok ? 'Dirección guardada' : 'Error')),
        backgroundColor: ok ? AppColors.vino : AppColors.vinoOscuro,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radius12),
      ),
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
        backgroundColor: AppColors.blancoCalido,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radius20),
        titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        actionsAlignment: MainAxisAlignment.end,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.vino,
                borderRadius: AppTheme.radius10,
              ),
              child: const Icon(
                Icons.delete_outline,
                size: 20,
                color: AppColors.blancoCalido,
              ),
            ),
            AppTheme.widthSpacer12,
            Expanded(
              child: Text(
                'Eliminar dirección',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.cafeOscuro,
                    ),
              ),
            ),
          ],
        ),
        content: Text(
          '¿Eliminar "${direccion.alias}"? Esta acción no se puede deshacer.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.cafeOscuro.withValues(alpha: 0.7),
                height: 1.4,
              ),
        ),
        actions: [
          AppTextButton(
            onPressed: () => Navigator.of(context).pop(false),
            text: 'Cancelar',
            color: AppColors.cafeOscuro.withValues(alpha: 0.6),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.vino,
              foregroundColor: AppColors.blancoCalido,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radius12),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    final ok = await vm.eliminar(direccion.id!);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(vm.error ?? (ok ? 'Dirección eliminada' : 'Error')),
        backgroundColor: ok ? AppColors.vino : AppColors.vinoOscuro,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radius12),
      ),
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
      body: Container(
        color: AppColors.fondoGeneral,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
                  child: AppFormHeader(
                    icon: Icons.location_on_outlined,
                    title: 'Mis direcciones',
                    caption: 'Administra tus direcciones de envío.',
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
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.rosaBeigeClaro.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off,
                  size: 32,
                  color: AppColors.terracota,
                ),
              ),
              AppTheme.spacer12,
              Text(
                vm.error ?? 'Error al cargar direcciones',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.cafeOscuro,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              AppTheme.spacer16,
              AppPrimaryButton(
                onPressed: vm.load,
                text: 'Reintentar',
              ),
            ],
          ),
        );
      case DireccionesStatus.initial:
      case DireccionesStatus.loaded:
        if (vm.direcciones.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.blancoCalido,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.rosaBeigeClaro),
                      boxShadow: [AppTheme.cardShadow],
                    ),
                    child: const Icon(
                      Icons.location_off_outlined,
                      size: 34,
                      color: AppColors.terracota,
                    ),
                  ),
                  AppTheme.spacer16,
                  Text(
                    'Aún no tienes direcciones.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.cafeOscuro,
                        ),
                  ),
                  AppTheme.spacer4,
                  Text(
                    'Toca el botón + para agregar una.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.cafeOscuro.withValues(alpha: 0.55),
                        ),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 88),
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
                    backgroundColor: ok ? AppColors.vino : AppColors.vinoOscuro,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.radius12,
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

/// Tarjeta boutique de una dirección guardada.
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blancoCalido,
        borderRadius: AppTheme.radius16,
        border: Border.all(color: AppColors.rosaBeigeClaro.withValues(alpha: 0.7)),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.rosaBeigeClaro.withValues(alpha: 0.55),
              borderRadius: AppTheme.radius12,
            ),
            child: const Icon(
              Icons.location_on_outlined,
              size: 22,
              color: AppColors.vino,
            ),
          ),
          AppTheme.widthSpacer12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        direccion.alias,
                        style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.cafeOscuro,
                              letterSpacing: -0.3,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (direccion.predeterminada) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.vino,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Predeterminada',
                          style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.blancoCalido,
                                letterSpacing: 0.4,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
                AppTheme.spacer6,
                _LineaIcono(
                  icon: Icons.signpost_outlined,
                  texto:
                      '${direccion.calle}${direccion.colonia != null && direccion.colonia!.isNotEmpty ? ', ${direccion.colonia}' : ''}',
                ),
                _LineaIcono(
                  icon: Icons.location_city_outlined,
                  texto:
                      '${direccion.ciudad}, ${direccion.estado} · CP ${direccion.cp}',
                ),
                _LineaIcono(
                  icon: Icons.phone_outlined,
                  texto: 'Tel: ${direccion.telefono}',
                ),
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
    );
  }
}

class _LineaIcono extends StatelessWidget {
  const _LineaIcono({required this.icon, required this.texto});

  final IconData icon;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.terracota),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.cafeOscuro.withValues(alpha: 0.65),
                    letterSpacing: 0.2,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Diálogo de alta/edición de una dirección con diseño boutique:
/// encabezado con icono, secciones, campos estilizados y acciones
/// Cancelar/Guardar en fila horizontal a mismo ancho.
class _DialogDireccion extends StatefulWidget {
  const _DialogDireccion({this.existente});

  final Direccion? existente;

  @override
  State<_DialogDireccion> createState() => _DialogDireccionState();
}

class _DialogDireccionState extends State<_DialogDireccion> {
  final _formKey = GlobalKey<FormState>();
  late final _aliasCtrl =
      TextEditingController(text: widget.existente?.alias ?? '');
  late final _calleCtrl =
      TextEditingController(text: widget.existente?.calle ?? '');
  late final _coloniaCtrl =
      TextEditingController(text: widget.existente?.colonia ?? '');
  late final _ciudadCtrl =
      TextEditingController(text: widget.existente?.ciudad ?? '');
  late final _estadoCtrl =
      TextEditingController(text: widget.existente?.estado ?? '');
  late final _cpCtrl = TextEditingController(text: widget.existente?.cp ?? '');
  late final _telefonoCtrl =
      TextEditingController(text: widget.existente?.telefono ?? '');
  late final _refsCtrl =
      TextEditingController(text: widget.existente?.referencias ?? '');
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

  @override
  Widget build(BuildContext context) {
    final editando = widget.existente != null;
    return Dialog(
      backgroundColor: AppColors.blancoCalido,
      shape: RoundedRectangleBorder(borderRadius: AppTheme.radius20),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Encabezado ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.vino,
                      borderRadius: AppTheme.radius14,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.vinoOscuro.withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      editando ? Icons.edit_location_alt_outlined : Icons.add_location_alt_outlined,
                      size: 22,
                      color: AppColors.blancoCalido,
                    ),
                  ),
                  AppTheme.widthSpacer14,
                  Expanded(
                    child: Text(
                      editando ? 'Editar dirección' : 'Nueva dirección',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.cafeOscuro,
                            letterSpacing: -0.5,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 22),
                    color: AppColors.cafeOscuro.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Divider(
                height: 1,
                thickness: 1,
                color: AppColors.rosaBeigeClaro,
              ),
            ),

            // ── Formulario ────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppFormSectionLabel('Ubicación'),
                      AppFormField(
                        controller: _aliasCtrl,
                        labelText: 'Alias (ej. Casa)',
                        hintText: 'Ej. Casa, Oficina',
                        prefixIcon: const Icon(Icons.label_outline),
                        textCapitalization: TextCapitalization.words,
                        inputFormatters: [
                          FormValidators.addressFormatter,
                          LengthLimitingTextInputFormatter(40),
                        ],
                        validator: (v) =>
                            FormValidators.requiredAddressText(v, 'El alias'),
                      ),
                      AppTheme.spacer12,
                      AppFormField(
                        controller: _calleCtrl,
                        labelText: 'Calle',
                        hintText: 'Calle y número',
                        prefixIcon: const Icon(Icons.signpost_outlined),
                        textCapitalization: TextCapitalization.words,
                        inputFormatters: [
                          FormValidators.addressFormatter,
                          LengthLimitingTextInputFormatter(100),
                        ],
                        validator: (v) =>
                            FormValidators.requiredAddressText(v, 'La calle'),
                      ),
                      AppTheme.spacer12,
                      AppFormField(
                        controller: _coloniaCtrl,
                        labelText: 'Colonia',
                        prefixIcon: const Icon(Icons.location_city_outlined),
                        textCapitalization: TextCapitalization.words,
                        inputFormatters: [
                          FormValidators.addressFormatter,
                          LengthLimitingTextInputFormatter(80),
                        ],
                        validator: (v) => FormValidators.optionalAddressText(
                          v,
                          'La colonia',
                        ),
                      ),
                      AppTheme.spacer12,
                      Row(
                        children: [
                          Expanded(
                            child: AppFormField(
                              controller: _ciudadCtrl,
                              labelText: 'Ciudad',
                              prefixIcon: const Icon(Icons.location_on_outlined),
                              textCapitalization: TextCapitalization.words,
                              inputFormatters: [
                                FormValidators.lettersOnlyFormatter,
                                LengthLimitingTextInputFormatter(60),
                              ],
                              validator: (v) =>
                                  FormValidators.requiredLetters(v, 'La ciudad'),
                            ),
                          ),
                          AppTheme.widthSpacer12,
                          Expanded(
                            child: AppFormField(
                              controller: _estadoCtrl,
                              labelText: 'Estado',
                              textCapitalization: TextCapitalization.words,
                              inputFormatters: [
                                FormValidators.lettersOnlyFormatter,
                                LengthLimitingTextInputFormatter(60),
                              ],
                              validator: (v) =>
                                  FormValidators.requiredLetters(v, 'El estado'),
                            ),
                          ),
                        ],
                      ),
                      AppTheme.spacer12,
                      Row(
                        children: [
                          Expanded(
                            child: AppFormField(
                              controller: _cpCtrl,
                              labelText: 'CP',
                              hintText: '5 dígitos',
                              prefixIcon: const Icon(Icons.markunread_mailbox_outlined),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FormValidators.digitsOnlyFormatter,
                                LengthLimitingTextInputFormatter(5),
                              ],
                              validator: FormValidators.requiredPostalCode,
                            ),
                          ),
                          AppTheme.widthSpacer12,
                          Expanded(
                            child: AppFormField(
                              controller: _telefonoCtrl,
                              labelText: 'Teléfono',
                              hintText: '10 dígitos',
                              prefixIcon: const Icon(Icons.phone_outlined),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FormValidators.digitsOnlyFormatter,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              validator: FormValidators.requiredPhone,
                            ),
                          ),
                        ],
                      ),
                      AppTheme.spacer20,
                      AppFormSectionLabel('Detalles'),
                      AppFormField(
                        controller: _refsCtrl,
                        labelText: 'Referencias',
                        hintText: 'Ej. Puerta azul, frente al parque',
                        prefixIcon: const Icon(Icons.notes_outlined),
                        textCapitalization: TextCapitalization.sentences,
                        inputFormatters: [
                          FormValidators.addressFormatter,
                          LengthLimitingTextInputFormatter(120),
                        ],
                        validator: (v) => FormValidators.optionalAddressText(
                          v,
                          'Las referencias',
                        ),
                      ),
                      AppTheme.spacer12,
                      Material(
                        color: AppColors.fondoGeneral,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppTheme.radius12,
                          side: BorderSide(
                            color: AppColors.rosaBeigeClaro.withValues(alpha: 0.6),
                          ),
                        ),
                        child: CheckboxListTile(
                          value: _predeterminada,
                          onChanged: (v) =>
                              setState(() => _predeterminada = v ?? false),
                          title: Text(
                            'Predeterminada',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.cafeOscuro,
                                ),
                          ),
                          subtitle: Text(
                            'Usar como dirección de envío por defecto',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.cafeOscuro.withValues(alpha: 0.5),
                                ),
                          ),
                          activeColor: AppColors.vino,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Acciones: Cancelar / Guardar en fila, mismo ancho ──────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: AppFormActions(
                cancelLabel: 'Cancelar',
                onCancel: () => Navigator.of(context).pop(),
                primaryLabel: 'Guardar',
                onPrimary: _guardar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
