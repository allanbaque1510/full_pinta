import 'package:flutter/material.dart';

/// Fila de una línea "ícono + texto", con el texto truncable — dirección de
/// un local, un dato de contacto, una nota. El patrón más repetido de la
/// app en su forma más chica.
class IconTextRow extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color? color;
  final TextStyle? estilo;
  final int? maxLineas;

  const IconTextRow({
    super.key,
    required this.icono,
    required this.texto,
    this.color,
    this.estilo,
    this.maxLineas,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tinte = color ?? scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 15, color: tinte),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              texto,
              maxLines: maxLineas,
              overflow: maxLineas != null ? TextOverflow.ellipsis : null,
              style: estilo ?? Theme.of(context).textTheme.bodySmall?.copyWith(color: tinte),
            ),
          ),
        ],
      ),
    );
  }
}
