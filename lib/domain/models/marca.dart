/// Modelo de dominio de la **Marca** (catálogo).
class Marca {
  const Marca({this.id, required this.nombre, this.descripcion});

  final String? id;
  final String nombre;
  final String? descripcion;

  factory Marca.fromJson(Map<String, dynamic> json) {
    return Marca(
      id: json['_id'] as String?,
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
    };
  }
}
