import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'color_dot.dart';

/// Pill de estado de una cita (§6): punto de color + texto, con el mismo
/// mapeo `colorEstadoCita`/`textoEstadoCita` en toda la app — antes se
/// repetía a mano en la agenda, en mis citas y en el detalle de una cita.
class EstadoCitaPill extends StatelessWidget {
  final String estado;

  const EstadoCitaPill({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final color = colorEstadoCita(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ColorDot(color: color),
          const SizedBox(width: 5),
          Text(textoEstadoCita(estado), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}
