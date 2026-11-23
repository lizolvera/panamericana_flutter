import 'package:flutter/material.dart';

/// Botón con efecto de presión usando AnimatedScale y AnimatedContainer.
/// 
/// Este widget envuelve cualquier botón (FilledButton, OutlinedButton, etc.)
/// y añade animaciones de escala y sombra al presionar, creando un efecto
/// táctil elegante estilo "boutique moderna".
/// 
/// Uso:
/// ```dart
/// PressableButton(
///   onPressed: () => print('Pressed'),
///   child: FilledButton(
///     onPressed: () => print('Pressed'),
///     child: Text('Botón'),
///   ),
/// )
/// ```
class PressableButton extends StatefulWidget {
  const PressableButton({
    super.key,
    required this.child,
    this.onPressed,
    this.scaleDown = 0.98,
    this.animationDuration = const Duration(milliseconds: 100),
    this.shadowColor,
    this.shadowBlurRadius = 0,
    this.shadowOffset = Offset.zero,
  });

  /// Widget hijo (normalmente un botón)
  final Widget child;

  /// Callback al presionar
  final VoidCallback? onPressed;

  /// Escala al presionar (default: 0.98 = 2% más pequeño)
  final double scaleDown;

  /// Duración de la animación
  final Duration animationDuration;

  /// Color de la sombra (opcional)
  final Color? shadowColor;

  /// Radio de desenfoque de la sombra
  final double shadowBlurRadius;

  /// Offset de la sombra
  final Offset shadowOffset;

  @override
  State<PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<PressableButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _onTapDown(),
      onTapUp: (_) => _onTapUp(),
      onTapCancel: () => _onTapUp(),
      onTap: widget.onPressed,
      child: AnimatedScale(
        duration: widget.animationDuration,
        scale: _isPressed ? widget.scaleDown : 1.0,
        child: AnimatedContainer(
          duration: widget.animationDuration,
          decoration: _isPressed && widget.shadowColor != null
              ? BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: widget.shadowColor!,
                      blurRadius: widget.shadowBlurRadius,
                      offset: widget.shadowOffset,
                    ),
                  ],
                )
              : null,
          child: widget.child,
        ),
      ),
    );
  }

  void _onTapDown() {
    if (mounted) {
      setState(() => _isPressed = true);
    }
  }

  void _onTapUp() {
    if (mounted) {
      setState(() => _isPressed = false);
    }
  }
}

/// Botón filled con efecto de presión preconfigurado para el tema boutique.
/// 
/// Usa los colores y estilos definidos en AppTheme.
class PressableFilledButton extends StatelessWidget {
  const PressableFilledButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.icon,
    this.label,
  });

  const PressableFilledButton.icon({
    super.key,
    required this.onPressed,
    required this.icon,
    required Widget label,
    this.style,
  })  : child = label,
        label = label;

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final Widget? label;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (icon != null) {
      return PressableButton(
        onPressed: onPressed,
        shadowColor: theme.colorScheme.primary.withValues(alpha: 0.2),
        shadowBlurRadius: 8,
        shadowOffset: const Offset(0, 2),
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: icon!,
          label: child,
          style: style,
        ),
      );
    }
    
    return PressableButton(
      onPressed: onPressed,
      shadowColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      shadowBlurRadius: 8,
      shadowOffset: const Offset(0, 2),
      child: FilledButton(
        onPressed: onPressed,
        style: style,
        child: child,
      ),
    );
  }
}

/// Botón outlined con efecto de presión preconfigurado.
class PressableOutlinedButton extends StatelessWidget {
  const PressableOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.icon,
    this.label,
  });

  const PressableOutlinedButton.icon({
    super.key,
    required this.onPressed,
    required this.icon,
    required Widget label,
    this.style,
  })  : child = label,
        label = label;

  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final Widget? icon;
  final Widget? label;

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return PressableButton(
        onPressed: onPressed,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: icon!,
          label: child,
          style: style,
        ),
      );
    }
    
    return PressableButton(
      onPressed: onPressed,
      child: OutlinedButton(
        onPressed: onPressed,
        style: style,
        child: child,
      ),
    );
  }
}

/// Botón text con efecto de presión preconfigurado.
class PressableTextButton extends StatelessWidget {
  const PressableTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    return PressableButton(
      onPressed: onPressed,
      child: TextButton(
        onPressed: onPressed,
        style: style,
        child: child,
      ),
    );
  }
}
