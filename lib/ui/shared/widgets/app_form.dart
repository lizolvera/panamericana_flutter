import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'app_buttons.dart';
import 'app_input_field.dart';

/// ============================================================================
/// WIDGETS COMPARTIDOS PARA FORMULARIOS (tema boutique)
/// ============================================================================
///
/// - [AppFormHeader]: encabezado con icono en círculo vino + título + descripción.
/// - [AppFormCard]: tarjeta blanca con sombra boutique que envuelve un formulario.
/// - [AppDropdownField]: dropdown con la misma decoración boutique que [AppInputField].
/// - [AppDateField]: campo de fecha (solo lectura) con decoración boutique.
/// - [AppFormActions]: fila de acciones Cancelar / Guardar bien acomodada.
/// - [AppPasswordRequirements]: lista visual de requisitos de contraseña.
/// - [AppStepIndicator]: indicador de pasos para flujos multi-paso.

// ─────────────────────────────────────────────────────────────────────────────
// AppFormHeader
// ─────────────────────────────────────────────────────────────────────────────

/// Encabezado de formulario: icono en círculo + título + descripción opcional.
class AppFormHeader extends StatelessWidget {
  const AppFormHeader({
    super.key,
    required this.icon,
    required this.title,
    this.caption,
    this.iconColor = AppColors.blancoCalido,
    this.iconBackground = AppColors.vino,
  });

  final IconData icon;
  final String title;
  final String? caption;
  final Color iconColor;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: AppTheme.radius14,
            boxShadow: [
              BoxShadow(
                color: AppColors.vinoOscuro.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, size: 22, color: iconColor),
        ),
        AppTheme.widthSpacer14,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.cafeOscuro,
                      letterSpacing: -0.5,
                    ),
              ),
              if (caption != null && caption!.isNotEmpty) ...[
                AppTheme.spacer4,
                Text(
                  caption!,
                  style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.cafeOscuro.withValues(alpha: 0.55),
                        height: 1.4,
                        letterSpacing: 0.2,
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppFormCard
// ─────────────────────────────────────────────────────────────────────────────

/// Tarjeta boutique que envuelve el contenido de un formulario.
///
/// Fondo blancoCalido, radio 20, borde rosaBeigeClaro tenue y sombra boutique.
class AppFormCard extends StatelessWidget {
  const AppFormCard({
    super.key,
    required this.child,
    this.header,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.maxWidth,
  });

  final Widget child;
  final Widget? header;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.blancoCalido,
        borderRadius: AppTheme.radius20,
        border: Border.all(color: AppColors.rosaBeigeClaro.withValues(alpha: 0.7)),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header != null) ...[
            header!,
            AppTheme.spacer20,
            const _FormDivider(),
            AppTheme.spacer20,
          ],
          child,
        ],
      ),
    );

    if (maxWidth != null) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth!),
          child: card,
        ),
      );
    }
    return card;
  }
}

class _FormDivider extends StatelessWidget {
  const _FormDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.rosaBeigeClaro.withValues(alpha: 0.6),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppDropdownField
// ─────────────────────────────────────────────────────────────────────────────

/// Dropdown con la misma decoración boutique que [AppInputField].
///
/// Mantiene el tipo [DropdownButtonFormField] para compatibilidad con tests.
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.validator,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.isExpanded = true,
  });

  final List<DropdownMenuItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const radius = BorderRadius.all(Radius.circular(12));

    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      isExpanded: isExpanded,
      style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.cafeOscuro,
            letterSpacing: 0.2,
          ),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.terracota,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null
            ? IconTheme(
                data: const IconThemeData(color: AppColors.terracota),
                child: prefixIcon!,
              )
            : null,
        filled: true,
        fillColor: AppColors.blancoCalido.withValues(alpha: 0.7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: const OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: AppColors.rosaBeigeClaro),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: AppColors.rosaBeigeClaro),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: AppColors.terracota, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: AppColors.vinoOscuro),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: AppColors.vinoOscuro, width: 1.5),
        ),
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.cafeOscuro.withValues(alpha: 0.75),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.cafeOscuro.withValues(alpha: 0.4),
              letterSpacing: 0.2,
            ),
        errorStyle: const TextStyle(color: AppColors.vinoOscuro),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppDateField
// ─────────────────────────────────────────────────────────────────────────────

/// Campo de fecha de solo lectura con decoración boutique.
///
/// Al tocarlo ejecuta [onTap] (típicamente `showDatePicker`).
/// Muestra la fecha como `día/mes/año`.
class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.labelText,
    this.date,
    this.hintText = 'Selecciona una fecha',
    this.onTap,
    this.enabled = true,
  });

  final String labelText;
  final DateTime? date;
  final String hintText;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const radius = BorderRadius.all(Radius.circular(12));

    final decoration = InputDecoration(
      labelText: labelText,
      prefixIcon: const IconTheme(
        data: IconThemeData(color: AppColors.terracota),
        child: Icon(Icons.calendar_month_outlined),
      ),
      suffixIcon: const Icon(
        Icons.edit_calendar_outlined,
        size: 20,
        color: AppColors.terracota,
      ),
      filled: true,
      fillColor: enabled
          ? AppColors.blancoCalido.withValues(alpha: 0.7)
          : AppColors.rosaBeigeClaro.withValues(alpha: 0.4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.rosaBeigeClaro),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.rosaBeigeClaro),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.terracota, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.rosaBeigeClaro.withValues(alpha: 0.5)),
      ),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
            color: enabled
                ? AppColors.cafeOscuro.withValues(alpha: 0.75)
                : AppColors.cafeOscuro.withValues(alpha: 0.4),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
    );

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: radius,
      child: InputDecorator(
        decoration: decoration,
        child: Text(
          date == null
              ? hintText
              : '${date!.day}/${date!.month}/${date!.year}',
          style: theme.textTheme.bodyMedium?.copyWith(
                color: date == null
                    ? AppColors.cafeOscuro.withValues(alpha: 0.4)
                    : AppColors.cafeOscuro,
                letterSpacing: 0.2,
              ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppFormActions
// ─────────────────────────────────────────────────────────────────────────────

/// Fila de acciones para formularios/diálogos: Cancelar (secundario) + Guardar
/// (primario) lado a lado con el mismo ancho, bien acomodados.
///
/// Si [cancelLabel] es nulo, el botón primario ocupa todo el ancho.
class AppFormActions extends StatelessWidget {
  const AppFormActions({
    super.key,
    required this.primaryLabel,
    this.onPrimary,
    this.cancelLabel,
    this.onCancel,
    this.primaryChild,
    this.spacing = 12,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? cancelLabel;
  final VoidCallback? onCancel;
  final Widget? primaryChild;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final primary = AppPrimaryButton(
      onPressed: onPrimary,
      text: primaryLabel,
      child: primaryChild,
    );

    if (cancelLabel == null) {
      return primary;
    }

    return Row(
      children: [
        Expanded(
          child: AppSecondaryButton(
            onPressed: onCancel,
            text: cancelLabel!,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(child: primary),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppPasswordRequirements
// ─────────────────────────────────────────────────────────────────────────────

/// Caja visual con los requisitos de una contraseña; cada requisito se ilumina
/// con un check cuando la contraseña actual [password] lo cumple.
class AppPasswordRequirements extends StatelessWidget {
  const AppPasswordRequirements({
    super.key,
    required this.password,
    this.minLength = 12,
  });

  final String password;
  final int minLength;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checks = <_Req>[
      _Req('Mínimo $minLength caracteres', password.length >= minLength),
      _Req('Al menos una mayúscula', RegExp(r'[A-Z]').hasMatch(password)),
      _Req('Al menos un número', RegExp(r'\d').hasMatch(password)),
      _Req('Al menos un símbolo', RegExp(r'[^a-zA-Z0-9]').hasMatch(password)),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.fondoGeneral,
        borderRadius: AppTheme.radius12,
        border: Border.all(
          color: AppColors.rosaBeigeClaro.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu contraseña debe incluir:',
            style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.cafeOscuro.withValues(alpha: 0.65),
                  letterSpacing: 0.2,
                ),
          ),
          AppTheme.spacer8,
          for (final c in checks)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    c.ok ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 16,
                    color: c.ok ? AppColors.vino : AppColors.cafeOscuro.withValues(alpha: 0.3),
                  ),
                  AppTheme.widthSpacer8,
                  Text(
                    c.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                          color: c.ok
                              ? AppColors.vinoOscuro
                              : AppColors.cafeOscuro.withValues(alpha: 0.5),
                          fontWeight: c.ok ? FontWeight.w600 : FontWeight.normal,
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

class _Req {
  const _Req(this.label, this.ok);
  final String label;
  final bool ok;
}

// ─────────────────────────────────────────────────────────────────────────────
// AppStepIndicator
// ─────────────────────────────────────────────────────────────────────────────

/// Indicador visual de pasos para flujos multi-paso (ej. recuperación).
class AppStepIndicator extends StatelessWidget {
  const AppStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.labels = const [],
  });

  /// Paso actual (1-based).
  final int currentStep;
  final int totalSteps;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (var i = 1; i <= totalSteps; i++) ...[
          if (i > 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: i <= currentStep
                    ? AppColors.vino
                    : AppColors.rosaBeigeClaro,
              ),
            ),
          _StepDot(
            number: i,
            active: i == currentStep,
            done: i < currentStep,
          ),
          if (labels.length >= i) ...[
            AppTheme.widthSpacer6,
            Flexible(
              child: Text(
                labels[i - 1],
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: i == currentStep ? FontWeight.w700 : FontWeight.w500,
                      color: i <= currentStep
                          ? AppColors.vino
                          : AppColors.cafeOscuro.withValues(alpha: 0.4),
                      letterSpacing: 0.2,
                    ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.number,
    required this.active,
    required this.done,
  });

  final int number;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: active || done ? AppColors.vino : AppColors.blancoCalido,
        shape: BoxShape.circle,
        border: Border.all(
          color: active || done ? AppColors.vino : AppColors.rosaBeigeClaro,
          width: 1.5,
        ),
      ),
      child: Center(
        child: done
            ? const Icon(Icons.check, size: 14, color: AppColors.blancoCalido)
            : Text(
                '$number',
                style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: active
                          ? AppColors.blancoCalido
                          : AppColors.cafeOscuro.withValues(alpha: 0.4),
                    ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppSectionLabel (interno de formularios)
// ─────────────────────────────────────────────────────────────────────────────

/// Etiqueta de sección dentro de un formulario (ej. "Dirección", "Seguridad").
class AppFormSectionLabel extends StatelessWidget {
  const AppFormSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: AppColors.terracota,
            ),
      ),
    );
  }
}

/// Helper para construir un campo de formulario boutique con formatter
/// opcional y límite de caracteres, evitando repetir parámetros.
class AppFormField extends StatelessWidget {
  const AppFormField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.inputFormatters = const [],
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
    this.autofillHints = const [],
    this.counterText = '',
  });

  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter> inputFormatters;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final bool enabled;
  final List<String> autofillHints;
  final String counterText;

  @override
  Widget build(BuildContext context) {
    return AppInputField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      autofillHints: autofillHints,
      counterText: counterText,
      enabled: enabled,
    );
  }
}
