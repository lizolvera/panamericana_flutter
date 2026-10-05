import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../data/repositories/catalog_repository.dart';
import '../../../../domain/models/producto.dart';

/// Estados de carga del detalle de producto.
enum ProductDetailStatus { initial, loading, loaded, error }

/// **ViewModel del detalle de producto** (MVVM).
///
/// Obtiene el producto **fresco** desde la API con `getProductoById`
/// (precios con oferta, stock y descripción actualizados al momento).
class ProductDetailViewModel extends ChangeNotifier {
  ProductDetailViewModel(this._repository);

  final CatalogRepository _repository;

  ProductDetailStatus _status = ProductDetailStatus.initial;
  Producto? _producto;
  String? _errorMessage;

  ProductDetailStatus get status => _status;
  Producto? get producto => _producto;
  String? get errorMessage => _errorMessage;

  Future<void> loadProduct(String id) async {
    _status = ProductDetailStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _producto = await _repository.getProductoById(id);
      _status = ProductDetailStatus.loaded;
      notifyListeners();
    } catch (e) {
      _status = ProductDetailStatus.error;
      _errorMessage = _extractError(e);
      notifyListeners();
    }
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
    return 'No se pudo cargar el producto.';
  }
}
