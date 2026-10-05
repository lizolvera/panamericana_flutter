/// Modelo de dominio del **Carrusel** (banners del catálogo).
class Carrusel {
  const Carrusel({
    this.id,
    this.titulo,
    required this.imagenUrl,
    this.enlaceDestino,
    this.orden = 0,
    this.activo = true,
  });

  final String? id;
  final String? titulo;
  final String imagenUrl;
  final String? enlaceDestino;
  final int orden;
  final bool activo;

  factory Carrusel.fromJson(Map<String, dynamic> json) {
    return Carrusel(
      id: json['_id'] as String?,
      titulo: json['titulo'] as String?,
      imagenUrl: json['imagenUrl'] as String? ?? '',
      enlaceDestino: json['enlaceDestino'] as String?,
      orden: json['orden'] as int? ?? 0,
      activo: json['activo'] as bool? ?? true,
    );
  }
}
