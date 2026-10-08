import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/network/api_client.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/catalog_repository.dart';
import 'data/storage/session_storage.dart';
import 'ui/features/auth/view_models/auth_view_model.dart';
import 'ui/features/cart/view_models/cart_view_model.dart';
import 'ui/features/shell/tab_index_notifier.dart';
import 'ui/features/auth/views/google/google_init.dart';
import 'ui/features/auth/views/login_view.dart';
import 'ui/features/catalog/view_models/catalog_view_model.dart';
import 'ui/features/home/views/home_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Almacenamiento local: si falla o se cuelga (sin internet, privacidad,
  // incógnito), la app DEBE arrancar igual: el esqueleto siempre se muestra.
  try {
    await SessionStorage.instance
        .init()
        .timeout(const Duration(seconds: 4));
  } catch (_) {
    debugPrint('[main] Sin almacenamiento local; continúa sin sesión.');
  }

  // Inicia Google Sign-In sin bloquear el arranque de la app; el botón
  // de Google espera este futuro y reacciona ante errores.
  googleSignInInit().catchError((Object e) {
    debugPrint('[main] GoogleSignIn.initialize falló: $e');
  });

  // Instancias únicas de los repositorios (patrón Repository + Singleton).
  final authRepository = AuthRepository(ApiClient.instance.dio);
  final catalogRepository = CatalogRepository(ApiClient.instance.dio);

  final cartViewModel = CartViewModel();
  final authViewModel =
      AuthViewModel(authRepository, SessionStorage.instance);

  // 🔒 La sesión manda: al cerrar sesión (o expirar), el carrito se vacía
  // y el badge de la barra inferior desaparece.
  authViewModel.addListener(() {
    if (!authViewModel.isAuthenticated) {
      cartViewModel.limpiar();
    }
  });

  runApp(
    MultiProvider(
      providers: [
        // Cliente HTTP Singleton.
        Provider.value(value: ApiClient.instance),
        Provider.value(value: authRepository),
        Provider.value(value: catalogRepository),
        // ViewModels (MVVM) — la UI observa estos estados.
        ChangeNotifierProvider.value(value: authViewModel),
        ChangeNotifierProvider(create: (_) => CatalogViewModel(catalogRepository)),
        ChangeNotifierProvider.value(value: cartViewModel),
        ChangeNotifierProvider(create: (_) => TabIndexNotifier()),
      ],
      child: const PanamericanaApp(),
    ),
  );
}

class PanamericanaApp extends StatelessWidget {
  const PanamericanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Distribuidora Panamericana',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeView(),
        '/login': (_) => const LoginView(),
      },
    );
  }
}
