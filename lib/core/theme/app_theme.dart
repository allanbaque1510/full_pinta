import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sistema de diseño "Urban Beauty & Grooming" (ver `design/`, generado con
/// una IA de diseño y adoptado como identidad de FullPinta): obsidiana
/// multi-capa + persimmon cálido, con un toque de lavanda y menta para
/// balancear — pensado para sentirse urbano y unisex, no una app clínica
/// ni una app financiera. Dark-mode-first a propósito: es la identidad,
/// no una opción secundaria.
class AppColors {
  AppColors._();

  static const Color primario = Color(0xFFFB5B36); // persimmon — CTAs, estados activos
  static const Color exito = Color(0xFF3CDDC7); // menta — completada, disponible, positivo
  static const Color peligro = Color(0xFFFFB4AB); // legible sobre fondo oscuro
  static const Color advertencia = Color(0xFFFFB74D); // hold / pendiente
  static const Color textoSecundario = Color(0xFF9CA3AF);
}

class AppTheme {
  AppTheme._();

  static final ColorScheme _oscuro = const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFB5B36),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFB4A3),
    onPrimaryContainer: Color(0xFF630F00),
    secondary: Color(0xFFCEBEFA),
    onSecondary: Color(0xFF35285A),
    secondaryContainer: Color(0xFF4E4174),
    onSecondaryContainer: Color(0xFFC0B0EB),
    tertiary: Color(0xFF3CDDC7),
    onTertiary: Color(0xFF003731),
    tertiaryContainer: Color(0xFF00A392),
    onTertiaryContainer: Color(0xFF00302A),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF101319),
    onSurface: Color(0xFFE1E2EB),
    surfaceDim: Color(0xFF101319),
    surfaceBright: Color(0xFF363940),
    surfaceContainerLowest: Color(0xFF0B0E14),
    surfaceContainerLow: Color(0xFF191C22),
    surfaceContainer: Color(0xFF1D2026),
    surfaceContainerHigh: Color(0xFF272A30),
    surfaceContainerHighest: Color(0xFF32353B),
    onSurfaceVariant: Color(0xFF9CA3AF),
    outline: Color(0xFFAA8982),
    outlineVariant: Color(0xFF5A413B),
    inverseSurface: Color(0xFFE1E2EB),
    onInverseSurface: Color(0xFF2D3037),
    inversePrimary: Color(0xFFB42806),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: Color(0xFFFB5B36),
  );

  static ThemeData get oscuro => _build(_oscuro);

  /// Sin especificación de modo claro en el sistema de diseño (es
  /// deliberadamente dark-first) — se deriva de la misma semilla como
  /// respaldo para dispositivos que fuercen tema claro por accesibilidad.
  static ThemeData get claro => _build(
        ColorScheme.fromSeed(seedColor: const Color(0xFFFB5B36), brightness: Brightness.light),
      );

  static ThemeData _build(ColorScheme scheme) {
    final esOscuro = scheme.brightness == Brightness.dark;
    final textTheme = _textTheme(scheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.onSurface.withValues(alpha: esOscuro ? 0.06 : 0.08)),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.onSurface.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(color: scheme.onSurface.withValues(alpha: 0.14)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        selectedColor: scheme.primary.withValues(alpha: 0.16),
        side: BorderSide(color: scheme.onSurface.withValues(alpha: 0.08)),
        labelStyle: textTheme.labelMedium,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.onSurface.withValues(alpha: 0.08), space: 1),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? scheme.primary : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? scheme.primary.withValues(alpha: 0.4) : null,
        ),
      ),
    );
  }

  /// Plus Jakarta Sans para títulos (calidez geométrica), Inter para texto
  /// denso/transaccional — tamaños y pesos tomados literal de `design/`.
  static TextTheme _textTheme(ColorScheme scheme) {
    TextStyle jakarta({required double size, required double height, required FontWeight weight, double? spacing}) =>
        GoogleFonts.plusJakartaSans(
          fontSize: size,
          height: height / size,
          fontWeight: weight,
          letterSpacing: spacing,
          color: scheme.onSurface,
        );

    TextStyle inter({required double size, required double height, required FontWeight weight, double? spacing}) =>
        GoogleFonts.inter(
          fontSize: size,
          height: height / size,
          fontWeight: weight,
          letterSpacing: spacing,
          color: scheme.onSurface,
        );

    return TextTheme(
      displayLarge: jakarta(size: 40, height: 48, weight: FontWeight.w700, spacing: -0.8),
      displayMedium: jakarta(size: 30, height: 38, weight: FontWeight.w700, spacing: -0.45),
      headlineLarge: jakarta(size: 28, height: 36, weight: FontWeight.w700, spacing: -0.28),
      headlineMedium: jakarta(size: 22, height: 28, weight: FontWeight.w600),
      headlineSmall: jakarta(size: 18, height: 24, weight: FontWeight.w600),
      titleLarge: jakarta(size: 18, height: 24, weight: FontWeight.w600),
      titleMedium: jakarta(size: 16, height: 22, weight: FontWeight.w600),
      titleSmall: inter(size: 14, height: 20, weight: FontWeight.w600, spacing: 0.14),
      bodyLarge: inter(size: 16, height: 24, weight: FontWeight.w400),
      bodyMedium: inter(size: 14, height: 20, weight: FontWeight.w400),
      bodySmall: inter(size: 12, height: 18, weight: FontWeight.w400),
      labelLarge: inter(size: 14, height: 20, weight: FontWeight.w600, spacing: 0.14),
      labelMedium: inter(size: 12, height: 16, weight: FontWeight.w600, spacing: 0.24),
      labelSmall: inter(size: 11, height: 14, weight: FontWeight.w600, spacing: 0.33),
    ).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
      decorationColor: scheme.onSurface,
    );
  }
}

/// Colores de estado de cita (§6), consistentes en toda la app.
Color colorEstadoCita(String estado) {
  switch (estado) {
    case 'reservada':
      return AppColors.advertencia;
    case 'confirmada':
      return AppColors.primario;
    case 'en_curso':
      return const Color(0xFFCEBEFA); // lavanda — "en curso", distinto de reservado/confirmado
    case 'completada':
      return AppColors.exito;
    case 'cancelada_cliente':
    case 'cancelada_local':
    case 'no_show':
    case 'expirada':
      return AppColors.peligro;
    case 'reagendada':
      return AppColors.textoSecundario;
    default:
      return AppColors.textoSecundario;
  }
}

String textoEstadoCita(String estado) {
  switch (estado) {
    case 'reservada':
      return 'Reservada';
    case 'confirmada':
      return 'Confirmada';
    case 'en_curso':
      return 'En curso';
    case 'completada':
      return 'Completada';
    case 'cancelada_cliente':
      return 'Cancelada por el cliente';
    case 'cancelada_local':
      return 'Cancelada por el local';
    case 'no_show':
      return 'No se presentó';
    case 'expirada':
      return 'Expirada';
    case 'reagendada':
      return 'Reagendada';
    default:
      return estado;
  }
}
