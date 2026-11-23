import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:panamericana_flutter/data/network/api_client.dart';
import 'package:panamericana_flutter/data/repositories/auth_repository.dart';
import 'package:panamericana_flutter/data/repositories/catalog_repository.dart';
import 'package:panamericana_flutter/data/storage/session_storage.dart';
import 'package:panamericana_flutter/main.dart';
import 'package:panamericana_flutter/ui/features/auth/view_models/auth_view_model.dart';
import 'package:panamericana_flutter/ui/features/cart/view_models/cart_view_model.dart';
import 'package:panamericana_flutter/ui/features/catalog/view_models/catalog_view_model.dart';
import 'package:panamericana_flutter/ui/features/catalog/views/product_detail_view.dart';
import 'package:panamericana_flutter/ui/features/shell/tab_index_notifier.dart';
import 'package:panamericana_flutter/ui/theme/app_theme.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  testWidgets('La app arranca mostrando el catálogo (vista invitado)',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await SessionStorage.instance.init();

    final authRepository = AuthRepository(ApiClient.instance.dio);
    final catalogRepository = CatalogRepository(ApiClient.instance.dio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) =>
                AuthViewModel(authRepository, SessionStorage.instance),
          ),
          ChangeNotifierProvider(
            create: (_) => CatalogViewModel(catalogRepository),
          ),
          ChangeNotifierProvider(create: (_) => CartViewModel()),
          ChangeNotifierProvider(create: (_) => TabIndexNotifier()),
        ],
        child: const PanamericanaApp(),
      ),
    );

    // En los tests la red está bloqueada: el ViewModel pasa a estado error
    // y la UI muestra el encabezado del catálogo + botón "Reintentar".
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Panamericana'), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('El detalle de producto maneja el error de red',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await SessionStorage.instance.init();

    final authRepository = AuthRepository(ApiClient.instance.dio);
    final catalogRepository = CatalogRepository(ApiClient.instance.dio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: catalogRepository),
          ChangeNotifierProvider(
            create: (_) =>
                AuthViewModel(authRepository, SessionStorage.instance),
          ),
          ChangeNotifierProvider(create: (_) => CartViewModel()),
          ChangeNotifierProvider(create: (_) => TabIndexNotifier()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProductDetailView(productoId: 'abc123'),
        ),
      ),
    );

    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Detalle'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
