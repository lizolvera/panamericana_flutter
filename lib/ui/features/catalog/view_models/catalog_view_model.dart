import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../data/repositories/catalog_repository.dart';
import '../../../../domain/models/carrusel.dart';
import '../../../../domain/models/familia.dart';
import '../../../../domain/models/marca.dart';
import '../../../../domain/models/oferta.dart';
import '../../../../domain/models/producto.dart';

/// Estados de carga del catálogo.
enum CatalogStatus { initial, loading, loaded, error }

/// **ViewModel del catálogo** (vista invitado, MVVM).
///
/// Carga en paralelo productos, marcas, familias, carruseles y ofertas,
/// y expone el filtrado reactivo (marca, familia, búsqueda) para la UI.
class CatalogViewModel extends ChangeNotifier {
  CatalogViewModel(this._repository);

  final CatalogRepository _repository;

  CatalogStatus _status = CatalogStatus.initial;
  String? _errorMessage;

  List<Producto> _productos = [];
  List<Marca> _marcas = [];
  List<Familia> _familias = [];
  List<Carrusel> _carruseles = [];
  List<Oferta> _ofertas = [];

  /// Productos recomendados por el backend (destacados).
  List<Producto> _recomendados = [];

  String? _marcaFiltro;
  String? _familiaFiltro;
  String _busqueda = '';

  // --- Paginación numérica ---
  static const int _tamPagina = 8;

  int _paginaActual = 1;

  CatalogStatus get status => _status;
  String? get errorMessage => _errorMessage;

  List<Producto> get productos => _productos;
  List<Marca> get marcas => _marcas;
  List<Familia> get familias => _familias;
  List<Carrusel> get carruseles => _carruseles;
  List<Oferta> get ofertas => _ofertas;
  List<Producto> get recomendados => _recomendados;

  String? get marcaFiltro => _marcaFiltro;
  String? get familiaFiltro => _familiaFiltro;

  /// Familias visibles según la marca seleccionada (cada familia
  /// pertenece a una marca en la API).
  List<Familia> get familiasVisibles {
    if (_marcaFiltro == null) return _familias;
    return _familias.where((f) => f.marca?.id == _marcaFiltro).toList();
  }

  /// Productos tras aplicar los filtros locales (marca, familia, búsqueda).
  List<Producto> get productosFiltrados => _filtrar();

  List<Producto> _filtrar() {
    return _productos.where((p) {
      final porMarca = _marcaFiltro == null || p.marca?.id == _marcaFiltro;
      final porFamilia = _familiaFiltro == null || p.familia?.id == _familiaFiltro;
      final porBusqueda = _busqueda.isEmpty ||
          p.nombre.toLowerCase().contains(_busqueda.trim().toLowerCase());
      return p.activo && porMarca && porFamilia && porBusqueda;
    }).toList();
  }

  /// Total de productos tras los filtros (para el contador).
  int get totalFiltrados => _filtrar().length;

  /// Página actual (1-based).
  int get paginaActual => _paginaActual;

  /// Total de páginas según el tamaño de página (8).
  int get totalPaginas {
    final total = _filtrar().length;
    if (total == 0) return 1;
    return ((total - 1) ~/ _tamPagina) + 1;
  }

  bool get hayPaginaAnterior => _paginaActual > 1;
  bool get hayPaginaSiguiente => _paginaActual < totalPaginas;

  /// Productos de la página actual.
  List<Producto> get productosVisibles {
    final filtrados = _filtrar();
    final inicio = (_paginaActual - 1) * _tamPagina;
    if (inicio >= filtrados.length) return const [];
    final fin = (inicio + _tamPagina).clamp(0, filtrados.length);
    return filtrados.sublist(inicio, fin);
  }

  /// Ir a una página específica (clamp 1..totalPaginas).
  void irAPagina(int pagina) {
    final nueva = pagina.clamp(1, totalPaginas);
    if (nueva == _paginaActual) return;
    _paginaActual = nueva;
    notifyListeners();
  }

  void paginaSiguiente() {
    if (!hayPaginaSiguiente) return;
    _paginaActual++;
    notifyListeners();
  }

  void paginaAnterior() {
    if (!hayPaginaAnterior) return;
    _paginaActual--;
    notifyListeners();
  }

  /// Productos destacados: usa el **recomendador del backend**; si no hay
  /// resultados (sin historial o sin conexión), cae a productos con oferta
  /// activa y, en último caso, a los primeros del catálogo.
  List<Producto> get productosDestacados {
    if (_recomendados.isNotEmpty) return _recomendados;
    final conOferta =
        _productos.where((p) => p.ofertaAplicada != null).toList();
    if (conOferta.isNotEmpty) return conOferta.take(8).toList();
    return _productos.take(8).toList();
  }

  /// Carga inicial (o reintento) de todo el catálogo en paralelo.
  Future<void> loadCatalog() async {
    _status = CatalogStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultados = await Future.wait([
        _repository.getProductos(),
        _repository.getMarcas(),
        _repository.getFamilias(),
        _repository.getCarruseles(),
        _repository.getOfertas(),
      ]);

      _productos = resultados[0] as List<Producto>;
      _marcas = resultados[1] as List<Marca>;
      _familias = resultados[2] as List<Familia>;
      _carruseles = resultados[3] as List<Carrusel>;
      _ofertas = resultados[4] as List<Oferta>;

      // 🔮 "Productos Destacados" con el recomendador del backend (basado
      // en items): semillas = productos con oferta, o los primeros del
      // catálogo si no hay ofertas. Si falla, se cae al respaldo local.
      final semillas = _productos
          .where((p) => p.ofertaAplicada != null)
          .toList();
      final semillasFinal =
          semillas.isNotEmpty ? semillas : _productos.take(6).toList();
      if (semillasFinal.isNotEmpty) {
        try {
          _recomendados = await _repository.getRecomendaciones(
            productoIds:
                semillasFinal.map((p) => p.id).whereType<String>().toList(),
            limite: 8,
          );
        } catch (_) {
          _recomendados = [];
        }
      }

      _status = CatalogStatus.loaded;
      notifyListeners();
    } catch (e) {
      _status = CatalogStatus.error;
      _errorMessage = _extractError(e);
      notifyListeners();
    }
  }

  // --- Filtros reactivos ---

  void setMarca(String? id) {
    _marcaFiltro = id;
    _familiaFiltro = null; // al cambiar de marca se reinicia la familia
    _paginaActual = 1;
    notifyListeners();
  }

  void setFamilia(String? id) {
    _familiaFiltro = id;
    _paginaActual = 1;
    notifyListeners();
  }

  void setBusqueda(String texto) {
    _busqueda = texto;
    _paginaActual = 1;
    notifyListeners();
  }

  void limpiarFiltros() {
    _marcaFiltro = null;
    _familiaFiltro = null;
    _busqueda = '';
    _paginaActual = 1;
    notifyListeners();
  }

  String _extractError(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Problema de conexión con el servidor.';
      }
      final data = error.response?.data;
      if (data is Map<String, dynamic> && data['error'] != null) {
        return data['error'].toString();
      }
    }
    return 'Error al cargar el catálogo.';
  }
}
