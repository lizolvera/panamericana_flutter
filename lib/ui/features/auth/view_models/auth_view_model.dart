import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/storage/session_storage.dart';
import '../views/google/google_init.dart';

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
  AuthViewModel(this._repository, this._storage) {
    // En web el flujo de Google es mediante el botón GSI renderizado
    // (renderButton): el plugin emite eventos de autenticación y aquí
    // los procesamos (obtenemos idToken y llamamos al backend).
    if (kIsWeb) {
      _suscripcionWeb = _signIn.authenticationEvents.listen((evento) {
        if (evento is GoogleSignInAuthenticationEventSignIn) {
          _procesarCuentaGoogle(evento.user);
        }
      });
    }
  }

  StreamSubscription<GoogleSignInAuthenticationEvent>? _suscripcionWeb;

  @override
  void dispose() {
    _suscripcionWeb?.cancel();
    super.dispose();
  }

  final AuthRepository _repository;
  final SessionStorage _storage;

  /// Singleton de google_sign_in v7 (debe inicializarse en main()).
  GoogleSignIn get _signIn => GoogleSignIn.instance;

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
      final result = await _repository.verifyCode(
        email: email,
        code: code.trim(),
      );
      return await _aceptarSesion(result);
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _extractError(e);
      notifyListeners();
      return false;
    }
  }

  /// Inicio de sesión con Google: obtiene el `idToken`, el backend lo valida
  /// (y crea el usuario si no existe) y aplica el mismo bloqueo de admin.
  Future<bool> loginWithGoogle() async {
    // El plugin de google_sign_in NO soporta Linux/Windows desktop.
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.windows)) {
      _status = AuthStatus.error;
      _errorMessage = 'Google Sign-In no está disponible en esta plataforma. '
          'Usa la versión web (Chrome) o Android, o inicia sesión con correo.';
      notifyListeners();
      return false;
    }

    // En web el flujo lo dispara el botón GSI (renderButton) + stream.
    if (kIsWeb) return false;

    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Asegura la inicialización (idempotente) antes de autenticar.
      await googleSignInInit();
      final account = await _signIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        _status = AuthStatus.error;
        _errorMessage = 'No se pudo obtener el token de Google.';
        notifyListeners();
        return false;
      }

      final result = await _repository.loginWithGoogle(idToken);
      return await _aceptarSesion(result);
    } on GoogleSignInException catch (e) {
      // El usuario canceló el flujo de Google: no es un error.
      if (e.code == GoogleSignInExceptionCode.canceled) {
        _status = AuthStatus.initial;
        notifyListeners();
        return false;
      }
      debugPrint('[AuthViewModel] GoogleSignInException: '
          '${e.code.name} - ${e.description}');
      _status = AuthStatus.error;
      _errorMessage = _extractError(e);
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('[AuthViewModel] Error Google: $e');
      _status = AuthStatus.error;
      _errorMessage = _extractError(e);
      notifyListeners();
      return false;
    }
  }

  /// Procesa el evento del botón GSI en web: obtiene el idToken de la
  /// cuenta y lo envía al backend (mismo bloqueo de admin).
  Future<void> _procesarCuentaGoogle(GoogleSignInAccount account) async {
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      _status = AuthStatus.error;
      _errorMessage = 'No se pudo obtener el token de Google.';
      notifyListeners();
      return;
    }
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.loginWithGoogle(idToken);
      await _aceptarSesion(result);
    } catch (e) {
      debugPrint('[AuthViewModel] Error al procesar cuenta Google: $e');
      _status = AuthStatus.error;
      _errorMessage = _extractError(e);
      notifyListeners();
    }
  }

  /// 🔒 Regla de seguridad compartida (2FA y Google): la app es exclusiva
  /// de clientes. Si el rol es `admin` (peticion == 2) se rechaza el login
  /// y **no se persiste ninguna sesión**.
  Future<bool> _aceptarSesion(AuthResult result) async {
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
    // Cierra también la sesión de Google si se usó.
    try {
      await _signIn.signOut();
    } catch (_) {
      // Si Google no estaba iniciado, no pasa nada.
    }
    _role = AppRole.invitado;
    _nombre = null;
    _email = null;
    _status = AuthStatus.initial;
    notifyListeners();
  }

  /// Permite reiniciar el flujo de login (p. ej. si el usuario ingresó un correo erróneo en el paso 1).
  void resetState() {
    _status = AuthStatus.initial;
    _errorMessage = null;
    _email = null;
    notifyListeners();
  }

  String _extractError(Object error) {
    if (error is GoogleSignInException) {
      final desc = error.description;
      if (desc != null && desc.isNotEmpty) {
        return 'Error de Google: $desc';
      }
      return 'Error de Google (${error.code.name}).';
    }
    if (error is MissingPluginException) {
      return 'Google Sign-In no está disponible en esta plataforma. '
          'Usa la versión web (Chrome) o Android, o inicia sesión con correo.';
    }
    if (error is PlatformException) {
      final msg = error.message;
      return (msg != null && msg.isNotEmpty)
          ? 'Error de plataforma: $msg'
          : 'Error de plataforma (${error.code}).';
    }
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
    debugPrint('[AuthViewModel] error sin clasificar: $error');
    return 'Ocurrió un error inesperado.';
  }
}
