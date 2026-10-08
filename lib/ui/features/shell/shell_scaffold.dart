import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/view_models/auth_view_model.dart';
import '../cart/view_models/cart_view_model.dart';
import 'tab_index_notifier.dart';

/// **Concha de la app**: header (Panamericana + menú) y footer (barra
/// Inicio/Carrito/Perfil) persistentes en TODAS las vistas. Solo el
/// contenido (`body`) cambia según la ruta/pestaña.
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.body, this.fab});

  final Widget body;

  /// Botón flotante opcional (p. ej. el "+" de direcciones).
  final Widget? fab;

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

    return Scaffold(
      appBar: AppBar(
        // Flecha de regreso cuando hay una ruta apilada; si no, sin leading.
        leading: Navigator.of(context).canPop() ? const BackButton() : null,
        title: const Text('Panamericana'),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Menú',
            onSelected: (opcion) {
              switch (opcion) {
                case 'inicio':
                  _cambiarPestana(context, tab, 0);
                case 'carrito':
                  _cambiarPestana(context, tab, 1);
                case 'perfil':
                  if (auth.isCliente) {
                    _cambiarPestana(context, tab, 2);
                  } else {
                    Navigator.of(context).pushNamed('/login');
                  }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'inicio',
                child: ListTile(
                  leading: Icon(Icons.home_outlined),
                  title: Text('Inicio'),
                ),
              ),
              PopupMenuItem(
                value: 'carrito',
                child: ListTile(
                  leading: Icon(Icons.shopping_cart_outlined),
                  title: Text('Carrito'),
                ),
              ),
              PopupMenuItem(
                value: 'perfil',
                child: ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Perfil'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: body,
      floatingActionButton: fab,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.indice,
        onDestinationSelected: (i) {
          // El perfil exige sesión: si es invitado, primero a iniciar sesión.
          if (i == 2 && !auth.isCliente) {
            Navigator.of(context).pushNamed('/login');
            return;
          }
          _cambiarPestana(context, tab, i);
        },
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
      ),
    );
  }
}
