/// Modelo de dominio de la **Oferta** del catálogo.
class Oferta {
  const Oferta({
    this.id,
    required this.nombre,
    this.descripcion,
    required this.tipoDescuento,
    required this.valorDescuento,
    this.productos = const [],
    this.marcas = const [],
    this.fechaInicio,
    this.fechaFin,
    this.activo = true,
  });

  final String? id;
  final String nombre;
  final String? descripcion;

  /// 'porcentaje' | 'monto_fijo'
  final String tipoDescuento;
  final double valorDescuento;

  /// IDs de productos/marcas afectados (la API los popula con {_id, nombre}).
  final List<String> productos;
  final List<String> marcas;

  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final bool activo;

  factory Oferta.fromJson(Map<String, dynamic> json) {
    return Oferta(
      id: json['_id'] as String?,
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      tipoDescuento: json['tipoDescuento'] as String? ?? 'porcentaje',
      valorDescuento: _toDouble(json['valorDescuento']) ?? 0,
      productos: _idsDe(json['productos']),
      marcas: _idsDe(json['marcas']),
      fechaInicio: json['fechaInicio'] != null
          ? DateTime.tryParse(json['fechaInicio'].toString())
          : null,
      fechaFin: json['fechaFin'] != null
          ? DateTime.tryParse(json['fechaFin'].toString())
          : null,
      activo: json['activo'] as bool? ?? true,
    );
  }

  /// Convierte arrays poblados `[{_id, nombre}]` o simples `[id]` a `List<String>`.
  static List<String> _idsDe(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((e) => e is Map<String, dynamic> ? (e['_id'] ?? '').toString() : e.toString())
        .toList();
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

/// Oferta **ya aplicada** dentro de un producto (respuesta de /api/productos).
class OfertaAplicada {
  const OfertaAplicada({
    required this.nombre,
    required this.tipoDescuento,
    required this.valorDescuento,
  });

  final String nombre;
  final String tipoDescuento;
  final double valorDescuento;

  factory OfertaAplicada.fromJson(Map<String, dynamic> json) {
    return OfertaAplicada(
      nombre: json['nombre'] as String? ?? '',
      tipoDescuento: json['tipoDescuento'] as String? ?? 'porcentaje',
      valorDescuento: (json['valorDescuento'] as num?)?.toDouble() ?? 0,
    );
  }
}
