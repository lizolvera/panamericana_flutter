import 'package:dio/dio.dart';

import '../../domain/models/cart_item.dart';
import '../../domain/models/direccion.dart';

class CheckoutRepository {
  CheckoutRepository(this._dio);
  final Dio _dio;
  static const _base = '/api/pagos/paypal';
  // Permite el arranque en frío del backend y la respuesta de PayPal.
  Options get _paymentOptions =>
      Options(receiveTimeout: const Duration(seconds: 90));

  Future<Map<String, dynamic>> crear(
    List<CartItem> items,
    Direccion direccion, {
    String? returnUrl,
  }) async {
    final response = await _dio.post(
      '$_base/orden',
      options: _paymentOptions,
      data: {
        'canal': 'flutter',
        'returnUrl': ?returnUrl,
        'productos': items
            .map((i) => {'producto': i.producto.id, 'cantidad': i.cantidad})
            .toList(),
        'direccionEnvio': direccion.toJson(),
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> reintentar(
    String id, {
    String? returnUrl,
  }) async {
    final response = await _dio.post(
      '$_base/pedido/${Uri.encodeComponent(id)}/orden',
      options: _paymentOptions,
      data: {'canal': 'flutter', 'returnUrl': ?returnUrl},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> capturar(String id) async {
    final response = await _dio.post(
      '$_base/orden/${Uri.encodeComponent(id)}/capturar',
      options: _paymentOptions,
    );
    final pedido = response.data['pedido'];
    if (pedido is! Map || pedido['pago']?['estado'] != 'aprobado') {
      throw StateError('El servidor no confirmó el pago.');
    }
  }

  Future<void> cancelar(String id) async {
    await _dio.post('$_base/pedido/${Uri.encodeComponent(id)}/cancelar');
  }

  Future<List<Map<String, dynamic>>> pedidos() async {
    final response = await _dio.get('/api/pedidos');
    return (response.data as List)
        .map((p) => Map<String, dynamic>.from(p as Map))
        .toList();
  }
}
