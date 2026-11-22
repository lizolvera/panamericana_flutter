import '../../checkout/views/checkout_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../cart/view_models/cart_view_model.dart';
import '../../shell/tab_index_notifier.dart';
import '../view_models/direcciones_view_model.dart';
import '../view_models/profile_view_model.dart';
import 'datos_view.dart';
import 'direcciones_view.dart';
import 'password_view.dart';
import 'pregunta_view.dart';

/// **View del perfil** (Boceto 4): MI CUENTA → Perfil + tiles de configuración
/// + sección INFORMACIÓN PERSONAL + botón Cerrar sesión.
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              ProfileViewModel(context.read<AuthRepository>())..load(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              DireccionesViewModel(context.read<AuthRepository>())..load(),
        ),
      ],
      child: const _ProfileMenu(),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final perfil = context.watch<ProfileViewModel>();

    return Container(
      color: AppColors.fondoGeneral,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            // El body se extiende bajo el NavigationBar (extendBody: true):
            // dejamos espacio inferior para que el botón no quede tapado.
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              // ── Sección "MI CUENTA" ──────────────────────────────────────
              _SeccionLabel('MI CUENTA'),

              // Tarjeta "Perfil" con descripción
              _PerfilCard(auth: auth),

              const SizedBox(height: 10),

              // Tiles de opciones
              _OpcionTile(
                icon: Icons.person_outline,
                titulo: 'DATOS PERSONALES',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        DatosView(profileVm: context.read<ProfileViewModel>()),
                  ),
                ),
              ),
              _OpcionTile(
                icon: Icons.lock_outline,
                titulo: 'CONTRASEÑA',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PasswordView(
                        profileVm: context.read<ProfileViewModel>()),
                  ),
                ),
              ),
              _OpcionTile(
                icon: Icons.shopping_bag_outlined,
                titulo: 'MIS COMPRAS',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CheckoutView(soloPedidos: true),
                  ),
                ),
              ),
              _OpcionTile(
                icon: Icons.location_on_outlined,
                titulo: 'MIS DIRECCIONES',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DireccionesView(
                        direccionesVm:
                            context.read<DireccionesViewModel>()),
                  ),
                ),
              ),
              _OpcionTile(
                icon: Icons.security_outlined,
                titulo: 'PREGUNTA SECRETA',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PreguntaView(
                        profileVm: context.read<ProfileViewModel>()),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Sección "INFORMACIÓN PERSONAL" ───────────────────────────
              _SeccionLabel('INFORMACIÓN PERSONAL'),

              // Tarjeta "Datos Personales"
              _InfoPersonalCard(perfil: perfil, auth: auth),

              const SizedBox(height: 28),

              // ── Botón Cerrar sesión ──────────────────────────────────────
              _BotonCerrarSesion(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Etiqueta de sección ────────────────────────────────────────────────────────

class _SeccionLabel extends StatelessWidget {
  const _SeccionLabel(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
              color: AppColors.terracota.withValues(alpha: 0.8),
            ),
      ),
    );
  }
}

// ── Tarjeta de perfil (Boceto 4) ───────────────────────────────────────────────

class _PerfilCard extends StatelessWidget {
  const _PerfilCard({required this.auth});
  final AuthViewModel auth;

  @override
  Widget build(BuildContext context) {
    return AppOutlineCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: AppTheme.padding16,
      borderRadius: AppTheme.radius14,
      elevation: 4,
      shadowColor: AppTheme.cardShadow.color,
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
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
              Icons.person,
              size: 30,
              color: AppColors.vino,
            ),
          ),
          AppTheme.widthSpacer14,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título "Perfil"
                Text(
                  'Perfil',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.cafeOscuro,
                        letterSpacing: -0.5,
                      ),
                ),
                AppTheme.spacer4,
                // Nombre del usuario
                Text(
                  auth.nombre ?? 'Cliente',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.vino,
                        letterSpacing: 0.2,
                      ),
                ),
                AppTheme.spacer2,
                Text(
                  'Administra tus datos personales, direcciones y seguridad.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.cafeOscuro.withValues(alpha: 0.55),
                        height: 1.4,
                        letterSpacing: 0.2,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tile de opción (Boceto 4) ─────────────────────────────────────────────────

class _OpcionTile extends StatelessWidget {
  const _OpcionTile({
    required this.icon,
    required this.titulo,
    required this.onTap,
  });

  final IconData icon;
  final String titulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.blancoCalido,
        borderRadius: AppTheme.radius14,
        border: Border.all(color: AppColors.rosaBeigeClaro),
        boxShadow: [AppTheme.shadowBoutique],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.radius14,
        splashColor: AppColors.rosaPalo.withValues(alpha: 0.12),
        highlightColor: AppColors.terracota.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.rosaBeigeClaro.withValues(alpha: 0.6),
                  borderRadius: AppTheme.radius10,
                ),
                child: Icon(icon, size: 20, color: AppColors.vino),
              ),
              AppTheme.widthSpacer16,
              Expanded(
                child: Text(
                  titulo,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: AppColors.cafeOscuro,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.terracota,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tarjeta "Datos Personales" (INFORMACIÓN PERSONAL) ────────────────────────

class _InfoPersonalCard extends StatelessWidget {
  const _InfoPersonalCard({required this.perfil, required this.auth});
  final ProfileViewModel perfil;
  final AuthViewModel auth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blancoCalido,
        borderRadius: AppTheme.radius14,
        border: Border.all(color: AppColors.rosaBeigeClaro),
        boxShadow: [AppTheme.shadowBoutique],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.vino,
                  borderRadius: AppTheme.radius10,
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  size: 20,
                  color: AppColors.blancoCalido,
                ),
              ),
              AppTheme.widthSpacer12,
              Expanded(
                child: Text(
                  'Datos Personales',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.cafeOscuro,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          AppTheme.spacer8,
          Text(
            'Actualiza los datos principales de tu cuenta.',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              color: AppColors.cafeOscuro.withValues(alpha: 0.55),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          // Datos actuales (si se han cargado)
          if (perfil.perfil?.email != null) ...[
            _DatoRow(
              icon: Icons.email_outlined,
              label: 'Correo',
              valor: perfil.perfil!.email ?? '',
            ),
          ],
          if (auth.nombre != null) ...[
            AppTheme.spacer8,
            _DatoRow(
              icon: Icons.person_outline,
              label: 'Nombre',
              valor: auth.nombre!,
            ),
          ],
        ],
      ),
    );
  }
}

class _DatoRow extends StatelessWidget {
  const _DatoRow({
    required this.icon,
    required this.label,
    required this.valor,
  });
  final IconData icon;
  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.terracota),
        AppTheme.widthSpacer8,
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.cafeOscuro.withValues(alpha: 0.5),
            letterSpacing: 0.2,
          ),
        ),
        Expanded(
          child: Text(
            valor,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: AppColors.cafeOscuro,
              letterSpacing: 0.2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Botón Cerrar sesión ────────────────────────────────────────────────────────

class _BotonCerrarSesion extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.vino.withValues(alpha: 0.06),
        borderRadius: AppTheme.radius14,
        border: Border.all(color: AppColors.vino.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        onTap: () async {
          final confirmar = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.radius20,
              ),
              backgroundColor: AppColors.blancoCalido,
              titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              actionsAlignment: MainAxisAlignment.end,
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.vino,
                      borderRadius: AppTheme.radius12,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.vinoOscuro.withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.logout,
                      color: AppColors.blancoCalido,
                      size: 20,
                    ),
                  ),
                  AppTheme.widthSpacer12,
                  Expanded(
                    child: Text(
                      'Cerrar sesión',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.cafeOscuro,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              content: Text(
                '¿Estás seguro de que deseas salir de tu cuenta?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.cafeOscuro.withValues(alpha: 0.7),
                  letterSpacing: 0.2,
                  height: 1.4,
                ),
              ),
              actions: [
                AppTextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  text: 'Cancelar',
                  color: AppColors.cafeOscuro.withValues(alpha: 0.55),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.vino,
                    foregroundColor: AppColors.blancoCalido,
                    minimumSize: const Size(0, 46),
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.radius12,
                    ),
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: 0.2,
                        ),
                  ),
                  child: const Text('Cerrar sesión'),
                ),
              ],
            ),
          );
          if (confirmar != true || !context.mounted) return;

          final cart = context.read<CartViewModel>();
          final auth = context.read<AuthViewModel>();
          final tab = context.read<TabIndexNotifier>();
          final navigator = Navigator.of(context);
          final messenger = ScaffoldMessenger.of(context);

          cart.limpiar();
          await auth.logout();
          if (!context.mounted) return;

          tab.indice = 0;
          navigator.popUntil((route) => route.isFirst);
          navigator.pushNamed('/login');

          messenger.showSnackBar(
            SnackBar(
              content: const Text('Sesión cerrada correctamente'),
              backgroundColor: AppColors.vino,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.radius10,
              ),
            ),
          );
        },
        borderRadius: AppTheme.radius14,
        splashColor: AppColors.vino.withValues(alpha: 0.12),
        highlightColor: AppColors.vino.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.logout,
                size: 20,
                color: AppColors.vino,
              ),
              AppTheme.widthSpacer10,
              Text(
                'Cerrar sesión',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.vino,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
