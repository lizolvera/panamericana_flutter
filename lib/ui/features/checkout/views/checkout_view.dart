import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/network/api_client.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/checkout_repository.dart';
import '../../../../domain/models/direccion.dart';
import '../../cart/view_models/cart_view_model.dart';
import '../../profile/views/direcciones_view.dart';
import '../../profile/view_models/direcciones_view_model.dart';

/// El pedido pendiente se recupera del servidor incluso tras cerrar la app.
class CheckoutView extends StatefulWidget {
  const CheckoutView({super.key, this.soloPedidos = false});
  final bool soloPedidos;
  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  late final CheckoutRepository _repository;
  List<Direccion> _direcciones = [];
  List<Map<String, dynamic>> _pedidos = [];
  Direccion? _direccion;
  Map<String, dynamic>? _orden;
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = CheckoutRepository(context.read<ApiClient>().dio);
    _cargar();
  }

  Future<void> _ejecutar(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      final data = e is DioException ? e.response?.data : null;
      setState(
        () => _error = data is Map && data['error'] != null
            ? data['error'].toString()
            : 'No se pudo completar la operación. Revisa tu conexión y reintenta.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cargar() => _ejecutar(() async {
    final authRepository = context.read<AuthRepository>();
    final pedidos = await _repository.pedidos();
    final direcciones = widget.soloPedidos
        ? <Direccion>[]
        : await authRepository.getDirecciones();
    if (!mounted) return;
    setState(() {
      _pedidos = pedidos;
      _direcciones = direcciones;
      _direccion = direcciones.isEmpty
          ? null
          : direcciones.firstWhere(
              (d) => d.predeterminada,
              orElse: () => direcciones.first,
            );
    });
  });

  Future<void> _abrirPaypal() async {
    final uri = Uri.tryParse(_orden?['approvalUrl']?.toString() ?? '');
    if (uri == null ||
        uri.scheme != 'https' ||
        !(uri.host == 'www.paypal.com' ||
            uri.host == 'www.sandbox.paypal.com')) {
      throw StateError('Enlace de PayPal inválido.');
    }
    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    )) {
      throw StateError('No se pudo abrir PayPal.');
    }
  }

  Future<void> _confirmar() => _ejecutar(() async {
    await _repository.capturar(_orden!['orderId'] as String);
    if (!mounted) return;
    // Solo el checkout del carrito vacía sus artículos tras confirmar el servidor.
    if (!widget.soloPedidos && _orden!['reutilizado'] != true) {
      context.read<CartViewModel>().limpiar();
    }
    setState(() => _orden = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pago confirmado. Tu pedido está pagado.')),
    );
    final pedidos = await _repository.pedidos();
    if (mounted) setState(() => _pedidos = pedidos);
  });

  Future<void> _cancelar(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar pedido?'),
        content: const Text(
          'Se liberarán los productos reservados de este pedido.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar pedido'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    await _ejecutar(() async {
      await _repository.cancelar(id);
      final pedidos = await _repository.pedidos();
      if (mounted) {
        setState(() {
          _orden = null;
          _pedidos = pedidos;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartViewModel>();
    final pendientes = _pedidos
        .where(
          (p) =>
              p['estado'] == 'Pendiente' &&
              p['metodoPago'] == 'PayPal' &&
              p['pago']?['estado'] == 'pendiente',
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.soloPedidos ? 'Mis compras' : 'Confirmar pedido'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_busy) const LinearProgressIndicator(),
          if (_error != null) ...[
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            TextButton(
              onPressed: _busy ? null : _cargar,
              child: const Text('Actualizar'),
            ),
          ],
          if (_orden != null) ...[
            Text(
              'Total del pedido: \$${_orden!['total']} MXN',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Text(
              'Abre PayPal y autoriza el pago. Después regresa aquí y pulsa Confirmar pago. El pedido se marcará pagado únicamente cuando el servidor confirme el cobro.',
            ),
            FilledButton(
              onPressed: _busy ? null : () => _ejecutar(_abrirPaypal),
              child: const Text('Abrir PayPal'),
            ),
            FilledButton(
              onPressed: _busy ? null : _confirmar,
              child: const Text('Confirmar pago'),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => _cancelar(_orden!['pedidoId'] as String),
              child: const Text('Cancelar pedido'),
            ),
          ] else ...[
            if (!widget.soloPedidos &&
                pendientes.isEmpty &&
                cart.items.isNotEmpty) ...[
              Text(
                'Dirección de entrega',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              RadioGroup<Direccion>(
                groupValue: _direccion,
                onChanged: (value) => setState(() => _direccion = value),
                child: Column(
                  children: [
                    for (final d in _direcciones)
                      RadioListTile<Direccion>(
                        title: Text(d.alias),
                        subtitle: Text(
                          '${d.calle}, ${d.ciudad}, ${d.estado}, CP ${d.cp}\n${d.telefono}',
                        ),
                        value: d,
                        enabled: !_busy,
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () async {
                        final vm = DireccionesViewModel(
                          context.read<AuthRepository>(),
                        );
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => DireccionesView(direccionesVm: vm),
                          ),
                        );
                        vm.dispose();
                        if (mounted) await _cargar();
                      },
                child: const Text('Administrar direcciones'),
              ),
              for (final item in cart.items)
                Text('${item.producto.nombre} × ${item.cantidad}'),
              Text(
                'Total estimado: \$${cart.totalPrecio.toStringAsFixed(2)} MXN',
              ),
              const Text(
                'El servidor calculará el importe final. Pago con PayPal; tarjetas según disponibilidad.',
              ),
              FilledButton(
                onPressed: _busy || _direccion == null
                    ? null
                    : () => _ejecutar(() async {
                        final orden = await _repository.crear(
                          List.of(cart.items),
                          _direccion!,
                        );
                        if (mounted) setState(() => _orden = orden);
                      }),
                child: const Text('Preparar pago con PayPal'),
              ),
            ],
            if (pendientes.isNotEmpty)
              const Text(
                'Tienes pedidos pendientes. Puedes retomarlos o cancelarlos antes de crear uno nuevo.',
              ),
            for (final p in (widget.soloPedidos ? _pedidos : pendientes))
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pedido ${p['_id']}'),
                      Text('${p['estado']} · \$${p['total']} MXN'),
                      if (p['pago']?['expiraEn'] != null &&
                          pendientes.contains(p))
                        Text('Vence: ${p['pago']['expiraEn']}'),
                      if (pendientes.contains(p)) ...[
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _ejecutar(() async {
                                  final orden = await _repository.reintentar(
                                    p['_id'] as String,
                                  );
                                  if (mounted) {
                                    setState(
                                      () => _orden = {
                                        ...orden,
                                        'reutilizado': true,
                                      },
                                    );
                                  }
                                }),
                          child: const Text('Retomar pago con PayPal'),
                        ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _cancelar(p['_id'] as String),
                          child: const Text('Cancelar pedido'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            if (widget.soloPedidos && _pedidos.isEmpty && !_busy)
              const Text('Todavía no tienes compras.'),
            TextButton(
              onPressed: _busy ? null : _cargar,
              child: const Text('Actualizar pedidos'),
            ),
          ],
        ],
      ),
    );
  }
}
