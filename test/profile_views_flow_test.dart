import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panamericana_flutter/ui/features/profile/views/datos_view.dart';
import 'package:panamericana_flutter/ui/features/profile/views/password_view.dart';
import 'package:panamericana_flutter/ui/features/profile/views/pregunta_view.dart';
import 'package:panamericana_flutter/ui/features/profile/views/direcciones_view.dart';
import 'package:panamericana_flutter/ui/features/profile/views/profile_view.dart';
import 'package:panamericana_flutter/ui/features/profile/view_models/profile_view_model.dart';
import 'package:panamericana_flutter/ui/features/profile/view_models/direcciones_view_model.dart';
import 'package:panamericana_flutter/ui/shared/preguntas_secretas.dart';

import 'support/fixture_api.dart';

void main() {
  late FixtureApi f;
  setUp(() async {
    f = FixtureApi();
    await f.init(signedIn: true);
  });
  tearDown(() async => f.dispose());
  testWidgets(
    'datos personales muestra perfil y guarda cambios sin permitir editar correo',
    (t) async {
      final vm = ProfileViewModel(f.authRepo);
      addTearDown(vm.dispose);
      await t.runAsync(vm.load);
      await renderFixture(t, f, DatosView(profileVm: vm));
      expect(field('Correo (no editable)'), findsOneWidget);
      expect(
        t.widget<TextField>(field('Correo (no editable)')).enabled,
        isFalse,
      );
      await fill(t, 'Nombre', 'Beatriz');
      await fill(t, 'Teléfono', '2229876543');
      await press(t, 'Guardar cambios');
      expect(
        f.requests
            .where((r) => r.method == 'PUT' && r.path.endsWith('/perfil'))
            .single
            .data['nombre'],
        'Beatriz',
      );
      expect(find.text('Perfil actualizado correctamente.'), findsOneWidget);
      await t.tap(find.text('3/2/2000'));
      await t.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await press(t, 'OK');
    },
  );
  testWidgets(
    'contraseña valida vacíos, coincidencia y guarda sin dejar texto sensible',
    (t) async {
      final vm = ProfileViewModel(f.authRepo);
      addTearDown(vm.dispose);
      await renderFixture(t, f, PasswordView(profileVm: vm));
      await press(t, 'Cambiar contraseña');
      expect(find.text('Ingresa tu contraseña actual'), findsOneWidget);
      await fill(t, 'Contraseña actual', 'Anterior2026!');
      await fill(t, 'Nueva contraseña', 'corta');
      await fill(t, 'Confirmar nueva contraseña', 'otra');
      await press(t, 'Cambiar contraseña');
      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
      await t.tap(find.byIcon(Icons.visibility_off));
      await t.pump();
      await fill(t, 'Nueva contraseña', 'NuevaPrueba2026!');
      await fill(t, 'Confirmar nueva contraseña', 'NuevaPrueba2026!');
      await press(t, 'Cambiar contraseña');
      expect(f.requests.last.path, '/api/usuarios/update-password');
      expect(
        t.widget<TextField>(field('Nueva contraseña')).controller!.text,
        '',
      );
      expect(
        find.text('Contraseña actualizada correctamente.'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'pregunta secreta exige pregunta y respuesta y guarda los datos seleccionados',
    (t) async {
      f.profile.remove('preguntaSecreta');
      final vm = ProfileViewModel(f.authRepo);
      addTearDown(vm.dispose);
      await t.runAsync(vm.load);
      await renderFixture(t, f, PreguntaView(profileVm: vm));
      await press(t, 'Guardar pregunta');
      expect(find.text('Selecciona una pregunta'), findsOneWidget);
      await t.tap(find.byType(DropdownButtonFormField<String>));
      await t.pumpAndSettle();
      await t.tap(find.text(kPreguntasSecretas.values.first).last);
      await t.pumpAndSettle();
      await fill(t, 'Respuesta secreta', 'Personaje de prueba');
      await press(t, 'Guardar pregunta');
      expect(f.requests.last.data, {
        'preguntaSecreta': kPreguntasSecretas.keys.first,
        'respuestaSecreta': 'Personaje de prueba',
      });
      expect(find.text('Pregunta y respuesta actualizadas.'), findsOneWidget);
    },
  );
  testWidgets('direcciones muestra vacíos, valida alta y crea una dirección', (
    t,
  ) async {
    f.addresses.clear();
    final vm = DireccionesViewModel(f.authRepo);
    addTearDown(vm.dispose);
    await t.runAsync(vm.load);
    await renderFixture(t, f, DireccionesView(direccionesVm: vm));
    expect(find.textContaining('Aún no tienes'), findsOneWidget);
    await t.tap(find.byTooltip('Agregar dirección'));
    await t.pumpAndSettle();
    await press(t, 'Guardar');
    expect(find.textContaining('El alias es obligatorio'), findsOneWidget);
    for (final e in {
      'Alias (ej. Casa)': 'Oficina',
      'Calle': 'Calle Prueba 456',
      'Colonia': 'Centro',
      'Ciudad': 'Puebla',
      'Estado': 'Puebla',
      'CP': '72000',
      'Teléfono': '2221234567',
      'Referencias': 'Puerta azul',
    }.entries) {
      await fill(t, e.key, e.value);
    }
    await t.tap(find.byType(CheckboxListTile));
    await t.pump();
    await press(t, 'Guardar');
    expect(vm.direcciones.single.alias, 'Oficina');
    expect(find.text('Oficina'), findsOneWidget);
    expect(find.text('Dirección guardada'), findsOneWidget);
  });
  testWidgets('direcciones edita, predetermina y confirma antes de eliminar', (
    t,
  ) async {
    final vm = DireccionesViewModel(f.authRepo);
    addTearDown(vm.dispose);
    await t.runAsync(vm.load);
    await renderFixture(t, f, DireccionesView(direccionesVm: vm));
    expect(find.text('Casa'), findsOneWidget);
    expect(find.text('Predeterminada'), findsOneWidget);
    Future<void> menu(String option) async {
      await t.tap(find.byType(PopupMenuButton<String>).first);
      await t.pumpAndSettle();
      await press(t, option);
    }

    await menu('Editar');
    await fill(t, 'Alias (ej. Casa)', 'Casa nueva');
    await press(t, 'Guardar');
    expect(vm.direcciones.single.alias, 'Casa nueva');
    await menu('Marcar predeterminada');
    expect(vm.direcciones.single.predeterminada, isTrue);
    await menu('Eliminar');
    await press(t, 'Cancelar');
    expect(vm.direcciones, hasLength(1));
    await menu('Eliminar');
    await press(t, 'Eliminar');
    expect(vm.direcciones, isEmpty);
    expect(find.textContaining('Aún no tienes'), findsOneWidget);
  });
  testWidgets(
    'direcciones muestra error y permite reintentar sin perder la pantalla',
    (t) async {
      f.failures['/api/usuarios/direcciones'] = 'Servicio no disponible';
      final vm = DireccionesViewModel(f.authRepo);
      addTearDown(vm.dispose);
      await t.runAsync(vm.load);
      await renderFixture(t, f, DireccionesView(direccionesVm: vm));
      expect(find.text('Servicio no disponible'), findsOneWidget);
      f.failures.clear();
      await press(t, 'Reintentar');
      expect(find.text('Casa'), findsOneWidget);
    },
  );
  testWidgets(
    'menú de perfil permite entrar a datos, seguridad y direcciones',
    (t) async {
      await renderFixture(t, f, const Scaffold(body: ProfileView()));
      expect(find.text('Ana'), findsWidgets);
      for (final option in [
        'CONTRASEÑA',
        'MIS DIRECCIONES',
        'PREGUNTA SECRETA',
      ]) {
        await press(t, option);
        expect(find.byType(Scaffold), findsWidgets);
        await t.pageBack();
        await t.pumpAndSettle();
      }
      expect(t.takeException(), isNull);
    },
  );
}
