import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panamericana_flutter/ui/features/auth/views/login_view.dart';
import 'package:panamericana_flutter/ui/features/auth/views/registro_view.dart';
import 'package:panamericana_flutter/ui/features/auth/views/recuperacion_view.dart';
import 'package:panamericana_flutter/ui/shared/preguntas_secretas.dart';

import 'support/fixture_api.dart';

void main() {
  late FixtureApi f;
  setUp(() async {
    f = FixtureApi();
    await f.init();
  });
  tearDown(() async => f.dispose());
  Future<void> route(WidgetTester t, Widget child) async {
    await renderFixture(
      t,
      f,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => child)),
            child: const Text('Abrir formulario'),
          ),
        ),
      ),
    );
    await press(t, 'Abrir formulario');
  }

  Future<void> hint(WidgetTester t, String h, String value) async {
    final finder = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == h,
    );
    await t.ensureVisible(finder);
    await t.enterText(finder, value);
  }

  testWidgets(
    'login valida vacíos y completa 2FA conservando una sesión de cliente',
    (t) async {
      await route(t, const LoginView());
      await press(t, 'Continuar');
      expect(find.text('El correo es obligatorio'), findsOneWidget);
      await hint(t, 'Email @ Panamericana.com', 'ana@example.test');
      await hint(t, 'Contraseña', 'Prueba2026!');
      await press(t, 'Continuar');
      expect(find.text('Verificación 2FA'), findsOneWidget);
      await hint(t, '------', '123456');
      await press(t, 'Verificar y entrar');
      expect(f.auth.isCliente, isTrue);
      expect(find.text('Abrir formulario'), findsOneWidget);
    },
  );
  testWidgets(
    'login comunica el rechazo de credenciales y permite corregirlas',
    (t) async {
      f.failures['/api/usuarios/login'] = 'Credenciales incorrectas';
      await route(t, const LoginView());
      await hint(t, 'Email @ Panamericana.com', 'ana@example.test');
      await hint(t, 'Contraseña', 'incorrecta');
      await press(t, 'Continuar');
      expect(find.text('Credenciales incorrectas'), findsOneWidget);
      expect(f.auth.isAuthenticated, isFalse);
    },
  );
  testWidgets(
    'recuperación valida correo y respuesta antes de cambiar contraseña',
    (t) async {
      await route(t, const RecuperacionView());
      await press(t, 'Continuar');
      expect(find.text('El correo es obligatorio'), findsOneWidget);
      await fill(t, 'Correo registrado', 'ana@example.test');
      await press(t, 'Continuar');
      expect(find.textContaining('personaje favorito'), findsOneWidget);
      await press(t, 'Verificar respuesta');
      expect(find.textContaining('La respuesta'), findsWidgets);
      await fill(t, 'Respuesta', 'Personaje');
      await press(t, 'Verificar respuesta');
      await fill(t, 'Nueva contraseña', 'NuevaPrueba2026!');
      await fill(t, 'Confirmar contraseña', 'no coincide');
      await press(t, 'Restablecer contraseña');
      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
      await fill(t, 'Confirmar contraseña', 'NuevaPrueba2026!');
      await press(t, 'Restablecer contraseña');
      expect(
        find.text('Contraseña restablecida. Inicia sesión.'),
        findsOneWidget,
      );
      expect(f.requests.last.path, '/api/usuarios/cambiar-contrasena');
    },
  );
  testWidgets(
    'recuperación conserva el paso cuando el servidor rechaza la respuesta',
    (t) async {
      f.failures['/api/usuarios/verificar-respuesta'] = 'Respuesta incorrecta';
      await route(t, const RecuperacionView());
      await fill(t, 'Correo registrado', 'ana@example.test');
      await press(t, 'Continuar');
      await fill(t, 'Respuesta', 'Prueba');
      await press(t, 'Verificar respuesta');
      expect(find.text('Respuesta incorrecta'), findsOneWidget);
      expect(field('Respuesta'), findsOneWidget);
    },
  );
  testWidgets(
    'registro valida obligatorios y envía los datos de una nueva cuenta',
    (t) async {
      await route(t, const RegistroView());
      await press(t, 'Crear cuenta');
      await t.ensureVisible(field('Nombre *'));
      await t.pumpAndSettle();
      expect(find.textContaining('obligatorio'), findsWidgets);
      for (final e in {
        'Nombre *': 'Ana',
        'Apellido paterno': 'Prueba',
        'Apellido materno': 'Cliente',
        'Correo *': 'ana@example.test',
        'Teléfono (10 dígitos) *': '2221234567',
        'Contraseña *': 'NuevaPrueba2026!',
        'Confirmar contraseña *': 'NuevaPrueba2026!',
        'Respuesta secreta *': 'Personaje',
      }.entries) {
        await fill(t, e.key, e.value);
      }
      final drop = find.byType(DropdownButtonFormField<String>);
      await t.ensureVisible(drop);
      await t.tap(drop);
      await t.pumpAndSettle();
      await t.tap(find.text(kPreguntasSecretas.values.first).last);
      await t.pumpAndSettle();
      await press(t, 'Crear cuenta');
      expect(f.requests.last.path, '/api/usuarios/register');
      expect(f.requests.last.data['nombre'], 'Ana');
      expect(
        find.text('Cuenta creada con éxito. Inicia sesión.'),
        findsOneWidget,
      );
    },
  );
}
