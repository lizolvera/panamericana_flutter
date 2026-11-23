import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Configuración del tema Material 3 para Panamericana - Estilo "boutique moderna"
/// 
/// Paleta: rosa empolvado, vino y terracota
/// Tipografía: Playfair Display (headlines) + Inter (cuerpo/UI)
/// Formas: radios generosos (cards 20, botones 14), chips pill
/// Sombras: vinoOscuro con alpha bajo, blur 24, offset (0,8)
/// Feedback: splash rosaPalo, highlight terracota
/// Espaciado: múltiplos de 8 (8/16/24/32)
class AppTheme {
  AppTheme._();

  /// Verifica si estamos en modo web o si GoogleFonts tiene el fetching deshabilitado (modo test)
  /// En web, deshabilitamos GoogleFonts para evitar fallos de red
  static bool get _shouldUseFallbackFonts {
    try {
      return kIsWeb || !GoogleFonts.config.allowRuntimeFetching;
    } catch (_) {
      return kIsWeb;
    }
  }


  // ===========================================================================
  // TEXT STYLES - Playfair Display para headlines, Inter para cuerpo
  // ===========================================================================

  static TextStyle _playfairStyle({
    FontWeight weight = FontWeight.w600,
    double? fontSize,
    Color? color,
    double letterSpacing = -0.5,
    double? height,
  }) {
    if (_shouldUseFallbackFonts) {
      // En modo test, usamos Roboto (ya cargada en golden tests) para evitar descargar fuentes
      return TextStyle(
        fontFamily: 'Roboto',
        fontWeight: weight,
        fontSize: fontSize,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    }
    return GoogleFonts.playfairDisplay(
      fontWeight: weight,
      fontSize: fontSize,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle _interStyle({
    FontWeight weight = FontWeight.normal,
    double? fontSize,
    Color? color,
    double letterSpacing = 0.2,
    double? height,
  }) {
    if (_shouldUseFallbackFonts) {
      // En modo test, usamos Roboto (ya cargada en golden tests) para evitar descargar fuentes
      return TextStyle(
        fontFamily: 'Roboto',
        fontWeight: weight,
        fontSize: fontSize,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    }
    return GoogleFonts.inter(
      fontWeight: weight,
      fontSize: fontSize,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  // ===========================================================================
  // THEME DATA
  // ===========================================================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.fondoGeneral,
      
      // =======================================================================
      // COLOR SCHEME - NO MODIFICAR (según restricción)
      // =======================================================================
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
      
      // =======================================================================
      // TYPOGRAPHY
      // =======================================================================
      fontFamily: _shouldUseFallbackFonts ? 'Roboto' : GoogleFonts.inter().fontFamily,
      textTheme: TextTheme(
        // Headlines con Playfair Display
        displayLarge: _playfairStyle(
          weight: FontWeight.w700,
          fontSize: 57,
          color: AppColors.cafeOscuro,
          letterSpacing: -0.5,
        ),
        displayMedium: _playfairStyle(
          weight: FontWeight.w700,
          fontSize: 45,
          color: AppColors.cafeOscuro,
          letterSpacing: -0.5,
        ),
        displaySmall: _playfairStyle(
          weight: FontWeight.w700,
          fontSize: 36,
          color: AppColors.cafeOscuro,
          letterSpacing: -0.5,
        ),
        headlineLarge: _playfairStyle(
          weight: FontWeight.w700,
          fontSize: 32,
          color: AppColors.cafeOscuro,
          letterSpacing: -0.5,
        ),
        headlineMedium: _playfairStyle(
          weight: FontWeight.w700,
          fontSize: 28,
          color: AppColors.cafeOscuro,
          letterSpacing: -0.5,
        ),
        headlineSmall: _playfairStyle(
          weight: FontWeight.w600,
          fontSize: 24,
          color: AppColors.cafeOscuro,
          letterSpacing: -0.5,
        ),
        titleLarge: _playfairStyle(
          weight: FontWeight.w600,
          fontSize: 22,
          color: AppColors.cafeOscuro,
          letterSpacing: -0.5,
        ),
        titleMedium: _interStyle(
          weight: FontWeight.w600,
          fontSize: 16,
          color: AppColors.cafeOscuro,
          letterSpacing: 0.2,
        ),
        titleSmall: _interStyle(
          weight: FontWeight.w600,
          fontSize: 14,
          color: AppColors.cafeOscuro,
          letterSpacing: 0.2,
        ),
        bodyLarge: _interStyle(
          weight: FontWeight.normal,
          fontSize: 16,
          color: AppColors.cafeOscuro,
          letterSpacing: 0.2,
          height: 1.4,
        ),
        bodyMedium: _interStyle(
          weight: FontWeight.normal,
          fontSize: 14,
          color: AppColors.cafeOscuro,
          letterSpacing: 0.2,
          height: 1.35,
        ),
        bodySmall: _interStyle(
          weight: FontWeight.normal,
          fontSize: 12,
          color: AppColors.cafeOscuro,
          letterSpacing: 0.2,
          height: 1.3,
        ),
        labelLarge: _interStyle(
          weight: FontWeight.w600,
          fontSize: 14,
          color: AppColors.cafeOscuro,
          letterSpacing: 0.2,
        ),
        labelMedium: _interStyle(
          weight: FontWeight.w500,
          fontSize: 12,
          color: AppColors.cafeOscuro,
          letterSpacing: 0.2,
        ),
        labelSmall: _interStyle(
          weight: FontWeight.w500,
          fontSize: 10,
          color: AppColors.cafeOscuro,
          letterSpacing: 0.2,
        ),
      ),
      
      // =======================================================================
      // APP BAR THEME
      // =======================================================================
      appBarTheme: const AppBarTheme(
        // Para AppBar estándar (detalle): fondo blancoCalido
        backgroundColor: AppColors.blancoCalido,
        foregroundColor: AppColors.cafeOscuro,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.cafeOscuro),
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.cafeOscuro,
          letterSpacing: -0.5,
        ),
      ),
      
      // =======================================================================
      // CARD THEME
      // =======================================================================
      cardTheme: CardThemeData(
        color: AppColors.blancoCalido,
        elevation: 0,
        // Sombra boutique: vinoOscuro con alpha 0.08
        shadowColor: AppColors.vinoOscuro.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          // Sin borde visible
          side: BorderSide.none,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // =======================================================================
      // BUTTON THEMES
      // =======================================================================
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.vino,
          foregroundColor: AppColors.blancoCalido,
          elevation: 0,
          // Sombra boutique para botones
          shadowColor: AppColors.vinoOscuro.withValues(alpha: 0.08),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: _interStyle(
            weight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.blancoCalido,
            letterSpacing: 0.2,
          ),
          // Feedback táctil boutique
          splashFactory: InkSplash.splashFactory,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.vino,
          side: const BorderSide(color: AppColors.vino, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: _interStyle(
            weight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.vino,
            letterSpacing: 0.2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.vino,
          textStyle: _interStyle(
            weight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.vino,
            letterSpacing: 0.2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      
      // =======================================================================
      // INPUT DECORATION THEME
      // =======================================================================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // Fill color al 70% de opacidad
        fillColor: AppColors.blancoCalido.withValues(alpha: 0.7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: _interStyle(
          weight: FontWeight.w500,
          fontSize: 14,
          color: AppColors.cafeOscuro,
          letterSpacing: 0.2,
        ),
        hintStyle: _interStyle(
          weight: FontWeight.normal,
          fontSize: 14,
          color: AppColors.cafeOscuro.withValues(alpha: 0.5),
          letterSpacing: 0.2,
        ),
        // Sin borde completo - borde transparente
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        // Borde inferior en terracota al enfocarse
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.terracota,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.vinoOscuro),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.vinoOscuro, width: 1.5),
        ),
      ),
      
      // =======================================================================
      // CHIP THEME - Pill shape (StadiumBorder)
      // =======================================================================
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        backgroundColor: AppColors.blancoCalido,
        labelStyle: _interStyle(
          weight: FontWeight.w500,
          fontSize: 12,
          color: AppColors.cafeOscuro,
          letterSpacing: 0.2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        secondaryLabelStyle: _interStyle(
          weight: FontWeight.w600,
          fontSize: 12,
          color: AppColors.blancoCalido,
          letterSpacing: 0.2,
        ),
        brightness: Brightness.light,
      ),
      
      // =======================================================================
      // DIALOG THEME
      // =======================================================================
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.blancoCalido,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: _playfairStyle(
          weight: FontWeight.w700,
          fontSize: 20,
          color: AppColors.cafeOscuro,
          letterSpacing: -0.5,
        ),
        contentTextStyle: _interStyle(
          weight: FontWeight.normal,
          fontSize: 14,
          color: AppColors.cafeOscuro,
          letterSpacing: 0.2,
        ),
      ),
      
      // =======================================================================
      // NAVIGATION BAR THEME
      // =======================================================================
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.blancoCalido,
        indicatorColor: AppColors.rosaBeigeClaro,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.vinoOscuro);
          }
          return const IconThemeData(color: AppColors.cafeOscuro);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _interStyle(
              weight: FontWeight.w600,
              fontSize: 12,
              color: AppColors.vinoOscuro,
              letterSpacing: 0.2,
            );
          }
          return _interStyle(
            weight: FontWeight.w500,
            fontSize: 12,
            color: AppColors.cafeOscuro,
            letterSpacing: 0.2,
          );
        }),
      ),
      
      // =======================================================================
      // FLOATING ACTION BUTTON
      // =======================================================================
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.vino,
        foregroundColor: AppColors.blancoCalido,
        elevation: 0,
        shape: const CircleBorder(),
        extendedTextStyle: _interStyle(
          weight: FontWeight.w600,
          fontSize: 14,
          color: AppColors.blancoCalido,
          letterSpacing: 0.2,
        ),
      ),
      
      // =======================================================================
      // PROGRESS INDICATOR
      // =======================================================================
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.vino,
        linearTrackColor: AppColors.rosaBeigeClaro,
        circularTrackColor: AppColors.rosaBeigeClaro,
      ),
      
      // =======================================================================
      // BOTTOM APP BAR THEME
      // =======================================================================
      bottomAppBarTheme: BottomAppBarThemeData(
        color: AppColors.blancoCalido,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // =======================================================================
      // DIVIDER THEME - No usar Divider gris, usar SizedBox
      // =======================================================================
      dividerTheme: DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
        space: 0,
      ),
      
      // =======================================================================
      // SNACKBAR THEME
      // =======================================================================
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.vino,
        contentTextStyle: _interStyle(
          weight: FontWeight.w500,
          fontSize: 14,
          color: AppColors.blancoCalido,
          letterSpacing: 0.2,
        ),
        actionTextColor: AppColors.rosaBeigeClaro,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
      
      // =======================================================================
      // BADGE THEME
      // =======================================================================
      badgeTheme: BadgeThemeData(
        backgroundColor: AppColors.vino,
        textStyle: _interStyle(
          weight: FontWeight.w700,
          fontSize: 11,
          color: AppColors.blancoCalido,
          letterSpacing: 0.2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      
      // =======================================================================
      // FEEDBACK TÁCTIL - Colores boutique
      // =======================================================================
      splashColor: AppColors.rosaPalo.withValues(alpha: 0.3),
      highlightColor: AppColors.terracota.withValues(alpha: 0.15),
      hoverColor: AppColors.rosaPalo.withValues(alpha: 0.1),
      
      // =======================================================================
      // LIST TILE THEME
      // =======================================================================
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        titleTextStyle: _interStyle(
          weight: FontWeight.w600,
          fontSize: 16,
          color: AppColors.cafeOscuro,
          letterSpacing: 0.2,
        ),
        subtitleTextStyle: _interStyle(
          weight: FontWeight.normal,
          fontSize: 14,
          color: AppColors.cafeOscuro.withValues(alpha: 0.6),
          letterSpacing: 0.2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        selectedTileColor: AppColors.rosaBeigeClaro,
      ),
      
      // =======================================================================
      // SWITCH THEME
      // =======================================================================
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.vino;
          }
          return AppColors.rosaBeigeClaro;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.vino.withValues(alpha: 0.3);
          }
          return AppColors.rosaBeigeClaro;
        }),
      ),
      
      // =======================================================================
      // CHECKBOX THEME
      // =======================================================================
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.vino;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.blancoCalido),
        side: const BorderSide(color: AppColors.terracota),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      
      // =======================================================================
      // RADIO THEME
      // =======================================================================
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.vino;
          }
          return Colors.transparent;
        }),
      ),
      
      // =======================================================================
      // TAB BAR THEME
      // =======================================================================
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.vino,
        unselectedLabelColor: AppColors.cafeOscuro.withValues(alpha: 0.5),
        indicator: UnderlineTabIndicator(
          borderSide: const BorderSide(color: AppColors.vino, width: 2),
          insets: const EdgeInsets.symmetric(horizontal: 16),
        ),
        labelStyle: _interStyle(
          weight: FontWeight.w600,
          fontSize: 14,
          color: AppColors.vino,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: _interStyle(
          weight: FontWeight.normal,
          fontSize: 14,
          color: AppColors.cafeOscuro,
          letterSpacing: 0.2,
        ),
      ),
      
      // =======================================================================
      // TOOLTIP THEME
      // =======================================================================
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.vinoOscuro,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: _interStyle(
          weight: FontWeight.normal,
          fontSize: 12,
          color: AppColors.blancoCalido,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // ===========================================================================
  // SLIVER APP BAR UTILITIES - Para pantallas principales
  // ===========================================================================
  
  /// Gradiente para flexibleSpace de SliverAppBar
  static const LinearGradient sliverAppBarGradient = LinearGradient(
    colors: [AppColors.vino, AppColors.vinoOscuro],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===========================================================================
  // SHADOW UTILITIES
  // ===========================================================================
  
  /// Sombra boutique principal para cards
  static BoxShadow get cardShadow {
    return BoxShadow(
      color: AppColors.vinoOscuro.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    );
  }

  /// Sombra boutique para botones
  static BoxShadow get buttonShadow {
    return BoxShadow(
      color: AppColors.vinoOscuro.withValues(alpha: 0.12),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    );
  }

  // ===========================================================================
  // PADDING UTILITIES - Múltiplos de 8
  // ===========================================================================
  
  static const EdgeInsets padding6 = EdgeInsets.all(6);
  static const EdgeInsets padding8 = EdgeInsets.all(8);
  static const EdgeInsets padding10 = EdgeInsets.all(10);
  static const EdgeInsets padding12 = EdgeInsets.all(12);
  static const EdgeInsets padding16 = EdgeInsets.all(16);
  static const EdgeInsets padding20 = EdgeInsets.all(20);
  static const EdgeInsets padding24 = EdgeInsets.all(24);
  static const EdgeInsets padding28 = EdgeInsets.all(28);
  static const EdgeInsets padding32 = EdgeInsets.all(32);
  
  static const EdgeInsets padding4 = EdgeInsets.all(4);
  
  static const EdgeInsets horizontal4 = EdgeInsets.symmetric(horizontal: 4);
  static const EdgeInsets horizontal6 = EdgeInsets.symmetric(horizontal: 6);
  static const EdgeInsets horizontal8 = EdgeInsets.symmetric(horizontal: 8);
  static const EdgeInsets horizontal10 = EdgeInsets.symmetric(horizontal: 10);
  static const EdgeInsets horizontal12 = EdgeInsets.symmetric(horizontal: 12);
  static const EdgeInsets horizontal14 = EdgeInsets.symmetric(horizontal: 14);
  static const EdgeInsets horizontal16 = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets horizontal24 = EdgeInsets.symmetric(horizontal: 24);
  static const EdgeInsets horizontal32 = EdgeInsets.symmetric(horizontal: 32);
  
  static const EdgeInsets vertical4 = EdgeInsets.symmetric(vertical: 4);
  static const EdgeInsets vertical6 = EdgeInsets.symmetric(vertical: 6);
  static const EdgeInsets vertical8 = EdgeInsets.symmetric(vertical: 8);
  static const EdgeInsets vertical12 = EdgeInsets.symmetric(vertical: 12);
  static const EdgeInsets vertical16 = EdgeInsets.symmetric(vertical: 16);
  static const EdgeInsets vertical24 = EdgeInsets.symmetric(vertical: 24);
  static const EdgeInsets vertical32 = EdgeInsets.symmetric(vertical: 32);

  // ===========================================================================
  // ESPACIADO - SizedBox Utilities
  // ===========================================================================
  
  static const SizedBox spacer2 = SizedBox(height: 2);
  static const SizedBox spacer4 = SizedBox(height: 4);
  static const SizedBox spacer5 = SizedBox(height: 5);
  static const SizedBox spacer6 = SizedBox(height: 6);
  static const SizedBox spacer8 = SizedBox(height: 8);
  static const SizedBox spacer10 = SizedBox(height: 10);
  static const SizedBox spacer12 = SizedBox(height: 12);
  static const SizedBox spacer14 = SizedBox(height: 14);
  static const SizedBox spacer16 = SizedBox(height: 16);
  static const SizedBox spacer20 = SizedBox(height: 20);
  static const SizedBox spacer24 = SizedBox(height: 24);
  static const SizedBox spacer28 = SizedBox(height: 28);
  static const SizedBox spacer32 = SizedBox(height: 32);
  
  static const SizedBox widthSpacer4 = SizedBox(width: 4);
  static const SizedBox widthSpacer6 = SizedBox(width: 6);
  static const SizedBox widthSpacer8 = SizedBox(width: 8);
  static const SizedBox widthSpacer10 = SizedBox(width: 10);
  static const SizedBox widthSpacer12 = SizedBox(width: 12);
  static const SizedBox widthSpacer14 = SizedBox(width: 14);
  static const SizedBox widthSpacer16 = SizedBox(width: 16);
  static const SizedBox widthSpacer20 = SizedBox(width: 20);
  static const SizedBox widthSpacer24 = SizedBox(width: 24);
  static const SizedBox widthSpacer32 = SizedBox(width: 32);

  // ===========================================================================
  // BORDER RADIUS UTILITIES
  // ===========================================================================
  
  static const BorderRadius radius4 = BorderRadius.all(Radius.circular(4));
  static const BorderRadius radius6 = BorderRadius.all(Radius.circular(6));
  static const BorderRadius radius8 = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radius10 = BorderRadius.all(Radius.circular(10));
  static const BorderRadius radius12 = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radius14 = BorderRadius.all(Radius.circular(14));
  static const BorderRadius radius16 = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radius20 = BorderRadius.all(Radius.circular(20));
  
  /// Sombra boutique principal (alias de cardShadow para consistencia)
  static BoxShadow get shadowBoutique => cardShadow;
}
