import 'package:dio/dio.dart';

import '../../domain/models/carrusel.dart';
import '../../domain/models/familia.dart';
import '../../domain/models/marca.dart';
import '../../domain/models/oferta.dart';
import '../../domain/models/producto.dart';

/// **Repositorio del catálogo**: aísla el acceso a los endpoints públicos
/// de productos, familias, marcas, ofertas y carruseles (vista invitado).
class CatalogRepository {
  CatalogRepository(this._dio);

  final Dio _dio;

  /// `GET /api/productos` — el backend popula `marca`/`familia`
  /// y aplica las ofertas vigentes (precioFinal, ofertaAplicada).
  ///
  /// Filtros opcionales por query param: `marca`, `familia`, `nombre`.
  Future<List<Producto>> getProductos({
    String? marca,
    String? familia,
    String? nombre,
  }) async {
    final res = await _dio.get(
      '/api/productos',
      queryParameters: {
        'marca': ?marca,
        'familia': ?familia,
        if (nombre != null && nombre.isNotEmpty) 'nombre': nombre,
      },
    );
    final data = res.data as List<dynamic>;
    return data
        .map((e) => Producto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /api/productos/:id` — detalle de producto (con oferta aplicada).
  Future<Producto> getProductoById(String id) async {
    final res = await _dio.get('/api/productos/$id');
    return Producto.fromJson(res.data as Map<String, dynamic>);
  }

  /// `GET /api/marcas`
  Future<List<Marca>> getMarcas() async {
    final res = await _dio.get('/api/marcas');
    final data = res.data as List<dynamic>;
    return data
        .map((e) => Marca.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /api/familias` — opcional filtrar por marca: `?marca=id`.
  Future<List<Familia>> getFamilias({String? marca}) async {
    final res = await _dio.get(
      '/api/familias',
      queryParameters: {'marca': ?marca},
    );
    final data = res.data as List<dynamic>;
    return data
        .map((e) => Familia.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /api/ofertas` — ofertas ordenadas por creación (recientes primero).
  Future<List<Oferta>> getOfertas() async {
    final res = await _dio.get('/api/ofertas');
    final data = res.data as List<dynamic>;
    return data
        .map((e) => Oferta.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /api/carruseles?activo=true` — banners activos en orden.
  Future<List<Carrusel>> getCarruseles() async {
    final res = await _dio.get(
      '/api/carruseles',
      queryParameters: {'activo': 'true'},
    );
    final data = res.data as List<dynamic>;
    return data
        .map((e) => Carrusel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
