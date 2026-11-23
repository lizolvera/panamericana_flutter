import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Encabezado de sección con tipografía Playfair Display.
/// 
/// Usa el textTheme del tema para aplicar estilos consistentes.
/// 
/// Variantes:
/// - title: Título principal (headlineSmall)
/// - subtitle: Subtítulo (titleMedium o bodyLarge)
/// - caption: Texto descriptivo (bodyMedium)
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.caption,
    this.textAlign = TextAlign.center,
    this.titleStyle,
    this.subtitleStyle,
    this.captionStyle,
    this.spacing = 6.0,
    this.captionAlpha = 0.6,
  });

  final String title;
  final String? subtitle;
  final String? caption;
  final TextAlign textAlign;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final TextStyle? captionStyle;
  final double spacing;
  final double captionAlpha;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: textAlign == TextAlign.center 
          ? CrossAxisAlignment.center 
          : CrossAxisAlignment.start,
      children: [
        // Título principal
        Text(
          title,
          textAlign: textAlign,
          style: titleStyle ?? theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.cafeOscuro,
              ),
        ),
        
        // Subtítulo
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          SizedBox(height: spacing),
          Text(
            subtitle!,
            textAlign: textAlign,
            style: subtitleStyle ?? theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.terracota,
                ),
          ),
        ],
        
        // Descripción/Caption
        if (caption != null && caption!.isNotEmpty) ...[
          SizedBox(height: spacing),
          Text(
            caption!,
            textAlign: textAlign,
            style: captionStyle ?? theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.cafeOscuro.withValues(alpha: captionAlpha),
                  height: 1.4,
                  letterSpacing: 0.2,
                ),
          ),
        ],
      ],
    );
  }
}

/// Encabezado simple con solo título
class AppTitle extends StatelessWidget {
  const AppTitle(
    this.text, {
      super.key,
      this.textAlign = TextAlign.center,
      this.style,
      this.color,
    }
  );

  final String text;
  final TextAlign textAlign;
  final TextStyle? style;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Text(
      text,
      textAlign: textAlign,
      style: style ?? theme.textTheme.headlineSmall?.copyWith(
            color: color ?? AppColors.cafeOscuro,
          ),
    );
  }
}

/// Subtítulo con estilo terracota
class AppSubtitle extends StatelessWidget {
  const AppSubtitle(
    this.text, {
      super.key,
      this.textAlign = TextAlign.center,
      this.style,
      this.color = AppColors.terracota,
    }
  );

  final String text;
  final TextAlign textAlign;
  final TextStyle? style;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Text(
      text,
      textAlign: textAlign,
      style: style ?? theme.textTheme.titleMedium?.copyWith(
            color: color,
            letterSpacing: 0.2,
          ),
    );
  }
}

/// Texto descriptivo con alpha reducido
class AppCaption extends StatelessWidget {
  const AppCaption(
    this.text, {
      super.key,
      this.textAlign = TextAlign.center,
      this.style,
      this.alpha = 0.6,
      this.height = 1.4,
    }
  );

  final String text;
  final TextAlign textAlign;
  final TextStyle? style;
  final double alpha;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Text(
      text,
      textAlign: textAlign,
      style: style ?? theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.cafeOscuro.withValues(alpha: alpha),
            height: height,
            letterSpacing: 0.2,
          ),
    );
  }
}
