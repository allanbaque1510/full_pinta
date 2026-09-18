import 'package:flutter/material.dart';

/// Punto de color sólido — indicador de estado inline (junto a un texto,
/// dentro de un pill, etc.). Se repetía como `Container` suelto en cada
/// pantalla que pinta un estado.
class ColorDot extends StatelessWidget {
  final Color color;
  final double tamano;

  const ColorDot({super.key, required this.color, this.tamano = 6});

  @override
  Widget build(BuildContext context) {
    return Container(width: tamano, height: tamano, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}
