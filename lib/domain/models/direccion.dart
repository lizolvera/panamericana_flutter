/// Modelo de dominio de una **dirección de envío**.
///
/// Implementa el patrón **Adapter**: `fromJson` (API → modelo)
/// y `toJson` (modelo → API).
class Direccion {
  const Direccion({
    this.id,
    required this.alias,
    required this.calle,
    this.colonia,
    required this.ciudad,
    required this.estado,
    required this.cp,
    required this.telefono,
    this.referencias,
    this.predeterminada = false,
  });

  final String? id;
  final String alias;
  final String calle;
  final String? colonia;
  final String ciudad;
  final String estado;
  final String cp;
  final String telefono;
  final String? referencias;
  final bool predeterminada;

  factory Direccion.fromJson(Map<String, dynamic> json) {
    return Direccion(
      id: json['_id'] as String?,
      alias: json['alias'] as String? ?? '',
      calle: json['calle'] as String? ?? '',
      colonia: json['colonia'] as String?,
      ciudad: json['ciudad'] as String? ?? '',
      estado: json['estado'] as String? ?? '',
      cp: json['cp'] as String? ?? '',
      telefono: json['telefono'] as String? ?? '',
      referencias: json['referencias'] as String?,
      predeterminada: json['predeterminada'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'alias': alias,
      'calle': calle,
      if (colonia != null) 'colonia': colonia,
      'ciudad': ciudad,
      'estado': estado,
      'cp': cp,
      'telefono': telefono,
      if (referencias != null) 'referencias': referencias,
      'predeterminada': predeterminada,
    };
  }
}
