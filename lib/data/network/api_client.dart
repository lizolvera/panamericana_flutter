import 'package:dio/dio.dart';

import '../storage/session_storage.dart';

/// Cliente HTTP **Singleton** (patrón Singleton de la arquitectura).
///
/// Centraliza la conexión con la API de Render y agrega el token JWT
/// automáticamente a cada petición. IMPORTANTE: el backend de
/// pryBinaBack recibe el token **crudo** (sin prefijo "Bearer").
class ApiClient {
  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://prybinaback.onrender.com',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = SessionStorage.instance.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = token;
          }
          handler.next(options);
        },
        onError: (error, handler) {
          // Si el backend responde 401 (token expirado/sesión cerrada),
          // la sesión local queda inválida y se limpia.
          if (error.response?.statusCode == 401) {
            SessionStorage.instance.clear();
          }
          handler.next(error);
        },
      ),
    );
  }

  /// Única instancia global del cliente HTTP.
  static final ApiClient instance = ApiClient._internal();

  late final Dio dio;
}
