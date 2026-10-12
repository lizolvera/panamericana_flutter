import 'package:flutter/services.dart';

class FormValidators {
  FormValidators._();

  static final RegExp _emailRegex = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );
  static final RegExp _lettersRegex = RegExp(r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ' -]+$");
  static final RegExp _addressRegex = RegExp(
    r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9#.,'°º /-]+$",
  );
  static final RegExp _passwordRegex = RegExp(
    r'^(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z0-9]).{12,}$',
  );

  static final TextInputFormatter lettersOnlyFormatter =
      FilteringTextInputFormatter.allow(RegExp(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ' -]"));
  static final TextInputFormatter addressFormatter =
      FilteringTextInputFormatter.allow(
        RegExp(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9#.,'°º /-]"),
      );
  static final TextInputFormatter digitsOnlyFormatter =
      FilteringTextInputFormatter.digitsOnly;
  static final TextInputFormatter noSpacesFormatter =
      FilteringTextInputFormatter.deny(RegExp(r'\s'));

  static String? requiredText(
    String? value,
    String field, {
    int min = 1,
    int max = 80,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$field es obligatorio';
    if (text.length < min) return '$field debe tener al menos $min caracteres';
    if (text.length > max) return '$field no debe exceder $max caracteres';
    return null;
  }

  static String? optionalLetters(String? value, String field) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    return requiredLetters(text, field);
  }

  static String? requiredLetters(String? value, String field) {
    final base = requiredText(value, field, min: 2, max: 60);
    if (base != null) return base;
    final text = value!.trim();
    if (!_lettersRegex.hasMatch(text)) {
      return '$field solo debe contener letras';
    }
    return null;
  }

  static String? requiredEmail(String? value) {
    final base = requiredText(value, 'El correo', max: 120);
    if (base != null) return base;
    if (!_emailRegex.hasMatch(value!.trim())) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  static String? requiredPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Ingresa una contraseña';
    if (!_passwordRegex.hasMatch(password)) {
      return 'Mínimo 12 caracteres, una mayúscula, un número y un símbolo';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirma la contraseña';
    if (value != password) return 'Las contraseñas no coinciden';
    return null;
  }

  static String? requiredSecretAnswer(String? value) {
    final base = requiredText(value, 'La respuesta', min: 2, max: 60);
    if (base != null) return base;
    if (value!.trim().contains(RegExp(r'\s{2,}'))) {
      return 'La respuesta no debe tener espacios dobles';
    }
    return null;
  }

  static String? requiredDigits(
    String? value,
    String field, {
    required int length,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$field es obligatorio';
    if (!RegExp(r'^\d+$').hasMatch(text)) {
      return '$field solo debe contener números';
    }
    if (text.length != length) {
      return '$field debe tener $length dígitos';
    }
    return null;
  }

  static String? requiredPhone(String? value) {
    return requiredDigits(value, 'El teléfono', length: 10);
  }

  static String? requiredPostalCode(String? value) {
    return requiredDigits(value, 'El código postal', length: 5);
  }

  static String? requiredAddressText(String? value, String field) {
    final base = requiredText(value, field, min: 2, max: 100);
    if (base != null) return base;
    if (!_addressRegex.hasMatch(value!.trim())) {
      return '$field contiene caracteres no válidos';
    }
    return null;
  }

  static String? optionalAddressText(String? value, String field) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (text.length > 120) return '$field no debe exceder 120 caracteres';
    if (!_addressRegex.hasMatch(text)) {
      return '$field contiene caracteres no válidos';
    }
    return null;
  }
}
