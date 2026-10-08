import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/cart_item.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../cart/view_models/cart_view_model.dart';
import '../../catalog/views/catalog_view.dart';
import '../../profile/views/profile_view.dart';
import '../../shell/shell_scaffold.dart';
import '../../shell/tab_index_notifier.dart';

/// **View principal**: usa la shell persistente (header + footer) y cambia
/// el contenido según la pestaña activa. El inicio es el catálogo para
/// todos (invitados y clientes).
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final tab = context.watch<TabIndexNotifier>();
    final auth = context.watch<AuthViewModel>();

    final Widget cuerpo;
    switch (tab.indice) {
      case 0:
        cuerpo = const CatalogView();
      case 1:
        cuerpo = _CarritoView(isCliente: auth.isCliente);
      default:
        cuerpo = auth.isCliente ? const ProfileView() : const _LoginPrompt();
    }

    return ShellScaffold(body: cuerpo);
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Inicia sesión para ver tu perfil'));
  }
}

class _CarritoView extends StatelessWidget {
  const _CarritoView({required this.isCliente});

  final bool isCliente;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartViewModel>();

    if (!isCliente) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            const Text('Inicia sesión para ver tu carrito'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).pushNamed('/login'),
              child: const Text('Iniciar sesión'),
            ),
          ],
        ),
      );
    }

    if (cart.items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Tu carrito está vacío'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: cart.items.length,
            itemBuilder: (context, i) => _CartItemTile(item: cart.items[i]),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total', style: TextStyle(color: Colors.grey)),
                      Text(
                        '\$${cart.totalPrecio.toStringAsFixed(2)}',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () {
                    // TODO(fase 3): checkout con PayPal (pagos/paypal/*).
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('El pago estará disponible en la fase 3'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.payment),
                  label: const Text('Comprar'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartViewModel>();
    final producto = item.producto;
    final id = producto.id;
    final precio = producto.precioFinal ?? producto.precioNormal ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 56,
                child: (producto.imagenUrl != null &&
                        producto.imagenUrl!.isNotEmpty)
                    ? Image.network(
                        producto.imagenUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${precio.toStringAsFixed(2)} c/u',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: id == null ? null : () => cart.decrementar(id),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              '${item.cantidad}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: id == null ? null : () => cart.incrementar(id),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.inventory_2, size: 24),
      );
}
