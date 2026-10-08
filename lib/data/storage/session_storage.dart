import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Almacenamiento local de la sesión: token JWT, rol y nombre.
///
/// **Singleton** para garantizar consistencia en el manejo de credenciales
/// (mismo equivalente que el localStorage del frontend Angular).
class SessionStorage {
  SessionStorage._();

  static final SessionStorage instance = SessionStorage._();

  static const String _kToken = 'user_token';
  static const String _kRol = 'user_rol';
  static const String _kNombre = 'user_name';

  SharedPreferences? _prefs;

  /// Debe llamarse una sola vez antes de `runApp`.
  ///
  /// Nunca lanza: si el almacenamiento local no está disponible, la app
  /// arranca igual (los getters devuelven null y guardar no hace nada).
  Future<void> init() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('[SessionStorage] Almacenamiento local no disponible: $e');
    }
  }

  String? get token => _prefs?.getString(_kToken);
  String? get rol => _prefs?.getString(_kRol);
  String? get nombre => _prefs?.getString(_kNombre);

  bool get isLoggedIn {
    final t = token;
    return t != null && t.isNotEmpty;
  }

  Future<void> saveSession({
    required String token,
    required String rol,
    required String nombre,
  }) async {
    await _prefs?.setString(_kToken, token);
    await _prefs?.setString(_kRol, rol);
    await _prefs?.setString(_kNombre, nombre);
  }

  Future<void> clear() async {
    await _prefs?.remove(_kToken);
    await _prefs?.remove(_kRol);
    await _prefs?.remove(_kNombre);
  }
}
