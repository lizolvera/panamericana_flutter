import 'package:flutter/foundation.dart';

import '../../../../domain/models/cart_item.dart';
import '../../../../domain/models/producto.dart';

/// **ViewModel del carrito** (MVVM): estado reactivo de los artículos del
/// cliente (agregar, incrementar, decrementar y totales).
class CartViewModel extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalArticulos =>
      _items.fold(0, (suma, item) => suma + item.cantidad);

  double get totalPrecio =>
      _items.fold(0, (suma, item) => suma + item.subtotal);

  /// Agrega un producto; si ya existe, acumula la cantidad.
  void agregar(Producto producto, {int cantidad = 1}) {
    final id = producto.id;
    final existente = id == null ? null : _buscar(id);
    if (existente != null) {
      existente.cantidad += cantidad;
    } else {
      _items.add(CartItem(producto: producto, cantidad: cantidad));
    }
    notifyListeners();
  }

  void incrementar(String id) {
    final item = _buscar(id);
    if (item == null) return;
    item.cantidad++;
    notifyListeners();
  }

  /// Resta uno; si llega a 0, elimina el ítem del carrito.
  void decrementar(String id) {
    final item = _buscar(id);
    if (item == null) return;
    item.cantidad--;
    if (item.cantidad <= 0) {
      _items.remove(item);
    }
    notifyListeners();
  }

  void eliminar(String id) {
    _items.removeWhere((i) => i.producto.id == id);
    notifyListeners();
  }

  void limpiar() {
    _items.clear();
    notifyListeners();
  }

  CartItem? _buscar(String id) {
    for (final item in _items) {
      if (item.producto.id == id) return item;
    }
    return null;
  }
}
