import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart';

import 'google_init.dart';

/// Botón oficial de Google (GIS) para web.
///
/// Espera a que el SDK de Google termine de inicializarse; si falla,
/// muestra un aviso claro en lugar de quedarse en "Getting ready".
class _GoogleButtonWeb extends StatefulWidget {
  const _GoogleButtonWeb();

  @override
  State<_GoogleButtonWeb> createState() => _GoogleButtonWebState();
}

class _GoogleButtonWebState extends State<_GoogleButtonWeb> {
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = googleSignInInit();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 48,
            child: Center(child: Text('Cargando…')),
          );
        }
        if (snapshot.hasError) {
          return Text(
            'No se pudo cargar Google Sign-In.\n'
            'Revisa la consola (client_id o red).',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          );
        }
        return renderButton(
          configuration: GSIButtonConfiguration(
            type: GSIButtonType.standard,
            theme: GSIButtonTheme.filledBlue,
            size: GSIButtonSize.large,
            text: GSIButtonText.continueWith,
            shape: GSIButtonShape.pill,
          ),
        );
      },
    );
  }
}

Widget buildGoogleSignInButton(
  BuildContext context,
  Future<bool> Function() onLogin,
) {
  return const _GoogleButtonWeb();
}
