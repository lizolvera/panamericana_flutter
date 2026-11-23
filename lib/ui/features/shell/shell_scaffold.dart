import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/view_models/auth_view_model.dart';
import '../cart/view_models/cart_view_model.dart';
import 'tab_index_notifier.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_colors.dart';

/// **Concha de la app**: shell persistente con AppBar temático y BottomNavigationBar.
/// 
/// - Para pantallas principales (isDetail=false): usa SliverAppBar expandible
///   con gradiente vino → vinoOscuro
/// - Para pantallas de detalle (isDetail=true): usa AppBar estándar
///   con fondo blancoCalido
/// 
/// Solo el contenido (`body`) cambia según la ruta/pestaña.
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({
    super.key,
    required this.body,
    this.fab,
    this.titleText,
    this.isDetail = false,
  });

  final Widget body;

  /// Botón flotante opcional (p. ej. el "+" de direcciones).
  final Widget? fab;

  /// Título opcional de la barra superior. Si es nulo, usa 'Panamericana'.
  final String? titleText;

  /// Si es true, usa AppBar estándar (para pantallas de detalle)
  final bool isDetail;

  void _cambiarPestana(
    BuildContext context,
    TabIndexNotifier tab,
    int indice,
  ) {
    // Si venimos de una ruta apilada (detalle, login...), volvemos al inicio.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
    tab.indice = indice;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final cart = context.watch<CartViewModel>();
    final tab = context.watch<TabIndexNotifier>();
    final hayArticulos = cart.totalArticulos > 0;

    final String effectiveTitle = titleText ?? 'Panamericana';

    // ===========================================================================
    // PANTALLAS PRINCIPALES: SliverAppBar expandible con gradiente
    // ===========================================================================
    if (!isDetail) {
      return Scaffold(
        extendBody: true,
        floatingActionButton: fab,
        bottomNavigationBar: _buildBottomNavigationBar(
          context, auth, cart, tab, hayArticulos,
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // SliverAppBar expandible con gradiente vino → vinoOscuro
              SliverAppBar(
                backgroundColor: AppColors.vino,
                foregroundColor: AppColors.blancoCalido,
                elevation: 0,
                scrolledUnderElevation: 0,
                floating: true,
                pinned: true,
                stretch: true,
                snap: false,
                expandedHeight: 160,
                collapsedHeight: kToolbarHeight,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    effectiveTitle,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blancoCalido,
                      letterSpacing: -0.5,
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Gradiente boutique
                      Container(
                        decoration: const BoxDecoration(
                          gradient: AppTheme.sliverAppBarGradient,
                        ),
                      ),
                      // Overlay para mejorar legibilidad del texto
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.vinoOscuro.withValues(alpha: 0.4),
                              AppColors.vinoOscuro.withValues(alpha: 0.2),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                  titlePadding: const EdgeInsetsDirectional.only(
                    start: 72,
                    bottom: 16,
                  ),
                ),
                leading: Navigator.of(context).canPop() 
                    ? const BackButton(color: AppColors.blancoCalido) 
                    : null,
                iconTheme: const IconThemeData(color: AppColors.blancoCalido),
                actionsIconTheme: const IconThemeData(color: AppColors.blancoCalido),
              ),
            ];
          },
          body: body,
        ),
      );
    }

    // ===========================================================================
    // PANTALLAS DE DETALLE: AppBar estándar con fondo blancoCalido
    // ===========================================================================
    return Scaffold(
      appBar: AppBar(
        // Flecha de regreso cuando hay una ruta apilada; si no, sin leading.
        leading: Navigator.of(context).canPop() ? const BackButton() : null,
        title: Text(effectiveTitle),
        centerTitle: false,
        // Estilo para detalle: fondo blancoCalido, surfaceTint transparent
        backgroundColor: AppColors.blancoCalido,
        foregroundColor: AppColors.cafeOscuro,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 4,
        iconTheme: const IconThemeData(color: AppColors.cafeOscuro),
        titleTextStyle: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.cafeOscuro,
          letterSpacing: -0.5,
        ),
      ),
      body: body,
      floatingActionButton: fab,
      bottomNavigationBar: _buildBottomNavigationBar(
        context, auth, cart, tab, hayArticulos,
      ),
    );
  }

  Widget _buildBottomNavigationBar(
    BuildContext context,
    AuthViewModel auth,
    CartViewModel cart,
    TabIndexNotifier tab,
    bool hayArticulos,
  ) {
    return NavigationBar(
      selectedIndex: tab.indice.clamp(0, 2),
      onDestinationSelected: (i) {
        // El perfil exige sesión: si es invitado, primero a iniciar sesión.
        if (i == 2 && !auth.isCliente) {
          Navigator.of(context).pushNamed('/login').then((_) {
            if (context.mounted && context.read<AuthViewModel>().isCliente) {
              _cambiarPestana(context, tab, 2);
            }
          });
          return;
        }
        _cambiarPestana(context, tab, i);
      },
      backgroundColor: AppColors.blancoCalido,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 64,
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: hayArticulos,
            label: Text('${cart.totalArticulos}'),
            child: const Icon(Icons.shopping_cart_outlined),
          ),
          selectedIcon: Badge(
            isLabelVisible: hayArticulos,
            label: Text('${cart.totalArticulos}'),
            child: const Icon(Icons.shopping_cart),
          ),
          label: 'Carrito',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}
