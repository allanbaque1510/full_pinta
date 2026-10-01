import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sistema de diseño de FullPinta según el mockup oficial
/// (`context/Image.jpg`): lienzo claro y limpio, acento frambuesa para
/// CTAs/estados activos, verde para disponibilidad y amarillo cálido para
/// estrellas. Modo claro es la identidad; el oscuro es solo respaldo.
class AppColors {
  AppColors._();

  static const Color primario = Color(0xFFC72A5B); // frambuesa — CTAs, estados activos
  static const Color primarioSuave = Color(0xFFFCE7EE); // fondo de chips/slots
  static const Color exito = Color(0xFF1E9E57); // "Disponible hoy", completada
  static const Color exitoSuave = Color(0xFFE3F6EA);
  static const Color peligro = Color(0xFFD93F3F);
  static const Color advertencia = Color(0xFFF59E0B); // hold / pendiente
  static const Color estrella = Color(0xFFF5B301);
  static const Color textoSecundario = Color(0xFF6B7280);
  static const Color borde = Color(0xFFECE9EC);
}

class AppTheme {
  AppTheme._();

  static const ColorScheme _claroScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primario,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: AppColors.primarioSuave,
    onPrimaryContainer: Color(0xFF7A1636),
    secondary: Color(0xFF6D4C8F),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFEFE6F7),
    onSecondaryContainer: Color(0xFF3B2459),
    tertiary: AppColors.exito,
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: AppColors.exitoSuave,
    onTertiaryContainer: Color(0xFF0B5A31),
    error: AppColors.peligro,
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFDE4E4),
    onErrorContainer: Color(0xFF7A1D1D),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1F1F24),
    surfaceDim: Color(0xFFF1EFF1),
    surfaceBright: Color(0xFFFFFFFF),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFFFFFF),
    surfaceContainer: Color(0xFFF6F4F6),
    surfaceContainerHigh: Color(0xFFF1EFF1),
    surfaceContainerHighest: Color(0xFFEBE8EB),
    onSurfaceVariant: AppColors.textoSecundario,
    outline: Color(0xFFC9C5CA),
    outlineVariant: AppColors.borde,
    inverseSurface: Color(0xFF2D2D33),
    onInverseSurface: Color(0xFFF6F4F6),
    inversePrimary: Color(0xFFFFB1C8),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: Colors.transparent,
  );

  static final ColorScheme _oscuro = ColorScheme.fromSeed(
    seedColor: AppColors.primario,
    brightness: Brightness.dark,
  ).copyWith(primary: const Color(0xFFFF6B93), tertiary: const Color(0xFF3CDDC7));

  static ThemeData get claro => _build(_claroScheme);

  /// Respaldo para dispositivos que fuercen tema oscuro: el mockup es claro.
  static ThemeData get oscuro => _build(_oscuro);

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
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: esOscuro ? scheme.onSurface.withValues(alpha: 0.08) : AppColors.borde),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.onSurface.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(color: scheme.onSurface.withValues(alpha: 0.14)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        selectedColor: scheme.primary.withValues(alpha: esOscuro ? 0.24 : 0.12),
        checkmarkColor: scheme.primary,
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
        backgroundColor: scheme.surface,
        indicatorColor: Colors.transparent,
        height: 68,
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
