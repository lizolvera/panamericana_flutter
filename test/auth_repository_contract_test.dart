import 'package:flutter_test/flutter_test.dart';

import 'support/fixture_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FixtureApi f;
  setUp(() async {
    f = FixtureApi();
    await f.init();
  });
  tearDown(() async => f.dispose());
  test(
    'login y Google envían credenciales al endpoint correcto y leen sesión',
    () async {
      await f.authRepo.requestLoginCode(
        email: 'ana@example.test',
        password: 'Prueba2026!',
      );
      expect(f.requests.last.path, '/api/usuarios/login');
      expect(f.requests.last.data, {
        'email': 'ana@example.test',
        'password': 'Prueba2026!',
      });
      final result = await f.authRepo.verifyCode(
        email: 'ana@example.test',
        code: '123456',
      );
      expect(result.rol, 'usuario');
      expect(result.token, 'test-session');
      expect(result.nombre, 'Ana');
      await f.authRepo.loginWithGoogle('google-test');
      expect(f.requests.last.data, {'idToken': 'google-test'});
    },
  );
  test('registro disponibilidad y recuperación respetan el contrato sin llamadas reales', () async {
    await f.authRepo.register({'nombre': 'Ana', 'email': 'ana@example.test'});
    expect(f.requests.last.path, '/api/usuarios/register');
    expect(await f.authRepo.checkEmail('ana@example.test'), isTrue);
    expect(f.requests.last.data, {'email': 'ana@example.test'});
    f.overrides['/api/usuarios/check-phone'] = {'available': false};
    expect(await f.authRepo.checkPhone('2221234567'), isFalse);
    await f.authRepo.verificarCorreo('ana@example.test');
    expect(f.requests.last.path, '/api/usuarios/verificar-correo');
    expect(
      await f.authRepo.obtenerPregunta('ana@example.test'),
      contains('personaje'),
    );
    await f.authRepo.verificarRespuesta('ana@example.test', 'Ana');
    expect(f.requests.last.data, {
      'email': 'ana@example.test',
      'respuesta': 'Ana',
    });
    await f.authRepo.cambiarContrasenaRecuperacion(
      'ana@example.test',
      'OtraClave2026!',
    );
    expect(f.requests.last.data, {
      'email': 'ana@example.test',
      'nuevaPassword': 'OtraClave2026!',
    });
  });
  test('rechazos de la API no se convierten en operaciones exitosas', () async {
    f.failures['/api/usuarios/register'] = 'Correo ya registrado';
    expect(
      f.authRepo.register({'email': 'ana@example.test'}),
      throwsA(isA<Exception>()),
    );
  });
}
