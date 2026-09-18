import 'package:flutter/material.dart';

/// Entrada suave (fade + leve deslizamiento hacia arriba) para filas de
/// lista — con `indice` escalona la animación entre ítems consecutivos.
/// Se anima una sola vez al montarse, no en cada rebuild.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int indice;

  const FadeSlideIn({super.key, required this.child, this.indice = 0});

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  late final Animation<double> _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    final retraso = Duration(milliseconds: 25 * widget.indice.clamp(0, 12));
    Future.delayed(retraso, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
