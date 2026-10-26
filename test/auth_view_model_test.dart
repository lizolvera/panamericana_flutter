import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:panamericana_flutter/data/repositories/auth_repository.dart';
import 'package:panamericana_flutter/data/storage/session_storage.dart';
import 'package:panamericana_flutter/ui/features/auth/view_models/auth_view_model.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late AuthViewModel vm;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SessionStorage.instance.init();
    await SessionStorage.instance.clear();
    repository = MockAuthRepository();
    vm = AuthViewModel(repository, SessionStorage.instance);
  });
  tearDown(() => vm.dispose());

  Future<void> requestCode() async {
    when(
      () => repository.requestLoginCode(
        email: 'cliente@example.com',
        password: 'synthetic',
      ),
    ).thenAnswer((_) async {});
    expect(
      await vm.sendLoginCode(
        email: 'cliente@example.com',
        password: 'synthetic',
      ),
      isTrue,
    );
    expect(vm.status, AuthStatus.codeSent);
  }

  test('2FA acepta cliente y persiste su sesión', () async {
    await requestCode();
    when(
      () => repository.verifyCode(email: 'cliente@example.com', code: '123456'),
    ).thenAnswer(
      (_) async => const AuthResult(
        token: 'synthetic-token',
        rol: 'usuario',
        nombre: 'Cliente CI',
      ),
    );
    expect(await vm.verifyCode(' 123456 '), isTrue);
    expect(vm.isCliente, isTrue);
    expect(SessionStorage.instance.token, 'synthetic-token');
    expect(vm.nombre, 'Cliente CI');
  });

  for (final role in ['admin', 'almacenista', 'gerente', 'desconocido']) {
    test('no permite persistir una sesión con rol $role', () async {
      await requestCode();
      when(
        () =>
            repository.verifyCode(email: 'cliente@example.com', code: '123456'),
      ).thenAnswer(
        (_) async => AuthResult(token: 'rejected', rol: role, nombre: 'CI'),
      );
      expect(await vm.verifyCode('123456'), isFalse);
      expect(vm.isAuthenticated, isFalse);
      expect(SessionStorage.instance.token, isNull);
    });
  }

  test('no verifica código sin completar el primer paso', () async {
    expect(await vm.verifyCode('123456'), isFalse);
    verifyNever(
      () => repository.verifyCode(
        email: any(named: 'email'),
        code: any(named: 'code'),
      ),
    );
  });
  test('propaga rechazo del servidor y permite reiniciar', () async {
    when(
      () => repository.requestLoginCode(
        email: 'cliente@example.com',
        password: 'incorrecta',
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/login'),
          statusCode: 401,
          data: <String, dynamic>{'error': 'Credenciales inválidas'},
        ),
      ),
    );
    expect(
      await vm.sendLoginCode(
        email: 'cliente@example.com',
        password: 'incorrecta',
      ),
      isFalse,
    );
    expect(vm.errorMessage, 'Credenciales inválidas');
    vm.resetState();
    expect(vm.status, AuthStatus.initial);
    expect(vm.errorMessage, isNull);
  });
  test('restauración elimina sesión de administrador', () async {
    await SessionStorage.instance.saveSession(
      token: 'synthetic',
      rol: 'admin',
      nombre: 'CI',
    );
    await vm.restoreSession();
    expect(vm.isAuthenticated, isFalse);
    expect(SessionStorage.instance.isLoggedIn, isFalse);
  });
}
