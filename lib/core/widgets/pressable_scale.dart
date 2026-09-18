import 'package:flutter/material.dart';

/// Envuelve cualquier fila/card tocable para que encoja levemente al
/// presionar, sobre el mismo `InkWell` (sin duplicar el gesto ni perder el
/// ripple) — el ripple solo, en tarjetas grandes (menús, accesos rápidos,
/// filas de lista), se sentía plano.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double escalaAlPresionar;
  final BorderRadius? borderRadius;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.escalaAlPresionar = 0.97,
    this.borderRadius,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _presionado = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _presionado ? widget.escalaAlPresionar : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: Material(
        type: MaterialType.transparency,
        borderRadius: widget.borderRadius,
        child: InkWell(
          borderRadius: widget.borderRadius,
          onTap: widget.onTap,
          onHighlightChanged: (v) => setState(() => _presionado = v),
          child: widget.child,
        ),
      ),
    );
  }
}
