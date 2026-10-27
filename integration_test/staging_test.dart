import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dio/dio.dart';
import 'package:panamericana_flutter/main.dart' as app;
import 'package:panamericana_flutter/data/storage/session_storage.dart';
import 'package:panamericana_flutter/data/network/api_client.dart';
import 'package:panamericana_flutter/data/repositories/catalog_repository.dart';
import 'package:panamericana_flutter/data/repositories/auth_repository.dart';
import 'package:panamericana_flutter/data/repositories/checkout_repository.dart';

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
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Perfil').last);
    for (
      var i = 0;
      i < 60 && find.text('MIS DIRECCIONES').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.text('MIS DIRECCIONES'), findsOneWidget);
    expect(find.text('MIS COMPRAS'), findsOneWidget);
    await tester.tap(find.text('MIS COMPRAS'));
    for (
      var i = 0;
      i < 60 && find.textContaining('Pedido ').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.textContaining('Pedido '), findsWidgets);
    expect(tester.takeException(), isNull);
    await SessionStorage.instance.clear();
  });
}
