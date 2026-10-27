import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panamericana_flutter/ui/features/catalog/view_models/catalog_view_model.dart';
import 'package:panamericana_flutter/ui/features/catalog/view_models/product_detail_view_model.dart';

import 'support/fixture_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FixtureApi f;
  setUp(() async {
    f = FixtureApi();
    await f.init();
  });
  tearDown(() async => f.dispose());
  test('catálogo filtra activos por marca familia y búsqueda sin distinguir mayúsculas', () async {
    f.products.add({
      '_id': 'inactive',
      'nombre': 'Champú inactivo',
      'activo': false,
    });
    final vm = CatalogViewModel(f.catalogRepo);
    addTearDown(vm.dispose);
    await vm.loadCatalog();
    expect(vm.status, CatalogStatus.loaded);
    expect(vm.totalFiltrados, 12);
    expect(vm.productos, hasLength(13));
    expect(vm.marcas, hasLength(2));
    expect(vm.familias, hasLength(1));
    expect(vm.carruseles, isEmpty);
    expect(vm.ofertas.single.nombre, 'Oferta del mes');
    expect(vm.productosDestacados.map((p) => p.id), ['p0', 'p1']);
    expect(vm.recomendados, hasLength(2));
    vm.setMarca('m1');
    expect(vm.totalFiltrados, 6);
    expect(vm.familiasVisibles, hasLength(1));
    vm.setFamilia('f1');
    expect(vm.familiaFiltro, 'f1');
    vm.setBusqueda('PRUEBA 0');
    expect(vm.productosFiltrados.single.id, 'p0');
    vm.setMarca('m2');
    expect(vm.familiaFiltro, isNull);
    expect(vm.familiasVisibles, isEmpty);
    expect(vm.totalFiltrados, 0);
    vm.limpiarFiltros();
    expect(vm.totalFiltrados, 12);
    expect(vm.busqueda, '');
    expect(vm.marcaFiltro, isNull);
  });
  test('paginación respeta límites y vuelve al inicio al buscar', () async {
    final vm = CatalogViewModel(f.catalogRepo);
    addTearDown(vm.dispose);
    await vm.loadCatalog();
    expect(vm.totalPaginas, 2);
    expect(vm.productosVisibles, hasLength(8));
    expect(vm.hayPaginaAnterior, isFalse);
    vm.paginaAnterior();
    expect(vm.paginaActual, 1);
    vm.paginaSiguiente();
    expect(vm.productosVisibles, hasLength(4));
    expect(vm.hayPaginaSiguiente, isFalse);
    vm.paginaSiguiente();
    expect(vm.paginaActual, 2);
    vm.irAPagina(500);
    expect(vm.paginaActual, 2);
    vm.paginaAnterior();
    expect(vm.paginaActual, 1);
    vm.irAPagina(-10);
    expect(vm.paginaActual, 1);
    vm.irAPagina(2);
    vm.setFamilia('f1');
    expect(vm.paginaActual, 1);
    vm.setBusqueda('inexistente');
    expect(vm.productosVisibles, isEmpty);
    expect(vm.totalPaginas, 1);
  });
  test('recomendador caído mantiene oferta como respaldo y catálogo vacío no lo llama', () async {
    f.failures['/api/productos/recomendaciones'] = 'No disponible';
    await f.catalog.loadCatalog();
    expect(f.catalog.status, CatalogStatus.loaded);
    expect(f.catalog.productosDestacados.single.id, 'p0');
    f.products.first.remove('ofertaAplicada');
    await f.catalog.loadCatalog();
    expect(f.catalog.productosDestacados, hasLength(8));
    f.products.clear();
    f.requests.clear();
    await f.catalog.loadCatalog();
    expect(f.catalog.productosDestacados, isEmpty);
    expect(
      f.requests.where((r) => r.path.endsWith('/recomendaciones')),
      isEmpty,
    );
  });
  for (final error in [
    'Catálogo no disponible',
    DioException(
      requestOptions: RequestOptions(path: '/'),
      type: DioExceptionType.connectionTimeout,
    ),
    Exception('fallo'),
  ]) {
    test(
      'catálogo y detalle permiten recuperación tras ${error.runtimeType}',
      () async {
        f.failures['/api/productos'] = error;
        await f.catalog.loadCatalog();
        expect(f.catalog.status, CatalogStatus.error);
        expect(f.catalog.errorMessage, isNotEmpty);
        f.failures['/api/productos/p0'] = error;
        final detail = ProductDetailViewModel(f.catalogRepo);
        addTearDown(detail.dispose);
        await detail.loadProduct('p0');
        expect(detail.status, ProductDetailStatus.error);
        expect(detail.errorMessage, isNotEmpty);
        f.failures.clear();
        await detail.loadProduct('p0');
        expect(detail.status, ProductDetailStatus.loaded);
        expect(detail.producto!.id, 'p0');
        await detail.loadSimilares('p0');
        expect(detail.similares, hasLength(2));
        expect(() => detail.similares.clear(), throwsUnsupportedError);
        f.failures['/api/productos/p0/recomendaciones'] = 'fallo';
        await detail.loadSimilares('p0');
        expect(detail.similares, isEmpty);
      },
    );
  }
  test('repositorio conserva filtros y límites enviados a la API', () async {
    await f.catalogRepo.getProductos(
      marca: 'm1',
      familia: 'f1',
      nombre: 'Champú',
    );
    expect(f.requests.last.queryParameters, {
      'marca': 'm1',
      'familia': 'f1',
      'nombre': 'Champú',
    });
    await f.catalogRepo.getFamilias(marca: 'm1');
    expect(f.requests.last.queryParameters, {'marca': 'm1'});
    await f.catalogRepo.getRecomendaciones(productoIds: ['p0'], limite: 3);
    expect(f.requests.last.data, {
      'productos': ['p0'],
    });
    expect(f.requests.last.queryParameters, {'limite': 3});
    final count = f.requests.length;
    expect(await f.catalogRepo.getRecomendaciones(productoIds: []), isEmpty);
    expect(f.requests.length, count);
  });
}
