import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:panamericana_flutter/data/repositories/auth_repository.dart';
import 'package:panamericana_flutter/data/storage/session_storage.dart';
import 'package:panamericana_flutter/domain/models/producto.dart';
import 'package:panamericana_flutter/ui/features/auth/view_models/auth_view_model.dart';
import 'package:panamericana_flutter/ui/features/cart/view_models/cart_view_model.dart';
import 'package:panamericana_flutter/ui/features/home/views/home_view.dart';
import 'package:panamericana_flutter/ui/features/shell/tab_index_notifier.dart';
import 'package:panamericana_flutter/ui/theme/app_theme.dart';

import 'fonts.dart';

void main() {
  setUpAll(loadGoldenFonts);
  testWidgets('carrito con productos, cantidades y total', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await SessionStorage.instance.init();
    await SessionStorage.instance.saveSession(
      token: 'synthetic',
      rol: 'usuario',
      nombre: 'Cliente CI',
    );
    final auth = AuthViewModel(AuthRepository(Dio()), SessionStorage.instance);
    await auth.restoreSession();
    final cart = CartViewModel()
      ..agregar(
        const Producto(id: '1', nombre: 'Shampoo de prueba', precioNormal: 100),
        cantidad: 2,
      );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: cart),
          ChangeNotifierProvider(create: (_) => TabIndexNotifier()..indice = 1),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme.copyWith(platform: TargetPlatform.android),
          home: const RepaintBoundary(
            key: Key('cart-golden'),
            child: HomeView(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Shampoo de prueba'), findsOneWidget);
    await expectLater(
      find.byKey(const Key('cart-golden')),
      matchesGoldenFile(goldenPath('cart.png')),
    );
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
    cart.dispose();
    await SessionStorage.instance.clear();
  });
}
