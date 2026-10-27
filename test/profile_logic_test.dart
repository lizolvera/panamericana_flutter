import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panamericana_flutter/ui/features/profile/view_models/profile_view_model.dart';
import 'package:panamericana_flutter/ui/features/profile/view_models/direcciones_view_model.dart';

import 'support/fixture_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FixtureApi f;
  setUp(() async {
    f = FixtureApi();
    await f.init();
  });
  tearDown(() async => f.dispose());
  test('perfil carga datos, guarda cambios y comunica confirmación', () async {
    final vm = ProfileViewModel(f.authRepo);
    addTearDown(vm.dispose);
    final states = <ProfileStatus>[];
    vm.addListener(() => states.add(vm.status));
    await vm.load();
    expect(states, [ProfileStatus.loading, ProfileStatus.loaded]);
    expect(vm.perfil!.email, 'ana@example.test');
    expect(vm.error, isNull);
    expect(await vm.actualizarDatos({'nombre': 'Beatriz'}), isTrue);
    expect(vm.perfil!.nombre, 'Beatriz');
    expect(vm.accion, AccionStatus.ok);
    expect(vm.mensaje, contains('actualizado'));
    vm.reiniciarAccion();
    expect(vm.accion, AccionStatus.idle);
    expect(vm.mensaje, isNull);
    expect(
      await vm.cambiarContrasena(
        currentPassword: 'Anterior2026!',
        newPassword: 'NuevaPrueba2026!',
      ),
      isTrue,
    );
    expect(f.requests.last.data, {
      'currentPassword': 'Anterior2026!',
      'newPassword': 'NuevaPrueba2026!',
    });
    expect(
      await vm.actualizarPregunta(
        preguntaSecreta: 'personaje-favorito',
        respuestaSecreta: 'Ana',
      ),
      isTrue,
    );
    expect(f.requests.last.data['respuestaSecreta'], 'Ana');
  });
  for (final error in [
    'Rechazado',
    DioException(
      requestOptions: RequestOptions(path: '/'),
      type: DioExceptionType.connectionTimeout,
    ),
    StateError('offline'),
  ]) {
    test(
      'perfil mantiene estados coherentes al fallar ${error.runtimeType}',
      () async {
        final vm = ProfileViewModel(f.authRepo);
        addTearDown(vm.dispose);
        f.failures['/api/usuarios/perfil'] = error;
        await vm.load();
        expect(vm.status, ProfileStatus.error);
        expect(vm.error, isNotEmpty);
        expect(await vm.actualizarDatos({'nombre': 'Ana'}), isFalse);
        expect(vm.accion, AccionStatus.error);
        expect(vm.mensaje, isNotEmpty);
        f.failures['/api/usuarios/update-password'] = error;
        expect(
          await vm.cambiarContrasena(currentPassword: 'a', newPassword: 'b'),
          isFalse,
        );
        f.failures['/api/usuarios/update-secret'] = error;
        expect(
          await vm.actualizarPregunta(
            preguntaSecreta: 'p',
            respuestaSecreta: 'r',
          ),
          isFalse,
        );
        f.failures.clear();
        await vm.load();
        expect(vm.status, ProfileStatus.loaded);
        expect(vm.error, isNull);
      },
    );
  }
  test('direcciones crea, actualiza, predetermina y elimina sin alterar otra dirección', () async {
    final vm = DireccionesViewModel(f.authRepo);
    addTearDown(vm.dispose);
    expect(vm.status, DireccionesStatus.initial);
    await vm.load();
    expect(vm.direcciones, hasLength(1));
    expect(() => vm.direcciones.clear(), throwsUnsupportedError);
    expect(await vm.crear({...f.address, 'alias': 'Oficina'}), isTrue);
    expect(vm.direcciones, hasLength(2));
    expect(vm.guardando, isFalse);
    expect(await vm.actualizar('d2', {'alias': 'Trabajo'}), isTrue);
    expect(vm.direcciones.last.alias, 'Trabajo');
    expect(await vm.marcarPredeterminada('d2'), isTrue);
    expect(vm.direcciones.last.predeterminada, isTrue);
    expect(vm.direcciones.first.predeterminada, isFalse);
    expect(await vm.eliminar('d2'), isTrue);
    expect(vm.direcciones.single.alias, 'Casa');
  });
  for (final error in [
    'Sin permiso',
    DioException(
      requestOptions: RequestOptions(path: '/'),
      type: DioExceptionType.connectionError,
    ),
    Exception('offline'),
  ]) {
    test(
      'direcciones permite reintentar y libera el indicador de guardado ${error.runtimeType}',
      () async {
        final vm = DireccionesViewModel(f.authRepo);
        addTearDown(vm.dispose);
        f.failures['/api/usuarios/direcciones'] = error;
        await vm.load();
        expect(vm.status, DireccionesStatus.error);
        expect(vm.error, isNotEmpty);
        expect(await vm.crear(f.address), isFalse);
        expect(vm.guardando, isFalse);
        expect(vm.error, isNotEmpty);
        f.failures.clear();
        await vm.load();
        expect(vm.status, DireccionesStatus.loaded);
        expect(vm.error, isNull);
      },
    );
  }
}
