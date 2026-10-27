import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:panamericana_flutter/data/repositories/catalog_repository.dart';
import 'package:panamericana_flutter/domain/models/producto.dart';
import 'package:panamericana_flutter/ui/features/catalog/view_models/catalog_view_model.dart';

class _Repository extends Mock implements CatalogRepository {}

void main() {
  late _Repository repository;
  late CatalogViewModel vm;

  setUp(() {
    repository = _Repository();
    when(() => repository.getMarcas()).thenAnswer((_) async => []);
    when(() => repository.getFamilias()).thenAnswer((_) async => []);
    when(() => repository.getCarruseles()).thenAnswer((_) async => []);
    when(() => repository.getOfertas()).thenAnswer((_) async => []);
    vm = CatalogViewModel(repository);
  });

  for (final fails in [false, true]) {
    test('carga inicial termina tras dispose, error=$fails', () async {
      final response = Completer<List<Producto>>();
      when(() => repository.getProductos()).thenAnswer((_) => response.future);
      final loading = vm.loadCatalog();
      vm.dispose();
      if (fails) {
        response.completeError(Exception('Sin conexión'));
      } else {
        response.complete([]);
      }
      await expectLater(loading, completes);
      expect(vm.status, CatalogStatus.loading);
      expect(vm.productos, isEmpty);
    });

    test('recomendaciones terminan tras dispose, error=$fails', () async {
      final started = Completer<void>();
      final response = Completer<List<Producto>>();
      when(() => repository.getProductos()).thenAnswer((_) async => [
            Producto.fromJson({'_id': 'p0', 'nombre': 'Producto'}),
          ]);
      when(() => repository.getRecomendaciones(
            productoIds: any(named: 'productoIds'),
            limite: any(named: 'limite'),
          )).thenAnswer((_) {
        started.complete();
        return response.future;
      });
      final loading = vm.loadCatalog();
      await started.future;
      vm.dispose();
      if (fails) {
        response.completeError(Exception('Sin conexión'));
      } else {
        response.complete([Producto.fromJson({'_id': 'p1'})]);
      }
      await expectLater(loading, completes);
      expect(vm.status, CatalogStatus.loading);
      expect(vm.recomendados, isEmpty);
    });
  }

  test('no inicia peticiones después de dispose', () async {
    vm.dispose();
    await vm.loadCatalog();
    verifyZeroInteractions(repository);
  });
}
