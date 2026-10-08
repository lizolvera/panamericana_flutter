import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/cart_item.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../cart/view_models/cart_view_model.dart';
import '../../catalog/views/catalog_view.dart';
import '../../profile/views/profile_view.dart';
import '../../shell/shell_scaffold.dart';
import '../../shell/tab_index_notifier.dart';
import '../../../theme/app_colors.dart';

/// **View principal**: usa la shell persistente (header + footer) y cambia
/// el contenido según la pestaña activa.
/// Tab 0 = Inicio (catálogo/landing), Tab 1 = Perfil, Tab 2 = Carrito.
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

// ─────────────────────────────────────────────────────────────────────────────
// LOGIN PROMPT (invitado en Tab Perfil)
// ─────────────────────────────────────────────────────────────────────────────

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt();

  @override
  Widget build(BuildContext context) {
    final tab = context.read<TabIndexNotifier>();

    return Container(
      color: AppColors.fondoGeneral,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícono con fondo decorativo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.rosaBeigeClaro,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.vino.withValues(alpha: 0.15),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 52,
                    color: AppColors.vino,
                  ),
                ),
                const SizedBox(height: 24),
                // Sección "MI CUENTA"
                Text(
                  'MI CUENTA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    color: AppColors.terracota.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tu Perfil de Cliente',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.cafeOscuro,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Inicia sesión para consultar tus datos personales, administrar tus direcciones y pedidos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.cafeOscuro.withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                // Tarjeta de perfil decorativa
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.blancoCalido,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.rosaBeigeClaro),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cafeOscuro.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.rosaBeigeClaro,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.manage_accounts_outlined,
                          color: AppColors.vino,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Perfil',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.cafeOscuro,
                              ),
                            ),
                            Text(
                              'Administra tus datos personales, direcciones y seguridad.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.cafeOscuro.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: AppColors.vino,
                      foregroundColor: AppColors.blancoCalido,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/login').then((_) {
                      if (context.mounted &&
                          context.read<AuthViewModel>().isCliente) {
                        tab.indice = 2;
                      }
                    }),
                    icon: const Icon(Icons.login),
                    label: const Text('Iniciar sesión'),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => tab.indice = 0,
                  icon: const Icon(Icons.storefront_outlined,
                      color: AppColors.terracota),
                  label: const Text(
                    'Continuar explorando productos',
                    style: TextStyle(color: AppColors.terracota),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARRITO VIEW (Boceto 2) — diseño high-fidelity
// ─────────────────────────────────────────────────────────────────────────────

class _CarritoView extends StatelessWidget {
  const _CarritoView({required this.isCliente});

  final bool isCliente;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartViewModel>();
    final tab = context.read<TabIndexNotifier>();

    // ── Invitado ──────────────────────────────────────────────────────────────
    if (!isCliente) {
      return Container(
        color: AppColors.fondoGeneral,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.rosaBeigeClaro,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.vino.withValues(alpha: 0.15),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shopping_cart_outlined,
                      size: 48,
                      color: AppColors.vino,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'CARRITO DE COMPRAS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      color: AppColors.terracota.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tu carrito te espera',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.cafeOscuro,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Inicia sesión para agregar productos, consultar tu total y realizar pedidos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.cafeOscuro.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: AppColors.vino,
                        foregroundColor: AppColors.blancoCalido,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/login'),
                      icon: const Icon(Icons.login),
                      label: const Text('Iniciar sesión'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      foregroundColor: AppColors.vino,
                      side: const BorderSide(color: AppColors.vino),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => tab.indice = 0,
                    icon: const Icon(Icons.storefront_outlined),
                    label: const Text('Explorar catálogo'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ── Carrito vacío ─────────────────────────────────────────────────────────
    if (cart.items.isEmpty) {
      return Container(
        color: AppColors.fondoGeneral,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.rosaBeigeClaro,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.remove_shopping_cart_outlined,
                    size: 48,
                    color: AppColors.terracota,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Tu carrito está vacío',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cafeOscuro,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Descubre productos y aprovecha nuestras ofertas activas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.cafeOscuro.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.vino,
                    foregroundColor: AppColors.blancoCalido,
                  ),
                  onPressed: () => tab.indice = 0,
                  icon: const Icon(Icons.storefront_outlined),
                  label: const Text('Explorar productos'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Carrito con productos (Boceto 2) ──────────────────────────────────────
    return Container(
      color: AppColors.fondoGeneral,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header "Carrito de compras"
                  Container(
                    color: AppColors.blancoCalido,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shopping_cart_outlined,
                          color: AppColors.vino,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Carrito de compras',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.cafeOscuro,
                              ),
                        ),
                        const Spacer(),
                        Text(
                          '${cart.totalArticulos} art.',
                          style: const TextStyle(
                            color: AppColors.terracota,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Opciones colapsables (Boceto 2: ENVÍO >, ENTREGA >, PAGO >, PROMOCIONES >)
                  const _OpcionesEnvio(),
                  const SizedBox(height: 8),
                  // Encabezado de tabla
                  Container(
                    color: AppColors.blancoCalido,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        const SizedBox(width: 68),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'ARTÍCULO / DESCRIPCIÓN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color:
                                  AppColors.cafeOscuro.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        Text(
                          'PRECIO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.cafeOscuro.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.rosaBeigeClaro),
                  // Lista de productos
                  ...cart.items
                      .map((item) => _CartItemTile(item: item)),
                  const SizedBox(height: 16),
                  // Resumen del pedido (Boceto 2: subtotal, envío, impuestos, total)
                  _ResumenPedido(cart: cart),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          // Botón "Hacer Pedido"
          SafeArea(
            top: false,
            child: Container(
              color: AppColors.blancoCalido,
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppColors.vinoOscuro,
                    foregroundColor: AppColors.blancoCalido,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'El pago estará disponible en la fase 3',
                        ),
                        backgroundColor: AppColors.vino,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.lock_outline, size: 20),
                  label: const Text('Hacer Pedido'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Opciones de envío colapsables (Boceto 2) ──────────────────────────────────

class _OpcionesEnvio extends StatelessWidget {
  const _OpcionesEnvio();

  @override
  Widget build(BuildContext context) {
    const opciones = [
      (Icons.local_shipping_outlined, 'ENVÍO'),
      (Icons.schedule_outlined, 'ENTREGA'),
      (Icons.payment_outlined, 'PAGO'),
      (Icons.local_offer_outlined, 'PROMOCIONES'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.blancoCalido,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.rosaBeigeClaro),
        boxShadow: [
          BoxShadow(
            color: AppColors.cafeOscuro.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < opciones.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: AppColors.rosaBeigeClaro),
            InkWell(
              onTap: () {},
              borderRadius: i == 0
                  ? const BorderRadius.vertical(top: Radius.circular(14))
                  : i == opciones.length - 1
                      ? const BorderRadius.vertical(
                          bottom: Radius.circular(14))
                      : BorderRadius.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 13),
                child: Row(
                  children: [
                    Icon(opciones[i].$1,
                        size: 18, color: AppColors.terracota),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        opciones[i].$2,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          letterSpacing: 0.5,
                          color: AppColors.cafeOscuro,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 20,
                        color: AppColors.terracota),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Tile de producto en carrito ───────────────────────────────────────────────

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartViewModel>();
    final producto = item.producto;
    final id = producto.id;
    final precio = producto.precioFinal ?? producto.precioNormal ?? 0;

    return Container(
      color: AppColors.blancoCalido,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen cuadrada redondeada
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 60,
              height: 60,
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
          // Descripción
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (producto.marca != null &&
                    producto.marca!.nombre.isNotEmpty)
                  Text(
                    producto.marca!.nombre,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.terracota,
                      letterSpacing: 0.5,
                    ),
                  ),
                Text(
                  producto.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cafeOscuro,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${precio.toStringAsFixed(2)} c/u',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.cafeOscuro.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 6),
                // Controles de cantidad
                Row(
                  children: [
                    _QtyButton(
                      icon: Icons.remove,
                      onTap: id == null ? null : () => cart.decrementar(id),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.cantidad}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.cafeOscuro,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _QtyButton(
                      icon: Icons.add,
                      onTap: id == null ? null : () => cart.incrementar(id),
                    ),
                    const Spacer(),
                    // Eliminar ítem
                    GestureDetector(
                      onTap: id == null ? null : () => cart.eliminar(id),
                      child: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.terracota,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Precio total del ítem
          Text(
            '\$${(precio * item.cantidad).toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.vinoOscuro,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.rosaBeigeClaro,
        child: const Icon(Icons.inventory_2,
            size: 28, color: AppColors.terracota),
      );
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColors.rosaBeigeClaro
              : AppColors.rosaBeigeClaro.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.rosaNude.withValues(alpha: 0.5)),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null
              ? AppColors.vino
              : AppColors.cafeOscuro.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

// ── Resumen del pedido (Boceto 2) ─────────────────────────────────────────────

class _ResumenPedido extends StatelessWidget {
  const _ResumenPedido({required this.cart});
  final CartViewModel cart;

  @override
  Widget build(BuildContext context) {
    final subtotal = cart.totalPrecio;
    const envio = 0.0;
    final impuestos = subtotal * 0.16;
    final total = subtotal + envio + impuestos;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blancoCalido,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.rosaBeigeClaro),
        boxShadow: [
          BoxShadow(
            color: AppColors.cafeOscuro.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RESUMEN DEL PEDIDO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppColors.cafeOscuro.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 14),
          _FilaResumen(
            label: 'Subtotal (${cart.totalArticulos})',
            valor: '\$${subtotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 6),
          const _FilaResumen(
            label: 'Total de envío',
            valor: 'Gratis',
            valorColor: AppColors.terracota,
          ),
          const SizedBox(height: 6),
          _FilaResumen(
            label: 'Impuestos (16%)',
            valor: '\$${impuestos.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.rosaBeigeClaro),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cafeOscuro,
                ),
              ),
              const Spacer(),
              Text(
                '\$${total.toStringAsFixed(2)} pesos',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.vinoOscuro,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilaResumen extends StatelessWidget {
  const _FilaResumen({
    required this.label,
    required this.valor,
    this.valorColor,
  });

  final String label;
  final String valor;
  final Color? valorColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.cafeOscuro.withValues(alpha: 0.65),
          ),
        ),
        const Spacer(),
        Text(
          valor,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valorColor ?? AppColors.cafeOscuro,
          ),
        ),
      ],
    );
  }
}
