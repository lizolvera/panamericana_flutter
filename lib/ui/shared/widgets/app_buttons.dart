import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'pressable_button.dart';

/// Botón primario con estilo boutique (vino/blancoCalido).
/// 
/// Usa:
/// - backgroundColor: AppColors.vino
/// - foregroundColor: AppColors.blancoCalido
/// - borderRadius: 14
/// - textStyle: Inter w600, size 16
/// - minimumSize: 52 de altura
/// - splashColor: rosaPalo (del tema)
/// - highlightColor: terracota (del tema)
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.onPressed,
    this.text,
    this.child,
    this.minHeight = 52,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    this.textStyle,
    this.shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
    ),
  });

  const AppPrimaryButton.icon({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.text,
    this.minHeight = 52,
    this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    this.textStyle,
    this.shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
    ),
  });

  final VoidCallback? onPressed;
  final String? text;
  final Widget? child;
  final double minHeight;
  final Widget? icon;
  final EdgeInsetsGeometry padding;
  final TextStyle? textStyle;
  final OutlinedBorder shape;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonChild = child ?? (text != null ? Text(text!) : const SizedBox());
    
    if (icon != null) {
      return PressableFilledButton.icon(
        onPressed: onPressed,
        icon: icon!,
        label: buttonChild,
        style: FilledButton.styleFrom(
          minimumSize: Size.fromHeight(minHeight),
          backgroundColor: AppColors.vino,
          foregroundColor: AppColors.blancoCalido,
          shape: shape,
          padding: padding,
          textStyle: textStyle ?? theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: 0.2,
              ),
        ),
      );
    }
    
    return PressableFilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: Size.fromHeight(minHeight),
        backgroundColor: AppColors.vino,
        foregroundColor: AppColors.blancoCalido,
        shape: shape,
        padding: padding,
        textStyle: textStyle ?? theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              letterSpacing: 0.2,
            ),
      ),
      child: buttonChild,
    );
  }
}

/// Botón secundario con estilo boutique (vino/blancoCalido).
/// 
/// Usa:
/// - foregroundColor: AppColors.vino
/// - side: BorderSide color AppColors.vino, width 1.2
/// - borderRadius: 14
/// - textStyle: Inter w600, size 14
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.minHeight = 48,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.textStyle,
    this.shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
    ),
  });

  const AppSecondaryButton.icon({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.text,
    this.minHeight = 48,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.textStyle,
    this.shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
    ),
  });

  final VoidCallback? onPressed;
  final String text;
  final double minHeight;
  final Widget? icon;
  final EdgeInsetsGeometry padding;
  final TextStyle? textStyle;
  final OutlinedBorder shape;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (icon != null) {
      return PressableOutlinedButton.icon(
        onPressed: onPressed,
        icon: icon!,
        label: Text(text),
        style: OutlinedButton.styleFrom(
          minimumSize: Size.fromHeight(minHeight),
          foregroundColor: AppColors.vino,
          side: const BorderSide(color: AppColors.vino, width: 1.2),
          shape: shape,
          padding: padding,
          textStyle: textStyle ?? theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
        ),
      );
    }
    
    return PressableOutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: Size.fromHeight(minHeight),
        foregroundColor: AppColors.vino,
        side: const BorderSide(color: AppColors.vino, width: 1.2),
        shape: shape,
        padding: padding,
        textStyle: textStyle ?? theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.2,
            ),
      ),
      child: Text(text),
    );
  }
}

/// Botón de texto con estilo boutique (vino o terracota).
/// 
/// Usa:
/// - foregroundColor: color especificado (default: AppColors.vino)
/// - textStyle: Inter w600, size 14
class AppTextButton extends StatelessWidget {
  const AppTextButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.color = AppColors.vino,
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  final VoidCallback? onPressed;
  final String text;
  final Color color;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return PressableTextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: padding,
        textStyle: textStyle ?? theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.2,
            ),
      ),
      child: Text(text),
    );
  }
}

/// Botón de icono con estilo primario
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.color = AppColors.vino,
    this.size = 24.0,
    this.padding = const EdgeInsets.all(8),
    this.tooltip,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final Color color;
  final double size;
  final EdgeInsetsGeometry padding;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: size, color: color),
      padding: padding,
      tooltip: tooltip,
    );
  }
}

/// Divisor con estilo boutique (rosaBeigeClaro)
class AppDivider extends StatelessWidget {
  const AppDivider({
    super.key,
    this.color = AppColors.rosaBeigeClaro,
    this.thickness = 1.2,
    this.height = 1.0,
    this.alpha = 0.8,
  });

  final Color color;
  final double thickness;
  final double height;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Divider(
        color: color.withValues(alpha: alpha),
        thickness: thickness,
      ),
    );
  }
}

/// Row divisor con texto en el centro (ej: "o")
class AppOrDivider extends StatelessWidget {
  const AppOrDivider({
    super.key,
    this.text = 'o',
    this.color = AppColors.rosaBeigeClaro,
    this.thickness = 1.2,
    this.textColor,
    this.textStyle,
    this.alpha = 0.8,
    this.horizontalPadding = 14.0,
  });

  final String text;
  final Color color;
  final double thickness;
  final Color? textColor;
  final TextStyle? textStyle;
  final double alpha;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        const Expanded(child: SizedBox()),
        AppDivider(color: color, thickness: thickness, alpha: alpha),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Text(
            text,
            style: textStyle ?? theme.textTheme.bodyMedium?.copyWith(
                  color: textColor ?? AppColors.cafeOscuro.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
          ),
        ),
        AppDivider(color: color, thickness: thickness, alpha: alpha),
        const Expanded(child: SizedBox()),
      ],
    );
  }
}
