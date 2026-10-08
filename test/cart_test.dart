import 'package:flutter_test/flutter_test.dart';

import 'package:panamericana_flutter/domain/models/producto.dart';
import 'package:panamericana_flutter/ui/features/cart/view_models/cart_view_model.dart';

void main() {
  group('CartViewModel', () {
    test('agregar acumula cantidades del mismo producto', () {
      final cart = CartViewModel();
      final producto = Producto(id: '1', nombre: 'Test', precioNormal: 100);

      cart.agregar(producto);
      cart.agregar(producto);

      expect(cart.totalArticulos, 2);
      expect(cart.totalPrecio, 200);
    });

    test('decrementar elimina el ítem al llegar a 0', () {
      final cart = CartViewModel();
      final producto = Producto(id: '1', nombre: 'Test', precioNormal: 100);

      cart.agregar(producto);
      cart.decrementar('1');

      expect(cart.items, isEmpty);
      expect(cart.totalArticulos, 0);
    });

    test('incrementar y decrementar ajustan la cantidad', () {
      final cart = CartViewModel();
      final producto = Producto(id: '1', nombre: 'Test', precioNormal: 50);

      cart.agregar(producto);
      cart.incrementar('1');
      cart.incrementar('1');
      cart.decrementar('1');

      expect(cart.totalArticulos, 2);
      expect(cart.totalPrecio, 100);
    });
  });
}
