import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Configuración del tema Material 3 para Panamericana / Barbería y Cuidado Personal.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.fondoGeneral,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.vino,
        onPrimary: AppColors.blancoCalido,
        primaryContainer: AppColors.rosaBeigeClaro,
        onPrimaryContainer: AppColors.vinoOscuro,
        secondary: AppColors.terracota,
        onSecondary: AppColors.blancoCalido,
        secondaryContainer: AppColors.rosaBeigeClaro,
        onSecondaryContainer: AppColors.cafeOscuro,
        surface: AppColors.blancoCalido,
        onSurface: AppColors.cafeOscuro,
        surfaceContainerHighest: AppColors.rosaBeigeClaro,
        error: AppColors.vinoOscuro,
        onError: AppColors.blancoCalido,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.blancoCalido,
        foregroundColor: AppColors.cafeOscuro,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.cafeOscuro),
        titleTextStyle: TextStyle(
          color: AppColors.cafeOscuro,
          fontSize: 19,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.blancoCalido,
        elevation: 1,
        shadowColor: AppColors.cafeOscuro.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.rosaBeigeClaro, width: 0.8),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.vino,
          foregroundColor: AppColors.blancoCalido,
          elevation: 1.5,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.vino,
          side: const BorderSide(color: AppColors.vino, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.vino,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.blancoCalido,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: AppColors.cafeOscuro),
        hintStyle: TextStyle(color: AppColors.cafeOscuro.withValues(alpha: 0.5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.rosaBeigeClaro),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.rosaBeigeClaro),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.vino, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.blancoCalido,
        indicatorColor: AppColors.rosaBeigeClaro.withValues(alpha: 0.7),
        elevation: 3,
        shadowColor: AppColors.cafeOscuro.withValues(alpha: 0.1),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.vinoOscuro);
          }
          return const IconThemeData(color: AppColors.cafeOscuro);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.vinoOscuro,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            );
          }
          return const TextStyle(
            color: AppColors.cafeOscuro,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.rosaBeigeClaro,
        thickness: 1,
      ),
    );
  }
}
