import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Logotipo "Full Pinta" del mockup: "Full" en frambuesa, "Pinta" en el
/// color de texto. Reemplaza al PNG naranja sobre fondo oscuro, que no se
/// ve bien en el lienzo claro.
class FullPintaWordmark extends StatelessWidget {
  final double tamano;
  final String? sufijo; // p. ej. "Business"

  const FullPintaWordmark({super.key, this.tamano = 24, this.sufijo});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = GoogleFonts.plusJakartaSans(fontSize: tamano, fontWeight: FontWeight.w800, letterSpacing: -0.5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text.rich(TextSpan(children: [
          TextSpan(text: 'Full', style: base.copyWith(color: scheme.primary)),
          TextSpan(text: ' Pinta', style: base.copyWith(color: scheme.primary)),
        ])),
        if (sufijo != null) ...[
          const SizedBox(width: 6),
          Text(sufijo!, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ],
    );
  }
}
