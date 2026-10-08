import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/carrusel.dart';
import '../../../../domain/models/familia.dart';
import '../../../../domain/models/marca.dart';
import '../../../../domain/models/producto.dart';
import '../../../theme/app_colors.dart';
import '../../cart/view_models/cart_view_model.dart';
import '../view_models/catalog_view_model.dart';
import '../../shell/shell_scaffold.dart';
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
  final _searchCtrl = TextEditingController();

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
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CatalogViewModel>();

    return Container(
      color: AppColors.fondoGeneral,
      child: Column(
        children: [
          // Buscador FIJO en la parte superior: no se desplaza con el contenido.
          Material(
            color: AppColors.blancoCalido,
            elevation: 0,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.rosaBeigeClaro, width: 1),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: TextField(
                controller: _searchCtrl,
                onChanged: vm.setBusqueda,
                decoration: InputDecoration(
                  hintText: 'Buscar producto…',
                  hintStyle: TextStyle(
                    color: AppColors.cafeOscuro.withValues(alpha: 0.4),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.terracota,
                    size: 22,
                  ),
                  suffixIcon: vm.busqueda.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 20,
                            color: AppColors.terracota,
                          ),
                          tooltip: 'Limpiar búsqueda',
                          onPressed: () {
                            _searchCtrl.clear();
                            vm.setBusqueda('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.fondoGeneral,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.rosaBeigeClaro),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.rosaBeigeClaro),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.vino, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      ),
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
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.rosaBeigeClaro,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_outlined,
                  size: 40,
                  color: AppColors.terracota,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  vm.errorMessage ?? 'Error al cargar el catálogo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.cafeOscuro.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.vino,
                  foregroundColor: AppColors.blancoCalido,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            if (vm.carruseles.isNotEmpty) _Carrusel(carruseles: vm.carruseles),
            if (vm.productosDestacados.isNotEmpty) ...[
              _SeccionTituloConFlecha(
                texto: 'Productos Destacados',
                onTap: () => Navigator.of(context).pushNamed('/catalogo'),
              ),
              _Destacados(productos: vm.productosDestacados),
            ],
            const _SeccionTitulo('Todos los productos'),
            if (vm.totalFiltrados == 0)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text(
                        'No hay productos que coincidan con la búsqueda o filtro',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: vm.limpiarFiltros,
                        child: const Text('Limpiar filtros'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              _GridConTransicion(vm: vm),
              const SizedBox(height: 12),
              _Paginacion(vm: vm),
            ],
          ],
        ),
      ),
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
            ?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.cafeOscuro,
            ),
      ),
    );
  }
}

/// Título de sección con flecha ">" que navega a otra pantalla.
class _SeccionTituloConFlecha extends StatelessWidget {
  const _SeccionTituloConFlecha({
    required this.texto,
    required this.onTap,
  });

  final String texto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
      child: Row(
        children: [
          Text(
            texto,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.cafeOscuro,
                ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onTap,
            child: const Row(
              children: [
                Text(
                  'Ver todo',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.vino,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.vino,
                ),
              ],
            ),
          ),
        ],
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
    final ancho = MediaQuery.of(context).size.width;
    final alturaCarrusel = (ancho * 0.38).clamp(140.0, 220.0);

    return Column(
      children: [
        SizedBox(
          height: alturaCarrusel,
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
              // Fondo degradado vino si no hay imagen
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.vinoOscuro, AppColors.vino],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Image.network(
                carrusel.imagenUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.content_cut,
                        color: AppColors.blancoCalido,
                        size: 40,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Distribuidora Panamericana',
                        style: TextStyle(
                          color: AppColors.blancoCalido,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (carrusel.titulo != null && carrusel.titulo!.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black54],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Text(
                      carrusel.titulo!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 4,
                          ),
                        ],
                      ),
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
    final precio = producto.precioFinal ?? producto.precioNormal ?? 0;
    final tieneOferta = producto.ofertaAplicada != null;

    return SizedBox(
      width: 190,
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: AppColors.blancoCalido,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.rosaBeigeClaro, width: 0.8),
        ),
        elevation: 2,
        shadowColor: AppColors.cafeOscuro.withValues(alpha: 0.08),
        child: InkWell(
          onTap: () => _abrirDetalle(context, producto),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen con badge de oferta
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14)),
                    child: AspectRatio(
                      aspectRatio: 1,
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
                  ),
                  if (tieneOferta)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.vino,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'OFERTA',
                          style: TextStyle(
                            color: AppColors.blancoCalido,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (producto.marca != null &&
                        producto.marca!.nombre.isNotEmpty)
                      Text(
                        producto.marca!.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.terracota,
                          letterSpacing: 0.3,
                        ),
                      ),
                    Text(
                      producto.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.cafeOscuro,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${precio.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.vinoOscuro,
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

/// Calcula de forma responsiva el número de columnas y la proporción
/// de aspecto de las tarjetas según el ancho del dispositivo.
SliverGridDelegate _calcularGridDelegate(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  final int crossAxisCount;
  final double childAspectRatio;

  if (width >= 900) {
    crossAxisCount = 4;
    childAspectRatio = 0.78;
  } else if (width >= 600) {
    crossAxisCount = 3;
    childAspectRatio = 0.74;
  } else if (width < 360) {
    crossAxisCount = 2;
    childAspectRatio = 0.67;
  } else {
    crossAxisCount = 2;
    childAspectRatio = 0.71;
  }

  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: crossAxisCount,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: childAspectRatio,
  );
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
        gridDelegate: _calcularGridDelegate(context),
        itemCount: 6,
        itemBuilder: (context, i) => Card(
          clipBehavior: Clip.antiAlias,
          color: AppColors.blancoCalido,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.rosaBeigeClaro, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.rosaBeigeClaro.withValues(alpha: 0.5),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 8,
                      width: 50,
                      decoration: BoxDecoration(
                        color: AppColors.rosaBeigeClaro,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 11,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.rosaBeigeClaro,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 11,
                      width: 70,
                      decoration: BoxDecoration(
                        color: AppColors.rosaBeigeClaro.withValues(alpha: 0.6),
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
      gridDelegate: _calcularGridDelegate(context),
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
    final tieneOferta = producto.ofertaAplicada != null;
    final precio = producto.precioFinal ?? producto.precioNormal ?? 0;
    final cart = context.read<CartViewModel>();

    return Card(
      clipBehavior: Clip.antiAlias,
      color: AppColors.blancoCalido,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.rosaBeigeClaro, width: 0.8),
      ),
      elevation: 2,
      shadowColor: AppColors.cafeOscuro.withValues(alpha: 0.08),
      child: InkWell(
        onTap: () => _abrirDetalle(context, producto),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen con overlay de oferta
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14)),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _imagenConHero(producto),
                  ),
                ),
                if (tieneOferta)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.vino,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'OFERTA',
                        style: TextStyle(
                          color: AppColors.blancoCalido,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (producto.marca != null &&
                      producto.marca!.nombre.isNotEmpty)
                    Text(
                      producto.marca!.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.terracota,
                        letterSpacing: 0.3,
                      ),
                    ),
                  Text(
                    producto.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.cafeOscuro,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (tieneOferta) ...[
                    Text(
                      '\$${(producto.precioNormal ?? 0).toStringAsFixed(2)}',
                      style: TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: AppColors.cafeOscuro.withValues(alpha: 0.4),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      '\$${precio.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.vinoOscuro,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ] else
                    Text(
                      '\$${precio.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.cafeOscuro,
                      ),
                    ),
                ],
              ),
            ),
            // Botón "Añadir"
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.vino,
                    foregroundColor: AppColors.blancoCalido,
                    minimumSize: const Size.fromHeight(32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () {
                    cart.agregar(producto);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${producto.nombre} añadido',
                          style: const TextStyle(fontSize: 13),
                        ),
                        backgroundColor: AppColors.vino,
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  },
                  child: const Text('Añadir'),
                ),
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
    return Container(
      height: 48,
      color: AppColors.blancoCalido,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          _Chip(
            label: 'Todas',
            selected: seleccionada == null,
            onTap: () => onSeleccion(null),
          ),
          ...marcas.map(
            (m) => Padding(
              padding: const EdgeInsets.only(left: 6),
              child: _Chip(
                label: m.nombre,
                selected: seleccionada == m.id,
                onTap: () => onSeleccion(m.id),
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
    return Container(
      height: 44,
      color: AppColors.blancoCalido,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        children: [
          _Chip(
            label: 'Todas',
            selected: seleccionada == null,
            onTap: () => onSeleccion(null),
          ),
          ...familias.map(
            (f) => Padding(
              padding: const EdgeInsets.only(left: 6),
              child: _Chip(
                label: f.nombre,
                selected: seleccionada == f.id,
                onTap: () => onSeleccion(f.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip personalizado con paleta de barbería.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.vino : AppColors.blancoCalido,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.vino : AppColors.rosaBeigeClaro,
            width: 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.vino.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.blancoCalido : AppColors.cafeOscuro,
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
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

Widget _placeholderImagen({IconData icon = Icons.content_cut, double size = 40}) {
  return Container(
    color: AppColors.rosaBeigeClaro.withValues(alpha: 0.5),
    child: Center(
      child: Icon(
        icon,
        size: size,
        color: AppColors.terracota.withValues(alpha: 0.6),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CatalogViewPage — ruta /catalogo (Boceto 5)
// ─────────────────────────────────────────────────────────────────────────────

/// Página completa del catálogo accesible desde el menú del AppBar o la
/// flecha "Ver todo >" de Productos Destacados. Incluye encabezado con
/// contador "MOSTRANDO X-Y DE Z PIEZAS" y todos los filtros.
class CatalogViewPage extends StatelessWidget {
  const CatalogViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShellScaffold(
      titleText: 'Catálogo de productos',
      body: _CatalogPageBody(),
    );
  }
}

class _CatalogPageBody extends StatefulWidget {
  const _CatalogPageBody();

  @override
  State<_CatalogPageBody> createState() => _CatalogPageBodyState();
}

class _CatalogPageBodyState extends State<_CatalogPageBody> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<CatalogViewModel>();
      if (vm.status == CatalogStatus.initial) vm.loadCatalog();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CatalogViewModel>();

    return Container(
      color: AppColors.fondoGeneral,
      child: Column(
        children: [
          // ── Buscador ────────────────────────────────────────────────────
          Material(
            color: AppColors.blancoCalido,
            elevation: 0,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.rosaBeigeClaro),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: TextField(
                controller: _searchCtrl,
                onChanged: vm.setBusqueda,
                decoration: InputDecoration(
                  hintText: 'Buscar en el catálogo…',
                  hintStyle: TextStyle(
                    color: AppColors.cafeOscuro.withValues(alpha: 0.4),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.terracota,
                  ),
                  suffixIcon: vm.busqueda.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 20,
                            color: AppColors.terracota,
                          ),
                          onPressed: () {
                            _searchCtrl.clear();
                            vm.setBusqueda('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.fondoGeneral,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.rosaBeigeClaro),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.rosaBeigeClaro),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.vino, width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          // ── Contador MOSTRANDO X-Y DE Z PIEZAS ─────────────────────────
          if (vm.status == CatalogStatus.loaded ||
              vm.status == CatalogStatus.initial)
            _ContadorPiezas(vm: vm),
          // ── Chips de marca ──────────────────────────────────────────────
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
          // ── Contenido ───────────────────────────────────────────────────
          Expanded(child: _contenidoCatalog(vm)),
        ],
      ),
    );
  }

  Widget _contenidoCatalog(CatalogViewModel vm) {
    switch (vm.status) {
      case CatalogStatus.loading:
        return const _GrillaSkeleton();
      case CatalogStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.rosaBeigeClaro,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_outlined,
                  size: 40,
                  color: AppColors.terracota,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  vm.errorMessage ?? 'Error al cargar el catálogo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.cafeOscuro.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.vino,
                  foregroundColor: AppColors.blancoCalido,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: vm.loadCatalog,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
      case CatalogStatus.initial:
      case CatalogStatus.loaded:
        if (vm.totalFiltrados == 0) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.search_off,
                  size: 48,
                  color: AppColors.terracota,
                ),
                const SizedBox(height: 8),
                const Text(
                  'No hay productos que coincidan',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.cafeOscuro),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.vino,
                    side: const BorderSide(color: AppColors.vino),
                  ),
                  onPressed: vm.limpiarFiltros,
                  child: const Text('Limpiar filtros'),
                ),
              ],
            ),
          );
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _GridConTransicion(vm: vm),
                const SizedBox(height: 12),
                _Paginacion(vm: vm),
              ],
            ),
          ),
        );
    }
  }
}

/// Banner contador: "MOSTRANDO X-Y DE Z PIEZAS" (Boceto 5).
class _ContadorPiezas extends StatelessWidget {
  const _ContadorPiezas({required this.vm});
  final CatalogViewModel vm;

  @override
  Widget build(BuildContext context) {
    final inicio = ((vm.paginaActual - 1) * 8) + 1;
    final fin = (vm.paginaActual * 8).clamp(0, vm.totalFiltrados);
    final total = vm.totalFiltrados;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.blancoCalido,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.rosaBeigeClaro),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.storefront_outlined,
            size: 16,
            color: AppColors.terracota,
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              total == 0
                  ? 'SIN RESULTADOS'
                  : 'MOSTRANDO $inicio-$fin DE $total PIEZAS',
              key: ValueKey('contador-$inicio-$fin-$total'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.cafeOscuro,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
