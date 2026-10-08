import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../domain/models/usuario.dart';

/// Estados de carga del perfil.
enum ProfileStatus { initial, loading, loaded, error }

/// Estado de una acción de configuración (guardar datos, contraseña, etc.).
enum AccionStatus { idle, working, ok, error }

/// **ViewModel del perfil** (MVVM): carga los datos del usuario y ejecuta
/// las acciones de configuración (actualizar datos, contraseña, pregunta).
class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel(this._repository);

  final AuthRepository _repository;

  ProfileStatus _status = ProfileStatus.initial;
  Usuario? _perfil;
  String? _error;

  AccionStatus _accion = AccionStatus.idle;
  String? _mensaje;

  ProfileStatus get status => _status;
  Usuario? get perfil => _perfil;
  String? get error => _error;
  AccionStatus get accion => _accion;
  String? get mensaje => _mensaje;

  Future<void> load() async {
    _status = ProfileStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _perfil = await _repository.getPerfil();
      _status = ProfileStatus.loaded;
      notifyListeners();
    } catch (e) {
      _status = ProfileStatus.error;
      _error = _extractError(e);
      notifyListeners();
    }
  }

  /// Actualiza los datos personales (nombre, apellidos, fecha, teléfono).
  Future<bool> actualizarDatos(Map<String, dynamic> datos) async {
    _accion = AccionStatus.working;
    _mensaje = null;
    notifyListeners();
    try {
      _perfil = await _repository.updatePerfil(datos);
      _accion = AccionStatus.ok;
      _mensaje = 'Perfil actualizado correctamente.';
      notifyListeners();
      return true;
    } catch (e) {
      _accion = AccionStatus.error;
      _mensaje = _extractError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> cambiarContrasena({
    required String currentPassword,
    required String newPassword,
  }) async {
    _accion = AccionStatus.working;
    _mensaje = null;
    notifyListeners();
    try {
      await _repository.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _accion = AccionStatus.ok;
      _mensaje = 'Contraseña actualizada correctamente.';
      notifyListeners();
      return true;
    } catch (e) {
      _accion = AccionStatus.error;
      _mensaje = _extractError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> actualizarPregunta({
    required String preguntaSecreta,
    required String respuestaSecreta,
  }) async {
    _accion = AccionStatus.working;
    _mensaje = null;
    notifyListeners();
    try {
      await _repository.updateSecret(
        preguntaSecreta: preguntaSecreta,
        respuestaSecreta: respuestaSecreta,
      );
      _accion = AccionStatus.ok;
      _mensaje = 'Pregunta y respuesta actualizadas.';
      notifyListeners();
      return true;
    } catch (e) {
      _accion = AccionStatus.error;
      _mensaje = _extractError(e);
      notifyListeners();
      return false;
    }
  }

  void reiniciarAccion() {
    _accion = AccionStatus.idle;
    _mensaje = null;
    notifyListeners();
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
