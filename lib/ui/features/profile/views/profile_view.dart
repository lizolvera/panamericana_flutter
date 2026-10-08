import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../cart/view_models/cart_view_model.dart';
import '../view_models/direcciones_view_model.dart';
import '../view_models/profile_view_model.dart';
import 'datos_view.dart';
import 'direcciones_view.dart';
import 'password_view.dart';
import 'pregunta_view.dart';

/// **View del perfil** (cliente): menú con los apartados de configuración
/// del usuario (datos personales, contraseña, direcciones y pregunta secreta).
///
/// Los ViewModels se crean aquí y se **pasan por constructor** a las
/// sub-vistas (que se abren como rutas nuevas y no pueden leerlos de un
/// provider acotado a esta ruta).
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
    final theme = Theme.of(context);
    final auth = context.watch<AuthViewModel>();
    final perfil = context.watch<ProfileViewModel>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 32,
              child: Icon(Icons.person, size: 34),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auth.nombre ?? 'Cliente',
                    style: theme.textTheme.titleLarge,
                  ),
                  Text(
                    perfil.perfil?.email ?? '',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _OpcionMenu(
          icon: Icons.person_outline,
          titulo: 'Datos personales',
          descripcion: 'Nombre, fecha de nacimiento y teléfono',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  DatosView(profileVm: context.read<ProfileViewModel>()),
            ),
          ),
        ),
        _OpcionMenu(
          icon: Icons.lock_outline,
          titulo: 'Contraseña',
          descripcion: 'Cambia tu contraseña de acceso',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  PasswordView(profileVm: context.read<ProfileViewModel>()),
            ),
          ),
        ),
        _OpcionMenu(
          icon: Icons.location_on_outlined,
          titulo: 'Mis direcciones',
          descripcion: 'Administra tus direcciones de envío',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DireccionesView(
                direccionesVm: context.read<DireccionesViewModel>(),
              ),
            ),
          ),
        ),
        _OpcionMenu(
          icon: Icons.security_outlined,
          titulo: 'Pregunta secreta',
          descripcion: 'Pregunta de recuperación de cuenta',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  PreguntaView(profileVm: context.read<ProfileViewModel>()),
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            // Se vacía el carrito en el momento exacto del cierre de sesión
            // (además del listener en main.dart para expiración de sesión).
            context.read<CartViewModel>().limpiar();
            context.read<AuthViewModel>().logout();
          },
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}

class _OpcionMenu extends StatelessWidget {
  const _OpcionMenu({
    required this.icon,
    required this.titulo,
    required this.descripcion,
    required this.onTap,
  });

  final IconData icon;
  final String titulo;
  final String descripcion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(titulo),
        subtitle: Text(descripcion),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
