import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:panamericana_flutter/main.dart' as app;
import 'package:panamericana_flutter/data/network/api_client.dart';
import 'package:panamericana_flutter/data/repositories/catalog_repository.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('rendimiento del desplazamiento real del catálogo', (
    tester,
  ) async {
    const base = String.fromEnvironment('API_BASE_URL');
    expect(Uri.parse(base).host, isNot('prybinaback.onrender.com'));
    expect(Uri.parse(base).scheme, 'https');
    final products = await CatalogRepository(ApiClient.instance.dio)
        .getProductos();
    expect(
      products.length,
      greaterThanOrEqualTo(20),
      reason: 'Se requieren al menos 20 productos de prueba',
    );
    await app.main();
    for (
      var i = 0;
      i < 60 && find.text(products.first.nombre).evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.text(products.first.nombre), findsWidgets);
    final scroll = find.byType(Scrollable).first;
    await binding.traceAction(() async {
      for (var i = 0; i < 5; i++) {
        await tester.fling(scroll, const Offset(0, -300), 800);
        await tester.pump(const Duration(seconds: 1));
      }
    }, reportKey: 'catalog_timeline');
  });
}
