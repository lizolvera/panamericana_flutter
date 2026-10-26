import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:panamericana_flutter/data/network/api_client.dart';
import 'package:panamericana_flutter/data/repositories/auth_repository.dart';
import 'package:panamericana_flutter/data/repositories/catalog_repository.dart';
import 'package:panamericana_flutter/data/storage/session_storage.dart';
import 'package:panamericana_flutter/ui/features/auth/view_models/auth_view_model.dart';
import 'package:panamericana_flutter/ui/features/cart/view_models/cart_view_model.dart';
import 'package:panamericana_flutter/ui/features/catalog/view_models/catalog_view_model.dart';
import 'package:panamericana_flutter/ui/features/shell/tab_index_notifier.dart';
import 'package:panamericana_flutter/ui/theme/app_theme.dart';
import 'package:panamericana_flutter/ui/features/catalog/views/catalog_view.dart';
import 'package:panamericana_flutter/ui/features/auth/views/login_view.dart';

class FixtureApi {
  final Dio dio = ApiClient.instance.dio;
  late List<Interceptor> previous;
  final requests = <RequestOptions>[];
  final failures = <String, Object>{};
  final overrides = <String, dynamic>{};
  final address = <String, dynamic>{
    '_id': 'd1',
    'alias': 'Casa',
    'calle': 'Calle Prueba 123',
    'colonia': 'Centro',
    'ciudad': 'Puebla',
    'estado': 'Puebla',
    'cp': '72000',
    'telefono': '2221234567',
    'referencias': 'Puerta azul',
    'predeterminada': true,
  };
  late Map<String, dynamic> profile;
  late List<Map<String, dynamic>> products;
  late List<Map<String, dynamic>> addresses;
  late AuthRepository authRepo;
  late CatalogRepository catalogRepo;
  late AuthViewModel auth;
  late CartViewModel cart;
  late CatalogViewModel catalog;
  late TabIndexNotifier tab;

  Future<void> init({bool signedIn = false}) async {
    SharedPreferences.setMockInitialValues({});
    await SessionStorage.instance.init();
    await SessionStorage.instance.clear();
    addresses = [Map.of(address)];
    profile = {
      '_id': 'u1',
      'nombre': 'Ana',
      'ap': 'Prueba',
      'am': 'Cliente',
      'email': 'ana@example.test',
      'telefono': '2221234567',
      'rol': 'usuario',
      'fechaNacimiento': '2000-02-03',
      'preguntaSecreta': 'personaje-favorito',
      'direcciones': addresses,
    };
    products = List.generate(
      12,
      (i) => {
        '_id': 'p$i',
        'nombre': 'Champú de prueba $i',
        'descripcion': 'Descripción del producto $i',
        'precioNormal': 100 + i,
        'precioMayoreo': 80 + i,
        'precioCaja': 900 + i,
        'stock': 20,
        'activo': true,
        'skuNormal': 'SKU-$i',
        'skuMayoreo': 'M-$i',
        'skuCaja': 'C-$i',
        'marca': {
          '_id': i.isEven ? 'm1' : 'm2',
          'nombre': i.isEven ? 'Marca Uno' : 'Marca Dos',
        },
        'familia': {'_id': 'f1', 'nombre': 'Cabello', 'marca': 'm1'},
        if (i == 0) 'precioNormalFinal': 90,
        if (i == 0) 'precioFinal': 90,
        if (i == 0)
          'ofertaAplicada': {
            'nombre': 'Oferta del mes',
            'tipoDescuento': 'porcentaje',
            'valorDescuento': 10,
          },
      },
    );
    previous = List.of(dio.interceptors);
    dio.interceptors.clear();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) {
          requests.add(r);
          final failure = failures['${r.method} ${r.path}'] ?? failures[r.path];
          if (failure != null) {
            h.reject(
              failure is DioException
                  ? failure
                  : DioException(
                      requestOptions: r,
                      type: DioExceptionType.badResponse,
                      response: Response(
                        requestOptions: r,
                        statusCode: 400,
                        data: {'error': failure.toString()},
                      ),
                    ),
            );
            return;
          }
          try {
            h.resolve(
              Response(requestOptions: r, statusCode: 200, data: respond(r)),
            );
          } catch (e) {
            h.reject(DioException(requestOptions: r, error: e));
          }
        },
      ),
    );
    authRepo = AuthRepository(dio);
    catalogRepo = CatalogRepository(dio);
    auth = AuthViewModel(authRepo, SessionStorage.instance);
    cart = CartViewModel();
    catalog = CatalogViewModel(catalogRepo);
    tab = TabIndexNotifier();
    if (signedIn) {
      await SessionStorage.instance.saveSession(
        token: 'test-session',
        rol: 'usuario',
        nombre: 'Ana',
      );
      await auth.restoreSession();
    }
  }

  dynamic respond(RequestOptions r) {
    final key = '${r.method} ${r.path}';
    if (overrides.containsKey(key)) return overrides[key];
    if (overrides.containsKey(r.path)) return overrides[r.path];
    if (r.path == '/api/productos') return products;
    if (r.path.endsWith('/recomendaciones')) return products.take(2).toList();
    if (r.path.startsWith('/api/productos/')) {
      return products.firstWhere(
        (p) => p['_id'] == r.path.split('/').last,
        orElse: () => products.first,
      );
    }
    if (r.path == '/api/marcas') {
      return [
        {'_id': 'm1', 'nombre': 'Marca Uno'},
        {'_id': 'm2', 'nombre': 'Marca Dos'},
      ];
    }
    if (r.path == '/api/familias') {
      return [
        {
          '_id': 'f1',
          'nombre': 'Cabello',
          'marca': {'_id': 'm1', 'nombre': 'Marca Uno'},
        },
      ];
    }
    if (r.path == '/api/carruseles') return <dynamic>[];
    if (r.path == '/api/ofertas') {
      return [
        {
          '_id': 'o1',
          'nombre': 'Oferta del mes',
          'tipoDescuento': 'porcentaje',
          'valorDescuento': 10,
          'productos': ['p0'],
          'marcas': [
            {'_id': 'm1'},
          ],
        },
      ];
    }
    if (r.path == '/api/usuarios/perfil') {
      if (r.method == 'PUT') profile.addAll(Map<String, dynamic>.from(r.data));
      return profile;
    }
    if (r.path == '/api/usuarios/verify-2fa' ||
        r.path == '/api/usuarios/google-login') {
      return {'token': 'test-session', 'rol': 'usuario', 'nombre': 'Ana'};
    }
    if (r.path == '/api/usuarios/check-email' ||
        r.path == '/api/usuarios/check-phone') {
      return {'available': true};
    }
    if (r.path == '/api/usuarios/obtener-pregunta') {
      return {'preguntaSecreta': '¿Cuál es tu personaje favorito?'};
    }
    if (r.path == '/api/usuarios/direcciones') {
      if (r.method == 'POST') {
        final a = {
          ...Map<String, dynamic>.from(r.data),
          '_id': 'd${addresses.length + 1}',
        };
        addresses.add(a);
        return a;
      }
      return addresses;
    }
    if (r.path.startsWith('/api/usuarios/direcciones/')) {
      final id = r.path.split('/')[4];
      if (r.method == 'DELETE') {
        addresses.removeWhere((a) => a['_id'] == id);
        return {};
      }
      if (r.path.endsWith('/predeterminada')) {
        for (final a in addresses) {
          a['predeterminada'] = a['_id'] == id;
        }
        return {};
      }
      final a = addresses.firstWhere((a) => a['_id'] == id);
      a.addAll(Map<String, dynamic>.from(r.data));
      return a;
    }
    if (r.path == '/api/pedidos') {
      return [
        {
          '_id': 'order1',
          'usuario': 'u1',
          'estado': 'Entregado',
          'total': 100,
          'fecha': '2026-10-01T12:00:00Z',
          'createdAt': '2026-10-01T12:00:00Z',
          'productos': [
            {
              'producto': products.first,
              'nombre': 'Champú de prueba 0',
              'cantidad': 1,
              'precio': 100,
            },
          ],
          'direccionEnvio': address,
          'metodoPago': 'Prueba',
          'pago': {'estado': 'aprobado'},
        },
      ];
    }
    if (r.path.startsWith('/api/usuarios/')) {
      return {'mensaje': 'Operación correcta'};
    }
    throw StateError('Solicitud no simulada: $key');
  }

  Widget wrap(Widget child) => MultiProvider(
    providers: [
      Provider.value(value: ApiClient.instance),
      Provider.value(value: authRepo),
      Provider.value(value: catalogRepo),
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider.value(value: cart),
      ChangeNotifierProvider.value(value: catalog),
      ChangeNotifierProvider.value(value: tab),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
      routes: {
        '/catalogo': (_) => const CatalogViewPage(),
        '/login': (_) => const LoginView(),
      },
    ),
  );

  Future<void> dispose() async {
    dio.interceptors.clear();
    dio.interceptors.addAll(previous);
    auth.dispose();
    cart.dispose();
    catalog.dispose();
    tab.dispose();
    await SessionStorage.instance.clear();
  }
}

Future<void> renderFixture(
  WidgetTester tester,
  FixtureApi f,
  Widget child, {
  double width = 1000,
  double height = 1400,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(f.wrap(child));
  await tester.pumpAndSettle();
}

Finder field(String label) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.labelText == label,
);
Future<void> fill(WidgetTester tester, String label, String value) async {
  final target = field(label);
  await tester.ensureVisible(target);
  await tester.enterText(target, value);
}

Future<void> press(WidgetTester tester, String text) async {
  final button = find.widgetWithText(FilledButton, text);
  final target = button.evaluate().isNotEmpty
      ? button.last
      : find.text(text).last;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}
