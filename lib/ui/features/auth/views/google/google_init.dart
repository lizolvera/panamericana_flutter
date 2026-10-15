import 'package:google_sign_in/google_sign_in.dart';

/// Inicializa Google Sign-In una vez por sesión de la app.
///
/// El `Future` queda guardado para que main(), el botón web y el ViewModel
/// puedan esperarlo sin inicializar dos veces. Si falla, se limpia para que
/// un siguiente intento pueda volver a cargar Google.
Future<void>? _googleInitFuture;

/// Client ID de la app (coincide con el audience del backend).
const String kGoogleClientId =
    '610797077240-hd26f06tg0k68v7hhtuoi5fdl76a50rf.apps.googleusercontent.com';

/// Inicializa Google Sign-In con un **timeout** de 10s: si el script de
/// Google no puede cargarse (p. ej. sin internet), el futuro termina con
/// error y el botón muestra su aviso en lugar de quedarse "Cargando…".
Future<void> googleSignInInit() {
  final current = _googleInitFuture;
  if (current != null) return current;

  final future = GoogleSignIn.instance
      .initialize(clientId: kGoogleClientId)
      .timeout(const Duration(seconds: 10));
  _googleInitFuture = future;

  return future.catchError((Object error) {
    _googleInitFuture = null;
    throw error;
  });
}
