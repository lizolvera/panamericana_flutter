import 'familia.dart';
import 'marca.dart';
import 'oferta.dart';

/// Modelo de dominio del **Producto** (catálogo).
///
/// La API de `/api/productos` popula `marca` y `familia` como objetos
/// `{_id, nombre}` y agrega los campos de oferta (`precioFinal`,
/// `precioNormalFinal`, `ofertaAplicada`) cuando hay un descuento vigente.
class Producto {
  const Producto({
    this.id,
    required this.nombre,
    this.descripcion,
    this.precioNormal,
    this.skuNormal,
    this.precioMayoreo,
    this.skuMayoreo,
    this.precioCaja,
    this.skuCaja,
    this.stock = 0,
    this.marca,
    this.familia,
    this.activo = true,
    this.imagenUrl,
    this.precioNormalFinal,
    this.precioMayoreoFinal,
    this.precioCajaFinal,
    this.precioFinal,
    this.ofertaAplicada,
  });

  final String? id;
  final String nombre;
  final String? descripcion;
  final double? precioNormal;
  final String? skuNormal;
  final double? precioMayoreo;
  final String? skuMayoreo;
  final double? precioCaja;
  final String? skuCaja;
  final int stock;

  /// Viene poblado como `{_id, nombre}` desde la API (o solo id si no).
  final Marca? marca;
  final Familia? familia;

  final bool activo;
  final String? imagenUrl;

  // --- Campos agregados por el backend al aplicar ofertas ---
  final double? precioNormalFinal;
  final double? precioMayoreoFinal;
  final double? precioCajaFinal;
  final double? precioFinal;
  final OfertaAplicada? ofertaAplicada;

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['_id'] as String?,
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      precioNormal: _toDouble(json['precioNormal']),
      skuNormal: json['skuNormal'] as String?,
      precioMayoreo: _toDouble(json['precioMayoreo']),
      skuMayoreo: json['skuMayoreo'] as String?,
      precioCaja: _toDouble(json['precioCaja']),
      skuCaja: json['skuCaja'] as String?,
      stock: json['stock'] as int? ?? 0,
      marca: _parseMarca(json['marca']),
      familia: _parseFamilia(json['familia']),
      activo: json['activo'] as bool? ?? true,
      imagenUrl: json['imagenUrl'] as String?,
      precioNormalFinal: _toDouble(json['precioNormalFinal']),
      precioMayoreoFinal: _toDouble(json['precioMayoreoFinal']),
      precioCajaFinal: _toDouble(json['precioCajaFinal']),
      precioFinal: _toDouble(json['precioFinal']),
      ofertaAplicada: json['ofertaAplicada'] != null
          ? OfertaAplicada.fromJson(json['ofertaAplicada'] as Map<String, dynamic>)
          : null,
    );
  }

  static Marca? _parseMarca(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return Marca.fromJson(value);
    return Marca(id: value.toString(), nombre: '');
  }

  static Familia? _parseFamilia(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return Familia.fromJson(value);
    return Familia(id: value.toString(), nombre: '');
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
      if (precioNormal != null) 'precioNormal': precioNormal,
      if (skuNormal != null) 'skuNormal': skuNormal,
      if (precioMayoreo != null) 'precioMayoreo': precioMayoreo,
      if (skuMayoreo != null) 'skuMayoreo': skuMayoreo,
      if (precioCaja != null) 'precioCaja': precioCaja,
      if (skuCaja != null) 'skuCaja': skuCaja,
      'stock': stock,
      if (marca != null) 'marca': marca!.toJson(),
      if (familia != null) 'familia': familia!.toJson(),
      'activo': activo,
      if (imagenUrl != null) 'imagenUrl': imagenUrl,
      if (precioNormalFinal != null) 'precioNormalFinal': precioNormalFinal,
      if (precioMayoreoFinal != null) 'precioMayoreoFinal': precioMayoreoFinal,
      if (precioCajaFinal != null) 'precioCajaFinal': precioCajaFinal,
      if (precioFinal != null) 'precioFinal': precioFinal,
      if (ofertaAplicada != null)
        'ofertaAplicada': {
          'nombre': ofertaAplicada!.nombre,
          'tipoDescuento': ofertaAplicada!.tipoDescuento,
          'valorDescuento': ofertaAplicada!.valorDescuento,
        },
    };
  }
}
