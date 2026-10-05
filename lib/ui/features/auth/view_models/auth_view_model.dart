import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/storage/session_storage.dart';

/// Roles de la app: **0 = invitado, 1 = cliente, 2 = admin**.
enum AppRole { invitado, cliente, admin }

/// Estados del flujo de autenticación (login de 2 pasos con 2FA).
enum AuthStatus { initial, loading, codeSent, authenticated, error }

/// **ViewModel de autenticación** (MVVM).
///
/// Orquesta el login de 2 pasos de pryBinaBack y aplica la regla de
/// seguridad: la app móvil es **EXCLUSIVA de clientes**, por lo que si
/// el rol devuelto por la API es `admin` (peticion == 2), se rechaza
/// el inicio de sesión y **no se persiste ninguna sesión**.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repository, this._storage);

  final AuthRepository _repository;
  final SessionStorage _storage;

  AuthStatus _status = AuthStatus.initial;
  AppRole _role = AppRole.invitado;
  String? _errorMessage;
  String? _email;
  String? _nombre;

  AuthStatus get status => _status;
  AppRole get role => _role;
  String? get errorMessage => _errorMessage;
  String? get nombre => _nombre;

  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isCliente => _role == AppRole.cliente;

  /// Mapeo del rol string de la API → petición numérica:
  /// `"usuario"` → 1 (cliente), `"admin"` → 2 (admin),
  /// sin sesión → 0 (invitado).
  static int mapearRol(String? rol) {
    switch (rol) {
      case 'admin':
        return 2;
      case 'usuario':
        return 1;
      default:
        return 0;
    }
  }

  /// Paso 1 del login: envía credenciales y espera el código 2FA.
  Future<bool> sendLoginCode({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.requestLoginCode(email: email, password: password);
      _email = email;
      _status = AuthStatus.codeSent;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _extractError(e);
      notifyListeners();
      return false;
    }
  }

  /// Paso 2 del login: valida el código 2FA.
  ///
  /// 🔒 **Bloqueo de admin**: si `peticion == 2` el login se rechaza
  /// y no se guarda token ni sesión.
  Future<bool> verifyCode(String code) async {
    final email = _email;
    if (email == null) {
      _status = AuthStatus.error;
      _errorMessage = 'Primero ingresa tu correo y contraseña.';
      notifyListeners();
      return false;
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.verifyCode(email: email, code: code.trim());

      final int peticion = mapearRol(result.rol);

      // 🚫 Seguridad: la app es exclusiva de clientes.
      if (peticion == 2) {
        _status = AuthStatus.error;
        _errorMessage = 'Acceso restringido: esta app es exclusiva de clientes. '
            'Usa la versión web para administración.';
        notifyListeners();
        return false;
      }

      if (peticion != 1) {
        _status = AuthStatus.error;
        _errorMessage = 'Rol no permitido en esta aplicación.';
        notifyListeners();
        return false;
      }

      // ✅ Solo cliente (1): se persiste la sesión.
      await _storage.saveSession(
        token: result.token,
        rol: result.rol,
        nombre: result.nombre,
      );

      _role = AppRole.cliente;
      _nombre = result.nombre;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _extractError(e);
      notifyListeners();
      return false;
    }
  }

  /// Restaura la sesión guardada al abrir la app (splash).
  ///
  /// Por seguridad: si por cualquier motivo existe una sesión de `admin`
  /// persistida, se borra y se regresa a invitado.
  Future<void> restoreSession() async {
    if (!_storage.isLoggedIn) {
      _role = AppRole.invitado;
      _status = AuthStatus.initial;
      notifyListeners();
      return;
    }

    final int peticion = mapearRol(_storage.rol);

    if (peticion == 2) {
      await _storage.clear();
      _role = AppRole.invitado;
      _status = AuthStatus.initial;
      notifyListeners();
      return;
    }

    if (peticion == 1) {
      _role = AppRole.cliente;
      _nombre = _storage.nombre;
      _status = AuthStatus.authenticated;
    } else {
      await _storage.clear();
      _role = AppRole.invitado;
      _status = AuthStatus.initial;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await _storage.clear();
    _role = AppRole.invitado;
    _nombre = null;
    _email = null;
    _status = AuthStatus.initial;
    notifyListeners();
  }

  String _extractError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic> && data['error'] != null) {
        return data['error'].toString();
      }
      if (error.response?.statusCode == 429) {
        return 'Demasiados intentos fallidos. Intenta de nuevo más tarde.';
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Problema de conexión con el servidor.';
      }
    }
    return 'Ocurrió un error inesperado.';
  }
}
