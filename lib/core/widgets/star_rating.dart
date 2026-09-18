import 'package:flutter/material.dart';

/// Estrellas de solo lectura, para mostrar un promedio (ej. 4.7).
class StarRatingView extends StatelessWidget {
  final double puntaje;
  final double tamano;

  const StarRatingView({super.key, required this.puntaje, this.tamano = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final relleno = (puntaje - i).clamp(0, 1).toDouble();
        return Icon(
          relleno >= 1
              ? Icons.star_rounded
              : relleno > 0
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
          size: tamano,
          color: Colors.amber,
        );
      }),
    );
  }
}

/// Estrellas interactivas para dejar una reseña (1 a 5, toque para elegir).
class StarRatingInput extends StatelessWidget {
  final int valor;
  final ValueChanged<int> onChanged;
  final double tamano;

  const StarRatingInput({
    super.key,
    required this.valor,
    required this.onChanged,
    this.tamano = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final indice = i + 1;
        return IconButton(
          onPressed: () => onChanged(indice),
          icon: Icon(
            indice <= valor ? Icons.star_rounded : Icons.star_outline_rounded,
            color: Colors.amber,
            size: tamano,
          ),
        );
      }),
    );
  }
}
