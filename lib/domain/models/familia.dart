import 'marca.dart';

/// Modelo de dominio de la **Familia** (subcategoría dentro de una marca).
class Familia {
  const Familia({
    this.id,
    required this.nombre,
    this.descripcion,
    this.marca,
  });

  final String? id;
  final String nombre;
  final String? descripcion;

  /// Viene poblada como `{_id, nombre}` desde la API.
  final Marca? marca;

  factory Familia.fromJson(Map<String, dynamic> json) {
    final marcaJson = json['marca'];
    return Familia(
      id: json['_id'] as String?,
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      marca: marcaJson is Map<String, dynamic>
          ? Marca.fromJson(marcaJson)
          : marcaJson != null
              ? Marca(id: marcaJson.toString(), nombre: '')
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
      if (marca != null) 'marca': marca!.toJson(),
    };
  }
}
