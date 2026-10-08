import 'package:flutter/foundation.dart';

/// Índice de la pestaña activa de la barra inferior. Se comparte entre
/// TODAS las vistas de la app para que el footer se mantenga sincronizado.
class TabIndexNotifier extends ChangeNotifier {
  int _indice = 0;

  int get indice => _indice;

  set indice(int valor) {
    if (valor == _indice) return;
    _indice = valor;
    notifyListeners();
  }
}
