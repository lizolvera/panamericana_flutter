import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../theme/app_colors.dart';
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
            padding: const EdgeInsets.only(bottom: 24),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _BotonCerrarSesion(),
              ),
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
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.0,
          color: AppColors.terracota,
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
                  color: AppColors.vino.withValues(alpha: 0.15),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              size: 30,
              color: AppColors.vino,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título "Perfil"
                const Text(
                  'Perfil',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.cafeOscuro,
                  ),
                ),
                const SizedBox(height: 4),
                // Nombre del usuario
                Text(
                  auth.nombre ?? 'Cliente',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.vino,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Administra tus datos personales, direcciones y seguridad.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.cafeOscuro.withValues(alpha: 0.55),
                    height: 1.4,
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.blancoCalido,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rosaBeigeClaro),
        boxShadow: [
          BoxShadow(
            color: AppColors.cafeOscuro.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.rosaBeigeClaro.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 20, color: AppColors.vino),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.5,
                    color: AppColors.cafeOscuro,
                  ),
                ),
              ),
              const Icon(
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.vino,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  size: 20,
                  color: AppColors.blancoCalido,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Datos Personales',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.cafeOscuro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Actualiza los datos principales de tu cuenta.',
            style: TextStyle(
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
            const SizedBox(height: 8),
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
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.terracota),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.cafeOscuro.withValues(alpha: 0.5),
          ),
        ),
        Expanded(
          child: Text(
            valor,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.cafeOscuro,
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.vino.withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        onTap: () async {
          final confirmar = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: AppColors.blancoCalido,
              title: const Row(
                children: [
                  Icon(Icons.logout, color: AppColors.vino, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Cerrar sesión',
                    style: TextStyle(
                      color: AppColors.cafeOscuro,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Text(
                '¿Estás seguro de que deseas salir de tu cuenta?',
                style: TextStyle(
                  color: AppColors.cafeOscuro.withValues(alpha: 0.7),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: AppColors.cafeOscuro.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.vino,
                    foregroundColor: AppColors.blancoCalido,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Cerrar sesión'),
                ),
              ],
            ),
          );
          if (confirmar != true || !context.mounted) return;
          context.read<CartViewModel>().limpiar();
          await context.read<AuthViewModel>().logout();
          if (!context.mounted) return;
          context.read<TabIndexNotifier>().indice = 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Sesión cerrada correctamente'),
              backgroundColor: AppColors.vino,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.logout,
                size: 20,
                color: AppColors.vino,
              ),
              const SizedBox(width: 10),
              const Text(
                'Cerrar sesión',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.vino,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
