import 'package:flutter/material.dart';

import 'pressable_scale.dart';

/// Botón circular con ícono + etiqueta abajo — "Llamar", "WhatsApp", "Cómo
/// llegar", etc. Mismo patrón en el perfil público del local y en el
/// detalle de una cita; antes vivía duplicado como `_AccionMini`/`_AccionRapida`
/// en cada pantalla.
class QuickActionButton extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final VoidCallback onTap;
  final Color? color;

  const QuickActionButton({super.key, required this.icono, required this.etiqueta, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tinte = color ?? scheme.onSurface;
    return PressableScale(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: tinte.withValues(alpha: 0.16),
              foregroundColor: tinte,
              child: Icon(icono, size: 20),
            ),
            const SizedBox(height: 4),
            Text(etiqueta, style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
