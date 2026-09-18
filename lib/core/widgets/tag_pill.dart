import 'package:flutter/material.dart';

/// Pill de una sola palabra/número con fondo tenue del color dado — para
/// contadores ("4 guardados"), etiquetas de tipo ("LOCAL"/"PROFESIONAL") o
/// roles ("Propietario"). Sin ícono ni borde: para eso está `StatusBadge`.
class TagPill extends StatelessWidget {
  final String texto;
  final Color color;
  final double alphaFondo;

  /// Fondo neutro (`surfaceContainerHighest`) para contadores sin
  /// connotación de color, en vez del fondo teñido con `color`.
  final bool neutro;

  const TagPill({
    super.key,
    required this.texto,
    this.color = Colors.transparent,
    this.alphaFondo = 0.15,
    this.neutro = false,
  }) : assert(neutro || color != Colors.transparent, 'Pasa un color, o neutro: true');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textoColor = neutro ? scheme.onSurface : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: neutro ? scheme.surfaceContainerHighest : color.withValues(alpha: alphaFondo),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(texto, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: textoColor)),
    );
  }
}
