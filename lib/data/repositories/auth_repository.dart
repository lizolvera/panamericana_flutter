import 'package:dio/dio.dart';

import '../../domain/models/direccion.dart';
import '../../domain/models/usuario.dart';

/// Resultado del paso 2 del login (`verify-2fa`): el backend responde
/// con `{ token, rol, nombre }`.
class AuthResult {
  const AuthResult({
    required this.token,
    required this.rol,
    required this.nombre,
  });

  final String token;
  final String rol;
  final String nombre;

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      token: json['token'] as String,
      rol: json['rol'] as String,
      nombre: json['nombre'] as String? ?? '',
    );
  }
}

/// **Repositorio de autenticación**: aísla el acceso a los endpoints
/// `/api/usuarios/*` (login con 2FA, perfil y direcciones).
class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  /// Paso 1 del login: envía credenciales. El backend responde enviando
  /// un código de 6 dígitos al correo del usuario (2FA).
  Future<void> requestLoginCode({
    required String email,
    required String password,
  }) async {
    await _dio.post(
      '/api/usuarios/login',
      data: {'email': email, 'password': password},
    );
  }

  /// Paso 2 del login: valida el código 2FA y devuelve `{ token, rol, nombre }`.
  Future<AuthResult> verifyCode({
    required String email,
    required String code,
  }) async {
    final res = await _dio.post(
      '/api/usuarios/verify-2fa',
      data: {'email': email, 'code': code},
    );
    return AuthResult.fromJson(res.data as Map<String, dynamic>);
  }

  /// Inicio de sesión con Google: el backend valida el `idToken`, crea el
  /// usuario si no existe y devuelve `{ token, rol, nombre }`.
  Future<AuthResult> loginWithGoogle(String idToken) async {
    final res = await _dio.post(
      '/api/usuarios/google-login',
      data: {'idToken': idToken},
    );
    return AuthResult.fromJson(res.data as Map<String, dynamic>);
  }

  /// Perfil del cliente autenticado.
  Future<Usuario> getPerfil() async {
    final res = await _dio.get('/api/usuarios/perfil');
    return Usuario.fromJson(res.data as Map<String, dynamic>);
  }

  /// Actualiza el perfil del cliente autenticado.
  Future<Usuario> updatePerfil(Map<String, dynamic> cambios) async {
    final res = await _dio.put('/api/usuarios/perfil', data: cambios);
    return Usuario.fromJson(res.data as Map<String, dynamic>);
  }

  // --- Direcciones de envío (solo cliente autenticado) ---

  Future<List<Direccion>> getDirecciones() async {
    final res = await _dio.get('/api/usuarios/direcciones');
    final data = res.data as List<dynamic>;
    return data
        .map((e) => Direccion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Direccion> createDireccion(Map<String, dynamic> direccion) async {
    final res = await _dio.post('/api/usuarios/direcciones', data: direccion);
    return Direccion.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Direccion> updateDireccion(
    String id,
    Map<String, dynamic> cambios,
  ) async {
    final res = await _dio.put('/api/usuarios/direcciones/$id', data: cambios);
    return Direccion.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteDireccion(String id) async {
    await _dio.delete('/api/usuarios/direcciones/$id');
  }

  /// Marca una dirección como predeterminada.
  Future<void> setDireccionPredeterminada(String id) async {
    await _dio.put('/api/usuarios/direcciones/$id/predeterminada');
  }

  /// Cambia la contraseña del cliente autenticado.
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.put(
      '/api/usuarios/update-password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  /// Actualiza la pregunta y respuesta secreta.
  Future<void> updateSecret({
    required String preguntaSecreta,
    required String respuestaSecreta,
  }) async {
    await _dio.put(
      '/api/usuarios/update-secret',
      data: {
        'preguntaSecreta': preguntaSecreta,
        'respuestaSecreta': respuestaSecreta,
      },
    );
  }
}
