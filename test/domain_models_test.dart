import 'package:flutter_test/flutter_test.dart';
import 'package:panamericana_flutter/domain/models/usuario.dart';
import 'package:panamericana_flutter/domain/models/producto.dart';
import 'package:panamericana_flutter/domain/models/oferta.dart';
import 'package:panamericana_flutter/domain/models/marca.dart';
import 'package:panamericana_flutter/domain/models/familia.dart';
import 'package:panamericana_flutter/domain/models/carrusel.dart';

void main() {
  test(
    'usuario conserva datos opcionales y convierte fechas inválidas sin fallar',
    () {
      final json = {
        '_id': 'u1',
        'nombre': 'Ana',
        'ap': 'Uno',
        'am': 'Dos',
        'email': 'a@example.test',
        'telefono': '2221234567',
        'fechaNacimiento': '2000-02-03',
        'rol': 'usuario',
        'preguntaSecreta': 'p',
        'direcciones': <dynamic>[],
      };
      final u = Usuario.fromJson(json);
      expect(u.id, 'u1');
      expect(u.fechaNacimiento!.year, 2000);
      expect(u.preguntaSecreta, 'p');
      expect(u.toJson()['am'], 'Dos');
      expect(
        Usuario.fromJson({'fechaNacimiento': 'invalida'}).fechaNacimiento,
        isNull,
      );
      expect(Usuario.fromJson({}).rol, 'usuario');
      expect(const Usuario(nombre: 'Ana').toJson().containsKey('_id'), isFalse);
    },
  );
  test(
    'ofertas aceptan IDs simples o poblados y precios de texto o número',
    () {
      final o = Oferta.fromJson({
        '_id': 'o',
        'nombre': 'Oferta',
        'descripcion': 'Temporal',
        'tipoDescuento': 'monto_fijo',
        'valorDescuento': '12.50',
        'productos': [
          'p1',
          {'_id': 'p2'},
        ],
        'marcas': [
          {'_id': 'm1'},
        ],
        'fechaInicio': '2026-01-01',
        'fechaFin': '2026-12-31',
        'activo': false,
      });
      expect(o.valorDescuento, 12.5);
      expect(o.productos, ['p1', 'p2']);
      expect(o.marcas, ['m1']);
      expect(o.fechaFin!.year, 2026);
      expect(o.activo, isFalse);
      expect(Oferta.fromJson({'valorDescuento': 10}).valorDescuento, 10);
      expect(Oferta.fromJson({}).productos, isEmpty);
      expect(
        Oferta.fromJson({'valorDescuento': 'incorrecto'}).valorDescuento,
        0,
      );
      expect(OfertaAplicada.fromJson({}).valorDescuento, 0);
    },
  );
  test('producto serializa oferta y relaciones sin perder precios ni SKUs', () {
    final json = {
      '_id': 'p',
      'nombre': 'Champú',
      'descripcion': 'Prueba',
      'precioNormal': '100',
      'precioMayoreo': 80,
      'precioCaja': 900,
      'stock': 10,
      'skuNormal': 'S',
      'skuMayoreo': 'M',
      'skuCaja': 'C',
      'marca': {'_id': 'm', 'nombre': 'Marca'},
      'familia': {'_id': 'f', 'nombre': 'Familia', 'marca': 'm'},
      'imagenUrl': 'https://example.test/p.png',
      'precioNormalFinal': 90,
      'precioMayoreoFinal': 70,
      'precioCajaFinal': 800,
      'precioFinal': 90,
      'ofertaAplicada': {
        'nombre': 'Oferta',
        'tipoDescuento': 'porcentaje',
        'valorDescuento': 10,
      },
    };
    final p = Producto.fromJson(json);
    final copy = Producto.fromJson(p.toJson());
    expect(copy.precioNormal, 100);
    expect(copy.ofertaAplicada!.valorDescuento, 10);
    expect(copy.familia!.marca!.id, 'm');
    expect(copy.skuCaja, 'C');
    expect(copy.precioCajaFinal, 800);
    final ids = Producto.fromJson({
      'marca': 'm',
      'familia': 'f',
      'precioNormal': 'inválido',
    });
    expect(ids.marca!.id, 'm');
    expect(ids.familia!.id, 'f');
    expect(ids.precioNormal, isNull);
  });
  test('marca familia y carrusel admiten respuestas mínimas y completas', () {
    final m = Marca.fromJson({
      '_id': 'm',
      'nombre': 'Marca',
      'descripcion': 'Texto',
    });
    expect(m.toJson()['descripcion'], 'Texto');
    expect(const Marca(nombre: 'M').toJson().containsKey('_id'), isFalse);
    final f = Familia.fromJson({
      '_id': 'f',
      'nombre': 'Familia',
      'descripcion': 'Texto',
      'marca': m.toJson(),
    });
    expect(f.toJson()['marca']['_id'], 'm');
    expect(Familia.fromJson({}).marca, isNull);
    expect(const Familia(nombre: 'F').toJson(), {'nombre': 'F'});
    final c = Carrusel.fromJson({
      '_id': 'b',
      'titulo': 'Banner',
      'imagenUrl': 'https://example.test/banner.png',
      'enlaceDestino': '/catalogo',
      'orden': 2,
      'activo': false,
    });
    expect(c.orden, 2);
    expect(c.enlaceDestino, '/catalogo');
    expect(Carrusel.fromJson({}).imagenUrl, '');
  });
}
