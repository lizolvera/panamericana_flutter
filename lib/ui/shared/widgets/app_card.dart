import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Tarjeta con estilo boutique preconfigurado.
/// 
/// Usa el cardTheme del tema con:
/// - borderRadius: 20
/// - color: blancoCalido
/// - elevation: 0
/// - shadowColor: vinoOscuro (alpha: 0.08)
/// - sin borde visible
/// 
/// Se puede personalizar el contenido y el padding.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.elevation,
    this.shadowColor,
    this.shape,
    this.color,
    this.onTap,
    this.onLongPress,
  });

  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final Color? shadowColor;
  final RoundedRectangleBorder? shape;
  final Color? color;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardShape = shape ?? theme.cardTheme.shape as RoundedRectangleBorder?;
    final inkWellBorderRadius = cardShape?.borderRadius ?? BorderRadius.circular(20);
    
    return Card(
      margin: margin,
      elevation: elevation,
      shadowColor: shadowColor ?? AppTheme.cardShadow.color,
      shape: cardShape,
      color: color ?? theme.cardTheme.color,
      child: onTap != null || onLongPress != null
          ? InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              borderRadius: inkWellBorderRadius as BorderRadius,
              child: Padding(
                padding: padding ?? EdgeInsets.zero,
                child: child,
              ),
            )
          : Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
    );
  }
}

/// Tarjeta con borde personalizado (para inputs y contenedores especiales)
class AppOutlineCard extends StatelessWidget {
  const AppOutlineCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.borderColor = AppColors.rosaBeigeClaro,
    this.backgroundColor = AppColors.blancoCalido,
    this.elevation = 0,
    this.shadowColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius borderRadius;
  final Color borderColor;
  final Color backgroundColor;
  final double elevation;
  final Color? shadowColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      elevation: elevation,
      shadowColor: shadowColor,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: borderColor),
      ),
      color: backgroundColor,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: borderRadius,
              child: Padding(
                padding: padding ?? EdgeInsets.zero,
                child: child,
              ),
            )
          : Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
    );
  }
}
