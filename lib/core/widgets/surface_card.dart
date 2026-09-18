import 'package:flutter/material.dart';

/// Contenedor "tarjeta suave" (`surfaceContainerLow`, radio 16, padding
/// consistente) — es el bloque que más se repite en las pantallas nuevas
/// del sistema de diseño (`design/`): resumen de cita, tarjeta de local
/// seleccionado, secciones del panel de negocio, etc. Antes de envolver algo
/// en un `Container` con esta decoración a mano, usar este widget.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radio;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radio = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(radio),
      ),
      child: child,
    );
  }
}
