import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/carrusel.dart';
import '../../../../domain/models/familia.dart';
import '../../../../domain/models/marca.dart';
import '../../../../domain/models/producto.dart';
import '../view_models/catalog_view_model.dart';
import 'product_detail_view.dart';

/// **View del catálogo** (vista invitado, rediseño):
/// buscador → carrusel de banners → productos destacados (con oferta)
/// → todos los productos (grid 2 columnas).
class CatalogView extends StatefulWidget {
  const CatalogView({super.key});

  @override
  State<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<CatalogView> {
  @override
  void initState() {
    super.initState();
    // Carga inicial después del primer frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<CatalogViewModel>();
      if (vm.status == CatalogStatus.initial) {
        vm.loadCatalog();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CatalogViewModel>();

    return Column(
      children: [
        // Buscador FIJO en la parte superior: no se desplaza con el contenido.
        Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: vm.setBusqueda,
              decoration: InputDecoration(
                hintText: 'Buscar producto…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
        // Chips de marca/familia fijos (se desplazan solo en horizontal).
        if (vm.marcas.isNotEmpty)
          _FiltrosMarcas(
            marcas: vm.marcas,
            seleccionada: vm.marcaFiltro,
            onSeleccion: vm.setMarca,
          ),
        if (vm.familiasVisibles.isNotEmpty)
          _FiltrosFamilias(
            familias: vm.familiasVisibles,
            seleccionada: vm.familiaFiltro,
            onSeleccion: vm.setFamilia,
          ),
        Expanded(child: _contenido(vm)),
      ],
    );
  }

  Widget _contenido(CatalogViewModel vm) {
    switch (vm.status) {
      case CatalogStatus.loading:
        return const _GrillaSkeleton();
      case CatalogStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  vm.errorMessage ?? 'Error al cargar el catálogo',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: vm.loadCatalog,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
      case CatalogStatus.initial:
      case CatalogStatus.loaded:
        return _CatalogoCargado(vm: vm);
    }
  }
}

/// Contenido principal una vez cargado: carrusel + destacados + grilla.
class _CatalogoCargado extends StatelessWidget {
  const _CatalogoCargado({required this.vm});

  final CatalogViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        if (vm.carruseles.isNotEmpty) _Carrusel(carruseles: vm.carruseles),
        if (vm.productosDestacados.isNotEmpty) ...[
          const _SeccionTitulo('Productos Destacados'),
          _Destacados(productos: vm.productosDestacados),
        ],
        const _SeccionTitulo('Todos los productos'),
        if (vm.totalFiltrados == 0)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('No hay productos que coincidan')),
          )
        else ...[
          _GridConTransicion(vm: vm),
          const SizedBox(height: 8),
          _Paginacion(vm: vm),
        ],
      ],
    );
  }
}

class _SeccionTitulo extends StatelessWidget {
  const _SeccionTitulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        texto,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _Carrusel extends StatefulWidget {
  const _Carrusel({required this.carruseles});

  final List<Carrusel> carruseles;

  @override
  State<_Carrusel> createState() => _CarruselState();
}

class _CarruselState extends State<_Carrusel> {
  late final PageController _controller;
  Timer? _timer;
  int _pagina = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.92);
    _iniciarAutoplay();
  }

  /// Desliza automáticamente cada 4 segundos con animación suave.
  void _iniciarAutoplay() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || widget.carruseles.length <= 1) return;
      final siguiente = (_pagina + 1) % widget.carruseles.length;
      _controller.animateToPage(
        siguiente,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.carruseles.length,
            onPageChanged: (i) => setState(() => _pagina = i),
            itemBuilder: (context, i) => _BannerCarrusel(
              carrusel: widget.carruseles[i],
              controller: _controller,
              indice: i,
            ),
          ),
        ),
        // Indicadores animados (se expande el de la página activa).
        if (widget.carruseles.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.carruseles.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _pagina ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _pagina
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Un banner del carrusel con escala suave: se agranda al centro y
/// se encoge ligeramente en los lados mientras se desliza.
class _BannerCarrusel extends StatelessWidget {
  const _BannerCarrusel({
    required this.carrusel,
    required this.controller,
    required this.indice,
  });

  final Carrusel carrusel;
  final PageController controller;
  final int indice;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final pagina = controller.hasClients
            ? (controller.page ?? 0)
            : controller.initialPage.toDouble();
        final distancia = (pagina - indice).abs().clamp(0.0, 1.0);
        final escala = 0.94 + 0.06 * (1 - distancia);
        return Transform.scale(scale: escala, child: child);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                carrusel.imagenUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _placeholderImagen(icon: Icons.image, size: 48),
              ),
              if (carrusel.titulo != null && carrusel.titulo!.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.black45,
                    child: Text(
                      carrusel.titulo!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
class _Destacados extends StatefulWidget {
  const _Destacados({required this.productos});

  final List<Producto> productos;

  @override
  State<_Destacados> createState() => _DestacadosState();
}

class _DestacadosState extends State<_Destacados>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Entrada escalonada: las tarjetas se deslizan con fade una tras otra.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 270,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.productos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          // Retraso escalonado por tarjeta (0, 0.1, 0.2, ...).
          final inicio = (i * 0.1).clamp(0.0, 0.5);
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = Curves.easeOutCubic.transform(
                Interval(inicio, 1.0).transform(_controller.value),
              );
              return Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(50 * (1 - t), 0),
                  child: child,
                ),
              );
            },
            child: _TarjetaDestacado(producto: widget.productos[i]),
          );
        },
      ),
    );
  }
}
class _TarjetaDestacado extends StatelessWidget {
  const _TarjetaDestacado({required this.producto});

  final Producto producto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final precio = producto.precioFinal ?? producto.precioNormal ?? 0;

    return SizedBox(
      width: 190,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _abrirDetalle(context, producto),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: (producto.imagenUrl != null &&
                        producto.imagenUrl!.isNotEmpty)
                    ? Image.network(
                        producto.imagenUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, _, _) => _placeholderImagen(),
                      )
                    : _placeholderImagen(),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (producto.marca != null &&
                        producto.marca!.nombre.isNotEmpty)
                      Text(
                        producto.marca!.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: Colors.grey),
                      ),
                    Text(
                      producto.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${precio.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Esqueleto de carga con pulso suave (shimmer simple, sin dependencias).
class _GrillaSkeleton extends StatefulWidget {
  const _GrillaSkeleton();

  @override
  State<_GrillaSkeleton> createState() => _GrillaSkeletonState();
}

class _GrillaSkeletonState extends State<_GrillaSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 0.9).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: 6,
        itemBuilder: (context, i) => Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(color: Colors.grey.shade300),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 10,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Contador + botón "Ver más" para el límite de visualización.
/// Paginación numérica: Anterior / números / Siguiente.
/// Envuelve la grilla con una transición suave al cambiar de página:
/// la página nueva entra deslizándose según la dirección (adelante/atrás)
/// con fundido, mientras la anterior sale.
class _GridConTransicion extends StatefulWidget {
  const _GridConTransicion({required this.vm});

  final CatalogViewModel vm;

  @override
  State<_GridConTransicion> createState() => _GridConTransicionState();
}

class _GridConTransicionState extends State<_GridConTransicion> {
  int _paginaPrevia = 1;

  @override
  Widget build(BuildContext context) {
    final actual = widget.vm.paginaActual;
    final haciaAdelante = actual > _paginaPrevia;
    _paginaPrevia = actual;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final desplazamiento = Tween<Offset>(
          begin: Offset(haciaAdelante ? 0.08 : -0.08, 0),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: desplazamiento,
            child: child,
          ),
        );
      },
      child: _Grilla(
        key: ValueKey('pagina-$actual'),
        productos: widget.vm.productosVisibles,
      ),
    );
  }
}

/// Paginación numérica: Anterior / números / Siguiente.
/// La página actual se resalta con un botón sólido que hace "pop" al
/// entrar, y el contador se anima al cambiar de página.
class _Paginacion extends StatelessWidget {
  const _Paginacion({required this.vm});

  final CatalogViewModel vm;

  @override
  Widget build(BuildContext context) {
    final total = vm.totalPaginas;
    final actual = vm.paginaActual;

    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.25),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Text(
            'Página $actual de $total · ${vm.totalFiltrados} productos',
            key: ValueKey('contador-$actual-$total'),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
          ),
        ),
        const SizedBox(height: 6),
        // Fila compacta que cabe en pantalla sin scroll horizontal.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _BotonAnterior(vm: vm),
            const SizedBox(width: 2),
            ..._paginas(context, vm),
            const SizedBox(width: 2),
            _BotonSiguiente(vm: vm),
          ],
        ),
      ],
    );
  }

  /// Números de página compactos: hasta 5 se muestran todos; si hay más,
  /// una ventana deslizante de 5 alrededor de la actual.
  List<Widget> _paginas(BuildContext context, CatalogViewModel vm) {
    final total = vm.totalPaginas;
    final actual = vm.paginaActual;
    final botones = <Widget>[];

    void agregar(int n) {
      final esActual = n == actual;
      botones.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: esActual
              ? TweenAnimationBuilder<double>(
                  key: ValueKey('pagina-seleccionada-$n'),
                  tween: Tween(begin: 0.85, end: 1),
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutBack,
                  builder: (context, escala, child) =>
                      Transform.scale(scale: escala, child: child),
                  child: FilledButton(
                    onPressed: () => vm.irAPagina(n),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(36, 36),
                      padding: EdgeInsets.zero,
                      shape: const StadiumBorder(),
                      visualDensity: VisualDensity.compact,
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Text('$n'),
                  ),
                )
              : OutlinedButton(
                  onPressed: () => vm.irAPagina(n),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(36, 36),
                    padding: EdgeInsets.zero,
                    shape: const StadiumBorder(),
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  child: Text('$n'),
                ),
        ),
      );
    }

    if (total <= 5) {
      for (var i = 1; i <= total; i++) {
        agregar(i);
      }
    } else {
      final inicio = (actual - 2).clamp(1, total - 4);
      for (var i = inicio; i <= inicio + 4; i++) {
        agregar(i);
      }
    }
    return botones;
  }
}

/// Botón compacto "Ant." (anterior).
class _BotonAnterior extends StatelessWidget {
  const _BotonAnterior({required this.vm});

  final CatalogViewModel vm;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: vm.hayPaginaAnterior ? vm.paginaAnterior : null,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 36),
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(fontSize: 13),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chevron_left, size: 18),
          Text('Ant.'),
        ],
      ),
    );
  }
}

/// Botón compacto "Sig." (siguiente).
class _BotonSiguiente extends StatelessWidget {
  const _BotonSiguiente({required this.vm});

  final CatalogViewModel vm;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: vm.hayPaginaSiguiente ? vm.paginaSiguiente : null,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 36),
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(fontSize: 13),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Sig.'),
          Icon(Icons.chevron_right, size: 18),
        ],
      ),
    );
  }
}

class _Grilla extends StatefulWidget {
  const _Grilla({super.key, required this.productos});

  final List<Producto> productos;

  @override
  State<_Grilla> createState() => _GrillaState();
}

class _GrillaState extends State<_Grilla> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Entrada escalonada de las tarjetas del grid (fade + desliz hacia arriba).
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: widget.productos.length,
      itemBuilder: (context, i) {
        final inicio = (i * 0.07).clamp(0.0, 0.45);
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = Curves.easeOutCubic.transform(
              Interval(inicio, 1.0).transform(_controller.value),
            );
            return Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, 30 * (1 - t)),
                child: child,
              ),
            );
          },
          child: _ProductCard(producto: widget.productos[i]),
        );
      },
    );
  }
}
class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.producto});

  final Producto producto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tieneOferta = producto.ofertaAplicada != null;
    final precio = producto.precioFinal ?? producto.precioNormal ?? 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrirDetalle(context, producto),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _imagenConHero(producto)),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (producto.marca != null &&
                      producto.marca!.nombre.isNotEmpty)
                    Text(
                      producto.marca!.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: Colors.grey),
                    ),
                  Text(
                    producto.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  if (tieneOferta) ...[
                    Text(
                      '\$${(producto.precioNormal ?? 0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '\$${precio.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else
                    Text(
                      '\$${precio.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltrosMarcas extends StatelessWidget {
  const _FiltrosMarcas({
    required this.marcas,
    required this.seleccionada,
    required this.onSeleccion,
  });

  final List<Marca> marcas;
  final String? seleccionada;
  final ValueChanged<String?> onSeleccion;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        children: [
          ChoiceChip(
            label: const Text('Todas'),
            selected: seleccionada == null,
            onSelected: (_) => onSeleccion(null),
          ),
          ...marcas.map(
            (m) => Padding(
              padding: const EdgeInsets.only(left: 6),
              child: ChoiceChip(
                label: Text(m.nombre),
                selected: seleccionada == m.id,
                onSelected: (_) => onSeleccion(m.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltrosFamilias extends StatelessWidget {
  const _FiltrosFamilias({
    required this.familias,
    required this.seleccionada,
    required this.onSeleccion,
  });

  final List<Familia> familias;
  final String? seleccionada;
  final ValueChanged<String?> onSeleccion;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        children: [
          ChoiceChip(
            label: const Text('Todas'),
            selected: seleccionada == null,
            onSelected: (_) => onSeleccion(null),
          ),
          ...familias.map(
            (f) => Padding(
              padding: const EdgeInsets.only(left: 6),
              child: ChoiceChip(
                label: Text(f.nombre),
                selected: seleccionada == f.id,
                onSelected: (_) => onSeleccion(f.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Navega al detalle del producto (compartida por las tarjetas).
void _abrirDetalle(BuildContext context, Producto producto) {
  final id = producto.id;
  if (id == null) return;
  Navigator.of(context).push(
    MaterialPageRoute(
      // `productoInicial` permite la transición Hero inmediata;
      // el detalle refresca con getProductoById al cargar.
      builder: (_) => ProductDetailView(
        productoId: id,
        productoInicial: producto,
      ),
    ),
  );
}

/// Imagen del producto con transición Hero hacia el detalle.
Widget _imagenConHero(Producto producto) {
  final imagen = (producto.imagenUrl != null && producto.imagenUrl!.isNotEmpty)
      ? Image.network(
          producto.imagenUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, _, _) => _placeholderImagen(),
        )
      : _placeholderImagen();
  final id = producto.id;
  return id != null ? Hero(tag: 'producto-$id', child: imagen) : imagen;
}

Widget _placeholderImagen({IconData icon = Icons.inventory_2, double size = 40}) {
  return Container(
    color: Colors.grey.shade200,
    child: Icon(icon, size: size),
  );
}
