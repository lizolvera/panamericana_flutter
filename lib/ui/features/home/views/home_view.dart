import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/view_models/auth_view_model.dart';
import '../../catalog/views/catalog_view.dart';

/// **View principal**: contenedor con barra inferior (Inicio / Carrito /
/// Perfil). Muestra la vista de **invitado** (catálogo público) o la vista
/// de **cliente** según el rol de la sesión.
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _indice = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panamericana'),
        centerTitle: false,
      ),
      body: _cuerpo(context, auth),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) {
          // El perfil exige sesión: si es invitado, primero a iniciar sesión.
          if (i == 2 && !auth.isCliente) {
            Navigator.of(context).pushNamed('/login');
            return;
          }
          setState(() => _indice = i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Carrito',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _cuerpo(BuildContext context, AuthViewModel auth) {
    switch (_indice) {
      case 0:
        return auth.isCliente
            ? _ClienteHome(nombre: auth.nombre)
            : const CatalogView();
      case 1:
        return _CarritoPlaceholder(isCliente: auth.isCliente);
      default:
        return _PerfilPlaceholder(
          isCliente: auth.isCliente,
          nombre: auth.nombre,
        );
    }
  }
}

class _ClienteHome extends StatelessWidget {
  const _ClienteHome({this.nombre});

  final String? nombre;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Hola, ${nombre ?? 'cliente'} 👋\n\nVista de cliente:\n'
        'carrito, perfil y compras.',
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _CarritoPlaceholder extends StatelessWidget {
  const _CarritoPlaceholder({required this.isCliente});

  final bool isCliente;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          Text(
            isCliente
                ? 'Tu carrito (próximamente)'
                : 'Inicia sesión para ver tu carrito',
            textAlign: TextAlign.center,
          ),
          if (!isCliente) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).pushNamed('/login'),
              child: const Text('Iniciar sesión'),
            ),
          ],
        ],
      ),
    );
  }
}

class _PerfilPlaceholder extends StatelessWidget {
  const _PerfilPlaceholder({required this.isCliente, this.nombre});

  final bool isCliente;
  final String? nombre;

  @override
  Widget build(BuildContext context) {
    if (!isCliente) {
      return const Center(child: Text('Inicia sesión para ver tu perfil'));
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 40,
            child: Icon(Icons.person, size: 40),
          ),
          const SizedBox(height: 12),
          Text(
            nombre ?? 'Cliente',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.read<AuthViewModel>().logout(),
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}
