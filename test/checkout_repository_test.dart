import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panamericana_flutter/data/repositories/checkout_repository.dart';
import 'package:panamericana_flutter/domain/models/cart_item.dart';
import 'package:panamericana_flutter/domain/models/direccion.dart';
import 'package:panamericana_flutter/domain/models/producto.dart';

class _Adapter implements HttpClientAdapter {
  Map<String, dynamic> response = {};
  late RequestOptions request;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode(response),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _Adapter adapter;
  late CheckoutRepository repository;
  setUp(() {
    adapter = _Adapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.httpClientAdapter = adapter;
    repository = CheckoutRepository(dio);
  });

  test(
    'envía productos y dirección sin aceptar un importe del cliente',
    () async {
      adapter.response = {
        'orderId': 'ORDER',
        'pedidoId': 'PEDIDO',
        'total': 80,
      };
      await repository.crear(
        [
          CartItem(
            producto: const Producto(
              id: 'producto',
              nombre: 'Producto',
              precioNormal: 40,
            ),
            cantidad: 2,
          ),
        ],
        const Direccion(
          alias: 'Casa',
          calle: 'Calle 1',
          ciudad: 'Puebla',
          estado: 'Puebla',
          cp: '72000',
          telefono: '2221234567',
        ),
      );
      expect(adapter.request.path, '/api/pagos/paypal/orden');
      expect(adapter.request.data['canal'], 'flutter');
      expect(adapter.request.data['productos'], [
        {'producto': 'producto', 'cantidad': 2},
      ]);
      expect(adapter.request.data.containsKey('total'), isFalse);
      expect(adapter.request.data['direccionEnvio']['cp'], '72000');
    },
  );

  test('solo acepta el pago aprobado por el servidor', () async {
    adapter.response = {
      'pedido': {
        'pago': {'estado': 'pendiente'},
      },
    };
    await expectLater(repository.capturar('ORDER'), throwsStateError);
    adapter.response = {
      'pedido': {
        'pago': {'estado': 'aprobado'},
      },
    };
    await repository.capturar('ORDER');
    expect(adapter.request.path, '/api/pagos/paypal/orden/ORDER/capturar');
  });

  test('reintenta el pedido existente con canal Flutter', () async {
    adapter.response = {'orderId': 'NEW'};
    final result = await repository.reintentar('PEDIDO');
    expect(result['orderId'], 'NEW');
    expect(adapter.request.path, '/api/pagos/paypal/pedido/PEDIDO/orden');
    expect(adapter.request.data, {'canal': 'flutter'});
    await repository.cancelar('PEDIDO');
    expect(adapter.request.path, '/api/pagos/paypal/pedido/PEDIDO/cancelar');
  });
}
