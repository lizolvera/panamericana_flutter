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

  Map<String, dynamic> toJson() => {
        'producto': producto.toJson(),
        'cantidad': cantidad,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      producto: Producto.fromJson(json['producto'] as Map<String, dynamic>),
      cantidad: json['cantidad'] as int,
    );
  }
}
