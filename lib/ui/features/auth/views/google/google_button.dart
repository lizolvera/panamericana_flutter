import 'package:flutter/widgets.dart';

import 'google_button_io.dart'
    if (dart.library.js_interop) 'google_button_web.dart' as impl;

/// Botón de inicio de sesión con Google adaptado a la plataforma:
/// - **Web**: renderiza el botón oficial de Google (GIS) vía `renderButton`;
///   el flujo completa con el stream de autenticación del AuthViewModel.
/// - **Móvil/desktop**: botón de Material que dispara
///   `AuthViewModel.loginWithGoogle()` (flujo `authenticate()`).
Widget googleSignInButton(
  BuildContext context,
  Future<bool> Function() onLogin,
) {
  return impl.buildGoogleSignInButton(context, onLogin);
}
