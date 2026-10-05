import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/catalog_repository.dart';
import '../../../../domain/models/producto.dart';
import '../view_models/product_detail_view_model.dart';

/// **View del detalle de producto** (vista invitado).
///
/// Recibe el `productoId` y obtiene los datos frescos con `getProductoById`.
class ProductDetailView extends StatelessWidget {
  const ProductDetailView({
    super.key,
    required this.productoId,
    this.productoInicial,
  });

  final String productoId;

  /// Datos que ya trae el catálogo: muestran la imagen al instante
  /// (habilita la transición Hero) y luego se refrescan con getProductoById.
  final Producto? productoInicial;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // El ViewModel queda acotado a esta ruta.
      create: (_) => ProductDetailViewModel(
        context.read<CatalogRepository>(),
      )..loadProduct(productoId),
      child: _ProductDetailBody(
        productoId: productoId,
        productoInicial: productoInicial,
      ),
    );
  }
}

class _ProductDetailBody extends StatelessWidget {
  const _ProductDetailBody({required this.productoId, this.productoInicial});

  final String productoId;
  final Producto? productoInicial;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductDetailViewModel>();
    final producto = vm.producto ?? productoInicial;

    return Scaffold(
      appBar: AppBar(title: Text(producto?.nombre ?? 'Detalle')),
      body: _contenido(context, vm),
      bottomNavigationBar: producto != null
          ? TweenAnimationBuilder<double>(
              // La barra de compra sube deslizándose con un ligero rebote.
              tween: Tween(begin: 1, end: 0),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutBack,
              builder: (context, valor, child) => Transform.translate(
                offset: Offset(0, 56 * valor),
                child: child,
              ),
              child: _BarraCompra(producto: producto),
            )
          : null,
    );
  }

  Widget _contenido(BuildContext context, ProductDetailViewModel vm) {
    switch (vm.status) {
      case ProductDetailStatus.initial:
      case ProductDetailStatus.loading:
        final inicial = productoInicial;
        if (inicial != null) {
          // Mostrar al instante lo que trae el catálogo (con Hero).
          return _Detalle(producto: inicial);
        }
        return const Center(child: CircularProgressIndicator());
      case ProductDetailStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  vm.errorMessage ?? 'Error al cargar el producto',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    context.read<ProductDetailViewModel>().loadProduct(productoId),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
      case ProductDetailStatus.loaded:
        return _Detalle(producto: vm.producto!);
    }
  }
}

/// Sección del detalle con entrada escalonada (fade + desliz hacia arriba).
class _SeccionAnimada extends StatelessWidget {
  const _SeccionAnimada({
    required this.controller,
    required this.inicio,
    required this.fin,
    required this.child,
  });

  final AnimationController controller;
  final double inicio;
  final double fin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(
          Interval(inicio, fin).transform(controller.value),
        );
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - t)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _Detalle extends StatefulWidget {
  const _Detalle({required this.producto});

  final Producto producto;

  @override
  State<_Detalle> createState() => _DetalleState();
}

class _DetalleState extends State<_Detalle> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Entrada escalonada: imagen -> precios -> descripción.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final producto = widget.producto;
    final tieneOferta = producto.ofertaAplicada != null;
    final precio = producto.precioFinal ?? producto.precioNormal ?? 0;
    final hayChips = producto.marca != null || producto.familia != null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen: entrada con fade + transición Hero desde la grilla.
          _SeccionAnimada(
            controller: _controller,
            inicio: 0.0,
            fin: 0.5,
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: _imagenConHero(producto),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hayChips)
                  _SeccionAnimada(
                    controller: _controller,
                    inicio: 0.15,
                    fin: 0.7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (producto.marca != null &&
                                producto.marca!.nombre.isNotEmpty)
                              Chip(
                                label: Text(producto.marca!.nombre),
                                avatar: const Icon(Icons.business, size: 18),
                              ),
                            if (producto.familia != null &&
                                producto.familia!.nombre.isNotEmpty)
                              Chip(label: Text(producto.familia!.nombre)),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                _SeccionAnimada(
                  controller: _controller,
                  inicio: 0.2,
                  fin: 0.8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.nombre,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      if (tieneOferta) ...[
                        Row(
                          children: [
                            Text(
                              '\$${(producto.precioNormal ?? 0).toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'OFERTA ${producto.ofertaAplicada!.nombre}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '\$${precio.toStringAsFixed(2)}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else
                        Text(
                          '\$${precio.toStringAsFixed(2)}',
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      const SizedBox(height: 12),
                      if (producto.precioMayoreo != null)
                        _fila(
                          'Precio mayoreo',
                          '\$${producto.precioMayoreo!.toStringAsFixed(2)}',
                        ),
                      if (producto.precioCaja != null)
                        _fila(
                          'Precio por caja',
                          '\$${producto.precioCaja!.toStringAsFixed(2)}',
                        ),
                      if (producto.skuNormal != null &&
                          producto.skuNormal!.isNotEmpty)
                        _fila('SKU', producto.skuNormal!),
                      _fila(
                        'Stock',
                        producto.stock > 0
                            ? '${producto.stock} disponibles'
                            : 'Agotado',
                      ),
                      const Divider(height: 32),
                    ],
                  ),
                ),
                _SeccionAnimada(
                  controller: _controller,
                  inicio: 0.45,
                  fin: 1.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Descripción', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        producto.descripcion ?? 'Sin descripción disponible.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagenConHero(Producto producto) {
    final imagen = (producto.imagenUrl != null &&
            producto.imagenUrl!.isNotEmpty)
        ? Image.network(
            producto.imagenUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _placeholder(),
          )
        : _placeholder();
    final id = producto.id;
    return id != null ? Hero(tag: 'producto-$id', child: imagen) : imagen;
  }

  Widget _fila(String etiqueta, String valor) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(etiqueta, style: const TextStyle(color: Colors.grey)),
            Text(
              valor,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );

  Widget _placeholder() => Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.inventory_2, size: 64),
      );
}

class _BarraCompra extends StatelessWidget {
  const _BarraCompra({required this.producto});

  final Producto producto;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FilledButton.icon(
          onPressed: () {
            // TODO(fase cliente): agregar al carrito (CartViewModel).
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'El carrito estará disponible en la fase de cliente.',
                ),
              ),
            );
          },
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Agregar al carrito'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ),
    );
  }
}
