import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panamericana_flutter/domain/models/producto.dart';
import 'package:panamericana_flutter/ui/features/home/views/home_view.dart';

import 'support/fixture_api.dart';

void main() {
  late FixtureApi f;
  setUp(() async {
    f = FixtureApi();
    await f.init();
  });
  tearDown(() async => f.dispose());
  testWidgets(
    'invitado recibe acceso a login y puede volver a explorar desde carrito y perfil',
    (t) async {
      f.tab.indice = 1;
      await renderFixture(t, f, const HomeView());
      expect(find.text('Tu carrito te espera'), findsOneWidget);
      await press(t, 'Explorar catálogo');
      expect(f.tab.indice, 0);
      f.tab.indice = 2;
      await t.pumpAndSettle();
      expect(find.text('Tu Perfil de Cliente'), findsOneWidget);
      await press(t, 'Continuar explorando productos');
      expect(f.tab.indice, 0);
    },
  );
  testWidgets(
    'cliente cambia cantidades, elimina productos y ve el carrito vacio',
    (t) async {
      await t.runAsync(() async {
        await f.auth.sendLoginCode(
          email: 'ana@example.test',
          password: 'Prueba',
        );
        await f.auth.verifyCode('123456');
      });
      f.cart.agregar(Producto.fromJson(f.products.first));
      f.tab.indice = 1;
      await renderFixture(t, f, const HomeView());
      expect(f.cart.totalArticulos, 1);
      await t.tap(find.byIcon(Icons.add).first);
      await t.pumpAndSettle();
      expect(f.cart.totalArticulos, 2);
      await t.tap(find.byIcon(Icons.remove).first);
      await t.pumpAndSettle();
      expect(f.cart.totalArticulos, 1);
      await t.tap(find.byIcon(Icons.delete_outline).first);
      await t.pumpAndSettle();
      expect(f.cart.items, isEmpty);
      await press(t, 'Explorar productos');
      expect(f.tab.indice, 0);
    },
  );
}
