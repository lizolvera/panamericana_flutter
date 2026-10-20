import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:panamericana_flutter/data/network/api_client.dart';
import 'package:panamericana_flutter/data/repositories/auth_repository.dart';
import 'package:panamericana_flutter/domain/models/producto.dart';
import 'package:panamericana_flutter/ui/features/cart/view_models/cart_view_model.dart';
import 'package:panamericana_flutter/ui/features/shell/tab_index_notifier.dart';
import 'package:panamericana_flutter/ui/features/checkout/payment/payment_window.dart';
import 'package:panamericana_flutter/ui/features/checkout/views/checkout_view.dart';

class _Window implements PaymentWindow {
  _Window(this.approved);
  final bool approved;
  bool closed = false;
  String? order;
  @override
  String get returnUrl =>
      'https://tienda.example/paypal_return.html?state=12345678901234567890';
  @override
  Future<bool> authorize(String url, String orderId) async {
    order = orderId;
    return approved;
  }

  @override
  void close() => closed = true;
}

void main() {
  for (final approved in [true, false]) {
    testWidgets(
      approved
          ? 'un clic autoriza y captura sin pantalla intermedia'
          : 'cancelar la ventana conserva el carrito sin capturar',
      (tester) async {
        final dio = ApiClient.instance.dio;
        final original = List<Interceptor>.of(dio.interceptors);
        dio.interceptors.clear();
        addTearDown(() {
          dio.interceptors.clear();
          dio.interceptors.addAll(original);
        });
        final requests = <RequestOptions>[];
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (request, handler) {
              requests.add(request);
              final Object data;
              if (request.path == '/api/usuarios/direcciones') {
                data = [
                  {
                    'alias': 'Casa',
                    'calle': 'Calle 1',
                    'ciudad': 'Puebla',
                    'estado': 'Puebla',
                    'cp': '72000',
                    'telefono': '2221234567',
                  },
                ];
              } else if (request.path == '/api/pedidos') {
                data = [];
              } else if (request.path.endsWith('/capturar')) {
                data = {
                  'pedido': {
                    'pago': {'estado': 'aprobado'},
                  },
                };
              } else {
                data = {
                  'pedidoId': 'PEDIDO',
                  'orderId': 'ORDER',
                  'total': 160,
                  'approvalUrl':
                      'https://www.sandbox.paypal.com/checkoutnow?token=ORDER',
                };
              }
              handler.resolve(
                Response(requestOptions: request, statusCode: 200, data: data),
              );
            },
          ),
        );
        final cart = CartViewModel()
          ..agregar(
            const Producto(
              id: 'producto',
              nombre: 'Producto',
              precioNormal: 160,
            ),
          );
        final window = _Window(approved);
        final tab = TabIndexNotifier()..indice = 1;
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider.value(value: ApiClient.instance),
              Provider.value(value: AuthRepository(dio)),
              ChangeNotifierProvider.value(value: cart),
              ChangeNotifierProvider.value(value: tab),
            ],
            child: MaterialApp(
              home: Builder(builder: (context) => Scaffold(
                body: FilledButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => CheckoutView(windowFactory: (_) => window),
                  )),
                  child: const Text('Menú principal'),
                ),
              )),
            ),
          ),
        );
        await tester.tap(find.text('Menú principal'));
        await tester.pumpAndSettle();
        expect(find.text('Confirmar pago'), findsOneWidget);
        expect(find.text('Abrir PayPal'), findsNothing);
        expect(find.text('Revisar pedido'), findsNothing);
        await tester.ensureVisible(find.text('Confirmar pago'));
        await tester.tap(find.text('Confirmar pago'));
        await tester.pumpAndSettle();
        expect(window.order, 'ORDER');
        expect(window.closed, isTrue);
        final creates = requests
            .where((r) => r.path == '/api/pagos/paypal/orden')
            .toList();
        expect(creates, hasLength(1));
        expect(creates.single.data['returnUrl'], window.returnUrl);
        expect(
          requests.where((r) => r.path.endsWith('/capturar')).length,
          approved ? 1 : 0,
        );
        expect(cart.totalArticulos, approved ? 0 : 1);
        expect(tab.indice, approved ? 0 : 1);
        expect(find.byType(CheckoutView), approved ? findsNothing : findsOneWidget);
        if (approved) expect(find.text('Menú principal'), findsOneWidget);
        expect(
          requests.where((r) => r.path.endsWith('/PEDIDO/orden')),
          isEmpty,
        );
      },
    );
  }
}
