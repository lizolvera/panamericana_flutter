import '../../checkout/views/checkout_view.dart';
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
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';

/// **View principal**: usa la shell persistente (header + footer) y cambia
/// el contenido según la pestaña activa.
/// Tab 0 = Inicio (catálogo/landing), Tab 1 = Carrito, Tab 2 = Perfil.
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

    return ShellScaffold(
      isDetail: false,
      body: cuerpo,
    );
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
          padding: AppTheme.padding28,
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
                        color: AppColors.vinoOscuro.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 52,
                    color: AppColors.vino,
                  ),
                ),
                AppTheme.spacer24,
                // Sección "MI CUENTA"
                Text(
                  'MI CUENTA',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                        color: AppColors.terracota.withValues(alpha: 0.8),
                      ),
                ),
                AppTheme.spacer12,
                Text(
                  'Tu Perfil de Cliente',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.cafeOscuro,
                        letterSpacing: -0.5,
                      ),
                ),
                AppTheme.spacer8,
                Text(
                  'Inicia sesión para consultar tus datos personales, administrar tus direcciones y pedidos.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.cafeOscuro.withValues(alpha: 0.6),
                        height: 1.5,
                        letterSpacing: 0.2,
                      ),
                ),
                AppTheme.spacer28,
                // Tarjeta de perfil decorativa
                AppOutlineCard(
                  padding: AppTheme.padding16,
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
                      AppTheme.spacer14,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Perfil',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.cafeOscuro,
                                    letterSpacing: 0.2,
                                  ),
                            ),
                            AppTheme.spacer4,
                            Text(
                              'Administra tus datos personales, direcciones y seguridad.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.cafeOscuro.withValues(alpha: 0.6),
                                    letterSpacing: 0.2,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                AppTheme.spacer28,
                AppPrimaryButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/login').then((_) {
                    if (context.mounted &&
                        context.read<AuthViewModel>().isCliente) {
                      tab.indice = 2;
                    }
                  }),
                  icon: const Icon(Icons.login),
                  text: 'Iniciar sesión',
                ),
                AppTheme.spacer10,
                AppSecondaryButton.icon(
                  onPressed: () => tab.indice = 0,
                  icon: const Icon(Icons.storefront_outlined),
                  text: 'Continuar explorando productos',
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
            padding: AppTheme.padding28,
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
                          color: AppColors.vinoOscuro.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shopping_cart_outlined,
                      size: 48,
                      color: AppColors.vino,
                    ),
                  ),
                  AppTheme.spacer24,
                  Text(
                    'CARRITO DE COMPRAS',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                          color: AppColors.terracota.withValues(alpha: 0.8),
                        ),
                  ),
                  AppTheme.spacer10,
                  Text(
                    'Tu carrito te espera',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.cafeOscuro,
                          letterSpacing: -0.5,
                        ),
                  ),
                  AppTheme.spacer8,
                  Text(
                    'Inicia sesión para agregar productos, consultar tu total y realizar pedidos.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.cafeOscuro.withValues(alpha: 0.6),
                          height: 1.5,
                          letterSpacing: 0.2,
                        ),
                  ),
                  AppTheme.spacer28,
                  AppPrimaryButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/login'),
                    icon: const Icon(Icons.login),
                    text: 'Iniciar sesión',
                  ),
                  AppTheme.spacer10,
                  AppSecondaryButton.icon(
                    onPressed: () => tab.indice = 0,
                    icon: const Icon(Icons.storefront_outlined),
                    text: 'Explorar catálogo',
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
            padding: AppTheme.padding28,
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
                        color: AppColors.vinoOscuro.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.remove_shopping_cart_outlined,
                    size: 48,
                    color: AppColors.terracota,
                  ),
                ),
                AppTheme.spacer20,
                Text(
                  'Tu carrito está vacío',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.cafeOscuro,
                        letterSpacing: -0.5,
                      ),
                ),
                AppTheme.spacer8,
                Text(
                  'Descubre productos y aprovecha nuestras ofertas activas.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.cafeOscuro.withValues(alpha: 0.6),
                        letterSpacing: 0.2,
                      ),
                ),
                AppTheme.spacer24,
                AppPrimaryButton.icon(
                  onPressed: () => tab.indice = 0,
                  icon: const Icon(Icons.storefront_outlined),
                  text: 'Explorar productos',
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
                        AppTheme.spacer8,
                        Text(
                          'Carrito de compras',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.cafeOscuro,
                                letterSpacing: -0.5,
                              ),
                        ),
                        const Spacer(),
                        Text(
                          '${cart.totalArticulos} art.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.terracota,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                        ),
                      ],
                    ),
                  ),
                  AppTheme.spacer10,
                  // Encabezado de tabla
                  AppOutlineCard(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        const SizedBox(width: 68),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'ARTÍCULO / DESCRIPCIÓN',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: AppColors.cafeOscuro.withValues(alpha: 0.5),
                                ),
                          ),
                        ),
                        Text(
                          'PRECIO',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: AppColors.cafeOscuro.withValues(alpha: 0.5),
                              ),
                        ),
                      ],
                    ),
                  ),
                  AppTheme.spacer8,
                  // Lista de productos
                  ...cart.items.map((item) => _CartItemTile(item: item)),
                  AppTheme.spacer6,
                  // Resumen del pedido (Boceto 2: subtotal, envío, impuestos, total)
                  _ResumenPedido(cart: cart),
                  AppTheme.spacer24,
                ],
              ),
            ),
          ),
          // Botón "Hacer Pedido"
          SafeArea(
            top: false,
            child: Container(
              color: AppColors.blancoCalido,
              padding: AppTheme.padding16,
              child: AppPrimaryButton.icon(
                minHeight: 52,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const CheckoutView()),
                ),
                icon: const Icon(Icons.lock_outline, size: 20),
                text: 'Pagar con PayPal',
              ),
            ),
          ),
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

    return AppOutlineCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: AppTheme.padding12,
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 76,
                child: (producto.imagenUrl != null &&
                        producto.imagenUrl!.isNotEmpty)
                    ? Image.network(
                        producto.imagenUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            AppTheme.spacer12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (producto.marca != null &&
                                producto.marca!.nombre.isNotEmpty)
                              Text(
                                producto.marca!.nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.terracota,
                                      letterSpacing: 0.4,
                                    ),
                              ),
                            AppTheme.spacer2,
                            Text(
                              producto.nombre,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    height: 1.15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.cafeOscuro,
                                    letterSpacing: 0.2,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      AppTheme.spacer8,
                      Text(
                        '\$${(precio * item.cantidad).toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.vinoOscuro,
                              letterSpacing: 0.2,
                            ),
                      ),
                    ],
                  ),
                  AppTheme.spacer5,
                  Text(
                    '\$${precio.toStringAsFixed(2)} c/u',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.cafeOscuro.withValues(alpha: 0.55),
                          letterSpacing: 0.2,
                        ),
                  ),
                  AppTheme.spacer8,
                  Row(
                    children: [
                      _QtyButton(
                        icon: Icons.remove,
                        onTap: id == null ? null : () => cart.decrementar(id),
                      ),
                      SizedBox(
                        width: 26,
                        child: Text(
                          '${item.cantidad}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.cafeOscuro,
                                letterSpacing: 0.2,
                              ),
                        ),
                      ),
                      _QtyButton(
                        icon: Icons.add,
                        onTap: id == null ? null : () => cart.incrementar(id),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: id == null ? null : () => cart.eliminar(id),
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 19,
                          color: AppColors.terracota,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.superficieSuave,
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
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColors.rosaBeigeClaro
              : AppColors.rosaBeigeClaro.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.rosaBeigeClaro),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 15,
            color: onTap != null
                ? AppColors.vino
                : AppColors.cafeOscuro.withValues(alpha: 0.3),
          ),
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
    // El backend no añade un impuesto adicional al total de los productos.
    final total = subtotal + envio;

    return AppOutlineCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: AppTheme.padding16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RESUMEN DEL PEDIDO',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppColors.cafeOscuro.withValues(alpha: 0.5),
                ),
          ),
          AppTheme.spacer14,
          _FilaResumen(
            label: 'Subtotal (${cart.totalArticulos})',
            valor: '\$${subtotal.toStringAsFixed(2)}',
          ),
          AppTheme.spacer6,
          _FilaResumen(
            label: 'Total de envío',
            valor: 'Gratis',
            valorColor: AppColors.terracota,
          ),
          AppTheme.spacer14,
          Container(
            height: 1,
            color: AppColors.rosaBeigeClaro,
          ),
          AppTheme.spacer10,
          Row(
            children: [
              Text(
                'Total',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.cafeOscuro,
                      letterSpacing: -0.5,
                    ),
              ),
              Expanded(
                child: Text(
                  '\$${total.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.vinoOscuro,
                        letterSpacing: -0.5,
                      ),
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.cafeOscuro.withValues(alpha: 0.65),
                letterSpacing: 0.2,
              ),
        ),
        const Spacer(),
        Text(
          valor,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valorColor ?? AppColors.cafeOscuro,
                letterSpacing: 0.2,
              ),
        ),
      ],
    );
  }
}
