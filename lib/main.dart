import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/network/api_client.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/catalog_repository.dart';
import 'data/storage/session_storage.dart';
import 'ui/features/auth/view_models/auth_view_model.dart';
import 'ui/features/auth/views/login_view.dart';
import 'ui/features/catalog/view_models/catalog_view_model.dart';
import 'ui/features/home/views/home_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa el almacenamiento local de la sesión (una sola vez).
  await SessionStorage.instance.init();

  // Instancias únicas de los repositorios (patrón Repository + Singleton).
  final authRepository = AuthRepository(ApiClient.instance.dio);
  final catalogRepository = CatalogRepository(ApiClient.instance.dio);

  runApp(
    MultiProvider(
      providers: [
        // Cliente HTTP Singleton.
        Provider.value(value: ApiClient.instance),
        Provider.value(value: authRepository),
        Provider.value(value: catalogRepository),
        // ViewModels (MVVM) — la UI observa estos estados.
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(authRepository, SessionStorage.instance),
        ),
        ChangeNotifierProvider(create: (_) => CatalogViewModel(catalogRepository)),
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
