import 'package:flutter_test/flutter_test.dart';
import 'package:panamericana_flutter/ui/shared/form_validators.dart';

void main() {
  test('campos obligatorios respetan límites y espacios', () {
    expect(FormValidators.requiredText(null, 'Nombre'), isNotNull);
    expect(FormValidators.requiredText('  ', 'Nombre'), isNotNull);
    expect(FormValidators.requiredText('a', 'Nombre', min: 2), isNotNull);
    expect(FormValidators.requiredText('abcd', 'Nombre', max: 3), isNotNull);
    expect(
      FormValidators.requiredText(' Ana ', 'Nombre', min: 3, max: 3),
      isNull,
    );
  });
  test('nombres permiten acentos pero rechazan dígitos y símbolos', () {
    expect(FormValidators.requiredLetters('María José', 'Nombre'), isNull);
    expect(FormValidators.requiredLetters('', 'Nombre'), isNotNull);
    expect(FormValidators.requiredLetters('Ana123', 'Nombre'), isNotNull);
    expect(FormValidators.optionalLetters('', 'Nombre'), isNull);
    expect(FormValidators.optionalLetters('Ana', 'Nombre'), isNull);
    expect(FormValidators.optionalLetters('<script>', 'Nombre'), isNotNull);
  });
  test('correo y datos numéricos rechazan formatos inválidos', () {
    for (final value in [null, '', 'ana', 'ana@', 'a b@example.com']) {
      expect(FormValidators.requiredEmail(value), isNotNull);
    }
    expect(FormValidators.requiredEmail('ana@example.com'), isNull);
    for (final value in [null, '', '123a', '123']) {
      expect(FormValidators.requiredPhone(value), isNotNull);
    }
    expect(FormValidators.requiredPhone('2221234567'), isNull);
    expect(FormValidators.requiredPostalCode('72000'), isNull);
    expect(FormValidators.requiredPostalCode('7200'), isNotNull);
  });
  test('direcciones validan contenido y longitud', () {
    expect(FormValidators.requiredAddressText('Calle 3 #12', 'Calle'), isNull);
    expect(FormValidators.requiredAddressText('', 'Calle'), isNotNull);
    expect(FormValidators.requiredAddressText('<script>', 'Calle'), isNotNull);
    expect(FormValidators.optionalAddressText('', 'Referencia'), isNull);
    expect(
      FormValidators.optionalAddressText('Casa azul', 'Referencia'),
      isNull,
    );
    expect(
      FormValidators.optionalAddressText('a' * 121, 'Referencia'),
      isNotNull,
    );
    expect(
      FormValidators.optionalAddressText('<script>', 'Referencia'),
      isNotNull,
    );
  });
}
