import 'package:flutter/material.dart';

/// `CircleAvatar` con ícono "tintado" (fondo del color al 16%, ícono al
/// 100%) — el avatar de acceso más repetido en menús, tarjetas de contexto
/// y filas de selección rápida en toda la app.
class IconAvatar extends StatelessWidget {
  final IconData icono;
  final Color? color;
  final double radio;
  final double tamanoIcono;

  const IconAvatar({super.key, required this.icono, this.color, this.radio = 20, this.tamanoIcono = 20});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tinte = color ?? scheme.primary;
    return CircleAvatar(
      radius: radio,
      backgroundColor: tinte.withValues(alpha: 0.16),
      foregroundColor: tinte,
      child: Icon(icono, size: tamanoIcono),
    );
  }
}
