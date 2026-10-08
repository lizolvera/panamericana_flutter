import 'producto.dart';

/// Ítem del carrito: un producto con su cantidad.
class CartItem {
  CartItem({required this.producto, required this.cantidad});

  final Producto producto;
  int cantidad;

  /// Subtotal usando el precio final (con oferta) o el normal.
  double get subtotal {
    final precio = producto.precioFinal ?? producto.precioNormal ?? 0;
    return precio * cantidad;
  }
}
