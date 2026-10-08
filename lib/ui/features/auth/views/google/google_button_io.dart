import 'package:flutter/material.dart';

/// Botón de Material para plataformas no-web (Android/iOS/desktop).
/// Llama al flujo de `authenticate()` del AuthViewModel.
Widget buildGoogleSignInButton(
  BuildContext context,
  Future<bool> Function() onLogin,
) {
  return OutlinedButton.icon(
    onPressed: () => onLogin(),
    icon: const Text(
      'G',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF4285F4),
      ),
    ),
    label: const Text('Continuar con Google'),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
    ),
  );
}
