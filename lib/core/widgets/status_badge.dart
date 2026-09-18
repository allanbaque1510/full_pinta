import 'package:flutter/material.dart';

/// Insignia pill con ícono, usada para "Verificado", "Cupos hoy", estados
/// de cita resumidos, etc. — mismo patrón visual en toda la app (ver
/// `design/`: badges tipo pill con fondo tenue del color de acento).
class StatusBadge extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color color;

  const StatusBadge({super.key, required this.icono, required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            texto,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
