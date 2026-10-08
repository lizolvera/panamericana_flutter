import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../domain/models/direccion.dart';

enum DireccionesStatus { initial, loading, loaded, error }

/// **ViewModel de direcciones** (MVVM): lista + CRUD de las direcciones
/// de envío del cliente.
class DireccionesViewModel extends ChangeNotifier {
  DireccionesViewModel(this._repository);

  final AuthRepository _repository;

  DireccionesStatus _status = DireccionesStatus.initial;
  String? _error;
  List<Direccion> _direcciones = [];
  bool _guardando = false;

  DireccionesStatus get status => _status;
  String? get error => _error;
  List<Direccion> get direcciones => List.unmodifiable(_direcciones);
  bool get guardando => _guardando;

  Future<void> load() async {
    _status = DireccionesStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _direcciones = await _repository.getDirecciones();
      _status = DireccionesStatus.loaded;
      notifyListeners();
    } catch (e) {
      _status = DireccionesStatus.error;
      _error = _extractError(e);
      notifyListeners();
    }
  }

  Future<bool> crear(Map<String, dynamic> datos) async {
    return _ejecutar(() => _repository.createDireccion(datos));
  }

  Future<bool> actualizar(String id, Map<String, dynamic> datos) async {
    return _ejecutar(() => _repository.updateDireccion(id, datos));
  }

  Future<bool> eliminar(String id) async {
    return _ejecutar(() => _repository.deleteDireccion(id));
  }

  Future<bool> marcarPredeterminada(String id) async {
    return _ejecutar(() => _repository.setDireccionPredeterminada(id));
  }

  Future<bool> _ejecutar(Future<dynamic> Function() accion) async {
    _guardando = true;
    _error = null;
    notifyListeners();
    try {
      await accion();
      await load();
      return true;
    } catch (e) {
      _error = _extractError(e);
      notifyListeners();
      return false;
    } finally {
      _guardando = false;
      notifyListeners();
    }
  }

  String _extractError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic> && data['error'] != null) {
        return data['error'].toString();
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Problema de conexión con el servidor.';
      }
    }
    return 'Ocurrió un error inesperado.';
  }
}
