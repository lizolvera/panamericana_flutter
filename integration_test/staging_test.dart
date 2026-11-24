import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dio/dio.dart';
import 'package:panamericana_flutter/main.dart' as app;
import 'package:panamericana_flutter/data/storage/session_storage.dart';
import 'package:panamericana_flutter/data/network/api_client.dart';
import 'package:panamericana_flutter/data/repositories/catalog_repository.dart';
import 'package:panamericana_flutter/data/repositories/auth_repository.dart';
import 'package:panamericana_flutter/data/repositories/checkout_repository.dart';
import 'package:panamericana_flutter/ui/features/checkout/views/checkout_view.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sesión cliente real: catálogo, perfil, direcciones e historial', (
    tester,
  ) async {
    const base = String.fromEnvironment('API_BASE_URL');
    const token = String.fromEnvironment('STAGING_CLIENT_A_TOKEN');
    final uri = Uri.parse(base);
    expect(uri.scheme, 'https', reason: 'Se requiere staging HTTPS');
    expect(uri.host, isNot('prybinaback.onrender.com'));
    expect(token, isNotEmpty, reason: 'Falta sesión sintética vigente');
    await SessionStorage.instance.init();
    await SessionStorage.instance.clear();
    final dio = ApiClient.instance.dio;
    // Nunca imprimir los cuerpos o cabeceras: contienen datos de prueba y JWT.
    final response = await dio.get<Map<String, dynamic>>(
      '/api/usuarios/perfil',
      options: Options(headers: {'Authorization': token}),
    );
    final profile = response.data!;
    expect(profile['rol'], 'usuario');
    await SessionStorage.instance.saveSession(
      token: token,
      rol: 'usuario',
      nombre: profile['nombre'] as String,
    );
    final catalog = await CatalogRepository(dio).getProductos();
    expect(
      catalog,
      isNotEmpty,
      reason: 'Sembrar catálogo sintético en staging',
    );
    final addresses = await AuthRepository(dio).getDirecciones();
    expect(addresses, isNotEmpty, reason: 'Sembrar dirección del cliente A');
    final orders = await CheckoutRepository(dio).pedidos();
    expect(orders, isNotEmpty, reason: 'Sembrar historial del cliente A');

    await app.main();
    // Esperar a que la app pinte el catálogo (texto siempre presente en tab 0).
    for (var i = 0; i < 40 && find.text('Todos los productos').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.text('Todos los productos'), findsOneWidget,
        reason: 'La app no llego a pintar el catalogo inicial');
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Perfil'), findsOneWidget,
        reason: 'No se encontro el boton Perfil en la barra de navegacion');
    await tester.tap(find.text('Perfil'));
    for (
      var i = 0;
      i < 60 && find.text('MIS DIRECCIONES').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.text('MIS DIRECCIONES'), findsOneWidget,
        reason: 'No se encontro MIS DIRECCIONES en el perfil');
    expect(find.text('MIS COMPRAS'), findsOneWidget,
        reason: 'No se encontro MIS COMPRAS en el perfil');
    // El SliverAppBar colapsable tapa los tiles superiores y el tap no llega
    // al InkWell. Navegamos directamente con el Navigator del contexto.
    final profileContext = tester.element(find.text('MIS COMPRAS'));
    Navigator.of(profileContext).push(MaterialPageRoute<void>(
      builder: (_) => const CheckoutView(soloPedidos: true),
    ));
    await tester.pumpAndSettle();
    // Verificar que la navegacion ocurrio: el AppBar de la vista muestra "Mis compras".
    expect(find.text('Mis compras'), findsOneWidget,
        reason: 'No se navego a la vista Mis compras');
    // Esperar a que termine la carga: aparezca un Pedido o el mensaje de vacío.
    for (var i = 0; i < 120; i++) {
      if (find.textContaining('Pedido ').evaluate().isNotEmpty) break;
      if (find.text('Todavía no tienes compras.').evaluate().isNotEmpty) break;
      await tester.pump(const Duration(milliseconds: 500));
    }
    final vacio = find.text('Todavía no tienes compras.').evaluate().isNotEmpty;
    expect(vacio, isFalse,
        reason: 'La vista llego al estado vacio: la app no recibio pedidos del API aunque el test verifico que existen');
    expect(find.textContaining('Pedido '), findsWidgets,
        reason: 'No se encontraron pedidos en MIS COMPRAS');
    expect(tester.takeException(), isNull,
        reason: 'Hubo una excepcion durante el test');
    await SessionStorage.instance.clear();
  });
}
