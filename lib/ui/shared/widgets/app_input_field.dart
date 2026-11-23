import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';

/// Campo de entrada con estilo boutique.
/// 
/// Usa:
/// - fillColor: blancoCalido a 70%
/// - borderRadius: 12
/// - borderSide: transparente
/// - enabledBorder: transparente
/// - focusedBorder: terracota, width 1.5
/// - prefixIcon/suffixIcon: color terracota
/// - hintStyle: cafeOscuro alpha 0.4
/// - contentPadding: symmetric(horizontal: 16, vertical: 14)
class AppInputField extends StatelessWidget {
  const AppInputField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints = const [],
    this.inputFormatters = const [],
    this.maxLength,
    this.counterText = '',
    this.style,
    this.hintStyle,
    this.textAlign = TextAlign.start,
    this.readOnly = false,
    this.enabled = true,
    this.focusNode,
    this.cursorColor,
    this.fillColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.borderSideColor = AppColors.rosaBeigeClaro,
    this.focusedBorderColor = AppColors.terracota,
    this.iconColor = AppColors.terracota,
  });

  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final TextCapitalization textCapitalization;
  final List<String> autofillHints;
  final List<TextInputFormatter> inputFormatters;
  final int? maxLength;
  final String counterText;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final TextAlign textAlign;
  final bool readOnly;
  final bool enabled;
  final FocusNode? focusNode;
  final Color? cursorColor;
  final Color? fillColor;
  final BorderRadius borderRadius;
  final Color borderSideColor;
  final Color focusedBorderColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inputTheme = theme.inputDecorationTheme;
    
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      textCapitalization: textCapitalization,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      textAlign: textAlign,
      readOnly: readOnly,
      enabled: enabled,
      focusNode: focusNode,
      cursorColor: cursorColor ?? theme.colorScheme.primary,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: style ?? theme.textTheme.bodyMedium?.copyWith(
            letterSpacing: 0.2,
          ),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        prefixIcon: prefixIcon != null 
            ? IconTheme(
                data: IconThemeData(color: iconColor),
                child: prefixIcon!,
              )
            : null,
        suffixIcon: suffixIcon != null
            ? IconTheme(
                data: IconThemeData(color: iconColor),
                child: suffixIcon!,
              )
            : null,
        filled: true,
        fillColor: fillColor ?? AppColors.blancoCalido.withValues(alpha: 0.7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: borderSideColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: borderSideColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: focusedBorderColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: AppColors.vinoOscuro),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: AppColors.vinoOscuro, width: 1.5),
        ),
        hintStyle: hintStyle ?? inputTheme.hintStyle?.copyWith(
              color: AppColors.cafeOscuro.withValues(alpha: 0.4),
            ),
        errorStyle: const TextStyle(color: AppColors.vinoOscuro),
        counterText: counterText,
      ),
    );
  }
}

/// Campo de entrada para código 2FA
class AppCodeInputField extends StatelessWidget {
  const AppCodeInputField({
    super.key,
    required this.controller,
    this.length = 6,
    this.hintText = '------',
    this.focusedBorderColor = AppColors.vino,
    this.textStyle,
    this.hintStyle,
  });

  final TextEditingController controller;
  final int length;
  final String hintText;
  final Color focusedBorderColor;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;

  @override
  Widget build(BuildContext context) {
    return AppInputField(
      controller: controller,
      hintText: hintText,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: length,
      counterText: '',
      focusedBorderColor: focusedBorderColor,
      style: textStyle ?? const TextStyle(
        letterSpacing: 10,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.vinoOscuro,
      ),
      hintStyle: hintStyle ?? TextStyle(
        color: AppColors.cafeOscuro.withValues(alpha: 0.3),
        letterSpacing: 8,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(length),
      ],
    );
  }
}
