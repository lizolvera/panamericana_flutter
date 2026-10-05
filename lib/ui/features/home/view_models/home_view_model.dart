import 'package:flutter/foundation.dart';

import '../../../../data/storage/session_storage.dart';

/// **ViewModel de la vista principal** (MVVM).
///
/// Por ahora decide la "cara" de la app según la sesión:
/// invitado (0) → catálogo público; cliente (1) → experiencia de compra.
/// Aquí se integrará después el estado del catálogo (productos, familias,
/// marcas, ofertas) y del carrito.
class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this._storage);

  final SessionStorage _storage;

  bool _isCliente = false;
  String? _nombre;

  bool get isCliente => _isCliente;
  String? get nombre => _nombre;

  void refreshFromSession() {
    _isCliente = _storage.isLoggedIn && _storage.rol == 'usuario';
    _nombre = _storage.nombre;
    notifyListeners();
  }
}
