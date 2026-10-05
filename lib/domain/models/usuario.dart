import 'direccion.dart';

/// Modelo de dominio del **Usuario**.
///
/// El backend devuelve `rol` como string: `"usuario"` | `"admin"`.
/// El mapeo a la petición numérica (0 invitado / 1 cliente / 2 admin)
/// se hace en el AuthViewModel.
class Usuario {
  const Usuario({
    this.id,
    required this.nombre,
    this.ap,
    this.am,
    this.fechaNacimiento,
    this.email,
    this.telefono,
    this.rol = 'usuario',
    this.direcciones = const [],
  });

  final String? id;
  final String nombre;
  final String? ap;
  final String? am;
  final DateTime? fechaNacimiento;
  final String? email;
  final String? telefono;
  final String rol;
  final List<Direccion> direcciones;

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['_id'] as String?,
      nombre: json['nombre'] as String? ?? '',
      ap: json['ap'] as String?,
      am: json['am'] as String?,
      fechaNacimiento: json['fechaNacimiento'] != null
          ? DateTime.tryParse(json['fechaNacimiento'].toString())
          : null,
      email: json['email'] as String?,
      telefono: json['telefono'] as String?,
      rol: json['rol'] as String? ?? 'usuario',
      direcciones: (json['direcciones'] as List<dynamic>? ?? const [])
          .map((e) => Direccion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'nombre': nombre,
      if (ap != null) 'ap': ap,
      if (am != null) 'am': am,
      if (fechaNacimiento != null)
        'fechaNacimiento': fechaNacimiento!.toIso8601String(),
      if (email != null) 'email': email,
      if (telefono != null) 'telefono': telefono,
      'rol': rol,
      'direcciones': direcciones.map((d) => d.toJson()).toList(),
    };
  }
}
