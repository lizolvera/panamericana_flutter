import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../data/storage/session_storage.dart';
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

  // ── Persistencia (cache storage) ──────────────────────────────────

  /// Guarda el carrito en el almacenamiento local (JSON) tras cada cambio.
  void _persistir() {
    try {
      final json = jsonEncode(
        _items.map((item) => item.toJson()).toList(),
      );
      SessionStorage.instance.saveCart(json);
    } catch (_) {
      // Si el almacenamiento no está disponible, se omite.
    }
  }

  /// Restaura el carrito guardado (solo debe llamarse con sesión activa).
  Future<void> restaurarCarrito() async {
    try {
      final json = SessionStorage.instance.cartJson;
      if (json == null || json.isEmpty) return;
      final lista = jsonDecode(json) as List<dynamic>;
      _items
        ..clear()
        ..addAll(
          lista.map((e) => CartItem.fromJson(e as Map<String, dynamic>)),
        );
      notifyListeners();
    } catch (_) {
      _items.clear();
      notifyListeners();
    }
  }

  // ── Operaciones ───────────────────────────────────────────────────

  /// Agrega un producto; si ya existe, acumula la cantidad.
  void agregar(Producto producto, {int cantidad = 1}) {
    final id = producto.id;
    final existente = id == null ? null : _buscar(id);
    if (existente != null) {
      existente.cantidad += cantidad;
    } else {
      _items.add(CartItem(producto: producto, cantidad: cantidad));
    }
    _persistir();
    notifyListeners();
  }

  void incrementar(String id) {
    final item = _buscar(id);
    if (item == null) return;
    item.cantidad++;
    _persistir();
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
    _persistir();
    notifyListeners();
  }

  void eliminar(String id) {
    _items.removeWhere((i) => i.producto.id == id);
    _persistir();
    notifyListeners();
  }

  void limpiar() {
    _items.clear();
    _persistir();
    notifyListeners();
  }

  CartItem? _buscar(String id) {
    for (final item in _items) {
      if (item.producto.id == id) return item;
    }
    return null;
  }
}
