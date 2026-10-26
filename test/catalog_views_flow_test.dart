import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panamericana_flutter/ui/features/catalog/views/catalog_view.dart';
import 'package:panamericana_flutter/ui/features/catalog/views/product_detail_view.dart';

import 'support/fixture_api.dart';

void main() {
  late FixtureApi f;
  setUp(() async {
    f = FixtureApi();
    await f.init(signedIn: true);
  });
  tearDown(() async => f.dispose());
  testWidgets('catalogo busca, limpia y combina filtros de marca y familia', (
    t,
  ) async {
    await renderFixture(t, f, const Scaffold(body: CatalogView()));
    expect(find.text('Todos los productos'), findsOneWidget);
    await t.enterText(find.byType(TextField), 'inexistente');
    await t.pumpAndSettle();
    expect(f.catalog.productosFiltrados, isEmpty);
    await press(t, 'Limpiar filtros');
    expect(f.catalog.busqueda, isEmpty);
    await t.enterText(find.byType(TextField), 'Champú');
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Limpiar búsqueda'));
    await t.pumpAndSettle();
    await t.tap(find.text('Marca Uno').first);
    await t.pumpAndSettle();
    expect(f.catalog.marcaFiltro, 'm1');
    await t.tap(find.text('Cabello').first);
    await t.pumpAndSettle();
    expect(f.catalog.familiaFiltro, 'f1');
    await t.tap(find.text('Todas').first);
    await t.pumpAndSettle();
    expect(f.catalog.marcaFiltro, isNull);
  });
  testWidgets(
    'catalogo pagina y agrega productos mostrando acceso al carrito',
    (t) async {
      await renderFixture(
        t,
        f,
        const Scaffold(body: CatalogView()),
        height: 2000,
      );
      final add = find.text('Añadir').first;
      await t.ensureVisible(add);
      await t.tap(add);
      await t.pumpAndSettle();
      expect(f.cart.items, hasLength(1));
      await press(t, 'Ver');
      expect(f.tab.indice, 1);
      final next = find.text('Sig.');
      await t.ensureVisible(next);
      await t.tap(next);
      await t.pumpAndSettle();
      expect(f.catalog.paginaActual, 2);
      await press(t, 'Ant.');
      expect(f.catalog.paginaActual, 1);
    },
  );
  testWidgets('catalogo comunica fallo y reintenta la carga', (t) async {
    f.failures['/api/productos'] = 'Catálogo temporalmente no disponible';
    await renderFixture(t, f, const Scaffold(body: CatalogView()));
    expect(find.text('Catálogo temporalmente no disponible'), findsOneWidget);
    f.failures.clear();
    await press(t, 'Reintentar');
    expect(find.text('Todos los productos'), findsOneWidget);
  });
  testWidgets('catalogo completo permite buscar y abrir el detalle', (t) async {
    await renderFixture(t, f, const CatalogViewPage(), height: 2000);
    await t.enterText(find.byType(TextField), 'Champú de prueba 1');
    await t.pumpAndSettle();
    expect(f.catalog.productosFiltrados, hasLength(3));
    final product = find.widgetWithText(InkWell, 'Champú de prueba 1').last;
    await t.ensureVisible(product);
    await t.pumpAndSettle();
    await t.tap(product);
    await t.pumpAndSettle();
    expect(find.byType(ProductDetailView), findsOneWidget);
    expect(find.text('Descripción del producto 1'), findsOneWidget);
  });
  for (final width in [340.0, 700.0, 1000.0]) {
    testWidgets(
      'detalle muestra precios, oferta y permite comprar en ancho $width',
      (t) async {
        await renderFixture(
          t,
          f,
          const ProductDetailView(productoId: 'p0'),
          width: width,
          height: 1600,
        );
        expect(find.text('Descripción del producto 0'), findsOneWidget);
        expect(find.text('Precio mayoreo'), findsOneWidget);
        await press(t, 'Agregar al carrito');
        expect(f.cart.items.single.producto.id, 'p0');
        expect(f.cart.totalPrecio, 90);
        await press(t, 'Ver');
        expect(f.tab.indice, 1);
      },
    );
  }
  testWidgets(
    'detalle maneja agotado y campos opcionales sin inventar informacion',
    (t) async {
      f.products[1].remove('descripcion');
      f.products[1]['stock'] = 0;
      await renderFixture(t, f, const ProductDetailView(productoId: 'p1'));
      expect(find.text('Agotado'), findsOneWidget);
      expect(find.text('Sin descripción disponible.'), findsOneWidget);
    },
  );
  testWidgets('detalle permite recuperar la consulta despues de un fallo', (
    t,
  ) async {
    f.failures['/api/productos/p0'] = 'Producto no disponible';
    await renderFixture(t, f, const ProductDetailView(productoId: 'p0'));
    expect(find.text('Producto no disponible'), findsOneWidget);
    f.failures.clear();
    await press(t, 'Reintentar');
    expect(find.text('Descripción del producto 0'), findsOneWidget);
  });
}
